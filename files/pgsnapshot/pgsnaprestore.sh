#!/bin/bash

if [ -z "$1" ];
then
  echo "usage: $0 <snap_name>"
  exit 1
fi

exec > /var/log/$1.$(date +%Y%m%d%H%M%S).log 2>&1


LVDISPLAYBIN=$(which lvdisplay 2>/dev/null)

if [ -z "${LVDISPLAYBIN}" ];
then
  echo "lvdisplay not found, please install lvm tools"
  exit 1
fi

lvdisplay 2>/dev/null | grep "LV Name" | grep "$1"
while [ "$?" -ne 0 ];
do
  RANDOM_SLEEP=$(echo $RANDOM | grep -Eo "^[0-9]{2}")
  if [ -z "${RANDOM_SLEEP}" ];
  then
    RANDOM_SLEEP=10
  fi
  echo "$1 not found, waiting for ${RANDOM_SLEEP} seconds"
  sleep $RANDOM_SLEEP

  DUPLICATED_PV=$(pvscan 2>&1 | grep "was already found on" | awk '{ print $5 }' | head -n1)
  if [ ! -z "${DUPLICATED_PV}" ];
  then
    # hack - needs to be improved
    vgimportclone --config 'devices{filter=[ "r|/dev/xvdb1|" ]}' -n restore $(ls /dev/xvd* | grep "[0-9]$" | grep -v "xvd[ab]")
  fi


  lvdisplay 2>/dev/null | grep "LV Name" | grep "$1"
done

vgchange -ay

SNAP_PATH=$(lvdisplay | grep -E "LV Name[ ]*${1}" -B1 | grep "LV Path" | awk '{ print $NF }')
BASE_VOLUME=$(lvdisplay "${SNAP_PATH}" | grep "LV snapshot status" | awk '{ print $NF }')
BASE_PATH="${SNAP_PATH%/*}/${BASE_VOLUME}"

lvconvert --merge ${SNAP_PATH}

if [ "$?" -ne 0 ];
then
  echo "error merging snapshot"
  exit 1
fi

mkdir -p /var/lib/pgsnapshot

mount | grep "/var/lib/pgsnapshot"
if [ "$?" -ne 0 ];
then
  mount "${BASE_PATH}" /var/lib/pgsnapshot
  if [ "$?" ne 0 ];
  then
    echo "error mounting FS"
    exit 1
  fi
fi

grep "/var/lib/pgsnapshot" /etc/fstab
if [ "$?" -ne 0 ];
then
  mount | grep /var/lib/pgsnapshot | awk '{ print $1,$3,$5,"defaults,noatime 0 0" }' >> /etc/fstab
else
  echo "/var/lib/pgsnapshot already present on the fstab"
fi

if [ ! -f "/var/lib/pgsnapshot/postgresql.conf" ];
then
  echo "/var/lib/pgsnapshot/postgresql.conf NOT FOUND"
  exit 1
fi

POSTGRES_VERSION=$(grep "# PostgreSQL [0-9]\+\.[0-9]\+ configuration file" /var/lib/pgsnapshot | grep -o "[0-9]\+\.[0-9]\+")
# postgres 9.6 by default for absolutely no reason -_(._.)_-
POSTGRES_VERSION=${POSTGRES_VERSION:-9.6}

if [ ! -f "/opt/puppet-masterless/localpuppetmaster.sh" ];
then
  echo "puppet-masterless NOT FOUND"
  exit 1
fi

bash /opt/puppet-masterless/setup.sh

if [ ! -f "/opt/puppet-masterless/localpuppetmaster.sh" ];
then
  echo "puppet-masterless NOT FOUND"
  exit 1
fi

if [ ! -f "/tmp/postgres/modules/postgresql/manifests/init.pp" ];
then
  echo "eyp-postgresql NOT FOUND"
  exit 1
fi

mkdir -p /tmp/postgres/manifests

cat <<EOF >/tmp/postgres/manifests/pgrestore.pp
class { 'postgresql::backup::pgsnapshot::pgsnaprestore': }

->

class { 'postgresql':
  wal_level           => 'hot_standby',
  max_wal_senders     => '3',
  checkpoint_segments => '8',
  wal_keep_segments   => '8',
  version             => '${POSTGRES_VERSION}',
  datadir             => '/var/lib/pgsnapshot',
  initdb              => false,
  manage_pghba        => false,
  manage_configfile   => false,
}
EOF

/opt/puppet-masterless/localpuppetmaster.sh -d /tmp/postgres -r https://github.com/NTTCom-MS/eyp-postgresql -s /tmp/postgres/manifests/pgrestore.pp

exit 0
