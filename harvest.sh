#!/bin/bash
# Harvest: uses rsync to copy data from three support PCs at RMMF, and rearrange the directory structures
# to end up with a structure like /mnt/rmmf_staging/e123/NovaNanoSEM/datafiles...

# It also produces log files and status files (HTML) to allow monitoring.

# It is intended to be run every 5 minutes or so.


#TESTING=0

#set -e

MACHINES="NovaNanoSEM Quanta200 XL30";
ALLMACHINES="NovaNanoSEM Quanta200 XL30";

HOME="/usr/local/microtardis/harvest";                   # root location of various output files, scripts etc.
DIR_STAGING="/mnt/np_staging";                         # where files are copied to, for ingest into Tardis.
LOGAREA="/usr/local/microtardis/logs";                   # where to log to
OUTPUTTEMP="${LOGAREA}/current.log";
OUTPUTDAILY="${LOGAREA}/rsync`date +\%Y_\%m_\%d`.log";
OUTPUTSYMLK="${LOGAREA}/rsync_current.log";


if [ ${TESTING} ]; then
DIR_STAGING="${HOME}/mnt/rmmf_staging"
fi

RM="/bin/rm"
VERBOSE=1

# -v, --verbose                           increase verbosity
# -c, --checksum                          skip based on checksum, not mod-time & size
# -r, --recursive                         recurse into directories
# -l, --links                             copy symlinks as symlinks
# -t, --times                             preserve times
# -S, --sparse                            handle sparse files efficiently
# -h, --human-readable                    output numbers in a human-readable format
# --delete                                delete files that don't exist on sender
# --progress                              show progress during transfer
# --exclude                               don't copy junk files (like Windows thumbnails)

# --modify-window                         compares times with less accuracy (supposed to be good for Windows systems)
RSYNCOPTIONS="-rltSh --modify-window=2 --progress --exclude 'Thumbs.db'";

RSYNC="/usr/bin/rsync";
USERDIRSFILE="$HOME/tmp_userdirsfile.txt"

function summarylog {
echo "`date` $1" >> ${LOGAREA}/summary.log
}

function rsyncPC2HERE {
# Perform rsync and directory restructuring for one support PC.

MACHINE=$1;
unset MACHINEFOLDER
unset MACHINEIP
if [ $MACHINE == "NovaNanoSEM" ]; then
  MACHINEFOLDER="UserData"
  MACHINEIP="192.168.10.23"
elif [ $MACHINE == "Quanta200" ]; then
  MACHINEFOLDER="UserData"
  MACHINEIP="192.168.10.24"
elif [ $MACHINE == "XL30" ]; then
  MACHINEFOLDER="UserData"
  MACHINEIP="192.168.10.25"
else
  echo "Unknown machine: ${MACHINE}" 2>&1
  return 
fi


${RM} -f ${OUTPUTTEMP};

echo -e "\/n" > ${OUTPUTTEMP};
echo "${MACHINE}: Rsync starting at `/bin/date`" >> ${OUTPUTTEMP};

TIMERSTART=`date +%s`

rm -f ${USERDIRSFILE}

# Get list of user directories
if [ $VERBOSE ]; then echo "$MACHINE: Getting list of user directories." | tee -a ${OUTPUTTEMP} ; fi
# only copy directories with names like e1234, s0189 etc.
rsync --include='[eEsSzZxX][0-9]*/' --exclude='*' rsync://${MACHINEIP}/${MACHINEFOLDER} | awk 'FNR>1{print $5}' > ${USERDIRSFILE}

 
ERRORS=0
SUCCESSES=0
SUCCESSDIRS=""
# translate E123 to e123 in the process.
for USERDIR in `cat ${USERDIRSFILE}`; do
    USERDIRLOWER=`echo $USERDIR | awk '{print tolower($0)}'`
    mkdir -p ${DIR_STAGING}/${USERDIRLOWER}/${MACHINE};
    echo "$USERDIR -> $USERDIRLOWER"
    if [ $VERBOSE ]; then echo "$MACHINE/$USERDIR: Rsyncing ($MACHINEFOLDER/$USERDIR) to $DIR_STAGING/$USERDIRLOWER/$MACHINE"; fi
    rsync ${RSYNCOPTIONS} --log-file="${OUTPUTTEMP}" "rsync://${MACHINEIP}/${MACHINEFOLDER}/${USERDIR}/" "${DIR_STAGING}/${USERDIRLOWER}/${MACHINE}";
STATUS=$?
ELAPSEDTIME=`expr \`date +%s\` - ${TIMERSTART}`
if [ ${STATUS} -eq 0 ]; then
    if [ $VERBOSE ]; then    
        echo "$MACHINE/$USERDIR: Rsync stopped (successfully) at `/bin/date`" | tee -a ${OUTPUTTEMP};
    fi
    SUCCESSES=`expr ${SUCCESSES} + 1`
    SUCCESSDIRS="${SUCCESSDIRS} $USERDIRLOWER"
else
    echo "$MACHINE/$USERDIR: Rsync stopped (with error ${STATUS}) at `/bin/date`" | tee -a ${OUTPUTTEMP};
    ./set_status.sh ${MACHINE} down "Rsync stopped (with error ${STATUS}) at `/bin/date`"
    summarylog "(${ELAPSEDTIME}s) *** $MACHINE/$USERDIR: Rsync failed with error ${STATUS}."
    ERRORS=`expr ${ERRORS} + 1`
fi
done
rm -f ${USERDIRSFILE}


STATUS=$?;
ELAPSEDTIME=`expr \`date +%s\` - ${TIMERSTART}`

if [ ${STATUS} -eq 0 ]; then
    echo "$MACHINE: Rsync completed without errors at `/bin/date`" | tee -a ${OUTPUTTEMP};
    ./set_status.sh ${MACHINE} ok "${SUCCESSES} user directories transferred."
    summarylog "(${ELAPSEDTIME}s) ${MACHINE} rsync finished for ${SUCCESSES} user directories: ${SUCCESSDIRS}" 
else
    echo "$MACHINE: Rsync completed with ${ERRORS} errors and ${SUCCESSES} successes at `/bin/date`" | tee -a ${OUTPUTTEMP};
    summarylog "(${ELAPSEDTIME}s) *** Rsync for ${MACHINE} failed with error ${STATUS}. Errors: ${ERRORS}, successes: ${SUCCESSDIRS}"
fi

# Update symlink
/bin/cat ${OUTPUTTEMP} >> ${OUTPUTDAILY};
${RM} -f ${OUTPUTSYMLK};
/bin/ln -s ${OUTPUTDAILY} ${OUTPUTSYMLK};
${RM} -f ${OUTPUTTEMP};


} # finish rsync procedure

if test `find $HOME/harvest.pid -mmin +180`; then
    msg="Old harvest.pid file found. Probably the system was rebooted, or crashed or something. Deleting it and  carrying on";
    echo "$msg"
    summarylog "$msg"
    rm -f $HOME/harvest.pid
fi

if [ -e $HOME/harvest.pid ]; then
	echo "Harvest script already running - abort.";
        summarylog "Harvest script already running - abort."
	exit 1;
fi
cd ${HOME}
echo "Harvest commences at `date`" > $HOME/harvest.pid
echo ${OUTPUTTEMP}
summarylog "--- Harvest commences at `date`"

./domounts.sh >> ${OUTPUTTEMP}
for MACHINE in ${MACHINES}; do
    #  If machine is unreachable, don't try and sync.
    if [ -f "${MACHINE}_reachable.txt" ]; then
       rsyncPC2HERE ${MACHINE};
    fi
done

echo "Current dir sizes:" | tee -a $OUTPUTDAILY
pushd $DIR_STAGING; for X in `ls $DIR_STAGING`; do du -h -s "$X"; done | tee -a $OUTPUTDAILY; popd

./make_status_html.sh

${RM} -f $HOME/harvest.pid
