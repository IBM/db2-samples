#!/usr/bin/ksh
#---------------------------------------------------------------------------
# (c) Copyright IBM Corp. 2012 All rights reserved.
#
# Script Name: acs_ibmstor.sh
#
# Purpose: implement the scripted interface for DB2 ACS using IBM System Storage DS4800 and Storage Manager.
# This script is called by DB2 to make snapshot backups of paths provided by DB2.
# 
# Please see developerwork article for details: https://www.ibm.com/developerworks/data/library/techarticle/dm-1506scriptdb2copy4/dm-1506scriptdb2copy4-pdf.pdf
#
# The following sample of source code ("Sample") is owned by International
# Business Machines Corporation or one of its subsidiaries ("IBM") and is
# copyrighted and licensed, not sold. You may use, copy, modify, and
# distribute the Sample in any form without payment to IBM, for the purpose of
# assisting you in the development of your applications.
#
# The Sample code is provided to you on an "AS IS" basis, without warranty of
# any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
# not allow for the exclusion or limitation of implied warranties, so the above
# limitations or exclusions may not apply to you. IBM shall not be liable for
# any damages you suffer as a result of using, copying, modifying or
# distributing the Sample, even if IBM has been advised of the possibility of
# such damages.
#---------------------------------------------------------------------------

# print out debug info
# set X for Debug, 
# DEBUG=X

# IBM Storage Manager path and exes
SMINST="/usr/SMclient"
SMBIN=$SMINST
SMCLI="$SMBIN/SMcli"
# SM_HOST="10.17.200.86"
SM_HOST="10.17.200.73 10.17.200.86"
SM_PASSWORD="dashb0ard"

MOUNT=/usr/sbin/mount
UMOUNT=/usr/sbin/umount
LSPV=/usr/sbin/lspv
LSDEV=/usr/sbin/lsdev
LSVG=/usr/sbin/lsvg
VARYOFFVG=/usr/sbin/varyoffvg
VARYONVG=/usr/sbin/varyonvg
EXPORTVG=/usr/sbin/exportvg
RECREATEVG=/usr/sbin/recreatevg
GREP=/usr/bin/grep

# Log file
LOGPREFIX="storage_snap"
LOGPOSTFIX="AMT"
LOG=/tmp/${LOGPREFIX}_${LOGPOSTFIX}.log

# Protocol Backup directory
PROT_BKP_DIR="/db2/db2amt/scriptACS/prot_bkp/"
# Mapping file for FlashCopy Logical Drives
FC_MAPPING_FILE="/db2/db2amt/fc_mapping.txt"

# User defined entries in the protocol file
USER_DB2FS="USER_DB2FS"
USER_FC="USER_FC"

# Tempfile names
TMPDIR=/tmp
TMP=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}.tmp
TMP_=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}.tmp_
BGND_RC_FILE=${TMPDIR}/${LOGPREFIX}_BGND_RC_${LOGPOSTFIX}.tmp
SM_CMD_OUT=${TMPDIR}/${LOGPREFIX}_SM_CMD_OUT_${LOGPOSTFIX}.tmp
SM_CMD_ERR=${TMPDIR}/${LOGPREFIX}_SM_CMD_ERR_${LOGPOSTFIX}.tmp
FILESYSTEMS=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}_fs.tmp
PHYS_VOLUMES=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}_hdisk.tmp
VOLGRP=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}_volgrp.tmp

# Constants
SM_SNAP_PREFIX="snap_"
SM_SNAP_PREFIX_DATA="snap_DATA_"
SM_SNAP_PREFIX_LOG="snap_LOG_"
D="Done."
S="Starting"
D_PATH="DATAPATH_"
L_PATH="LOGPATH_"
DB2BACKUP_LOGS="DB2BACKUP_LOGS"

# Returncode
RC_PREP_ERROR=40
RC_SNAP_ERROR=50
RC_VFY_ERROR=60
RC_RBCK_ERROR=70
RC_STORE_METADATA_ERROR=80
RC_REST_ERROR=90
RC_DELETE_ERROR=100
RC_EXPORTVG_ERROR=110
RC_RECREATEVG_ERROR=120
RC_BUILD_VGLIST_ERROR=130
RC_MAPPING_ERROR=140
RC_TIMEOUT_ERROR=150

# Variables
CMD=""
CMD_OUT=""
TIMESTAMP=""
OBJ_HOST=""

##################
function if_error
##################
# check return code passed to function
# if rc not equal 0 then print error msg, finalize log and exit with latest rc
{  
   RC=$?
   if [[ $RC -ne 0 ]]
   then 
      write_log "$1 RC=$RC" 
      finalize_log
      exit $RC
   fi
}

##################
function debug_info
##################
# write into log file if DEBUG=X
# 
{  
   if [[ $DEBUG == "X" ]]
   then 
      write_log "DEBUG: $1" 
   fi
}

##################
function  check_config_file
##################
# checks if the provided config file is a file
{
   if [ ! -f $config ]
   then 
      write_log "   Configuration file: $config is not a file" 
      RC=1   
   fi
   return $RC
}

##################
function init_log
##################
# init the log file
{
    print "=====================================" >> $LOG
    print "== Starting customer script =========" >> $LOG
    print "=====================================" >> $LOG
}

##################
function finalize_log
##################
# finalize the log file
{
    print "=====================================" >> $LOG
    print "== Ending customer skript ===========" >> $LOG
    print "=====================================" >> $LOG
}

##################
function write_log
##################
# writes messages to the log file
{
    print "$*" >> $LOG
}

##################
function storeSetting
##################
# writes customer option to protocol file
{
    print "$*" >> $config
}

##################
function getSetting
##################
# gets options from protocol file
{
   useConfig=$config
   if [ "$3" != "" ]
   then
      useConfig=$3
   fi
   cmd="awk -F= '/^${1}/ { print \$2 }' $useConfig | head -1"
   _setting=`eval $cmd`
   if [ "$2" != "" -a "$_setting" = "" ]
   then
      _setting=$2
   fi
}


function cleanup_tempfiles
##################
# cleans up temp files
{
   debug_info "entry: cleanup_tempfiles"
   if [[ $DEBUG == "X" ]]
   then
      debug_info "In Debug mode do not remove temp files"
      debug_info " $TMP $TMP_ $FILESYSTEMS"
   else
      CMD="rm $TMP $TMP_ $FILESYSTEMS $BGND_RC_FILE $SM_CMD_OUT $SM_CMD_ERR >> $LOG 2>&1"
      write_log $S "cleanup temp files ...."
      write_log "   $CMD"
      eval $CMD
      if [[ $? -ne 0 ]]
      then
         write_log "   WARNING: the command $CMD failed."
      fi
      write_log $D
   fi
   debug_info "exit: cleanup_tempfiles"
}

function timeout_pid
##################
# kills pid after timeout
# parameter $1 : timeout period in sec
# parameter $2 : PID to watch 
{
   debug_info "entry: timeout_pid"

   debug_info "data: TIMEOUT=$1 "
   debug_info "data: WATCH_PID=$2 "
   TIMEOUT=$1
   WATCH_PID=$2
   DURATION=0
   SLEEPTIME=2
   IS_RUNNING=0
   RC=0

   # check if process is running
   ps -fp $WATCH_PID > /dev/null
   if [[ $? -eq 0 ]]; then IS_RUNNING=true; else IS_RUNNING=false; fi

   # wait for process to complete or run into timeout
   debug_info "data: entering while loop (sleep $SLEEPTIME)"
   while $IS_RUNNING
   do
      debug_info "data: PID: $WATCH_PID IS_RUNNING: $IS_RUNNING DURATION: $DURATION TIMEOUT: $TIMEOUT"
      let 'DURATION = DURATION + SLEEPTIME'
      sleep $SLEEPTIME

      # check if still running after sleep time
      ps -fp $WATCH_PID > /dev/null
      if [[ $? -eq 0 ]]; then IS_RUNNING=true; else IS_RUNNING=false; fi

      # if TIMEOUT is exceeded AND process still runs -> kill it
      if  [[ $DURATION -gt $TIMEOUT ]] && [[ $IS_RUNNING == "true" ]]
      then
         write_log  "   TIMEOUT: $TIMEOUT sec reached. PID $WATCH_PID will be killed..."
         kill -9 $WATCH_PID; RC=$?
         if [[ $RC -eq 0 ]]
         then
            write_log "   ... PID $WATCH_PID was killed."
            IS_RUNNING=false
	    RC=$RC_TIMEOUT_ERROR
         else
            write_log "   ... Error killing PID $WATCH_PID. "
	    return $RC
	 fi
      fi
   done
   debug_info "data: exiting while loop"

   return $RC
   debug_info "exit: timeout_pid"
}

##################
function prepare_delete_command
##################
# checks if the delete command exists
# currently not used
{ 
   debug_info "entry: prepare_delete_command"
   write_log $S "checking delete commands ...."
   
   write_log $D
   debug_info "exit: prepare_delete_command"
   return $RC
}

##################
function prepare_snapshot_command
##################
# checks if the snapshot command exists
{ 
   debug_info "entry: prepare_snapshot_command"
   write_log "   checking snapshot commands ...."
   RC=0

   debug_info "data: check if $SMCLI exits."
   if [[ -e $SMCLI ]]
   then
      write_log "   $SMCLI exists."
   else
      write_log "   $SMCLI does NOT exist."
      RC=$RC_PREP_ERROR
   fi

   debug_info "exit: prepare_snapshot_command"
   return $RC
}

##################
function mount_filesystems
##################
# mounts the filesystems in file $FILESYSTEMS
#
{
   debug_info "entry: mount_filesystems"
   write_log "   mounting filesystems ... "

   TMP_RC=0 

   while read x
   do
      # set parm1 for the mount command
      PARM1=`echo $x | awk '{print $3}'`
      
      CMD="sudo $MOUNT"
      write_log "   $CMD ${PARM1}"
      eval $CMD ${PARM1} >> $LOG 2>&1
      RC=$?

      if [[ $RC -ne 0 ]]
      then
           # increment counter, if command did not return 0
           let "TMP_RC = TMP_RC + 1"
           write_log "   **** ERROR: mount of this filesystem failed."
      fi
   done < $FILESYSTEMS

   if [[ $TMP_RC -eq 0 ]]
   then
       write_log "   All filesystem mounted. RC=0."
       RC=0
   else
       write_log "   **** ERROR: at least one filesystem was not mounted. RC=$RC_REST_ERROR."
       RC=$RC_REST_ERROR
   fi

   debug_info "exit: mount_filesystems"
   return $RC
}


##################
function umount_filesystems 
##################
# umounts the filesystems in file $FILESYSTEMS
# before executing umount, check if filesystem is mounted 
#
{
   debug_info "entry: umount_filesystems"
   write_log "   unmount filesystems ... "
   TMP_RC=0 

   debug_info "data: sort (reverse) list of filesystems to workaround dependecies"
   CMD="mv ${FILESYSTEMS} $TMP"
   debug_info "data: executing $CMD"
   eval $CMD 
   if_error "Error: $CMD failed"

   CMD="sort -rk2 $TMP"
   debug_info "data: executing $CMD"
   eval $CMD > $FILESYSTEMS
   if_error "Error: $CMD failed"

   while read x
   do
      # extract devicename for filesystem from $FILESYSTEMS
      PARM1=`echo $x | awk '{print $3}'`

      # check if FS is mounted
      CMD="$MOUNT | $GREP"
      debug_info "data: $CMD ${PARM1}"
      eval $CMD ${PARM1} 2>> $LOG 
      # eval $CMD ${PARM1} >> $LOG 2>&1
      RC=$?
      if [[ $RC -eq 1 ]] then ISMOUNTED="false"; else ISMOUNTED="true"; fi

      debug_info "data: Filesystem ${PARM1} -- ISMOUNTED=$ISMOUNTED"
      if [[ $ISMOUNTED == "true" ]]
      then
         CMD="sudo $UMOUNT"
         write_log "   $CMD ${PARM1}"
         eval $CMD ${PARM1} >> $LOG 2>&1
         RC=$?

         if [[ $RC -ne 0 ]]
         then
            # increment counter, if command did not return 0
            let "TMP_RC = TMP_RC + 1"
            write_log "   ... umount of this filesystem failed."
         fi
      fi 
   done < $FILESYSTEMS

   if [[ $TMP_RC -eq 0 ]]
   then
       write_log "   All filesystem umounted. RC=0."
       RC=0
   else
       write_log "   **** ERROR: at least one filesystem was not umounted. RC=$RC_REST_ERROR."
       RC=$RC_REST_ERROR
   fi
   
   debug_info "exit: umount_filesystems"
   return $RC
}

##################
function export_vgs 
##################
# varyoff and export all Volume Groups in $VOLGRP
# (ONLY if list $VOLGRP exists) 
# if vg exists, vary off and exportvg
# looks in $FlashCopyTarget for the asssociated backup hdisks and AIX vg names
{
   debug_info "entry: export_vgs"

   TMP_RC=0
   VG_NAME=""

   if [[ -f $VOLGRP ]]
   then
      while read VG_NAME
      do
         # only if vg_name currently exists, varyoffvg and exportvg
         write_log "   varyoff and export Volume Groups..."
         debug_info: "data: lsvg $VG_NAME"
         CMD="$LSVG $VG_NAME"
         eval $CMD > /dev/null 2>&1
         RC=$?
         if [[ RC -eq 0 ]]
         then
            debug_info: "data: varyoffvg $VG_NAME"
            CMD="sudo $VARYOFFVG $VG_NAME"
            debug_info "data: $CMD"
            eval $CMD >> $LOG 2>&1
            RC=$?
            if [[ RC -eq 0 ]]
            then
               CMD="sudo $EXPORTVG $VG_NAME"
               debug_info "data: $CMD "
               eval $CMD >> $LOG 2>&1
               RC=$?
               # if exportvg fails incr error counter
               if [[ RC -ne 0 ]]
   	       then
   	          let "TMP_RC = TMP_RC + 1"
	          write_log "   $CMD failed"
               else
	          write_log "   $VG_NAME complete"
	       fi
            else
               # if varyoffvg fails incr error counter
       	       let "TMP_RC = TMP_RC + 1"
               write_log "  $CMD failed"
            fi
         fi
      done < $VOLGRP
   fi

   # exit if any of the vgs in the list cannot be varied off or exported
   # investigate the reason for this manually
   if [[ $TMP_RC -eq 0 ]]
   then
       write_log "   All Volume Groups varied off and exported. RC=0."
       RC=0
   else
       write_log "   **** ERROR: at least one Volume group was not exported. RC=$RC_EXPORTVG_ERROR."
       write_log "   **** Check manually if there are open filesystems on this Volume Group(s)."
       return $RC_EXPORTVG_ERROR
   fi
   debug_info "exit: export_vgs"
}

##################
function  recreate_vgs
##################
# read from list $VOLGRP which AIX Volume Group to recreate
# read from $FlashCopyTarget which hdisk belongs to which VG
# eg. recreatevg -y sapAMT3vg -p -Y NA -L / hdisk6
{
   debug_info "entry: recreate_vgs"
   TMP_RC=0
   while read VG_NAME
   do
      # get all backup hdisks for one Volumegroup from $FlashCopyTarget
      # all hdisks must be in one space separated list created by the awk printf command
      CMD="awk -vVG_NAME=$VG_NAME '\$5 == \"$VG_NAME\" { printf \"%s\", \$3; printf \"%c\", \" \" }' $FlashCopyTarget"
      debug_info "data: command to create string of hdisks for recreatevg cmd: $CMD"
      LOCAL_HDISK_BKP=`eval $CMD`
      debug_info "data: hdisk list: $LOCAL_HDISK_BKP"
     
      CMD="sudo $RECREATEVG -y $VG_NAME -p -Y NA -L / $LOCAL_HDISK_BKP"
      debug_info "data: recreatevg: $CMD"
      write_log "   Recreating VG : $CMD"
      eval $CMD >> $LOG 2>&1
      RC=$?
      if [[ RC -ne 0 ]]
      then
         let "TMP_RC = TMP_RC + 1"         
	 write_log "  $CMD failed"
      fi
   done < $VOLGRP

   if [[ TMP_RC -eq 0 ]]
   then
      write_log "   All Volumegroups recreated successfully."
   else
      write_log "   ERROR: At least one Volumegroup  could not be recreated."
      return $RC_RECREATEVG_ERROR
   fi
   debug_info "exit: recreate_vgs"
}

##################
function  build_vglist
##################
# build the list of AIX Volume Groups to vary off and export
# reads in each hdisk from $PHYS_VOLUMES,
# looks in protocol file for its Volume Group (key=USER_FC)
# writes out file $VOLGRP
{
   debug_info "entry: build_vglist"
   # clear tmp file if exists 
   if [[ -f $VOLGRP ]]; then CMD="rm $VOLGRP"; eval $CMD; fi
   
   debug_info "data: restoreConfig= $restoreConfig"
 
   # build the list of vgs to vary off and export, loop for each hdisk
   while read x
   do
      debug_info "data: reading line $x" 
      # read original hdisk name from $PHYS_VOLUMES
      LOCAL_HDISK_ORI=`echo $x | awk '{print $2}'`

      # get volume group name for each hdisk from protocol file 
      # keyword=USER_FC,  3rd field = hdisk, 6th field = volumegroup
      CMD="awk -F\"=| \" '\$1 == \"$USER_FC\" && \$3 == \"$LOCAL_HDISK_ORI\" { print \$6}' "
      debug_info "data: VG_NAME=\`eval $CMD $restoreConfig\`"
      VG_NAME=`eval $CMD $restoreConfig`

      # exit if VG_NAME for current LOCAL_HDISK_ORI is not found in protocol file
      # If it happens, it means the protocol file incorrect.
      # else append the VG to the list $VOLGRP
      if [[ -z $VG_NAME ]]
      then
        write_log "   ****  ERROR: No Volumegroup name found for $LOCAL_HDISK_ORI in $restoreConfig."
	write_log "   ****  key=$USER_FC. Terminating $0."
        return $RC_BUILD_VGLIST_ERROR
      else
        debug_info "data:  Volume Group for $LOCAL_HDISK_ORI is $VG_NAME."
	write_log "   Adding Volume Group $VG_NAME to list $VOLGRP."
        echo $VG_NAME >> $VOLGRP
        if_error "Error: $CMD failed"
      fi
   done < $PHYS_VOLUMES
   debug_info "exit: build_vglist"
}

##################
function  restore_pvs
##################
# restore the hdisks (physical volumes = pvs) from flashcopies
{
   debug_info "entry: restore_pvs"
   write_log "   Restoring pvs in AIX Volume Group ...."
   
   # build the list of vgs to vary off and export
   debug_info "data: restoreConfig $restoreConfig"
   build_vglist
   if_error "Error: build_vglist failed"
 
   # varyoff and export volume groups
   export_vgs
   if_error "Error: export_vgs failed"

   # recreate the vg
   recreate_vgs
   if_error "Error: recreate_vgs failed"

   debug_info "exit: restore_pvs"
}

##################
function get_used_filesystems_for_restore
##################
# get the filesystems to be restored from protocol file
# and stores them in $FILESYSTEMS
{
   debug_info "entry: get_used_filesystems_for_restore"
   write_log "   find the filesystems for restore... "
   RC=0
  
   getSetting "OBJ_ID"
   result_file_no=$_setting
   key="RESULT_"${result_file_no}"_FILE"
   getSetting $key
   restoreConfig=$_setting

   # grep for all snapshots first (data and log)
   write_log "   looking in $restoreConfig"
   write_log "   for (keyword=$USER_DB2FS) and and write them to $FILESYSTEMS "
  
   CMD="awk -F\"=| \" '/^USER_DB2FS/ {print \$2 \" \" \$3 \" \" \$4}' $restoreConfig" 
   debug_info "data: executing $CMD"
   eval $CMD > $FILESYSTEMS
   if_error "Error: $CMD failed"

   # if option ACTION = DB2ACS_ACTION_READ_BY_OBJECT -> inlcude log in restore
   # if option ACTION = DB2ACS_ACTION_READ_BY_GROUP -> exlcude log from restore
   debug_info "data:  grep parameter ACTION from $restoreConfig"
   getSetting "ACTION"
   WHAT_TODO_WITH_LOGS=$_setting
   debug_info "data:  parameter ACTION is $WHAT_TODO_WITH_LOGS"

   if [[ $WHAT_TODO_WITH_LOGS == "DB2ACS_ACTION_READ_BY_GROUP" ]]
   then
       # remove the snapped log volumes from the list in $FILESYSTEMS
       write_log "   LOG volumes are not restored, option ACTION = $WHAT_TODO_WITH_LOGS"
       debug_info "data:  removing line with ${SM_SNAP_PREFIX_LOG} from $FILESYSTEMS"

       CMD="grep -v ${SM_SNAP_PREFIX_LOG} $FILESYSTEMS"
       debug_info "data: $CMD"
       eval $CMD > $TMP
       if_error "Error: $CMD failed"

       CMD="mv $TMP $FILESYSTEMS"
       debug_info "data: $CMD"
       eval $CMD 
       if_error "Error: $CMD failed"
   fi

   debug_info "exit: get_used_filesystems_for_restore"
}

##################
function get_used_pvs_for_restore 
##################
# get the physical volumes (hdisks) to be restored from protocol file
# and write them to file $PHYS_VOLUMES
{
   debug_info "entry: get_used_pvs_for_restore"
   write_log "   Looking for key $USER_FC in $restoreConfig"

   # first look for all backup hdisks (data and log), later remove log if required
   write_log "   and write them to $PHYS_VOLUMES"
  
   CMD="awk -F\"=| \" '\$1 == \"$USER_FC\" {print \$2 \" \" \$3 \" \" \$4}' $restoreConfig" 
   debug_info "data: executing $CMD"
   # eval $CMD > $FILESYSTEMS
   eval $CMD > $PHYS_VOLUMES
   if_error "Error: $CMD failed"

   # if option ACTION = DB2ACS_ACTION_READ_BY_OBJECT -> inlcude log in restore
   # if option ACTION = DB2ACS_ACTION_READ_BY_GROUP -> exlcude log from restore
   debug_info "data:  grep parameter ACTION from $restoreConfig"
   getSetting "ACTION"
   WHAT_TODO_WITH_LOGS=$_setting
   debug_info "data:  parameter ACTION is $WHAT_TODO_WITH_LOGS"

   if [[ $WHAT_TODO_WITH_LOGS == "DB2ACS_ACTION_READ_BY_GROUP" ]]
   then
       # remove the hdisks with logs from the list in $PHYS_VOLUMES
       write_log "   LOG volumes are not restored, option ACTION = $WHAT_TODO_WITH_LOGS"
       debug_info "data:  removing line with ${SM_SNAP_PREFIX_LOG} from $PHYS_VOLUMES"

       CMD="grep -v ${SM_SNAP_PREFIX_LOG} $PHYS_VOLUMES"
       debug_info "data: $CMD"
       eval $CMD > $TMP
       if_error "Error: $CMD failed"

       CMD="mv $TMP $PHYS_VOLUMES"
       debug_info "data: $CMD"
       eval $CMD 
       if_error "Error: $CMD failed"
   fi
   debug_info "exit: get_used_pvs_for_restore"
}

##################
function get_used_pvs_for_backup
##################
# creates a list of all used AIX physical volumes to be backuped up
# reads filesystem names from $FILESYSTEMS
# determines the used hdisks for each filesystem
# and writes them to file $PHYS_VOLUMES
{
   debug_info "entry: get_used_pvs_for_backup"
   RC=0
   write_log "   Reading filesystems from $FILESYSTEMS..."

   # delete $TMP before using it
   debug_info "data: remove file $TMP"
   CMD="rm $TMP"
   eval $CMD
   if_error "Error: $CMD failed"

   debug_info "data: reading from $FILESYSTEMS"

   while read x
   do
       # parse df -M output with awk to get device names: 
       #   if first character in first field is a "/" -> means it a local filesystem
       #   if not we assume it is as a NFS filesystem (host:/fs1)
       #   before output, substitute substring "/dev/" with ""
       type=`echo $x | awk '{print $1}'`
       fsname=`echo $x | awk '{print $2}'`

       CMD="df -M $fsname | awk '\$1 ~ /^\// { sub(/\/dev\//,\"\",\$1); print \$1 }'"
       debug_info "data: CMD: $CMD"
       device=`eval $CMD`
       if_error "Error: $CMD failed"
       debug_info "data: TYPE/DEVICE: $type / $device"
       
       # get list of pvs for logical volumes
       CMD="/usr/sbin/lslv -l $device | awk -v type=$type '\$1 ~ /^hdisk/ {print type \" \" \$1 }'"
       debug_info "data: CMD: $CMD"
       eval $CMD >> $TMP
       if_error "Error: $CMD failed"
       debug_info "data: writing the hdisks to $TMP"

   done < $FILESYSTEMS
   
   if_error "Error: reading or writing $FILESYSTEMS or $TMP"
   
   debug_info "data: eliminating duplicates in $TMP "

   CMD="sort -u $TMP" 
   eval $CMD > $PHYS_VOLUMES
   if_error "Error: $CMD failed"

   # check for duplicate hdisks, if a duplicate is found, set RC.
   # this reveals hdisks with both DATA and LOG files
   debug_info "data: check for DATA and LOG not separated"

   awk '{print $2}' $PHYS_VOLUMES | sort -u | while read line
   do
      debug_info "data: searching for $line"
      if [[ `grep -c $line $PHYS_VOLUMES` -ne 1 ]]
      then
         write_log "    ERROR: $line: contains DATA and LOG files"
         write_log "    ERROR: setting RC=$RC_PREP_ERROR"
         RC=$RC_PREP_ERROR
      fi
   done

   write_log "   Storing local hdisks for snapshot in $PHYS_VOLUMES "
   debug_info "exit: get_used_pvs_for_backup. RC=$RC"
   return $RC
}


##################
function get_used_filesystems_for_backup
##################
# creates a list of filesystems to backup
# and writes them to file $FILESYSTEMS
# $FILESYSTEMS has 2 columns: first is identifier DATA or LOG 
# second is filesystem name (not mount point)
{
   debug_info "entry: get_used_filesystems_for_backup"

   # look for all entries in $config starting with DATAPATH_ 
   # label each line with DATA, write to file $TMP
   CMD="awk -F= '/^${D_PATH}/ {print  \"${SM_SNAP_PREFIX_DATA} \" \$2}' $config"

   write_log "   Retrieving db and storage paths from protocol file..." 
   write_log "   writing them to $TMP" 
   debug_info "data: executing $CMD > $TMP"
   eval $CMD > $TMP
   if_error "Error: $CMD failed"
   write_log $D

   # if logs must be included , then append the file by the log paths
   # get setting from config file (DB2BACKUP_LOGS) 
   debug_info "data:  grep parameter DB2BACKUP_LOGS from $config"
   getSetting $DB2BACKUP_LOGS
   WHAT_TODO_WITH_LOGS=$_setting
    
   debug_info "data:  WHAT_TODO_WITH_LOGS: $WHAT_TODO_WITH_LOGS"
   debug_info "data:  protocolfile $config"

   if [[ $WHAT_TODO_WITH_LOGS == "INCLUDE" ]] 
   then
      debug_info "data: append log volumes"
      # look for lines starting with LOGPATH_ from config file
      # label each line with LOG, write to file $TMP
      CMD="awk -F= '/^${L_PATH}/ {print \"${SM_SNAP_PREFIX_LOG} \" \$2}' $config"
   
      write_log $S "Retrieving log paths from protocol file..." 
      write_log "   appending them to $TMP" 
      debug_info "data: executing $CMD >> $TMP"
      eval $CMD >> $TMP
      if_error "Error: $CMD failed"
      write_log $D
   fi

   # read the DB2 path names from file $TMP and extract the filesystem name
   # write the filesystm names to file $TMP_
   # no error checking here, we trust in what is delivered by the DB 
   debug_info "data: reading from $TMP"
   while read x
   do 
       TYPE=`echo $x | awk '{print $1}'`
       FS_PATH=`echo $x | awk '{print $2}'`
       debug_info "data: filessystemname= df -M $FS_PATH | awk '\$2 ~ /^\// { print \$1 }'"
       DEVICE=`df -M $FS_PATH | awk '$2 ~ /^\// { print $1 }'`
       FS=`df -M  $FS_PATH | awk '$2 ~ /^\// { print $2 }'`
       echo "$TYPE $DEVICE $FS" 
   done < $TMP > $TMP_
   
   if_error "Error: reading or writing $TMP or $TMP_"
   
   debug_info "data: writing to $TMP_"
   # remove duplicate filesystem entries resulting from db2 query on paths
   # a filesystem typically holds many directories and paths
   # use sort -u to remove duplicates and save in file $FILESYSTEMS
   
   debug_info "data: eliminating duplicates in $TMP_ "
   CMD="sort -u $TMP_" 
   eval $CMD > $FILESYSTEMS
   if_error "Error: $CMD failed"
   debug_info "data: storing filesystem for snapshot in $FILESYSTEMS "

   # save the filesystem also in the protocol file. This is mandatory for restore.
   debug_info "data: storing filesystems in current protocol file"
   debug_info "data: $config"
  
   while read x
   do
      TYPE=`echo $x | awk '{print $1}'`
      DEVICE=`echo $x | awk '{print $2}'`
      MOUNTPOINT=`echo $x | awk '{print $3}'`
      debug_info "data: $USER_DB2FS=$TYPE $MOUNTPOINT $DEVICE"
      storeSetting "$USER_DB2FS=$TYPE $MOUNTPOINT $DEVICE"
   done < $FILESYSTEMS

   debug_info "exit: get_used_filesystems_for_backup"
}


##################
function check_hdisks_available
##################
# reads in the list of local hdisks used for restore.
# The hdisks must be in status "Available" AND NOT in use in any Volume Group
# If they are in a VG and filesystems are mounted, contents
# will be deleted by the drop db command preceeding the next call of the script (doRestore)
{
   debug_info "entry: check_hdisks_available"
   write_log "   Checking availability of target hdisks" 
   RC=0 
   TMP_RC=0
   LOCAL_HDISK=""

   debug_info "data: reading from file $FlashCopyTarget" 
   while read x
   do 
      # ignore lines starting with # or empty lines
      # third column should be the local hdisk for restore
      debug_info "data: Now processing line: $x"
      FIRST_COLUMN=`echo $x | awk '{ print $1 }' `

      if  ! [[ $FIRST_COLUMN == "#" || $FIRST_COLUMN == "" ]]
      then
         debug_info "data: echo $x | awk '{ print \$3 }'"
         CMD="echo $x | awk '{ print \$3 }' "
         LOCAL_HDISK=`eval $CMD`

         debug_info "data: checking if local hdisk $LOCAL_HDISK is available ..." 
         debug_info "data: $LSDEV -l $LOCAL_HDISK | awk ' { print \$2 }'"

	 # get the status of the LOCAL_HDISK with lsdev command 
         CMD="$LSDEV -l $LOCAL_HDISK | awk '{ print \$2 }' "
         LOCAL_HDISK_STATUS=`eval $CMD`

	 # get the Volume Group name of the LOCAL_HDISK with lspv command 
         CMD="$LSPV ${LOCAL_HDISK} | awk -F: '/VOLUME GROUP/ { sub(/ */,\"\", \$3); print \$3 }'"
	 LOCAL_VOLGRP=`eval $CMD`
	
	 # if LOCAL_HDISK is Available and NOT assigned to a Volume Group, continue
	 # else increase error counter TMP_RC
         if [[ $LOCAL_HDISK_STATUS == "Available"  ]] && [[ -z $LOCAL_VOLGRP ]]
         then
            write_log "   $LOCAL_HDISK: can be used for restore"
         else
            write_log "   $LOCAL_HDISK: can NOT be used. State is not \"Available\" OR is used in VG $LOCAL_VOLGRP" 
            let "TMP_RC = TMP_RC + 1"
         fi
      fi
      
   done < $FlashCopyTarget

   debug_info "data: TMP_RC= $TMP_RC"
   debug_info "data: LOCAL_HDISK= $LOCAL_HDISK"
        
   # return error if error counter TMP_RC is set or LOCAL_HDISK does not exist
   if [[ $TMP_RC -ne 0 || LOCAL_HDISK == "" ]]
   then
       write_log "   **** ERROR:  At least one local target hdisk can not be used"
       write_log "   **** ERROR:  or no local hdisk was provided in $FlashCopyTarget. RC: $RC_PREP_ERROR"
       RC=$RC_PREP_ERROR
   else
       write_log "   All local target hdisks are available. Setting RC: 0."
       RC=0
   fi
  
   debug_info "exit: check_hdisks_available"
   return $RC
}


##################
function doPrepare
##################
# runs preparation for each script action (snapshot, restore. delete)
{
   debug_info "entry: doPrepare"

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   debug_info "data: checking the config file"
   check_config_file
   if_error "Error:  check_config_file."

   write_log "   Using protocol file: $config"

   getSetting "OPERATION"
   operation=$_setting
     
   write_log "   preparation for $operation ..."

   case $operation in 
      "SNAPSHOT")
         # prepare for action snapshot
         # check needed commands
         prepare_snapshot_command
         if_error "Error:  prepare_snapshot_command failed."

         # get the filesystems and store them in file $FILESYSTEMS 
         get_used_filesystems_for_backup
     
         # get the used pvs for backup and store them in file $PHYS_VOLUMES
         get_used_pvs_for_backup
         if_error "Error:  get_used_pvs_for_backup failed."
         ;;
      "RESTORE")
         # prepare for action restore 
         # check needed commands
         prepare_snapshot_command
         if_error "Error:  prepare_snapshot_command failed."
         
         # check if target local hdisks are available
         check_hdisks_available
         if_error "Error:  check_hdisks_available failed."

         # copy backup protocol files into place if the repository is empty
         # get_used_filesystems_for_restore, umount, restore, mount in doRestore function
         ;;
      "DELETE")
         # prepare for deletion of snapshot images
         # check needed commands, currently not used
         ;;
       *)
         # default
         write_log "   Nothing specific to be prepared."
         ;;
   esac

   write_log $D

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."
   
   # test to simulate doPrepare failure
   # RC=$RC_PREP_ERROR
   
   finalize_log
   debug_info "exit: doPrepare"
}

##################
function doDelete
##################
# flashcopy snapshots are NOT deleted from the storage system, instead
# they will only be removed from the scripted interface repository
# vital paramters are passed as arguments of the delete call
# from the ACS library
# -o objectID is the object id
# -t is not used in this function in this function
{
   debug_info "entry: doDelete"

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   RC=0
   TMP_RC=0
   IGNORE_RC=0

   # look for the backup protocol file  
   debug_info "data: get option RESULT_${objectId}_FILE from current\
 protocol file $config"
   key="RESULT_"${objectId}"_FILE"
   getSetting $key
   deleteConfig=$_setting

   debug_info "data: objectId: ${objectId}"
   debug_info "data: deleteConfig: $deleteConfig"

   # look for the snapshot names in the backup protocol file (KEY=USER_FC)
   write_log "   Retrieving snapshots from protocol file $deleteConfig" 
   write_log "   flashcopy snaphot will be removed from repository:"
   CMD="awk -F= '\$1 == \"$USER_FC\" {print \$2 }' $deleteConfig" 
   debug_info "data: executing $CMD > $TMP"
   eval $CMD > $TMP
   if_error "Error: $CMD failed"

   debug_info "data: reading from $TMP"
   while read x
   do 
      # print name and timestamp of flashcopy snapshot
      FC_NAME=`echo $x | awk '{ print $3 }'`
      FC_TIMESTAMP=`echo $x | awk '{ print $4 }'`
      write_log "   $FC_NAME with timestamp $FC_TIMESTAMP"
	  
   done < $TMP 
   
   # cleanup 
   cleanup_tempfiles
   
   write_log $D
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."

   # test to simulate doDelete failure
   # RC=$RC_DELETE_ERROR

   finalize_log
   debug_info "exit: doDelete"
   return $RC
}


##################
function doRestore
##################
# performs the restore of the FlashCopy(ies)
# mapping of Storage Logical Drives, VIO physical hdisks, local hdisks is handled
# externally in file $FC_MAPPING_FILE
{
   debug_info "entry: doRestore"

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."
   
   # get_used_filesystems_on_hdisks, umount, restore, mount in restore function
   # use $FILESYSTEMS as input

   debug_info "data: get option OBJ_ID from current protocol file $config"
   getSetting "OBJ_ID"
   result_file_no=$_setting

   debug_info "data: get option RESULT_${result_file_no}_FILE from current\
 protocol file $config"
   key="RESULT_"${result_file_no}"_FILE"
   getSetting $key
   restoreConfig=$_setting

   # unmount all filesystems
   get_used_filesystems_for_restore
   umount_filesystems
   if_error "Error: $CMD failed"
  
   # restore flashcopied pvs
   get_used_pvs_for_restore
   restore_pvs
   if_error "Error: $CMD failed"

   # mount all filesystems
   get_used_filesystems_for_restore
   mount_filesystems
   if_error "Error: $CMD failed"

   write_log $D
   
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."
   finalize_log 
   
   debug_info "exit: doRestore"
   # test to simulate doRestore failure
   # RC=$RC_REST_ERROR
   # return $RC
}


##################
function doStoreMetaData
##################
# performs post processing after successful backup
{
   debug_info "entry: doStoreMetaData"

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   # Post Processing Tasks:
   # must be executed n both cases, if snapshot ok in Store Metadata
   #                                if  NOT in Rollback
   # cleanup
   cleanup_tempfiles

   # save the protocol file 
   CMD="cp $config $PROT_BKP_DIR" 
   write_log "   Saving the protocol file $config"
   write_log "   to $PROT_BKP_DIR"
   debig_info "data: $CMD"
   eval $CMD >> $LOG
   # give a warning instead of ERROR in this phase 
   
   if [[ $? -ne 0 ]]
   then
      # copy failed, print a warning in $LOG, 
      write_log "   WARNING **** : protocol file could not be saved"
   fi

   write_log $D
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."
   finalize_log 
   
   debug_info "exit: doStoreMetaData"
}

##################
function doSnapshot
##################
# reads in local hdisks to backup from file $PHYS_VOLUMES
# and creates flashcopy for each entry
{
   debug_info "entry doSnapshot"

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."
   FC_TIMESTAMP=""
   
   debug_info "data: reading from $PHYS_VOLUMES"
   while read x
   do
      # name of the FlashCopyLogicalDrive is defined externally
      # should contain the TYPE in the name (DATA or lOG) 
      TYPE=`echo $x | awk '{print $1}'`
      LOCAL_HDISK=`echo $x | awk '{print $2}'`
    
      # look for $LOCAL_HDISK in file $FlashCopyTarget
      debug_info "data: awk ' \$1 ~ /^$LOCAL_HDISK/ { print \$2 }' $FlashCopyTarget"
      CMD="awk ' \$1 ~ /^$LOCAL_HDISK/ { print \$2 }' $FlashCopyTarget"
      FC_LOGICALDRIVE=`eval $CMD` 
      
      # if FC_LOGICALDRIVE was not found, return with error
      if [[ -z $FC_LOGICALDRIVE ]]
      then
        write_log "****  ERROR: no FlashCopyLogicalDrive for $LOCAL_HDISK in $FlashCopyTarget. Terminating $0."
        RC=$RC_SNAP_ERROR
        return $RC
      fi
    
      # recreate the flashcopy on a prepared storage flashcopy logical drive
      debug_info "data: flashcopy of local hdisk $LOCAL_HDISK to fc_logicaldrive $FC_LOGICALDRIVE"
      write_log "$S FlashCopy ...."
 
      SMCLI_RECREATE="$SMCLI $SM_HOST -c 'recreate Flashcopy LogicalDrive [\"$FC_LOGICALDRIVE\"];' -p $SM_PASSWORD"
      write_log "   recreate Flashcopy LogicalDrive $FC_LOGICALDRIVE"
      CMD="sudo $SMCLI_RECREATE 1>$SM_CMD_OUT 2>$SM_CMD_ERR; echo \$?>$BGND_RC_FILE "
      debug_info "data: $CMD"
      #eval $CMD  >> $LOG 2>&1 &
      eval $CMD &
      timeout_pid 10 $!
      if_error "Error: Storage Manager Command exceeded timeout. Exiting $0."
      # check rc of flashcopy command
      CMD="awk '{print \$1}' $BGND_RC_FILE"
      debug_info "data: check RC of backgrounded command in BGND_RC_FILE"
      debug_info "data: CMD=$CMD"
      if [[ `eval $CMD` -ne 0 ]]
      then
         write_log "   recreate Flashcopy LogicalDrive $FC_LOGICALDRIVE failed. Exiting $0."
	 write_log "   STDERR of last Storage Manager Command:"
	 write_log "   `cat $SM_CMD_ERR`"
	 write_log "   STDOUT of last Storage Manager Command:"
	 write_log "   `cat $SM_CMD_OUT`"
         write_log "   Exiting $0."
	 exit $RC_SNAP_ERROR
      fi
 
      # request the flashcopy creation timestamp from the storage manager
      debug_info "data: requesting creation timestamp....."
      SMCLI_VERIFY="$SMCLI $SM_HOST -c 'show LogicalDrive [\"$FC_LOGICALDRIVE\"];' | awk '/Creation timestamp/ { print \$3 \" \" \$4 \" \" \$5 }' "
      CMD="sudo $SMCLI_VERIFY"
      debug_info "data: $CMD"
      # store the output of the command in CMD_OUT
      CMD_OUT=`eval $CMD 2>> $LOG`
      RC=$?
      if [[ $RC -eq 0 ]]
      then
         debug_info "data: request returned $CMD_OUT"
         FC_TIMESTAMP=`echo $CMD_OUT | sed 's/ /_/g' `
      else
         FC_TIMESTAMP="unknown"
      fi
    
      # lookup current Volume Group name of LOCAL_HDISK
      CMD="$LSPV ${LOCAL_HDISK} | awk -F: '/VOLUME GROUP/ { sub(/ */,\"\", \$3); print \$3 }'"
      VG_NAME=`eval $CMD`
      if_error "Error: $CMD failed. Exiting $0."

      # write local hdisk, current volumegroup name, flashcopy logical drive name and 
      # timestamp to protocol file
      debug_info "data: $USER_FC=${TYPE} ${LOCAL_HDISK} ${FC_LOGICALDRIVE} ${FC_TIMESTAMP} ${VG_NAME}" 
      storeSetting "$USER_FC=${TYPE} ${LOCAL_HDISK} ${FC_LOGICALDRIVE} ${FC_TIMESTAMP} ${VG_NAME}"
      write_log $D 
      
   done < $PHYS_VOLUMES
   
   if_error "Error: Processing Snapshots for Filesystems in $PHYS_VOLUMES failed. "

   # set return code for DB2 backup call
   write_log "   All snapshots complete. Setting RC=0." 
   write_log $D.
   RC=0;
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."
 
   finalize_log
   debug_info "exit: doSnapshot"  
}

##################
function doRollback
##################
# function is called when the preceeding call of the script failed 
# in case of prepare:
#     - no rollback activity needed
# in case of snapshot:
#     - delete the failed snapshot images from protocol files
#     - deletion of flashcopy in storage manager must be done manually
#     - name and timestamp is provided in the log file $LOG of the script
# in case of verify:
#     - delete the failed snapshot images
# in case of storemetadata:
#     - remove the backup copy of the protocol file
# in case of restore:
#     - try to umount the filesystems, export the Volume Group activated by restore
# in case of delete:
#     - to be defined

{
   debug_info "entry: doRollback"
   # init_log  
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."
   
   # initialize RC 
   RC=0
   TMP_RC=0

   # get the failed step. There is only one with RC != 0
   # escape the $1 and $2 in the awk program, this is the field not shell variable
   # $1 ~ /...../ && $2 != 0  means: the 1st field must match any of RC_....
   #                                 the 2nd field must be != 0

   debug_info "data: searching for the failed step in the protocol file"
   CMD="awk -F= '\$1 ~ /^RC_PREPARE|^RC_SNAPSHOT|^RC_VERIFY|^RC_RESTORE|^RC_DELETE|\
^RC_STORE_METADATA/ && \$2 != 0 {print \$1 }' $config"
   CMD_OUT=`eval $CMD`
   debug_info "data: Executed: $CMD"

   case $CMD_OUT in
      "RC_SNAPSHOT" | "RC_VERIFY")
         # perform clean up of failed flashcopy snapshot images
         # delete all flshcopy snapshot images if doVerify returns an invalid status
         write_log "   Found: $CMD_OUT is != 0."
         write_log "   Specific Rollback activities for failed SNAPSHOT, VERIFY"

         write_log $S "listing failed flashcopy snapshot ...."
	 CMD="awk -F= '\$1 == \"$USER_FC\" { print \$2 }' $config"
         eval $CMD > $TMP
        
         if [[ -s $TMP ]]
         then
           # if the file $TMP exists and is greater than size 0 
           # means that at least one flashcopy snapshot is found for deletion
           while read x
           do
              # print name and timestamp of flashcopy snapshot 
              FC_NAME=`echo $x | awk '{ print $3 }'`
              FC_TIMESTAMP=`echo $x | awk '{ print $4 }'`
	      
	      write_log "   Manually remove flashcopy snaphot:"
	      write_log "   $FC_NAME with timestamp $FC_TIMESTAMP"
           done < $TMP
	 else
            # No flshcopy snapshot found for deletion
            write_log "   No flashcopy snapshot to be deleted." 
         fi 
         ;;
      "RC_STORE_METADATA")
         # remove the backup copy of the protocol file
         write_log "   Found: $CMD_OUT is != 0."
         write_log "   Specific Rollback activities for failed STORE_METADATA"
   
         # construct path and filename for protocolfile backup  
         write_log "   Removing protocolfile  backup..."
         CMD="`echo $config  |  awk -F/ '{print \$NF }'`"
         write_log "   rm ${PROT_BKP_DIR}$CMD" 
         eval "rm ${PROT_BKP_DIR}${CMD} 2>> $LOG"
         
         if [[ $? -ne 0 ]]
         then
             write_log "   WARNING: File ${PROT_BKP_DIR}$CMD could not be removed."
         fi

         write_log $D
         ;;
      "RC_RESTORE")
         # umount fs and export backup vgs.
         debug_info "entry: case RC_RESTORE"
	 write_log $S "Trying to unmount and export backup Volume Groups ...."

         # get_used_filesystems_for_restore
         umount_filesystems

         if [[ $? -eq 0 ]]
         then
	     debug_info "data: all fs unmounted. "

	     # varyoff and export volume groups
	     export_vgs
	     if_error "Error: export_vgs failed"
         else
             write_log "   WARNING: Filesystems could not be unmounted "
             RC=$RC_RBCK_ERROR
         fi

         write_log $D
         debug_info "exit: case RC_RESTORE"
         ;;
      *)
         # default, do nothing
         write_log "   Nothing specific to rollback for failed step: $CMD_OUT"
         ;;
   esac
   
   # Post Processing Tasks:
   # must be executed n both cases, if snapshot ok in Store Metadata
   #                                if  NOT in Rollback
   # cleanup
   cleanup_tempfiles

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "Ending $0 at $TIMESTAMP ."
   finalize_log 

   debug_info "exit: doRollback"
   return $RC
}

##################
function doVerify
##################
# verifies the snapshot images created in doSnapshot
# 
{ 
   debug_info "entry: doVerify"
   # init_log  
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   # initialize global RC variable  
   RC=0

   # initialize counter for function return code 
   TMP_RC=0
   
   write_log "   verifing all Flashcopies ...."
   debug_info "data: reading key $USER_FC from $config and store in $TMP"
   CMD="awk -F= '\$1 == \"$USER_FC\" { print \$2 }' $config"
   debug_info "data: using command: $CMD"
   eval $CMD > $TMP

   debug_info "data: reading FlashCopy LogicalDrive from $TMP"
   while read x
   do
     # prepare SMcli show LogicalDrive command paramter Name
     FC_LOGICALDRIVE=`echo $x | awk '{ print $3 }'`

     SMCLI_VERIFY="$SMCLI $SM_HOST -c 'show LogicalDrive [\"$FC_LOGICALDRIVE\"];' | awk '/Status/ { print \$2 }' "
     CMD="sudo $SMCLI_VERIFY"
     debug_info "data: $CMD"
     # store the output of the command in CMD_OUT
     CMD_OUT=`eval $CMD 2>> $LOG`
     RC=$?

     if [[ $RC -eq 0 ]]
     then
        if [[ $CMD_OUT == "Optimal" ]];
        then
           write_log "   Verification of Flashcopy $FC_LOGICALDRIVE succeeded."
        fi
     else
        # increment counter, if command did not return "Optimal"
        let "TMP_RC = TMP_RC + 1"
        write_log "   Verification of Flashcopy $FC_LOGICALDRIVE failed." 
     fi
     
     write_log "   LogicalDrive Status $FC_LOGICALDRIVE = \"$CMD_OUT\"." 

   done < $TMP

   # set the final return code
   if [[ $TMP_RC -eq 0 ]]
   then
       write_log "   All snapshots successfully verified." 
       RC=0
   else
       write_log "   **** ERROR: at least one snapshot image is not in state: valid. rc=$RC_VFY_ERROR"
       RC=$RC_VFY_ERROR
   fi

   # test to simulate doVerify failure
   # RC=$RC_VFY_ERROR

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."
   finalize_log 

   debug_info "exit: doVerify"
   return $RC
}


#
#  M A I N
#
# --------------------------------------

init_log

debug_info "entry main: parsing of options"

# COLLECT PARAMS PROVIDED BY DB2 ACS API
# --------------------------------------

while getopts a:c:o:t: OPTION
do
   case ${OPTION} in
      a) action=${OPTARG}
         debug_info "data: -a=${OPTARG}"
         ;;
      c) config=${OPTARG}
         debug_info "data: -c=${OPTARG}"
         ;;
      o) objectId=${OPTARG}
         debug_info "data: -o=${OPTARG}"
         ;;
      t) timestamp=${OPTARG}
         debug_info "data: -t=${OPTARG}"
         ;;
      \?) echo "# Unknown parameter '$1'"
   esac
done
debug_info "data: parsing of options done." 

# COLLECT OPTIONS PROVIDED BY THE USER
# IN THE BACKUP COMMAND 
# --------------------------------------
# additional arguments such as <repository directory> and <FlashCopyTarget>

debug_info "data: parsing secondary options"
debug_info "data: no. of arguments before shift: $#"

# OPTIND (von getopts) zaehlt programname mit, $# nicht
shift `expr $OPTIND - 1`
debug_info "data: no. of arguments after shift: $#"

if [ $# -eq 0 ] # no 2ndary options
then
  write_log "no external options from DB2 backup command"
else
  # search in the remaining arguments for "FlashCopyTarget="
  debug_info "data: \$*: $*"
  for i in $*
  do
     if [[ "$i" == FlashCopyTarget=* ]]
     then
        FlashCopyTarget=`echo $i | awk -F= '{ print \$2 }'`
        write_log "Found $FlashCopyTarget as secondary option"
     fi
  done
fi
debug_info "data: parsing secondary options done"

# exit if Mapping file was not found
if [[ -z $FlashCopyTarget ]] 
then
        write_log "Specify mapping file in the USE SNAPSHOT clause"
        write_log "e.g.  ... USE SNAPSHOT ... OPTIONS \"FlashCopyTarget=<mappingfile.txt>\" "
        write_log "No mapping file found. Exiting."
        exit $RC_MAPPING_ERROR
fi



# WORK
# --------------------------------------

case "$action" in
   prepare)
      doPrepare
      ;;
   snapshot)
      doSnapshot
      ;;
   restore)
      doRestore
      ;;
   delete)
      doDelete
      ;;
   verify)
      doVerify
      ;;
   store_metadata)
      doStoreMetaData
      ;;
   rollback)
      doRollback
      ;;
esac
debug_info "exit main."
exit $RC
  
