#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USERNAME=$USER
DATABASE=$USER

while getopts 'hd:U:e:' OPT;
do
    case $OPT in
        d)  DATABASE="$OPTARG"
        ;;
        U)  USERNAME="$OPTARG"
        ;;
        e)  EXECCMD="$OPTARG"
        ;;
        h)  JELP=1
        ;;
        *)  WTF="yes"
        ;;
    esac
done

shift $(($OPTIND - 1))

if [ -n "$WTF" ] || [ -n "$JELP" ];
then
    echo "usage: $0 -d <DATABASE> [OPTIONS]"
    echo -e "\t-d\t\tdatabase name to connect to (default: $USER)"
    echo -e "\t-U\t\tdatabase user name (default: $USER)"
    echo -e "\t-e\t\tcommand to run (use %t for table)"
    exit 1
fi

PSQLBIN=$(which psql)

if [ -z "$PSQLBIN" ];
then
    echo "unable to find psql"
    exit 1
fi

if [ -z "$EXECCMD" ];
then
    $PSQLBIN -U "$USERNAME" -d "$DATABASE" -A -t -q --pset pager=off -c "select table_name from information_schema.tables where table_type='BASE TABLE';"
else
    $PSQLBIN -U "$USERNAME" -d "$DATABASE" -A -t -q --pset pager=off -c "select table_name from information_schema.tables where table_type='BASE TABLE';" | xargs -I %t echo "$EXECCMD" | $PSQLBIN -U "$USERNAME" -d "$DATABASE" -A -t -q --pset pager=off$PSQLBIN -U "$USERNAME" -d "$DATABASE" -A -t -q --pset pager=off
fi
