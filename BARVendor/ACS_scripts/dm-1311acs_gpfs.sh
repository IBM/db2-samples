#!/usr/bin/ksh
#---------------------------------------------------------------------------
# (c) Copyright IBM Corp. 2012 All rights reserved.
#
# Script Name: dm-1311acs_gpfs.sh
# 
# Purpose: implement the scripted interface for DB2 ACS using IBM GPFS.This
# script is called by DB2 to make GPFS snapshot backups of paths
# provided by DB2.
# 
# Please see developerwork article for details: https://www.ibm.com/developerworks/data/library/techarticle/dm-1311scriptdb2copy3/dm-1311scriptdb2copy3-pdf.pdf
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

# GPFS path and exes
GPFSINST=/usr/lpp/mmfs
GPFSBIN=$GPFSINST/bin
GPFSSNAP=$GPFSBIN/mmcrsnapshot
GPFSVFY=$GPFSBIN/mmlssnapshot
GPFSDEL=$GPFSBIN/mmdelsnapshot
GPFSREST=$GPFSBIN/mmrestorefs
GPFSMOUNT=$GPFSBIN/mmmount
GPFSUMOUNT=$GPFSBIN/mmumount

# Log file
LOGPREFIX="gpfs_snap"
LOGPOSTFIX="BWP"
LOG=/tmp/${LOGPREFIX}_${LOGPOSTFIX}.log

# Protocol Backup directory
PROT_BKP_DIR="/db2/db2bwp/scriptACS/prot_bkp/"

# User defined entries in the protocol file
USER_GPFSSNAP="USER_GPFSSNAP"

# Tempfile names
TMPDIR=/tmp
TMP=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}.tmp
TMP_=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}.tmp_
FILESYSTEMS=${TMPDIR}/${LOGPREFIX}_${LOGPOSTFIX}_fs.tmp

# Constants
GPFS_SNAP_PREFIX="snap_"
GPFS_SNAP_PREFIX_DATA="snap_DATA_"
GPFS_SNAP_PREFIX_LOG="snap_LOG_"
D="Done."
S="Starting"
D_PATH="DATAPATH_"
L_PATH="LOGPATH_"
DB2BACKUP_LOGS="DB2BACKUP_LOGS"

# Returncode
RC_OK=0
RC_COMM_ERROR=2
RC_INV_ACTION=4
RC_NOT_ENOUGH_SPACE=28
RC_DEV_ERROR=18
RC_INV_DEV_HANDLE=12
RC_IO_ERROR=25
RC_ERROR=30
RC_PREP_ERROR=40
RC_SNAP_ERROR=50
RC_VFY_ERROR=60
RC_RBCK_ERROR=70
RC_STORE_METADATA_ERROR=80
RC_REST_ERROR=90
RC_DELETE_ERROR=100

# Variables
CMD=""
CMD_OUT=""
TIMESTAMP=""
GPFS_PARM1=""
GPFS_PARM2=""
GPFS_SNAP_STATUS=""
VOLUMEGROUPS=""
LUNID=""
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
      #print "$1 RC=$RC" | tee -a $LOG
      write_log "$i RC=$RC" 
   
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

##################
function cleanup_tempfiles
##################
# cleans up temp files
{
   debug_info "entry: cleanup_tempfiles"
   CMD="rm $TMP $TMP_ $FILESYSTEMS >> $LOG 2>&1"
   write_log $S "cleanup temp files ...."
   write_log "   $CMD"
   eval $CMD
   if [[ $? -ne 0 ]]
   then
      write_log "   WARNING: the command $CMD failed."
   fi
   write_log $D
   debug_info "exit: cleanup_tempfiles"
}

##################
function prepare_restore_command
##################
# checks if the restore command exists
{ 
   debug_info "entry: prepare_restore_command"
   write_log $S "checking restore commands ...."
   TMP_RC=0 
   RC=0

   for i in $GPFSREST $GPFSMOUNT $GPFSUMOUNT
   do 
      debug_info "data: check if $i exits."
      if [[ -e $i ]]
      then
         write_log "   $i exists."
      else
         write_log "   $i does NOT exist."
         let "TMP_RC = TMP_RC + 1"
      fi
   done

   # set the final return code
   if [[ $TMP_RC -ne 0 ]]
   then
       write_log "   At least one GPFS command is missing."
       RC=$RC_PREP_ERROR
   fi
   
   write_log $D
   debug_info "exit: prepare_restore_command"
   return $RC
}

function prepare_delete_command
##################
# checks if the delete command exists
{ 
   debug_info "entry: prepare_delete_command"
   write_log $S "checking delete commands ...."
   TMP_RC=0 
   RC=0

   for i in $GPFSDEL
   do 
      debug_info "data: check if $i exits."
      if [[ -e $i ]]
      then
         write_log "   $i exists."
      else
         write_log "   $i does NOT exist."
         let "TMP_RC = TMP_RC + 1"
      fi
   done

   # set the final return code
   if [[ $TMP_RC -ne 0 ]]
   then
       write_log "   At least one GPFS command is missing."
       RC=$RC_PREP_ERROR
   fi
   
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
   write_log $S "checking snapshot commands ...."
   TMP_RC=0 
   RC=0

   for i in $GPFSSNAP $GPFSVFY $GPFSDEL
   do 
      debug_info "data: check if $i exits."
      if [[ -e $i ]]
      then
         write_log "   $i exists."
      else
         write_log "   $i does NOT exist."
         let "TMP_RC = TMP_RC + 1"
      fi
   done

   # set the final return code
   if [[ $TMP_RC -ne 0 ]]
   then
       write_log "   At least one GPFS command is missing."
       RC=$RC_PREP_ERROR
   fi
   
   write_log $D
   debug_info "exit: prepare_snapshot_command"
   return $RC
}

##################
function mount_filesystems
##################
# mounts the GPFS devices/filesystems in file $FILESYSTEMS
#
{
   debug_info "entry: mount_filesystems"
   write_log $S "GPFS mnount ... "

   TMP_RC=0 

   while read x
   do
      # set parm1 for the GPFS mount command
      GPFS_PARM1=`echo $x | awk '{print $1}'`
      #  set parm2 for the GPFS mount command
      GPFS_PARM2="-a"

      CMD="sudo $GPFSMOUNT"
      write_log "   $CMD ${GPFS_PARM1} ${GPFS_PARM2}"
      eval $CMD ${GPFS_PARM1} ${GPFS_PARM2} >> $LOG 2>&1
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

   write_log $D
   debug_info "exit: mount_filesystems"
   return $RC
}


##################
function umount_filesystems 
##################
# umounts the GPFS devices/filesystems in file $FILESYSTEMS
#
{
   debug_info "entry: umount_filesystems"
   write_log $S "GPFS umnount ... "
 
   TMP_RC=0 

   while read x
   do
      # set parm1 for the GPFS umount command
      GPFS_PARM1=`echo $x | awk '{print $1}'`
      #  set parm2 for the GPFS umount command
      GPFS_PARM2="-a"

      CMD="sudo $GPFSUMOUNT"
      write_log "   $CMD ${GPFS_PARM1} ${GPFS_PARM2}"
      eval $CMD ${GPFS_PARM1} ${GPFS_PARM2} >> $LOG 2>&1
      RC=$?

      if [[ $RC -ne 0 ]]
      then
           # increment counter, if command did not return 0
           let "TMP_RC = TMP_RC + 1"
           write_log "   ... umount of this filesystem failed."
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
   
   write_log $D
   debug_info "exit: umount_filesystems"
   return $RC
}


##################
function  restore_filesystems
##################
# restore the filesystems from snapshots
# uses $FILESYSTEMS 
# function tries to restore all required filesystems. If an error occurs 
# during the restorefs command the next filesystem is processed.
# This gives the user the possibility to fix all errors (e.g out of space errors)
# at once, instead of repeating the restore several time and fix the errors one by one
{
   debug_info "entry: restore_filesystems"
   write_log $S "GPFS restore from snapshot ...."
   TMP_RC=0

   while read x
   do
      # set parm1 and parm2 for the GPFS mmrestorefs command
      GPFS_PARM1=`echo $x | awk '{print $1}'`
      GPFS_PARM2=`echo $x | awk '{print $2}'`

      CMD="sudo $GPFSREST"
      write_log "   $CMD ${GPFS_PARM1} ${GPFS_PARM2}"
      eval $CMD ${GPFS_PARM1} ${GPFS_PARM2} >> $LOG 2>&1 
      RC=$?

      if [[ $RC -ne 0 ]]
      then
           # increment counter, if command did not return "Valid"
           let "TMP_RC = TMP_RC + 1"
           write_log "   **** ERROR: restore of this snapshot failed."
      fi
   done < $FILESYSTEMS

   if [[ $TMP_RC -eq 0 ]]
   then
       write_log "   All restores from snapshot complete. Setting RC=0." 
       RC=0
   else
       write_log "   **** ERROR: at least one snapshot was not restored. rc=$RC_REST_ERROR"
       RC=$RC_REST_ERROR
   fi 

   write_log $D
   debug_info "exit: restore_filesystems"
   return $RC
}

##################
function get_used_filesystems_for_restore
##################
# get the fs for restore from the protocol file of the selected backup
# grep for all entries starting with USER_GPFSSNAP
{
   debug_info "entry: get_used_filesystems_for_restore"
   write_log $S "build the protocol file name to use for the restore... "
   RC=0
  
   getSetting "OBJ_ID"
   result_file_no=$_setting
   key="RESULT_"${result_file_no}"_FILE"
   getSetting $key
   restoreConfig=$_setting

   # grep for all snapshots first (data and log)
   write_log "   looking for GPFS devices / filesystem to restore in: $restoreConfig  "
   write_log "   and write them to $FILESYSTEMS"
  
   CMD="awk -F= '/^USER_GPFSSNAP/ {print \$2}' $restoreConfig" 
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
       # remove the snapped log volumes form the list in $FILESYSTEMS
       write_log "   LOG volumes are not restored, option ACTION = $WHAT_TODO_WITH_LOGS"
       debug_info "data:  removing line with ${GPFS_SNAP_PREFIX_LOG} from $FILESYSTEMS"

       CMD="grep -v ${GPFS_SNAP_PREFIX_LOG} $FILESYSTEMS"
       debug_info "data: $CMD"
       eval $CMD > $TMP
       if_error "Error: $CMD failed"

       CMD="mv $TMP $FILESYSTEMS"
       debug_info "data: $CMD"
       eval $CMD 
       if_error "Error: $CMD failed"
   fi

   write_log $D
   debug_info "exit: get_used_filesystems_for_restore"

}

##################
function get_used_filesystems_for_backup
##################
# creates a list of filesystems for backup
# and writes them to file $FILESYSTEMS
{
   debug_info "entry: get_used_filesystems_for_backup"

   # grep all entries in $config starting with DATAPATH_ 
   CMD="awk -F= '/^${D_PATH}/ {print  \"DATA \" \$2}' $config"

   write_log $S "Retrieving db and storage paths from protocol file..." 
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
      # grep lines starting with LOGPATH_ from config file
      # label each line with LOG
      CMD="awk -F= '/^${L_PATH}/ {print \"LOG \" \$2}' $config"
   
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
       type=`echo $x | awk '{print $1}'`
       path=`echo $x | awk '{print $2}'`
       debug_info "data: filessystemname= df -M  $path | awk '\$2 ~ /^\// { print \$1 }'"
       device=`df -M  $path | awk '$2 ~ /^\// { print $1 }'`
       echo "$type $device" 
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

   debug_info "exit: get_used_filesystems_for_backup"
}

##################
function doPrepare
##################
# reads in file and paths to be backed up from DB2
# maps files and paths to a unique list of filesystems
# checks if snapshot command is available 
# reads in backup option in/exclude logs 
{
   debug_info "entry: doPrepare"
   init_log

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   debug_info "data: checking the config file"
   check_config_file
   if_error "Error:  check_config_file."

   write_log "Using $config..."

   getSetting "OPERATION"
   operation=$_setting
     
   write_log "$S preparation for $operation ..."

   case $operation in 
      "SNAPSHOT")
         # prepare for snapshot
         # check needed GPFS commands
         prepare_snapshot_command
         if_error "Error:  prepare_snapshot_command failed."

         # get the filesystems and store them in file $FILESYSTEMS 
         get_used_filesystems_for_backup
         ;;
      "RESTORE")
         # prepare for restore 
         # check needed commands
         prepare_restore_command
         if_error "Error:  prepare_restore_command failed."

         # copy  backup protocol files into place if the repository is empty
         # get_used_filesystems_for_restore, umount, restore, mount in doRestore function
         ;;
      "DELETE")
         # prepare for deletion of snapshot images
         # check needed commands
         prepare_delete_command
         if_error "Error:  prepare_delete_command failed."
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
# deletes the GPFS snapshots linked to a backup image
# vital paramters are passed as arguments of the delete call
# from the ACS library
# -o objectID is the object id
# -t is not used in this function in this function
{
   debug_info "entry: doDelete"
   init_log

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   RC=0
   TMP_RC=0
   IGNORE_RC=0

   debug_info "data: grep the option RESULT_${objectId}_FILE from current\
 protocol file $config"
   key="RESULT_"${objectId}"_FILE"
   getSetting $key
   deleteConfig=$_setting

   debug_info "data: objectId: ${objectId}"
   debug_info "data: deleteConfig: $deleteConfig"

   # for all lines starting with USER_GPFSSNAP, get the GPFS device name
   # and the snapshotname
   CMD="awk -F= '/^USER_GPFSSNAP/ {print \$2\" \"\$3}' $deleteConfig"
   
   write_log $S "Retrieving GPFS snapshots from protocol file..." 
   write_log "   writing them to $TMP" 
   debug_info "data: executing $CMD > $TMP"
   eval $CMD > $TMP
   if_error "Error: $CMD failed"

   debug_info "data: reading from $TMP"
   while read x
   do 
      # set parm1 and parm2 for the GPFS commands
      GPFS_PARM1=`echo $x | awk '{print $1}'`
      GPFS_PARM2=`echo $x | awk '{print $2}'`
	  
      # if snap image exists exists evaluate RC (normal delete)
      # if not ignore RC (cleanup delete)
      CMD="sudo $GPFSVFY"
      write_log "   $CMD ${GPFS_PARM1} -s ${GPFS_PARM2}"
      eval $CMD ${GPFS_PARM1} -s ${GPFS_PARM2} >> $LOG 2>&1 
      RC=$?
      if [[ $RC -ne 0 ]]
      then
        write_log "   Snap does not exist. Ignoring the following $GPFSDEL error."
        IGNORE_RC=1
      fi

      CMD="sudo $GPFSDEL"
      write_log "   $CMD ${GPFS_PARM1} ${GPFS_PARM2}"
      eval $CMD ${GPFS_PARM1} ${GPFS_PARM2} >> $LOG 2>&1 
      RC=$?

      debug_info "data: RC: $RC and IGNORE_RC:$IGNORE_RC"
      if [[ $RC -ne 0 ]] && [[ $IGNORE_RC -eq 0  ]]
      then
           # increment counter, if command did not return 0
           let "TMP_RC = TMP_RC + 1"
           debug_info "data: normal delete, report errors."
           write_log "   WARNING **** : Can't delete this snapshot:"
           write_log "                ${GPFS_PARM1} ${GPFS_PARM2}"
      fi

      # reset the variable for next iteration
      IGNORE_RC=0
   done < $TMP 
   
   if [[ $TMP_RC -eq 0 ]]
   then
       write_log "   All snapshots deleted. Setting RC: 0." 
       RC=0
   else
       write_log "  Error *****:  At least one snapshot was not deleted. RC: $RC_DELETE_ERROR" 
       RC=$RC_DELETE_ERROR
   fi 

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
# performs thre restore of GPFS snapshots
{
   debug_info "entry: doRestore"
   init_log

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."
   
   # get_used_filesystems_for_restore, umount, restore, mount in restore function
   # use $FILESYSTEMS as input

   debug_info "data: grep the option OBJ_ID from current protocol file $config"
   getSetting "OBJ_ID"
   result_file_no=$_setting

   debug_info "data: grep the option RESULT_${result_file_no}_FILE from current\
 protocol file $config"
   key="RESULT_"${result_file_no}"_FILE"
   getSetting $key
   restoreConfig=$_setting

   debug_info "data: calling get_used_filesystems_for_restore "
   get_used_filesystems_for_restore

   # unmount all 
   umount_filesystems
   if_error "Error: $CMD failed"

   restore_filesystems
   if_error "Error: $CMD failed"

   # mount all 
   mount_filesystems
   if_error "Error: $CMD failed"

   write_log $D
   
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."
   finalize_log 
   
   # test to simulate doRestore failure
   # RC=$RC_STORE_REST_ERROR

   debug_info "exit: doRestore"
}


##################
function doStoreMetaData
##################
# performs post processing after successful backup
{
   debug_info "entry: doStoreMetaData"
   init_log

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   # Post Processing Tasks:
   # must be executed n both cases, if snapshot ok in Store Metadata
   #                                if  NOT in Rollback
   # cleanup
   cleanup_tempfiles

   # save the protocol file 
   CMD="cp $config $PROT_BKP_DIR" 
   write_log "Starting saving the protocol file to another directory"
   write_log "   $CMD"
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
# reads in filesystems to backup from file $FILESYSTEMS
# an makes GPFS snapshot for each entry
{
   debug_info "entry doSnapshot"
   init_log

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."
   
   debug_info "data. reading from $FILESYSTEMS"
   while read x
   do
      # remove the /dev from the 2nd filed in each line and use as parm1
      # parm1 = name of the gpfs filesystem 
      GPFS_PARM1=`echo $x | awk '{print $2}' | sed 's/^\/dev\///'`

      # generate name for snapshot and use as parm2
      # different snapshotnames for log and sapdata filesystems 
      # TYPE can be DATA or LOG
      TIMESTAMP=`date +'%Y%m%d%H%M%S'`
      TYPE=`echo $x | awk '{print $1"_"}'`
      GPFS_PARM2=${GPFS_SNAP_PREFIX}${TYPE}${TIMESTAMP}

      write_log "$S GPFS snapshot ...."
      CMD="sudo $GPFSSNAP"
      write_log "   $CMD ${GPFS_PARM1} ${GPFS_PARM2}"
      eval $CMD ${GPFS_PARM1} ${GPFS_PARM2} >> $LOG 2>&1 

      if_error "Error: $CMD ${GPFS_PARM1} ${GPFS_PARM2} failed. Exiting $0."
      
      storeSetting "USER_GPFSSNAP=${GPFS_PARM1} ${GPFS_PARM2}"
      
      write_log $D 
      
   done < $FILESYSTEMS
   
   if_error "Error: Processing Snapshots for Filesystems in $FILESYSTEMS failed. "

   # set return code for DB2 backup call
   write_log "   All snapshots complete. Setting RC=0." 
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
#     - delete the failed snapshot images
# in case of verify:
#     - delete the failed snapshot images
# in case of storemetadata:
#     - remove the backup copy of the protocol file
# in case of restore:
#     - try to mount the filesystem again. The user can then repeat another
#        restore without having to manually mount the db filesystems
# in case of delete:
#     - to be defined

{
   debug_info "entry: doRollback"
   init_log  
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."
   
   # initialize RC 
   RC=0
   TMP_RC=0

   # get the failed step. There is only one with RC != 0
   # escape the $1 and $2 in the awk program, this is the field not shell variable
   # $1 ~ /...../ && $2 != 0  means: the 1st field must match any of RC_....
   #                                 the 2nd field must be != 0

   write_log "Searching for the failed step in the protocol file..."
   CMD="awk -F= '\$1 ~ /^RC_PREPARE|^RC_SNAPSHOT|^RC_VERIFY|^RC_RESTORE|^RC_DELETE|\
^RC_STORE_METADATA/ && \$2 != 0 {print \$1 }' $config"
   CMD_OUT=`eval $CMD`
   debug_info "data: Executed: $CMD"

   case $CMD_OUT in
      "RC_SNAPSHOT" | "RC_VERIFY")
         # perform clean up of failed GPFS snapshot images
         # delete all GPFS snapshot images if doVerify returns an invalid status
         write_log "Found: $CMD_OUT is != 0."
         write_log "Specific Rollback activities for failed SNAPSHOT, VERIFY"

         write_log $S "deleting failed GPFS snapshot ...."
         CMD="awk -F= '/^USER_GPFSSNAP/ { print \$2 }' $config"
         eval $CMD > $TMP
        
         if [[ -s $TMP ]]
         then
           # if the file $TMP exists and is greater than size 0 
           # means that at least one GPFS snapshot is found for deletion
           while read x
           do
              # prepare GPFS command paramters Device and Snapshotname
              GPFS_PARM1=`echo $x | awk '{ print $1 }'`
              GPFS_PARM2=`echo $x | awk '{ print $2 }'`
         
              CMD="sudo $GPFSDEL ${GPFS_PARM1} ${GPFS_PARM2}"
              write_log "   $CMD" 
              eval $CMD 2>> $LOG
              RC=$?
         
              if [[ $RC -ne 0 ]]
              then
                 # increment counter, if command failed in the loop
                 let "TMP_RC = TMP_RC + 1"
                 write_log "   ... Deletion of snapshot failed."
              fi
            done < $TMP
         

            # set the final return code
            if [[ $TMP_RC -eq 0 ]]
            then
                write_log "   All snapshots successfully deleted. " 
                RC=0
            else
                write_log "   **** ERROR: at least one snapshot image could not\
                              be deleted. rc=$RC_RBCK_ERROR"
                RC=$RC_RBCK_ERROR
            fi

         else
            # No GPFS snapshot found for deletion
            write_log "   No GPFS snapshot to be deleted." 
         fi 
         
         ;;
      "RC_STORE_METADATA")
         # remove the backup copy of the protocol file
         write_log "Found: $CMD_OUT is != 0."
         write_log "Specific Rollback activities for failed STORE_METADATA"
   
         # construct path and filename for protocolfile  backup  
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
         # try to mount the filesystems again. This gives the user the chance to 
         # repeat the restore without having to mount the filesystems manually 
         debug_info "entry: case RC_RESTORE"

         write_log "   Trying to mount filesystems again...."
         mount_filesystems
         if [[ $? -ne 0 ]]
         then
             write_log "   WARNING: Filesystems could not be mounted "
             RC=$RC_RBCK_ERROR
         fi

         write_log $D

         debug_info "exit: case RC_RESTORE"

         ;;
      *)
         # default, do nothing
         write_log "Nothing specific to rollback for failed step: $CMD_OUT"
         ;;
   esac
   
   # Post Processing Tasks:
   # must be executed n both cases, if snapshot ok in Store Metadata
   #                                if  NOT in Rollback
   # cleanup
   write_log "Default rollback activities:"
   cleanup_tempfiles

   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "\nEnding $0 at $TIMESTAMP ."
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
   init_log  
   TIMESTAMP=`date +'%Y%m%d%H%M%S'`
   write_log "$S $0 at $TIMESTAMP ."

   # initlaize global RC variable  
   RC=0

   # initialize counter for function return code 
   TMP_RC=0
   
   write_log $S "verify GPFS snapshot ...."
   debug_info "data: writing GPFS snapshotnames to verify to $TMP"
   CMD="awk -F= '/^USER_GPFSSNAP/ { print \$2 }' $config"
   debug_info "data: using command: $CMD"
   eval $CMD > $TMP

   debug_info "data: reading from $TMP"
   while read x
   do
     # prepare GPFS command paramters Device and Snapshotname
     GPFS_PARM1=`echo $x | awk '{ print $1 }'`
     GPFS_PARM2=`echo $x | awk '{ print $2 }'`

     CMD="sudo $GPFSVFY ${GPFS_PARM1} -s ${GPFS_PARM2}"
     write_log "   $CMD"

     # store the output of the command in CMD_OUT
     CMD_OUT=`eval $CMD 2>> $LOG`
     RC=$?

     if [[ $RC -eq 0 ]]
     then
        # check the result of the verify command, double qoutes to preserve LF
        # grep 3rd line, 3rd field of the output
        # /usr/lpp/mmfs/bin/mmlssnapshot database_dir -s snap_20130522162002 | 
        # awk '{ if(NR==3) print $3}'

        GPFS_SNAP_STATUS=`echo "$CMD_OUT" |  awk '{ if(NR==3) print $3}'`
        write_log "   ... returns: $GPFS_SNAP_STATUS." 

        if [[ $GPFS_SNAP_STATUS != "Valid" ]];
        then
           # increment counter, if command did not return "Valid"
           let "TMP_RC = TMP_RC + 1"
           write_log "   ... Verification of snapshot failed."
           write_log "   ... Status is not equal to \"Valid\"." 
        fi
 
     else
        # increment counter, if command failed in the loop
        let "TMP_RC = TMP_RC + 1"
        write_log "   ... Verification of snapshot failed." 
     fi

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

   write_log $D
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
# COLLECT PARAMS
# --------------------------------------
while getopts a:c:o:t: OPTION
do
   case ${OPTION} in
      a) action=${OPTARG}
         ;;
      c) config=${OPTARG}
         ;;
      o) objectId=${OPTARG}
         ;;
      t) timestamp=${OPTARG}
         ;;
      \?) echo "# Unknown parameter '$1'"
   esac
done

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
exit $RC
  
