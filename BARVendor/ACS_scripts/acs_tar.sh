#!/bin/sh
#---------------------------------------------------------------------------
# (c) Copyright IBM Corp. 2012 All rights reserved.
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
# CONSTANTS
#########################################################################
# Possible return codes
RC_OK=0
RC_COMM_ERROR=2
RC_INV_ACTION=4
RC_NOT_ENOUGH_SPACE=28
RC_DEV_ERROR=18
RC_INV_DEV_HANDLE=12
RC_IO_ERROR=25
RC_ERROR=30
# Variables
#########################################################################
RC=$RC_OK
_setting=0
action=0
config=0
instance=0
db_name=0
dbpartnum=0
repository="/tmp/"
objectId=0
timestamp=0
# HELPER
#########################################################################
# getSetting()
#
# Searches for setting in the protocol file identified
# by its keyword $1 and stores its value in the tmp variable
# _setting
# @param $1 - Setting's keyword
# @param $2 - Default value if setting's keyword was not found
# (optional, if not set $_setting will be empty)
# @param $3 - Configuration file to be opened (optional, if not
# set, $config will be used)
########################################################################
getSetting() {
  useConfig=$config
  if [ "$3" != "" ]
  then
    useConfig=$3
  fi
  cmd="awk -F= '/^${1}/ { print \$2 }' $useConfig"
  _setting=`eval $cmd`
  if [ "$2" != "" -a "$_setting" = "" ]
  then
    _setting=$2
  fi
}
# storeSetting()
#
# Stores a local variable in the protocol file which can be
# used later using getSetting
# @param $1 Setting's key
# $2 Settings' value
#######################################################################
storeSetting() {
  echo "$1=$2"
}
# collectSettings()
#
# Collects common settings from the protocol file and
# populates the global variables like handle, db_name and timestamp
# @param void
########################################################################
collectSettings() {
  getSetting "INSTANCE"
  instance=$_setting
  getSetting "DB_NAME"
  db_name=$_setting
  getSetting "DBPARTNUM"
  dbpartnum=$_setting
  getSetting "TIMESTAMP"
  timestamp=$_setting
}

doPrepare() {
#
# P R E P A R E
#
# --------------------------------------
# getSetting "OPERATION"
# operation=$_setting
#
# case "$operation" in
# snapshot)
# ;;
# delete)
# ;;
# restore)
# ;;
# query)
# ;;
: # noop
# Your commands here
# --------------------------------------
}

doSnapshot() {
#
# S N A P S H O T
#
# --------------------------------------
# Snapshot action here: build temporary backup
# file name and create TAR archive of all known
# paths to protocol file repository
# Construct file name of backup file
# and store it in the protocol file
  file="${repository}${db_name}.0.${instance}.${dbpartnum}.${timestamp}.001.tar"
  storeSetting "BACKUP_FILE" $file
# Create TAR archive from all storage paths:
# Use AWK to extract all *_PATH settings from $config file and pipe them to
# tar to create a tar archive
# cmd="awk -F= '/^STORAGE_PATH|DB_PATH|LOCAL_DB_PATH|TBSP_DEVICE|TBSP_PATH|CONT_PATH/ { print \$2; }' $config | tar cmd="awk -F= '/^DATAPATH/ { print \$2; }' $config | tar -Pcf $file -T - 2>/dev/null && echo 0 || echo 1"
  echo "# cmd: $cmd"
# execute command
  RC=`eval $cmd`
  echo "# backup tar created, rc=$RC"
# if logs included
  getSetting "DB2BACKUP_LOGS"
  includeLogs=$_setting
  if [ $includeLogs = "INCLUDE" ]
  then
    echo "# Logs to be included"
# Construct file name of logs file:
    logs="${repository}${db_name}.0.${instance}.${dbpartnum}.${timestamp}.log.tar"
# store backup file name to config
    storeSetting "BACKUP_LOGS" $logs
# cmd="awk -F= '/^LOG_DIR|MIRRORLOG_PATH/ { print \$2; }' $config | tar -Pcf $logs -T - 2>/dev/null && echo 0 || cmd="awk -F= '/^LOGPATH/ { print \$2; }' $config | tar -Pcf $logs -T - 2>/dev/null && echo 0 || echo 1"
    echo "# cmd: $cmd"
# execute command
    RC=`eval $cmd`
    echo "# tar for logs created, rc=$RC"
  fi
# --------------------------------------
}
doRestore() {
#
# R E S T O R E
#
# --------------------------------------
  getSetting "OBJ_ID"
  objectId=$_setting
  # Construct key to search for in currenct protocol file
  key="RESULT_${objectId}_FILE"
  getSetting $key
  oldConfig=$_setting
# Read setting BACKUP_FILE from $oldConfig...
  getSetting "BACKUP_FILE" "" $oldConfig
# ... and store it in $oldBackup
  oldBackup=$_setting
# Run command to extract old backup
  cmd="tar -xf $oldBackup && echo 0 || echo 1"
  echo "# cmd: $cmd"
  RC=`eval $cmd`
  echo "# tar extracted, rc=$RC"
# if logs included
  getSetting "ACTION"
  readAction=$_setting
  if [ $readAction = "DB2ACS_ACTION_READ_BY_OBJECT" ]
    then
# Read setting BACKUP_LOGS from $oldConfig...
    getSetting "BACKUP_LOGS" "" $oldConfig
# ... and store it in $oldBackup
    oldLogs=$_setting
# Run command to extract old backup
    cmd="tar -xf $oldLogs && echo 0 || echo 1"
    echo "# cmd: $cmd"
    RC=`eval $cmd`
    echo "# logs extracted, rc=$RC"
  fi
# --------------------------------------
}
doDelete() {
#
# D E L E T E
#
# --------------------------------------
# We may use $objectId or $timestamp to identify
# files to be deleted. In this sample case, we
# use $objectId to get the protocol file name
# in $oldConfig and read the backup file from this
# file to $oldBackup
# Construct key to search for in current protocol file
  key="RESULT_${objectId}_FILE"
# Read setting RESULT_i_FILE and store it in oldConfig
  getSetting $key
  oldConfig=$_setting
# Read setting BACKUP_FILE from $oldConfig...
  getSetting "BACKUP_FILE" "" $oldConfig
# ... and store it in $oldBackup
  oldBackup=$_setting
# Read setting BACKUP_FILE from $oldConfig...
  getSetting "BACKUP_LOGS" "" $oldConfig
# ... and store it in $oldBackup
  oldLogs=$_setting
# Delete old backup and protocol file
  echo "# Delete old backup file and logs: $oldBackup"
  rm $oldBackup
  rm $oldLogs
  echo "# Delete old protocol file: $oldConfig"
  rm $oldConfig
# --------------------------------------
}
doVerify() {
#
# V E R I F Y
#
# --------------------------------------
# check if the TAR archive is available
  getSetting "BACKUP_FILE"
  file=$_setting
  if [ -f "$file" -a -s "$file" ]
  then
    echo "# Backup '$file' exist"
    getSetting "BACKUP_LOGS"
    logs=$_setting
# if logs included
    getSetting "DB2BACKUP_LOGS"
    includeLogs=$_setting
    if [ $includeLogs = "INCLUDE" ]
    then
    if [ -f "$logs" -a -s "$logs" ]
    then
      echo "# Logs '$logs' exist"
    else
    echo "# ERROR: Backup '$logs' does not exists or is empty!"
    ((RC= $RC | $RC_ERROR))
    fi
  fi
else
  echo "# ERROR: Backup '$file' does not exists or is empty!"
  ((RC= $RC | $RC_ERROR))
fi
# --------------------------------------
}
doStoreMetaData() {
#
# S T O R E M E T A D A T A
#
# --------------------------------------
# The snapshot is successful
# The protocol file can be saved,
# only some non important lines will be added
: # noop
# --------------------------------------
}
doRollback() {
#
# R O L L B A C K
#
# --------------------------------------
# Your commands here
: # noop
# --------------------------------------
}
#
# M A I N
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
  repository="`dirname $config`/"
# WORK
# --------------------------------------
  collectSettings
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

