#!/bin/bash
# Check that all support PC mounts are ok, and mount them if not.
#MOUNT_DIR="/usr/local/microtardis/harvest/new/mnt/rmmf_supportpc";
PING="/bin/ping"

function domount {
    NETWORK_PATH=$1;
    HOST=$2;
    MOUNT_NAME=$3;

#OUT=/dev/null
#VERBOSE=1
#if [ $VERBOSE ]; then OUT = &1; fi

# We're not actually mounting atm.
#    if [ "`ls -A ${MOUNT_DIR}/${MOUNT_NAME}`" ]; then
#	    ./set_status.sh ${MOUNT_NAME} up "${MOUNT_NAME} already mounted - ok."
#        return 
#    fi
    echo -n "Mounting ${MOUNT_NAME}: ";
    rm -f "${MOUNT_NAME}_reachable.txt"
    # Ping first so we fail much faster if machine is down.
    ${PING}  -q -l 3 -c 1 -w 5 ${HOST} > /dev/null
    if [ $? -ne 0 ]; then
	   ./set_status.sh ${MOUNT_NAME} down "${MOUNT_NAME} machine (${HOST}) is unreachable."
           #./set_status.sh "${MOUNT_NAME}_rsync" down "${MOUNT_NAME} host unreachable, therefore rsync not attempted."
          return
    fi 
       # skipping the actual mount!
       #mount_smbfs -o rdonly "${NETWORK_PATH}" "${MOUNT_DIR}/${MOUNT_NAME}"
     echo "Ok"
     #./set_status.sh ${MOUNT_NAME} up "${MOUNT_NAME} is reachable."
     touch "${MOUNT_NAME}_reachable.txt"
     return
     echo "Skipping mount."      
     if [ $? -ne 0 ]; then
         ./set_status.sh ${MOUNT_NAME} down "Failed to mount ${MOUNT_NAME} even though host (${HOST}) is reachable."
     else
         ./set_status.sh ${MOUNT_NAME} up "Mounted ${MOUNT_NAME} as read-only."
     fi          
     
}
domount "//supervisor:supervisor@171.170.94.242" "171.170.94.242" "JEOL2100F"
domount "//supervisor:supervisor@192.168.10.25/Images" "192.168.10.25" "XL30"
domount "//supervisor:supervisor@192.168.10.24/Users%20Images" "192.168.10.24" "Quanta200"
domount "//supervisor:supervisor@192.168.10.23/SharedData" "192.168.10.23" "NovaNanoSEM"
