#!/bin/bash

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USERNAME=postgres
MAXLAG=18000
WARNINGLAG=14400

while getopts 'U:l:w:h' OPT;
do
    case $OPT in
        U)  USERNAME="$OPTARG"
        ;;
        l)  MAXLAG="$OPTARG"
        ;;
        w)  WARNINGLAG="$OPTARG"
        ;;
        h)  JELP=1
        ;;
        *)  JELP="wtf"
        ;;
    esac
done

shift $(($OPTIND - 1))

if [ -n "$JELP" ];
then
    echo "usage: $0 [-U <USRNAME>] [-l <MAXLAG>]"
    echo -e "\t-U\t\t user name (default: postgres)"
    echo -e "\t-l\t\t max lag in seconds (default: 18000 - 5 hours)"
    echo -e "\t-w\t\t warning lag in seconds (default: 14400 - 4 hours)"
    echo -e "\t-h\t\t show help"
    exit 1
fi

REPLAY_DATE=$(psql -U "${USERNAME}" -c 'select pg_last_xact_replay_timestamp();' -t | head -n1)

NOW_TS="$(date +%s)"
REPLAY_TS="$(date -d "${REPLAY_DATE}" '+%s')"

DIFF_TS="ERROR"

let DIFF_TS=NOW_TS-REPLAY_TS


if ! [[ $DIFF_TS =~ ^[0-9]+$ ]];
then
   echo "UNKNOWN: unable to process timestamps - check select pg_last_xact_replay_timestamp();"
   exit 3
fi

if [ "$DIFF_TS" -gt "${MAXLAG}" ];
then
  echo "CRITICAL - current lag is ${DIFF_TS} seconds - pg_last_xact_replay_timestamp is: ${REPLAY_DATE}"
  exit 2
elif [ "$DIFF_TS" -gt "${WARNINGLAG}" ];
then
  echo "WARNING - current lag is ${DIFF_TS} seconds - pg_last_xact_replay_timestamp is: ${REPLAY_DATE}"
  exit 1
else
  echo "OK - current lag is ${DIFF_TS} seconds - pg_last_xact_replay_timestamp is: ${REPLAY_DATE}"
  exit 0
fi
