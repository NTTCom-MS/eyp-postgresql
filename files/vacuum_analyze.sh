#!/bin/bash
# puppet managed file

PATH="/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin"

BASEDIRBCK=$(dirname $0)
BASENAMEBCK=$(basename $0)
IDHOST=${IDHOST-$(hostname -s)}

if [ ! -z "$1" ] && [ -f "$1" ];
then
	. $1 2>/dev/null
else
	if [[ -s "$BASEDIRBCK/${BASENAMEBCK%%.*}.config" ]];
	then
		. $BASEDIRBCK/${BASENAMEBCK%%.*}.config 2>/dev/null
	fi
fi

if [ -z "${DATABASES}" ];
then
  DATABASES=$(echo "select datname as x5885c02fbd247232adb1438b52e6acd0 from pg_database;" | psql -U postgres | grep -v "No relations found" | grep "^ [^ ]*" | grep -v "x5885c02fbd247232adb1438b52e6acd0\|\btemplate0\b")
fi

for DATABASE in $DATABASES;
do
  if [ -z "${TABLES}" ];
  then
    TABLES="$(echo "select n.nspname || '.' || c.relname as x5885c02fbd247232adb1438b52e6acd0 from pg_catalog.pg_class c LEFT JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE c.relkind = 'r' AND n.nspname <> 'pg_catalog' AND n.nspname <> 'information_schema' AND n.nspname !~ '^pg_toast' AND pg_catalog.pg_table_is_visible(c.oid);" | psql -U postgres -d ${DATABASE} | grep -v "No relations found" | grep "^ [^ ]*" | grep -v "x5885c02fbd247232adb1438b52e6acd0")"
  fi

  for TABLE in $TABLES;
  do
    echo "VACUUM ANALYZE ${TABLE}" | psql -U postgres -d ${DATABASE}
  done
done
