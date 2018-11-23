import getopt
import sys
import subprocess

def getVG(lvm_disk):
    # busquem vg del lv

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
            vg_name = line_split[2]
            pv_disks = []

            p = subprocess.Popen('vgdisplay '+vg_name+' -vv 2>/dev/null  | grep "PV Name"', shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            for line in p.stdout.readlines():
                line_split = line.split()
                if line_split[0]=="PV" and line_split[1]=="Name":
                    pv_disks.append(line_split[2])
                else:
                    sys.exit('Corrupted output getting PV disk for '+vg_name+':\n'+line)
            retval = p.wait()

            if retval!=0:
                sys.exit('ERROR listing PV disks for: '+vg_name)
            else:
                print pv_disks


        else:
            sys.exit('Corrupted output getting VG name: '+lastline)
    else:
        sys.exit('Invalid disk: '+lvm_disk)

lvm_disk = ""
snapshot_size = "10G"
awscli = False

options, remainder = getopt.getopt(sys.argv[1:], 'l:s:a', ['lvm-disk=',
                                                          'snapshot-size=',
                                                          'aws'
                                                         ])

for opt, arg in options:
    if opt in ('-l', '--lvm-disk'):
        lvm_disk = arg
    elif opt in ('-s', '--snapshot-size'):
        snapshot_size = arg
    elif opt in ('-a', '--aws'):
        awscli = True
    else:
      sys.exit("unrecoginzed option: ".opt)

if not lvm_disk:
    sys.exit("lvm-disk is mandatory")

getVG(lvm_disk)

if awscli:
    import boto3
    import urllib2

    instance_id = urllib2.urlopen('http://169.254.169.254/latest/meta-data/instance-id').read()

    if not instance_id:
      sys.exit("error getting instance_id")

    ec2 = boto3.resource('ec2')

    instance = ec2.Instance(instance_id)

    print(instance.block_device_mappings)
