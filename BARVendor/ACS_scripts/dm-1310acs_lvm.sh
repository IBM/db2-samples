#!/bin/sh
#---------------------------------------------------------------------------
# (c) Copyright IBM Corp. 2013 All rights reserved.
# 
# Script Name: dm-1310acs_lvm.sh
# 
# Purpose: implement the scripted interface for DB2 ACS using Linux LVM.
# 
# Please see developerwork article for details: https://www.ibm.com/developerworks/data/library/techarticle/dm-1310scriptdb2copy2/dm-1310scriptdb2copy2-pdf.pdf
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

RC=$RC_OK

# HELPER
#########################################################################
# getSetting()
#
# Searches for setting in the protocol file identified
# by its keyword $1 and stores its value in the tmp variable
# _setting
# @param	$1 - Setting's keyword
# @param	$2 - Default value if setting's keyword was not found
#		     (optional, if not set $_setting will be empty)
# @param	$3 - Configuration file to be opened (optional, if not
#		     set, $config will be used)
########################################################################
getSetting() {
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

# storeSetting()
#
# Stores a local variable in the protocol file which can be
# used later using getSetting
# @param	$1	Setting's key
#		$2	Settings' value
#######################################################################
storeSetting() {
   echo "$1=$2"
}

doPrepare() {
#
# P R E P A R E
#
# --------------------------------------
   freespace=`sudo pvdisplay -c | awk -F":" '{print $10}'`
   neededspace=0
   for i in `grep "^DATAPATH" $config | awk -F= '{print $2}' | xargs -I\{\} df \{\} | grep '^/' | awk '{print $1;}' | uniq `
   do
      currentspace=`lvdisplay -c $i | awk -F":" '{print $8}'`
      neededspace=`expr $neededspace + $currentspace`
   done
   getSetting "DB2BACKUP_LOGS"
   includeLogs=$_setting
   if [ $includeLogs = "INCLUDE" -a $RC -eq 0 ]
   then
      for i in `grep "^LOGPATH" $config | awk -F= '{print $2}' | xargs -I\{\} df \{\} | grep '^/' | awk '{print $1;}' | uniq `
      do
         currentspace=`lvdisplay -c $i | awk -F":" '{print $8}'`
         neededspace=`expr $neededspace + $currentspace`
      done
   fi
   if [ $neededspace -gt $freespace ]
   then
      RC=$RC_NOT_ENOUGH_SPACE
   fi
# --------------------------------------
}

doSnapshot() {
#
# S N A P S H O T
#
# --------------------------------------
   getSetting "TIMESTAMP"
   timestamp=$_setting
   for i in `grep "^DATAPATH" $config | awk -F= '{print $2}' | xargs -I\{\} df \{\} | grep '^/' | awk '{print $1;}' | uniq `
   do
      vol=`sudo lvdisplay -c $i | awk -F: '{print $1;}'`
      storeSetting "VOLUME_DATA" $vol
      snapName=`basename $vol`_snap_$timestamp
      cmd="sudo lvcreate -s -n $snapName -l100%ORIGIN $vol"
      $RC=`eval $cmd`
      if [ $RC -neq 0 ]
      then
         echo "# Snapshotting of $vol failed"
         break
      fi
   done
   getSetting "DB2BACKUP_LOGS"
   includeLogs=$_setting
   if [ $includeLogs = "INCLUDE" -a $RC -eq 0 ]
   then
      for i in `grep "^LOGPATH" $config | awk -F= '{print $2}' | xargs -I\{\} df \{\} | grep '^/' | awk '{print $1;}' | uniq `
      do
         vol=`sudo lvdisplay -c $i | awk -F: '{print $1;}'`
         storeSetting "VOLUME_LOG" $vol
         snapName=`basename $vol`"_snap_"$timestamp
         cmd="sudo lvcreate -s -n $snapName -l100%ORIGIN $vol"
         $RC=`eval $cmd`
         if [ $RC -neq 0 ]
         then
            echo "# Snapshotting of $vol failed"
            break
         fi
      done
   fi
# --------------------------------------
}

doRestore() {
#
# R E S T O R E
#
# --------------------------------------

   getSetting "OBJ_ID"
   id=$_setting
   # Construct key to search for in currenct protocol file
   key="RESULT_"$id"_FILE"
   getSetting $key
   oldConfig=$_setting

   getSetting "TIMESTAMP" "" $oldConfig
   timestamp=$_setting
   for i in `grep "^VOLUME_DATA" $oldConfig | awk -F= '{print $2}'`
   do
      vol=$i"_snap_"$timestamp
      echo "# Unmounting volume $vol"
      sudo umount -f $i
      echo "# Merging volume $vol"
      sudo lvconvert --merge --background $vol
      if [ $? -neq 0 ]
      then
         echo "# Deactivating volume $vol"
         sudo lvchange -an $i
         echo "# Activating volume $vol"
         sudo lvchange -ay $i
      fi
      echo "# Mounting volume $vol"
      sudo mount $i
      echo "# Take the backup of volume $vol again"
      sudo lvcreate -s -n $vol -l100%ORIGIN $i
   done
   # if logs included
   getSetting "ACTION"
   readAction=$_setting
   if [ $readAction = "DB2ACS_ACTION_READ_BY_OBJECT" ]
   then
      for i in `grep "^VOLUME_LOG" $oldConfig | awk -F= '{print $2}'`
      do
         vol=$i"_snap_"${timestamp}
         echo "# Umounting volume $vol"
         sudo umount -f $i
         echo "# Merging volume $vol"
         sudo lvconvert --merge --background $vol
         if [ $? -neq 0 ]
         then
            echo "# Deactivating volume $vol"
            sudo lvchange -an $i
            echo "# Activating volume $vol"
            sudo lvchange -ay $i
         fi
         echo "# Mounting volume $vol"
         sudo mount $i
         echo "# Take the backup of volume $vol again"
         sudo lvcreate -s -n $vol -l100%ORIGIN $i
      done
   fi
# --------------------------------------
}

doDelete() {
#
# D E L E T E
#
# --------------------------------------
   getSetting "RESULT_"${objectId}"_FILE"
   oldConfig=$_setting
   getSetting "TIMESTAMP" "" $oldConfig
   timestamp=$_setting
   for i in `grep "^VOLUME_DATA" $oldConfig | awk -F= '{print $2}'`
   do
      vol=$i"_snap_"${timestamp}
      echo "# Volume $vol"
      echo "# "`sudo lvremove -f $vol`
   done
   getSetting "DB2BACKUP_LOGS" "" $oldConfig
   includeLogs=$_setting
   if [ $includeLogs = "INCLUDE" ]
   then
      for i in `grep "^VOLUME_LOG" $oldConfig | awk -F= '{print $2}'`
      do
         vol=$i"_snap_"${timestamp}
         echo "# Volume $vol"
         echo "# "`sudo lvremove -f $vol`
      done
   fi
   rm $oldConfig
# --------------------------------------
}

doVerify() {
#
# V E R I F Y
#
# --------------------------------------
   mkdir /tmp/verify
   getSetting "TIMESTAMP" "" $oldConfig
   timestamp=$_setting
   for i in `grep "^VOLUME_DATA" $config | awk -F= '{print $2}'`
   do
      vol=$i"_snap_"$timestamp
      sudo mount $vol /tmp/verify
      $RC=$?
      sudo umount /tmp/verify
      if [ $RC -neq 0 ]
      then
         echo "# Mounting of $vol failed"
         break
      fi
      echo "# Volume $i checked"
   done
   getSetting "DB2BACKUP_LOGS"
   includeLogs=$_setting
   if [ $includeLogs = "INCLUDE" -a $RC -eq 0 ]
   then
      for i in `grep "^VOLUME_LOG" $config | awk -F= '{print $2}'`
      do
         vol=$i"_snap_"$timestamp
         sudo mount $vol /tmp/verify
         $RC=$?
         sudo umount /tmp/verify
         if [ $RC -neq 0 ]
         then
            echo "# Mounting of $vol failed"
            break
         fi
         echo "# Volume $i checked"
      done
   fi
   rmdir /tmp/verify
# --------------------------------------
}

doStoreMetaData() {
# 
#  S T O R E  M E T A  D A T A
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
#  R O L L B A C K
#
# --------------------------------------
   for i in `grep "^VOLUME_DATA" $config | awk -F= '{print $2}'`
   do
      sudo lvremove $i_snap_$timestamp
   done
   getSetting "DB2BACKUP_LOGS"
   includeLogs=$_setting
   if [ $includeLogs = "INCLUDE" -a $RC -eq 0 ]
   then
      for i in `grep "^VOLUME_LOG" $config | awk -F= '{print $2}'`
      do
         sudo lvremove $i_snap_$timestamp
      done
   fi
# --------------------------------------
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

repository="`dirname $config`/"

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
