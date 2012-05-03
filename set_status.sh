#!/bin/sh
NCSA_COMMAND_FILE="ncsa_cmd_file.txt"

die () {
    echo >&2 "$@"
    exit 1
}

if [ ! "$#" -eq 3 ]; then echo "Usage: set_status <thing> <status> <message>"; exit; fi

THING=$1
STATUS=$2
MESSAGE=$3
unset WASDOWN
if [ -e ${THING}_status_down.txt ]; then
	WASDOWN=1
fi
rm -f ${THING}_status_*.txt
echo "${MESSAGE}" > ${THING}_status_${STATUS}.txt

# Write to format understood by Nagios NCSA. (As of Jan 2012 Nagios is not actually installed...)
EPOCHSECONDS=`date +%s`
STATUSCODE=3 # unknown
if [ ${STATUS} == "ok" ]; then
	STATUSCODE=0
elif [ ${STATUS} == "warning" ]; then
	STATUSCODE=1
elif [ ${STATUS} == "down" ]; then
	STATUSCODE=2
fi
echo "[${EPOCHSECONDS}] PROCESS_SERVICE_CHECK_RESULT;ka1;${THING};${STATUSCODE};${MESSAGE}" >> ${NCSA_COMMAND_FILE} 

if [ ${STATUS} == "down" ] && [ ! ${WASDOWN} ]; then
	# Something is down that wasn't down before - email someone.
    echo >&2 "$1 is $2: $3"
    echo "$3\n" | mail -s "[MicroTardis] $1 is $2" e88789@rmit.edu.au
fi
./make_status_html.sh
