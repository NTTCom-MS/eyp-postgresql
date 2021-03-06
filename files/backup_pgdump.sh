#!/bin/bash
# puppet managed file

function echo_error()
{
  echo $(date +"%F %T %z") $@ 1>&2;
  ERROR=1;
}

function echo_info()
{
  echo $(date +"%F %T %z") $@ 1>&2;
}

function checkdirs()
{
  if [ ! -d "${BACKUPDIR}" ];
  then
    echo_error "Error: ${BACKUPDIR}/ does not exist";
    exit 1;
  fi
}

function bacula()
{
  dumpglobals;
  if [ x"${DATABASE}" == x"ALL" ];
  then
    getalldblist;
  else
    DUMPDBLIST=${DATABASE};
  fi
  for DBASE in ${DUMPDBLIST};
  do
    local NAME="dump_${DBASE}.${DATE}";
    local FDEST="${BACKUPDIR}/${NAME}.dmp"
    local FLOG="${BACKUPDIR}/${NAME}.elog"

    # no need to dump template0, it will be recreated by initdb
    if [ x"$DBASE" == x"template0" ];
    then
      continue;
    fi

    pg_dump -Fc -v -h $PGDATA -f $FDEST $DBASE 2>> $FLOG

    if [ "$?" -ne "0" ];
    then
      cat $FLOG;
    fi
  done
}

# dumpglobals($INSTANCE)
function dumpglobals()
{
  local GLOBALS="globals.${DATE}";
  local FDEST="${BACKUPDIR}/${GLOBALS}.sql";
  local ERROR=0;
  # local FLOG="${PDEST}/${INSTANCE}/${GLOBALS}.log";
  # exec 2> "${FLOG}"

  if [ -f "${FDEST}" ];
  then
    echo_error "Dumping instance ${INSTANCE}: dump file ${FDEST} exists. Refusing to overwrite.";
    return;
  fi

  pg_dumpall --verbose --host=${PGDATA} --globals-only --file=${FDEST};

  if [ "$?" -ne "0" ];
  then
    echo_error "Dumping instance ${INSTANCE}: an error has occurred dumping the globals from ${INSTANCE} to ${FDEST}. Please check ${FLOG}."
  fi
}


function getalldblist()
{
  DUMPDBLIST=$(psql --host=$PGDATA --no-align --tuples-only --command 'SELECT datname FROM pg_catalog.pg_database order by 1');
}

function mailer()
{
  SUBJECTOK="${IDHOST}-${TYPE}-OK";
  SUBJECTFAIL="${IDHOST}-${TYPE}-ERROR";
  TMPFILE=$(mktemp 'pgdump-backup.XXXXXXXXXXXXXXXXXXX');
  SUBJECT=$SUBJECTOK;
  FLOG="${BACKUPDIR}/${DATE}.log";
  exec 2>>${FLOG};
  echo "V2.0 PSQL" > $TMPFILE;
  if [ "${DATABASE}" == "ALL" ]; then
          getalldblist;
  else
          DUMPDBLIST=${DATABASE};
  fi

  dumpglobals;

  for DBASE in ${DUMPDBLIST};
  do
    local NAME="dump_${DBASE}.${DATE}";
    local FDEST="${BACKUPDIR}/${NAME}.dmp";
    # local FLOG="${PDEST}/${INSTANCE}/${NAME}.log";

    if [ -e "${FDEST}" ];
    then
      echo_error "ERROR while dumping instance ${INSTANCE}(${DBASE}): file ${FDEST} already exists";
      continue;
    fi


    # no need to dump template0, it will be recreated by initdb
    if [ x"$DBASE" == x"template0" ];
    then
      continue;
    fi

    echo "$(date +'%F %T %z') - pgdump $INSTANCE - database: $DBASE" 1>&2;

    pg_dump --format=c --host="${PGDATA}" --file="${FDEST}" --verbose "${DBASE}";

    if [ "$?" -ne "0" ];
    then
      echo_error "An error has occurred dumping database ${DBASE} on instance ${INSTANCE} to ${FDEST}. Please check ${FLOG}."
    fi

    SIZE=$(stat --format="%s" ${FDEST});
    echo_info "pgdump completed - ${INSTANCE}(${DBASE}) - size ${SIZE} bytes"
  done

  if [ "$ERROR" -eq "1" ];
  then
    SUBJECT=$SUBJECTFAIL;
    cat $FLOG >> $TMPFILE;
  fi

  for NOTIFY_P in $NOTIFY;
  do
    mail -s "$SUBJECT" $NOTIFY_P < $TMPFILE
  done

  rm -f "${TMPFILE}";
}


BACKUPDEFAULT='/apps/backup/postgresql/';
DUMPDBLIST="";
ERROR=0;
DATE=$(date +%Y%m%d.%H%M%S);

CONFIG=`dirname $0`/`basename $0 .sh`.config
. $CONFIG

# if PGDATA is not set in the config file look for the socket file in /tmp by default
PGDATA="${CONN:-/tmp/}";

if [ -z "${INSTANCE}" ];
then
  BACKUPDIR="${PDEST-$BACKUPDEFAULT}";
  TYPE="${TYPE:-POSTGRES}";
else
  BACKUPDIR="${PDEST-$BACKUPDEFAULT}/${INSTANCE}";
  #TYPE="${TYPE:-POSTGRES_${INSTANCE}}";
  TYPE="${TYPE:-POSTGRES}";
fi

INSTANCE="${INSTANCE:-default}";

checkdirs;

for EXT in dmp dmp.gz log elog err sql;
do
  for FILE in `find "${BACKUPDIR}" -daystart -maxdepth 1 -name "*.${EXT}" -mtime +${RETENTION} -type f`;
  do
    rm -f $FILE
  done
done

if [ -z $1 ]
then
  mailer
else
  if [ "$1" = "-bacula" ] || [ "$1" = "/bacula" ]
  then
    bacula
  else
    mailer
  fi
fi
