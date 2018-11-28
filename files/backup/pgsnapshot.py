import logging
import getopt
import sys
import subprocess
import os.path
import smtplib
import datetime, time
import psutil, os
import re
import socket
import urllib2
import getpass
from os import access, R_OK
from ConfigParser import SafeConfigParser
from subprocess import Popen,PIPE,STDOUT
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText

def sendReportEmail(errors, to_addr, id_host):
    global logFile

    from_addr=getpass.getuser()+'@'+socket.gethostname()

    msg = MIMEMultipart()
    msg['From'] = from_addr
    msg['To'] = to_addr
    if errors:
        msg['Subject'] = id_host+"-PGSNAPSHOT-ERROR"
    else:
        msg['Subject'] = id_host+"-PGSNAPSHOT-OK"

    body = "please check "+logFile+" on "+socket.gethostname()
    msg.attach(MIMEText(body, 'plain'))

    server = smtplib.SMTP('localhost')
    text = msg.as_string()
    server.sendmail(from_addr, to_addr, text)
    server.quit()

    logging.info("sent report to "+to_addr)

def isPostgresInBackupMode():
    # check if it is un backup mode
    # psql -U postgres -c 'select pg_backup_start_time();' | grep -A 1 -- --- | tail -n1
    p = subprocess.Popen("psql -U postgres -c 'select pg_backup_start_time();' | grep -A 1 -- --- | tail -n1", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    linecount=0
    lastline=""
    for line in p.stdout.readlines():
        lastline = line.strip()
        linecount+=1
    retval = p.wait()

    if retval==0 and linecount==1:
        return bool(lastline)
    else:
        logging.error('Unable check if postgres is un backup mode: '+lastline)

def logAndExit(msg):
    global purge
    global keep_lvm_snaps
    if isPostgresInBackupMode():
        logging.debug("postgres in backup mode, disabling backup mode")
        postgresBackupMode(False)
    else:
        logging.debug("postgres is not un backup mode")

    logging.error(msg)

    if purge and keep_lvm_snaps==0:
        purgeOldSnapshots(vg_name, lv_name, keep_lvm_snaps, awscli)

    if to_addr:
        sendReportEmail(False, to_addr, id_host)

    sys.exit(msg+"\n")

def removeLVMSnapshot(lv_snap):
    p = subprocess.Popen("lvremove "+lv_snap+" -y", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    linecount=0
    lastline=""
    for line in p.stdout.readlines():
        lastline = line.strip()
        linecount+=1
    retval = p.wait()

    if retval==0 and linecount==1:
        logging.debug("removed snapshot:"+lv_snap)
        return snap_name
    else:
        logAndExit('Unable to remove lvm snapshot: (retcode: '+str(retval)+')'+lastline)

def purgeOldSnapshots(vg_name, lv_name, keep, awscli):
    snaps = {}
    p = subprocess.Popen("lvdisplay /dev/"+vg_name+"/"+lv_name+" | awk '/LV snapshot/,/LV Status/' | grep -v LV | awk '{ print $1 }'", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    linecount=0
    for line in p.stdout.readlines():
        try:
            ts = time.mktime(datetime.datetime.strptime(line.strip(), snapshotbasename+'.'+timeformat).timetuple())
        except:
            continue
        snaps[ts] = line.strip()
    retval = p.wait()

    if retval==0:
        keylist = snaps.keys()
        keylist.sort()
        logging.debug(keylist)
        to_delete = len(keylist)-keep
        logging.debug("snapshots: "+str(len(keylist))+" keeping: "+str(keep)+" deleting: "+str(to_delete))
        for key in keylist:
            if to_delete<=0:
                return True
            logging.debug("purging snapshot: "+str(key)+": "+snaps[key])
            removeLVMSnapshot("/dev/"+vg_name+"/"+snaps[key])
            to_delete-=1
        return True
    else:
        # not using longAndExit because we could end up in a recurse loop
        if to_addr:
            sendReportEmail(False, to_addr, id_host)

        sys.exit('Unable to purge old snapshots'+"\n")

def doLVMSnapshot(lvm_disk, snap_name, snap_size='5G'):
    # [root@ip-172-31-46-9 ~]# lvcreate -s -n snap -L 5G /dev/vg/postgres
    #   Logical volume "snap" created.
    # [root@ip-172-31-46-9 ~]# echo $?
    # 0
    # [root@ip-172-31-46-9 ~]#
    p = subprocess.Popen("lvcreate -s -n "+snap_name+" -L "+snap_size+" "+lvm_disk+" 2>/dev/null", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    linecount=0
    output=""
    lastline=""
    for line in p.stdout.readlines():
        lastline = line.strip()
        output+=lastline
        linecount+=1
    retval = p.wait()

    if retval==0:
        logging.debug("created snapshot:"+snap_name)
        return snap_name
    else:
        logAndExit('Unable to create lvm snapshot (retcode: '+str(retval)+'): '+output)


def postgresBackupMode(enable = True, backup_name=""):
    global pgusername
    global snapshotbasename
    if enable:
        if not backup_name:
            backup_name = snapshotbasename+"."+datetime.datetime.fromtimestamp(time.time()).strftime(timeformat)
        backup_command ="select pg_start_backup('"+backup_name+"');"
    else:
        backup_command = "select pg_stop_backup();"

    psql_command = "psql -U "+pgusername+' -c "'+backup_command+'"'
    logging.debug("postgresBackupMode: "+psql_command)
    p = subprocess.Popen(psql_command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    for line in p.stdout.readlines():
        logging.debug("postgresBackupMode: "+line.strip())
    retval = p.wait()

    if retval==0:
        return backup_name
    else:
        logAndExit('Unable to start pg_backup')

def getDisks(pv_disks, tranlate_aws=True):
    disks = set()
    regex = re.compile(r"^xv")
    for pv_disk in pv_disks:
        p = subprocess.Popen("lsblk -no pkname "+pv_disk+" | head -n1", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        linecount=0
        lastline=""
        for line in p.stdout.readlines():
            lastline = line.strip()
            linecount+=1
        retval = p.wait()

        if retval==0 and linecount==1:
            if tranlate_aws:
                disks.add("/dev/"+regex.sub('s', lastline))
            else:
                disks.add("/dev/"+lastline)
        else:
            logAndExit('Error getting disk from PV')
    return disks


# thank god for stackoverflow - https://stackoverflow.com/questions/25283882/determining-the-filesystem-type-from-a-path-in-python
def getFSType(path):
    partition = {}
    for part in psutil.disk_partitions(True):
        partition[part.mountpoint] = (part.fstype, part.device)
    if path in partition:
        return partition[path]
    splitpath = path.split(os.sep)
    for i in xrange(len(splitpath),0,-1):
        path = os.sep.join(splitpath[:i]) + os.sep
        if path in partition:
            return partition[path]
        path = os.sep.join(splitpath[:i])
        if path in partition:
            return partition[path]
    return ("unkown","none")

def getDataDir():
    global pgusername
    #psql -U postgres -c 'SHOW data_directory;'
    p = subprocess.Popen("psql -U "+pgusername+" -c 'SHOW data_directory;' | grep -A 1 -- --- | tail -n1", shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    linecount=0
    lastline=""
    for line in p.stdout.readlines():
        lastline = line.strip()
        linecount+=1
    retval = p.wait()

    if retval==0 and linecount==1:
        return lastline
    else:
        logAndExit('Error getting datadir')

def getLV(lvm_disk):
    # busquem vg del lv, dsp pv del vg
    p = subprocess.Popen('lvdisplay '+lvm_disk+' 2>/dev/null | grep "LV Name"', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    linecount=0
    lastline=""
    for line in p.stdout.readlines():
        lastline = line
        linecount+=1
    retval = p.wait()

    if retval==0 and linecount==1:
        line_split = lastline.split()
        if line_split[0]=="LV" and line_split[1]=="Name":
            return line_split[2]
        else:
            logAndExit('Corrupted output getting LV name: '+lastline)
    else:
        logAndExit('Invalid disk: '+lvm_disk)

def getVG(lvm_disk):
    # busquem vg del lv, dsp pv del vg
    p = subprocess.Popen('lvdisplay '+lvm_disk+' 2>/dev/null | grep "VG Name"', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    linecount=0
    lastline=""
    for line in p.stdout.readlines():
        lastline = line
        linecount+=1
    retval = p.wait()

    if retval==0 and linecount==1:
        line_split = lastline.split()
        if line_split[0]=="VG" and line_split[1]=="Name":
            return line_split[2]
        else:
            logAndExit('Corrupted output getting VG name: '+lastline)
    else:
        logAndExit('Invalid disk: '+lvm_disk)

def getPVs(vg_name):
    pv_disks = []

    p = subprocess.Popen('vgdisplay '+vg_name+' -vv 2>/dev/null  | grep "PV Name"', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    for line in p.stdout.readlines():
        line_split = line.split()
        if line_split[0]=="PV" and line_split[1]=="Name":
            pv_disks.append(line_split[2])
        else:
            logAndExit('Corrupted output getting PV disk for '+vg_name)
    retval = p.wait()

    if retval!=0:
        logAndExit('ERROR listing PV disks for: '+vg_name)
    else:
        return pv_disks

def getInstanceID():
    return urllib2.urlopen('http://169.254.169.254/latest/meta-data/instance-id').read()

def getAWSVolumes(instance_devices):
    volumes = []
    for instance_device in instance_devices:
        if instance_device['DeviceName'] in disks:
            volumes.append(instance_device['Ebs']['VolumeId'])
    return volumes

def createAWSsnapshot(ec2, volume_id, lvm_disk, snap_name):
    global id_host
    try:
        # Create snapshot
        response = ec2.create_snapshot(volume_id, "pgsnapshot for "+snap_name)
        result = response[volume_id]
        ec.create_tags(Resources=[result],Tags=[{ 'Key': 'pgsnapshot-lvm_disk', 'Value': lvm_disk },{ 'Key': 'pgsnapshot-host', 'Value': id_host },{ 'Key': 'pgsnapshot-snap_name', 'Value': snap_name }])

        return True
    except Exception as e:
        logging.error(str(e))
        return False

def getAWSsnapshot(lvm_disk, snap_name):
    global id_host
    try:
        ec2 = boto3.client('ec2')
        response = ec2.describe_snapshots( Filters=[{ 'Name': 'pgsnapshot-lvm_disk', 'Values': lvm_disk },{ 'Name': 'pgsnapshot-host', 'Values': id_host },{ 'Name': 'pgsnapshot-snap_name', 'Values': snap_name }])

        return response
    except Exception as e:
        logAndExit('error getting AWS snapshot list: '+str(e))


timeformat = '%Y%m%d%H%M%S'
lvm_disk = ""
snap_size = "5G"
awscli = False
purge = True
config_file = './postgres_snapshot.config'
logdir = '/var/log/pgsnapshot'
pgusername = "postgres"
keep_lvm_snaps = 2
snapshotbasename='snap'
error_count=0

# parse opts

options, remainder = getopt.getopt(sys.argv[1:], 'l:s:ac:d', [
                                                            'lvm-disk=',
                                                            "config="
                                                            'snapshot-size=',
                                                            'aws',
                                                            'dontpurge'
                                                         ])

for opt, arg in options:
    if opt in ('-l', '--lvm-disk'):
        lvm_disk = arg
    elif opt in ('-s', '--snapshot-size'):
        snap_size = arg
    elif opt in ('-c', '--config'):
        config_file = arg
    elif opt in ('-a', '--aws'):
        awscli = True
    elif opt in ('-d', '--dontpurge'):
        purge = False
    elif opt in ('-l', '--logdir'):
        logdir = arg
    else:
      sys.exit("unrecoginzed option: ".opt)

logFormatter = logging.Formatter("%(asctime)s [%(threadName)-12.12s] [%(levelname)-5.5s]  %(message)s")
rootLogger = logging.getLogger()

consoleHandler = logging.StreamHandler()
consoleHandler.setFormatter(logFormatter)
rootLogger.addHandler(consoleHandler)

if not os.path.isfile(config_file):
    logging.error("Error - config file NOT FOUND ("+config_file+")")
    sys.exit(1)

if not access(config_file, R_OK):
    logging.error("Error reading config file ("+config_file+")")
    sys.exit(1)

try:
    config = SafeConfigParser()
    config.read(config_file)
except Exception, e:
    logging.error("error reading config file - ABORTING - "+str(e))
    sys.exit(1)

try:
    logdir=config.get('pgsnapshot', 'logdir').strip('"')
except:
    logdir=os.path.dirname(os.path.abspath(config_file))

ts = time.time()

logFile = "{0}/{1}/{2}-{3}.log".format(logdir, datetime.datetime.fromtimestamp(ts).strftime('%Y%m%d'), 'pgsnapshot', datetime.datetime.fromtimestamp(ts).strftime('%Y%m%d-%H%M%S'))

current_day_dirname = os.path.dirname(logFile)

try:
    os.makedirs(current_day_dirname)
except Exception, e:
    logging.debug("WARNING - error creating log directory: "+current_day_dirname+" - "+str(e))

fileHandler = logging.FileHandler(logFile)
fileHandler.setFormatter(logFormatter)
rootLogger.addHandler(fileHandler)

rootLogger.setLevel(0)

try:
    lvm_disk=config.get('pgsnapshot', 'lvmdisk').strip('"')
except:
    logging.debug('Using default value for lvm_disk: "'+lvm_disk+'"')

try:
    snap_size=config.get('pgsnapshot', 'snapsize').strip('"')
except:
    logging.debug('Using default value for snap_size: '+str(snap_size))

try:
    pgusername=config.get('pgsnapshot', 'pgusername').strip('"')
except:
    logging.debug('Using default value for pgusername: '+pgusername)

try:
    snapshotbasename=config.get('pgsnapshot', 'snapshotbasename').strip('"')
except:
    logging.debug('Using default value for snapshotbasename: '+snapshotbasename)

try:
    awscli=config.getboolean('pgsnapshot', 'aws')
except:
    logging.debug('Using default value for awscli: '+str(awscli))

try:
    keep_lvm_snaps=int(config.get('pgsnapshot', 'keeplvmsnaps'))
except:
    if awscli:
        keep_lvm_snaps=0
    else:
        keep_lvm_snaps=2

try:
    to_addr=config.get('pgsnapshot', 'to').strip('"')
except:
    to_addr=''

try:
    id_host=config.get('pgsnapshot', 'host-id').strip('"')
except:
    id_host=socket.gethostname()

#
# ACTIONS
#

if not lvm_disk:
    logging.debug("lvm_disk undefined, searching datadir")
    datadir = getDataDir()
    logging.debug("postgres datadir: "+datadir)
    lvm_disk = getFSType(datadir)[1]

logging.debug("lvm_disk: "+lvm_disk)

lv_name = getLV(lvm_disk)

logging.debug("lv_name: "+lv_name)

vg_name = getVG(lvm_disk)

logging.debug("vg_name: "+vg_name)

pv_disks = getPVs(vg_name)

logging.debug("pv_disks: "+str(pv_disks))

disks = getDisks(pv_disks)

logging.debug("disks: "+str(disks))

backup_name = postgresBackupMode(True)

logging.debug("backup_name: "+backup_name)

snap_name = doLVMSnapshot(lvm_disk, backup_name, snap_size)

logging.debug("snap_name: "+snap_name)

postgresBackupMode(False)

if awscli:
    try:
        import boto3

        logging.getLogger('boto3').setLevel(logging.CRITICAL)
        logging.getLogger('botocore').setLevel(logging.CRITICAL)
        logging.getLogger('nose').setLevel(logging.CRITICAL)

        instance_id = getInstanceID()

        logging.debug('instance_id: '+instance_id)

        if not instance_id:
          logAndExit("error getting instance_id")

        ec2 = boto3.resource('ec2')
        instance = ec2.Instance(instance_id)

        instance_devices = instance.block_device_mappings

        logging.debug('instance_devices: '+str(instance_devices))

        volumes = getAWSVolumes(instance_devices)

        logging.debug('volumes: '+str(volumes))

        for volume_id in volumes:
            if createAWSsnapshot(ec2, volume_id, lvm_disk, snap_name):
                logging.debug('created AWS snapshot for '+volume_id)
            else:
                error_count+=0
                logging.debug('error creating snapshot for '+volume_id)

        if purge:
            aws_snapshots = getAWSsnapshot(lvm_disk, snap_name)

            print aws_snapshots


    except Exception as e:
        logAndExit('error using AWS API: '+str(e))

if purge:
    purgeOldSnapshots(vg_name, lv_name, keep_lvm_snaps, awscli)

if to_addr:
    sendReportEmail(error_count!=0, to_addr, id_host)
