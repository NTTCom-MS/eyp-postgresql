#!/bin/bash
# puppet managed file

PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

USERNAME=postgres
DATADIR="/var/lib/pgsql"

while getopts 'U:d:w:h' OPT;
do
    case $OPT in
        U)  USERNAME="$OPTARG"
        ;;
        d)  DATADIR="$OPTARG"
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
    echo "usage: $0 [-U <USRNAME>] [-d <DATADIR>]"
    echo -e "\t-U\t\t user name (default: postgres)"
    echo -e "\t-d\t\t datadir (default: /var/lib/pgsql)"
    echo -e "\t-h\t\t show help"
    exit 1
fi

if [[ "$(ls -ld "${DATADIR}" | awk '{ print $1 }' | sed 's/[^a-z]//g')" != "drwx" ]];
then
  echo "CRITICAL: datadir mode is not 0700";
  exit 2
fi

ID_POSTGRES="$(id -u ${USERNAME})"

NOT_POSTGRES_FILES="$(find "${DATADIR}" -type f -not -uid "${ID_POSTGRES}" | wc -l)"
if [ "${NOT_POSTGRES_FILES}" -ne 0 ];
then
  echo "CRITICAL: found files not owned by postgres"
  exit 2
else
  echo "OK: datadir in compliance"
  exit 0
fi
