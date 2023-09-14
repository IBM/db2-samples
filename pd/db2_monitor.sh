#!/usr/bin/env bash
# sed -i 's/\x0D$//' script
#-------------------------------------------------------------------------------
# (C) COPYRIGHT International Business Machines Corp. 2004
# All Rights Reserved
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
#
# NAME: db2_monitor.sh
#
# FUNCTION: Script to collect monitoring data.
#
# The script is provided to you on an "AS IS" basis, without warranty of
# any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
# not allow for the exclusion or limitation of implied warranties, so the above
# limitations or exclusions may not apply to you. IBM shall not be liable for
# any damages you suffer as a result of using, copying, modifying or
# distributing the Sample, even if IBM has been advised of the possibility of
# such damages.
#
# Author: Rajib Sarkar (rsarkar@us.ibm.com)
# Revisions: BharatGoyal (bharat.goyal@ibm.com)
#
# History:
#----------------------
#
# 2019-12-12                    - First drop
# 
# 2020-01-08                    - Changed the -max default to infinite
#
# 2020-01-10                    - Added the Quick check options
#                                 -wlm          -- To get WLM state ( how many queries queued etc )
#                                 -sessions     -- How many queries active and more details of each
#                                 -transactions -- To get transaction log status
#                                 -explain      -- To get explains of top 10 long running queries
#                                 -tablespaces  -- To get tablespace usage status
#
# 2020-01-21                    - Added options -exfmt and -trace
#
# 2020-01-23                    - Changed the default of -max to 4 iterations ( which combined with 
#                                 default -period value amounts to 1 hour of data collection
#
# 2020-08-25                    - Added -explapp option to explain a apphandle
#
# 2020-12-10                    - Added -hang and -hangapp option
#
# 2021-01-05                    - Added db2trc under -perf full option
#
# 2021-08-24                    - Added -stop option to cleanly stop the program
#
# 2021-11-22                    - Added -hangdb2trc to turn on db2trc for -hangapp option. This was
#                                 due to a defect which causes a crash if db2trc was running. By
#                                 default, db2trc will not be taken for -hangapp option
# 2023-01-16                    - Major refactoring and add User ID fixes 
#                                 Over all general fixes after testing script 
#                                 added some features to -trace option and added perf record (BharatGoyal)
# 2023-02-08                    - added -noconnect and -nodb2pd sub-options to -hang option.
# 2023-02-13                    - added -localhost sub-options to -hang, -perf and -hangapp option.
# 2023-02-13                    - added -additionalcmd option to -hang, -perf and -hangapp option.
# 2023-02-28                    - added -nodumpall option to -hang full option.
# 2023-03-03                    - Added More parallelism in -hangapp, -hang, -perf options. Changed date "+%Y%m%d_%H%M%S" to date "+%Y-%m-%d-%H.%M.%S"
# 2023-03-05                    - Added -hadr option
# 2023-03-09                    - Added -ptimeout <N> and exfmt using execid.
# 2023-03-15                    - Better handling of backgroundprocess. Added descendent_pids
# 2023-05-08                    - Make sure OUTDIR is always absolute path.
# 2023-05-12                    - Added -watchquery
# 2023-07-18                    - Added CPU Info and ping commands in -sessions option.
#----------------------------------------------------------------------------------------------------------

trap "cleanup" 1 2 15

function log ()
{
	if [[ ! -z $LOGFILE ]] ; then 
		[[ -f "$LOGFILE" ]] && echo "`date`: ""$@" >> $LOGFILE
	fi
	
    if [ "x$VERBOSE" = "x1" ]; then
       echo "`date`: ""$@" 
    fi

}
##########################################################
## descendent_pids
## Function to get decendents of the pid.
##########################################################
descendent_pids() 
{
	pidtocheck="$1"
	if [[ ! -z "$pidtocheck" ]] ; then 
		#echo  "descendent_pids: $pidtocheck"
		for xxpid in `echo $pidtocheck`
		do 
			dpids=$(pgrep -P $xxpid)			
			if [[ ! -z $dpids ]] ; then 	
				#echo "dpids: $dpids"
				for xdpid in `echo $dpids`
				do
					[[ "x$PIDDETAILS" = "x1" ]] && echo "xdpid: $xdpid"
					[[ "x$PIDDETAILS" = "x1" ]] && ps -e -o user,pid,ppid,stime,cmd,lstart | grep -w $xdpid | grep -v grep
						
					checkbg=$( grep -wq $xdpid $PROCESSFILECHILD > /dev/null 2>&1; echo $? )   # CHECK IF THE PROCESS EXISTS IN THIS FILE OR NOT
					checkP=$( grep -wq $xdpid $PROCESSFILE > /dev/null 2>&1; echo $? )           # CHECK IF THE PROCESS EXISTS IN THIS FILE OR NOT			
					
					( ps -e -o user,pid,ppid,stime,cmd,lstart | grep -w $xdpid | grep -v grep ) | while read psLine; 
					do
						XElapEPOCH=$(date --date="$(echo $psLine | awk '{print $(NF-4),$(NF-3),$(NF-2),$(NF-1),$NF}')" '+%s')
						if [[ $XElapEPOCH -ge $SSTARTTIME ]] ; then 
							[[ $checkP -ne 0  ]] && echo "DEP PID: $psLine" >> $PROCESSFILE 2>&1
							[[ $checkbg -ne 0  ]] && echo $xdpid >> $PROCESSFILECHILD	
						else
							echo "descendent_pids: Process $xdpid may not be part of this script. Should not come here: $psLine"
						fi
					done							
					descendent_pids "$xdpid"
				done				
			fi
		done 
	fi
}
##########################################################
## RefreshRunningpids
## Refresh the list of running pids by checking if they are complete or running.
##########################################################

function RefreshRunningpids()
{	
		#( grep PID $PROCESSFILE 2> /dev/null |  grep -v "^DEP" 2> /dev/null | awk '{print $NF}' | awk '!x[$0]++' | awk NF )  >> $1
		#( grep PID $PROCESSFILE | awk '{ if (/^DEP PID:/) { if ( $6 != "DONECOMPLETE" && $7 != "DONECOMPLETE" )  { printf "%s\n%s\n", $6, $7 }  else if ( $6 != "DONECOMPLETE" && $7 == "DONECOMPLETE" )  { print $6 } else if ( $6 == "DONECOMPLETE" && $8 != "DONECOMPLETE" )  {  print $8 } } else { if ( $(NF-1) != "DONECOMPLETE" ) {  print $NF } } }'   | awk '!x[$0]++' | awk NF ) >> $1
		( grep PID $PROCESSFILE | awk '{ if (/^DEP PID:/) { if ( $4 != "DONECOMPLETE" && $5 != "DONECOMPLETE" )  { printf "%s\n%s\n", $4, $5 } else if ( $4 != "DONECOMPLETE" && $5 == "DONECOMPLETE" )  { print $4 } else if ( $4 == "DONECOMPLETE" && $6 != "DONECOMPLETE" )  {  print $6 } } else { if ( $(NF-1) != "DONECOMPLETE" ) {  print $NF } } }'   | awk '!x[$0]++' | awk NF ) >> $1
		## WatchPidArray=(`cat $1 | awk '{print $NF}' | sort -n | uniq | awk NF `) removed sorting and added below to remove duplication without sorting.
        WatchPidArray=(`cat $1 | tr -s ' ' '\n' | grep -v COPY | awk '{print $NF}' | awk '!x[$0]++' | awk NF `)
		#WatchPidArray+=(`grep PID $PROCESSFILE 2> /dev/null |  grep -v DEP 2> /dev/null | awk '{print $NF}' | awk '!x[$0]++' | awk NF `)
        RunningArray=()
		
		log "Checking running processes -  ${WatchPidArray[@]} "
        
		[[ "x$PIDDETAILS" = "x1" ]] && printf '\n\n'
		[[ "x$PIDDETAILS" = "x1" ]] && printf '%s\t' "`date` : Checking running processes -  ${WatchPidArray[@]} "
		[[ "x$PIDDETAILS" = "x1" ]] && printf '\n\n'
		
		#pattern=$( cat $1 | awk 'NF > 0 {printf("%s|",$NF)} ' | sed 's/.$//' )
		pattern=$(printf "%s|" "${WatchPidArray[@]}" | sed 's/.$//' )
		#echo $pattern
		
		[[ "x$PIDDETAILS" = "x1" && ! -z "$pattern" ]] &&  ps -elf | { head -1 ; egrep -w "$pattern" ; } | egrep -wv "grep|egrep"
		[[ "x$PIDDETAILS" = "x1" ]] && printf '\n\n'
		[[ "x$PIDDETAILS" = "x1" ]] && printf '\n%s\n\n' "$(date): Checking the processes 1 by 1 and updating the running processes list"
		[[ "x$PIDDETAILS" = "x1" ]] && printf '\n\n'
		
        for (( i = 0 ; i < ${#WatchPidArray[@]} ; i++))
        do
          [[ "x$DEBUG" == "x1" ]] &&  printf '%s\n' "$(date): Still left ${WatchPidArray[@]}"
          [[ "x$DEBUG" == "x1" ]] &&  printf '%s\n' "$(date): Checking pid [$i]: ${WatchPidArray[$i]}"
		   
          #check=$( kill -0 ${WatchPidArray[$i]} > /dev/null 2>&1; echo $? )
		  #ps -elf | grep -w ${WatchPidArray[$i]} | grep -v grep | wc -l
		 
		  #ps -e | grep -w ${WatchPidArray[$i]} | grep -v grep
		  #check=$( ps -e | grep -w ${WatchPidArray[$i]} | grep -v grep | wc -l )
		  PSetls=$(ps -p ${WatchPidArray[$i]} -o etimes=,lstart= )
		  #echo "PSetls: $PSetls PID: ${WatchPidArray[$i]}"
		  #echo " "
          #if [[ $check -gt 0  ]]; then   #PROCESS IS ACTIVE
		  if [[ ! -z $PSetls ]]; then   #PROCESS IS ACTIVE			
				
				ElapSec=$(echo $PSetls | cut -f 1 -d ' ')
				ElapEPOCH=$(date --date="$(echo $PSetls | cut -f 2- -d ' ')" '+%s')
				
				[[ "x$PIDDETAILS" = "x1" ]] && echo "`date` : PID: ${WatchPidArray[$i]} running since $ElapSec seconds and $ElapEPOCH EPOCH"
				[[ "x$PIDDETAILS" = "x1" ]] && ps -elf | grep -w ${WatchPidArray[$i]} | grep -v grep 
				
				if [[ $ElapSec -gt $PTIMEOUT ]]; then   #CHECK IF PTIMEOUT THRESHOLD IS REACHED.
																
					if [[ $ElapEPOCH -ge $SSTARTTIME ]] ; then  # Procss started after script start time.
						kill -TERM ${WatchPidArray[$i]} ; retchk "$?" "$LINENO" "kill -TERM ${WatchPidArray[$i]}" "$(hostname)" "Cannot kill ${WatchPidArray[$i]}" 					
						printf '\n%s PROCESS: %s\n' "`date`: Killed ${WatchPidArray[$i]} as it was running for $ElapSec seconds > $PTIMEOUT (Timeout) seconds. ($ElapEPOCH > $SSTARTTIME)" "$(grep -w ${WatchPidArray[$i]} $PROCESSFILE)"
					else
						printf '\n%s\n' "`date`: RefreshRunningpids: Process ${WatchPidArray[$i]} may not belong to script"
						ps -elf | grep -w ${WatchPidArray[$i]} | grep -v grep 
					fi
										
				else 				
					RunningArray+=(${WatchPidArray[$i]})
					descendent_pids "${WatchPidArray[$i]}"
				fi
          else  # Update th $PROCESSFILE with DONE Status
				sed -i "s/\b${WatchPidArray[$i]}\b/DONECOMPLETE ${WatchPidArray[$i]}/g" $PROCESSFILE >> $LOGFILE 2>&1
		  fi
        done
		log "Still running processes -  ${RunningArray[@]} "
        
		[[ "x$PIDDETAILS" = "x1" ]] && printf '\n\n'
		[[ "x$PIDDETAILS" = "x1" ]] && printf '%s\t' "`date` : Still running processes -  ${RunningArray[@]} "
		[[ "x$PIDDETAILS" = "x1" ]] && printf '\n\n'
		
        printf "%s\n" "${RunningArray[@]}" > $1
		if [[ -f "$PROCESSFILECHILD" ]] ; then 
		   for xpid in  `cat $PROCESSFILECHILD` 
		   do 
				xcheck=$( ps -e | grep -w $xpid | grep -v grep | wc -l ) 
				if [[ $xcheck -gt 0  ]]; then
					echo "$xpid" >> $1
				fi
		   done 
           echo -n "" > $PROCESSFILECHILD
		fi
}

##########################################
## SSH_KERNEL_STACK_DATA
## Common function with SSH to get kernel data
##########################################
function SSH_KERNEL_STACK_DATA ()
{
	if [ "x$DEBUG" == "x1" ]; then
         set -xv
	fi	
	
	PNAME="$1"
	DB2SYSC_PID="$2"
	host="$3"
	KERNELSTACKDIR="$4"
	TSTAMP="$5"
	IH="$6"
	MAXOSROUNDS="$7"
	
	if [[ $NUMHOSTS -gt 1 ]]; then
		  xssh="ssh $host \" "
		  xquote=" \" "
    else
		  xssh=""
		  xquote=""
    fi
	
    log "[OS data]: Getting kernel stacks from $host ( $PNAME = $DB2SYSC_PID ) - Round $IH of $MAXOSROUNDS"
	echo "`date`: [OS data]: Getting kernel stacks from $host ( $PNAME = $DB2SYSC_PID ) - Round $IH of $MAXOSROUNDS"             
	( eval "$xssh tail -n +1 /proc/$DB2SYSC_PID/task/*/stack $xquote" )   >> $KERNELSTACKDIR/kernelstack.$host.$DB2SYSC_PID.$IH.$TSTAMP 2>&1
	( eval "$xssh tail -n +1 /proc/$DB2SYSC_PID/task/*/syscall $xquote" ) >> $KERNELSTACKDIR/syscall.$host.$DB2SYSC_PID.$IH.$TSTAMP 2>&1
	( eval "$xssh tail -n +1 /proc/$DB2SYSC_PID/fdinfo/* $xquote" )       >> $KERNELSTACKDIR/fdinfo.$host.$DB2SYSC_PID.$IH.$TSTAMP 2>&1
	( eval "$xssh ls -l /proc/$DB2SYSC_PID/fd/* $xquote" )                >> $KERNELSTACKDIR/fd.$host.$DB2SYSC_PID.$IH.$TSTAMP 2>&1
	
	if [[ $nodb2pd_SET -eq "1" && $noconnect_SET -eq "1" ]]; then 
		log "[OS data]: Getting strace and pstack from $host ( $PNAME = $DB2SYSC_PID ) - Round $IH of $MAXOSROUNDS"
		echo "`date`: [OS data]: Getting strace and pstack from $host ( $PNAME = $DB2SYSC_PID ) - Round $IH of $MAXOSROUNDS" 
		( eval "$xssh timeout 5 strace -fttTyyy -s 1024 -p $DB2SYSC_PID $xquote" ) >>  $KERNELSTACKDIR/strace.$host.$DB2SYSC_PID.$IH.$TSTAMP 2>&1
		( eval "$xssh pstack $DB2SYSC_PID $xquote" )                           >> $KERNELSTACKDIR/pstack.$host.$DB2SYSC_PID.$IH.$TSTAMP 2>&1					
	fi

}
##########################################
## BACKGROUND_KERNEL_STACK_DATA
## Function to send this as background process for each host:
##########################################
function BACKGROUND_KERNEL_STACK_DATA ()
{
	if [ "x$DEBUG" == "x1" ]; then
         set -xv
	fi	
	
	host="$1"
	KERNELSTACKDIR="$2" 
	IH="$3" 
	TSTAMP="$4"
	MAXOSROUNDS="$5"

	if [[ $NUMHOSTS -gt 1 ]]; then
		  xssh="ssh $host \" "
		  xquote=" \" "
		  PREFIX="ps -elf | grep -w "
		  POSTFIX=" | grep -v grep | awk '{print \\\$4} ' | sort | uniq | tr '\n' ' ' "   # \\\$4 is needed to put \$4 in awk command in ssh.
    else
		  xssh=""
		  xquote=""
		  PREFIX="ps -elf | grep -w "
		  POSTFIX=" | grep -v grep | awk '{print \$4} ' | sort | uniq | tr '\n' ' ' "   # \$4 is needed to put $4 in awk command.

    fi	

	[[ "x$DEBUG" == "x1" ]] && echo "$(date): STMT: $xssh $PREFIX db2sysc $POSTFIX  $xquote EVAL: $( eval $xssh $PREFIX db2sysc $POSTFIX  $xquote )"
	
	for DB2SYSC_PID in $( eval "$xssh $PREFIX db2sysc $POSTFIX  $xquote" )
	do
		SSH_KERNEL_STACK_DATA "db2sysc" "$DB2SYSC_PID" "$host" "$KERNELSTACKDIR" "$TSTAMP" "$IH" "$MAXOSROUNDS"
	done
	
	for DB2SYSC_PID in $( eval "$xssh $PREFIX db2vend $POSTFIX $xquote" )
	do
		SSH_KERNEL_STACK_DATA "db2vend" "$DB2SYSC_PID" "$host" "$KERNELSTACKDIR" "$TSTAMP" "$IH" "$MAXOSROUNDS"
	done
	
	for DB2SYSC_PID in $( eval "$xssh $PREFIX db2ckpwd $POSTFIX $xquote" )
	do
		SSH_KERNEL_STACK_DATA "db2ckpwd" "$DB2SYSC_PID" "$host" "$KERNELSTACKDIR" "$TSTAMP" "$IH" "$MAXOSROUNDS"		 
	done
	
	for DB2SYSC_PID in $( eval "$xssh $PREFIX db2acd $POSTFIX $xquote" )
	do
		SSH_KERNEL_STACK_DATA "db2acd" "$DB2SYSC_PID" "$host" "$KERNELSTACKDIR" "$TSTAMP" "$IH" "$MAXOSROUNDS"		 				 
	done
	
	for DB2SYSC_PID in $( eval "$xssh $PREFIX db2fmp $POSTFIX $xquote" )
	do
		SSH_KERNEL_STACK_DATA "db2fmp" "$DB2SYSC_PID" "$host" "$KERNELSTACKDIR" "$TSTAMP" "$IH" "$MAXOSROUNDS"	 				 
	done
	
	if [[ $nodb2pd_SET -eq "1" && $noconnect_SET -eq "1" ]] ; then
	
	  for DB2SYSC_PID in $( eval "$xssh $PREFIX db2 $POSTFIX $xquote" )
	  do
			SSH_KERNEL_STACK_DATA "db2" "$DB2SYSC_PID" "$host" "$KERNELSTACKDIR" "$TSTAMP" "$IH" "$MAXOSROUNDS"		 				 				 
	  done
	  
	  for DB2SYSC_PID in $( eval "$xssh $PREFIX db2bp $POSTFIX $xquote" )
	  do
			SSH_KERNEL_STACK_DATA "db2bp" "$DB2SYSC_PID" "$host" "$KERNELSTACKDIR" "$TSTAMP" "$IH" 	"$MAXOSROUNDS"	 					 
	  done	
	  
	fi
	
    origsysrqVal=$( eval $xssh cat /proc/sys/kernel/sysrq $xquote )

    log "Original value of sysrq on $host = $origsysrqVal - Round $IH of $MAXOSROUNDS "
    printf '%s\n' "$(date): [OS data]: Collecting kernel stacks using dmesg on host $host - Round $IH of $MAXOSROUNDS "

    ( eval "$xssh echo 1 > /proc/sys/kernel/sysrq $xquote" )
    ( eval "$xssh echo t > /proc/sysrq-trigger $xquote" )
    ( eval "$xssh dmesg -T $xquote" ) >> $KERNELSTACKDIR/dmesg.kernelstacks.$host.$IH.$TSTAMP 2>&1
    ( eval "$xssh echo $origsysrqVal" > /proc/sys/kernel/sysrq $xquote )

    log "Collecting Perf Record for 20 seconds on $host - Round $IH of $MAXOSROUNDS "
	printf '%s\n' "$(date): [OS data]: Collecting Perf Record for 20 seconds on $host - Round $IH of $MAXOSROUNDS "
	
	( eval "$xssh perf record -a  -o $KERNELSTACKDIR/perf.record.$host.$IH.$TSTAMP sleep 20 ; perf report --stdio -n -f -i $KERNELSTACKDIR/perf.record.$host.$IH.$TSTAMP $xquote" ) >> $KERNELSTACKDIR/perf.report.$host.$IH.$TSTAMP 2>&1 
	
	( eval "$xssh cp /usr/include/asm/unistd_64.h $KERNELSTACKDIR/unistd_64.h.$host.$IH.$TSTAMP $xquote" )
	
	chmod -R 777 "$KERNELSTACKDIR"
	
}

##########################################
## CollectKernelStacksData
## Collect Db2 kernel stacks
##########################################
function CollectKernelStacksData ()
{
	if [ "x$DEBUG" == "x1" ]; then
         set -xv
	fi
  
	KERNELSTACKDIR="$1"
	IH="$2"
	TSTAMP="$3"
	MAXOSROUNDS="$4"
	
	for host in `echo $HOSTS`
	do
		BACKGROUND_KERNEL_STACK_DATA "$host" "$KERNELSTACKDIR" "$IH" "$TSTAMP" "$MAXOSROUNDS" &	
		childpidBKSD=$( echo $! )
		echo $childpidBKSD >> $TMPFILE
		echo "BACKGROUND_KERNEL_STACK_DATA PID: $childpidBKSD" >> $PROCESSFILE 2>&1
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "BACKGROUND_KERNEL_STACK_DATA PID: $childpidBKSD"
	done
}

####################################################
#### Function CheckifOUTDIRisWritableByAll
#### CHECK IF THE OUTPUT PATH IS WRITABLE ##########
####################################################

function CheckifOUTDIRisWritableByAll ()
{

if [[ $ISROOT -eq "1" && $NUMHOSTS -gt "1" ]]; then

   for ihost in `echo $HOSTS`
   do
	  [[ "x$DEBUG" == "x1" ]] && echo "ssh $ihost \" ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR )\" "
	  [[ "x$DEBUG" == "x1" ]] && echo "ssh $ihost \"( sudo -u $DB2INSTANCEUSER test -w $OUTDIR && sudo -u $DB2INSTANCEUSER test -r $OUTDIR && sudo -u $DB2INSTANCEUSER test -x $OUTDIR ) \""
      ssh $ihost " ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR )"  ; retchk "$?" "$LINENO" "ssh $ihost \" ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR )\"" "$ihost" "Path: `hostname`:$OUTDIR not writable/readable/executable by user $RUN_USER on host $ihost" "D"
      ssh $ihost "( sudo -u $DB2INSTANCEUSER test -w $OUTDIR && sudo -u $DB2INSTANCEUSER test -r $OUTDIR && sudo -u $DB2INSTANCEUSER test -x $OUTDIR ) " ; retchk "$?" "$LINENO" "ssh $ihost \"( sudo -u $DB2INSTANCEUSER test -w $OUTDIR && sudo -u $DB2INSTANCEUSER test -r $OUTDIR && sudo -u $DB2INSTANCEUSER test -x $OUTDIR ) \"" "$ihost" "Path: `hostname`: $OUTDIR not writable/readable/executable by user $DB2INSTANCEUSER on host $ihost" "D"
   done

elif [[ $ISROOT -eq "0" && $NUMHOSTS -gt "1" ]]; then

   for ihost in `echo $HOSTS`
   do
	  [[ "x$DEBUG" == "x1" ]] && echo "ssh $ihost \" ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR ) \""
      ssh $ihost " ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR ) " ; retchk "$?" "$LINENO" "ssh $ihost \" ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR ) \"" "$ihost" "Path: `hostname`: $OUTDIR not writable/readable/executable by user $RUN_USER on host $ihost" "D"
   done

elif [[ $ISROOT -eq "1" && $NUMHOSTS -eq "1" ]]; then
	
	 [[ "x$DEBUG" == "x1" ]] && echo "( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR )"
     ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR ) ; retchk "$?" "$LINENO" "( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR )" "$(hostname)" "Path: $OUTDIR not writable/readable/executable by user $RUN_USER on host $(hostname)" "D"
       sudo -u $DB2INSTANCEUSER  test -w $OUTDIR && sudo -u $DB2INSTANCEUSER test -r $OUTDIR && sudo -u $DB2INSTANCEUSER test -x $OUTDIR  ; retchk "$?" "$LINENO" "sudo -u $DB2INSTANCEUSER  test -w $OUTDIR && sudo -u $DB2INSTANCEUSER test -r $OUTDIR && sudo -u $DB2INSTANCEUSER test -x $OUTDIR" "$(hostname)" "Path: $OUTDIR not writable/readable/executable by user $DB2INSTANCEUSER on host $(hostname)" "D"

elif [[ $ISROOT -eq "0" && $NUMHOSTS -eq "1" ]]; then
	
	 [[ "x$DEBUG" == "x1" ]] && echo "( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR )"
     ( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR ) ; retchk "$?" "$LINENO" "( test -w $OUTDIR && test -r $OUTDIR && test -x $OUTDIR )" "$(hostname)" "Path: $OUTDIR not writable/readable/executable by user $RUN_USER on host $(hostname)" "D"

else
        printf '\n\n%s\n' "Should not come here"
        exit 0
fi

}

##########################################################
## waitforpid
## Waits for the Pid in the file to be completed. DOSLEEP parameter if NOT SET then this function waits for all the process to complete, else just keeps a list of processes that are running
##########################################################

function waitforpid ()
{
	## WatchPidArray=(`cat $1 | awk '{print $NF}' | sort -n | uniq | awk NF `) removed sorting and added below to remove duplication without sorting.
	XWatchPidArray=(`cat $1 | tr -s ' ' '\n' | grep -v COPY | awk '{print $NF}' | awk '!x[$0]++' | awk NF `)
	
	[[ "x$PIDDETAILS" = "x1" ]] &&  printf '%s\t' "$(date): Waiting for the proceses to Complete ${XWatchPidArray[@]} "
	log "Waiting for the proceses to Complete ${XWatchPidArray[@]} "
					
	for (( i = 0 ; i < ${#XWatchPidArray[@]} ; i++))
	do
	  
	  [[ "x$PIDDETAILS" = "x1" ]] &&  printf '\n\n%s\n' "$(date): Checking pid [$i]: ${XWatchPidArray[$i]}"
	  # check=$( kill -0 ${XWatchPidArray[$i]} > /dev/null 2>&1; echo $? )
	  check=$( ps -e | grep -w ${XWatchPidArray[$i]} | grep -v grep | wc -l )
	
	  if [[ $check -gt 0  ]]; then   #PROCESS IS ACTIVE
			
			[[ "x$PIDDETAILS" = "x1" ]] &&  printf '\n\n%s\n' "$( date ): ${XWatchPidArray[$i]} is Running"
			echo "$( date ): ${XWatchPidArray[$i]} is Running" >> $LOGFILE 2>&1
			sleep 3
			#Commented this as this will always run outside if/else
			#RefreshRunningpids "$TMPFILE"
			
	  else
			TODELETE=${XWatchPidArray[$i]}
			temp_array=()

			for Dvalue in "${XWatchPidArray[@]}"
			do
			   [[ $Dvalue != $TODELETE ]] && temp_array+=($Dvalue)
			done
			XWatchPidArray=("${temp_array[@]}")
			[[ -z $DOSLEEP ]] && echo "$( date ): $TODELETE Completed. PID still left ${temp_array[@]}" >> $LOGFILE 2>&1
			unset temp_array
	  fi
	  # RESET THE FOR LOOP COUNTER and Append PIDLIST FROM TEMPFILE to add new PIDS
	  ## XWatchPidArray=(`cat $1 | awk '{print $NF}' | sort -n | uniq | awk NF `) removed sorting and added below to remove duplication without sorting.
	  RefreshRunningpids "$TMPFILE"
	  XWatchPidArray+=(`cat $TMPFILE | tr -s ' ' '\n' | grep -v COPY | awk '{print $NF}' | awk '!x[$0]++' | awk NF `)	  
	  i=-1
	done
}
##########################################################
## cleanup
## Cleanup and exit
##########################################################
function cleanup ()
{
	DELETEOUTDIR="$1"
	CLEANUPCOUNT=$(( CLEANUPCOUNT + 1 ))
	# IF TMPFILE IS NOT SET.
	
	if [[ -z $TMPFILE ]] ; then	
	
		if [[ -e "/tmp/.tmp.dbmonitorpid" ]]; then 
			pidfortempfile=$( cat "/tmp/.tmp.dbmonitorpid" )
		else
			pidfortempfile=0
		fi
		
		if [[ -e /tmp/.dbmonitor.$pidfortempfile ]] ; then
			TMPFILE=/tmp/.dbmonitor.$pidfortempfile
			printf '\n\n%s\n' "TMPFILE contining child PID's was not set. Setting TMPFILE to $TMPFILE" 
		else 
			printf '\n\n%s\n' "TMPFILE contining child PID's does not exist. This should not happen! Setting TMPFILE to dummy file /tmp/.dbmonitor.dummy just to have the script completed."
			touch /tmp/.dbmonitor.dummy
			chmod 777 /tmp/.dbmonitor.dummy
			TMPFILE=/tmp/.dbmonitor.dummy
		fi
	fi
	
	[[ -z $OUTDIR ]] && OUTDIR=$PWD && printf '\n\n%s\n' "OUTDIR was not set, so setting it to $PWD".
		
    printf '\n%s\n' "`date`: Stopping the script `basename $0` "
	log "`date`: Stopping the script `basename $0` "
	
    if [[ "x$TYPECOLLECT" = "x1" || "x$TYPECOLLECT" = "x2" || "x$QUICKWATCH" || "x$QUICKHADR" != "x" || "x$QUICKHANGAPP" != "x" || "x$STOPSCRIPT" != "x" || "x$QUICKTRACE" != "x" || $ecl1_SET -eq "1" ||  $ecl0_SET -eq "1" ]]; then  

       log "Cleaning up"
       printf '\n%s\n' "`date`: Cleaning up"
	   
	   if [[ -e $TMPFILE ]] ; then 

		  printf '\n\n%s\n' "*******************************************************************************************************************"
		  printf '\n%s\n' "Don't kill or Press CNTL+c / CNTL+d now as script is cleaning up background processess as part of cleanup"
		  printf '\n%s\n' "*******************************************************************************************************************"
		  
		  printf '\n%s\n' "`date`: File: $TMPFILE . Killing pids: `cat $TMPFILE | tr -s ' ' '\n' | grep -v COPY | awk '{print $NF}' | sort | uniq | tr '\n' ' ' ` "
		  log "`date`: File: $TMPFILE . Killing pid: `cat $TMPFILE | tr -s ' ' '\n' | grep -v COPY | awk '{print $NF}' | sort | uniq | tr '\n' ' ' ` "
		  
		  RefreshRunningpids "$TMPFILE"
		   	   
		  for pid in `cat $TMPFILE | tr -s ' ' '\n' | grep -v COPY | awk '{print $NF}' | sort -n | uniq | awk NF `  
		  do			   
			  #check=$( kill -0 $pid > /dev/null 2>&1; echo $? )
			  check=$( ps -e | grep -w $pid | grep -v grep | wc -l )
			  if [[ $check -gt 0  ]]; then
					 
				  printf '\n%s\n' "Pid: $pid - echo $( ps -x --forest | grep $pid )"
				  kill -TERM $pid ; retchk "$?" "$LINENO" "kill -TERM $pid" "$(hostname)" "Cannot kill $pid" 
				  printf '\n%s\n' "`date`: File: $files - Killed $pid "
				  log "`date`: File: $files - Killed $pid "					  
			  fi		  
		  done
	   fi
	   
	   log "Exiting program `basename $0` "

	   if [[ ! -z "$DB2INSTANCEUSER" ]]; then
		  printf '\n%s\n' "`date`: Turning off db2trc" 
		  log "`date`: Turning off db2trc" 
		  ParallelSSH "db2trc off $Db2trcMemAll " "$OUTDIR/db2_traceOFF.cleanup.$tstamp" "$ISROOT" "1" "DB2"  #Forfully turning off all members as by chance if it remains active.	  
	   fi
	   
    fi

	if [[ $EVMONSET -eq 1 ]]; then 
		printf '\n\n%s\n' "$(date): Disabling event monitor: USER_ACTUALS"	
		ParallelSSH "db2 -v connect to $DBNAME ; db2 -v set event monitor USER_ACTUALS state 0 ; db2 -v Alter workload USER_ACTUALS DISABLE ;  db2 -v drop workload USER_ACTUALS ; db2 -v \"SELECT substr(evmonname, 1, 30) as EVMONNAME , event_mon_state(evmonname) as STATE FROM syscat.eventmonitors WHERE evmonname = 'USER_ACTUALS' \" ; db2 -v terminate " "$OUTDIR/db2_EventMonitor.cleanup.$tstamp" "$ISROOT" "1" "DB2"
	fi  	
	
	printf '\n%s\n' "`date`: Deleting rahout files if any"
	log "`date`: Deleting rahout files if any"
	
	if [[ -f "$LOGFILE" ]] ; then 
			ls -lrt /tmp/"$DB2INSTANCEUSER"/rahout.*	>> $LOGFILE 2>&1
			rm -rf /tmp/"$DB2INSTANCEUSER"/rahout.*	>>  $LOGFILE 2>&1
			ls -lrt /tmp/"$DB2INSTANCEUSER"/rahout.*	>> $LOGFILE 2>&1	
			echo "Processes info after killing sub processes" >> $LOGFILE 2>&1	
			ps -elf --forest >> $LOGFILE 2>&1	
		
	else 
			ls -lrt /tmp/"$DB2INSTANCEUSER"/rahout.* 
			rm -rf /tmp/"$DB2INSTANCEUSER"/rahout.*	
			ls -lrt /tmp/"$DB2INSTANCEUSER"/rahout.*			
	fi		
	
	printf '\n%s\n' "`date`: Deleting $TMPFILE and /tmp/.tmp.dbmonitorpid"
    log "`date`: Deleting $TMPFILE and /tmp/.tmp.dbmonitorpid"

	rm -f $TMPFILE  ; retchk "$?" "$LINENO" "rm -f $TMPFILE" "$(hostname)" "Cannot remove file $TMPFILE" 
	printf '\n%s\n' "`date`: Deleted: $TMPFILE "
	log "Deleted: $TMPFILE "
	
    rm -f /tmp/.tmp.dbmonitorpid 2>/dev/null ; retchk "$?" "$LINENO" "rm -f /tmp/.tmp.dbmonitorpid 2>/dev/null" "$(hostname)" "Cannot remove file /tmp/.tmp.dbmonitorpid"
	printf '\n%s\n' "`date`: Deleted: /tmp/.tmp.dbmonitorpid "
    log "Deleted: /tmp/.tmp.dbmonitorpid "
	
	[[ ! -z $DELETEOUTDIR ]] && [[ $DELETEOUTDIR = "D" ]] && ( rm -rf $OUTDIR ) && ( printf '\n%s\n' "`date`: Deleted $OUTDIR" )
	
    mypid=$( echo $$ )
	check=$( kill -0 $mypid > /dev/null 2>&1; echo $? )
    [[ $check -eq 0 && $CLEANUPCOUNT -lt 2 ]] && kill -TERM $mypid
	
    exit 0
}

##########################################################
## check_empty
## Checks if a variable is empty
#########################################################
function check_empty ()
{
   CKEY="$1"
   CVALUE="$2"
   check=$( echo "$CVALUE" | grep "^[-]" > /dev/null 2>&1; echo $? )
   
   if [[ "x$CVALUE" == "x" || $check == 0 ]]; then
       
         printf '\n\n%s\n\n' "WARNING: $CKEY is empty or $CVALUE is not valid."
		 
         exit 0;
    fi
}
##########################################################
## is_int
## Check if Number is +vs integer.
#########################################################
function is_int() { 
case "$1" in
    ''|*[!0-9]*) echo 1 ;;
    *) echo 0 ;;
esac
}

####################################################################################################################
## ParallelSSH
## Sends ssh command to server in parallel in background if NUMHOSTS>1 else just send to same server
###################################################################################################################

function ParallelSSH ()
{
  if [ "x$DEBUG" == "x1" ]; then
         set -xv
  fi
  
    COMMAND="$1"
    OUTPUTFILE="$2"
    ISROOT="$3"
	XNUMHOSTS="$4"
	CMDTYPE="$5"
	BACKGROUND="$6"

	[[ "x$DEBUG" == "x1" || "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): Command: $COMMAND"
	[[ "x$DEBUG" == "x1" || "x$VERBOSE" = "x1" ]] && printf '%s\n' "$(date): OutputFile: $OUTPUTFILE ISROOT: $ISROOT XNUMHOSTS: $XNUMHOSTS CMDTYPE: $CMDTYPE BACKGROUND: $BACKGROUND "
	
	log "Command: $COMMAND OutputFile: $OUTPUTFILE ISROOT: $ISROOT XNUMHOSTS: $XNUMHOSTS CMDTYPE: $CMDTYPE BACKGROUND: $BACKGROUND "
	 
	if [[ $ISROOT -eq 1 ]]; then
		
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE ISROOT=TRUE"
		
		if [[ "$CMDTYPE" == "DB2" ]]; then
			
			[[ "x$DEBUG" == "x1" ]] && echo "INSIDE COMMAND TYPE DB2"

			if [[ $XNUMHOSTS -gt "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND DPF $COMMAND"
sudo -i -u $DB2INSTANCEUSER bash << EOF
			  [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv
			  ( RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` rah "|| $COMMAND " ) > $OUTPUTFILE
			  [[ "x$PIDDETAILS" = "x1" ]] && set +xv			  
EOF
			elif [[ $XNUMHOSTS -gt "1" && ! -z $BACKGROUND ]]; then
				 [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND DPF $COMMAND"
sudo -i -u $DB2INSTANCEUSER bash << EOF
			  [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv
			  ( RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` rah "|| $COMMAND " ) > $OUTPUTFILE &
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  jobs -l
			   printf 'COPY rah : %s : %s\n' '`echo "$COMMAND" | sed "s/'/!/g" `' " \$( jobs -p )" >> $PROCESSFILE 2>&1
			   echo "COPY \$( jobs -p )"  >> $TMPFILE
			   [[ "x$PIDDETAILS" = "x1" ]] && set +xv			   
EOF
			elif [[ $XNUMHOSTS -eq "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND SINGLE $COMMAND"
sudo -i -u $DB2INSTANCEUSER bash << EOF
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv
				( eval $COMMAND ) > $OUTPUTFILE 2>&1
				[[ "x$PIDDETAILS" = "x1" ]] && set +xv
EOF
			else
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE ELSE BACKGROUND SINGLE $COMMAND"
sudo -i -u $DB2INSTANCEUSER bash << EOF
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv				
			   ( eval $COMMAND ) > $OUTPUTFILE  2>&1 &
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && jobs -l
			   printf 'COPY eval : %s PID: %s\n'  '`echo "$COMMAND" | sed "s/'/!/g" `' " \$( jobs -p )" >> $PROCESSFILE 2>&1
			   echo "COPY \$( jobs -p )"  >> $TMPFILE
			   [[ "x$PIDDETAILS" = "x1" ]] && set +xv			   
EOF
			fi   

		elif [[ "$CMDTYPE" == "DB2PD" ]]; then
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE COMMAND TYPE DB2PD"

			if [[ $XNUMHOSTS -gt "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND DPF $COMMAND" 
sudo -i -u $DB2INSTANCEUSER bash << EOF
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv
			   ( eval $COMMAND ) > $OUTPUTFILE 2>&1
			   [[ "x$PIDDETAILS" = "x1" ]] && set +xv			   
EOF
		   elif [[ $XNUMHOSTS -gt "1" && ! -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND DPF $COMMAND" 
sudo -i -u $DB2INSTANCEUSER bash << EOF
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv
			   ( eval $COMMAND ) > $OUTPUTFILE 2>&1 &
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && jobs -l
			   printf 'COPY eval : %s PID: %s\n'  '`echo "$COMMAND" | sed "s/'/!/g" `' " \$( jobs -p )" >> $PROCESSFILE 2>&1
			   echo "COPY \$( jobs -p )"  >> $TMPFILE
			   [[ "x$PIDDETAILS" = "x1" ]] && set +xv			   
EOF
			elif [[ $XNUMHOSTS -eq "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND SINGLE $COMMAND" 
sudo -i -u $DB2INSTANCEUSER bash << EOF
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv
    		   ( eval $COMMAND ) > $OUTPUTFILE 2>&1
			   [[ "x$PIDDETAILS" = "x1" ]] && set +xv
EOF
			else
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE ELSE BACKGROUND SINGLE $COMMAND" 
sudo -i -u $DB2INSTANCEUSER bash << EOF
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && set -xv
			   ( eval $COMMAND ) > $OUTPUTFILE 2>&1 &
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && jobs -l
			   printf 'COPY eval PID: %s : %s\n'  '`echo "$COMMAND" | sed "s/'/!/g" `' " \$( jobs -p )" >> $PROCESSFILE 2>&1
			   echo "COPY \$( jobs -p )"  >> $TMPFILE
			   [[ "x$PIDDETAILS" = "x1" ]] && set +xv
EOF
			fi   
			
		else
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE COMMAND TYPE OS"
			if [[ $XNUMHOSTS -gt "1" && -z $BACKGROUND ]]; then
               [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND DPF $COMMAND" 
			   for iserver in `echo $HOSTS`  ;
				   do
				  ( ssh -t -t -n $iserver "date; $COMMAND 2>&1" 2>&1 | sed -e "s/^/from $iserver `date '+%Y-%m-%d-%H.%M.%S.%N'` :/" )
			   done > $OUTPUTFILE

			elif [[ $XNUMHOSTS -gt "1" && ! -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND DPF $COMMAND" 
			   for iserver in `echo $HOSTS`  ;
			   do
				   ( ssh -t -t -n $iserver "date; $COMMAND 2>&1" 2>&1 | sed -e "s/^/from $iserver `date '+%Y-%m-%d-%H.%M.%S.%N'` :/" ) &
					childpidssh=$( echo $! )
					echo $childpidssh >> $TMPFILE
					echo "ssh -t -t -n $iserver $COMMAND PID: $childpidssh" >> $PROCESSFILE 2>&1
					[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "ssh -t -t -n $iserver $COMMAND PID: $childpidssh"
					
			   done > $OUTPUTFILE &
			   childpidfor=$( echo $! )
			   echo $childpidfor >> $TMPFILE
			   echo "for iserver in echo HOSTS $COMMAND PID: $childpidfor" >> $PROCESSFILE 2>&1
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "for iserver in echo HOSTS $COMMAND PID: $childpidfor"

			elif [[ $XNUMHOSTS -eq "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND SINGLE $COMMAND" 
				( eval " $COMMAND " ) > $OUTPUTFILE 2>&1

			else
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND SINGLE $COMMAND" 
				( eval " $COMMAND " ) > $OUTPUTFILE  2>&1 &
				childpideval=$( echo $! )
				echo $childpideval >> $TMPFILE
				echo "$COMMAND PID: $childpideval" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "$COMMAND PID: $childpideval"
			fi
		fi			
	else   #NO ISROOT
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE ISROOT=FALSE"
		if [[ "$CMDTYPE" == "DB2" ]]; then
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE COMMAND TYPE DB2"
			if [[ $XNUMHOSTS -gt "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND DPF $COMMAND" 
			   ( RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` rah "|| $COMMAND " ) > $OUTPUTFILE 2>&1
			   
			elif [[ $XNUMHOSTS -gt "1" && ! -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND DPF $COMMAND" 
			   ( RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` rah "|| $COMMAND " ) > $OUTPUTFILE 2>&1 &
			   	childpidrah=$( echo $! )
				echo $childpidrah >> $TMPFILE
				echo "rah || $COMMAND PID: $childpidrah" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "rah || $COMMAND PID: $childpidrah"

			elif [[ $XNUMHOSTS -eq "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND SINGLE $COMMAND" 
				( eval " $COMMAND " ) > $OUTPUTFILE 2>&1

			else
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE ELSE BACKGROUND SINGLE $COMMAND" 
				( eval " $COMMAND " ) > $OUTPUTFILE  2>&1 &
				childpideval=$( echo $! )
				echo $childpideval >> $TMPFILE
				echo "$COMMAND PID: $childpideval" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "$COMMAND PID: $childpideval"
			fi   
		elif [[ "$CMDTYPE" == "DB2PD" ]]; then
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE COMMAND TYPE DB2PD"
			if [[ $XNUMHOSTS -gt "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND DPF $COMMAND" 
			   ( eval $COMMAND ) > $OUTPUTFILE 2>&1  

			   
			elif [[ $XNUMHOSTS -gt "1" && ! -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND DPF $COMMAND" 
			   ( eval $COMMAND ) > $OUTPUTFILE 2>&1 &
			   	childpideval=$( echo $! )
				echo $childpideval >> $TMPFILE
				echo "$COMMAND PID: $childpideval" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "$COMMAND PID: $childpideval"

			elif [[ $XNUMHOSTS -eq "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND SINGLE $COMMAND" 
				( eval $COMMAND ) > $OUTPUTFILE 2>&1

			else
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE ELSE BACKGROUND SINGLE $COMMAND" 
				( eval $COMMAND ) > $OUTPUTFILE  2>&1 &
				childpideval=$( echo $! )
				echo $childpideval >> $TMPFILE
				echo "$COMMAND PID: $childpideval" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "$COMMAND PID: $childpideval"
			fi   
		else
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE COMMAND TYPE OS"
			if [[ $XNUMHOSTS -gt "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND DPF $COMMAND" 
			   for iserver in `echo $HOSTS`  ;
			   do
				  ( ssh -t -t -n $iserver "date; $COMMAND 2>&1" 2>&1 | sed -e "s/^/from $iserver `date '+%Y-%m-%d-%H.%M.%S.%N'` :/" )
			   done > $OUTPUTFILE

			elif [[ $XNUMHOSTS -gt "1" && ! -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND DPF $COMMAND" 
			   for iserver in `echo $HOSTS`  ;
			   do
				   ( ssh -n -t -t $iserver "date; $COMMAND 2>&1" 2>&1 | sed -e "s/^/from $iserver `date '+%Y-%m-%d-%H.%M.%S.%N'` :/" ) &
					childpidssh=$( echo $! )
					echo $childpidssh >> $TMPFILE
					echo "ssh -n -t -t $iserver $COMMAND PID: $childpidssh" >> $PROCESSFILE 2>&1
					[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "ssh -n -t -t $iserver $COMMAND PID: $childpidssh"
			   
			   done > $OUTPUTFILE &
			   childpidfor=$( echo $! )
			   echo $childpidfor >> $TMPFILE
			   echo "for iserver in echo HOSTS $COMMAND PID: $childpidfor" >> $PROCESSFILE 2>&1
			   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "for iserver in echo HOSTS $COMMAND PID: $childpidfor"

			elif [[ $XNUMHOSTS -eq "1" && -z $BACKGROUND ]]; then
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE NOBACKGROUND SINGLE $COMMAND" 
				( eval " $COMMAND " ) > $OUTPUTFILE 2>&1

			else
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "INSIDE BACKGROUND SINGLE $COMMAND" 
				( eval " $COMMAND " ) > $OUTPUTFILE  2>&1 &
				childpideval=$( echo $! )
				echo $childpideval >> $TMPFILE
				echo "$COMMAND PID: $childpideval" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "$COMMAND PID: $childpideval"

			fi
		fi	
	fi
}


##########################################################
## read_arguments
## Read command line arguments
#########################################################
function read_arguments()
{
    #set -xv
    if [ "x$DEBUG" = "x1" ]; then

        set -xv

    fi
	
	DuplicateParmCnt=$(echo "$@" | tr ' ' '\n' | egrep -v '^$|^y|^Y|^n|^N' | grep -v -x -E '[0-9]+' | sort -rf | uniq -ci | sort -k 1,1nr | awk '{if ($1 > 1) {print $2}}')
	
	if [[ ! -z "$DuplicateParmCnt" ]] ; then 
		printf '\n\n'
		for dx in `echo "$DuplicateParmCnt"`
		do
			printf '%s\n' "Duplicate argument: $dx provided!! Bailing out!!"
		done
		printf '\n\n'
		exit 0
	fi 
	isParm=0

    while [ $# -gt 0 ]
    do

        input_command=$1

        check=$( echo "$input_command" | grep "^[-]" > /dev/null 2>&1; echo $? )

        if  [ $check -ne 0 ]; then

            log "WARNING: Command line option $input_command ignored as it is invalid"
            printf '\n\n%s\n\n' "WARNING: Command line option $input_command ignored as it is invalid"
            isParm=1

        fi
       
        case "$input_command" in
         
           -h|-help|"-?") usage ;;

           "-period"    ) shift 1

                          PERIOD=$1
                       
                          checkifdash=$(echo $PERIOD | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                          if [ $checkifdash -eq 1 ]; then

                              printf '\n%s\n' "Invalid value provided to -period option!! bailing out"
                              usage
                          fi

                          checkval=$( echo $PERIOD | bc )

                          if [ $checkval -lt 1 ]; then
                                PERIOD=900
                          fi

                          isParm=1                       
                          ;;

           "-max"       ) shift 1

                          MAX=$1

                          checkifdash=$(echo $MAX | awk '{ if( match($0,"^-")) { if (match ($0,"^-1")) print 0; else print 1 ;}  else print 0; }' )

                          if [ $checkifdash -eq 1 ]; then

                              printf '\n%s\n' "Invalid value provided to -max option!! bailing out"
                              usage

                          fi

                          checkval=$( echo $MAX | bc )

                          if [ $checkval -lt 1 ]; then
                                 MAX=9999999

                          elif [ $checkval -eq 0 ]; then
                                 MAX=4
                          fi

                          isParm=1

                          ;;


           "-service"   )  shift 1

                           SERVICEPASSWORD=$1

                           checkifdash=$(echo $SERVICEPASSWORD | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                           if [ $checkifdash -eq 1 ]; then

                               printf '\n%s\n' "Invalid value provided to -service option !! bailing out"
                               usage

                           fi
                           check_empty "-service" "$SERVICEPASSWORD"
                           isParm=1;;

           "-ptimeout"   )  shift 1

                           PTIMEOUT=$1

                           checkifdash=$(echo $PTIMEOUT | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                           if [ $checkifdash -eq 1 ]; then

                               printf '\n%s\n' "Invalid value provided to -ptimeout option !! bailing out"
                               usage

                           fi
						   if [[ $( is_int "$PTIMEOUT" ) != 0 ]]; then
								printf '\n\n%s\n' "-ptimeout $PTIMEOUT is invalid!. -ptimeout only takes number"
								usage
						   fi
                           isParm=1;;

						   
           "-perf"      )  shift 1

                           TYPE=$1

                           checkifdash=$(echo $TYPE | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                           if [ $checkifdash -eq 1 ]; then

                               printf '\n%s\n' "Invalid value provided to -perf option!! baling out"
                               usage
                           fi
                           
                           if [[ "x$TYPE" = "xbasic" || "x$TYPE" = "xBASIC" ]]; then
                               TYPECOLLECT=1
							   
                           elif [[ "x$TYPE" = "xfull" || "x$TYPE" = "xFULL" ]]; then
                               TYPECOLLECT=2
							   
						   else
    						   printf '\n%s\n' "Invalid value $TYPE provided to -perf option!! baling out"
                               usage
                           fi

                           isParm=1;;

           "-hang"      ) shift 1

                          HANGTYPE=$1

                          checkifdash=$( echo $HANGTYPE | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                          if [ $checkifdash -eq 1 ]; then

                              printf '\n%s\n' "Invalid value provided to -hang option!! baling out"
                              usage
                          fi

                           if [[ "x$HANGTYPE" = "xbasic" || "x$HANGTYPE" = "xBASIC" ]]; then

                               HANGTYPECOLLECT=1
                           elif [[ "x$HANGTYPE" = "xfull" || "x$HANGTYPE" = "xFULL" ]]; then

                               HANGTYPECOLLECT=2
						   else 
                              printf '\n%s\n' "Invalid value $HANGTYPE provided to -hang option!! baling out"
                              usage								
                           fi

                          isParm=1
						  
						  # PROCESS SUBOPTIONS like hangrounds
						  #set -x
						  #echo "$#"
						  #echo "$@"				
						  tstart=2
						  TVAL=2
						  xinput_command=$(eval echo \${$TVAL})
						  check=$( echo "$xinput_command" | egrep "^\-hangrounds|^\-noconnect|^\-nodb2pd" > /dev/null 2>&1; echo $? )
					      while [ $check -eq 0 ]
						  do
							case "$xinput_command" in
							
								"-hangrounds" ) TVAL=$(( 1 + TVAL ))
											   HANGROUNDS=$(eval echo \${$TVAL})
   											   if [[ $( is_int "$HANGROUNDS" ) != 0 ]]; then
											   
												  printf '\n\n%s\n' "-hangrounds $HANGROUNDS is invalid!. -hangrounds only takes number"
												  usage												  
											   fi

											   TVAL=$(( TVAL + 1 ))
											   hangrounds_SET=1
											;;		
											
								"-noconnect" ) TVAL=$(( 1 + TVAL ))
											   NOCONNECT=$(eval echo \${$TVAL})
											   if [[ $NOCONNECT != 'Y' && $NOCONNECT != 'y' ]]; then
												  printf '\n\n%s\n' "-noconnect $NOCONNECT is invalid!. Can only be Y "
												  usage 
											   fi
											   TVAL=$(( TVAL + 1 ))
											   noconnect_SET=1
											   ;;
											   
								"-nodb2pd" )   TVAL=$(( 1 + TVAL ))
											   NODB2PD=$(eval echo \${$TVAL})
											   if [[ $NODB2PD != 'Y' && $NODB2PD != 'y' ]]; then
												  printf '\n\n%s\n' "-nodb2pd $NODB2PD is invalid!. Can only be Y "
												  usage 
											   fi
											   TVAL=$(( TVAL + 1 ))
											   nodb2pd_SET=1
											   ;;											   
							esac
							xinput_command=$(eval echo \${$TVAL})
							check=$( echo "$xinput_command" | egrep "^\-hangrounds|^\-noconnect|^\-nodb2pd" > /dev/null 2>&1; echo $? )
						  done
						  shift $(( TVAL - tstart ))					
						  #echo $HANGROUNDS
                          ;;

         "-kernelstack" ) KERNELSTACK=1
                          isParm=1;;

           "-wlm"       ) QUICKWLM=1
                          isParm=1;;

           "-hadr"       ) QUICKHADR=1
						  
						  # PROCESS SUBOPTIONS like hangdb2trc and hrounds
						  #set -x
						  #echo "$#"
						  #echo "$@"				
						  tstart=2
						  TVAL=2
						  xinput_command=$(eval echo \${$TVAL})
						  check=$( echo "$xinput_command" | egrep "^\-hrounds" > /dev/null 2>&1; echo $? )
					      while [ $check -eq 0 ]
						  do
							case "$xinput_command" in
							
								"-hrounds" ) TVAL=$(( 1 + TVAL ))
											   HROUNDS=$(eval echo \${$TVAL})
   											   if [[ $( is_int "$HROUNDS" ) != 0 ]]; then
											   
												  printf '\n\n%s\n' "-hrounds $HROUNDS is invalid!. -hrounds only takes number"
												  usage												  
											   fi

											   TVAL=$(( TVAL + 1 ))
											   hrounds_SET=1
											;;
											   
							esac
							xinput_command=$(eval echo \${$TVAL})
							check=$( echo "$xinput_command" | egrep "^\-hrounds" > /dev/null 2>&1; echo $? )
						  done
						  shift $(( TVAL - tstart ))
						  #echo $HHANGDB2TRC
						  #echo $HROUNDS
						  isParm=1
                          ;;						  

         "-transactions") QUICKTRANSACTIONS=1
                          isParm=1;;

           "-sessions"  ) QUICKSESSIONS=1
                          isParm=1;;

          "-tablespaces") QUICKTABLESPACES=1
                          isParm=1;;

          "-explapp"|"-explainapp" ) shift 1

                          QUICKEXPLAINAPP=$1

                          checkifdash=$(echo $QUICKEXPLAINAPP | awk '{ if( match($0,"^-")) print 1; else print 0; }' )
                     
                          if [ $checkifdash -eq 1 ]; then

                              printf '\n%s\n' "Invalid value provided to -explapp option!! bailing out"
                              usage
                          fi

                          isNumeric=$( echo $QUICKEXPLAINAPP | perl -ne 'if( /\d+,\d+.*\d$/ or /^\d+$/ ){ print "1"; } else { print 0; }' )

                          if [ "x$isNumeric" = "x0" ]; then

                             printf '\n%s\n' "Invalid apphandles provided to -explapp option ! bailing out "
                             usage
                          fi

                          isParm=1;;


           "-hangapp"   ) shift 1

                          QUICKHANGAPP=$1

                          checkifdash=$( echo $QUICKHANGAPP | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                          if [ $checkifdash -eq 1 ]; then

                              printf '\n%s\n' "Invalid value provided to -hangapp option!! bailing out"
                              usage
                          fi

                          isNumeric=$( echo $QUICKHANGAPP | perl -ne 'if( /\d+,\d+.*\d$/ or /^\d+$/ ){ print "1"; } else { print 0; }' )

                          if [ "x$isNumeric" = "x0" ]; then

                             printf '\n%s\n' "Invalid apphandles provided to -hangapp option ! bailing out "
                             usage
                          fi

                          isParm=1
						  
						  # PROCESS SUBOPTIONS like hangdb2trc and hrounds
						  #set -x
						  #echo "$#"
						  #echo "$@"				
						  tstart=2
						  TVAL=2
						  xinput_command=$(eval echo \${$TVAL})
						  check=$( echo "$xinput_command" | egrep "^\-hangdb2trc|^\-hrounds|^\-hstacks|^\-hreorgchk" > /dev/null 2>&1; echo $? )
					      while [ $check -eq 0 ]
						  do
							case "$xinput_command" in
							
							   "-hstacks"  )   TVAL=$(( 1 + TVAL ))
											   HHSTACKS=$(eval echo \${$TVAL})
											   if [[ ${#HHSTACKS} -gt 1 || "${HHSTACKS}" =~ [^a-zA-Z] ]]; then
											   
												  printf '\n\n%s\n' "-hstacks $HHSTACKS is invalid!. -hstacks only Y|N"
												  usage
												  
											   elif [[ $HHSTACKS == 'Y' || $HHSTACKS == 'y' ]]; then
											   
												  HHSTACKS_SET=1											   												  
											   else
											   
												  HHSTACKS_SET=0													  
											   fi
											   TVAL=$(( TVAL + 1 ))
										   ;;  

							   "-hreorgchk"  )   TVAL=$(( 1 + TVAL ))
											   HHREORGCHK=$(eval echo \${$TVAL})
											   if [[ ${#HHREORGCHK} -gt 1 || "${HHREORGCHK}" =~ [^a-zA-Z] ]]; then
											   
												  printf '\n\n%s\n' "-hreorgchk $HHREORGCHK is invalid!. -hreorgchk only Y|N"
												  usage
											   
											   elif [[ $HHREORGCHK == 'Y' || $HHREORGCHK == 'y' ]]; then
											   
												  HHREORGCHK_SET=1											   												  
											   else
											   
												  HHREORGCHK_SET=0													  
											   fi
											   TVAL=$(( TVAL + 1 ))
										   ;;  
										   
							   "-hangdb2trc"  ) TVAL=$(( 1 + TVAL ))
											   HHANGDB2TRC=$(eval echo \${$TVAL})
											   if [[ ${#HHANGDB2TRC} -gt 1 || "${HHANGDB2TRC}" =~ [^a-zA-Z] ]]; then
											   
												  printf '\n\n%s\n' "-hangdb2trc $HHANGDB2TRC is invalid!. -hangdb2trc only Y|N"
												  usage
											   
											   elif [[ $HHANGDB2TRC == 'Y' || $HHANGDB2TRC == 'y' ]]; then
											   
												  HANG_DB2TRC=1											   											   
											   else
												
												  HANG_DB2TRC=0	
											   fi
											   
											   TVAL=$(( TVAL + 1 ))
											   hangdb2trc_SET=1
										   ;;  
								"-hrounds" ) TVAL=$(( 1 + TVAL ))
											   HROUNDS=$(eval echo \${$TVAL})
   											   if [[ $( is_int "$HROUNDS" ) != 0 ]]; then
											   
												  printf '\n\n%s\n' "-hrounds $HROUNDS is invalid!. -hrounds only takes number"
												  usage												  
											   fi

											   TVAL=$(( TVAL + 1 ))
											   hrounds_SET=1
											;;
											   
							esac
							xinput_command=$(eval echo \${$TVAL})
							check=$( echo "$xinput_command" | egrep "^\-hangdb2trc|^\-hrounds|^\-hstacks|^\-hreorgchk" > /dev/null 2>&1; echo $? )
						  done
						  shift $(( TVAL - tstart ))
						  #echo $HHANGDB2TRC
						  #echo $HROUNDS
                          ;;

                          
           "-explain"   ) shift 1                    
		   
                          QUICKEXPLAIN=$1

                          checkifdash=$(echo $QUICKEXPLAIN | awk '{ if( match($0,"^-")) print 1; else print 0; }' )
						  
                          if [ $checkifdash -eq 1 ]; then

                              printf '\n%s\n' "Invalid value provided to -explain option!! bailing out"
                              usage
                          fi

                          isNumeric=$( echo $QUICKEXPLAIN | awk '{ if( match($0,"^[0-9]+$") ) print 1; else print 0; }' )

                          if [ "x$isNumeric" = "x1" ]; then

                              QUICKEXPLAIN=$( echo $QUICKEXPLAIN | awk '{ print int( $0 ); }' )						  							  
						  else 

                              QUICKEXPLAIN="SORT"
                          fi

                          isParm=1;;

           "-exfmt"     ) shift 1

                          QUICKEXFMT=$1

                          if [ "x$QUICKEXFMT" = "x" ]; then

                             printf '\n\n%s\n' "Must provide a file containing SQL statement OR executable_id to -exfmt OR SP to explain a Stored Procedure !! Bailing out"
                             usage 
                          fi

                          checkifdash=$(echo $QUICKEXFMT | awk '{ if( match($0,"^-")) print 1; else print 0; }' )


                          if [ $checkifdash -eq 1 ]; then

                              printf '\n\n%s\n' "Must provide a file containing SQL statement OR executable_id to -exfmt OR SP to explain a Stored Procedure !! Bailing out"                             
                              isParm=0
							  exit 0
                          else

                              isParm=1
                          fi
						  # PROCESS SUBOPTIONS like cl1
						  #set -x
						  #echo "$#"
						  #echo "$@"				
						  tstart=2
						  TVAL=2
						  xinput_command=$(eval echo \${$TVAL})
						  check=$( echo "$xinput_command" | egrep "^\-ecl1|^\-ecl0" > /dev/null 2>&1; echo $? )
					      while [ $check -eq 0 ]
						  do
							case "$xinput_command" in					

							    "-ecl1" ) TVAL=$(( 1 + TVAL ))
											   ecl1=$(eval echo \${$TVAL})
											   if [[ $ecl1 != 'Y' && $ecl1 != 'y' ]]; then
												  printf '\n\n%s\n' "-ecl1 $ecl1 is invalid!. Can only be Y "
												  usage 
											   fi
											   TVAL=$(( TVAL + 1 ))
											   ecl1_SET=1
											   ;;
							    "-ecl0" ) TVAL=$(( 1 + TVAL ))
											   ecl0=$(eval echo \${$TVAL})
											   if [[ $ecl0 != 'Y' && $ecl0 != 'y' ]]; then
												  printf '\n\n%s\n' "-ecl0 $ecl0 is invalid!. Can only be Y "
												  usage 
											   fi
											   TVAL=$(( TVAL + 1 ))
											   ecl0_SET=1
											   ;;											   
							esac
							xinput_command=$(eval echo \${$TVAL})
							check=$( echo "$xinput_command" | egrep "^\-ecl1|^\-ecl0" > /dev/null 2>&1; echo $? )
						  done
						  shift $(( TVAL - tstart ))
						  #echo $TTIMEOUT
						  #echo $TTABLEORG					  

                          ;;
           "-additionalcmd" ) 	shift 1
								ADDITIONALCMD=$1

							  if [ "x$ADDITIONALCMD" = "x" ]; then

								 printf '\n\n%s\n' "Must provide a file containing addtional commands as per correct format. See Usage."					 
								 usage 
							  fi

							  checkifdash=$(echo $ADDITIONALCMD | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

							  if [ $checkifdash -eq 1 ]; then
								  printf '\n\n%s\n' "Must provide a file containing addtional commands as per correct format. See Usage."									  
								  isParm=0
							  else
								 if [[ ! -f "$ADDITIONALCMD" ]]; then
									printf '\n\n%s\n' "File: $ADDITIONALCMD does not exist. Bailing Out !! "
									exit 0
								 else								 
									isParm=1
									ADDITIONALCMD_SET=1
								 fi
							  fi				  

                          ;;
						  
           "-trace"     ) shift 1

                          QUICKTRACE=$1                     

                          if [ "x$QUICKTRACE" = "x" ]; then

                             printf '\n\n%s\n' "Must provide a file containing SQL statement to -trace !! Bailing out"
                             usage 

                          fi
                          
                          if [[ ! -f "$QUICKTRACE" ]]; then
                             printf '\n%s\n' "File $QUICKTRACE does not exist."
                             exit 0
                           fi

                          checkifdash=$(echo $QUICKTRACE | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                          if [ $checkifdash -eq 1 ]; then

                              printf '\n\n%s\n' "Must provide a file containing SQL statement to -trace !! Bailing out"                             
                              usage

                          elif [ $checkifdash -eq 0 ]; then

                              checkifsemicolon=$( cat $QUICKTRACE | grep -v "\-\-" | awk '/./{line=$0} END{print line}' | xargs | awk 'BEGIN{found=0}{ if( match($0,";$")) found=1; }END{ if( found ) print 1; else print 0; }' )

                              if [ $checkifsemicolon -eq 0 ]; then

                                  printf '\n\n%s\n' "SQL file must have an terminating semi-colon!! Bailing out"
								  exit 0
                                  isParm=0
                              else

                                  isParm=1
                              fi
                          fi
						  
						  # PROCESS SUBOPTIONS like TTABLEORG and TTIMEOUT
						  #set -x
						  #echo "$#"
						  #echo "$@"				
						  tstart=2
						  TVAL=2
						  xinput_command=$(eval echo \${$TVAL})
						  check=$( echo "$xinput_command" | egrep "^\-ttimeout|^\-ttableorg|^\-tdb2batch|^\-tdb2evmon" > /dev/null 2>&1; echo $? )
					      while [ $check -eq 0 ]
						  do
							case "$xinput_command" in
							
								"-ttimeout"  ) TVAL=$(( 1 + TVAL ))
											   TTIMEOUT=$(eval echo \${$TVAL})
											   
											   if [[ $( is_int "$TTIMEOUT" ) != 0 ]]; then
												  printf '\n\n%s\n' "-ttimeout $TTIMEOUT is invalid!. -ttimeout only takes number"
												  usage 
											   fi

											   TVAL=$(( TVAL + 1 ))
											   ttimeout_SET=1
											   ;;
											   
								"-ttableorg" ) TVAL=$(( 1 + TVAL ))
											   TTABLEORG=$(eval echo \${$TVAL})
											   if [[ $TTABLEORG != 'C' && $TTABLEORG != 'c' && $TTABLEORG != 'R' && $TTABLEORG != 'r' ]]; then
												  printf '\n\n%s\n' "-ttableorg $TTABLEORG is invalid!. Can only be C or R."
												  usage 
											   fi
											   TVAL=$(( TVAL + 1 ))
											   ttableorg_SET=1
											   ;;

								"-tdb2batch" ) TVAL=$(( 1 + TVAL ))
											   TDB2BATCH=$(eval echo \${$TVAL})
											   if [[ $TDB2BATCH != 'Y' && $TDB2BATCH != 'y' ]]; then
												  printf '\n\n%s\n' "-tdb2batch $TDB2BATCH is invalid!. Can only be Y "
												  usage 
											   fi
											   TVAL=$(( TVAL + 1 ))
											   tdb2batch_SET=1
											   ;;

							    "-tdb2evmon" ) TVAL=$(( 1 + TVAL ))
											   tdb2evmon=$(eval echo \${$TVAL})
											   if [[ $tdb2evmon != 'Y' && $tdb2evmon != 'y' ]]; then
												  printf '\n\n%s\n' "-tdb2evmon $tdb2evmon is invalid!. Can only be Y "
												  usage 
											   fi
											   TVAL=$(( TVAL + 1 ))
											   tdb2evmon_SET=1
											   ;;
											   
							esac
							xinput_command=$(eval echo \${$TVAL})
							check=$( echo "$xinput_command" | egrep "^\-ttimeout|^\-ttableorg|^\-tdb2batch|^\-tdb2evmon" > /dev/null 2>&1; echo $? )
						  done
						  shift $(( TVAL - tstart ))
						  #echo $TTIMEOUT
						  #echo $TTABLEORG
                          ;;

           "-watchquery" ) shift 1

                          QUICKWATCH="$1"

                          if [ "x$QUICKWATCH" = "x" ]; then

                             printf '\n\n%s\n' "Must provide query text to match !! Bailing out"
                             usage 

                          fi                         

                          checkifdash=$(echo $QUICKWATCH | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                          if [ $checkifdash -eq 1 ]; then

                              printf '\n\n%s\n' "Must provide query text to match !! Bailing out"                           
                              usage
                          else
							  isParm=1
                          fi
						  
                        ;;

           "-notrc"     ) PERF_NOTRC=1                    
                          isParm=1;;
						  
           "-noq1"     ) NOQ1=0     		   
                         isParm=1;;
						 
           "-noq2"     ) NOQ2=0                    
                         isParm=1;;
						 
           "-noq3"     ) NOQ3=0                    
                         isParm=1;;
						 
           "-noq4"     ) NOQ4=0                    
                         isParm=1;;	

           "-noq5"     ) NOQ5=0                    
                         isParm=1;;							 
						  
           "-nodumpall" ) PERF_NODUMPALL=1                    
                          isParm=1;;						  

           "-localhost" ) LOCALHOST=1                    
                          isParm=1;;						  

           "-all"       ) QUICKALL=1
                          isParm=1;;

           "-stop"      ) STOPSCRIPT=1
                          isParm=1;;

           "-keep"      ) shift 1

                          KEEP=$1

                          checkifdash=$(echo $KEEP | awk '{ if( match($0,"^-")) print 1; else print 0; }' )

                          if [ $checkifdash -eq 1 ]; then

                              printf '\n%s\n' "Invalid value provided to -keep option!! bailing out"
                              usage
                          fi

                          checkval=$( echo $KEEP | bc )

                          if [ $checkval -lt 1 ];then

                              KEEP=-1
                          else

                              KEEP=$( echo "$KEEP*60" | bc )
                          fi

                          isParm=1;;


          -d|-db|-dbname) shift 1
						  DBNAME=$1
                          check_empty "-d|-db|-dbname" "$DBNAME"
                          isParm=1;;

           "-outdir"   ) shift 1
                         OUTPUTDIR=$1
                         isParm=1;;

#           "-outfile"  ) shift 1
#                         OUTPUTFILE=$1
#                         isParm=1;;
                         
           
           "-instance" ) shift 1
           
                         # checking if user exits
                         
                         if [[ $ISROOT == 1 &&  `id -u $1 2>/dev/null || echo -1` -lt 0 ]]; then                                                         
                             
                             if [[ `id -u db2inst1 2>/dev/null || echo -1` -lt 0 ]]; then  # db2inst1 also does not exit
                             
                                 printf '\n%s\n' "The script is running as ROOT and Instance User: $1 does not exist, and default instance db2inst1 also does not exist. Bailing out "
                                 exit 0
                                                                                             
                             else 
                                 printf '\n%s\n' "$(date): The script is running as ROOT and Instance User: $1 does not exist! Setting default instance: db2inst1"
                                 DB2INSTANCEUSER="db2inst1"
                                 isParm=1
                             fi
                             
                         elif [[ $ISROOT == 1 &&  `id -u $DB2INSTANCEUSER 2>/dev/null || echo -1` -ge 0 ]]; then
						 
							 DB2INSTANCEUSER=$1
                             printf '\n%s\n' "$(date): The script is running as ROOT, setting db2instance: $DB2INSTANCEUSER "                                                          
                             isParm=1
                             
                         elif [[ $ISROOT == 1 && -z $1 ]]; then
                           
                             printf '\n%s\n' "The script is running as ROOT, please supply correct instance name for -instance option"
                             usage 
                             exit 0
                 
                         elif [[ $ISROOT == 0 ]] ; then 
                                                    
                             printf '\n%s\n' "The script is not running as ROOT, so -instance option is only needed when script is executed as ROOT, otherwise run this script only as db2 instance user."
                             usage 
                             exit 0                           
                         else
                             printf '\n%s\n' "-instance option is only needed when script is executed as ROOT, otherwise run this script only as db2 instance user."                         
                             usage 
                             exit 0                                                                                     
                         fi                                                                          
                         ;;

           "-verbose"  ) VERBOSE=1
                         isParm=1;;
						 
           "-piddetails"  ) PIDDETAILS=1
                         isParm=1;;
						 
           "-debug"    ) DEBUG=1
                         isParm=1;;

           "-norun"    ) NORUN=1
                         isParm=1;;

                      *) printf '\n\n%s\n\n' "Invalid option $input_command used !!"
                         usage 
                         exit 0;;
        esac

        shift 1

    done  

    if [ $isParm -eq 0 ]; then

        printf '\n\n%s\n\n' "No valid params found !!! Exiting"
        usage 

    fi
   #exit 0	
}

############################################################
## usage
## print usage for script
###########################################################

function usage()
{
    printf '\n'
    printf '\n%s\n\n'   "Program to collect Db2 Perf/Hang data"
    printf '%s\n\n'     "Synopsis:"
    printf '%s\n\n'     "`basename $0` [ Options ]"
    printf '%s\n\n'     "Performance data gather options:"

    printf '\t%s\n\n'   "-perf  [basic|full]          -- Collect long term performance data on the system ( Db2 and OS )"
    printf '\t%s\n'     "                             -- Basic collection:"
    printf '\t%s\n'     "                                 a) Basic WLM information   ( overall resource usage )"
    printf '\t%s\n'     "                                 b) Basic db2pd information ( query, locks, latches, memory, bufferpool  )"
    printf '\t%s\n'     "                                 c) Basic MON information   ( Query info, Queueing )"
    printf '\t%s\n'     "                                 d) OS info                 ( vmstat, iostat )"
    printf '\t%s\n'     "                                 e) db2mon                  "	
    printf '\t%s\n'     "                             -- Full  collection:"
    printf '\t%s\n'     "                                 a) WLM information         ( overall resource usage, per query usage info, internal wlm information )"
    printf '\t%s\n'     "                                 b) db2pd information       ( query, tablespace, locks, latches, memory, bufferpool, tcbstat, catalogcache, transactions )"
    printf '\t%s\n'     "                                 c) Basic MON information   ( Query info, Queueing, disk spill, explain plan of top 10 long running queries )"
    printf '\t%s\n'     "                                 d) OS info                 ( vmstat, iostat, netstat, memory info, cpuinfo, disk stats )"
    printf '\t%s\n'     "                                 e) db2trc                  ( CDE_PERF_TRACE for BLU instances, normal trace for non-BLU )"
    printf '\t%s\n'     "                                 f) db2mon"
    printf '\t\t%s\n\n' "-notrc                -- To not take db2trc with -perf full option"
	printf '\t\t%s\n\n' "-noq1                 -- To not collect mon queries batch 1 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq2                 -- To not collect mon queries batch 2 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq3                 -- To not collect mon queries batch 3 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq4                 -- To not collect mon queries batch 4 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq5                 -- To not collect mon queries batch 5 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-localhost            -- To collect data only on host: `hostname`. Only applicable for multinode systems. (Default: All hosts) "
	printf '\t\t%s\n\n' "-additionalcmd <file> -- To run additional commands. See below for the format of this file."		

    printf '%s\n\n'     "Options which can only be used with -perf option"

    printf '\t\t%s\n'   "-period               -- The cadence in seconds ( Default: 900 seconds )"
    printf '\t\t%s\n'   "-max                  -- Maximum number of iterations ( Default: 4 ). If you want to run forever, enter -1 for this"
    printf '\t\t%s\n'   "-keep                 -- How many hour(s) worth of data to keep ( Default: Keep ALL )"

    printf '\t\t%s\n'   "                         If user chooses the forever option ( max -1 ) and -keep option is not chosen"
    printf '\t\t%s\n\n' "                         the script will keep the last 2hours worth of data"
	
    printf '%s\n\n'     "Hang data collection options:"

    printf '\t%s\n\n'   "-hang  [basic|full] [-hangrounds <N>] [-noconnect Y] [-nodb2pd Y] [-kernelstack] -- Collect hang information"

    printf '\t%s\n'     "                             -- Basic collection:"
    printf '\t%s\n'     "                                 a) -perf basic and"
    printf '\t%s\n'     "                                 b) db2pd -stack all across all servers"
    printf '\t%s\n'     "                             -- Full collection:"
    printf '\t%s\n'     "                                 a) -perf full"
    printf '\t%s\n'     "                                 b) db2pd -dump all across all servers"
    printf '\t%s\n\n'   "                                 c) OS info ( vmstat, iostat, netstat, memory info, cpuinfo, disk stats )"
    printf '\t%s\n\n'   "                                 d) db2trc ( CDE_PERF_TRACE for BLU instances, normal trace for non-BLU )"	

    printf '\t\t%s\n'   "-hangrounds <N>       -- Collect <N> rounds of data collection every 60 seconds. ( Default: 2 ) "
	printf '\t\t%s\n\n' "-noconnect Y          -- Not to connect to Database with -hang full option. With this option no mon queries will be executed, that is no connection to database ( Default: Not set )."
	printf '\t\t%s\n\n' "-nodb2pd Y            -- No db2pd commands with -hang full option. With this option no db2pd commands will be executed ( Default: Not set )"
	printf '\t\t%s\n\n' "                      -- When -noconnect Y -nodb2pd Y -notrc -kernelstack are used together, script will just collect OS data and is useful to diagnose complete hang situation. (Pstack and Strace)"
	printf '\t\t%s\n\n' "                      -- This command has positional parameters, please respect sub-options positions. Sub-options should always be after the main command and should be together. "
    printf '\t\t%s\n'   "-kernelstack          -- Collect kernel stacks of DB2 processes ( db2sysc, db2fmp ) and perf record for 20 seconds"
    printf '\t\t%s\n'   "                         !!NOTE!! If this option is chosen, then -hang must be run as user root"
	printf '\t\t%s\n\n' "-notrc                -- To not take db2trc with -hang full option"
	printf '\t\t%s\n\n' "-noq1                 -- To not collect mon queries batch 1 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq2                 -- To not collect mon queries batch 2 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq3                 -- To not collect mon queries batch 3 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq4                 -- To not collect mon queries batch 4 in collect_mon_data_PERF_HANG"
	printf '\t\t%s\n\n' "-noq5                 -- To not collect mon queries batch 5 in collect_mon_data_PERF_HANG"	
	printf '\t\t%s\n\n' "-nodumpall            -- To not to take db2pd -dump all with -hang full option. It will run db2pd -stack all"	
	printf '\t\t%s\n\n' "-localhost            -- To collect data only on host: `hostname`. Only applicable for multinode systems. (Default: All hosts) "
	printf '\t\t%s\n\n' "-additionalcmd <file> -- To run additional commands. See below for the format of this file."	
	
    printf '%s\n\n'     "Quick data collection options:"
    printf '\t%s\n'     "-wlm                  -- Print the current WLM details ( also collect internal WLM data )"
    printf '\t%s\n'     "-transactions         -- Print the current transaction log usage status"
    printf '\t%s\n'     "-tablespaces          -- Print the current tablespace usage status"
    printf '\t%s\n'     "-sessions             -- Print the current status of the running queries"
    printf '\n\t%s\n'   "-explain <val>        -- Get the explains of the top <val> long running queries which are running for "
    printf '\t%s\n'     "                         more than <val> minutes. Limits to top 10 queries ( Default: 10 minutes )"
    printf '\t%s\n'     "-explain sort         -- Get the explains of the top 5 sort consuming queries"

    printf '\n\t%s\n'   "-explapp|-explainapp <app,[app<n>] "
    printf '%s\n'       "                                      -- Get the explains of the queries running under the apphandle(s) "
    printf '%s\n'       "                                         Multiple apphandles can be provided in comma-delimited way"

    printf '\n\t%s\n'   "-exfmt [<sqlfile>|\"execid\"|SP] [-ecl1 Y | -ecl0 Y] "
    printf '%s\n'       "                                       -- Get exfmt plan for the query in <sqlfile>"
	printf '\t\t%s\n'   "-ecl1 Y                -- Collect db2support CL1 for the query. Only valid when <sqlfile> is provided"
	printf '\t\t%s\n'   "-ecl0 Y                -- Collect db2support CL0 for the query."
	printf '\t\t%s\n'   "SP                        To explain for a Stored procedure "
	printf '\t\t%s\n'   "\"execid\"                  To explain for executable_id"
	printf '\t\t%s\n'   "                          execid should be provided in double quotes. It will not work if double quotes are not enclosed."
	printf '\t\t%s\n'   "Example:                  \"x'010000000000000038F600000000000000000000020020230309085509834143'\" "

    printf '\n\t%s\n'   "-trace <sqlfile> [-ttimeout <X>] [-ttableorg <C|R>] [-tdb2batch Y] [-tdb2evmon Y]"
    printf '%s\n'       "                                      -- Get db2trace for the query in <sqlfile>"
    printf '\t\t%s\n'   "-ttimeout <X>         -- In Seconds & should be X+20% time where X is good/expected runtime of the query ( Default: 600 seconds ) ."
    printf '\t\t%s\n'   "-ttableorg <C|R>      -- C = COLUMN/CDE, R = ROW. ( Default: if DB2_WORKLOAD=ANALYTICS then C else R)"
    printf '\t\t%s\n'   "-tdb2batch Y          -- Run db2batch instead of db2bp. ( Default: db2bp )"
    printf '\t\t%s\n'   "-tdb2evmon Y          -- Collect section actuals explains using activity event monitor. ( Default: NO section_actuals ) "
    printf '\t\t%s\n'   "                         if -ttimeout and -ttableorg are NOT specified, it will ask to confirm timeout and table organization"
    printf '\t\t%s\n'   "                         (Default: values wil be taken if no key is pressed in 20 seconds)"
	printf '\t\t%s\n\n' "                      -- This command has positional parameters, please respect sub-options positions. Sub-options should always be after the main command and should be together. "

    printf '\n\t%s\n'   "-quickwatch 'querytext' -- Get Explain from section of a query which we dont know when it will execute. "
	printf '%s\n'       "                                      It will start as a demon and check every 5 seconds (Max it will run for 24 hours), once it sees the query it will collect explain from section "
	
    printf '\n\t%s\n'   "-hangapp <app,[app<n>] [-hstacks <Y|N>] [-hreorgchk <Y|N>] [-hangdb2trc <Y|N>] [-hrounds <N>]"
    printf '%s\n'       "                                      -- Get the hang information for the apphandles"
    printf '%s\n'       "                                         Multiple apphandles can be provided in comma-delimited way"
    printf '%s\n'       "                                         If run as root, it will also collect kernel stacks and perf record for 20 seconds."
    printf '\t\t%s\n'   "-hangdb2trc <Y|N>     -- Turn on db2trc for the hung application handle ( Default: NO db2trc )"
    printf '\t\t%s\n'   "-hrounds <N>          -- Takes N rounds of data collection. ( Default: 2 )"
    printf '\t\t%s\n'   "-hstacks <Y|N>        -- Turns on Stack collection for all the applications agents ( Default: NO stack all )"
    printf '\t\t%s\n'   "-hreorgchk <Y|N>      -- Collects REORGCHK for all tables in database. [ Default: Y ]"
	printf '\t\t%s\n\n' "                      -- This command has positional parameters, please respect sub-options positions. Sub-options should always be after the main command and should be together. "
	printf '\t\t%s\n\n' "-localhost            -- To collect data only on host: `hostname`. Only applicable for multinode systems. (Default: All hosts) "
	printf '\t\t%s\n\n' "-additionalcmd <file> -- To run additional commands. See below for the format of this file."	

	printf '\n'
    printf '\n\t%s\n'   "-hadr [-hrounds <N>] [-additionalcmd <file>] "
	printf '%s\n'       "                                      -- Collect data related to HADR. Used to diagnose HADR issus."
	printf '\t\t%s\n'   "-hrounds <N>          -- Takes N rounds of data collection. ( Default: 2 )"
	printf '\t\t%s\n\n' "-additionalcmd <file> -- To run additional commands. See below for the format of this file."	

    printf '\n'
    printf '\n\t%s\n\n' "-all                  -- Run ALL the Quick check options ( except -exfmt, -explapp, -trace and -hangapp )"

    printf '%s\n\n'     "General options:"
    printf '\t%s\n'     "-service <password>   -- Provide the service password to the script. It will be provided by IBM Support"
    printf '\t%s\n'     "                         If the password is not provided the output of couple of db2pd commands will be in binary format"
    printf '\t%s\n'     "                         "
    printf '\t%s\n'     "-additionalcmd file format "
    printf '\t%s\n'     "                      -- Must provide a file containing addtional commands in below format"
    printf '\t%s\n'     "                         TYPE COMMAND"
	printf '\t%s\n'     "                         TYPE: Can only be OS, DB2, DB21, DB2PD, QUERY. Any other type will be ignored."
    printf '\t%s\n'     "                         COMMAND: A valid command of the type specified. It cannot span multiple lines."
    printf '\t%s\n'     "                         OS vmstat -t 1 (runs as ssh on all nodes if multinode)"
    printf '\t%s\n'     "                         DB2 db2 list applications - Goes on all hosts (runs as rah if multinode)"
    printf '\t%s\n'     "                         QUERY select * from syscat.tables - Goes on 1 host and appends db2 -v before each query."
    printf '\t%s\n'     "                         DB2PD db2pd -d SAMPLE -member all -agents"
	printf '\t%s\n'     "                         DB21 db2trc off -member all  - This command will be executed on 1 host and spread across all members."
	printf '\t%s\n'     "                         DB2 db2pd -d SAMPLE -alldbp - This command will be executed as rah"
	printf '\t%s\n'     "                         OS and DB2PD type will be submitted as background task."
	printf '\t%s\n'     "                         FileName Format - ADDITIONALCMD.TYPE.LINENO.txt.ROUND.TS."
	printf '\t%s\n'     "             SAMPLE FILE "
	printf '\t%s\n'     "                         OS lscpu"
	printf '\t%s\n'     "                         OS LS"
	printf '\t%s\n'     "                         OS date ; ls -lrt"
	printf '\t%s\n'     "                         DB2 db2 list applications"
	printf '\t%s\n'     "                         DB21 db2ilist"
	printf '\t%s\n'     "                         DB2PD db2pd - -"
	printf '\t%s\n'     "                         QUERY select * from syscat.tables"
	printf '\t%s\n'     "                         XX YY"
	printf '\t%s\n'     "                         DB21 db2trc info -member all"
	printf '\t%s\n'     "                         DB2 db2pd -d SAMPLE -alldbp -sort"
	printf '\t%s\n'     "                         OS blktrace -d /dev/vdb -w 10 -o xx -b 1024 && blkparse -i  xx -d  xx.blkparse.bin  && btt -i xx.blkparse.bin"
	
    printf '\t%s\n'     "                         "
    printf '\t%s\n'     "-d|-db|-dbname        -- Database Name ( Default: BLUDB )"
    printf '\t%s\n'     "-instance             -- Db2 instance name - Only needed when script is executed as root ( Default: db2inst1 ) "
    printf '\t%s\n'     "-outdir  <dirname>    -- Output dir name ( Default: /scratch/IBMData. If /scratch does not exist then default is $PWD ) "
   #printf '\t%s\n'     "-outfile              -- Output file name ( Default: db_monitor.txt.<timestamp> ) -- for -wlm, -sessions, -transactions, -tablespaces options"
    printf '\t%s\n'     "-stop                 -- Stop the script cleanly"
    printf '\t%s\n'     "-verbose              -- Print verbose messages from the script to the screen"
    printf '\t%s\n'     "-ptimeout <N>         -- Timeout in seconds for each sub-process. Default is 900 seconds. "
    printf '\t%s\n'     "                         This will only be applicable to -hang, -perf, -hangapp, -hadr, -exfmt collections only."
	printf '\t%s\n'     "-piddetails           -- Print background process details on screen ( Only for Debug purposes ). "
    printf '\t%s\n'     "-debug                -- Print debug messages to the screen"
   #printf '\t%s\n'     "-norun                -- Do not run the commands. This option is mainly for testing purpose and limited to test -perf commands"
    printf '\t%s\n\n'   "-? or -h or -help"

    exit 0

}

############################################################################################
# Function name: collect_os_data_HANG_PERF
# Purpose      : To collect OS data for both HANG and PERF DATA COLLECTIONS
###########################################################################################
function collect_os_data_HANG_PERF ()
{
	OSOUTDIR="$1"
	suffix="$2"
	COLLECTYPE="$3"
	OSCOUNTER="$4"
	OSMAXCOUNTER="$5"
	
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi
	
	ParallelSSH "hostname; uptime; lscpu" "$OSOUTDIR/lscpu.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" 
	ParallelSSH "hostname; uptime; ls -lrt /dev/mapper " "$OSOUTDIR/devMapper.$suffix" "$ISROOT" "$NUMHOSTS" "OS"
	ParallelSSH "hostname; uptime; lsblk " "$OSOUTDIR/lsblk.$suffix" "$ISROOT" "$NUMHOSTS" "OS"	
	ParallelSSH "hostname; uptime; cat /proc/meminfo" "$OSOUTDIR/meminfo.$suffix" "$ISROOT" "$NUMHOSTS" "OS" 
	ParallelSSH "hostname; uptime; ps -elfL" "$OSOUTDIR/ps_elfL.$suffix" "$ISROOT" "$NUMHOSTS" "OS" 
	ParallelSSH "hostname; uptime; ps -elf" "$OSOUTDIR/ps_elf.$suffix" "$ISROOT" "$NUMHOSTS" "OS" 
	ParallelSSH "hostname; uptime; ps -eTo state,stat,pid,ppid,tid,lstart,wchan:40,policy,pri,psr,sgi_p,time,command" "$OSOUTDIR/ps_ETo.$suffix" "$ISROOT" "$NUMHOSTS" "OS" 
	ParallelSSH "hostname; uptime; ps -L -o f,s,state,user,pid,ppid,tid,lwp,c,nlwp,pri,ni,addr,vsz,rss,sz,stime,tty,time,pcpu,pmem,cmd,wchan:40" "$OSOUTDIR/ps.LP.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "cp /usr/include/asm/unistd_64.h $OSOUTDIR/unistd_64.h.$suffix" "$OSOUTDIR/cpunistd_64.$suffix" "$ISROOT" "1" "OS"
	
	if [[ $ADDITIONALCMD_SET -eq "1" ]] ; then
		AdditionalCommands "$OSOUTDIR" "$suffix" "OS" &
		childpidACOS=$( echo $! )
		echo $childpidACOS >> $TMPFILE
		echo "AdditionalCommands PID: $childpidACOS" >> $PROCESSFILE 2>&1
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "AdditionalCommands PID: $childpidACOS"
		log "[OS Data]: Collecting AdditionalCommands Started"		
	fi
	
	[[ $nodb2pd_SET -eq "0" ]] && ParallelSSH "db2pd -edus $Db2pdMemAll" "$OSOUTDIR/db2pd.edus.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
						  
	if [ "x$COLLECTYPE" = "x2" ]; then

		log "[OS Data]: Collecting \"perf full\" data $OSCOUNTER of $OSMAXCOUNTER"
		ParallelSSH "hostname; uptime; ipcs -a --human " "$OSOUTDIR/ipcs_a.$suffix" "$ISROOT" "$NUMHOSTS" "OS" 
		ParallelSSH "hostname; uptime; ipcs -a -p -t " "$OSOUTDIR/ipcs_a_p_t.$suffix" "$ISROOT" "$NUMHOSTS" "OS"
		ParallelSSH "hostname; uptime; ipcs -a -u " "$OSOUTDIR/ipcs_summary.$suffix" "$ISROOT" "$NUMHOSTS" "OS"
		ParallelSSH "hostname; uptime; cat /proc/diskstats " "$OSOUTDIR/diskstats1.$suffix" "$ISROOT" "$NUMHOSTS" "OS"
		sleep 5
		ParallelSSH "hostname; uptime; cat /proc/diskstats " "$OSOUTDIR/diskstats2.$suffix" "$ISROOT" "$NUMHOSTS" "OS"				  
	fi
  
}	
#######################################################
# Function: perf_collect_os_data
# Purpose : Collect OS data for perf option
#######################################################
function perf_collect_os_data()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    COLLECTYPE="$1"
    OUTDIR="$2"
	suffix="$3"
	CTR1="$4"
	PERIOD1="$5"
	
    OSOUTDIR=$( echo "$OUTDIR/OSData" )
    CreateDIR "$OSOUTDIR"

    log "Starting to collect OS Data ( OUTDIR = $OSOUTDIR, PERIOD = $PERIOD1, MAX = $MAX, KEEP = $KEEP, COLLECTYPE = $COLLECTYPE ) "

	NTIMES=$((PERIOD1 - ( 30 * PERIOD1 )/100 ))   # REDUCE 30% for EVERY second data collection.
	NTIMES2=$(( NTIMES/2 ))
	NTIMES5=$(( NTIMES/5 ))

    log "[OS Data]: Started $CTR1 of $MAX iterations"
    printf '\n%s\n'  "`date`: [OS Data]: Started $CTR1 of $MAX iterations"

    if [ "x$KEEP" != "x-1" ]; then
		log "[OS Data]: Deleting below files modified $KEEP minutes ago " 		
		find $OSOUTDIR -name "*" -mmin +$KEEP >> $LOGFILE 2>&1
        find $OSOUTDIR -name "*" -mmin +$KEEP | xargs rm -f 
    fi
			   
  	ParallelSSH "hostname; uptime; vmstat -w -t 1 $NTIMES " "$OSOUTDIR/vmstat.$suffix" "$ISROOT" "$NUMHOSTS" "OS"  "&"
  	ParallelSSH "hostname; uptime; iostat -xktz 2 $NTIMES2 " "$OSOUTDIR/iostat.xtkz.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&" 
  	ParallelSSH "hostname; uptime; top -b -d 5 -n $NTIMES5 " "$OSOUTDIR/top.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
  	ParallelSSH "hostname; uptime; mpstat -P ALL 5 $NTIMES5" "$OSOUTDIR/mpstat.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&" 
	
	collect_os_data_HANG_PERF "$OSOUTDIR" "$suffix" "$COLLECTYPE" "$CTR1" "$MAX"
		   
    log "[OS Data]: Finished $CTR1 of $MAX iterations"
    printf '\n%s\n'  "`date`: [OS Data]: Finished $CTR1 of $MAX iterations"
	
	#RefreshRunningpids  "$TMPFILE"
}

#######################################################
# Function: hang_collect_os_data
# Purpose : Collect OS data for hang data collection.
#######################################################
function hang_collect_os_data()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    COLLECTYPE="$1"
    OUTDIR="$2"
	suffix="$3"
	IH="$4"
	TSTAMP="$5"
    KERNELSTACK="$6"

    OSOUTDIR=$( echo "$OUTDIR/OSData" )
    CreateDIR "$OSOUTDIR"

    log "Starting to collect OS Data ( OUTDIR = $OSOUTDIR, COLLECTYPE = $COLLECTYPE, KERNELSTACK = $KERNELSTACK , TSTAMP = $TSTAMP  ) "
      
    log "[OS Data]: Started Collecting ( round $IH of $HANGROUNDS )"
    printf '\n%s\n' "`date`: [OS Data]: Started Collecting ( round $IH of $HANGROUNDS )"
      
	ParallelSSH "hostname; uptime; vmstat -w -t  1 40" "$OSOUTDIR/vmstat.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; iostat -xktz 2 20 " "$OSOUTDIR/iostat.xtkz.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&" 
  	ParallelSSH "hostname; uptime; top -b -d 5 -n 8 " "$OSOUTDIR/top.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
  	ParallelSSH "hostname; uptime; mpstat -P ALL 5 8" "$OSOUTDIR/mpstat.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&" 
		
	collect_os_data_HANG_PERF "$OSOUTDIR" "$suffix" "$COLLECTYPE" "$IH" "$HANGROUNDS"
	  
	if [[ "x$KERNELSTACK" = "x1" ]]; then

	  OSSTACKDIR=$( echo "$OSOUTDIR/osstacks" )
	  CreateDIR "$OSSTACKDIR"
	  chmod -R 777 $OSSTACKDIR
		  
	  CollectKernelStacksData "$OSSTACKDIR" "$IH" "$TSTAMP"	"$HANGROUNDS"  			  
	fi 

    log "[OS Data]: Finished Collecting ( round $IH of $HANGROUNDS )"
    printf '\n%s\n' "`date`: [OS Data]: Finished Collecting ( round $IH of $HANGROUNDS )"
          
	#RefreshRunningpids  "$TMPFILE"

}

#######################################################
# Function: Collect_db2pd_WLM_SORT
# Purpose : Collect_db2pd_WLM_SORT 
#######################################################

function Collect_db2pd_WLM_SORT ()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi
	
	DBNAME="$1"
	DB2PDOUTDIR="$2"
	suffix="$3"	
	SERVICEPASSWORD="$4"
	
	
    if [ "x$SERVICEPASSWORD" != "x0" ]; then

	   ParallelSSH "db2pd -dbp 0 -db $DBNAME -intwlmadmission detail -service $SERVICEPASSWORD" "$DB2PDOUTDIR/db2pd_intwladmission.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"
	   ParallelSSH "db2pd -alldbp -db $DBNAME -sortheapconsumers -service $SERVICEPASSWORD" "$DB2PDOUTDIR/db2pd_sortheapconsumers.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"	
	   ParallelSSH "db2pd -alldbp -db $DBNAME -dpsdbcb -service $SERVICEPASSWORD" "$DB2PDOUTDIR/db2pd_dpsdbcb.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"				   
	   ParallelSSH "db2pd -alldbp -db $DBNAME -dpsprcb -service $SERVICEPASSWORD" "$DB2PDOUTDIR/db2pd_dpsprcb.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"	   
	   ParallelSSH "db2pd -alldbp -db $DBNAME -ihadr -service $SERVICEPASSWORD" "$DB2PDOUTDIR/db2pd_ihadr.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"	   
    else

	   ParallelSSH "db2pd -dbp 0 -db $DBNAME -intwlmadmission detail " "$DB2PDOUTDIR/db2pd_intwladmission.bin.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"
       ParallelSSH "db2pd -alldbp -db $DBNAME -sortheapconsumers " "$DB2PDOUTDIR/db2pd_sortheapconsumers.bin.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"
	   ParallelSSH "db2pd -alldbp -db $DBNAME -dpsdbcb " "$DB2PDOUTDIR/db2pd_dpsdbcb.bin.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"
	   ParallelSSH "db2pd -alldbp -db $DBNAME -dpsprcb " "$DB2PDOUTDIR/db2pd_dpsprcb.bin.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"
	   ParallelSSH "db2pd -alldbp -db $DBNAME -ihadr " "$DB2PDOUTDIR/db2pd_ihadr.bin.$suffix" "$ISROOT" "$NUMHOSTS" "DB2"
	
	   if [[ $NUMHOSTS > 1 ]]; then
				
			for ihost in $HOSTS ; 
			do	
				 COPYSCP "$ihost" "$DB2INSTDIR" "$suffix" "$DB2PDOUTDIR"
				 COPYSCP "$ihost" "$DB2INSTDIR" "bin" "$DB2PDOUTDIR"
				 COPYSCP "$ihost" "$CWD" "$suffix" "$DB2PDOUTDIR"
				 COPYSCP "$ihost" "$CWD" "bin" "$DB2PDOUTDIR"
				 COPYSCP "$ihost" "$PWD" "$suffix" "$DB2PDOUTDIR"
				 COPYSCP "$ihost" "$PWD" "bin" "$DB2PDOUTDIR"
			done
	   else          
			mv $DB2INSTDIR/*.$suffix $DB2PDOUTDIR 1> /dev/null 2>&1
			mv $DB2INSTDIR/*.bin $DB2PDOUTDIR 1> /dev/null 2>&1
			mv $CWD/*.$suffix $DB2PDOUTDIR 1> /dev/null 2>&1
			mv $CWD/*.bin $DB2PDOUTDIR 1> /dev/null 2>&1
			mv $PWD/*.$suffix $DB2PDOUTDIR 1> /dev/null 2>&1
			mv $PWD/*.bin $DB2PDOUTDIR 1> /dev/null 2>&1
	   fi				   
    fi
}

#######################################################
# Function: collect_db2pd_HANG_PERF_FULL
# Purpose : Collect db2pd data common for HANG and PERF FULL
#######################################################
function collect_db2pd_HANG_PERF_FULL ()
{
	if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    DBNAME="$1"
    DB2PDOUTDIR="$2"
    suffix="$3"
	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -tcbstats all" "$DB2PDOUTDIR/db2pd_tcbstats.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -apinfo metrics -rep 5 2" "$DB2PDOUTDIR/db2pd_query_metrics.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -locks -transactions" "$DB2PDOUTDIR/db2pd_transactions.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfpool -db $DBNAME" "$DB2PDOUTDIR/db2pd_cfpool.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfinfo  gbp sca list lock gcl -db $DBNAME " "$DB2PDOUTDIR/db2pd_cfinfo_ext.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -fmpexechistory n=512 genquery" "$DB2PDOUTDIR/db2pd_FMPEXECHIST.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -storagegroups -storagepaths -tablespaces -rep 5 2" "$DB2PDOUTDIR/db2pd_tablespaces.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -dynamic" "$DB2PDOUTDIR/db2pd_dynamic.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -eve" "$DB2PDOUTDIR/db2pd_eve.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -static" "$DB2PDOUTDIR/db2pd_static.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -catalogcache" "$DB2PDOUTDIR/db2pd_catalogcache.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -rtsqueue" "$DB2PDOUTDIR/db2pd_rtsqueue.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -authenticationcache" "$DB2PDOUTDIR/db2pd_authenticationcache.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"			
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -iperiodic" "$DB2PDOUTDIR/db2pd_iperiodic.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -ha" "$DB2PDOUTDIR/db2pd_ha.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
}
#######################################################
# Function: collect_db2pd_HANG_PERF_BASIC
# Purpose : Collect db2pd data common for HANG and PERF BASIC
#######################################################
function collect_db2pd_HANG_PERF_BASIC ()
{		  
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi
	DBNAME="$1"
    DB2PDOUTDIR="$2"
    suffix="$3"
	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -edus interval=5 top=10" "$DB2PDOUTDIR/db2pd_edus_top.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -active -apinfo " "$DB2PDOUTDIR/db2pd_active_apinfo.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"	"&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -hadr -rep 5 2" "$DB2PDOUTDIR/db2pd_hadr.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -agents -rep 5 2" "$DB2PDOUTDIR/db2pd_agent.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -recovery -rep 5 2" "$DB2PDOUTDIR/db2pd_recovery.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -fvp LAM1 LAM2 LAM3 -rep 5 2" "$DB2PDOUTDIR/db2pd_fvp.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfinfo 129 perf  -d $DBNAME -rep 5 2" "$DB2PDOUTDIR/db2pd_cfinfo_129.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfinfo 128 perf  -d $DBNAME -rep 5 2" "$DB2PDOUTDIR/db2pd_cfinfo_128.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"		  
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -cleaner -rep 2 3" "$DB2PDOUTDIR/db2pd_cleaner.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -dirtypages summary -rep 2 3" "$DB2PDOUTDIR/db2pd_dirtypages.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -extent -rep 2 3" "$DB2PDOUTDIR/db2pd_extent.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -gfw -rep 2 3" "$DB2PDOUTDIR/db2pd_gfw.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
 	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -load -rep 2 3" "$DB2PDOUTDIR/db2pd_load.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -runstats  -rep 2 3" "$DB2PDOUTDIR/db2pd_runstats.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
 	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -reorgs index -rep 2 3" "$DB2PDOUTDIR/db2pd_reorg.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -util -rep 2 3" "$DB2PDOUTDIR/db2pd_util.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -sort -rep 2 3" "$DB2PDOUTDIR/db2pd_sort.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -dbptnmem -memset -mempool subpool -inst " "$DB2PDOUTDIR/db2pd_mem.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -fmp -rep 2 3" "$DB2PDOUTDIR/db2pd_FMP.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -edus -db $DBNAME " "$DB2PDOUTDIR/db2pd_edus.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -temptable" "$DB2PDOUTDIR/db2pd_temptable.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -logs" "$DB2PDOUTDIR/db2pd_logs.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"								
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -osinfo" "$DB2PDOUTDIR/db2pd_osinfo.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -workload" "$DB2PDOUTDIR/db2pd_workload.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"		
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -serviceclasses" "$DB2PDOUTDIR/db2pd_serviceclasses.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -workactionsets" "$DB2PDOUTDIR/db2pd_workactionsets.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -workclasssets" "$DB2PDOUTDIR/db2pd_workclasssets.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -thresholds" "$DB2PDOUTDIR/db2pd_thresholds.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"		
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -bufferpool " "$DB2PDOUTDIR/db2pd_bufferpool.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
		  		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -applications " "$DB2PDOUTDIR/db2pd_applications.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" 			
			
	backapphdl=$( cat "$DB2PDOUTDIR/db2pd_applications.txt.$suffix" | grep -w PerformingBackup | awk '{printf("%s\t%s\t%s\n", $2, $3, $5) }' | sort | uniq | head -1 )
	BACKUPAPPHDL=$(echo $backapphdl | awk '{print $1}')
		  
	if [[ ! -z $BACKUPAPPHDL && $noconnect_SET -eq "0" ]]; then 
		ParallelSSH "db2 -x connect to $DBNAME; db2 -x \"select 'db2pd -db $DBNAME -dbp '||DBPARTITIONNUM||' -barstats '||AGENT_TID from (select APPLICATION_HANDLE, DBPARTITIONNUM,  AGENT_TID, AGENT_TYPE, ROW_NUMBER() OVER (PARTITION BY APPLICATION_HANDLE,DBPARTITIONNUM ORDER BY APPLICATION_HANDLE,DBPARTITIONNUM) rownumber from TABLE (MON_GET_AGENT (NULL,NULL,$BACKUPAPPHDL ,-2)) $LocalBarstats  ) where ROWNUMBER = 1 \" ; db2 -x terminate " "$DB2PDOUTDIR/barstatcmd.$suffix" "$ISROOT" "1" "DB2"						
			
		cat $DB2PDOUTDIR/barstatcmd.$suffix | sed -n '/ Local database alias   = /,/DB20000I  The TERMINATE command completed/{//!p;}' | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		do				
			bkmember=$( echo $rec | awk '{print $5'} )				
			bkedu=$( echo $rec | awk '{print $7'} )
			ParallelSSH " db2pd -db $DBNAME -dbp $bkmember -barstats $bkedu " "$DB2PDOUTDIR/db2pd_barstats.$bkmember.$bkedu.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"
		done
	fi
	
}		  
#######################################################
# Function: perf_collect_db2pd_data
# Purpose : Collect db2pd data in perf mode
#######################################################
function perf_collect_db2pd_data()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    DBNAME="$1"
    PERIOD="$2"
    COLLECTYPE="$3"
    OUTDIR="$4"
	DB2PD_CTR="$5"
	suffix="$6"
    SERVICEPASSWORD="$7"

    DB2PDOUTDIR=$( echo "$OUTDIR/DB2PD_Data" )
    CreateDIR "$DB2PDOUTDIR"
    chmod 777 $DB2PDOUTDIR

	NTIMES=$((PERIOD - ( 30 * PERIOD )/100 ))   # REDUCE 30% for EVERY second data collection.
	NTIMES3=$((NTIMES/3))  # REDUCE 30% for EVERY second data collection.
	NTIMES30=$((NTIMES/30))  # REDUCE 30% for EVERY second data collection.
	
    log "[DB2PD data]: Starting to collect DB2PD data ( DBNAME = $DBNAME, PERIOD = $PERIOD, MAX = $MAX, COLLECTYPE = $COLLECTYPE )"
    log "[DB2PD data]: Starting to collect DB2PD data ( OUTDIR = $DB2PDOUTDIR, KEEP = $KEEP, SERVICEPASSWORD = $SERVICEPASSWORD, suffix = $suffix )"

    DB2PD_CTR=1

    log "[DB2PD Data]: Started $DB2PD_CTR of $MAX iterations"
    printf '\n%s\n' "`date`: [DB2PD Data]: Started $DB2PD_CTR of $MAX iterations"
			 
    if [ "x$KEEP" != "x-1" ]; then				   
	   log "[DB2PD Data]: Deleting below files modified $KEEP minutes ago " 
	   find $DB2PDOUTDIR -name "*" -mmin +$KEEP >> $LOGFILE 2>&1
       find $DB2PDOUTDIR -name "*" -mmin +$KEEP | xargs rm -f 
    fi
											
	ParallelSSH "db2pd $Db2pdMemAll -latches -rep 30 $NTIMES30" "$DB2PDOUTDIR/latches.log.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -wlocks -rep 30 $NTIMES30" "$DB2PDOUTDIR/wlocks.log.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -active -rep 30 $NTIMES30" "$DB2PDOUTDIR/active.log.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -wlocks detail -locks wait showlocks -rep 2 $NTIMES3" "$DB2PDOUTDIR/wlocks_showlocks.log.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -applications -rep 2 $NTIMES3" "$DB2PDOUTDIR/db2pd_appl.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"					
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -agents -rep 30 $NTIMES30 " "$DB2PDOUTDIR/db2pd_agents.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
				
	collect_db2pd_HANG_PERF_BASIC "$DBNAME" "$DB2PDOUTDIR" "$suffix" &
	childpidDHPB=$( echo $! )
	echo $childpidDHPB >> $TMPFILE
	echo "collect_db2pd_HANG_PERF_BASIC PID: $childpidDHPB" >> $PROCESSFILE 2>&1
	[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2pd_HANG_PERF_BASIC PID: $childpidDHPB"				
				 
    if [ "x$COLLECTYPE" = "x2" ]; then 
       log "[DB2PD Data]: Collecting \"perf full\" data ( Round $DB2PD_CTR of $MAX )"
	   collect_db2pd_HANG_PERF_FULL "$DBNAME" "$DB2PDOUTDIR" "$suffix"	&
	   childpidDHPF=$( echo $! )
	   echo $childpidDHPF >> $TMPFILE
	   echo "collect_db2pd_HANG_PERF_FULL PID: $childpidDHPF" >> $PROCESSFILE 2>&1
	   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2pd_HANG_PERF_FULL PID: $childpidDHPF"
					
    fi
			
	if [[ $ADDITIONALCMD_SET -eq "1" ]] ; then
		AdditionalCommands "$DB2PDOUTDIR" "$suffix" "DB2PD" &
		childpidACPD=$( echo $! )
		echo $childpidACPD >> $TMPFILE
		echo "AdditionalCommands PID: $childpidACPD" >> $PROCESSFILE 2>&1
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "AdditionalCommands PID: $childpidACPD"
		log "[DB2PD Data]: Collecting AdditionalCommands Started"			
	fi				
				
	Collect_db2pd_WLM_SORT "$DBNAME" "$DB2PDOUTDIR" "$suffix" "$SERVICEPASSWORD" &
	childpidWLM=$( echo $! )
	echo $childpidWLM >> $TMPFILE
	echo "Collect_db2pd_WLM_SORT PID: $childpidWLM" >> $PROCESSFILE 2>&1
	[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "Collect_db2pd_WLM_SORT PID: $childpidWLM"
	log "[DB2PD Data]: Started WLM_SORT data collection"
				
    ParallelSSH "db2pd $Db2pdMemAll -dbmcfg" "$DB2PDOUTDIR/db2pd_dbmcfg.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"
    ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME  -dbcfg" "$DB2PDOUTDIR/db2pd_dbcfg.txt.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"

    log "[DB2PD Data]: Finished $DB2PD_CTR of $MAX iterations"
    printf '\n%s\n' "`date`: [DB2PD Data]: Finished $DB2PD_CTR of $MAX iterations"

	#RefreshRunningpids  "$TMPFILE"
}
#######################################################
# Function: hang_collect_db2pd_data
# Purpose : Collect db2pd data for hang mode.
#######################################################
function hang_collect_db2pd_data()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    DBNAME="$1"
    IH="$2"
    COLLECTYPE="$3"
    OUTDIR="$4"
    suffix="$5"
    SERVICEPASSWORD="$6"

    DB2PDOUTDIR=$( echo "$OUTDIR/DB2PD_Data" )
    CreateDIR "$DB2PDOUTDIR"
	
	STACKDIR=$( echo "$DB2PDOUTDIR/stacks" )
   	CreateDIR "$STACKDIR"

    log "[DB2PD data]: Starting to collect DB2PD data ( DBNAME = $DBNAME, COLLECTYPE = $COLLECTYPE, suffix = $suffix )"
    log "[DB2PD data]: Starting to collect DB2PD data ( OUTDIR = $DB2PDOUTDIR, SERVICEPASSWORD = $SERVICEPASSWORD )"

          
    log "[DB2PD Data]: Started hang data collection ( round $IH of $HANGROUNDS )"
    printf '\n%s\n' "`date`: [DB2PD Data]: Started hang data collection ( round $IH of $HANGROUNDS )"
	  
    log "Collecting stacks ( Round $IH ) and dumping them in $STACKDIR"

    if [ "x$COLLECTYPE" = "x1" ];  then
		 ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -stack all dumpdir=$STACKDIR " "$DB2PDOUTDIR/db2pd_stackall.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
    fi 
		  
	if [ "x$COLLECTYPE" = "x2" ] ; then
             
		 [[ $PERF_NODUMPALL -eq "0" ]] && ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -dump all dumpdir=$STACKDIR " "$DB2PDOUTDIR/db2pd_dumpall.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
		 [[ $PERF_NODUMPALL -eq "1" ]] && ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -stack all dumpdir=$STACKDIR " "$DB2PDOUTDIR/db2pd_stackall.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
			 
		 log "[DB2PD Data]: Collecting \"Hang full\" data"
  		 collect_db2pd_HANG_PERF_FULL "$DBNAME" "$DB2PDOUTDIR" "$suffix" &
		 childpidDHPF=$( echo $! )
		 echo $childpidDHPF >> $TMPFILE
		 echo "collect_db2pd_HANG_PERF_FULL PID: $childpidDHPF" >> $PROCESSFILE 2>&1
		 [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2pd_HANG_PERF_FULL PID: $childpidDHPF"			 
	 
    fi		 				
		 
	log "[DB2PD Data]: Collecting \"Hang basic\" data ( Round $IH of $HANGROUNDS ) "
		  
	collect_db2pd_HANG_PERF_BASIC "$DBNAME" "$DB2PDOUTDIR" "$suffix" &
	childpidDHPB=$( echo $! )
	echo $childpidDHPB >> $TMPFILE
	echo "collect_db2pd_HANG_PERF_BASIC PID: $childpidDHPB" >> $PROCESSFILE 2>&1
	[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2pd_HANG_PERF_BASIC PID: $childpidDHPB"	
				
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -tcbstats all " "$DB2PDOUTDIR/db2pd_tcbstats.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -wlocks detail -locks wait showlocks -rep 2 3" "$DB2PDOUTDIR/db2pd_wlocks_showlocks.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -applications -rep 2 3" "$DB2PDOUTDIR/db2pd_appl.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
    ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -latches -rep 2 3" "$DB2PDOUTDIR/db2pd_latches.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	        		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -edus -agents -fmp -rep 2 3" "$DB2PDOUTDIR/db2pd_edus_agents_fmp.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -wlocks -locks -transactions -rep 2 3" "$DB2PDOUTDIR/db2pd_wlock_tran.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
		  
	if [[ $ADDITIONALCMD_SET -eq "1" ]] ; then
		AdditionalCommands "$DB2PDOUTDIR" "$suffix" "DB2PD" &
		childpidACPD=$( echo $! )
		echo $childpidACPD >> $TMPFILE
		echo "AdditionalCommands PID: $childpidACPD" >> $PROCESSFILE 2>&1
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "AdditionalCommands PID: $childpidACPD"
		log "[DB2PD Data]: Collecting AdditionalCommands Started"			
  	fi	
				
	Collect_db2pd_WLM_SORT "$DBNAME" "$DB2PDOUTDIR" "$suffix" "$SERVICEPASSWORD" &
	childpidWLM=$( echo $! )
	echo $childpidWLM >> $TMPFILE
	echo "Collect_db2pd_WLM_SORT PID: $childpidWLM" >> $PROCESSFILE 2>&1
	[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "Collect_db2pd_WLM_SORT PID: $childpidWLM"
	log "[DB2PD Data]: Started WLM_SORT data collection"
		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -dbmcfg " "$DB2PDOUTDIR/db2pd_dbmcfg.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -dbcfg " "$DB2PDOUTDIR/db2pd_dbcfg.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD"
		  
    log "[DB2PD Data]: Finished hang data collection ( round $IH of $HANGROUNDS ) "
    printf '\n%s\n' "`date`: [DB2PD Data]: Finished hang data collection ( round $IH of $HANGROUNDS ) "

	#RefreshRunningpids "$TMPFILE"
}
#######################################################
# Function: Collect_exfmt_db2mon
# Purpose : Collect exfmt from db2mon report.
#######################################################
function Collect_exfmt_db2mon()
{
    if [ "x$DEBUG" == "x1" ]; then
        set -xv
    fi
	
    DBNAME="$1"
	MONOUTDIR="$2"
	FNAME="$3"
	SUFFIX="$4"
	FileName="$FNAME.$SUFFIX"
			
	ctry=1
	cat $MONOUTDIR/$FileName | sed '/INF#EXPLN/,/record(s) selected./!d;//d' | awk ' { if ( $1 ~ /^[0-9]+$/ && tolower(substr($2,1,2)) == "x\x27" ) { print $1, $2} }' > $MONOUTDIR/$FileName.execids1
	cat $MONOUTDIR/$FileName | egrep "^COORD_MEMBER|^EXECUTABLE_ID" | awk '{print $NF}' | sed 'N;s/\n/ /g' | awk '{ if ( $1 ~ /^[0-9]+$/ && tolower(substr($2,1,2)) == "x\x27" ) { print $1, $2} }' > $MONOUTDIR/$FileName.execids2
		
	cat $MONOUTDIR/$FileName.execids1 $MONOUTDIR/$FileName.execids2  | sort | uniq | while read rec
	do
		 coord=$( echo $rec | awk '{ print $1; }' )
		 executable_id=$( echo $rec | awk '{ print $2 }' )
		 fmtexecid=$( echo $executable_id | tr -d "'" )
		 
		 if ls "$MONOUTDIR"/exfmt."$FNAME".*."$fmtexecid" 1> /dev/null 2>&1  ; then
		 
			  log "Skipping exfmt: in $MONOUTDIR/exfmt.$FNAME.*.$fmtexecid for filename: $FileName"
		 else 
		 
			 ParallelSSH "db2 connect to $DBNAME; db2 \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate " "$MONOUTDIR/explain_section.$FileName.$ctry.$fmtexecid" "$ISROOT" "1" "DB2"
			 check_success=$( cat $MONOUTDIR/explain_section.$FileName.$ctry.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
			 
			 if [ $check_success -eq 0 ]; then
			 
				param_values=$( cat $MONOUTDIR/explain_section.$FileName.$ctry.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' )
				param1=$( echo $param_values | awk '{ print $1; }' )
				param3=$( echo $param_values | awk '{ print $3; }' )
				param4=$( echo $param_values | awk '{ print $4; }' )
				param5=$( echo $param_values | awk '{ print $5; }' )						
				
				ParallelSSH "db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $MONOUTDIR/exfmt.$FileName.$ctry.$fmtexecid 2>&1" "$MONOUTDIR/db2exfmt.$FileName.$ctry.$fmtexecid" "$ISROOT" "1" "DB2"
				log "[MON Data]: Collected explain ( $FileName ) Execid: $executable_id , File: $MONOUTDIR/exfmt.$FileName.$ctry.$fmtexecid"
			 fi
		 fi	
		 let ctry=$ctry+1
	done
	QH1="db2 -v \"select executable_id, STMTID, PLANID, max_coord_stmt_exec_time, STMT_TEXT , XMLPARSE(DOCUMENT max_coord_stmt_exec_time_args) max_coord_stmt_exec_time_args FROM TABLE(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2)) where max_coord_stmt_exec_time_args IS NOT NULL AND STMTID in ( "
	QH2=$( cat $MONOUTDIR/$FileName | sed '/INF#EXPLN/,/record(s) selected./!d;//d' | awk ' { if ( $1 ~ /^[0-9]+$/ && tolower(substr($2,1,2)) == "x\x27" ) { print  $4","} }' | sort | uniq | tr '\n' ' ' )
	QH3=" 0)\" "
	FQ="$QH1 $QH2 $QH3"
	ParallelSSH "db2 connect to $DBNAME; $FQ ; db2 terminate " "$MONOUTDIR/values.$FileName.out" "$ISROOT" "1" "DB2"	
}	   
############################################################
# Function: collect_mon_data_PERF_HANG
# Purpose : Collect MON table data common for PERF and HANG
############################################################
function collect_mon_data_PERF_HANG ()
{
    if [ "x$DEBUG" == "x1" ]; then
        set -xv
    fi
	
    DBNAME="$1"
	COLLECTYPE="$2"
	MONOUTDIR="$3"
	suffix="$4"
	OKTORUN="$5"
	MONCOUNTER="$6"
	MONMAXCOUNT="$7"

	log "[MON Data]: Collecting MON Queries $MONCOUNTER of $MONMAXCOUNT  "
	
	Q01="db2 -v \"select current timestamp as timestamp, activity_state, sum(adm_bypassed) as bypassed, count(*) as connections from table( mon_get_activity(null,-2)) where member = coord_partition_num group by activity_state\"  > $MONOUTDIR/OverallApplicationStatus.$suffix"  	   
	Q02="db2 -v \"SELECT current timestamp as timestamp, substr(SERVICE_SUPERCLASS_NAME,1,25) as SUPER, EVENT_OBJECT, EVENT_OBJECT_NAME, COUNT(*) FROM TABLE(MON_GET_AGENT(NULL,NULL,NULL,-2)) AS T WHERE EVENT_OBJECT = 'WLM_QUEUE' GROUP BY substr(SERVICE_SUPERCLASS_NAME,1,25), EVENT_OBJECT, EVENT_OBJECT_NAME \"  > $MONOUTDIR/OverallAgentStatusInQueue.$suffix"  
	Q03="db2 -v \"SELECT current timestamp as timestamp, PARENTSERVICECLASSNAME AS SUPER, ACTIVITY_STATE, SUM(ADM_BYPASSED) AS BYPASSED, COUNT(*) AS TOTAL_CONNS FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T, SYSCAT.SERVICECLASSES AS Q WHERE SERVICECLASSID = SERVICE_CLASS_ID AND T.MEMBER = T.COORD_MEMBER GROUP BY PARENTSERVICECLASSNAME, ACTIVITY_STATE ORDER BY PARENTSERVICECLASSNAME DESC \"  > $MONOUTDIR/OverallStatePerServiceClass.$suffix"  
	Q04="db2 -v \"select current timestamp as timestamp, sum(act_completed_total) as stmts_completed, sum(act_aborted_total) as stmts_failed, sum(wlm_queue_assignments_total) as stmts_queued, dec((float(sum(wlm_queue_assignments_total))/float(sum(act_completed_total + act_aborted_total))) * 100, 5, 2) as pct_stmts_queued, sum(total_app_rqst_time) as rqst_time_ms, sum(total_app_rqst_time) / (sum(act_completed_total) + sum(act_aborted_total)) as avg_app_rqst_time_ms, sum(wlm_queue_time_total) as total_queue_time_ms, case when sum(wlm_queue_assignments_total) > 0 then sum(wlm_queue_time_total) / sum(wlm_queue_assignments_total) else 0 end as avg_queue_time_ms from table(mon_get_database(-2)) as t \"  > $MONOUTDIR/OverallQueueingState.$suffix"  
	Q05="db2 -v \"select current timestamp as timestamp, substr(service_superclass_name, 1, 25) as superclass, sum(act_completed_total) as stmts_completed, sum(act_aborted_total) as stmts_failed, sum(wlm_queue_assignments_total) as stmts_queued, case when sum(act_completed_total + act_aborted_total ) > 0 then decimal( (float(sum(wlm_queue_assignments_total)) / float(sum(act_completed_total + act_aborted_total))) * 100, 5, 2) else 0 end as pct_stmts_queued, sum(total_app_rqst_time) as rqst_time_ms, case when sum( act_completed_total + act_aborted_total) > 0 then decimal( (float(sum(total_app_rqst_time ))) / (float( sum(act_completed_total + act_aborted_total))),9,2) else 0 end as avg_app_rqst_time_ms, sum(wlm_queue_time_total) as total_queue_time_ms, case when sum(wlm_queue_assignments_total) > 0 then dec( float( sum(wlm_queue_time_total)) / float( sum(wlm_queue_assignments_total)), 9, 2)  else 0 end as avg_queue_time_ms from table(mon_get_service_superclass(null, -2)) as t group by substr(service_superclass_name,1,25) \"  > $MONOUTDIR/OverallQueueingPerServiceClass.$suffix"             
	Q06="db2 -v \"select current timestamp as timestamp, ACTIVITY_STATE, SUM(ADM_BYPASSED) AS BYPASSED, COUNT(*) AS TOT_CONNS FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE T.MEMBER = T.COORD_MEMBER GROUP BY ACTIVITY_STATE \"  > $MONOUTDIR/currentStateofQueries.$suffix"  
	Q07="db2 -v \"select current timestamp as timestamp, member, act_completed_total as stmts_completed, act_aborted_total as stmts_failed, wlm_queue_assignments_total as stmts_queued, decimal( ( float( wlm_queue_assignments_total) / float( act_completed_total + act_aborted_total )) * 100, 5, 2) as pct_stmts_queued, total_app_rqst_time as rqst_time_ms, total_app_rqst_time / ( act_completed_total + act_aborted_total ) as avg_app_rqst_time_ms, wlm_queue_time_total as total_queue_time_ms, ( case when wlm_queue_assignments_total > 0 then decimal( ( wlm_queue_time_total / wlm_queue_assignments_total ),15,2) else '0.00' end ) as avg_queue_time_ms from table( mon_get_database(-2)) as t order by member \"  > $MONOUTDIR/OverallSummaryQueryExecs.$suffix"  
	Q08="db2 -v \"select current timestamp as timestamp, sort_shrheap_allocated, sort_shrheap_top, wlm_queue_time_total, wlm_queue_assignments_total, member from table( mon_get_database(-2)) order by member \"  > $MONOUTDIR/sortmem_dblevel.$suffix"  
	Q09="db2 -v \"select current timestamp as timestamp, member, application_handle, entry_time, local_start_time, total_act_time, substr(client_applname,1,20) as client_applname, activity_state, active_sort_consumers, active_sort_consumers_top, active_sorts, active_sorts_top, active_col_vector_consumers, active_col_Vector_consumers_top, sort_consumer_shrheap_top, sort_shrheap_allocated, sort_shrheap_top, adm_bypassed, wlm_queue_time_total, wlm_queue_assignments_total, estimated_runtime, query_cost_estimate, estimated_sort_shrheap_top, stmtid, planid, executable_id, substr(stmt_text,1,500 ) as stmt from table(mon_get_activity(null,-2)) order by member \"  > $MONOUTDIR/mon_get_activity.$suffix"  
	Q10="db2 -v \"select current timestamp as timestamp, substr(u.metric_name,1,40) as metric_name, substr(u.parent_metric_name,1,30) as parent_metric_name, t.member, sum(u.total_time_value) as total_wait_time , sum(u.count) as total_count, ( sum(u.total_time_value) / sum(u.count) ) as total_time_per_count from table( mon_get_service_subclass_details(null,null,-2)) as t, table( mon_format_xml_times_by_row(t.details)) as u group by metric_name, parent_metric_name, t.member having sum(u.count) > 0 order by total_wait_time desc \"  > $MONOUTDIR/waitWithinDB2.$suffix"  

	Q11="db2 -v \"select current timestamp as timestamp, coord_member, member, application_handle, entry_time, local_start_time, substr(activity_state,1,16) as state, substr(activity_type,1,12) as type, total_act_time, total_act_wait_time, lock_wait_time, pool_read_time, pool_write_time, total_extended_latch_wait_time, lock_wait_time, log_buffer_wait_time, log_disk_wait_time, diaglog_write_wait_time, evmon_wait_time, prefetch_wait_time, ext_table_recv_wait_time, ext_table_recvs_total, ext_table_read_volume, fcm_recv_wait_time, fcm_send_wait_time,  effective_query_degree, substr(client_userid,1,20) as client_userid, NUM_AGENTS, SORT_SHRHEAP_ALLOCATED, adm_resource_actuals, total_act_time, coord_stmt_exec_time, AGENTS_TOP, TOTAL_CPU_TIME,  SORT_SHRHEAP_TOP, ESTIMATED_SORT_SHRHEAP_TOP, substr(activity_type,1,30) act_type, UOW_ID, ACTIVITY_ID, coord_member, executable_id, STMTID, PLANID, rows_read, rows_modified, rows_returned, substr(stmt_text,1,100) as stmt_text from table(mon_get_activity(null,-2)) where  member = coord_partition_num order by coord_stmt_exec_time  desc, application_handle, member  \"  > $MONOUTDIR/query_activity_metrics.$suffix"  
	Q12="db2 -v \"with activity_handles(application_handle) as (select application_handle from table(mon_get_activity(null,-2)) where member=coord_partition_num and activity_type != 'DDL' ) select a.request_start_time, a.agent_state_last_update_time, current timestamp as current_time, a.application_handle, a.member,  a.agent_tid, substr(a.agent_type,1,11) as agenttype, substr(a.agent_state,1,10) as agentstate, substr(a.request_type,1,12) as reqtype, substr(a.event_object,1,16) as event_object, substr(a.event_state,1,16) as event_state, substr(event_object_name,1,32) as event_object_name, substr(event_object_details,1,32) as event_object_details, a.uow_id, a.activity_id from table(mon_get_agent(null,null, null, -2)) a, activity_handles d where a.application_handle = d.application_handle order by application_handle, member \"  > $MONOUTDIR/activity_details.$suffix"  
	Q13="db2 -v \"with activity_handles(application_handle) as (select application_handle from table(mon_get_activity(null,-2)) where member=coord_partition_num and activity_type != 'DDL' ) select current timestamp as current_time, l.member, substr(l.latch_name,1,40) latch_name, l.application_handle, l.edu_id, l.latch_status, l.latch_wait_time from table(mon_get_latch(null,-2)) l,  activity_handles d where l.application_handle = d.application_handle order by application_handle, member \"  > $MONOUTDIR/activity_latch.$suffix"  
	Q14="db2 -v \"select current timestamp as timestamp, member,application_handle as apphandle, rows_read,rows_modified,num_agents as num_agents,  entry_time,effective_query_degree as eff_q_degree, query_actual_degree as q_actual_degree, planid, stmtid, substr(stmt_text,1,500) as stmt_text  from table(mon_get_activity(null,-2)) where activity_state = 'EXECUTING' order by member \"  > $MONOUTDIR/currentlyExecuting_Degree.$suffix"  
	Q15="db2 -v \"select current timestamp as timestamp, db_conn_time as activation_time, member, act_completed_total, rqsts_completed_total, ( total_app_commits + total_app_rollbacks ) as total_transactions, ( case when act_completed_total > 0 then int ( act_completed_total / timestampdiff( 2, to_char( current timestamp - db_conn_time )) ) else '0' end) as sql_stmts_p_sec, ( case when ( total_app_commits + total_app_rollbacks ) > 0 then int( ( total_app_commits + total_app_rollbacks ) / timestampdiff( 2, to_char( current timestamp - db_conn_time ) ) )  else '0' end ) as transactions_per_sec from table( mon_get_database(-2)) order by member \"  > $MONOUTDIR/thruputDetails.$suffix"  
	Q16="db2 -v \"select current timestamp as timestamp, member, remote_member, fcm_congested_sends, fcm_congestion_time, fcm_num_congestion_timeouts, connection_status from table(mon_get_fcm_connection_list(-2)) order by member \"  > $MONOUTDIR/fcm_congestion.$suffix"  
	Q17="db2 -v \"select member, integer(sum(total_rqst_time)) as total_rqst_tm, integer(sum(total_wait_time)) as total_wait_tm, decimal((sum(total_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_rqst_wait, decimal((sum(lock_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_lock, decimal((sum(lock_wait_time_global) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_glb_lock, decimal((sum(total_extended_latch_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_ltch, decimal((sum(log_disk_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_lg_dsk, decimal((sum(reclaim_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_rclm, decimal((sum(cf_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_cf, decimal((sum(pool_read_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_pool_r, decimal((sum(direct_read_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_dir_r, decimal((sum(direct_write_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_dir_w, decimal((sum(fcm_recv_wait_time+fcm_send_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_fcm, decimal((sum(tcpip_send_wait_time+tcpip_recv_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_tcpip , decimal((sum(diaglog_write_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_diag from table( mon_get_database(-2)) group by member order by member \"  > $MONOUTDIR/WaitTimesDB.$suffix"  
	Q18="db2 -v \"select current timestamp as timestamp, num_exec_with_metrics, insert_timestamp, last_metrics_update, planid, stmtid, executable_id, wlm_queue_time_total, wlm_queue_assignments_total, substr(stmt_text,1,200) as stmt_text from table( mon_get_pkg_cache_stmt( null, null, null, 0)) where wlm_queue_time_total > 0 and last_metrics_update >= current timestamp - 10 minutes order by wlm_queue_time_total desc fetch first 20 rows only \"  > $MONOUTDIR/HighestWLMQueueLast10Mins.$suffix"  
	Q19="db2 -v \"select current timestamp as timestamp, member, application_handle, entry_time, local_start_time, total_act_time,  substr(client_applname,1,20) as client_applname, activity_state, active_sort_consumers, adm_bypassed, wlm_queue_time_total, wlm_queue_assignments_total, estimated_runtime, query_cost_estimate, estimated_sort_shrheap_top, executable_id, planid, stmtid, substr(stmt_text,1,300 ) as stmt from table(mon_get_activity(null,-2)) where wlm_queue_time_total > 0 order by wlm_queue_time_total desc, member \"  > $MONOUTDIR/QueuedQueries.$suffix"  
	Q20="db2 -v \"select current timestamp as timestamp, member,MEMORY_POOL_USED as MemUsedKiB,MEMORY_POOL_USED_HWM as MemUsedKiB_HWM from table(mon_get_memory_pool('DATABASE',null,-2)) where MEMORY_POOL_TYPE='SHARED_SORT' order by MemUsedKiB_HWM desc \"  > $MONOUTDIR/SortMemUsed.$suffix"  

	Q21="db2 -v \"select current timestamp as timestamp, member,SORT_SHRHEAP_ALLOCATED*4 as SortResKiB,SORT_SHRHEAP_TOP*4 as SortResKiB_HWM from table(mon_get_database(-2)) order by SortResKiB_HWM desc \"  > $MONOUTDIR/SortReservation.$suffix"  
	Q22="db2 -v \"select current timestamp as timestamp, member, memory_set_type, memory_pool_type, memory_pool_id, memory_pool_used, memory_pool_used_hwm from table(mon_get_memory_pool(null,null,-2)) order by member \"  > $MONOUTDIR/mon_get_memory_pool.$suffix"  
	Q23="db2 -v \"WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), STMTS(NUMSTMT) AS (SELECT COUNT(*) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE ADM_BYPASSED = 0 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_DATABASE(-2)) AS T) SELECT current timestamp as timestamp, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(NUMSTMT)/FLOAT(LOADTRGT))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM WHERE SHEAPMEMBER=ALLOCMEMBER \"  > $MONOUTDIR/overallWLMResourceUsage.$suffix"  
	Q24="db2 -v \"WITH SORTMEM(SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), STMTS(NUMSTMT) AS (SELECT COUNT(*) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE ADM_BYPASSED = 0 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM ) , ESTMEM( ESTMEM, ESTMEMBER ) AS ( SELECT sum( ESTIMATED_SORT_SHRHEAP_TOP) , MEMBER FROM TABLE( MON_GET_ACTIVITY(null,-2)) WHERE ( ACTIVITY_STATE = 'EXECUTING' or ACTIVITY_STATE = 'IDLE') and ADM_BYPASSED = 0 GROUP BY MEMBER ), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_DATABASE(-2)) )  SELECT current timestamp as timestamp, MAX( DECIMAL( ( FLOAT( ESTMEM )/ FLOAT( SHEAPTHRESSHR ) ) * 100, 5,2 ) ) AS PERCENT_EST_SORTMEM, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(NUMSTMT)/FLOAT(LOADTRGT))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM, ESTMEM WHERE SHEAPMEMBER=ALLOCMEMBER AND ESTMEMBER=SHEAPMEMBER \"  > $MONOUTDIR/WLMEstvActUsage.$suffix"  
	Q25="db2 -v \"with total_mem(cfg_mem) as (select max(bigint(value)) from sysibmadm.dbcfg where name = 'sheapthres_shr' ), max_mem_part(member) as (select member from table(mon_get_database(-2)) as t order by sort_shrheap_allocated desc fetch first 1 rows only), mem_usage_on_member(application_handle, uow_id, activity_id, sort_shrheap_allocated) as (select application_handle, uow_id, activity_id, sort_shrheap_allocated from max_mem_part q, table(mon_get_activity(null, q.member)) as t where activity_state = 'EXECUTING' or activity_state = 'IDLE') select a.application_handle, a.uow_id, a.activity_id, a.local_start_time, timestampdiff(2, (current_timestamp-a.local_start_time)) as total_runtime_seconds, timestampdiff(2, (current_timestamp-a.local_start_time))-a.coord_stmt_exec_time/1000 as total_wait_on_client_time_seconds, a.wlm_queue_time_total / 1000 as time_queued_before_start_exec_seconds,b.application_name, b.session_auth_id, b.client_ipaddr, a.activity_state, a.adm_bypassed, a.estimated_sort_shrheap_top est_mem_usage, c.sort_shrheap_allocated as mem_usage_curr, d.cfg_mem, dec((float(c.sort_shrheap_allocated)/float(d.cfg_mem))*100,5,2) as query_pct_mem_used, substr(a.stmt_text, 1, 1024) as statement_text from table(mon_get_activity(null,-2)) as a, table(mon_get_connection(null,-2)) as b, mem_usage_on_member as c, total_mem as d where (a.application_handle = b.application_handle) AND (a.member = b.member) AND (a.application_handle = c.application_handle) AND (a.member=a.COORD_PARTITION_NUM) AND (a.uow_id = c.uow_id) AND (a.activity_id = c.activity_id) order by query_pct_mem_used \"  > $MONOUTDIR/memoryConsumptionRunningQueries.$suffix"  
	Q26="db2 -v \"with total_mem(cfg_mem) as (select bigint(max(value)) from sysibmadm.dbcfg where name = 'sheapthres_shr' ) select a.application_handle, a.uow_id, a.activity_id, a.entry_time, timestampdiff(2, (current_timestamp - a.entry_time)) as time_queued_seconds, b.application_name, b.session_auth_id, b.client_ipaddr, a.activity_state, a.estimated_sort_shrheap_top est_mem_usage, a.member, dec((float(a.estimated_sort_shrheap_top)/float(cfg_mem))*100,5,2) as est_query_pct_mem_usage, substr(a.stmt_text, 1, 1024) as statement_text from table(mon_get_activity(null,-2)) as a, table(mon_get_connection(null,-2)) as b, total_mem c where (a.application_handle = b.application_handle) AND (a.member = b.member) AND (a.activity_state = 'QUEUED') AND (a.member=a.COORD_PARTITION_NUM) AND (dec((float(a.estimated_sort_shrheap_top)/float(cfg_mem))*100,5,2)) > 25 order by est_mem_usage desc \"  > $MONOUTDIR/estimatedMemUsageQueuedQueries.$suffix"  
	Q27="db2 -v \"with pagesize( MEMBER, TBSP_ID, tbsp_page_size) as ( select MEMBER, TBSP_ID, tbsp_page_size from table(mon_get_tablespace(null,-2)) where TBSP_CONTENT_TYPE IN ('SYSTEMP','USRTEMP')  ) , numpages( apphandle, MEMBER, tbsp_id, num_objects, spillMB ) as ( select substr(tabschema,1,45) , t.MEMBER , t.tbsp_id, int(count(*)) , sum( decimal( ( float( ( nvl( col_object_l_pages,0) + nvl(data_object_l_pages,0) + nvl( index_object_l_pages,0)) * p.tbsp_page_size) / float((1024*1024)) ), 15,2)) as spillMB from table(mon_get_table(null,null,-2)) as t , pagesize p where t.tbsp_id = p.TBSP_ID AND t.MEMBER = p.MEMBER group by substr(tabschema,1,45), t.MEMBER, t.tbsp_id )  select current timestamp as curr_timestamp , apphandle , sum(num_objects) as num_objects , sum(spillMB) as spillMB  from   numpages group by apphandle order by spillMB desc fetch first 25 rows only with ur  \"  > $MONOUTDIR/sortDiskSpill.$suffix"  
	Q28="db2 -v \"select current timestamp as timestamp, member, decimal( ( 1 - ( double( TOTAL_LOG_USED )/double( TOTAL_LOG_USED + TOTAL_LOG_AVAILABLE ) ) )*100,5,2 ) as PCT_LOG_available,  first_active_log  as first_active_log,  last_active_log last_active_log,  current_active_log current_active_log, ( current_active_log - first_active_log ) num_active_logs, applid_holding_oldest_xact from table(mon_get_transaction_log(-2)) order by member with ur \"  > $MONOUTDIR/xactionlogDetails.$suffix" 
	Q29="db2 -v \"select current timestamp as timestamp, member, cast(substr(latch_name,1,60) as varchar(60)) as latch_name, total_extended_latch_wait_time as tot_ext_latch_wait_time_ms, total_extended_latch_waits as tot_ext_latch_waits, decimal( double(total_extended_latch_wait_time) / total_extended_latch_waits, 10, 2 ) as time_per_latch_wait_ms from table( mon_get_extended_latch_wait(-2)) where total_extended_latch_waits > 0 order by total_extended_latch_wait_time desc with UR \"  > $MONOUTDIR/latch_metrics.$suffix" 
	Q30="db2 -v \"SELECT * FROM TABLE ( MON_GET_LATCH(CLOB('<latch_status>W</latch_status>'), -2 ) ) ORDER BY LATCH_NAME, LATCH_STATUS\"  > $MONOUTDIR/get_latch_wait.txt.$suffix" 
	
	Q31="db2 -v \"WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), STMTS(NUMSTMT) AS (SELECT COUNT(*) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE ADM_BYPASSED = 0 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_DATABASE(-2)) AS T) SELECT current timestamp as timestamp, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(NUMSTMT)/FLOAT(LOADTRGT))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM WHERE SHEAPMEMBER=ALLOCMEMBER \"  > $MONOUTDIR/WLMOverallResUsage.$suffix" 
    Q32="db2 -v \"SELECT * FROM sysibmadm.mon_current_sql ORDER BY ELAPSED_TIME_SEC desc\"  > $MONOUTDIR/mon_get_sql.txt.$suffix"   		
	Q33="db2 -v \"select EXECUTABLE_ID,TOTAL_CPU_TIME/NUM_EXEC_WITH_METRICS AS AVG_CPU,TOTAL_CPU_TIME,COORD_STMT_EXEC_TIME/NUM_EXEC_WITH_METRICS AS AVG_ELAP,COORD_STMT_EXEC_TIME,NUM_EXEC_WITH_METRICS, STMT_TEXT from table(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2)) where NUM_EXEC_WITH_METRICS <> 0 order by COORD_STMT_EXEC_TIME/NUM_EXEC_WITH_METRICS desc fetch first 10 rows only\"  > $MONOUTDIR/elap_top_package_cache.txt.$suffix"   		
	Q34="db2 -v \"select EXECUTABLE_ID, substr(stmt_text,1,500) as stmt_text, decimal(float(total_extended_latch_wait_time)/num_executions,10,5) as avg_latch_time from table(mon_get_pkg_cache_stmt(null,null,null,null))  where num_executions > 0  order by avg_latch_time desc fetch first 10 rows only\"  > $MONOUTDIR/mon_get_pkg_cache_stmt_Avglatch.txt.$suffix"   		
    Q35="db2 -v \"select current timestamp as curr_timestamp, min(member) as member_min, max(member) member_max, substr(host_name,1,20) as host_name, max(cpu_online) cpu_online, max(cpu_usage_total) cpu_usage_total, max(decimal(cpu_load_short,6,1)) load_short, max(decimal(cpu_load_medium,6,1)) load_med, max(decimal(cpu_load_long,6,1)) load_long, min(memory_free)/1024 as mem_free_gb from table(sysproc.env_get_system_resources()) group by host_name order by member_min asc \"  > $MONOUTDIR/cpu_usage.$suffix" 
	Q36="db2 -v \"with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), actual_mem( tot_alloc_sortheap, sortmember ) as ( select sum( sort_shrheap_allocated ), member from table(mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING'  or activity_state = 'IDLE' ) group by member ) select current timestamp as curr_timestamp, sortmember as member, tot_alloc_sortheap as allocated_sort_heap, decimal( ( tot_alloc_sortheap / SHEAPTHRESSHR)*100,5,2) as pct_sortmem_used, int( SHEAPTHRESSHR ) as cfg_shrheap_thresh  from actual_mem, SORTMEM where sortmember = SHEAPMEMBER order by member \"  > $MONOUTDIR/sortmemUsagePerMember.$suffix" 
	Q37="db2 -v \"with SORTMEM( SHEAPTHRESHSHR, SHEAPMEMBER ) as ( select value, member from sysibmadm.dbcfg where NAME = 'sheapthres_shr' ), APPHBYPASS( apphandle, admbypass ) as ( select application_handle, adm_bypassed from table( mon_get_activity(null,-2)) where activity_state in ('EXECUTING','IDLE') and coord_partition_num = member ) , ALLOCMEMBYPASS( appmember, apphandle, admbypass, allocmem ) as ( select A.member, A.application_handle, B.admbypass, sum( A.sort_shrheap_allocated ) from table( mon_get_activity(null, -2 )) as A, APPHBYPASS B where A.activity_state in ('EXECUTING','IDLE') and A.application_handle = B.apphandle group by A.member, A.application_handle, B.admbypass ) select current timestamp as timestamp, appmember, admbypass, sum(allocmem) as sortmem_used, decimal( ( sum( allocmem ) / sum(sheapthreshshr) ) * 100, 5, 2) as sortmem_used_pct from ALLOCMEMBYPASS, SORTMEM where APPMEMBER = SHEAPMEMBER group by appmember, admbypass order by  sortmem_used_pct desc \"  > $MONOUTDIR/sortmemUsagePerMember_Bypass.$suffix" 
	Q38="db2 -v \"with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), APPSORTMEM( apphandle, appmember, admbypassed, est_sortmem, alloc_sortmem) as ( select application_handle, member, adm_bypassed, max( estimated_sort_shrheap_top), sum(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by application_handle, member , adm_bypassed ) select current timestamp as curr_timestamp, appmember, apphandle,  admbypassed as adm_bypass, alloc_sortmem as allocated_sortmem, decimal( ( alloc_sortmem / SHEAPTHRESSHR) * 100, 5,2 ) as pct_sortmem_used, est_sortmem, decimal( ( est_sortmem / SHEAPTHRESSHR ) * 100, 5,2) as pct_est_sortmem, int(SHEAPTHRESSHR) as cfg_shrheap_thresh  from SORTMEM, APPSORTMEM where SHEAPMEMBER = appmember and alloc_sortmem > 0 order by appmember, pct_sortmem_used desc \"  > $MONOUTDIR/sortmemUsagePerApphandle.$suffix" 
	Q39="db2 -v \"with sortmem( SHEAPTHRESSHR, SHEAPMEMBER) as ( SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr') select current timestamp as timestamp, member, sum( ESTIMATED_SORT_SHRHEAP_TOP ) as est_sort_heap_pages, sum( ESTIMATED_SORT_SHRHEAP_TOP * 4 ) as est_sort_heap_kb, sum( SORT_SHRHEAP_ALLOCATED ) as actual_sort_mem_usage_pages, sum( SORT_SHRHEAP_ALLOCATED * 4 ) as actual_sort_mem_usage_kb, sum( SHEAPTHRESSHR) as cfg_shrsortheap_pages, sum( SHEAPTHRESSHR * 4) as cfg_shrsortheap_thres_kb from table( mon_get_activity(null, -2 )), sortmem where member = SHEAPMEMBER group by member order by member \"  > $MONOUTDIR/EstVActSortmemusage.$suffix" 
	Q40="db2 -v \"with sortmem( SHEAPTHRESSHR, SHEAPMEMBER) as ( SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr') select current timestamp as timestamp, member, sum( ESTIMATED_SORT_SHRHEAP_TOP ) as est_sort_heap_pages, sum( ESTIMATED_SORT_SHRHEAP_TOP * 4 ) as est_sort_heap_kb, sum( SORT_SHRHEAP_ALLOCATED ) as actual_sort_mem_usage_pages, sum( SORT_SHRHEAP_ALLOCATED * 4 ) as actual_sort_mem_usage_kb, sum( SHEAPTHRESSHR ) as cfg_shrsortheap_pages, sum( SHEAPTHRESSHR * 4) as cfg_shrsortheap_thres_kb from table( mon_get_activity(null, -2 )), sortmem  where member = SHEAPMEMBER group by member order by member with ur \"  > $MONOUTDIR/sortmemsummary_per_member.$suffix" 
	
	Q41="db2 -v \"select * from SYSIBMADM.MON_BP_UTILIZATION ORDER BY 1,2\"  > $MONOUTDIR/MON_BP_UTILIZATION.txt.$suffix"   
	Q42="db2 -v \"select * from SYSIBMADM.MON_TRANSACTION_LOG_UTILIZATION ORDER BY 1 DESC \"  > $MONOUTDIR/MON_TRANSACTION_LOG_UTILIZATION.txt.$suffix"   
	Q43="db2 -v \"select * from sysibmadm.MON_WORKLOAD_SUMMARY ORDER BY 1 \"  > $MONOUTDIR/MON_WORKLOAD_SUMMARY.txt.$suffix"   
	Q44="db2 -v \"select * from sysibmadm.MON_SERVICE_SUBCLASS_SUMMARY  ORDER BY 1 \"  > $MONOUTDIR/MON_SERVICE_SUBCLASS_SUMMARY.txt.$suffix"   
	Q45="db2 -v \"select * from sysibmadm.MON_DB_SUMMARY \"  > $MONOUTDIR/MON_DB_SUMMARY.txt.$suffix"   
	Q46="db2 -v \"select * from sysibmadm.MON_CURRENT_UOW   ORDER BY ELAPSED_TIME_SEC DESC \"  > $MONOUTDIR/MON_CURRENT_UOW.txt.$suffix"   
	Q47="db2 -v \"select * from sysibmadm.MON_PKG_CACHE_SUMMARY ORDER BY AVG_STMT_EXEC_TIME DESC FETCH FIRST 10 rows only \"  > $MONOUTDIR/MON_PKG_CACHE_SUMMARY.txt.$suffix"   
	Q48="db2 -v \"select * from sysibmadm.MON_CONNECTION_SUMMARY ORDER BY RQST_WAIT_TIME_PERCENT DESC \"  > $MONOUTDIR/MON_CONNECTION_SUMMARY.txt.$suffix"   
	Q49="db2 -v \"select * from SYSIBMADM.MON_TBSP_UTILIZATION ORDER BY 1,2 \"  > $MONOUTDIR/MON_TBSP_UTILIZATION.txt.$suffix"   

	[[ $NOQ1 -eq "1" ]] && log "[MON Data]: Collecting MON Queries Batch 1 $MONCOUNTER of $MONMAXCOUNT  "
	[[ $NOQ1 -eq "1" ]] && ParallelSSH "db2 connect to $DBNAME; $Q01 ;  $Q02 ;  $Q03 ;  $Q04 ;  $Q05 ;  $Q06 ;  $Q07 ;  $Q08 ;  $Q09 ;  $Q10 ;  db2 terminate " "$MONOUTDIR/AllqueriesBatch1.txt.$suffix" "$ISROOT" "1" "DB2" "&"
	
	[[ $NOQ2 -eq "1" ]] && log "[MON Data]: Collecting MON Queries Batch 2 $MONCOUNTER of $MONMAXCOUNT  "
	[[ $NOQ2 -eq "1" ]] && ParallelSSH "db2 connect to $DBNAME; $Q11 ;  $Q12 ;  $Q13 ;  $Q14 ;  $Q15 ;  $Q16 ;  $Q17 ;  $Q18 ;  $Q19 ;  $Q20 ;  db2 terminate " "$MONOUTDIR/AllqueriesBatch2.txt.$suffix" "$ISROOT" "1" "DB2" "&"
	
	[[ $NOQ3 -eq "1" ]] && log "[MON Data]: Collecting MON Queries Batch 3 $MONCOUNTER of $MONMAXCOUNT  "
	[[ $NOQ3 -eq "1" ]] && ParallelSSH "db2 connect to $DBNAME; $Q21 ;  $Q22 ;  $Q23 ;  $Q24 ;  $Q25 ;  $Q26 ;  $Q27 ;  $Q28 ;  $Q29 ;  $Q30 ;  db2 terminate " "$MONOUTDIR/AllqueriesBatch3.txt.$suffix" "$ISROOT" "1" "DB2" "&"
	
	[[ $NOQ4 -eq "1" ]] && log "[MON Data]: Collecting MON Queries Batch 4 $MONCOUNTER of $MONMAXCOUNT  "
	[[ $NOQ4 -eq "1" ]] && ParallelSSH "db2 connect to $DBNAME; $Q31 ;  $Q32 ;  $Q33 ;  $Q34 ;  $Q35 ;  $Q36 ;  $Q37 ;  $Q38 ;  $Q39 ;  $Q40 ;  db2 terminate " "$MONOUTDIR/AllqueriesBatch4.txt.$suffix" "$ISROOT" "1" "DB2" "&"
	
	[[ $NOQ5 -eq "1" ]] && log "[MON Data]: Collecting MON Queries Batch 5 $MONCOUNTER of $MONMAXCOUNT  "
	[[ $NOQ5 -eq "1" ]] && ParallelSSH "db2 connect to $DBNAME; $Q41 ;  $Q42 ;  $Q43 ;  $Q44 ;  $Q45 ;  $Q46 ;  $Q47 ;  $Q48 ;  $Q49 ;  db2 terminate " "$MONOUTDIR/AllqueriesBatch5.txt.$suffix" "$ISROOT" "1" "DB2" "&"
	
	if [[ $ADDITIONALCMD_SET -eq "1" ]] ; then
		AdditionalCommands "$MONOUTDIR" "$suffix" "DB2" &
		childpidACMO=$( echo $! )
		echo $childpidACMO >> $TMPFILE
		echo "AdditionalCommands PID: $childpidACMO" >> $PROCESSFILE 2>&1
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "AdditionalCommands PID: $childpidACMO"
		log "[MON Data]: Collecting AdditionalCommands Started"			
  	fi		
	
	if [ "x$COLLECTYPE" = "x2" ]; then

		log "[MON Data]: Collecting \"perf full\" data  $MONCOUNTER of $MONMAXCOUNT  "

		QX01="db2 -v \"WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), CPUINFO(CPUS_PER_HOST) AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES())), PARTINFO(PART_PER_HOST) AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY ) SELECT current timestamp as timestamp, A.MEMBER, A.COORD_MEMBER, A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, B.APPLICATION_NAME, B.SESSION_AUTH_ID, B.CLIENT_IPADDR, A.ENTRY_TIME, A.LOCAL_START_TIME, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(A.LOCAL_START_TIME - A.ENTRY_TIME)) ELSE A.WLM_QUEUE_TIME_TOTAL/1000 END AS TOTAL_QUEUETIME_SECONDS, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME)) ELSE NULL END AS TOTAL_RUNTIME_SECONDS, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME))-A.COORD_STMT_EXEC_TIME/1000 ELSE NULL END AS TOTAL_CLIENT_WAIT_SECONDS, A.ADM_BYPASSED, A.ADM_RESOURCE_ACTUALS, A.EFFECTIVE_QUERY_DEGREE, DEC((FLOAT(A.EFFECTIVE_QUERY_DEGREE)/(FLOAT(D.LOADTRGT) * FLOAT(E.CPUS_PER_HOST) / FLOAT(F.PART_PER_HOST)))*100,5,2) AS THREADS_USED_PCT, A.QUERY_COST_ESTIMATE, A.ESTIMATED_RUNTIME, A.ESTIMATED_SORT_SHRHEAP_TOP AS ESTIMATED_SORTMEM_USED_PAGES, DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, A.SORT_SHRHEAP_ALLOCATED AS SORTMEM_USED_PAGES, DEC((FLOAT(A.SORT_SHRHEAP_ALLOCATED)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS SORTMEM_USED_PCT, SORT_SHRHEAP_TOP AS PEAK_SORTMEM_USED_PAGES, DEC((FLOAT(A.SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS PEAK_SORTMEM_USED_PCT, C.CFG_MEM AS CONFIGURED_SORTMEM_PAGES, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C, LOADTRGT AS D, CPUINFO AS E, PARTINFO AS F WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) ORDER BY MEMBER, APPLICATION_HANDLE, UOW_ID, ACTIVITY_ID, ACTIVITY_STATE \" > $MONOUTDIR/WLMResourcePerQuery.$suffix"  
		QX02="db2 -v \"with total_clients as (  select member, count(*) count, sum(client_idle_wait_time) client_idle_wait_time, sum(total_rqst_time) total_rqst_time, case when sum(total_rqst_time) > 0 then decimal(float(sum(client_idle_wait_time)) / sum(total_rqst_time), 10, 2) else null end as idle_rqst_ratio from table( mon_get_connection( null, -2 ) ) group by member), active_clients as (  select member, count(*) count, sum(client_idle_wait_time) client_idle_wait_time, sum(total_rqst_time) total_rqst_time, case when sum(total_rqst_time) > 0 then decimal(float(sum(client_idle_wait_time)) / sum(total_rqst_time), 10, 2) else null end as idle_rqst_ratio from table( mon_get_connection( null, -2)) where rqsts_completed_total > $PERIOD or (total_rqst_time > 0 and client_idle_wait_time / total_rqst_time < 2) group by member) select current timestamp as curr_timestamp, t.member, t.count as total_clients, t.client_idle_wait_time total_ciwt, t.total_rqst_time total_rqst, t.idle_rqst_ratio tot_ciwt_rq_ratio, a.count as active_clients, a.client_idle_wait_time active_ciwt, a.total_rqst_time active_rqst, a.idle_rqst_ratio active_ciwt_rq_ratio from total_clients t, active_clients a where a.member = t.member with UR \" > $MONOUTDIR/ClientIdleWaitToReqestRatio.$suffix"  
		QX03="db2 -v \"select current timestamp as timestamp, member, coord_member, application_handle, substr(client_applname,1,20) as client_appname, total_rqst_time, total_act_time, client_idle_wait_time, wlm_queue_time_total, total_act_wait_time, case when total_rqst_time > 0 then decimal(float(client_idle_wait_time) / total_rqst_time, 10, 2) else null end as idle_rqst_ratio from table(mon_get_connection(null,-2)) where client_applname is not null \" > $MONOUTDIR/connIdleTime.$suffix"  
		QX04="db2 -v \"with activity_data( member, application_handle, rows_read, rows_returned, rows_modified, fcm_tq_recvs_total, fcm_tq_sends_total ) as ( select member, application_handle, sum( rows_read), sum(rows_returned), sum(rows_modified), sum(fcm_tq_recvs_total), sum(fcm_tq_sends_total)  from table( mon_get_activity( null, -2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by member, application_handle) SELECT current timestamp as timestamp, SUBSTR(CHAR(SCDETAILS.APPLICATION_HANDLE),1,7) AS APPHANDLE, SUBSTR(CHAR(SCDETAILS.MEMBER),1,4) AS MEMB, SUBSTR(EVENT_STATE,1,10) AS EVENT_STATE, SUBSTR(EVENT_TYPE,1,10) AS EVENT_TYPE, SUBSTR(EVENT_OBJECT,1,10) AS EVENT_OBJECT, SUBSTR(EVENT_STATE,1,15) as EVENT_STATE, SUBSTR(EVENT_OBJECT_NAME,1,30) as EVENT_OBJECT_NAME, SUBSTR(EVENT_OBJECT_DETAILS,1,30) as EVENT_OBJECT_DETAILS, SUBSTR(CHAR(SUBSECTION_NUMBER),1,4) AS SUBSECTN, TIMESTAMPDIFF(2, CHAR( AGENT_STATE_LAST_UPDATE_TIME - REQUEST_START_TIME) ) as ELAPSED_SECS, rows_read as rread, rows_returned as rret, rows_modified as rmod, fcm_tq_recvs_total as tq_recv, fcm_tq_sends_total as tq_send FROM TABLE(MON_GET_AGENT(CAST(NULL AS VARCHAR(128)), CAST(NULL AS VARCHAR(128)), NULL, -2)) AS SCDETAILS, activity_data  where SCDETAILS.member = activity_data.member and SCDETAILS.application_handle = activity_data.application_handle ORDER BY elapsed_secs desc, memb, subsectn \" > $MONOUTDIR/subSectInfo.$suffix"  
		QX05="db2 -v \"WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), MAX_MEM( APPLICATION_HANDLE, UOW_ID, ACT_ID, SORTMEM, ESTSORTMEM , PEAKSORTMEM) AS ( select application_handle, uow_id, activity_id, max( sort_shrheap_allocated ) , max( estimated_sort_shrheap_top), max( sort_shrheap_top)  from table(mon_get_activity(null, -2 )) where activity_state in( 'IDLE', 'EXECUTING') group by application_handle, uow_id, activity_id ) SELECT CURRENT TIMESTAMP as CURR_TIMESTAMP, A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, B.SESSION_AUTH_ID, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME)) ELSE NULL END AS TOTAL_RUNTIME_SECONDS, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME))-A.COORD_STMT_EXEC_TIME/1000 ELSE NULL END AS TOTAL_CLIENT_WAIT_SECONDS, A.ADM_RESOURCE_ACTUALS, DEC((FLOAT(D.ESTSORTMEM)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, DEC((FLOAT(D.SORTMEM)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS SORTMEM_USED_PCT, DEC((FLOAT(D.PEAKSORTMEM)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS PEAK_SORTMEM_USED_PCT, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C, MAX_MEM D WHERE A.COORD_PARTITION_NUM = A.MEMBER AND (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) AND (A.ACTIVITY_STATE IN ('EXECUTING', 'IDLE')) AND ( A.APPLICATION_HANDLE = D.APPLICATION_HANDLE and A.UOW_ID = D.UOW_ID and A.ACTIVITY_ID = D.ACT_ID) ORDER BY SORTMEM_USED_PCT desc \" > $MONOUTDIR/currentlyExecutingResourceUsage.$suffix"  
		QX06="db2 -v \"WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr') SELECT A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, B.SESSION_AUTH_ID, A.WLM_QUEUE_TIME_TOTAL/1000 AS TOTAL_QUEUETIME_SECONDS, DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) AND (A.ACTIVITY_STATE IN ('QUEUED')) AND (A.MEMBER = C.MEMBER ) ORDER BY ESTIMATED_SORTMEM_USED_PCT desc \" > $MONOUTDIR/queuedResourceUsage.$suffix"  				
		QX07="db2 -v \"with curr_execid( apphandle, executable_id, cnt) as ( select application_handle, executable_id, count(*) from table( mon_get_activity(null,-2)) group by application_handle, executable_id )  select current timestamp as timestamp, a.coord_member , a.application_handle, b.executable_id, varchar(a.activity_state,12) as activity_state, varchar(a.activity_type,12) as activity_type, a.rows_read, a.rows_returned, a.total_cpu_time, a.query_cost_estimate, a.elapsed_time_sec, substr(a.stmt_text,1,150) as stmt_text from sysibmadm.mon_current_sql a, curr_execid b where a.elapsed_time_sec >  $PERIOD and  a.application_handle = b.apphandle order by elapsed_time_sec desc fetch first 20 rows only with ur \" > $MONOUTDIR/LongRunningQueriesGreaterThan_$PERIOD.$suffix"
		QX08="db2 -v \"select current timestamp as timestamp, application_handle, executable_id, decimal( avg( ( total_act_wait_time  /   total_act_time ) * 100 ), 5,2) as overall_wait_pct , decimal( avg( ( lock_wait_time / total_act_time ) * 100 ), 5,2 ) as pct_lck, decimal( avg( ( pool_read_time / total_act_time ) * 100 ), 5, 2) as pct_phys_rd, decimal( avg( ( ( direct_read_time+direct_write_time ) / total_act_time ) * 100 ), 5,2 ) as pct_dir_io, decimal( avg( ( (fcm_recv_wait_time+fcm_send_wait_time) / total_act_time ) * 100 ),5,2) as pct_fcm, decimal( avg( ( total_extended_latch_wait_time / total_act_time ) * 100 ),5,2) as pct_ltch, decimal( avg( ( log_disk_wait_time /  total_act_time ) * 100 ), 5,2 ) as pct_log, decimal( avg( ( diaglog_write_wait_time / total_act_time ) * 100 ), 5, 2) as pct_diaglog from table( mon_get_activity(null,-2)) where total_act_time > 0 group by application_handle , executable_id order by overall_wait_pct desc with ur \" > $MONOUTDIR/pctWaitTimesQueries.$suffix"
		QX09="db2 -v \"with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), APPSORTMEM( apphandle, appmember, coord_part_num, executable_id, alloc_sortmem) as ( select application_handle, member, coord_partition_num, executable_id, sum(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by application_handle, member, coord_partition_num, executable_id  ) select current timestamp as timestamp, apphandle, coord_part_num, executable_id from SORTMEM, APPSORTMEM where SHEAPMEMBER = appmember and alloc_sortmem > 0 order by alloc_sortmem desc fetch first 20 rows only with ur \" > $MONOUTDIR/TopSortConsumingQueries.$suffix"
		QX10="db2 -v \"select current timestamp as Time, case when sum(w.TOTAL_APP_COMMITS) < 100 then null else cast( float(sum(b.POOL_DATA_WRITES+b.POOL_INDEX_WRITES)) / sum(w.TOTAL_APP_COMMITS) as decimal(6,1)) end as BP_wrt_per_UOW, case when sum(b.POOL_DATA_WRITES+b.POOL_INDEX_WRITES) < 1000 then null else cast( float(sum(b.POOL_WRITE_TIME)) / sum(b.POOL_DATA_WRITES+b.POOL_INDEX_WRITES) as decimal(5,1)) end as ms_per_BPwrt from table(mon_get_workload(null,null)) as w,  table(mon_get_bufferpool(null,null)) as b with ur \" > $MONOUTDIR/castoutMonitoring.$suffix"
						
		if [ "x$OKTORUN" = "x1" ]; then
			QXOK01="db2 -v \"WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr') SELECT A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, SUBSTR(B.CLIENT_APPLNAME,1,15) as CLIENT_APPLNAME, substr(B.SESSION_AUTH_ID,1,20) as SESSION_AUTH_ID, A.WLM_QUEUE_TIME_TOTAL/1000 AS TOTAL_QUEUETIME_SECONDS, DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, D.ADM_QUEUE_POSITION, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C, TABLE(MON_GET_WLM_ADMISSION_QUEUE()) AS D WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) AND (A.ACTIVITY_STATE IN ('QUEUED')) AND (A.APPLICATION_HANDLE = D.APPLICATION_HANDLE AND A.UOW_ID = D.UOW_ID AND A.ACTIVITY_ID = D.ACTIVITY_ID AND D.ADM_QUEUE_POSITION <= 10) order by D.ADM_QUEUE_POSITION \" > $MONOUTDIR/queuedFirst10queriesResourceUsage.$suffix" 
		else 
		    QXOK01="db2 -v \" select 1 from sysibm.sysdummy1 \" > $MONOUTDIR/DummyQuery1.$suffix" 
		fi

		ParallelSSH "db2 connect to $DBNAME; $QX01 ;  $QX02 ;  $QX03 ;  $QX04 ;  $QX05 ;  $QX06 ; $QX07 ; $QX08 ; $QX09  ; $QX10 ; $QXOK01 ;  db2 terminate " "$MONOUTDIR/AllqueriesBatch1.Extended.$suffix" "$ISROOT" "1" "DB2" "&"

		#Get the explains of the top 5 long running queries
   	    
		log "[MON Data]: Collect explain Info  $MONCOUNTER of $MONMAXCOUNT  "

		QE01="db2 -x \" select a.coord_partition_num, a.application_handle, a.executable_id from table( mon_get_activity(null, -2 )) a where a.activity_state in ('EXECUTING', 'IDLE') and a.member = a.coord_partition_num order by a.coord_stmt_exec_time desc fetch first 5 rows only \" > $MONOUTDIR/longRunning.$suffix"
		QE02="db2 -x \" select a.coord_partition_num, a.application_handle, a.executable_id from table( mon_get_activity(null, -2 )) a where a.activity_state in ('EXECUTING', 'IDLE') and a.member = a.coord_partition_num order by sort_shrheap_top desc fetch first 5 rows only \" > $MONOUTDIR/topSortConsumer.$suffix"
		QE03="db2 -x \" select a.coord_partition_num, a.application_handle, a.executable_id from table(mon_get_activity(null,-2)) as a where a.member = a.coord_partition_num and a.activity_state = 'QUEUED' order by a.estimated_sort_shrheap_top desc fetch first 5 rows only \" > $MONOUTDIR/queued.$suffix"
			
		ParallelSSH "db2 connect to $DBNAME; $QE01 ;  $QE02 ;  $QX03 ;  $QE03 ; db2 terminate " "$MONOUTDIR/AllqueriesExplainInfo.$suffix" "$ISROOT" "1" "DB2"
		
		ctry=1
		#cat $MONOUTDIR/longRunning.$suffix | sed -n '/ Local database alias   = /,/DB20000I  The TERMINATE command completed/{//!p;}' | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		cat $MONOUTDIR/longRunning.$suffix | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		do
			 coord=$( echo $rec | awk '{ print $1; }' )
			 apphandle=$( echo $rec | awk '{ print $2 }' )
			 executable_id=$( echo $rec | awk '{ print $3 }' )
			 fmtexecid=$( echo $executable_id | tr -d "'" )
			 
			 #ParallelSSH "db2 connect to $DBNAME; db2 -v \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate ; db2exfmt -d $DBNAME -1 > $MONOUTDIR/exfmt.longRunning.$ctry.$apphandle.$suffix 2>&1" "$MONOUTDIR/explain_section_longRunning.$ctry.$apphandle.$suffix" "$ISROOT" "1" "DB2"
			 
			 ParallelSSH "db2 connect to $DBNAME; db2 \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate " "$MONOUTDIR/explain_section.longRunning.$ctry.$apphandle.$suffix.$fmtexecid" "$ISROOT" "1" "DB2"
			 check_success=$( cat  $MONOUTDIR/explain_section.longRunning.$ctry.$apphandle.$suffix.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
			 
			 if [ $check_success -eq 0 ]; then
			 
				param_values=$( cat  $MONOUTDIR/explain_section.longRunning.$ctry.$apphandle.$suffix.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' )
                param1=$( echo $param_values | awk '{ print $1; }' )
                param3=$( echo $param_values | awk '{ print $3; }' )
                param4=$( echo $param_values | awk '{ print $4; }' )
                param5=$( echo $param_values | awk '{ print $5; }' )						
                fmtexecid=$( echo $executable_id | tr -d "'" )
				
				ParallelSSH "db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $MONOUTDIR/exfmt.longRunning.$ctry.$apphandle.$suffix.$fmtexecid 2>&1" "$MONOUTDIR/db2exfmt.longRunning.$ctry.$apphandle.$suffix.$fmtexecid" "$ISROOT" "1" "DB2"
				log "[MON Data]: Collected explain ( LongRunning ) of Apphandle: $apphandle, Execid: $executable_id , File: $MONOUTDIR/exfmt.longRunning.$ctry.$apphandle.$suffix.$fmtexecid"
			 fi
			 
			 let ctry=$ctry+1
	    done
	    ctry=1
		#cat $MONOUTDIR/topSortConsumer.$suffix | sed -n '/ Local database alias   = /,/DB20000I  The TERMINATE command completed/{//!p;}' | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		cat $MONOUTDIR/topSortConsumer.$suffix | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		do
			 coord=$( echo $rec | awk '{ print $1 ;} ' )
			 apphandle=$( echo $rec | awk '{ print $2 ;} ' )
			 executable_id=$( echo $rec | awk '{ print $3 ;} ' )
			 fmtexecid=$( echo $executable_id | tr -d "'" )

			 #ParallelSSH "db2 connect to $DBNAME; db2 -v \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate ; db2exfmt -d $DBNAME -1 > $MONOUTDIR/exfmt.topSortConsumer.$ctry.$apphandle.$suffix 2>&1" "$MONOUTDIR/explain_section_topSortConsumer.$ctry.$apphandle.$suffix" "$ISROOT" "1" "DB2"
			 
			 ParallelSSH "db2 connect to $DBNAME; db2 \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate " "$MONOUTDIR/explain_section.topSortConsumer.$ctry.$apphandle.$suffix.$fmtexecid" "$ISROOT" "1" "DB2"
			 check_success=$( cat  $MONOUTDIR/explain_section.topSortConsumer.$ctry.$apphandle.$suffix.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
			 
			 if [ $check_success -eq 0 ]; then
			 
				param_values=$( cat  $MONOUTDIR/explain_section.topSortConsumer.$ctry.$apphandle.$suffix.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' )
                param1=$( echo $param_values | awk '{ print $1; }' )
                param3=$( echo $param_values | awk '{ print $3; }' )
                param4=$( echo $param_values | awk '{ print $4; }' )
                param5=$( echo $param_values | awk '{ print $5; }' )						
                fmtexecid=$( echo $executable_id | tr -d "'" )
				
				ParallelSSH "db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $MONOUTDIR/exfmt.topSortConsumer.$ctry.$apphandle.$suffix.$fmtexecid 2>&1" "$MONOUTDIR/db2exfmt.topSortConsumer.$ctry.$apphandle.$suffix.$fmtexecid" "$ISROOT" "1" "DB2"
				log "[MON Data]: Collected explain ( topSortConsumer ) of Apphandle: $apphandle, Execid: $executable_id , File: $MONOUTDIR/exfmt.topSortConsumer.$ctry.$apphandle.$suffix.$fmtexecid"
			 fi
			 
			 let ctry=$ctry+1
	    done
	    ctry=1
		#cat $MONOUTDIR/queued.$suffix | sed -n '/ Local database alias   = /,/DB20000I  The TERMINATE command completed/{//!p;}' | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		cat $MONOUTDIR/queued.$suffix | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		do
			 coord=$( echo $rec | awk '{ print $1 ;} ' )
			 apphandle=$( echo $rec | awk '{ print $2 ;} ' )
			 executable_id=$( echo $rec | awk '{ print $3 ;} ' )
             fmtexecid=$( echo $executable_id | tr -d "'" )

			 #ParallelSSH "db2 connect to $DBNAME; db2 -v \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate ; db2exfmt -d $DBNAME -1 > $MONOUTDIR/exfmt.queued.$ctry.$apphandle.$suffix 2>&1" "$MONOUTDIR/explain_section_queued.$ctry.$apphandle.$suffix" "$ISROOT" "1" "DB2"				 
 			 ParallelSSH "db2 connect to $DBNAME; db2 \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate " "$MONOUTDIR/explain_section.queued.$ctry.$apphandle.$suffix.$fmtexecid" "$ISROOT" "1" "DB2"
			 check_success=$( cat  $MONOUTDIR/explain_section.queued.$ctry.$apphandle.$suffix.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
			 
			 if [ $check_success -eq 0 ]; then
			 
				param_values=$( cat  $MONOUTDIR/explain_section.queued.$ctry.$apphandle.$suffix.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' )
                param1=$( echo $param_values | awk '{ print $1; }' )
                param3=$( echo $param_values | awk '{ print $3; }' )
                param4=$( echo $param_values | awk '{ print $4; }' )
                param5=$( echo $param_values | awk '{ print $5; }' )						
                fmtexecid=$( echo $executable_id | tr -d "'" )
				
				ParallelSSH "db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $MONOUTDIR/exfmt.queued.$ctry.$apphandle.$suffix.$fmtexecid 2>&1" "$MONOUTDIR/db2exfmt.queued.$ctry.$apphandle.$suffix.$fmtexecid" "$ISROOT" "1" "DB2"
				log "[MON Data]: Collected explain ( Queued ) of Apphandle: $apphandle, Execid: $executable_id , File: $MONOUTDIR/exfmt.queued.$ctry.$apphandle.$suffix.$fmtexecid"
			 fi
			 
			 let ctry=$ctry+1
	    done		
	fi  # COLLECTTYPEX2
	log "[MON Data]: Collecting db2mon data 60 seconds  $MONCOUNTER of $MONMAXCOUNT  "
	ParallelSSH "$DB2INSTDIR/sqllib/samples/perf/db2mon.sh $DBNAME 60 > $MONOUTDIR/db2mon.txt.$suffix" "$MONOUTDIR/db2mon.sh.$suffix" "$ISROOT" "1" "DB2" 
	Collect_exfmt_db2mon "$DBNAME" "$MONOUTDIR" "db2mon.txt" "$suffix"
}		
#######################################################
# Function: perf_collect_mon_data
# Purpose : Collect MON table data for perf collection.
#######################################################
function perf_collect_mon_data()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    DBNAME="$1"
    COLLECTYPE="$2"
    OUTDIR="$3"
    KEEP="$4"
	CTR2="$5"
	suffix="$6"
    OKTORUN="$7"

    MONOUTDIR=$( echo "$OUTDIR/MONData" )
	CreateDIR "$MONOUTDIR"

    log "[MON data]: Starting to collect MON table data ( DBNAME = $DBNAME, MAX = $MAX, COLLECTYPE = $COLLECTYPE, OUTDIR = $MONOUTDIR, KEEP = $KEEP )"

	log "[MON Data]: Started $CTR2 of $MAX iterations"
	printf '\n%s\n' "`date`: [MON Data]: Started $CTR2 of $MAX iterations"

	if [ "x$KEEP" != "x-1" ]; then
		log "[MON Data]: Deleting below files modified $KEEP minutes ago " 
		find $MONOUTDIR -name "*" -mmin +$KEEP >> $LOGFILE 2>&1
		find $MONOUTDIR -name "*" -mmin +$KEEP | xargs rm -f
	fi

	collect_mon_data_PERF_HANG "$DBNAME" "$COLLECTYPE" "$MONOUTDIR" "$suffix" "$OKTORUN" "$CTR2" "$MAX"
			   
	log "[MON Data]: Finished $CTR2 of $MAX iterations"
	printf '\n%s\n' "`date`: [MON Data]: Finished $CTR2 of $MAX iterations"

	#RefreshRunningpids  "$TMPFILE"	
}
#######################################################
# Function: hang_collect_mon_data
# Purpose : Collect MON table data for hang collection
#######################################################
function hang_collect_mon_data()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    DBNAME="$1"
	COLLECTYPE="$2"
    OUTDIR="$3"
	IH="$4"
	suffix="$5"
    OKTORUN="$6"

    MONOUTDIR=$( echo "$OUTDIR/MONData" )
	CreateDIR "$MONOUTDIR"

    log "[MON data]: Starting to collect MON table data ( DBNAME = $DBNAME, COLLECTYPE = $COLLECTYPE, OUTDIR = $MONOUTDIR )"

    log "[MON Data]: Started hang data collection ( round $IH of $HANGROUNDS )"
    printf '\n%s\n' "`date`: [MON Data]: Started hang data collection ( round $IH of $HANGROUNDS )"
	  
	collect_mon_data_PERF_HANG "$DBNAME" "$COLLECTYPE" "$MONOUTDIR" "$suffix" "$OKTORUN" "$IH" "$HANGROUNDS"
		  
	log "[MON Data]: Finished hang data collection ( round $IH of $HANGROUNDS )"
	printf '\n%s\n' "`date`: [MON Data]: Finished hang data collection ( round $IH of $HANGROUNDS )"

	#RefreshRunningpids "$TMPFILE" 
}
############################################################################################
# Function name: collect_db2trc_data_HANG_PERF
# Purpose      : To collect dbtrc data for both HANG and PERF DATA COLLECTIONS
###########################################################################################
function collect_db2trc_data_HANG_PERF ()
{
    if [ "x$DEBUG" == "x1" ]; then
        set -xv
    fi
	
	CDE="$1"
	TRCOUTDIR="$2"
	suffix="$3"
	SLEEPTIME="$4"
	CTR="$5"
	
	if [[ "x$CDE" == "x1" ]]; then
		ParallelSSH "db2trc on -m CDE_PERF_TRACE -t $Db2trcMemAll" "$TRCOUTDIR/db2_traceON.$suffix" "$ISROOT" "1" "DB2"  
	else
		ParallelSSH "db2trc on -l 512m -t $Db2trcMemAll" "$TRCOUTDIR/db2_traceON.$suffix" "$ISROOT" "1" "DB2"  
	fi
	cat $TRCOUTDIR/db2_traceON.$suffix >> $LOGFILE 2>&1
	
	log "[DB2TRC]: Sleeping for $SLEEPTIME seconds before dumping the trace"
	sleep $SLEEPTIME
	
	ParallelSSH "db2trc dmp trc.$CTR.dmp -sdir $TRCOUTDIR $Db2trcMemAll" "$TRCOUTDIR/db2_tracedmp.$suffix" "$ISROOT" "1" "DB2"
	cat $TRCOUTDIR/db2_tracedmp.$suffix >> $LOGFILE 2>&1
		
	ParallelSSH "db2trc off $Db2trcMemAll" "$TRCOUTDIR/db2_traceOFF.$suffix" "$ISROOT" "1" "DB2"
	cat $TRCOUTDIR/db2_traceOFF.$suffix >> $LOGFILE 2>&1			   
}	
############################################################################################
# Function name: perf_collect_dbtrc_data
# Purpose      : To collect dbtrc data for perf collection
###########################################################################################
function perf_collect_db2trc_data()
{
    if [ "x$DEBUG" == "x1" ]; then
        set -xv
    fi

    CDE="$1"
    PERIOD="$2"
    OUTDIR="$3"
	CTR3="$4"
	suffix="$5"
    KEEP="$6"

    TRCOUTDIR=$( echo "$OUTDIR/DB2TRCData" )
	CreateDIR "$TRCOUTDIR"

    log "[DB2TRC]: Starting to collect db2trc data "
	log "[DB2TRC]: Incoming params ( CDE = $CDE, PERIOD = $PERIOD, MAX = $MAX, KEEP = $KEEP, OUTDIR = $TRCOUTDIR )"

	SLEEPTIME=$(( PERIOD < 20 ? PERIOD : 20 ))

	log "[DB2TRC Data]: Started $CTR3 of $MAX iterations"
	printf '\n%s\n' "`date`: [DB2TRC Data]: Started $CTR3 of $MAX iterations"
				
	if [ "x$KEEP" != "x-1" ]; then
		log "[DB2TRC Data]: Deleting below files modified $KEEP minutes ago " 
		find $TRCOUTDIR -name "*" -mmin +$KEEP >> $LOGFILE 2>&1
		find $TRCOUTDIR -name "*" -mmin +$KEEP | xargs rm -f
	fi

	log "[DB2TRC]: Started $CTR3 of $MAX db2trc iterations"           
	collect_db2trc_data_HANG_PERF "$CDE" "$TRCOUTDIR" "$suffix" "$SLEEPTIME" "$CTR3"
				
	log "[DB2TRC Data]: Finished $CTR3 of $MAX iterations"
	printf '\n%s\n' "`date`: [DB2TRC Data]: Finished $CTR3 of $MAX iterations"
				
	#RefreshRunningpids  "$TMPFILE"
}
############################################################################################
# Function name: hang_collect_dbtrc_data
# Purpose      : To collect dbtrc data hang collection
###########################################################################################
function hang_collect_db2trc_data()
{
    if [ "x$DEBUG" == "x1" ]; then
        set -xv
    fi

    CDE="$1"
    OUTDIR="$2"
	IH="$3"
    suffix="$4"

    TRCOUTDIR=$( echo "$OUTDIR/DB2TRCData" )
	CreateDIR "$TRCOUTDIR"

    log "[DB2TRC]: Starting to collect db2trc data "
	log "[DB2TRC]: Incoming params ( CDE = $CDE, OUTDIR = $TRCOUTDIR, suffix = $suffix )"
          
    log "[DB2TRC Data]: Started hang data collection ( round $IH of $HANGROUNDS )"
    printf '\n%s\n' "`date`: [DB2TRC Data]: Started hang data collection ( round $IH of $HANGROUNDS )"

	collect_db2trc_data_HANG_PERF "$CDE" "$TRCOUTDIR" "$suffix" "20" "$IH"
		  
	log "[DB2TRC Data]: Finished hang data collection ( round $IH of $HANGROUNDS )"
	printf '\n%s\n' "`date`: [DB2TRC Data]: Finished hang data collection ( round $IH of $HANGROUNDS )"
}
############################################################################################
# Function name: formatTracefiles
# Purpose      : To format trace files
###########################################################################################
function formatTracefiles()
{
    if [ "x$DEBUG" == "x1" ]; then
        set -xv
    fi
	
	TRCOUTDIR="$1"
	
	log "[DB2TRC Data]: Formatting DB2TRC files in path $TRCOUTDIR  "
	printf '\n%s\n' "`date`: [DB2TRC Data]: Formatting DB2TRC files in path $TRCOUTDIR "	
		
	for files in `ls $TRCOUTDIR/trc.*.dmp_*`
	do
	  log "[DB2TRC Data]: Formatting file: $files "
	  fname=$(basename "$files")
	  fdirname=$(dirname $(absPath "$files"))
	  ParallelSSH "db2trc flw -t $files $fdirname/flw.$fname ; db2trc fmt $files $fdirname/fmt.$fname ; db2trc flw -t -data $files $fdirname/flw_data.$fname ; db2trc flw -t -rds $files $fdirname/flw_rds.$fname ; db2trc perffmt $files $fdirname/perffmt.$fname ; db2trc perfrep -rds -g -sort timeelapsed $files $fdirname/perfrep.$fname " "$TRCOUTDIR/db2_traceFormat.$fname" "$ISROOT" "1" "DB2"		  
	  cat $TRCOUTDIR/db2_traceFormat.$fname >> $LOGFILE 2>&1
	done
}
############################################################################################
# Function name: AdditionalCommands
# Purpose      : To execute Additional Commands on Adhoc
###########################################################################################
function AdditionalCommands ()
{  
    if [ "x$DEBUG" == "x1" ]; then
        set -xv
    fi
	
	AddOUTDIR="$1"
	Addsuffix="$2"
	AddCMDTYPE="$3"
		
	log "[$AddCMDTYPE Data]: Start Running Addtional Commands from file: $ADDITIONALCMD "
	echo "`date`: [$AddCMDTYPE Data]: Start Running Addtional Commands from file: $ADDITIONALCMD"
	
	log "Copying $ADDITIONALCMD to $AddOUTDIR"
	yes | cp "$ADDITIONALCMD" "$AddOUTDIR"
	
	log "Below Addtional Commands will be executed "
	log "--------------------------------------------------------------"
	cat -n "$ADDITIONALCMD" >> $LOGFILE 2>&1
	log "--------------------------------------------------------------"
	
	AddCTRY=1
	while read -r Addrec1
	do
		AddCTYPE=$( echo "$Addrec1" | awk '{print $1}' )
		AddCCOMMAND=$( echo "$Addrec1" | awk '{$1= ""; print $0}' )
		AddFILESUFFIX="ADDITIONALCMD.$AddCTYPE.$AddCTRY"

		[[ $( echo "OS DB2PD DB2 DB21 QUERY" | grep -w -q "$AddCTYPE" ; echo $? ) -ne 0 ]] && log "Invalid command in file: $ADDITIONALCMD at line: $AddCTRY - Type: $AddCTYPE - Command: $AddCCOMMAND "
						
		if [[ "$AddCMDTYPE" == "ALL" && "$AddCTYPE" == "OS" ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " hostname; uptime; $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "$NUMHOSTS" "OS" "&"				
		fi
		if [[ "$AddCMDTYPE" == "ALL" && "$AddCTYPE" == "DB2PD" ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
		fi 
		if [[ "$AddCMDTYPE" == "ALL" && "$AddCTYPE" == "DB2" ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "$NUMHOSTS" "DB2"
		fi
		if [[ "$AddCMDTYPE" == "ALL" && "$AddCTYPE" == "DB21" ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "1" "DB2"		
		fi
		if [[ "$AddCMDTYPE" == "ALL" && "$AddCTYPE" == "QUERY" ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " db2 -v connect to $DBNAME ; db2 -v \" $AddCCOMMAND \" ; db2 -v terminate" "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "1" "DB2"
		fi
		
		if [[ "$AddCMDTYPE" == "OS" && "$AddCTYPE" == "OS"    ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " hostname; uptime; $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
		fi
		
		if [[ "$AddCMDTYPE" == "DB2PD" && "$AddCTYPE" == "DB2PD" ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
		fi 
		
		if [[ "$AddCMDTYPE" == "DB2"   && "$AddCTYPE" == "DB2"   ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "$NUMHOSTS" "DB2" && sleep 2
		fi 
		
		if [[ "$AddCMDTYPE" == "DB2"   && "$AddCTYPE" == "DB21"  ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " $AddCCOMMAND " "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "1" "DB2"			
		fi 
		
		if [[ "$AddCMDTYPE" == "DB2"   && "$AddCTYPE" == "QUERY" ]] ; then 
			log "Running Additional Command AddCMDTYPE: $AddCMDTYPE AddCTYPE: $AddCTYPE AddCCOMMAND: $AddCCOMMAND "
			ParallelSSH " db2 -v connect to $DBNAME ; db2 -v \" $AddCCOMMAND \" ; db2 terminate" "$AddOUTDIR/$AddFILESUFFIX.txt.$Addsuffix" "$ISROOT" "1" "DB2"				
		fi
		
		let AddCTRY=$AddCTRY+1
		
	done < "$ADDITIONALCMD"

	log "[$AddCMDTYPE Data]: Finish Running Addtional Commands from file: $ADDITIONALCMD "
	echo "`date`: [$AddCMDTYPE Data]: Finish Running Addtional Commands from file: $ADDITIONALCMD"
}
#############################################################################################
# Function name: check_if_query_still_running
# Purpose:       To check if the SQL is still running or not. If not, dump trace output
#
#############################################################################################
function check_if_query_still_running()
{

  if [ "x$DEBUG" == "x1" ]; then
         set -xv
  fi
  
  CDE="$1"
  PIDFILE="$2"
  TOUTDIR="$3"
  TTIMEOUT="$4"
  FILE="$5"
  APPID="$6"
  APPHDLX="$7"
  BATCHSET="$8"
  EVMONSET="$9"
  
  echo "$(date): INCOMING PARMS: CDE: $CDE PIDFILE: $PIDFILE TOUTDIR: $TOUTDIR TTIMEOUT: $TTIMEOUT FILE: $FILE APPID: $APPID APPHDL: $APPHDLX BATCHSET: $BATCHSET EVMONSET: $EVMONSET "
 
  pidtocheck=$( cat $PIDFILE )  
  echo ""
  ps -elf | grep -w $pidtocheck | grep -v grep
  
  TIMESPCT=$(( TTIMEOUT*20/100 ))
  
  [[ $TIMESPCT -lt 1 ]] && TIMESPCT=1
  [[ $CDE == "R" || $CDE == "r" ]] && printf '\n\n%s\n' "$(date): Trace will be dumped every $TIMESPCT seconds (20% of $TTIMEOUT seconds Timeout) until query completes or $TTIMEOUT seconds timeout is reached."
  
  while kill -0 $pidtocheck >/dev/null 2>&1
  do
                if [[ $TTIMEOUT -gt 0 ]]; then
                    sleep 1
                    TTIMEOUT=$((TTIMEOUT - 1))
                    TTIMES=$(($TTIMEOUT % TIMESPCT))
                        
                    if [[ $TTIMES -eq 0 && ( $CDE == "R" || $CDE == "r" ) ]]; then
                        printf '\n\n%s\n' "$(date): Dumping a trace at seconds: $TTIMEOUT "
                        ( eval "db2trc dmp $FILE.$CDE.T$TTIMEOUT.dmp -sdir $TOUTDIR $Db2trcMemAll" )
                    elif [[ $TTIMES -eq 0 ]]; then
                        printf '\n\n%s\n' "$(date): $TIMESPCT seconds elapsed. Timeout: $TTIMEOUT seconds. (Waiting to it to become 0 or query gets completed)"
                    fi
                        
                else
						printf '\n\n%s\n' "$(date): Dumping trace just before killing: $APPID at seconds: $TTIMEOUT "
                        ( eval "db2trc dmp $FILE.$CDE.TA$TTIMEOUT.dmp -sdir $TOUTDIR $Db2trcMemAll" )

						if [[ $EVMONSET -eq 1 && ! -z $APPID ]]; then
							EQUERY="select APPLICATION_HANDLE, UOW_ID , ACTIVITY_ID FROM TABLE(MON_GET_ACTIVITY(NULL, -2)) WHERE CLIENT_APPLNAME = 'USER_ACTUALS' AND CLIENT_ACCTNG = 'USER_ACTUALS' AND SUBSTR(STMT_TEXT,1,100) NOT LIKE 'call DBMS_ALERT.SLEEP%' AND APPL_ID = '"$APPID"' fetch first 1 rows only "

							# RUNNING AS ParallelSSH coz the same process hangs to query tables when the main process is running never completing query.
							ParallelSSH "db2 -x connect to $DBNAME; db2 -x \"$EQUERY\" ; db2 -x terminate " "$TOUTDIR/db2_WLM_CANCEL_ACTIVITY.$tstamp" "$ISROOT" "1" "DB2"

							tvalues=$( cat $TOUTDIR/db2_WLM_CANCEL_ACTIVITY.$tstamp | sed -n '/ Local database alias   = /,/DB20000I  The TERMINATE command completed/{//!p;}' | awk NF | egrep -v '^\+|SQLSTATE|^SQL' )
							APPHDL=$( echo $tvalues | awk '{print $1}' )
							UOWID=$( echo $tvalues | awk '{print $2}' )
							ACTIVITYID=$( echo $tvalues | awk '{print $3}' )
													
							if [[ ! -z $APPHDL && ! -z $UOWID && ! -z $ACTIVITYID ]]; then
								EQUERY="call WLM_CANCEL_ACTIVITY ('"$APPHDL"','"$UOWID"','"$ACTIVITYID"')"								
								printf '\n\n%s\n' "$(date): Calling \"$EQUERY\" due to timeout $TTIMEOUT reached."
								ParallelSSH "db2 -x connect to $DBNAME; db2 -v \"$EQUERY\" ; db2 -x terminate " "$TOUTDIR/db2_Calling_WLM_CANCEL_ACTIVITY.$tstamp" "$ISROOT" "1" "DB2"															
								printf '\n\n%s\n' "$(date): Sleeping 10 seconds"
								sleep 10
							fi
						fi
						
						if [[ $BATCHSET -eq 1 ]]; then
							db2 connect to $DBNAME > /dev/null 2>&1
							printf '\n\n%s\n' "$(date): Calling force applications ($APPHDLX) due to timeout $TTIMEOUT reached."
							db2 -v "force applications ("$APPHDLX")"
							db2 terminate > /dev/null 2>&1
							printf '\n\n%s\n' "$(date): Sleeping 10 seconds"
							sleep 10
						fi
				    
                    printf '\n\n%s\n' "$(date): Killing $pidtocheck due to timeout $TTIMEOUT reached."
                    kill -SIGINT $pidtocheck  >/dev/null 2>&1
                    sleep 1
                fi
  done
  
  printf '\n\n%s\n' "$(date): Query PID $pidtocheck killed due to timeout or completed successfully. Dumping final trace."
  ( eval "db2trc dmp $FILE.$CDE.TF$TTIMEOUT.dmp -sdir $TOUTDIR $Db2trcMemAll" )
  ( eval "db2trc off $Db2trcMemAll" )
  
  if [[ $EVMONSET -eq 1 ]]; then 
  
	printf '\n\n%s\n' "$(date): Disabling event monitor: USER_ACTUALS"
	db2 connect to $DBNAME > /dev/null 2>&1
	db2 -v "SELECT substr(evmonname, 1, 30) as EVMONNAME , event_mon_state(evmonname) as STATE FROM syscat.eventmonitors WHERE evmonname = 'USER_ACTUALS' "
	db2 -v "set event monitor USER_ACTUALS state 0"
	db2 -v "Alter workload USER_ACTUALS DISABLE "
	db2 -v "drop workload USER_ACTUALS "
	db2 -v "SELECT substr(evmonname, 1, 30) as EVMONNAME , event_mon_state(evmonname) as STATE FROM syscat.eventmonitors WHERE evmonname = 'USER_ACTUALS' "
	printf '\n\n%s\n' "$(date): Collecting Explain Actuals "
	
	if [[ $BATCHSET -eq 1 ]] ; then
		EQUERY="SELECT a.time_completed, Substr(appl_name, 1, 20)   appl_name, Substr(a.appl_id, 1, 40)   appl_id, a.uow_id, a.activity_id, Length(a.section_actuals)  act_len, Substr(s.stmt_text, 1, 10000) stmt FROM   ACTIVITY_USER_ACTUALS a, ACTIVITYSTMT_USER_ACTUALS s WHERE  a.appl_id = s.appl_id AND a.uow_id = s.uow_id AND a.activity_id = s.activity_id AND a.APPL_NAME = 'db2batch' and Substr(s.stmt_text, 1, 50) NOT LIKE 'call DBMS_ALERT.SLEEP%' and Substr(s.stmt_text, 1, 50) NOT LIKE 'CALL SYSPROC.WLM_SET_CLIENT_INFO%' and Length(a.section_actuals) > 0 AND a.appl_id = '"$APPID"'"
		EQUERY1="SELECT a.* , Substr(s.stmt_text, 1, 15000) as stmt FROM   ACTIVITY_USER_ACTUALS a, ACTIVITYSTMT_USER_ACTUALS s WHERE  a.appl_id = s.appl_id AND a.uow_id = s.uow_id AND a.activity_id = s.activity_id AND a.APPL_NAME = 'db2batch' and Substr(s.stmt_text, 1, 50) NOT LIKE 'call DBMS_ALERT.SLEEP%' and Substr(s.stmt_text, 1, 50) NOT LIKE 'CALL SYSPROC.WLM_SET_CLIENT_INFO%' and Length(a.section_actuals) > 0 AND a.appl_id = '"$APPID"'"
	else
		EQUERY="SELECT a.time_completed, Substr(appl_name, 1, 20)   appl_name, Substr(a.appl_id, 1, 40)   appl_id, a.uow_id, a.activity_id, Length(a.section_actuals)  act_len, Substr(s.stmt_text, 1, 10000) stmt FROM   ACTIVITY_USER_ACTUALS a, ACTIVITYSTMT_USER_ACTUALS s WHERE  a.appl_id = s.appl_id AND a.uow_id = s.uow_id AND a.activity_id = s.activity_id AND a.APPL_NAME = 'db2bp' and Substr(s.stmt_text, 1, 50) NOT LIKE 'call DBMS_ALERT.SLEEP%' and Substr(s.stmt_text, 1, 50) NOT LIKE 'CALL SYSPROC.WLM_SET_CLIENT_INFO%' and Length(a.section_actuals) > 0 AND a.appl_id = '"$APPID"'"
		EQUERY1="SELECT a.* , substr(s.stmt_text, 1, 15000) as stmt FROM   ACTIVITY_USER_ACTUALS a, ACTIVITYSTMT_USER_ACTUALS s WHERE  a.appl_id = s.appl_id AND a.uow_id = s.uow_id AND a.activity_id = s.activity_id AND a.APPL_NAME = 'db2bp' and Substr(s.stmt_text, 1, 50) NOT LIKE 'call DBMS_ALERT.SLEEP%' and Substr(s.stmt_text, 1, 50) NOT LIKE 'CALL SYSPROC.WLM_SET_CLIENT_INFO%' and Length(a.section_actuals) > 0 AND a.appl_id = '"$APPID"'"
	fi
	db2 -x "$EQUERY" > $TOUTDIR/$FILE.activitytables.out
	db2 -v "$EQUERY1" > $TOUTDIR/$FILE.ACTIVITY_USER_ACTUALS.out
	db2 terminate > /dev/null 2>&1
	
	ctry=1
	cat $TOUTDIR/$FILE.activitytables.out | grep "$APPID" | grep -v grep | while read rec
	do
		 XAPPLID=$( echo $rec | awk '{ print $3 ;} ' )
		 XUOWID=$( echo $rec | awk '{ print $4 ;} ' )
		 XACTIVITY=$( echo $rec | awk '{ print $5 ;} ' )
		 db2 connect to $DBNAME > /dev/null 2>&1
		 db2 -v "CALL EXPLAIN_FROM_ACTIVITY( '"$XAPPLID"', "$XUOWID", "$XACTIVITY" , 'USER_ACTUALS', '', ?, ?, ?, ?, ? )" > $TOUTDIR/$FILE.EXPLAIN_FROM_ACTIVITY.$ctry.$APPHDLX.$XUOWID.$XACTIVITY.txt
		 
		 check_success=$( cat  $TOUTDIR/$FILE.EXPLAIN_FROM_ACTIVITY.$ctry.$APPHDLX.$XUOWID.$XACTIVITY.txt | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
		 
		 if [ $check_success -eq 0 ]; then
			 
				param_values=$( cat  $TOUTDIR/$FILE.EXPLAIN_FROM_ACTIVITY.$ctry.$APPHDLX.$XUOWID.$XACTIVITY.txt | grep -i "Parameter Value" | awk '{ print $NF; }' )
                param1=$( echo $param_values | awk '{ print $1; }' )
                param3=$( echo $param_values | awk '{ print $3; }' )
                param4=$( echo $param_values | awk '{ print $4; }' )
                param5=$( echo $param_values | awk '{ print $5; }' )						
				
				db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $TOUTDIR/$FILE.Actuals.exfmt.$ctry.$APPHDLX.$XUOWID.$XACTIVITY.txt 	
				printf '\n\n%s\n\n' "$(date): Collected explain actuals of Apphandle: $APPHDLX  , File: $TOUTDIR/$FILE.Actuals.exfmt.$ctry.$APPHDLX.$XUOWID.$XACTIVITY.txt  "								
		fi
		db2 terminate > /dev/null 2>&1 		  
		let ctry=$ctry+1
	done
	
  fi
  
  printf '\n\n%s\n' "$(date): Formatting trace files"
  for files in `ls $TOUTDIR/$FILE.$CDE.T*.dmp*`
  do

			  printf '\n\n%s\n' "$(date): Formatting file: $files ."
			  fname=$(basename "$files")
			  fdirname=$(dirname $(absPath "$files"))
			  
                   if [[ "$CDE" == "C" ]]; then
		
                      db2trc fmt $files $fdirname/fmt.$fname

                   else

                      db2trc fmt $files $fdirname/fmt.$fname
                      db2trc flw $files $fdirname/flw.$fname -t
                      db2trc flw $files $fdirname/rds.$fname -t -rds
                      db2trc flw -t -data $files $fdirname/data.$fname
                      db2trc perfrep -rds -g -sort timeelapsed $files $fdirname/perfrep.$fname
                      db2trc fflw  -wc -rds $files $fdirname/fflw.$fname 
                   fi
  done
  
  printf '\n\n%s\n' "`date` : Gather the files in $TOUTDIR and upload"
}
######################################################################################
#Function: get_version
#Purpose : To get Db2 version. Its required to check for MON_GET_WLM_ADMISSION_QUEUE 
#          function which is available from 11.5.4+
#
#####################################################################################
function get_version()
{
  if [ "x$DEBUG" == "x1" ]; then
         set -xv
  fi

    version=$( db2level|grep "Informational"|awk '{ print $5; }'|sed 's/[^0-9]*//g;')

    #checking to see if version has all digits or not

    len=$( expr "x$version" : "x[0-9]*$" )

    if [ $len -gt 1 ]; then

       # It is all digits. Check if its >=11540

       if [ $version -gt 11540 ]; then 

           echo 1

       else

           echo 0

       fi

    fi
}
#########################################################################################################
#Function: retchk
#Purpose : Check return code of the command
#########################################################################################################
function retchk() {
		
		ret="$1"
        LINE="$2"
        COMMAND="$3"
        RHOST="$4"
		MESSAGE="$5"
		CLEANUP="$6"
		
		[[ ! -z "$LINE" ]] && PLINE="Line: `echo $LINE` "
		[[ ! -z "$COMMAND" ]] && PCOMMAND="Command: `echo $COMMAND` "
		[[ ! -z "$RHOST" ]] && PRHOST="HOST: `echo $RHOST` "
		[[ ! -z "$MESSAGE" ]] && PMESSAGE="Message: `echo $MESSAGE` "
		
        if [[ "${ret}" != "0" ]] ; then
            printf '\n\n%s\n' "$(date '+%Y-%m-%d-%H.%M.%S') - $PRHOST - Failed at $PLINE - $PCOMMAND"
    		printf '%s\n\n' "$PMESSAGE"
			# IF $CLEANUP is NOT SET THEN RUN CLEANUP ELSE IF SET TO D DELETE THE OUTDIR TOO
			if [[ -z "$CLEANUP" ]]; then 
				cleanup
			fi
			if [[ ! -z "$CLEANUP" ]] && [[ "$CLEANUP" -eq "D" ]] ; then
				cleanup "D"
			fi
			exit "${ret}"
        else
            [[ "x$DEBUG" == "x1" ]] && echo "Timestamp: $(date '+%Y-%m-%d-%H.%M.%S') $PRHOST $PLINE $PCOMMAND Return Code: ${ret}"
        fi
}
#########################################################################################################
#Function: CreateDIR
#Purpose : Function to create a directory.
#########################################################################################################
function CreateDIR() {

	if [[ ! -d "$1" ]]; then	 
		 mkdir -p "$1"  > /dev/null 2>&1

		 if [ $? -eq 0 ]; then
			chmod 777 "$1"
		 else     
			printf '\n\n%s\n' "Unable to create directory: $1 .. bailing out !!"
			cleanup
			exit 0
		 fi
	fi
}
#########################################################################################################
#Function: COPYSCP
#Purpose : scp files and rm -rf files.
#########################################################################################################
function COPYSCP ()
{
  if [ "x$DEBUG" == "x1" ]; then
         set -xv
  fi

  SOURCEHOSTNAME="$1"
  SOURCEPATH="$2"
  FILEPREFIX="$3"
  TARGETPATH="$4"
                  
  log "Copying $SOURCEHOSTNAME:$SOURCEPATH/*.$FILEPREFIX to $TARGETPATH"
  scp "$SOURCEHOSTNAME":"$SOURCEPATH"/*."$FILEPREFIX" "$TARGETPATH"   2>> $LOGFILE
  ssh "$SOURCEHOSTNAME" "rm -rf \"$SOURCEPATH\"/*.\"$FILEPREFIX\" "   2>> $LOGFILE
}
#########################################################################################################
#Function: CheckIfScriptAlreadyRunning
#Purpose : Check if script is already running as we allow only single instance to be executed.
#########################################################################################################
function CheckIfScriptAlreadyRunning()
{	
	if [ "x$DEBUG" == "x1" ]; then
	   set -xv 
	fi

	if [[ $NUMHOSTS -eq 1 ]]; then
	
		if [[ -f /tmp/.tmp.dbmonitorpid ]] && [[ -s "/tmp/.tmp.dbmonitorpid" ]]; then 
		
			printf '\n\n%s\n' "Looks like another instance of this script: `basename $0` is already running with PID: $( cat /tmp/.tmp.dbmonitorpid ) . "
			printf '\n\n%s\n' "Run the command: \"`basename $0` -stop \" to stop the already running script gracefully"
			rm -rf $OUTDIR ; retchk "$?" "$LINENO" "rm -rf $OUTDIR" "$(hostname)" "Cannot delete folder  $OUTDIR" "N"
			exit 0
			
		elif [[ -f /tmp/.tmp.dbmonitorpid ]] && [[ ! -s "/tmp/.tmp.dbmonitorpid" ]]; then 
		
			printf '\n\n%s\n' "Looks like previous run of this script: `basename $0` did not end gracefully. Empty file \"/tmp/.tmp.dbmonitorpid\" already exists! "
			printf '\n\n%s\n' "Deleting this file now /tmp/.tmp.dbmonitorpid  so that you can run this script: `basename $0` again. If the file cannot be deleted, you can delete it manually and run the script again."	
			rm -rf /tmp/.tmp.dbmonitorpid ; retchk "$?" "$LINENO" "rm -rf /tmp/.tmp.dbmonitorpid" "$(hostname)" "Cannot delete file /tmp/.tmp.dbmonitorpid" "N"
			printf '\n\n%s\n' "File deleted: /tmp/.tmp.dbmonitorpid . Please run the script: `basename $0` again."	
			rm -rf $OUTDIR ; retchk "$?" "$LINENO" "rm -rf $OUTDIR" "$(hostname)" "Cannot delete folder  $OUTDIR" "N"
			
		else
			touch /tmp/.tmp.dbmonitorpid ; retchk "$?" "$LINENO" "touch /tmp/.tmp.dbmonitorpid" "$(hostname)" "Cannot create file /tmp/.tmp.dbmonitorpid"
			chmod 777 /tmp/.tmp.dbmonitorpid ; retchk "$?" "$LINENO" "chmod 777 /tmp/.tmp.dbmonitorpid" "$(hostname)" "Cannot set 777 permissions for file /tmp/.tmp.dbmonitorpid"
		fi

	else
		
		for ihosts in `echo $HOSTS` 
		do
			if [[ $( ssh $ihosts 'bash -c "[[  -f /tmp/.tmp.dbmonitorpid ]] && echo 1 || echo 0 " ' ) -eq 1 ]]; then
					
				checkpid=$( ssh $ihosts 'bash -c "cat /tmp/.tmp.dbmonitorpid" ' )
				if [[ ! -z $checkpid ]] ; then 
					printf '\n\n%s\n' "Looks like another instance of this script: `basename $0` is already running on host: $ihosts with PID: $( ssh $ihosts 'bash -c "cat /tmp/.tmp.dbmonitorpid" ' ) . "
					printf '\n\n%s\n' "Run the command: \"`basename $0` -stop \" on host: $ihosts to stop the already running script gracefully"
					rm -rf $OUTDIR ; retchk "$?" "$LINENO" "rm -rf $OUTDIR" "$(hostname)" "Cannot delete folder  $OUTDIR" "N"
					exit 0
				else
					printf '\n\n%s\n' "Empty file /tmp/.tmp.dbmonitorpid exists on host: $ihosts "
					printf '\n\n%s\n' "This is probably because of failed previous run for script  `basename $0` . Trying to delete the file and see if we can proceed. "
					if [[ $( ssh $ihosts 'bash -c "rm -rf /tmp/.tmp.dbmonitorpid && echo 1 || echo 0 " ' ) -eq 0 ]]; then
					
						printf '\n\n%s\n' "Failed to delete Empty file /tmp/.tmp.dbmonitorpid on host: $ihosts . Cannot continue."
						printf '\n\n%s\n' "Please manually delete the file /tmp/.tmp.dbmonitorpid on host: $ihosts . and rerun the script"
						rm -rf $OUTDIR ; retchk "$?" "$LINENO" "rm -rf $OUTDIR" "$(hostname)" "Cannot delete folder  $OUTDIR" "N"
						exit 0
					else
						printf '\n\n%s\n' "Deleted Empty file /tmp/.tmp.dbmonitorpid on host: $ihosts . Please rerun the script again and it should run fine now."
						rm -rf $OUTDIR ; retchk "$?" "$LINENO" "rm -rf $OUTDIR" "$(hostname)" "Cannot delete folder  $OUTDIR" "N"
						exit 0
					fi
				fi				
			fi
		done
	fi
}
#########################################################################################################
#Function: CollectHangAPPAPPHDL
#Purpose : Collect Apphdl specific data for HangApp option.
#########################################################################################################
function CollectHangAPPAPPHDL ()
{
	if [ "x$DEBUG" == "x1" ]; then
	   set -xv 
	fi
	
	DBNAME="$1"
	OUTDIR="$2"
	apphandle="$3"
	IH="$4"
	tstamp="$5"
	HANG_DB2TRC="$6"
	
	STACKDIR=$( echo "$OUTDIR/stacks_app_$apphandle" )
	CreateDIR "$STACKDIR" 

	log "[DB2PD data]: Collecting db2pd -dump for apphanndle $apphandle - Round $IH of $HROUNDS"
	echo "`date`: [DB2PD data]: Collecting db2pd -dump for apphanndle $apphandle - Round $IH of $HROUNDS"

	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -dump all apphdl=$apphandle dumpdir=$STACKDIR -rep 2 3" "$OUTDIR/db2pd_dumpall_apphdl_$apphandle.$IH.$tstamp.txt" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"           

	log "[DB2PD data]: Collecting app specific db2pd information - Round $IH of $HROUNDS"
	echo "`date`: [DB2PD data]: Collecting app specific db2pd information - Round $IH of $HROUNDS"

	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -apinfo $apphandle metrics -rep 2 3" "$OUTDIR/db2pd_apinfo_apphdl.txt.$apphandle.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -agents app=$apphandle -rep 2 3" "$OUTDIR/db2pd_agents_apphdl.txt.$apphandle.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -transactions $apphandle -rep 2 3" "$OUTDIR/db2pd_transactions_apphdl.txt.$apphandle.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -applications $apphandle -rep 2 3" "$OUTDIR/db2pd_applications_apphdl.txt.$apphandle.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -active apphdl=$apphandle -rep 2 3" "$OUTDIR/db2pd_active_apphdl.txt.$apphandle.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -sort  apphdl=$apphandle -rep 2 3" "$OUTDIR/db2pd_sort_apphdl.txt.$apphandle.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -locks apphdl=$apphandle -rep 2 3" "$OUTDIR/db2pd_locks_apphdl.txt.$apphandle.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	
	log "[SNAP data]: Taking global application snapshot for apphandle $apphandle - Round $IH of $HROUNDS"
	echo "`date`: [SNAP data]: Taking global application snapshot for apphandle $apphandle - Round $IH of $HROUNDS"
	
	# RUN ON JUST ONE HOST Make sure Instance db2 get dbm cfg | grep DFT are ON.
	ParallelSSH "db2 -v get snapshot for application agentid $apphandle global" "$OUTDIR/globsnap_apphdl.$apphandle.$IH.$tstamp" "$ISROOT" "1" "DB2"			
		
	
	log "[MON data]: Collecting app $apphandle specifc mon functions - Round $IH of $HROUNDS"
	echo "`date`: [MON data]: Collecting app $apphandle specific mon functions - Round $IH of $HROUNDS"

	Q1="db2 -v \"with act_data( member, application_handle, uow_id, activity_id, entry_time, local_start_time, rows_inserted, rows_deleted, rows_updated, rows_read, fcm_tq_recv_waits_total, fcm_tq_send_waits_total, fcm_tq_recvs_total, fcm_tq_recv_volume, fcm_tq_recv_wait_time, fcm_tq_sends_total, fcm_tq_send_volume, fcm_tq_send_wait_time ) as ( select member, application_handle, uow_id, activity_id, entry_time, local_start_time, rows_inserted, rows_deleted, rows_updated, rows_read, fcm_tq_recv_waits_total, fcm_tq_send_waits_total, fcm_tq_recvs_total, fcm_tq_recv_volume, fcm_tq_recv_wait_time, fcm_tq_sends_total, fcm_tq_send_volume, fcm_tq_send_wait_time from table( mon_get_activity( $apphandle, -2 )) )  select current timestamp as curr_tstamp,  age.member as member, substr(char(age.application_handle),1,7) as apphandle,  age.uow_id  as uow_id,  age.activity_id  as activity_id, act.entry_time, act.local_start_time, age.request_start_time, age.agent_state_last_update_time, timestampdiff( 2, CHAR( age.agent_state_last_update_time - age.request_start_time ) ) as elapsed_secs, substr(char(age.agent_tid),1,20) as agent_tid, substr(age.agent_subtype,1,10) as agent_subtype, substr(agent_state,1,10) as agent_state, substr(age.event_state,1,10) as event_state, substr(event_type,1,10) as event_type, substr( age.event_object,1,10) as event_object, substr( age.request_type,1,12) as request_type, substr( age.event_object_name,1,10)  as tq_id, substr( char( age.subsection_number),1,4) as subsect_num, substr( age.event_object_details,1,10) as tq_wait_member, act.rows_inserted, act.rows_deleted, act.rows_updated, act.rows_read, act.fcm_tq_recv_waits_total, act.fcm_tq_send_waits_total, act.fcm_tq_recvs_total, act.fcm_tq_recv_volume, act.fcm_tq_recv_wait_time, act.fcm_tq_sends_total, act.fcm_tq_send_volume, act.fcm_tq_send_wait_time from table( mon_get_agent( null, null, $apphandle, -2 )) as age left outer join act_data as act on age.member = act.member and age.application_handle = act.application_handle and age.uow_id = act.uow_id and age.activity_id = act.activity_id order by age.application_handle, age.member\" > $OUTDIR/subsectInfo_apphdl.$apphandle.$IH.txt.$tstamp "
	Q2="db2 -v \"with activity_handles(application_handle) as (select application_handle from table(mon_get_activity($apphandle,-2)) where member=coord_partition_num and activity_type != 'DDL' ) select a.request_start_time, a.agent_state_last_update_time, current timestamp as current_time, a.application_handle, a.member,  a.agent_tid, substr(a.agent_type,1,11) as agenttype, substr(a.agent_state,1,10) as agentstate, substr(a.request_type,1,12) as reqtype, substr(a.event_object,1,16) as event_object, substr(a.event_state,1,16) as event_state, substr(event_object_name,1,32) as event_object_name, substr(event_object_details,1,32) as event_object_details,a.uow_id, a.activity_id from table(mon_get_agent(null,null, null, -2)) a, activity_handles d where a.application_handle = d.application_handle order by application_handle, member\" > $OUTDIR/activity_details_apphdl.$apphandle.txt.$IH.$tstamp "
	Q3="db2 -v \"select current timestamp as timestamp, coord_member, member, application_handle, entry_time, local_start_time, timestampdiff(2, CHAR(current timestamp - local_start_time) ) as elapsed_sec, timestampdiff(2, CHAR(local_start_time - entry_time)) as queued_secs, substr(activity_state,1,16) as state, substr(activity_type,1,12) as type, last_reference_time, total_section_time, total_section_proc_time, total_act_time, total_act_wait_time, total_cpu_time, lock_wait_time, pool_read_time, pool_write_time, total_extended_latch_wait_time, lock_wait_time, log_buffer_wait_time, log_disk_wait_time, diaglog_write_wait_time, evmon_wait_time, prefetch_wait_time, ext_table_recv_wait_time, ext_table_recvs_total, ext_table_read_volume, fcm_recv_wait_time, fcm_send_wait_time,  effective_query_degree, substr(client_userid,1,20) as client_userid, NUM_AGENTS, agents_top, intra_parallel_state, SORT_SHRHEAP_ALLOCATED, adm_resource_actuals,  coord_stmt_exec_time,  SORT_SHRHEAP_TOP, ESTIMATED_SORT_SHRHEAP_TOP, substr(activity_type,1,30) act_type, UOW_ID, ACTIVITY_ID, coord_member, executable_id, STMTID, PLANID, rows_read, rows_modified, rows_returned, substr(stmt_text,1,100) as stmt_text from table(mon_get_activity($apphandle,-2))  order by member\" > $OUTDIR/query_activity_metrics_apphdl.$apphandle.$IH.$tstamp "				
	Q4="db2 -x \"select application_handle, uow_id, activity_id, coord_partition_num, executable_id from table(mon_get_activity($apphandle,-2)) where member = coord_partition_num order by activity_id desc with ur \" > $OUTDIR/query_mon_get_activity_apphdl.$apphandle.$IH.$tstamp "

	ParallelSSH "db2 connect to $DBNAME; $Q1 ; $Q2 ; $Q3 ; $Q4 ; db2 terminate " "$OUTDIR/AllQueries.$apphandle.$IH.txt.$tstamp" "$ISROOT" "1" "DB2"			

	cat $OUTDIR/query_mon_get_activity_apphdl.$apphandle.$IH.$tstamp | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
    do
        apphandle=$( echo $rec | awk '{ print $1; }' )
        uowid=$( echo $rec | awk '{ print $2; }' )
        actid=$( echo $rec | awk '{ print $3; }' )
        coord=$( echo $rec | awk '{ print $4; }' )
        executable_id=$( echo $rec | awk '{ print $5; }' )
		 
		ParallelSSH "db2 connect to $DBNAME; db2 \" call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) \" ; db2 terminate " "$OUTDIR/explain_section_apphdl.$apphandle.$IH.$tstamp" "$ISROOT" "1" "DB2"
		check_success=$( cat  $OUTDIR/explain_section_apphdl.$apphandle.$IH.$tstamp | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
	
		if [ $check_success -eq 0 ]; then
	 
			param_values=$( cat  $OUTDIR/explain_section_apphdl.$apphandle.$IH.$tstamp | grep -i "Parameter Value" | awk '{ print $NF; }' )
			param1=$( echo $param_values | awk '{ print $1; }' )
			param3=$( echo $param_values | awk '{ print $3; }' )
			param4=$( echo $param_values | awk '{ print $4; }' )
			param5=$( echo $param_values | awk '{ print $5; }' )						
		
			ParallelSSH "db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $OUTDIR/exfmt_apphdl.$apphandle.$IH.$tstamp 2>&1" "$OUTDIR/db2exfmt_apphdl.$apphandle.$IH.$tstamp" "$ISROOT" "1" "DB2"
			log "Collected explain of Apphandle: $apphandle, Execid: $executable_id , File: $OUTDIR/exfmt_apphdl.$apphandle.$IH.$tstamp - Round $IH of $HROUNDS"
		fi
	done
	
	if [ "x$HANG_DB2TRC" = "x1" ]; then

		log "[DB2TRC data]: Collecting a quick db2trc for $apphandle - Round $IH of $HROUNDS"
		echo "`date`: [DB2TRC data]: Collecting a quick db2trc for $apphandle - Round $IH of $HROUNDS"

		ParallelSSH "db2trc on -i 512m -t -apphdl $apphandle $Db2trcMemAll" "$OUTDIR/db2_traceON_apphdl.$apphandle.$IH.$tstamp" "$ISROOT" "1" "DB2"

		log "[DB2TRC data]: Sleeping for 10 seconds before dumping the trace for $apphandle - Round $IH of $HROUNDS"
		echo "`date`: [DB2TRC data]: Sleeping for 10 seconds before dumping the trace for apphdl $apphandle - Round $IH of $HROUNDS"					
		sleep 10

		ParallelSSH "db2trc dmp trc_hang.$IH.$apphandle.dmp -sdir $STACKDIR $Db2trcMemAll" "$OUTDIR/db2_tracedmp_apphdl.$apphandle.$IH.$tstamp" "$ISROOT" "1" "DB2"
		ParallelSSH "db2trc off $Db2trcMemAll" "$OUTDIR/db2_traceOFF_apphdl.$apphandle.$IH.$tstamp" "$ISROOT" "1" "DB2"

		log "[DB2TRC data]: Finished collecting db2trc for $apphandle - Round $IH of $HROUNDS"
		echo "`date`: [DB2TRC data]: Finished collecting db2trc for $apphandle - Round $IH of $HROUNDS"
		
		log "[DB2TRC data]: Start Formatting db2trc for $apphandle - Round $IH of $HROUNDS"
		echo "`date`: [DB2TRC data]: Start Formatting db2trc for $apphandle - Round $IH of $HROUNDS"
		
		for files in `ls $STACKDIR/trc_hang.$IH.$apphandle.dmp* `
		do
			log "[DB2TRC data]: Start Formatting file: $files - Round $IH of $HROUNDS"
			echo "`date`: [DB2TRC data]: Start Formatting file: $files - Round $IH of $HROUNDS"
			fname=$(basename "$files")
			fdirname=$(dirname $(absPath "$files"))
			ParallelSSH "db2trc flw -t $files $fdirname/flw.$fname ; db2trc fmt $files $fdirname/fmt.$fname ; db2trc flw -t -data $files $fdirname/flw_data.$fname ; db2trc flw -t -rds $files $fdirname/flw_rds.$fname ; db2trc perffmt $files $fdirname/perffmt.$fname ; db2trc perfrep -rds -g -sort timeelapsed $files $fdirname/perfrep.$fname " "$OUTDIR/db2_traceFormat.$tstamp" "$ISROOT" "1" "DB2"
			log "[DB2TRC data]: Finished Formatting file: $files - Round $IH of $HROUNDS"
			echo "`date`: [DB2TRC data]: Finished Formatting file: $files - Round $IH of $HROUNDS"
		done
		
		log "[DB2TRC data]: Finished Formatting db2trc for $apphandle - Round $IH of $HROUNDS"
		echo "`date`: [DB2TRC data]: Finished Formatting db2trc for $apphandle - Round $IH of $HROUNDS"

	fi
		
	#RefreshRunningpids "$TMPFILE"
}
#########################################################################################################
#Function: CollectHangAPPCommonMON
#Purpose : Collect common data MON Functions for HangApp option.
#########################################################################################################
function CollectHangAPPCommonMON ()
{
	if [ "x$DEBUG" == "x1" ]; then
	   set -xv 
	fi
	
	DBNAME="$1"
	OUTDIR="$2"
	IH="$3"
	tstamp="$4"
	
	Q01="db2 -v \"select current timestamp as timestamp, sort_shrheap_allocated, sort_shrheap_top, wlm_queue_time_total, wlm_queue_assignments_total, member from table( mon_get_database(-2)) order by member\" > $OUTDIR/sortmem_dblevel.txt.$IH.$tstamp" 
	Q02="db2 -v \"with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), actual_mem( tot_alloc_sortheap, sortmember ) as ( select sum( sort_shrheap_allocated ), member from table(mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING'  or activity_state = 'IDLE' ) group by member ) select current timestamp as curr_timestamp, sortmember as member, tot_alloc_sortheap as allocated_sort_heap, decimal( ( tot_alloc_sortheap / SHEAPTHRESSHR)*100,5,2) as pct_sortmem_used, int( SHEAPTHRESSHR ) as cfg_shrheap_thresh  from actual_mem, SORTMEM where sortmember = SHEAPMEMBER order by member\"  > $OUTDIR/sortmemUsagePerMember.txt.$IH.$tstamp" 
	Q03="db2 -v \"with SORTMEM( SHEAPTHRESHSHR, SHEAPMEMBER ) as ( select value, member from sysibmadm.dbcfg where NAME = 'sheapthres_shr' ), APPHBYPASS( apphandle, admbypass ) as ( select application_handle, adm_bypassed from table( mon_get_activity(null,-2)) where activity_state in ('EXECUTING','IDLE') and coord_partition_num = member ) , ALLOCMEMBYPASS( appmember, apphandle, admbypass, allocmem ) as ( select A.member, A.application_handle, B.admbypass, sum( A.sort_shrheap_allocated ) from table( mon_get_activity(null, -2 )) as A, APPHBYPASS B where A.activity_state in ('EXECUTING','IDLE') and A.application_handle = B.apphandle group by A.member, A.application_handle, B.admbypass ) select current timestamp as timestamp, appmember, admbypass, sum(allocmem) as sortmem_used, decimal( ( sum( allocmem ) / sum(sheapthreshshr) ) * 100, 5, 2) as sortmem_used_pct from ALLOCMEMBYPASS, SORTMEM where APPMEMBER = SHEAPMEMBER group by appmember, admbypass order by  sortmem_used_pct desc\"  > $OUTDIR/sortmemUsagePerMember_Bypass.txt.$IH.$tstamp" 		
	Q04="db2 -v \"with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), APPSORTMEM( apphandle, appmember, admbypassed, est_sortmem, alloc_sortmem) as ( select application_handle, member, adm_bypassed, max( estimated_sort_shrheap_top), sum(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by application_handle, member , adm_bypassed ) select current timestamp as curr_timestamp, appmember, apphandle,  admbypassed  as adm_bypass, alloc_sortmem as allocated_sortmem, decimal( ( alloc_sortmem / SHEAPTHRESSHR) * 100, 5,2 ) as pct_sortmem_used, est_sortmem, decimal( ( est_sortmem / SHEAPTHRESSHR ) * 100, 5,2) as pct_est_sortmem, int(SHEAPTHRESSHR) as cfg_shrheap_thresh  from SORTMEM, APPSORTMEM where SHEAPMEMBER = appmember and alloc_sortmem > 0 order by appmember, pct_sortmem_used desc\"  > $OUTDIR/sortmemUsagePerApphandle.txt.$IH.$tstamp" 		
	
	Q05="db2 -v \"SELECT * FROM TABLE ( MON_GET_LATCH(CLOB('<latch_status>W</latch_status>'), -2 ) ) ORDER BY LATCH_NAME, LATCH_STATUS\"  > $OUTDIR/get_latch_wait.txt.$IH.$tstamp" 		
	Q06="db2 -v \"SELECT * FROM sysibmadm.mon_current_sql ORDER BY ELAPSED_TIME_SEC desc\"  > $OUTDIR/mon_get_sql.txt.$IH.$tstamp" 		
	Q07="db2 -v \"select EXECUTABLE_ID,TOTAL_CPU_TIME/NUM_EXEC_WITH_METRICS AS AVG_CPU,TOTAL_CPU_TIME,COORD_STMT_EXEC_TIME/NUM_EXEC_WITH_METRICS AS AVG_ELAP,COORD_STMT_EXEC_TIME,NUM_EXEC_WITH_METRICS, STMT_TEXT from table(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2)) where NUM_EXEC_WITH_METRICS <> 0 order by COORD_STMT_EXEC_TIME/NUM_EXEC_WITH_METRICS desc fetch first 10 rows only\"  > $OUTDIR/elap_top_package_cache.txt.$IH.$tstamp" 		
	Q08="db2 -v \"select EXECUTABLE_ID, substr(stmt_text,1,500) as stmt_text, decimal(float(total_extended_latch_wait_time)/num_executions,10,5) as avg_latch_time from table(mon_get_pkg_cache_stmt(null,null,null,null))  where num_executions > 0  order by avg_latch_time desc fetch first 10 rows only\"  > $OUTDIR/mon_get_pkg_cache_stmt_Avglatch.txt.$IH.$tstamp" 		
	
	Q09="db2 -v \"select * from SYSIBMADM.MON_BP_UTILIZATION ORDER BY 1,2\"  > $OUTDIR/MON_BP_UTILIZATION.txt.$IH.$tstamp" 
	Q10="db2 -v \"select * from SYSIBMADM.MON_TRANSACTION_LOG_UTILIZATION ORDER BY 1 DESC \"  > $OUTDIR/MON_TRANSACTION_LOG_UTILIZATION.txt.$IH.$tstamp" 
	Q11="db2 -v \"select * from sysibmadm.MON_WORKLOAD_SUMMARY ORDER BY 1 \"  > $OUTDIR/MON_WORKLOAD_SUMMARY.txt.$IH.$tstamp" 
	Q12="db2 -v \"select * from sysibmadm.MON_SERVICE_SUBCLASS_SUMMARY  ORDER BY 1 \"  > $OUTDIR/MON_SERVICE_SUBCLASS_SUMMARY.txt.$IH.$tstamp" 
	Q13="db2 -v \"select * from sysibmadm.MON_DB_SUMMARY \"  > $OUTDIR/MON_DB_SUMMARY.txt.$IH.$tstamp" 
	Q14="db2 -v \"select * from sysibmadm.MON_CURRENT_UOW   ORDER BY ELAPSED_TIME_SEC DESC \"  > $OUTDIR/MON_CURRENT_UOW.txt.$IH.$tstamp" 
	Q15="db2 -v \"select * from sysibmadm.MON_PKG_CACHE_SUMMARY ORDER BY AVG_STMT_EXEC_TIME DESC FETCH FIRST 10 rows only \"  > $OUTDIR/MON_PKG_CACHE_SUMMARY.txt.$IH.$tstamp" 
	Q16="db2 -v \"select * from sysibmadm.MON_CONNECTION_SUMMARY ORDER BY RQST_WAIT_TIME_PERCENT DESC \"  > $OUTDIR/MON_CONNECTION_SUMMARY.txt.$IH.$tstamp" 
	Q17="db2 -v \"select * from SYSIBMADM.MON_TBSP_UTILIZATION ORDER BY 1,2 \"  > $OUTDIR/MON_TBSP_UTILIZATION.txt.$IH.$tstamp" 

	ParallelSSH "db2 connect to $DBNAME; $Q01 ; $Q02 ; $Q03 ; $Q04 ; $Q05 ; $Q06 ; $Q07 ; $Q08 ; $Q09 ; $Q10 ; db2 terminate " "$OUTDIR/CommonAllQueries1.txt.$IH.$tstamp" "$ISROOT" "1" "DB2" "&"
	ParallelSSH "db2 connect to $DBNAME; $Q11 ; $Q12 ; $Q13 ; $Q14 ; $Q15 ; $Q16 ; $Q17 ; db2 terminate " "$OUTDIR/CommonAllQueries2.txt.$IH.$tstamp" "$ISROOT" "1" "DB2" "&"			
	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -applications " "$OUTDIR/db2pd_applications.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" 			
	
	backapphdl=$( cat "$OUTDIR/db2pd_applications.txt.$IH.$tstamp" | grep -w PerformingBackup | awk '{printf("%s\t%s\t%s\n", $2, $3, $5) }' | sort | uniq | head -1 )
	BACKUPAPPHDL=$(echo $backapphdl | awk '{print $1}')
	
	if [[ ! -z $BACKUPAPPHDL ]]; then 

		log "[DB2PD data]: Collecting barstats info - Round $IH of $HROUNDS"
		echo "`date`: [DB2PD data]: Collecting barstats info - Round $IH of $HROUNDS"			
		
		ParallelSSH "db2 -x connect to $DBNAME; db2 -x \"select 'db2pd -db $DBNAME -dbp '||DBPARTITIONNUM||' -barstats '||AGENT_TID from (select APPLICATION_HANDLE, DBPARTITIONNUM,  AGENT_TID, AGENT_TYPE, ROW_NUMBER() OVER (PARTITION BY APPLICATION_HANDLE,DBPARTITIONNUM ORDER BY APPLICATION_HANDLE,DBPARTITIONNUM) rownumber from TABLE (MON_GET_AGENT (NULL,NULL,$BACKUPAPPHDL ,-2)) $LocalBarstats ) where ROWNUMBER = 1 \" ; db2 -x terminate " "$OUTDIR/barstatcmd.$IH.txt.$tstamp" "$ISROOT" "1" "DB2"						
	
		cat $OUTDIR/barstatcmd.$IH.txt.$tstamp | sed -n '/ Local database alias   = /,/DB20000I  The TERMINATE command completed/{//!p;}' | awk NF | egrep -v '^\+|SQLSTATE|^SQL' | while read rec
		do				
			bkmember=$( echo $rec | awk '{print $5'} )				
			bkedu=$( echo $rec | awk '{print $7'} )
			ParallelSSH " db2pd -db $DBNAME -dbp $bkmember -barstats $bkedu " "$OUTDIR/db2pd_barstats.$bkmember.$bkedu.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD"
		done
	
	fi
	#RefreshRunningpids  "$TMPFILE"
}
#########################################################################################################
#Function: CollectHangAPPONCE
#Purpose : Collect common data ONCE for HangApp option.
#########################################################################################################
function CollectHangAPPONCE ()
{
	if [ "x$DEBUG" == "x1" ]; then
	   set -xv 
	fi
	
	DBNAME="$1"
	OUTDIR="$2"
	HROUNDS="$3"
	tstamp="$4"
	HHREORGCHK_SET="$5"
	
	log "[MON data]: Start Db2mon.sh with 60 seconds ONLY ONCE"
	echo "`date`: [MON data]: Start Db2mon.sh with 60 seconds ONLY ONCE"

	ParallelSSH "$DB2INSTDIR/sqllib/samples/perf/db2mon.sh $DBNAME 60 > $OUTDIR/db2mon.txt.$HROUNDS.$tstamp" "$OUTDIR/db2mon.sh.$HROUNDS.$tstamp" "$ISROOT" "1" "DB2"
	Collect_exfmt_db2mon "$DBNAME" "$OUTDIR" "db2mon.txt" "$HROUNDS.$tstamp"	

	log "[MON data]: Finished Db2mon.sh with 60 seconds"
	echo "`date`: [MON data]: Finished Db2mon.sh with 60 seconds"
	
	log "[DB2PD data]: Collecting some db2pd info ONLY ONCE"
	echo "`date`: [DB2PD data]: Collecting some db2pd info ONLY ONCE"
	
	ParallelSSH "cp /usr/include/asm/unistd_64.h $OUTDIR/unistd_64.h.$HROUNDS.$tstamp" "$OUTDIR/cpunistd_64.$HROUNDS.$tstamp" "$ISROOT" "1" "OS"
	ParallelSSH "hostname; uptime; lscpu" "$OUTDIR/lscpu.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "OS"
	ParallelSSH "hostname; uptime; ls -lrt /dev/mapper" "$OUTDIR/devMapper.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "OS"
	ParallelSSH "hostname; uptime; lsblk " "$OUTDIR/lsblk.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "OS"		
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -dynamic" "$OUTDIR/db2pd_dynamic.txt.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -workload" "$OUTDIR/db2pd_workload.txt.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"				
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -workactionsets" "$OUTDIR/db2pd_workactionsets.txt.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -workclasssets" "$OUTDIR/db2pd_workclasssets.txt.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -thresholds" "$OUTDIR/db2pd_thresholds.txt.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"			
	ParallelSSH "db2pd $Db2pdMemAll -eve" "$OUTDIR/db2pd_eve.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"		
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -static" "$OUTDIR/db2pd_static.txt.$HROUNDS.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	
	if [[ $HHREORGCHK_SET -eq "1" ]]; then
		
		log "[MON data]: Start Reorgchk ONLY ONCE"
		echo "`date`: [MON data]: Start Reorgchk ONLY ONCE"
		QR01="db2 +c \"call REORGCHK_TB_STATS('T','ALL')\" ; db2 +c \"select table_schema, table_name,DATAPARTITIONNAME,card,overflow,  f1,  f2,  f3,  reorg  from SESSION.TB_STATS where REORG LIKE '%*%'\"  > $OUTDIR/REORGCHKTB.txt.$HROUNDS.$tstamp"
		QR02="db2 +c \"call REORGCHK_IX_STATS('T','ALL')\" ; db2 +c \"SELECT TABLE_SCHEMA,TABLE_NAME,INDEX_SCHEMA,INDEX_NAME,DATAPARTITIONNAME,INDCARD,F4,F5,F6,F7,F8,REORG FROM SESSION.IX_STATS  WHERE REORG LIKE '%*%'\"  > $OUTDIR/REORGCHKIX.txt.$HROUNDS.$tstamp"
		QR03="db2 -v \"select TABSCHEMA,TABNAME,CREATE_TIME,ALTER_TIME,INVALIDATE_TIME,STATS_TIME,COLCOUNT,TABLEID,TBSPACEID,CARD,NPAGES,MPAGES,FPAGES,OVERFLOW,LASTUSED,TABLEORG from syscat.tables WHERE TABSCHEMA NOT LIKE 'SYS%' AND TYPE = 'T' order by STATS_TIME,TABSCHEMA,TABNAME \" > $OUTDIR/SYSCATTABLES.txt.$HROUNDS.$tstamp"  
	    ParallelSSH "db2 connect to $DBNAME; $QR01 ;  $QR02 ;  $QR03 ;  db2 terminate " "$OUTDIR/ReorgQueries.txt.$HROUNDS.$tstamp" "$ISROOT" "1" "DB2"
		log "[MON data]: Finish Reorgchk ONLY ONCE"
		echo "`date`: [MON data]: Finish Reorgchk ONLY ONCE"
	fi
}
#########################################################################################################
#Function: CollectHADR_DB2TRC
#Purpose : Collect common data db2trc Functions for HADR option.
#########################################################################################################
function CollectHADR_DB2TRC()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi
	
	OUTDIR="$1"
	IH="$2"
	tstamp="$3"
	HROUNDS="$4"
	traceList="$5"
	eduList="$6"
	
	SIG=""
	SLEEPTIME="5"
	suffix=$( echo "$IH.$tstamp" )
	
	if [ "x$PLAT" = "xAIX" ]; then
		SIG="-60"
	else
		SIG="-27"
	fi
	
	TRACEDIR=$( echo "$OUTDIR/DB2TRCData" )
   	CreateDIR "$TRACEDIR"

	log "[DB2TRC data]: Start Collecting ( round $IH of $HROUNDS )"
	echo "`date`: [DB2TRC data]: Start Collecting ( round $IH of $HROUNDS )"
	
	if [[ "$traceList" == "-1" ]] ; then 
		
		log "[DB2TRC data]: traceList is not defined. Running normal trace."
		ParallelSSH "db2trc on -l 512m -t $Db2trcMemAll" "$TRACEDIR/db2_traceON.$suffix" "$ISROOT" "1" "DB2"  
		
	else
		log "[DB2TRC data]: Turning on Trace for list: $traceList"
		ParallelSSH "db2trc on -l 512m -t -p $traceList $Db2trcMemAll" "$TRACEDIR/db2_traceON.$suffix" "$ISROOT" "1" "DB2"  
	fi
	cat $TRACEDIR/db2_traceON.$suffix >> $LOGFILE 2>&1
	
	ParallelSSH "db2trc info $Db2trcMemAll" "$TRACEDIR/db2_traceinfo.$suffix" "$ISROOT" "1" "DB2"  
	cat $TRACEDIR/db2_traceinfo.$suffix >> $LOGFILE 2>&1
	
	for XeduList in `echo $eduList`; 
	do 
			log "[DB2TRC data]: Running: kill $SIG $XeduList"
			ParallelSSH "uptime; hostname; kill $SIG $XeduList" "$OUTDIR/kill.$SIG.$XeduList.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	done    
	
	CNT=3
	log "[DB2TRC data]: Dumping Db2trc every $SLEEPTIME seconds $CNT Times ( round $IH of $HROUNDS )"
	while [ $CNT -gt 0 ]; 
	do 		
		log "[DB2TRC data]: Sleeping for $SLEEPTIME seconds before dumping the trace count: $CNT ( round $IH of $HROUNDS )"
		sleep $SLEEPTIME	
		
		log "[DB2TRC data]: Dumping Db2trc Time: $CNT ( round $IH of $HROUNDS )"
		ParallelSSH "db2trc dmp trc.$CNT.$suffix.dmp -sdir $TRACEDIR $Db2trcMemAll" "$TRACEDIR/db2_tracedmp.$CNT.$suffix" "$ISROOT" "1" "DB2"
		cat $TRACEDIR/db2_tracedmp.$CNT.$suffix >> $LOGFILE 2>&1
		
		CNT=$(($CNT-1))
		
	done
	log "[DB2TRC data]: Stopping Db2trc ( round $IH of $HROUNDS )"
	ParallelSSH "db2trc stop $Db2trcMemAll" "$TRACEDIR/db2_traceStop.$suffix" "$ISROOT" "1" "DB2"
	cat $TRACEDIR/db2_traceStop.$suffix >> $LOGFILE	2>&1
	
	log "[DB2TRC data]: Dumping final Db2trc Time: $CNT ( round $IH of $HROUNDS )"
	ParallelSSH "db2trc dmp trc.$CNT.$suffix.dmp -sdir $TRACEDIR $Db2trcMemAll" "$TRACEDIR/db2_tracedmp.$CNT.$suffix" "$ISROOT" "1" "DB2"
	cat $TRACEDIR/db2_tracedmp.$CNT.$suffix >> $LOGFILE	2>&1 
	
	log "[DB2TRC data]: Turn off ( round $IH of $HROUNDS )"
	ParallelSSH "db2trc off $Db2trcMemAll" "$TRACEDIR/db2_traceOff.$suffix" "$ISROOT" "1" "DB2"
	cat $TRACEDIR/db2_traceOff.$suffix >> $LOGFILE 2>&1		

	log "[DB2TRC data]: Formatting DB2TRC files ( round $IH of $HROUNDS )"
	echo "`date`: [DB2TRC Data]: Formatting DB2TRC files ( round $IH of $HROUNDS )"	
  	    
	for files in `ls $TRACEDIR/trc.*.$suffix.dmp_*`
	do
		  log "[DB2TRC data]: Formatting file: $files ( round $IH of $HROUNDS )"
		  fname=$(basename "$files")
		  fdirname=$(dirname $(absPath "$files"))
		  ParallelSSH "db2trc flw -t $files $fdirname/flw.$fname ; db2trc fmt $files $fdirname/fmt.$fname ; db2trc flw -t -data $files $fdirname/flw_data.$fname ; db2trc perfrep -rds -g -sort timeelapsed $files $fdirname/perfrep.$fname " "$TRACEDIR/db2_traceFormat.$fname" "$ISROOT" "1" "DB2"		  
		  cat $TRACEDIR/db2_traceFormat.$fname >> $LOGFILE 2>&1
	done		
		  
	log "[DB2TRC data]: Finish Collecting ( round $IH of $HROUNDS )"
	echo "`date`: [DB2TRC data]: Finish Collecting ( round $IH of $HROUNDS )"		  
	
	#RefreshRunningpids "$TMPFILE"
}
#########################################################################################################
#Function: CollectHADR_DB2PD
#Purpose : Collect common data db2pd Functions for HADR option.
#########################################################################################################
function CollectHADR_DB2PD()
{
    if [ "x$DEBUG" = "x1" ]; then
        set -xv
    fi

    DBNAME="$1"
	OUTDIR="$2"
	IH="$3"
	tstamp="$4"
	HROUNDS="$5"
	traceList=""
	eduList=""
	suffix=$( echo "$IH.$tstamp" )
	
	STACKDIR=$( echo "$OUTDIR/stacks" )
   	CreateDIR "$STACKDIR"
	
	DB2PDOUTDIR=$( echo "$OUTDIR/DB2PD_Data" )
   	CreateDIR "$DB2PDOUTDIR"

	log "[DB2PD data]: Start Collecting ( round $IH of $HROUNDS )"
	echo "`date`: [DB2PD data]: Start Collecting ( round $IH of $HROUNDS )"
	
	log "[db2pd data]: Calling ihadr, dpsdbcb, dpsprcb ( round - $IH )"								
	Collect_db2pd_WLM_SORT "$DBNAME" "$DB2PDOUTDIR" "$suffix" "$SERVICEPASSWORD" &
	childpidWLM=$( echo $! )
	echo $childpidWLM >> $TMPFILE	
	echo "Collect_db2pd_WLM_SORT PID: $childpidWLM" >> $PROCESSFILE 2>&1
	[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "Collect_db2pd_WLM_SORT PID: $childpidWLM"
	
    ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -stack all dumpdir=$STACKDIR -rep 30 2 " "$DB2PDOUTDIR/db2pd_stackall.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -hadr -rep 2 100" "$DB2PDOUTDIR/db2pd_hadr.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -latches -rep 1 100" "$DB2PDOUTDIR/db2pd_latches.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	        		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -edus interval=5 top=50" "$DB2PDOUTDIR/db2pd_TopEdu.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	        	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -active -apinfo all -rep 2 40" "$DB2PDOUTDIR/db2pd_ActiveAPinfo.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	        	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -appl -tran -log -rep 2 30" "$DB2PDOUTDIR/db2pd_Appl_Tran_log.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	        	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -age -rep 2 50" "$DB2PDOUTDIR/db2pd_Agents.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	        	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -wlocks detail -locks wait showlocks -rep 1 100" "$DB2PDOUTDIR/db2pd_wlocks_showlocks.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        		  
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -edu" "$DB2PDOUTDIR/db2pd_edu.$suffix" "$ISROOT" "$NUMHOSTS" "DB2PD" 

	if [ "x$PLAT" = "xLinux" ]; then
		traceList=`egrep "db2sysc PID:|db2hadrp|db2loggw|db2loggr|db2hadrs|db2loggw|db2shred|db2redow|db2redom" $DB2PDOUTDIR/db2pd_edu.$suffix | awk '{ if( index($0, "db2sysc")){ db2syscPid = $NF; next;} if( ! first ) { pidTraceList = db2syscPid"."$2; first=1; } else{ if( index($0, "db2redow")){ ctr++; if( ctr > 7 ) next; }  pidTraceList = pidTraceList","db2syscPid"."$2;} }END{ print pidTraceList; }' | awk '{$1=$1;print}'`
	else
		traceList=`egrep "db2sysc PID:|db2hadrp|db2loggw|db2loggr|db2hadrs|db2loggw|db2shred|db2redow|db2redom" $DB2PDOUTDIR/db2pd_edu.$suffix | awk '{ if( index($0, "db2sysc")){ db2syscPid = $NF; next;} if( ! first ) { pidTraceList = db2syscPid"."$1; first=1; } else{ if( index($0, "db2redow")){ ctr++; if( ctr > 7 ) next; }  pidTraceList = pidTraceList","db2syscPid"."$1;} }END{ print pidTraceList; }' | awk '{$1=$1;print}' `
	fi
	
	eduList=`egrep "db2sysc PID:" $DB2PDOUTDIR/db2pd_edu.$suffix | awk '{ print $NF; }' | tr '\n' ' ' | awk '{$1=$1;print}' `

	log "[DB2PD data]: eduList: $eduList"
	log "[DB2PD data]: traceList: $traceList"
	
	if [[ -z "$eduList" ]]; then
		log "[DB2PD data]: eduList is empty. Setting to 0"
		eduList="0"
	fi
	
	if [[ -z "$traceList" ]]; then
		log "[DB2PD data]: traceList is empty. Setting to -1"
		traceList="-1"
	fi
	
	log "[DB2PD data]: eduList: $eduList"
	log "[DB2PD data]: traceList: $traceList"	
	
	if [ "x$PLAT" = "xLinux" ]; then
		for XeduList in `echo $eduList`; 
		do 
			log "[DB2PD data]: Running: lsof -p $XeduList"
			ParallelSSH "lsof -p $XeduList" "$OUTDIR/lsof.$XeduList.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
		done
	fi	
	
	log "[DB2TRC data]: Calling ( round $IH of $HROUNDS )"
	CollectHADR_DB2TRC "$OUTDIR" "$IH" "$tstamp" "$HROUNDS" "$traceList" "$eduList" &
	childpidHADRDB2TRC=$( echo $! )
	echo $childpidHADRDB2TRC >> $TMPFILE	
	echo "CollectHADR_DB2TRC PID: $childpidHADRDB2TRC" >> $PROCESSFILE 2>&1
	[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "CollectHADR_DB2TRC PID: $childpidHADRDB2TRC"		
		  
	log "[DB2PD data]: Finish Collecting ( round $IH of $HROUNDS )"
	echo "`date`: [DB2PD data]: Finish Collecting ( round $IH of $HROUNDS )"		  
	
	#RefreshRunningpids "$TMPFILE"
}
#########################################################################################################
#Function: CollectHADR_OS
#Purpose : Collect common data OS Functions for HADR option.
#########################################################################################################
function CollectHADR_OS ()
{
	if [ "x$DEBUG" == "x1" ]; then
	   set -xv 
	fi
	
	OUTDIR="$1"
	IH="$2"
	tstamp="$3"
	HROUNDS="$4"
	suffix=$( echo "$IH.$tstamp" )
	
	log "[OS data]: Start Collecting ( round $IH of $HROUNDS )"
	echo "`date`: [OS data]: Start Collecting ( round $IH of $HROUNDS )"
	
	ParallelSSH "hostname; uptime; echo; cat /proc/meminfo" "$OUTDIR/meminfo.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -eTo state,stat,pid,ppid,tid,sz,lstart,wchan:40,pri,policy,psr,sgi_p,time,command" "$OUTDIR/psETO.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -L -o f,s,state,user,pid,ppid,tid,lwp,c,nlwp,pri,ni,addr,vsz,rss,sz,stime,tty,time,pcpu,pmem,cmd,wchan:40" "$OUTDIR/ps.LP.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -elfL" "$OUTDIR/ps.elfL.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -elf" "$OUTDIR/ps.elf.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; mpstat -A 1 10" "$OUTDIR/mpstat.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	

	if [ "x$PLAT" = "xAIX" ]; then
		ParallelSSH "uptime; vmstat -w -t 5 20" "$OUTDIR/vmstat.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
		ParallelSSH "uptime; iostat -RDTVl 5 20" "$OUTDIR/iostat.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	else
		ParallelSSH "uptime; vmstat -t 5 20" "$OUTDIR/vmstat.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
		ParallelSSH "uptime; iostat -xkdtc 2 60" "$OUTDIR/iostat.allhosts.$suffix" "$ISROOT" "$NUMHOSTS" "OS" "&"
	fi
	
	if [[ $ISROOT -eq "1" ]]; then
	
		log "[OS data]: Start Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
		echo "`date`: [OS data]: Start Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
	
		KERNELSTACKDIR=$( echo $OUTDIR/kernel_stacks )
		CreateDIR "$KERNELSTACKDIR"
		chmod -R 777 $OUTDIR
		chmod -R 777 $KERNELSTACKDIR
	
		CollectKernelStacksData "$KERNELSTACKDIR" "$IH" "$tstamp" "$HROUNDS"
		
		log "[OS data]: Finished Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
		echo "`date`: [OS data]: Finished Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
		
	fi
	
	log "[OS data]: Finish Collecting ( round $IH of $HROUNDS )"
	echo "`date`: [OS data]: Finish Collecting ( round $IH of $HROUNDS )"

	#RefreshRunningpids  "$TMPFILE"
}
#########################################################################################################
#Function: CollectHangAPPCommonOS
#Purpose : Collect common data OS Functions for HangApp option.
#########################################################################################################
function CollectHangAPPCommonOS ()
{
	if [ "x$DEBUG" == "x1" ]; then
	   set -xv 
	fi
	
	OUTDIR="$1"
	IH="$2"
	tstamp="$3"
	HROUNDS="$4"
	
	log "[OS data]: Collecting ( round $IH of $HROUNDS )"
	echo "`date`: [OS data]: Collecting ( round $IH of $HROUNDS )"
	
	ParallelSSH "hostname; uptime; echo; cat /proc/meminfo" "$OUTDIR/meminfo.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -eTo state,stat,pid,ppid,tid,sz,lstart,wchan:40,pri,policy,psr,sgi_p,time,command" "$OUTDIR/psETO.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -L -o f,s,state,user,pid,ppid,tid,lwp,c,nlwp,pri,ni,addr,vsz,rss,sz,stime,tty,time,pcpu,pmem,cmd,wchan:40" "$OUTDIR/ps.LP.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -elfL" "$OUTDIR/ps.elfL.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; ps -elf" "$OUTDIR/ps.elf.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"


	#RefreshRunningpids  "$TMPFILE"
	
	if [[ $ISROOT -eq "1" ]]; then
	
		log "[OS data]: Start Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
		echo "`date`: [OS data]: Start Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
		
		KERNELSTACKDIR=$( echo $OUTDIR/kernel_stacks )
		CreateDIR "$KERNELSTACKDIR"
		chmod -R 777 $OUTDIR
		chmod -R 777 $KERNELSTACKDIR
		
		CollectKernelStacksData "$KERNELSTACKDIR" "$IH" "$tstamp" "$HROUNDS"
		
		log "[OS data]: Finished Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
		echo "`date`: [OS data]: Finished Collecting - KERNELSTACKS ( round $IH of $HROUNDS )"
		
	fi
}
#########################################################################################################
#Function: CollectHangAPPCommon
#Purpose : Collect common data for HangApp option.
#########################################################################################################
function CollectHangAPPCommonCMD ()
{
	if [ "x$DEBUG" == "x1" ]; then
	   set -xv 
	fi
	
	DBNAME="$1"
	OUTDIR="$2"
	IH="$3"
	tstamp="$4"
	HHSTACKS_SET="$5"
	
	log "[OS data]: Getting vmstat output - Round $IH of $HROUNDS "
	echo "`date`: [OS data]: Getting vmstat IOSTAT output - Round $IH of $HROUNDS "
	
	ParallelSSH "hostname; uptime; vmstat -w -t  1 20" "$OUTDIR/vmstat.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"
	ParallelSSH "hostname; uptime; iostat -xtzk 1 20" "$OUTDIR/iostat.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"
	
	log  "[OS data]: Getting top output - Round $IH of $HROUNDS "
	echo  "`date`: [OS data]: Getting top output - Round $IH of $HROUNDS "
	ParallelSSH "hostname; uptime; top -b -d 3 -n 2" "$OUTDIR/top.allhosts.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "OS" "&"
	
	echo "`date`: [DB2PD data]: Collecting latches and wlocks output - Round - $IH  of $HROUNDS" 			
	log "[DB2PD data]: Collecting latches and wlocks output - Round - $IH  of $HROUNDS" 
	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -latches -rep 2 3" "$OUTDIR/db2pd_latches.$IH.$tstamp.txt" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"		
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -wlocks detail -locks wait showlocks -rep 2 3" "$OUTDIR/db2pd_wlocks.$IH.$tstamp.txt" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	
	log "[DB2PD data]: Collecting some global db2pd information - Round - $IH  of $HROUNDS" 			
	echo "`date`: [DB2PD data]: Collecting some global db2pd information - Round - $IH  of $HROUNDS"
	
	if [[ $HHSTACKS_SET -eq "1" ]]; then			
		log "[DB2PD data]: Collecting stack information - Round - $IH  of $HROUNDS"
		echo "`date`: [DB2PD data]: Collecting stack all information - Round - $IH  of $HROUNDS"
		ALLSTACKDIR=$( echo "$OUTDIR/allstacks" )
		CreateDIR "$ALLSTACKDIR"
		ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -stack all dumpdir=$ALLSTACKDIR -rep 30 2" "$OUTDIR/db2pd_stackall.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"				
    fi
	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -tcbstat all -rep 5 2" "$OUTDIR/db2pd_tcbstats.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -bufferpool -rep 5 2" "$OUTDIR/db2pd_bufferpool.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -locks wait showlocks -active -transactions -agents -applications -rep 5 2" "$OUTDIR/db2pd_locks_tran.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -edus interval=5 top=10" "$OUTDIR/db2pd_edus_top.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -storagegroups -storagepaths -tablespaces -rep 5 2" "$OUTDIR/db2pd_tablespaces.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	
	ParallelSSH "db2pd $Db2pdMemAll -fvp LAM1 LAM2 LAM3 -rep 5 2" "$OUTDIR/db2pd_fvp.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfinfo 129 perf  -d $DBNAME -rep 5 2" "$OUTDIR/db2pd_cfinfo_129.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfinfo 128 perf  -d $DBNAME -rep 5 2" "$OUTDIR/db2pd_cfinfo_128.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -hadr -rep 5 2" "$OUTDIR/db2pd_hadr.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -recovery -rep 5 2" "$OUTDIR/db2pd_recovery.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -cleaner -rep 2 3" "$OUTDIR/db2pd_cleaner.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -dirtypages summary -rep 2 3" "$OUTDIR/db2pd_dirtypages.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -load -rep 2 3" "$OUTDIR/db2pd_load.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -runstats  -rep 2 3" "$OUTDIR/db2pd_runstats.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -reorgs index -rep 2 3" "$OUTDIR/db2pd_reorg.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -util -rep 2 3" "$OUTDIR/db2pd_util.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -extent -rep 2 3" "$OUTDIR/db2pd_extent.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -gfw -rep 2 3" "$OUTDIR/db2pd_gfw.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"        
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -edus -agents -rep 2 3" "$OUTDIR/db2pd_edus_agents.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -dbptnmem -memset -mempool subpool -inst -rep 2 3" "$OUTDIR/db2pd_mem.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -active -apinfo -applications -rep 2 3" "$OUTDIR/db2pd_active_apinfo_appl.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -catalogcache" "$OUTDIR/db2pd_catalogcache.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"		
	ParallelSSH "db2pd $Db2pdMemAll -fmp -rep 2 3" "$OUTDIR/db2pd_FMP.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
				
	ParallelSSH "db2pd $Db2pdMemAll -memblocks fmp" "$OUTDIR/db2pd_memblocksFMP.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -fmpexechistory n=512 genquery" "$OUTDIR/db2pd_FMPEXECHIST.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -memblocks all top" "$OUTDIR/db2pd_memblocks.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfpool -db $DBNAME" "$OUTDIR/db2pd_cfpool.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd -cfinfo  gbp sca list lock gcl -d $DBNAME " "$OUTDIR/db2pd_cfinfo_ext.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -rtsqueue" "$OUTDIR/db2pd_rtsqueue.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -authenticationcache" "$OUTDIR/db2pd_authenticationcache.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -temptable" "$OUTDIR/db2pd_temptable.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -osinfo" "$OUTDIR/db2pd_osinfo.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -iperiodic" "$OUTDIR/db2pd_iperiodic.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -ha" "$OUTDIR/db2pd_ha.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -logs" "$OUTDIR/db2pd_logs.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"								
	ParallelSSH "db2pd $Db2pdMemAll -db $DBNAME -serviceclasses" "$OUTDIR/db2pd_serviceclasses.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
	
	log "[DB2PD data]: Collecting Flight Recorder Trace data - Round - $IH  of $HROUNDS"
	echo "`date`: [DB2PD data]: Collecting Flight Recorder Trace data - Round - $IH  of $HROUNDS"
	
	FRDIR=$( echo "$OUTDIR/Flight_Recorder_Traces" )
	CreateDIR "$FRDIR"
	
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -dmpevrec comp=CDE_SERVICES dumpdir=$FRDIR -rep 2 3" "$OUTDIR/db2pd_FR_CDE.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"				
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -dmpevrec comp=SQLRL dumpdir=$FRDIR -rep 2 3" "$OUTDIR/db2pd_FR_SQLRL.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"		
	ParallelSSH "db2pd $Db2pdMemAll -d $DBNAME -dmpevrec comp=SQLRW dumpdir=$FRDIR -rep 2 3" "$OUTDIR/db2pd_FR_SQLRW.txt.$IH.$tstamp" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"				

}
#########################################################################################################
#Function: CheckArguments
#Purpose : Checking input arguments for validity
#########################################################################################################

function CheckArguments ()
{

	if [[ "x$TYPECOLLECT" = "x" && "x$QUICKHADR" = "x" && "x$QUICKWATCH" = "x" && "x$QUICKWLM" = "x" && "x$QUICKSESSIONS" = "x" && "x$QUICKEXPLAIN" = "x" && "x$QUICKTABLESPACES" = "x" && "x$QUICKTRANSACTIONS" = "x"  && "x$QUICKALL" = "x"  &&  "x$QUICKEXFMT" = "x" && "x$QUICKTRACE" = "x"  && "x$QUICKEXPLAINAPP" = "x" && "x$HANGTYPECOLLECT" = "x" && "x$QUICKHANGAPP" = "x" ]]; then
	   printf '\n%s\n\n' "Must use either -perf or -hang or any one of ( -watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -hangapp, -tablespaces, -transaction, -all ) options"
	   exit 0
	fi

	if [[ "x$TYPECOLLECT" != "x" ]] && [[ "x$QUICKWATCH" != "x" || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$HANGTYPECOLLECT" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
	   printf '\n%s\n\n' "-perf and other options such as -hang, -watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -hangapp, -tablespaces, -transaction, -all  are mutually exclusive. Cannot have both set"
	   exit 0
	fi 

	if [[ "x$PERF_NOTRC" = "x1" ]]; then
	  if [[ "x$HANGTYPECOLLECT" != "x2" && "x$TYPECOLLECT" != "x2" ]] || [[ "x$QUICKWATCH" != "x" || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
			printf '\n%s\n\n' "-notrc can only be used with -perf or -hang full option"
			exit 0
	  fi
	fi

	if [[ "x$NOQ1" = "x0" || "x$NOQ2" = "x0" || "x$NOQ3" = "x0" || "x$NOQ4" = "x0" || "x$NOQ5" = "x0" ]]; then
	  if [[ "x$HANGTYPECOLLECT" != "x" && "x$TYPECOLLECT" != "x" ]] || [[ "x$QUICKWATCH" != "x" || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
			printf '\n%s\n\n' "-noq1, -noq2, -noq3, -noq4, -noq5 can only be used with -perf or -hang option"
			exit 0
	  fi
	fi

	if [[ "x$PERF_NODUMPALL" = "x1" ]]; then
	  if [[ "x$HANGTYPECOLLECT" != "x2" ]] || [[ "x$TYPECOLLECT" != "x" || "x$QUICKWATCH" != "x" || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
			printf '\n%s\n\n' "-nodumpall can only be used with -hang full option"
			exit 0
	  fi
	fi
	
	if [[ "x$LOCALHOST" = "x1" ]]; then
	  if [[ "x$HANGTYPECOLLECT" != "x" && "x$TYPECOLLECT" != "x" ]] || [[ "x$QUICKWATCH" != "x" || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" ]]; then
			printf '\n%s\n\n' "-localhost can only be used with -perf, -hang or -hangapp option"
			exit 0
	  fi
	fi	
	
	if [[ $ADDITIONALCMD_SET -eq "1" ]]; then
	  if [[ "x$HANGTYPECOLLECT" != "x" && "x$TYPECOLLECT" != "x" ]] || [[ "x$QUICKWATCH" != "x" || "x$QUICKWLM" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" ]]; then
			printf '\n%s\n\n' "-ADDITIONALCMD can only be used with -perf, -hang, -hadr or -hangapp option"
			exit 0
	  fi
	fi	

	if [[ "x$HANGTYPECOLLECT" != "x" ]] && [[ "x$QUICKWATCH" != "x" || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$TYPECOLLECT" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
	   printf '\n%s\n\n' "-hang and other options such as -perf, -watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -hangapp, -tablespaces, -transaction, -all are mutually exclusive. Cannot have both set"
	   exit 0
	fi 
	
	if [[ "x$QUICKWATCH" != "x" ]] && [[ "x$QUICKHADR" != "x"  || "x$QUICKWLM" != "x"  || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x"  || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKHADR" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKWLM" != "x"  || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x"  || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi
	
	if [[ "x$QUICKWLM" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKSESSIONS" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x"  || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKSESSIONS" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -hangqpp, -tablespaces, -transaction, -exfmt, -trace, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKEXPLAIN" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKSESSIONS" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -hangapp, -tablespaces, -transaction, -exfmt, -trace, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKEXPLAINAPP" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKSESSIONS" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAIN" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -hangapp, -all are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKHANGAPP" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKSESSIONS" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAIN" != "x" || "x$QUICKEXPLAINAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -hangapp, -all are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKTABLESPACES" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKSESSIONS" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -hangapp, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKTRANSACTIONS" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKSESSIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -hangapp, -all are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKEXFMT" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKSESSIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -hangapp, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi

	if [[ "x$QUICKTRACE" != "x" ]] && [[ "x$QUICKWATCH" != "x"  || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKSESSIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
		printf '\n%s\n\n' "-watchquery, -hadr, -wlm, -sessions, -explain, -explapp, -tablespaces, -transaction, -exfmt, -trace, -hangapp, -all  are mutually exclusive. Can only choose one of them"
		exit 0
	fi
	if [[ "x$QUICKALL" != "x" ]] && [[ $ISROOT == 1 ]] ; then
        printf '\n%s\n' "-all option cannot be executed as ROOT user."
        exit 0
    fi
	if [[ "x$QUICKEXPLAIN" != "x" ]] && [[ $ISROOT == 1 ]] ; then
        printf '\n%s\n' "-explain option cannot be executed as ROOT user."
        exit 0
    fi
	if [[ "x$QUICKEXPLAIN" != "x" ]] && [[ $ISROOT == 1 ]] ; then
        printf '\n%s\n' "-explapp|-explainapp option cannot be executed as ROOT user."
        exit 0
    fi
	if [[ "x$QUICKEXFMT" != "x" ]] && [[ $ISROOT == 1 ]] ; then
        printf '\n%s\n' "-exfmt option cannot be executed as ROOT user."
        exit 0
    fi	
	if [[ "x$QUICKTRACE" != "x" ]] && [[ $ISROOT == 1 ]] ; then
        printf '\n%s\n' "-trace option cannot be executed as ROOT user."
        exit 0
    fi	

	if [[ "x$QUICKWATCH" != "x" ]] && [[ $ISROOT == 1 ]] ; then
        printf '\n%s\n' "-trace option cannot be executed as ROOT user."
        exit 0
    fi		
	
	if [[ "x$KERNELSTACK" = "x1" ]]; then
	
		if  [[ $ISROOT == 0 ]] ; then
			printf '\n%s\n' "-kernelstack option can only be executed as ROOT user."
			exit 0
		fi
		if [[ "x$TYPECOLLECT" != "x" || "x$QUICKTRACE" != "x" || "x$QUICKWATCH" != "x" || "x$QUICKHADR" != "x" || "x$QUICKWLM" != "x"  || "x$QUICKEXPLAIN" != "x" || "x$QUICKTABLESPACES" != "x" || "x$QUICKSESSIONS" != "x" || "x$QUICKALL" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKTRANSACTIONS" != "x" || "x$QUICKEXPLAINAPP" != "x" || "x$QUICKHANGAPP" != "x" ]]; then
			printf '\n%s\n' "-kernelstack option can only be used with -hang option."
			exit 0
		fi
	fi

	if [[ $ecl1_SET -eq "1" && $ecl0_SET -eq "1" ]]; then
	
		printf '\n%s\n' "-cl0 and -cl1 are mutually exclusive!"
		exit 0
	fi	
}

#########################################################################################################
#Function: get_user_setInstance
#Purpose : To get user running this script and set the instance owner by default if its executed as root
#########################################################################################################
function get_user_setInstance ()
{
  if [ "x$DEBUG" == "x1" ]; then
         set -xv 
  fi
  
  if [[ "$ISROOT" == 1 ]]; then
  
    	if [[ -z "$DB2INSTANCEUSER" ]]; then	
			DB2INSTANCEUSER="db2inst1"
			printf '\n%s\n' "$(date): Setting default Db2 Instance user: $DB2INSTANCEUSER."
			log "Setting default Db2 Instance user: $DB2INSTANCEUSER."
	    fi

  else  ## NOT AS ROOT
  
    	if [[ -z "$DB2INSTANCEUSER" ]]; then
			DB2INSTANCEUSER=$RUN_USER
			printf '\n%s\n' "$(date): Setting Db2 Instance user: $DB2INSTANCEUSER."
			log "Setting Db2 Instance user: $DB2INSTANCEUSER."
	    fi    
  fi
 
  if [[ `id -u $DB2INSTANCEUSER 2>/dev/null || echo -1` -lt 0 ]]; then
  
      printf '\n\n%s\n' "Db2 Instance user: $DB2INSTANCEUSER does not exist. Please provide the correct instance name using -instance parameter if running the script as root or run the script as Db2 instance owner. Bailing out "
      log "Db2 Instance user: $DB2INSTANCEUSER does not exist. Please provide the correct instance name using -instance parameter if running the script as root or run the script as Db2 instance owner. Bailing out "
	  rm -rf $OUTDIR ; retchk "$?" "$LINENO" "rm -rf $OUTDIR" "$(hostname)" "Cannot delete folder  $OUTDIR" "N"
      usage   
      exit 0    
  
  fi
                                                                
  #printf '\n\n%s\n\n' "DB2 Instance User set to $DB2INSTANCEUSER . Checking SQLLIB existance."		
	
  DB2INSTDIR=$(eval echo ~$DB2INSTANCEUSER)
 
  if [[ ! -d "$DB2INSTDIR/sqllib" ]]; then
	
  	printf '\n\n%s\n\n' "Instance directory: $DB2INSTDIR/sqllib does not exist. Cannot continue"
  	log "Instance directory: $DB2INSTDIR/sqllib does not exist. Cannot continue"
    rm -rf $OUTDIR ; retchk "$?" "$LINENO" "rm -rf $OUTDIR" "$(hostname)" "Cannot delete folder  $OUTDIR" "N"	
  	exit 2
	
  else
  
     DB2PROFILE=$( echo $DB2INSTDIR/sqllib/db2profile )
     
    . $DB2PROFILE
    
    HOSTS=$( cat $DB2INSTDIR/sqllib/db2nodes.cfg 2>/dev/null | awk '{ print $2; }' | sort -u )
    
    NUMHOSTS=$( cat $DB2INSTDIR/sqllib/db2nodes.cfg 2>/dev/null | awk '{ print $2; }' | sort -u  | wc -l )    
      
  fi
  
  printf '\n%s\n' "$(date): Running the script as $RUN_USER and Instance profile is set to $DB2INSTANCEUSER and sqllib - $DB2INSTDIR. Press cntl+c to cancel the script if needed."
  printf '\n%s' "$(date): DB2 Instance has $NUMHOSTS hosts. Hostnames: "
  printf '\n%s' "$HOSTS"
  printf '\n%s' ""
  [[ "x$QUICKHADR" != "x" || "x$QUICKEXFMT" != "x" || "x$QUICKHANGAPP" != "x" || "x$TYPECOLLECT" = "x1" || "x$TYPECOLLECT" = "x2" || "x$HANGTYPECOLLECT" = "x1" || "x$HANGTYPECOLLECT" = "x2" ]] && printf '\n%s\n' "$(date): Timeout of individual process is $PTIMEOUT seconds"
  
  log "Running the script as $RUN_USER and Instance profile is set to $DB2INSTANCEUSER and sqllib - $DB2INSTDIR. Press cntl+c to cancel the script if needed."
  log "DB2 Instance has $NUMHOSTS hosts. Hostnames: "
  log "$HOSTS"
  log "Timeout of individual process is $PTIMEOUT seconds"
  
  if [[ $LOCALHOST -eq "1" ]]; then 
		
	if [[ $NUMHOSTS -gt "1" ]]; then	

		NUMHOSTS=1
		HOSTS=`hostname`
		printf '\n\n%s\n\n' "$(date): -localhost option is used, Data collection will be limited to $NUMHOSTS host: $HOSTS . "
		log "-localhost option is used, Data collection will be limited to $NUMHOSTS host: $HOSTS . "
		Db2trcMemAll=""
		Db2pdMemAll=" -alldbpartitionnums "
		LocalBarstats=" ,table(SYSPROC.DB_MEMBERS()) where  MEMBER = MEMBER_NUMBER and UPPER(HOST_NAME) = UPPER('"$(echo $HOSTS)"') "
		[[ "x$DEBUG" == "x1" ]] && printf '\n\n%s\n' "$(date): Setting Db2trcMemAll: $Db2trcMemAll & Db2pdMemAll: $Db2pdMemAll LocalBarstats: $LocalBarstats"
		log "Setting Db2trcMemAll: $Db2trcMemAll & Db2pdMemAll: $Db2pdMemAll LocalBarstats: $LocalBarstats"
		
	else
		printf '\n\n%s\n\n' "$(date): -localhost option is ignored as its a Single physical node cluster only."
		log "-localhost option is ignored as its a Single physical node cluster only."
	fi
  fi
	
  if [[ $NUMHOSTS -gt "1" ]]; then
	  rah="rah \"||"
	  quote="\""
  else
	  rah=""
	  quote=""
  fi
	
  sleep 2
 
  if [[ $ISROOT == 1 ]]; then
    
	DB2_PREFIX="sudo -i -u $DB2INSTANCEUSER bash "
    DB2_POSTFIX="EOF"
	
  else
    DB2_PREFIX="bash "
    DB2_POSTFIX="EOF"  
  fi
  
  [[ "x$DEBUG" == "x1" ]] && printf '\n\n%s\n' "$(date): Setting DB2_PREFIX: $DB2_PREFIX & DB2_POSTFIX: $DB2_POSTFIX"
  log "Setting DB2_PREFIX: $DB2_PREFIX & DB2_POSTFIX: $DB2_POSTFIX"
}

#########################################################################################################
#Function: absPath
#Purpose : To get absolute path of the script.
#########################################################################################################
function absPath()
{
 if [[ -d "$1" ]]; then
     cd "$1"
     echo "$(pwd -P)"
 else
     cd "$(dirname "$1")"
     echo "$(pwd -P)/$(basename "$1")"
 fi
}
#########################################################################################################
#Function: round10
#Purpose : To round number to 10.
#########################################################################################################
function round10() 
{
  echo $(( ((${1%.*}+5)/10)*10 ))
}


typeset -x RUN_USER=$( echo $USER )
typeset -x PLAT=$(uname -s)
typeset -x ISROOT=0
typeset -x CLEANUPCOUNT=0
typeset -x DB2INSTANCEUSER=""
typeset -x HOSTS=""
typeset -x NUMHOSTS="0"
typeset -x DB2PROFILE=""
typeset -x DB2_PREFIX="bash "
typeset -x DB2_POSTFIX="EOF"
typeset -x ISDPF=""
typeset -x CWD=""
typeset -x TTABLEORG=""
typeset -x TTIMEOUT="600"
typeset -x LOGFILE=""
typeset -x PROCESSFILE=""
typeset -x ttableorg_SET="0"
typeset -x ttimeout_SET="0"
typeset -x hangdb2trc_SET="0"
typeset -x hrounds_SET="0"
typeset -x HROUNDS="2"
typeset -x hangrounds_SET="0"
typeset -x HANGROUNDS="2"
typeset -x HHANGDB2TRC=""
typeset -x HHSTACKS="N"
typeset -x HHSTACKS_SET="0"
typeset -x HHREORGCHK="Y"
typeset -x HHREORGCHK_SET="1"
typeset -x tdb2batch_SET="0"
typeset -x tdb2evmon_SET="0"
typeset -x noconnect_SET="0"
typeset -x nodb2pd_SET="0"
typeset -x ecl1_SET="0"
typeset -x ecl0_SET="0"
typeset -x RTNC=""
typeset -x RLINE=""
typeset -x LOCALHOST=0
typeset -x Db2trcMemAll=" -member all "
typeset -x Db2pdMemAll=" -member all "
typeset -x LocalBarstats=""
typeset -x ADDITIONALCMD=""
typeset -x ADDITIONALCMD_SET=0
typeset -x SSTARTTIME=$(date +%s)

# SETTING ISROOT
if [[ "$RUN_USER" == "root" || $(id -u) -eq 0 ]]; then
	ISROOT=1
fi

SCRIPTDIR=$PWD
DBNAME=BLUDB
PERIOD=900
MAX=4
TYPECOLLECT=""
HANGTYPECOLLECT=""
QUICKWLM=""
QUICKHADR=""
QUICKWATCH=""
QUICKSESSIONS=""
QUICKEXPLAIN=""
QUICKEXPLAINAPP=""
QUICKHANGAPP=""
QUICKTABLESPACES=""
QUICKTRANSACTIONS=""
QUICKALL=""
STOPSCRIPT=""
QUICKEXFMT=""
QUICKTRACE=""
DATACOLLECTMODE=""
NORUN=0
DEBUG=0
VERBOSE=""
PIDDETAILS=""
KEEP=-1
OUTPUTDIR=""
OUTPUTFILE=""
KERNELSTACK=0
PERF_NOTRC=0
NOQ1=1
NOQ2=1
NOQ3=1
NOQ4=1
NOQ5=1
PERF_NODUMPALL=0
typeset -x HANG_DB2TRC=0
typeset -x PTIMEOUT=900
SERVICEPASSWORD=0
OKTORUN=0


read_arguments "$@"


if [ "x$DEBUG" = "x1" ]; then
   set -xv
fi

if [ "x$STOPSCRIPT" = "x1" ]; then

   if [[ -e "/tmp/.tmp.dbmonitorpid" ]] && [[ -s "/tmp/.tmp.dbmonitorpid" ]]; then

	  FILEUSER=$( ls -ld /tmp/.tmp.dbmonitorpid | awk '{print $3}' )
	  
	  if [[ "$FILEUSER" != "$RUN_USER" && $ISROOT -eq 0 ]]; then   
	  
		printf '\n\n%s\n' "$(date): Script `basename $0` is running as user: $FILEUSER"
		printf '\n\n%s\n\n' "$(date): You tried to kill as user: $RUN_USER which is not allowed. Only ROOT or $FILEUSER can stop the running script."
		exit 0
		
	  else 
	  
		  pidtokill=$( cat "/tmp/.tmp.dbmonitorpid" )	  
		  check=$( ps -e | grep -w $pidtokill | grep -v grep | wc -l )
		  
		  if [[ $check -gt 0  ]]; then
		  
			kill -TERM $pidtokill ; retchk "$?" "$LINENO" "kill -TERM $pidtokill" "$(hostname)" "Cannot kill -TERM $pidtokill" 
			printf '\n%s\n' "`date`: Sent kill to Parent Process: $pidtokill"
			printf '\n%s\n' "`date`: The Parent Process: $pidtokill might respond in sometime as it might be sleep function call which will respond to kill after sleep"
			# THIS SHOULD AUTOMATICALLY CALL CLEANUP FUNCTION
			exit 0
		  else
			cleanup
		  fi
	  fi
	  
   else
	  printf '\n\n%s\n' "$(date): Script `basename $0` is not running!"
	  exit 0
   fi
fi
	  
CheckArguments

if [ "x$QUICKEXPLAIN" = "x0" ]; then
   QUICKEXPLAIN=10
   printf '\n%s\n' "$(date): Going to explain queries running for more than 10 minutes"
fi

tstamp=$( date "+%Y-%m-%d-%H.%M.%S" )
DATACOLLECTDIR=$( echo "monitor_collect_$tstamp" )

if [ "x$OUTPUTDIR" = "x" ]; then
   
   CWD="/scratch/IBMData"
   OUTDIR=$CWD/$DATACOLLECTDIR
   
   if [[ ! -d "/scratch" ]]; then  # /scratch does not exist, then set to CWD
     CWD=`pwd`
     OUTDIR=$CWD/$DATACOLLECTDIR
   fi
   
else   # OUTDIR is provided by USER.

   CWD=$(absPath "$OUTPUTDIR")
   OUTDIR=$( echo "$CWD/$DATACOLLECTDIR" )
fi

if [ "x$OUTPUTFILE" = "x" ]; then
   OUTPUTFILE=$( echo "db_monitor.txt" )
fi

CreateDIR "$OUTDIR"

printf '\n%s\n' "`date`: Setting OUTDIR to $OUTDIR"

#### START

LOGFILE=$OUTDIR/db_monitor.log
PROCESSFILE=$OUTDIR/backgroundprocess.log
PROCESSFILECHILD=$OUTDIR/dependends.backgroundprocess.log
touch $LOGFILE ; retchk "$?" "$LINENO" "touch $LOGFILE" "$(hostname)" "Cannot write to file /tmp/.tmp.dbmonitorpid"
touch $PROCESSFILE ; retchk "$?" "$LINENO" "touch $PROCESSFILE" "$(hostname)" "Cannot write to file $PROCESSFILE"
touch "$PROCESSFILECHILD" ; retchk "$?" "$LINENO" "touch $PROCESSFILECHILD" "$(hostname)" "Cannot write to file $PROCESSFILECHILD"
chmod 777 $LOGFILE
chmod 777 $PROCESSFILE
chmod 777 "$PROCESSFILECHILD"

exec  1> >(tee -ia $LOGFILE)
exec  2> >(tee -ia $LOGFILE >& 2)
exec &> >(tee -i "$LOGFILE")

# Notice no leading $
exec {FD}> $LOGFILE

# If you want to append instead of wiping previous logs
#exec {FD}>> $2/bash.log
export BASH_XTRACEFD="$FD"


get_user_setInstance
CheckIfScriptAlreadyRunning

OKTORUN=$( get_version )

progpid=$( echo $$ )

echo $progpid > /tmp/.tmp.dbmonitorpid  ; retchk "$?" "$LINENO" "echo $progpid > /tmp/.tmp.dbmonitorpid" "$(hostname)" "Cannot write to file /tmp/.tmp.dbmonitorpid"

TMPFILE=/tmp/.dbmonitor.$progpid
touch $TMPFILE  ; retchk "$?" "$LINENO" "touch $TMPFILE" "$(hostname)" "Cannot create file $TMPFILE" 
chmod 777 $TMPFILE ; retchk "$?" "$LINENO" "chmod 777 $TMPFILE" "$(hostname)" "Cannot set 777 permission for file $TMPFILE" 

log "`basename $0` pid: $progpid"
printf '\n\n%s\n\n' "$(date -d @$SSTARTTIME): Version: $(md5sum $(basename $0)) pid: $progpid epoch: $SSTARTTIME "
echo "`date`: Command Arguments: $@"
printf '\n\n'

CheckifOUTDIRisWritableByAll
cp $(realpath "$0") $OUTDIR/script.txt 2>&1

####################################################
### MAIN START OF SCRIPT
####################################################   
if [[ "x$TYPECOLLECT" = "x1" || "x$TYPECOLLECT" = "x2" || "x$HANGTYPECOLLECT" = "x1" || "x$HANGTYPECOLLECT" = "x2" ]]; then

   if [ "x$MAX" = "x-1" ]; then
      MAX=9999999
   fi

   
   if [[ $MAX -eq 9999999 ]]; then

      if [ "x$KEEP" = "x-1" ]; then
         KEEP=$( echo "2*60" | bc )
      fi

      if [ "x$HANGTYPECOLLECT" = "x" ]; then
          printf '\n%s\n' "`date`: You have chosen to run the script indefinitely .. are you sure? You have 10 seconds to Ctrl+c out of it"
          sleep 10
          printf '\n%s\n' "`date`: Ok as you wish, now will run indefinitely, collecting data every $PERIOD seconds!!"
      else
		  #Silently disable MAX and KEEP for Hang data collection
		  printf '\n%s\n' "`date`: For Hang collection, MAX will be defaulted to 3 "
          MAX=3
          KEEP=""
      fi
   fi

   if [ "x$TYPECOLLECT" != "x" ]; then

      DATACOLLECTMODE="perf"

   elif [ "x$HANGTYPECOLLECT" != "x" ]; then
      
	  if [[ "x$KERNELSTACK" = "x1"  && $ISROOT -eq 0 ]]; then
            printf '\n%s\n\n' "!! Must run as user ROOT since you want to collect kernel stacks as well"
			cleanup
            exit 0
      fi

      DATACOLLECTMODE="hang"
      TYPECOLLECT=$HANGTYPECOLLECT

      if [[ "x$PERIOD" != "x" || "x$MAX" != "x" ]]; then
         log "Ignoring -period or -max option as it is not relevant for hang data collection" 
      fi
	  
   fi

   printf '\n%s\n' "`date`: You can follow the progress of the script by tailing $LOGFILE or use -verbose option to view the progress"
   printf '\n%s\n' "`date`: Starting db_monitor $DATACOLLECTMODE data collection"

   log "Starting db_monitor data collection. Incoming params: "
   log "Incoming params: DBNAME = $DBNAME, DATACOLLECTMODE = $DATACOLLECTMODE, DATACOLLECT_TYPE = $TYPECOLLECT ( 1 = Basic, 2 = Full ) "
   printf '\n%s\n' "$(date): Starting db_monitor data collection. Incoming params: "
   printf '\n%s\n' "$(date): Incoming params: DBNAME = $DBNAME, DATACOLLECTMODE = $DATACOLLECTMODE, DATACOLLECT_TYPE = $TYPECOLLECT ( 1 = Basic, 2 = Full ) "
   
   [[ $DATACOLLECTMODE = "perf" ]] && log "Incoming params: PERIOD = $PERIOD , ITERATIONS = $MAX, KEEP = $KEEP ( mins ) "
   [[ $DATACOLLECTMODE = "perf" ]] && printf '\n%s\n'  "$(date): Incoming params: PERIOD = $PERIOD , ITERATIONS = $MAX, KEEP = $KEEP ( mins ) "

   [[ $DATACOLLECTMODE = "hang" ]] && log "Incoming params: KERNELSTACK = $KERNELSTACK, HANGROUNDS = $HANGROUNDS, PERF_NODUMPALL = $PERF_NODUMPALL ( 1 = db2pd -stack all , 0 = db2pd -dump all )"
   [[ $DATACOLLECTMODE = "hang" ]] && printf '\n%s\n'  "$(date): Incoming params: KERNELSTACK = $KERNELSTACK, HANGROUNDS = $HANGROUNDS, PERF_NODUMPALL = $PERF_NODUMPALL ( 1 = db2pd -stack all , 0 = db2pd -dump all )"
      
   [[ $DATACOLLECTMODE = "hang" && $noconnect_SET -eq "1" ]] && printf '\n%s\n'  "$(date): Incoming params: noconnect_SET = $noconnect_SET - i.e. NO CONNECTION TO DATABASE "
   [[ $DATACOLLECTMODE = "hang" && $noconnect_SET -eq "1" ]] && log "Incoming params: noconnect_SET = $noconnect_SET - i.e. NO CONNECTION TO DATABASE "
   
   [[ $DATACOLLECTMODE = "hang" && $nodb2pd_SET -eq "1" ]] && printf '\n%s\n'  "$(date): Incoming params: nodb2pd_SET = $nodb2pd_SET - i.e. NO DB2PD COMMANDS "
   [[ $DATACOLLECTMODE = "hang" && $nodb2pd_SET -eq "1" ]] && log "Incoming params: nodb2pd_SET = $nodb2pd_SET - i.e. NO DB2PD COMMANDS "
   
   [[ $ADDITIONALCMD_SET -eq "1" ]] && printf '\n%s\n'  "$(date): Incoming params: ADDITIONALCMD_SET = $ADDITIONALCMD_SET (Additional Commands from File: $ADDITIONALCMD will be executed ) "
   [[ $ADDITIONALCMD_SET -eq "1" ]] && log  "Incoming params: ADDITIONALCMD_SET = $ADDITIONALCMD_SET (Additional Commands from File: $ADDITIONALCMD will be executed ) "

   log "Incoming params: KERNELSTACK = $KERNELSTACK, SERVICEPASSWORD = $SERVICEPASSWORD, PERF_NOTRC = $PERF_NOTRC ( 1 = NO_DB2TRACE )"
   log "Writing to dir: $OUTDIR"   
   printf '\n%s\n' "$(date): Incoming params: SERVICEPASSWORD = $SERVICEPASSWORD, PERF_NOTRC = $PERF_NOTRC ( 1 = NO_DB2TRACE Applicable only if DATACOLLECT_TYPE = 2 )"
   printf '\n%s\n' "$(date): Incoming params: NOQ1 = $NOQ1, NOQ2 = $NOQ2, NOQ3 = $NOQ3, NOQ4 = $NOQ4, NOQ5 = $NOQ5 ( 1 = Queries will Execute in collect_mon_data_PERF_HANG)"
   printf '\n%s\n' "$(date): Writing to dir: $OUTDIR"   
   
   if [[ "x$DATACOLLECTMODE" = "xperf" ]]; then
	   
	   CTR=1	
       while [ $CTR -le $MAX ]
       do
           log "[MAIN]: Started $CTR of $MAX iterations"
           printf '\n%s\n'  "`date`: [OS Data]: Started $CTR of $MAX iterations"

		   # FORMATTING COUNTER
           if [ $MAX -le 9999 ]; then
              ctr=$( echo $CTR | awk '{ printf("%04d", $0 ); }' )
           else
              ctr=$CTR
           fi

           TSTAMP=$( date "+%Y-%m-%d-%H.%M.%S" )
           suffix=$( echo "$TSTAMP.$ctr" )

		   perf_collect_os_data "$TYPECOLLECT" "$OUTDIR" "$suffix" "$CTR" "$PERIOD" &
		   childpidOS=$( echo $! )
		   echo $childpidOS >> $TMPFILE
		   echo "collect_os_data PID: $childpidOS" >> $PROCESSFILE 2>&1
		   [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_os_data PID: $childpidOS"
		   printf '\n%s\n' "`date`: [OS data]: Started collection as background $CTR of $MAX iterations"

			   
		   if [[ $nodb2pd_SET -eq "0" ]] ; then
			  perf_collect_db2pd_data "$DBNAME" "$PERIOD" "$TYPECOLLECT" "$OUTDIR" "$CTR" "$suffix" "$SERVICEPASSWORD" &
			  childpiddb2pd=$( echo $! )
			  echo $childpiddb2pd >> $TMPFILE	
			  echo "collect_db2pd_data PID: $childpiddb2pd" >> $PROCESSFILE 2>&1
			  [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2pd_data PID: $childpiddb2pd"
			  printf '\n%s\n' "`date`: [DB2PD data ]: Started collection as background $CTR of $MAX iterations"
		   fi

		   if [[ $noconnect_SET -eq "0" ]] ; then
			  perf_collect_mon_data "$DBNAME" "$TYPECOLLECT" "$OUTDIR" "$KEEP" "$CTR" "$suffix" "$OKTORUN" &
			  childpidmon=$( echo $! )
			  echo $childpidmon >> $TMPFILE
			  echo "collect_mon_data PID: $childpidmon" >> $PROCESSFILE 2>&1
			  [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_mon_data PID: $childpidmon"
			  printf '\n%s\n' "`date`: [MON data]: Started collection as background $CTR of $MAX iterations"
		   fi  
				
		   if [ "x$TYPECOLLECT" = "x2" -a "x$PERF_NOTRC" = "x0"  ]; then
		   
			  log "DB2_WORKLOAD:  $( db2set | grep DB2_WORKLOAD= ) "	  				  
			  checkifCDE=$( db2set | grep "DB2_WORKLOAD=" | awk '{ if( match($0,"ANALYTICS")) print 1; else print 0; } END { if (NR==0) print 0 ; else 1; } ' )	  	  
			  perf_collect_db2trc_data "$checkifCDE" "$PERIOD" "$OUTDIR" "$CTR" "$suffix" "$KEEP" &
			  childpidtrc=$( echo $! )
			  echo $childpidtrc >> $TMPFILE
			  echo "collect_db2trc_data PID: $childpidtrc" >> $PROCESSFILE 2>&1
			  [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2trc_data PID: $childpidtrc"
			  printf '\n%s\n' "`date`: [DB2TRC data]: Started collection as background $CTR of $MAX iterations"		
				 
		   fi
		   
           log "[MAIN]: Finished $CTR of $MAX iterations"
           printf '\n%s\n'  "`date`: [MAIN]: Finished $CTR of $MAX iterations"

           let CTR=$CTR+1

           if [ $CTR -gt $MAX ]; then
              break
           else
  			 log "[MAIN]: Sleeping for $PERIOD seconds"
  			 printf '\n%s\n' "`date`: [MAIN]: Sleeping for $PERIOD seconds"
			 RefreshRunningpids  "$TMPFILE"
             sleep $PERIOD
			 log "[MAIN]: Waiting for background process to complete (if any), before triggering another round. For more details check - $LOGFILE "
  			 printf '\n%s\n' "`date`: Waiting for background process to complete (if any), before triggering another round. For more details check - $LOGFILE "
			 waitforpid "$TMPFILE"
           fi
		   #RefreshRunningpids  "$TMPFILE"
       done

       log "[MAIN]: Finished All $MAX iterations. Waiting for background tasks to finish. Check file: $LOGFILE for details of running background processes."
       printf '\n%s\n' "`date`: [MAIN]: Finished All $MAX iterations. Waiting for background tasks to finish. Check file: $LOGFILE for details of running background processes."
  
   else 

		if [[ $hangrounds_SET -eq 0 ]]; then
			HANGROUNDS=2
		fi
		
		for (( IH=1; IH<=$HANGROUNDS ; IH++ )) 
	    do
      
          log "[MAIN]: Started Collecting ( round $IH of $HANGROUNDS )"
          printf '\n%s\n' "`date`: [MAIN]: Started Collecting ( round $IH of $HANGROUNDS )"

          TSTAMP=$( date "+%Y-%m-%d-%H.%M.%S" )
		  suffix=$( echo "$IH.$TSTAMP" )
		  
		  hang_collect_os_data "$TYPECOLLECT" "$OUTDIR" "$suffix" "$IH" "$TSTAMP" "$KERNELSTACK"  &
		  childpidOS=$( echo $! )
		  echo $childpidOS >> $TMPFILE
		  echo "collect_os_data PID: $childpidOS" >> $PROCESSFILE 2>&1
		  [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_os_data PID: $childpidOS"
		  printf '\n%s\n' "`date`: [OS data]: Started collection as background ( round $IH of $HANGROUNDS )"
		  
		  if [[ $nodb2pd_SET -eq "0" ]] ; then
			 hang_collect_db2pd_data "$DBNAME" "$IH" "$TYPECOLLECT" "$OUTDIR" "$suffix" "$SERVICEPASSWORD" &
			 childpiddb2pd=$( echo $! )
			 echo $childpiddb2pd >> $TMPFILE	
			 echo "collect_db2pd_data PID: $childpiddb2pd" >> $PROCESSFILE 2>&1
			 [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2pd_data PID: $childpiddb2pd"
			 printf '\n%s\n' "`date`: [DB2PD data ]: Started collection as background ( round $IH of $HANGROUNDS )"
		  fi
		  
		  if [[ $noconnect_SET -eq "0" ]] ; then
			 hang_collect_mon_data "$DBNAME" "$TYPECOLLECT" "$OUTDIR" "$IH" "$suffix" "$OKTORUN" &
			 childpidmon=$( echo $! )
			 echo $childpidmon >> $TMPFILE
			 echo "collect_mon_data PID: $childpidmon" >> $PROCESSFILE 2>&1
			 [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_mon_data PID: $childpidmon"
			 printf '\n%s\n' "`date`: [MON data]: Started collection as background ( round $IH of $HANGROUNDS )"
		  fi  
		  
		  if [ "x$TYPECOLLECT" = "x2" -a "x$PERF_NOTRC" = "x0"  ]; then
		   
			 log "DB2_WORKLOAD:  $( db2set | grep DB2_WORKLOAD= ) "	  				  
			 checkifCDE=$( db2set | grep "DB2_WORKLOAD=" | awk '{ if( match($0,"ANALYTICS")) print 1; else print 0; } END { if (NR==0) print 0 ; else 1; } ' )	  	  
			 hang_collect_db2trc_data "$checkifCDE" "$OUTDIR" "$IH" "$suffix" &
			 childpidtrc=$( echo $! )
			 echo $childpidtrc >> $TMPFILE
			 echo "collect_db2trc_data PID: $childpidtrc" >> $PROCESSFILE 2>&1
			 [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "collect_db2trc_data PID: $childpidtrc"
			 printf '\n%s\n' "`date`: [DB2TRC data]: Started collection as background ( round $IH of $HANGROUNDS )"		
				 
		  fi
		  	
          log "[MAIN]: Finished Collecting ( round $IH of $HANGROUNDS )"
          printf '\n%s\n' "`date`: [MAIN]: Finished Collecting ( round $IH of $HANGROUNDS )"
          
		  #RefreshRunningpids  "$TMPFILE"
		  [[ $IH -lt $HANGROUNDS ]] && log "[MAIN]: Background process running. Waiting for the all background processes of round $IH to complete before triggering another round. For more details check - $LOGFILE"
		  [[ $IH -lt $HANGROUNDS ]] && printf '\n%s\n' "`date`: [MAIN]: Background process running. Waiting for the all background processes of round $IH to complete before triggering another round. For more details check - $LOGFILE"
		  [[ $IH -lt $HANGROUNDS ]] && waitforpid "$TMPFILE"
		  
		  #RefreshRunningpids  "$TMPFILE"
		  
		done

        log "[MAIN]: All rounds of Hang data collection finished. Waiting for background tasks to finish. Check file: $LOGFILE for details of running background processes."
        printf '\n%s\n' "`date`: [MAIN]: All rounds of Hang collection finished. Waiting for background tasks to finish. Check file: $LOGFILE for details of running background processes."

   fi #End of if condition for COLLECTMODE=perf

   printf '\n%s\n' "`date`: All Data collection started as background processes. Waiting for all data collection to finish"
   log "All Data collection started as background processes. Waiting for all data collection to finish"

   #RefreshRunningpids  "$TMPFILE"
   waitforpid "$TMPFILE"
   
   if [ "x$TYPECOLLECT" = "x2" -a "x$PERF_NOTRC" = "x0"  ]; then
			formatTracefiles "$OUTDIR/DB2TRCData" 
   fi
   		
   #RefreshRunningpids  "$TMPFILE"
   waitforpid "$TMPFILE"
 
   log "Data collection finished. Tar up the dir $OUTDIR"
   printf '\n\n%s\n\n' "`date`: Data collection finished. Tar up the dir $OUTDIR"

# MAIN ELSE
else 

    if [[ "x$QUICKWLM" != "x" || "x$QUICKALL" != "x" ]]; then
	
        $DB2_PREFIX <<- $DB2_POSTFIX
         db2 "connect to $DBNAME"  > /dev/null 2>&1
	$DB2_POSTFIX
	   
	   RTNC=$?
	   RLINE=$LINENO

       if [ "$RTNC" -eq 0 ]; then

          # The curly brace below is to control the output and write to a file and terminal 
		  [[ "x$QUICKALL" != "x" ]] &&  OUTPUTFILE=$( echo "db_monitor.txt" )
          OUTPUTFILE=$( echo $OUTPUTFILE".wlm.$( date "+%Y-%m-%d-%H.%M.%S" )" )

          {

           $DB2_PREFIX <<- $DB2_POSTFIX
           
           if [ "x$DEBUG" = "x1" ]; then
               set -xv
           fi

           db2 "connect to $DBNAME" 

           db2 -v "call WLM_SET_CLIENT_INFO( null, null, null, null, 'SYSDEFAULTADMWORKLOAD' )" 

           printf '\n\n%s\n\n' "HEADER - Current state of queries"
           db2 -v "SELECT current timestamp as timestamp, ACTIVITY_STATE, SUM(ADM_BYPASSED) AS BYPASSED, COUNT(*) AS ACTIVE_CONNS FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE T.MEMBER = T.COORD_MEMBER GROUP BY ACTIVITY_STATE"

           printf '\n\n%s\n\n' "HEADER - Current state of queries per service class"
           db2 -v "SELECT current timestamp as timestamp, PARENTSERVICECLASSNAME AS SUPER, ACTIVITY_STATE, SUM(ADM_BYPASSED) AS BYPASSED, COUNT(*) as TOTAL_CONNS FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T, SYSCAT.SERVICECLASSES AS Q WHERE SERVICECLASSID = SERVICE_CLASS_ID AND T.MEMBER = T.COORD_MEMBER GROUP BY PARENTSERVICECLASSNAME, ACTIVITY_STATE ORDER BY PARENTSERVICECLASSNAME DESC"

           printf '\n\n%s\n\n' "HEADER - Agents queued up"
           db2 -v "SELECT current timestamp as timestamp, substr(SERVICE_SUPERCLASS_NAME,1,25) as super, EVENT_OBJECT, substr(EVENT_OBJECT_NAME,1,30) as event_object_name, COUNT(*) AS QUEUED_CONNS FROM TABLE(MON_GET_AGENT(NULL,NULL,NULL,-2)) AS T WHERE EVENT_OBJECT = 'WLM_QUEUE' GROUP BY substr(SERVICE_SUPERCLASS_NAME,1,25), EVENT_OBJECT, substr(EVENT_OBJECT_NAME,1,30)" 

           printf '\n\n%s:\n\n' "HEADER - Overall Queueing behaviour"
           db2 -v "select current timestamp as curr_timestamp, sum(act_completed_total) as stmts_completed, sum(act_aborted_total) as stmts_failed, sum(wlm_queue_assignments_total) as stmts_queued, case when sum( act_completed_total + act_aborted_total) > 0 then dec((float(sum(wlm_queue_assignments_total))/float(sum(act_completed_total + act_aborted_total))) * 100, 5, 2) else 0 end as pct_stmts_queued, sum(total_app_rqst_time) as rqst_time_ms, case when sum( act_completed_total + act_aborted_total ) > 0 then dec( ( float( sum(total_app_rqst_time) / sum(act_completed_total + act_aborted_total ) ) ), 5, 2) else 0 end as avg_app_rqst_time_ms, sum(wlm_queue_time_total) as total_queue_time_ms, case when sum(wlm_queue_assignments_total) > 0 then sum(wlm_queue_time_total) / sum(wlm_queue_assignments_total) else 0 end as avg_queue_time_ms from table(mon_get_database(-2)) as t "

           printf '\n\n%s:\n\n' "HEADER - Overall Queueing per Service Class"
           db2 -v "select current timestamp as timestamp, substr(service_superclass_name, 1, 25) as superclass, sum(act_completed_total) as stmts_completed, sum(act_aborted_total) as stmts_failed, sum(wlm_queue_assignments_total) as stmts_queued, case when sum(act_completed_total + act_aborted_total ) > 0 then decimal( (float(sum(wlm_queue_assignments_total)) / float(sum(act_completed_total + act_aborted_total))) * 100, 5, 2) else 0 end as pct_stmts_queued, sum(total_app_rqst_time) as rqst_time_ms, case when sum( act_completed_total + act_aborted_total) > 0 then decimal( (float(sum(total_app_rqst_time ))) / (float( sum(act_completed_total + act_aborted_total))),12,2) else 0 end as avg_app_rqst_time_ms, sum(wlm_queue_time_total) as total_queue_time_ms, case when sum(wlm_queue_assignments_total) > 0 then dec( float( sum(wlm_queue_time_total)) / float( sum(wlm_queue_assignments_total)), 12, 2)  else 0 end as avg_queue_time_ms from table(mon_get_service_superclass(null, -2)) as t group by substr(service_superclass_name,1,25)"

           printf '\n\n%s:\n\n' "HEADER - Overall WLM Resource usage ( actual )"
           db2 -v "WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), STMTS(NUMSTMT) AS (SELECT COUNT(*) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE ADM_BYPASSED = 0 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_DATABASE(-2)) AS T) SELECT current timestamp as timestamp, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(NUMSTMT)/FLOAT(LOADTRGT))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM WHERE SHEAPMEMBER=ALLOCMEMBER"

           printf '\n\n%s:\n\n' "HEADER - Most constrained resource ( database wide )" 
           db2 -v "WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), CPUINFO(CPUS_PER_HOST) AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES())), PARTINFO(PART_PER_HOST) AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY ), SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), STMTS(THREADDEMAND, MEMDEMAND) AS (SELECT SUM(EFFECTIVE_QUERY_DEGREE), SUM(ESTIMATED_SORT_SHRHEAP_TOP) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE  (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_DATABASE(-2)) AS T) SELECT current timestamp as curr_timestamp, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(MEMDEMAND)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_DEMAND, MAX(DEC((FLOAT(THREADDEMAND)/(FLOAT(LOADTRGT) * FLOAT(CPUS_PER_HOST) / FLOAT(PART_PER_HOST)))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM, CPUINFO, PARTINFO WHERE SHEAPMEMBER=ALLOCMEMBER"

           printf '\n\n%s:\n\n' "HEADER - Most constrained resource WLM Non-bypassed ( database wide )" 
           db2 -v "WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), CPUINFO(CPUS_PER_HOST) AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES())), PARTINFO(PART_PER_HOST) AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY ), SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), STMTS(THREADDEMAND, MEMDEMAND) AS (SELECT SUM(EFFECTIVE_QUERY_DEGREE), SUM(ESTIMATED_SORT_SHRHEAP_TOP) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE  ADM_BYPASSED = 0 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_DATABASE(-2)) AS T) SELECT current timestamp as curr_timestamp, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(MEMDEMAND)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_DEMAND, MAX(DEC((FLOAT(THREADDEMAND)/(FLOAT(LOADTRGT) * FLOAT(CPUS_PER_HOST) / FLOAT(PART_PER_HOST)))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM, CPUINFO, PARTINFO WHERE SHEAPMEMBER=ALLOCMEMBER"

           printf '\n\n%s:\n\n' "HEADER - Most constrained resource WLM bypassed ( database wide )" 
           db2 -v "WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), CPUINFO(CPUS_PER_HOST) AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES())), PARTINFO(PART_PER_HOST) AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY ), SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), STMTS(THREADDEMAND, MEMDEMAND) AS (SELECT SUM(EFFECTIVE_QUERY_DEGREE), SUM(ESTIMATED_SORT_SHRHEAP_TOP) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE  ADM_BYPASSED = 1 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_DATABASE(-2)) AS T) SELECT current timestamp as curr_timestamp, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(MEMDEMAND)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_DEMAND, MAX(DEC((FLOAT(THREADDEMAND)/(FLOAT(LOADTRGT) * FLOAT(CPUS_PER_HOST) / FLOAT(PART_PER_HOST)))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM, CPUINFO, PARTINFO WHERE SHEAPMEMBER=ALLOCMEMBER"

           printf '\n\n%s:\n\n' "HEADER - Most constrained resource ( per service class )"
           db2 -v "WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), CPUINFO(CPUS_PER_HOST) AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES())), PARTINFO(PART_PER_HOST) AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY ), SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), STMTS(SUPERCLASS, THREADDEMAND, MEMDEMAND) AS (SELECT PARENTSERVICECLASSNAME, SUM(EFFECTIVE_QUERY_DEGREE), SUM(ESTIMATED_SORT_SHRHEAP_TOP) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T, SYSCAT.SERVICECLASSES AS Q WHERE T.SERVICE_CLASS_ID = Q.SERVICECLASSID AND ADM_BYPASSED = 0 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM GROUP BY PARENTSERVICECLASSNAME), ALLOCMEM(SUPERCLASS, ALLOCMEM, ALLOCMEMBER) AS (SELECT SERVICE_SUPERCLASS_NAME, SORT_SHRHEAP_ALLOCATED, MEMBER FROM TABLE(MON_GET_SERVICE_SUPERCLASS(NULL,-2)) AS T) SELECT substr(A.SUPERCLASS,1,25) as super, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(MEMDEMAND)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_DEMAND, MAX(DEC((FLOAT(THREADDEMAND)/(FLOAT(LOADTRGT) * FLOAT(CPUS_PER_HOST) / FLOAT(PART_PER_HOST)))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS A, ALLOCMEM B, CPUINFO, PARTINFO WHERE SHEAPMEMBER=ALLOCMEMBER AND A.SUPERCLASS = B.SUPERCLASS GROUP BY substr(A.SUPERCLASS,1,25)"

           printf '\n\n%s:\n\n' "HEADER - Memory used by bypassed and non-bypassed queries per member" 
           db2 -v "with SORTMEM( SHEAPTHRESHSHR, SHEAPMEMBER ) as ( select value, member from sysibmadm.dbcfg where NAME = 'sheapthres_shr' ), APPHBYPASS( apphandle, admbypass ) as ( select application_handle, adm_bypassed from table( mon_get_activity(null,-2)) where activity_state in ('EXECUTING','IDLE') and coord_partition_num = member ) , ALLOCMEMBYPASS( appmember, apphandle, admbypass, allocmem ) as ( select A.member, A.application_handle, B.admbypass, sum( A.sort_shrheap_allocated ) from table( mon_get_activity(null, -2 )) as A, APPHBYPASS B where A.activity_state in ('EXECUTING','IDLE') and A.application_handle = B.apphandle group by A.member, A.application_handle, B.admbypass ) select current timestamp as timestamp, appmember, admbypass, sum(allocmem) as sortmem_used, decimal( ( float( sum( allocmem )) / float( max(sheapthreshshr)) ) * 100, 5, 2) as sortmem_used_pct from ALLOCMEMBYPASS, SORTMEM where APPMEMBER = SHEAPMEMBER group by appmember, admbypass order by  appmember "

           printf '\n\n%s:\n\n' "HEADER - Overall WLM estimated memory usage vs Actual usage"
           db2 -v "WITH SORTMEM(SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), STMTS(NUMSTMT) AS (SELECT COUNT(*) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE ADM_BYPASSED = 0 AND (ACTIVITY_STATE = 'EXECUTING' OR ACTIVITY_STATE = 'IDLE') AND MEMBER=COORD_PARTITION_NUM ) , ESTMEM( ESTMEM, ESTMEMBER ) AS ( SELECT sum( ESTIMATED_SORT_SHRHEAP_TOP) , MEMBER FROM TABLE( MON_GET_ACTIVITY(null,-2)) WHERE ( ACTIVITY_STATE = 'EXECUTING' or ACTIVITY_STATE = 'IDLE') and ADM_BYPASSED = 0 GROUP BY MEMBER ), ALLOCMEM(ALLOCMEM, ALLOCMEMBER) AS (SELECT sum(SORT_SHRHEAP_ALLOCATED), MEMBER FROM TABLE(MON_GET_DATABASE(-2)) group by member)  SELECT current timestamp as timestamp, MAX( DECIMAL( ( FLOAT( ESTMEM )/ FLOAT( SHEAPTHRESSHR ) ) * 100, 5,2 ) ) AS PERCENT_EST_SORTMEM, MAX(DEC((FLOAT(ALLOCMEM)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) AS PERCENT_SORTMEM_USED, MAX(DEC((FLOAT(NUMSTMT)/FLOAT(LOADTRGT))*100,5,2)) AS PERCENT_THREADS_USED FROM LOADTRGT, SORTMEM, STMTS, ALLOCMEM, ESTMEM WHERE SHEAPMEMBER=ALLOCMEMBER AND ESTMEMBER=SHEAPMEMBER"

           printf '\n\n%s:\n\n' "HEADER - Top memory consuming queries ( currently running )" 
           db2 -v "WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), ALLOCMEMPERAPPH( APPH, ALLOCMEM) AS ( select application_handle, max(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where activity_state in ('EXECUTING', 'IDLE') group by application_handle), ESTMEMPERAPPH( APPH, ESTMEM) AS ( select application_handle, max( estimated_sort_shrheap_top) from table(mon_get_activity(null,-2)) group by application_handle ), PEAKMEMPERAPPH( APPH, PEAKMEM) AS( select application_handle, max(sort_shrheap_top) from table( mon_get_activity(null,-2)) group by application_handle)   SELECT current timestamp as curr_timestamp, A.COORD_MEMBER, A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, B.APPLICATION_NAME, B.SESSION_AUTH_ID, B.CLIENT_IPADDR, A.ENTRY_TIME, A.LOCAL_START_TIME, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(A.LOCAL_START_TIME - A.ENTRY_TIME)) ELSE A.WLM_QUEUE_TIME_TOTAL/1000 END AS TOTAL_QUEUETIME_SECONDS, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME)) ELSE NULL END AS TOTAL_RUNTIME_SECONDS, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME))-A.COORD_STMT_EXEC_TIME/1000 ELSE NULL END AS TOTAL_CLIENT_WAIT_SECONDS, A.ADM_BYPASSED, A.ADM_RESOURCE_ACTUALS, A.QUERY_COST_ESTIMATE, A.ESTIMATED_RUNTIME, D.ESTMEM as ESTIMATED_SORT_SHREHEAP_PAGES, DEC((FLOAT(D.ESTMEM)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, E.ALLOCMEM AS SORTMEM_USED_PAGES, DEC((FLOAT(E.ALLOCMEM)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS SORTMEM_USED_PCT, F.PEAKMEM as PEAK_SORTMEM_USED_PAGES, DEC((FLOAT(F.PEAKMEM)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS PEAK_SORTMEM_USED_PCT, C.CFG_MEM AS CONFIGURED_SORTMEM_PAGES, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C, ALLOCMEMPERAPPH as E, ESTMEMPERAPPH as D,  PEAKMEMPERAPPH as F WHERE ( A.MEMBER = A.COORD_PARTITION_NUM ) and (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) AND (A.ACTIVITY_STATE IN ('EXECUTING', 'IDLE')) AND (A.APPLICATION_HANDLE = E.APPH ) AND ( A.APPLICATION_HANDLE = D.APPH ) AND ( A.APPLICATION_HANDLE = F.APPH ) ORDER BY SORTMEM_USED_PCT desc, APPLICATION_HANDLE, UOW_ID, ACTIVITY_ID, ACTIVITY_STATE"

           printf '\n\n%s:\n\n' "HEADER - Top thread consuming queries ( currently running )"
           db2 -v "WITH LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), CPUINFO(CPUS_PER_HOST) AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES())), PARTINFO(PART_PER_HOST) AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY ) SELECT current timestamp as curr_timestamp, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, A.LOCAL_START_TIME, A.ACTIVITY_STATE, EFFECTIVE_QUERY_DEGREE AS THREAD_DEMAND, DEC(FLOAT(EFFECTIVE_QUERY_DEGREE) / (FLOAT(LOADTRGT) * FLOAT(CPUS_PER_HOST) / FLOAT(PART_PER_HOST))*100,5,2) PCT_THREAD_DEMAND, TIMESTAMPDIFF(2, (CURRENT_TIMESTAMP - A.LOCAL_START_TIME)) AS TOTAL_RUNTIME, B.APPLICATION_NAME, B.SESSION_AUTH_ID, A.MEMBER, SUBSTR(A.STMT_TEXT, 1, 512) AS STATEMENT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL, -2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-2)) AS B, LOADTRGT, CPUINFO, PARTINFO WHERE A.APPLICATION_HANDLE = B.APPLICATION_HANDLE AND A.MEMBER = B.MEMBER AND A.ACTIVITY_STATE IN ('EXECUTING', 'IDLE') AND A.MEMBER = A.COORD_PARTITION_NUM AND A.ADM_BYPASSED = 0 ORDER BY PCT_THREAD_DEMAND desc" 

           if [ "x$OKTORUN" = "x1" ]; then

              printf '\n\n%s:\n\n' "HEADER - Resource consumption by the query sitting at head of the queue"
              db2 -v "WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr') SELECT current timestamp as curr_timestamp, SERVICE_SUPERCLASS_NAME, A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, B.APPLICATION_NAME, B.SESSION_AUTH_ID, B.CLIENT_IPADDR, A.ENTRY_TIME, A.LOCAL_START_TIME, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(A.LOCAL_START_TIME - A.ENTRY_TIME)) ELSE A.WLM_QUEUE_TIME_TOTAL/1000 END AS TOTAL_QUEUETIME_SECONDS, A.ADM_RESOURCE_ACTUALS, A.QUERY_COST_ESTIMATE, A.ESTIMATED_RUNTIME, A.ESTIMATED_SORT_SHRHEAP_TOP AS ESTIMATED_SORTMEM_USED_PAGES, DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C, TABLE(MON_GET_WLM_ADMISSION_QUEUE()) AS D WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) AND (A.APPLICATION_HANDLE = D.APPLICATION_HANDLE) AND (A.UOW_ID = D.UOW_ID) AND (A.ACTIVITY_ID = D.ACTIVITY_ID) AND (D.ADM_QUEUE_POSITION = 1)"

           fi

           printf '\n\n%s:\n\n' "HEADER - Sort memory usage per member"
           db2 -v "with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), actual_mem( tot_alloc_sortheap, sortmember ) as ( select sum( sort_shrheap_allocated ), member from table(mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING'  or activity_state = 'IDLE' ) group by member ) select current timestamp as timestamp, sortmember as member, tot_alloc_sortheap as allocated_sort_heap, decimal( ( tot_alloc_sortheap / SHEAPTHRESSHR)*100,5,2) as pct_sortmem_used, int( SHEAPTHRESSHR ) as cfg_shrheap_thresh  from actual_mem, SORTMEM where sortmember = SHEAPMEMBER order by pct_sortmem_used desc "

           printf '\n\n%s:\n\n' "HEADER - Sort memory usage per apphandle across ALL members"
           db2 -v "with ADMBYPASSAPPH( APPH, ADMBYPASS,RESOURCE_ACTUALS) AS( select application_handle, adm_bypassed, adm_resource_actuals from table( mon_get_activity(null,-2)) where member = coord_partition_num), SORTMEM(SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), ESTSORTMEM( estapphandle, estappmember, estsortmem) as ( select application_handle, member,  max( estimated_sort_shrheap_top ) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE') group by application_handle, member ), APPSORTMEM( apphandle, appmember, alloc_sortmem) as ( select application_handle, member, sum(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by application_handle, member ) select current timestamp as timestamp, appmember, apphandle,  ADMBYPASS as adm_bypass, RESOURCE_ACTUALS, alloc_sortmem as allocated_sortmem, estsortmem as est_sortmem, decimal( ( alloc_sortmem / SHEAPTHRESSHR ) * 100, 5,2 ) as pct_sortmem_used, decimal( ( estsortmem / SHEAPTHRESSHR )*100, 5, 2) as pct_est_sortmem, int(SHEAPTHRESSHR) as cfg_shrheap_thresh  from SORTMEM, APPSORTMEM, ESTSORTMEM, ADMBYPASSAPPH where SHEAPMEMBER = appmember and SHEAPMEMBER = estappmember and estapphandle = apphandle and apphandle = APPH and alloc_sortmem > 0 order by appmember, pct_sortmem_used desc"

           printf '\n\n%s:\n\n' "HEADER - Memory consumption of currently running queries"
           db2 -v "with total_mem(cfg_mem) as (select max(bigint(value)) from sysibmadm.dbcfg where name = 'sheapthres_shr' ), max_mem_part(member) as (select member from table(mon_get_database(-2)) as t order by sort_shrheap_allocated desc fetch first 1 rows only), mem_usage_on_member(application_handle, uow_id, activity_id, sort_shrheap_allocated) as (select application_handle, uow_id, activity_id, sort_shrheap_allocated from max_mem_part q, table(mon_get_activity(null, q.member)) as t where activity_state = 'EXECUTING' or activity_state = 'IDLE') select current timestamp as timestamp, a.application_handle, a.uow_id, a.activity_id, a.local_start_time, timestampdiff(2, (current_timestamp-a.local_start_time)) as total_runtime_seconds, timestampdiff(2, (current_timestamp-a.local_start_time))-a.coord_stmt_exec_time/1000 as total_wait_on_client_time_seconds, a.wlm_queue_time_total / 1000 as time_queued_before_start_exec_seconds,b.application_name, b.session_auth_id, b.client_ipaddr, a.activity_state, a.adm_bypassed, a.estimated_sort_shrheap_top est_mem_usage, c.sort_shrheap_allocated as mem_usage_curr, d.cfg_mem, dec((float(c.sort_shrheap_allocated)/float(d.cfg_mem))*100,5,2) as query_pct_mem_used, substr(a.stmt_text, 1, 1024) as statement_text from table(mon_get_activity(null,-2)) as a, table(mon_get_connection(null,-2)) as b, mem_usage_on_member as c, total_mem as d where (a.application_handle = b.application_handle) AND (a.member = b.member) AND (a.application_handle = c.application_handle) AND (a.member=a.COORD_PARTITION_NUM) AND (a.uow_id = c.uow_id) AND (a.activity_id = c.activity_id) order by query_pct_mem_used desc"

           printf '\n\n%s:\n\n' "HEADER - Estimated resource consumption by queries sitting on queue"
           db2 -v "with total_mem(cfg_mem) as (select bigint(max(value)) from sysibmadm.dbcfg where name = 'sheapthres_shr' ) select current timestamp as timestamp, a.application_handle, a.uow_id, a.activity_id, a.entry_time, timestampdiff(2, (current_timestamp - a.entry_time)) as time_queued_seconds, b.application_name, b.session_auth_id, b.client_ipaddr, a.activity_state, a.estimated_sort_shrheap_top est_mem_usage, a.member, dec((float(a.estimated_sort_shrheap_top)/float(cfg_mem))*100,5,2) as est_query_pct_mem_usage, substr(a.stmt_text, 1, 1024) as statement_text from table(mon_get_activity(null,-2)) as a, table(mon_get_connection(null,-2)) as b, total_mem c where (a.application_handle = b.application_handle) AND (a.member = b.member) AND (a.activity_state = 'QUEUED') AND (a.member=a.COORD_PARTITION_NUM)  order by est_mem_usage desc"

           printf '\n\n%s:\n\n' "HEADER - Resource Usage per Query ( Running and Queued )"
           db2 -v "WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), LOADTRGT(LOADTRGT) AS (SELECT MAX(VALUE) FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt'), CPUINFO(CPUS_PER_HOST) AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES())), PARTINFO(PART_PER_HOST) AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY ) SELECT current timestamp as timestamp, A.MEMBER, A.COORD_MEMBER, A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, B.APPLICATION_NAME, B.SESSION_AUTH_ID, B.CLIENT_IPADDR, A.ENTRY_TIME, A.LOCAL_START_TIME, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(A.LOCAL_START_TIME - A.ENTRY_TIME)) ELSE A.WLM_QUEUE_TIME_TOTAL/1000 END AS TOTAL_QUEUETIME_SECONDS, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME)) ELSE NULL END AS TOTAL_RUNTIME_SECONDS, CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME))-A.COORD_STMT_EXEC_TIME/1000 ELSE NULL END AS TOTAL_CLIENT_WAIT_SECONDS, A.ADM_BYPASSED, A.ADM_RESOURCE_ACTUALS, A.EFFECTIVE_QUERY_DEGREE, DEC((FLOAT(A.EFFECTIVE_QUERY_DEGREE)/(FLOAT(D.LOADTRGT) * FLOAT(E.CPUS_PER_HOST) / FLOAT(F.PART_PER_HOST)))*100,5,2) AS THREADS_USED_PCT, A.QUERY_COST_ESTIMATE, A.ESTIMATED_RUNTIME, A.ESTIMATED_SORT_SHRHEAP_TOP AS ESTIMATED_SORTMEM_USED_PAGES, DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, A.SORT_SHRHEAP_ALLOCATED AS SORTMEM_USED_PAGES, DEC((FLOAT(A.SORT_SHRHEAP_ALLOCATED)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS SORTMEM_USED_PCT, SORT_SHRHEAP_TOP AS PEAK_SORTMEM_USED_PAGES, DEC((FLOAT(A.SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS PEAK_SORTMEM_USED_PCT, C.CFG_MEM AS CONFIGURED_SORTMEM_PAGES, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C, LOADTRGT AS D, CPUINFO AS E, PARTINFO AS F WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) ORDER BY MEMBER, ACTIVITY_STATE, SORTMEM_USED_PCT desc" 

           printf '\n\n%s\n\n' "HEADER - Activity metrics"
           db2 -v "select current timestamp as current_time, coord_member, member, application_handle, entry_time, local_start_time, substr(activity_state,1,16) as state, substr(activity_type,1,12) as type, total_act_time, total_act_wait_time, lock_wait_time, pool_read_time, pool_write_time, total_extended_latch_wait_time, lock_wait_time, log_buffer_wait_time, log_disk_wait_time, diaglog_write_wait_time, evmon_wait_time, prefetch_wait_time, ext_table_recv_wait_time, ext_table_recvs_total, ext_table_read_volume, fcm_recv_wait_time, fcm_send_wait_time,  planid, stmtid, substr(stmt_text,1,100) as stmt_text from table(mon_get_activity(null,-2)) where  activity_type != 'DDL' order by total_act_time desc, application_handle, member  "

           printf '\n\n%s\n\n' "HEADER - Connection idle times"
           db2 -v "select current timestamp as timestamp, member, coord_member, application_handle, substr(client_applname,1,20) as client_appname, total_rqst_time, total_act_time, client_idle_wait_time, wlm_queue_time_total, total_act_wait_time, case when total_rqst_time > 0 then decimal(float(client_idle_wait_time) / total_rqst_time, 10, 2) else null end as idle_rqst_ratio from table(mon_get_connection(null,-2)) where client_applname is not null"

           printf '\n\n%s\n\n' "HEADER - Agent states per apphandle"
           db2 -v "with activity_handles(application_handle) as (select application_handle from table(mon_get_activity(null,-2)) where member=coord_partition_num and activity_type != 'DDL' ) select a.request_start_time, a.agent_state_last_update_time, current timestamp as current_time, a.application_handle, a.member,  a.agent_tid, substr(a.agent_type,1,11) as agenttype, substr(a.agent_state,1,10) as agentstate, substr(a.request_type,1,12) as reqtype, substr(a.event_object,1,16) as event_object, substr(a.event_state,1,16) as event_state, substr(event_object_name,1,32) as event_object_name, substr(event_object_details,1,32) as event_object_details, a.uow_id, a.activity_id from table(mon_get_agent(null,null, null, -2)) a, activity_handles d where a.application_handle = d.application_handle order by application_handle, member"


           if [ "x$OKTORUN" = "x1" ]; then

              printf '\n\n%s\n\n' "HEADER - Estimated Resource Usage of Top 10 queries on the queue"
              db2 -v "WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr') SELECT current timestamp as curr_timestamp, substr(A.ACTIVITY_STATE,1,15) as state, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, substr(B.SESSION_AUTH_ID,1,15) as auth_id, A.WLM_QUEUE_TIME_TOTAL/1000 AS TOTAL_QUEUETIME_SECONDS, DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, int( D.ADM_QUEUE_POSITION) as queue_position, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C, TABLE(MON_GET_WLM_ADMISSION_QUEUE()) AS D WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) AND (A.ACTIVITY_STATE IN ('QUEUED')) AND (A.APPLICATION_HANDLE = D.APPLICATION_HANDLE AND A.UOW_ID = D.UOW_ID AND A.ACTIVITY_ID = D.ACTIVITY_ID AND D.ADM_QUEUE_POSITION <= 10) order by D.ADM_QUEUE_POSITION"

           fi

           printf '\n\n%s:\n\n' "HEADER - Estimated resource usage of queries on the queue"
           db2 -v "WITH TOTAL_MEM(CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr') SELECT A.ACTIVITY_STATE, A.APPLICATION_HANDLE, A.UOW_ID, A.ACTIVITY_ID, B.SESSION_AUTH_ID, A.WLM_QUEUE_TIME_TOTAL/1000 AS TOTAL_QUEUETIME_SECONDS, DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT, SUBSTR(A.STMT_TEXT, 1, 512) AS STMT_TEXT FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS A, TABLE(MON_GET_CONNECTION(NULL,-1)) AS B, TOTAL_MEM AS C WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER) AND (A.ACTIVITY_STATE IN ('QUEUED')) AND (A.MEMBER = C.MEMBER ) ORDER BY ESTIMATED_SORTMEM_USED_PCT desc"

		   printf '\n\n%s\n\n' "HEADER - Actual sort usage"
		   db2 -v "WITH SORTMEM (SHEAPTHRESSHR, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), ACT_SORT(NUM_COORD_EXEC, SORT_SHRHEAP_UTIL) AS (SELECT MAX(NUM_EXEC_WITH_METRICS), MAX(DEC((FLOAT(SORT_SHRHEAP_TOP)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) FROM TABLE(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2)) AS A, SORTMEM B WHERE A.MEMBER = B.MEMBER GROUP BY A.EXECUTABLE_ID) SELECT RANGE AS PCT_MEM_UTIL, SUM(NUM_COORD_EXEC) NUM_IN_BIN FROM ( SELECT CASE WHEN SORT_SHRHEAP_UTIL < 1 THEN '1. < 1%' WHEN SORT_SHRHEAP_UTIL < 5 THEN '2. > 1% and < 5%' WHEN SORT_SHRHEAP_UTIL < 10 THEN '3. > 5% and < 10%' WHEN SORT_SHRHEAP_UTIL < 20 THEN '4. > 10% and < 20%' WHEN SORT_SHRHEAP_UTIL < 30 THEN '5. > 20% and < 30%' WHEN SORT_SHRHEAP_UTIL < 50 THEN '6. > 30% and < 50%' WHEN SORT_SHRHEAP_UTIL < 75 THEN '7. > 50% and < 75%' ELSE '8. > 75%' END AS RANGE, NUM_COORD_EXEC FROM ACT_SORT) GROUP BY RANGE ORDER BY RANGE ASC"
    
		   printf '\n\n%s\n\n' "HEADER - Estimated sort usage"
		   db2 -v "WITH SORTMEM (SHEAPTHRESSHR, MEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), ACT_SORT(NUM_COORD_EXEC, SORT_SHRHEAP_UTIL) AS (SELECT MAX(NUM_EXEC_WITH_METRICS), MAX(DEC((FLOAT(ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(SHEAPTHRESSHR))*100, 5,2)) FROM TABLE(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2)) AS A, SORTMEM B WHERE A.MEMBER = B.MEMBER GROUP BY A.EXECUTABLE_ID) SELECT RANGE AS PCT_MEM_UTIL, SUM(NUM_COORD_EXEC) NUM_IN_BIN FROM ( SELECT CASE WHEN SORT_SHRHEAP_UTIL < 1 THEN '1. < 1%' WHEN SORT_SHRHEAP_UTIL < 5 THEN '2. > 1% and < 5%' WHEN SORT_SHRHEAP_UTIL < 10 THEN '3. > 5% and < 10%' WHEN SORT_SHRHEAP_UTIL < 20 THEN '4. > 10% and < 20%' WHEN SORT_SHRHEAP_UTIL < 30 THEN '5. > 20% and < 30%' WHEN SORT_SHRHEAP_UTIL < 50 THEN '6. > 30% and < 50%' WHEN SORT_SHRHEAP_UTIL < 75 THEN '7. > 50% and < 75%' ELSE '8. > 75%' END AS RANGE, NUM_COORD_EXEC FROM ACT_SORT) GROUP BY RANGE ORDER BY RANGE ASC"

		   printf '\n\n%s\n\n' "HEADER - service class CPU utilization"
		   db2 -v "select service_subclass_name as name, decimal(estimated_cpu_entitlement,5,2) as entitlement, cpu_limit as limit, decimal(cpu_utilization,5,2) as cpu from  table(MON_SAMPLE_SERVICE_CLASS_METRICS(null, current server, '', '', 10, -2)) as t "
		   
		   printf '\n\n%s\n\n' "HEADER - queries are above_below the cost line"
		   db2 -v "with smallcost as (  select sum(num_coord_exec) as smallcost from table(mon_get_pkg_cache_stmt(null,null,null,-2)) where query_cost_estimate < 150000 ), smalltime as (  select sum(num_coord_exec) as smalltime from table(mon_get_pkg_cache_stmt(null,null,null,-2))   where (coord_stmt_exec_time / nullif(num_coord_exec,0)) < 30 ), total as ( select sum(num_coord_exec) as total from table(mon_get_pkg_cache_stmt(null,null,null,-2)) ) select (smallcost * 100) / total as pctsmallcost,  (smalltime * 100) / total as pctsmalltime from smallcost, smalltime, total"
		   
		   printf '\n\n%s\n\n' "HEADER - percentage of SORT operations spilling"
		   db2 -v "with ops as ( select MEMBER, (total_sorts + total_hash_joins + total_hash_grpbys)  as sort_ops,  (sort_overflows + hash_join_overflows + hash_grpby_overflows)  as overflows from table(mon_get_database(-2))) select MEMBER, sort_ops, overflows, (overflows * 100) / nullif(sort_ops,0) as pctoverflow from ops"
		   
		   printf '\n\n%s\n\n' "HEADER - SORT consumers per subclass per query"
		   db2 -v "with ops as ( select  service_superclass_name, service_subclass_name, (total_sorts + total_hash_joins + total_hash_grpbys) as sort_ops, cast(app_act_completed_total as decimal(5,0)) as stmts from table(mon_get_service_subclass('','',-2))) select service_superclass_name, service_subclass_name, sort_ops, stmts, round(sort_ops / nullif(stmts,0)) as sort_ops_avg from ops "
		   
           printf '\n\n%s:\n\n' "$(date): Collecting db2pd -intwlmadmission detail output"

           if [ "x$SERVICEPASSWORD" != "x0" ]; then

              db2pd -dbp 0 -db $DBNAME -intwlmadmission detail -service $SERVICEPASSWORD > db2pd_intwladmission.$tstamp
              RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` $rah db2pd -alldbp -db $DBNAME -sortheapconsumers -service $SERVICEPASSWORD $quote > db2pd_sortheapconsumers.$tstamp
              printf '%s\n\n' "$(date): More info in db2pd_intwladmission.$tstamp and db2pd_sortheapconsumers.$tstamp"

           else

              db2pd -dbp 0 -db $DBNAME -intwlmadmission detail > db2pd_intwladmission.$tstamp             
              find $SCRIPTDIR -maxdepth 1 -name "*.bin" -mmin -10 | xargs -I{} mv -f {} $PWD >/dev/null 2>&1  #To move the bin files generated by the db2pd command              

              RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` $rah db2pd -alldbp -db $DBNAME -sortheapconsumers $quote > db2pd_sortheapconsumers.$tstamp
              find $DB2INSTDIR -maxdepth 1 -name "*.bin" -mmin -10 | xargs -I{} mv -f {} $PWD >/dev/null 2>&1  #To move the bin files generated by the db2pd command

              printf '%s\n\n' "$(date): More info in db2pd_intwladmission.$tstamp and db2pd_sortheapconsumers.$tstamp"              
              printf '%s\n\n' "$(date): Send the .bin files as well"

           fi

           ( eval "db2pd -db $DBNAME $Db2pdMemAll -active -apinfo" ) > db2pd_apinfo.txt.$tstamp

           db2 -v "call WLM_SET_CLIENT_INFO( null, null, null, null, null )"

           db2 terminate
            
		$DB2_POSTFIX
          } 2>&1 | tee $OUTDIR/$OUTPUTFILE
  
                
            if [[ $NUMHOSTS > 1 ]]; then
            
              for ihost in $HOSTS ; 
              do
                COPYSCP "$ihost" "$DB2INSTDIR" "$tstamp" "$OUTDIR"
                COPYSCP "$ihost" "$DB2INSTDIR" "bin" "$OUTDIR"
                COPYSCP "$ihost" "$CWD" "$tstamp" "$OUTDIR"
                COPYSCP "$ihost" "$CWD" "bin" "$OUTDIR"
				COPYSCP "$ihost" "$PWD" "$tstamp" "$OUTDIR"
                COPYSCP "$ihost" "$PWD" "bin" "$OUTDIR"
              done
            
            else          
				mv $DB2INSTDIR/*.$tstamp $OUTDIR 1> /dev/null 2>&1 
				mv $DB2INSTDIR/*.bin $OUTDIR 1> /dev/null 2>&1 
				mv $CWD/*.$tstamp $OUTDIR 1> /dev/null 2>&1 
				mv $CWD/*.bin $OUTDIR 1> /dev/null 2>&1 
				mv $PWD/*.$tstamp $OUTDIR 1> /dev/null 2>&1 
				mv $PWD/*.bin $OUTDIR 1> /dev/null 2>&1 
            fi
                      
          printf '\n\n%s\n\n' "$(date): The terminal output is captured in $OUTPUTFILE and diagnostics are in $OUTDIR"

       else

			retchk "$RTNC" "$RLINE" "db2 connect to $DBNAME" "$(hostname)" "Unable to connect to $DBNAME"  
       fi
       
	fi
    if [[ "x$QUICKTRANSACTIONS" != "x" || "x$QUICKALL" != "x" ]]; then

        $DB2_PREFIX <<- $DB2_POSTFIX
         db2 "connect to $DBNAME"  > /dev/null 2>&1
	$DB2_POSTFIX
	
		 RTNC=$?
		 RLINE=$LINENO
		 
         if [ "$RTNC" -eq 0 ]; then
			[[ "x$QUICKALL" != "x" ]] && OUTPUTFILE=$( echo "db_monitor.txt" )
            OUTPUTFILE=$( echo $OUTPUTFILE".transactions.$( date "+%Y-%m-%d-%H.%M.%S" )" )

            {
           $DB2_PREFIX <<- $DB2_POSTFIX
           
           if [ "x$DEBUG" = "x1" ]; then
               set -xv
           fi

            db2 connect to $DBNAME 

            printf '\n%s\n\n' "HEADER - Transaction log usage"
            db2 -v "select current timestamp as timestamp, member, log_utilization_percent, total_log_used_kb, total_log_available_kb, total_log_used_top_kb from sysibmadm.mon_transaction_log_utilization order by member with ur" 

            printf '\n%s\n\n' "HEADER - Transaction log usage details and apphandle holding the oldest transaction"
            db2 -v "select current timestamp as timestamp, member, decimal( ( 1 - ( double( TOTAL_LOG_USED )/double( TOTAL_LOG_USED + TOTAL_LOG_AVAILABLE ) ) )*100,5,2 ) as PCT_LOG_available,  first_active_log  as first_active_log,  last_active_log last_active_log,  current_active_log  current_active_log, ( current_active_log - first_active_log ) num_active_logs, applid_holding_oldest_xact from table(mon_get_transaction_log(-2)) order by member with ur"

            printf '\n%s\n\n' "HEADER - Logspace usage per apphandle"
            db2 -v "select current timestamp as timestamp, member, application_handle, decimal( double( sum( uow_log_space_used )  / ( 1024 * 1024 ) ), 12, 2) as logspace_used_MB from table( mon_get_unit_of_work(null,-2)) where uow_log_space_used > 0 group by member,application_handle order by logspace_used_MB desc, member"

            db2 terminate 
		$DB2_POSTFIX
            } 2>&1 | tee $OUTDIR/$OUTPUTFILE 


         else
		 
            retchk "$RTNC" "$RLINE" "db2 connect to $DBNAME" "$(hostname)" "Unable to connect to $DBNAME" 
         fi
	fi
    if [[ "x$QUICKSESSIONS" != "x" || "x$QUICKALL" != "x" ]]; then

        $DB2_PREFIX <<- $DB2_POSTFIX
         db2 "connect to $DBNAME"  > /dev/null 2>&1
	$DB2_POSTFIX

		 RTNC=$?
		 RLINE=$LINENO
		 
         if [ "$RTNC" -eq 0 ]; then
		   [[ "x$QUICKALL" != "x" ]] && OUTPUTFILE=$( echo "db_monitor.txt" )
           OUTPUTFILE=$( echo $OUTPUTFILE".sessions.$( date "+%Y-%m-%d-%H.%M.%S" )" )

           {
           $DB2_PREFIX <<- $DB2_POSTFIX
           
           if [ "x$DEBUG" = "x1" ]; then
               set -xv
           fi

            db2 "connect to $DBNAME" 
			
            printf '\n\n%s\n\n' "HEADER - Current CPU usage across members"
            db2 -v "select current timestamp as curr_timestamp, min(member) as member_min, max(member) member_max, substr(host_name,1,20) as host_name, max(cpu_online) cpu_online, max(cpu_usage_total) cpu_usage_total, max(decimal(cpu_load_short,6,1)) load_short, max(decimal(cpu_load_medium,6,1)) load_med, max(decimal(cpu_load_long,6,1)) load_long, min(memory_free)/1024 as mem_free_gb from table(sysproc.env_get_system_resources()) group by host_name order by member_min asc"

            printf '\n\n%s\n\n' "HEADER - Current state of queries"
            db2 -v "SELECT current timestamp as timestamp, ACTIVITY_STATE, SUM(ADM_BYPASSED) AS BYPASSED, COUNT(*) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T WHERE T.MEMBER = T.COORD_MEMBER GROUP BY ACTIVITY_STATE"

            printf '\n\n%s\n\n' "HEADER - Current state of queries per service class"
            db2 -v "SELECT current timestamp as timestamp, substr(PARENTSERVICECLASSNAME,1,25) AS SUPER, ACTIVITY_STATE, SUM(ADM_BYPASSED) AS BYPASSED, COUNT(*) FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T, SYSCAT.SERVICECLASSES AS Q WHERE SERVICECLASSID = SERVICE_CLASS_ID AND T.MEMBER = T.COORD_MEMBER GROUP BY substr(PARENTSERVICECLASSNAME,1,25), ACTIVITY_STATE ORDER BY SUPER DESC"

            printf '\n\n%s\n\n' "HEADER - Agents queued up"
            db2 -v "SELECT current timestamp as timestamp, SERVICE_SUPERCLASS_NAME, EVENT_OBJECT, EVENT_OBJECT_NAME, COUNT(*) FROM TABLE(MON_GET_AGENT(NULL,NULL,NULL,-2)) AS T WHERE EVENT_OBJECT = 'WLM_QUEUE' GROUP BY SERVICE_SUPERCLASS_NAME, EVENT_OBJECT, EVENT_OBJECT_NAME" 

            printf '\n\n%s\n\n' "HEADER - Queries in executing or idle state"
            db2 -v "select current timestamp as timestamp, application_handle, substr(activity_state,1,12) as state, coord_partition_num as connecting_member, member as current_member, planid, stmtid, substr( stmt_text, 1, 120 ) as stmt_text from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) and member = coord_partition_num with ur" 

            printf '\n\n%s\n\n' "HEADER - Queries on the queue"
            db2 -v "select current timestamp as timestamp, application_handle, coord_partition_num as connecting_member, estimated_sort_shrheap_top, estimated_runtime, substr( stmt_text, 1, 120 ) as stmt_text from table( mon_get_activity(null,-2)) where activity_state = 'QUEUED' and member = coord_partition_num with ur" 
	
            printf '\n\n%s\n\n' "HEADER - Top 10 longest running queries"
            db2 -v "select current timestamp as timestamp, application_handle, entry_time, local_start_time, timestampdiff( 2, to_char( current timestamp - local_start_time ) ) as elapsed_tm_secs, stmtid, planid, effective_query_degree, substr(stmt_text,1,200) as stmt_text  from table(mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) and member = coord_partition_num and timestampdiff( 2, to_char( current timestamp - local_start_time ) ) > 0 order by elapsed_tm_secs desc fetch first 10 rows only with ur"

            printf '\n\n%s\n\n' "HEADER - Top 10 sort memory consuming queries"
            db2 -v "select current timestamp as timestamp, application_handle, sum( nvl( sort_shrheap_allocated, 0 ) * 4) as allocated_sortmem_kb, max( sort_shrheap_top * 4 ) as peak_sortmem_used_kb from table( mon_get_activity(null, -2 )) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) and ( nvl( sort_shrheap_allocated, 0 ) > 0 or nvl( sort_shrheap_top, 0 ) > 0 ) group by application_handle order by allocated_sortmem_kb desc fetch first 10 rows only with ur"

            printf '\n\n%s\n\n' "HEADER - Top 10 queries with longest wait within engine"
            db2 -v "select current timestamp as timestamp, application_handle, executable_id, decimal( avg( ( total_act_wait_time  /   total_act_time ) * 100 ), 5,2) as overall_wait_pct , decimal( avg( ( lock_wait_time / total_act_time ) * 100 ), 5,2 ) as pct_lck, decimal( avg( ( pool_read_time / total_act_time ) * 100 ), 5, 2) as pct_phys_rd, decimal( avg( ( ( direct_read_time+direct_write_time ) / total_act_time ) * 100 ), 5,2 ) as pct_dir_io, decimal( avg( ( (fcm_recv_wait_time+fcm_send_wait_time) / total_act_time ) * 100 ),5,2) as pct_fcm, decimal( avg( ( total_extended_latch_wait_time / total_act_time ) * 100 ),5,2) as pct_ltch, decimal( avg( ( log_disk_wait_time /  total_act_time ) * 100 ), 5,2 ) as pct_log, decimal( avg( ( diaglog_write_wait_time / total_act_time ) * 100 ), 5, 2) as pct_diaglog from table( mon_get_activity(null,-2)) where total_act_time > 0 group by application_handle , planid, stmtid, executable_id order by overall_wait_pct desc fetch first 10 rows only with ur"

            printf '\n\n%s\n\n' "HEADER - Top 25 apphandles spilling sorts to disk"
            #db2 -v "select current timestamp as timestamp, substr(a.tabschema,1,25) as apphandle, count(*) as num_objects, decimal( (sum(  nvl(a.data_object_l_pages,0) + nvl(col_object_l_pages,0) + nvl( a.index_object_l_pages,0)) * 32 )/(1024*1024),15,2) as diskspillInGB from table( mon_get_table( null, null, -2) ) as a  where a.tbsp_id = 1  group by a.tabschema order by diskspillInGB desc  fetch first 10 rows only with ur "
            db2 -v "with pagesize( MEMBER, TBSP_ID, tbsp_page_size) as ( select MEMBER, TBSP_ID, tbsp_page_size from table(mon_get_tablespace(null,-2)) where TBSP_CONTENT_TYPE IN ('SYSTEMP','USRTEMP')  ) , numpages( apphandle, MEMBER, tbsp_id, num_objects, spillMB ) as ( select substr(tabschema,1,45) , t.MEMBER , t.tbsp_id, int(count(*)) , sum( decimal( ( float( ( nvl( col_object_l_pages,0) + nvl(data_object_l_pages,0) + nvl( index_object_l_pages,0)) * p.tbsp_page_size) / float((1024*1024)) ), 15,2)) as spillMB from table(mon_get_table(null,null,-2)) as t , pagesize p where t.tbsp_id = p.TBSP_ID AND t.MEMBER = p.MEMBER group by substr(tabschema,1,45), t.MEMBER, t.tbsp_id )  select current timestamp as curr_timestamp , apphandle , sum(num_objects) as num_objects , sum(spillMB) as spillMB  from   numpages group by apphandle order by spillMB desc fetch first 25 rows only with ur"

            printf '\n\n%s:\n\n' "HEADER - Sort memory usage per member"
            db2 -v "with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), actual_mem( tot_alloc_sortheap, sortmember ) as ( select sum( sort_shrheap_allocated ), member from table(mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING'  or activity_state = 'IDLE' ) group by member ) select current timestamp as timestamp, sortmember as member, tot_alloc_sortheap as allocated_sort_heap, decimal( ( tot_alloc_sortheap / SHEAPTHRESSHR)*100,5,2) as pct_sortmem_used, int( SHEAPTHRESSHR ) as cfg_shrheap_thresh  from actual_mem, SORTMEM where sortmember = SHEAPMEMBER order by member "

            printf '\n\n%s:\n\n' "HEADER - Sort memory usage of bypassed and non-bypassed queries per member"
            db2 -v "with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), ADMBYPASS( appmember, admbypassed, alloc_sortmem) as ( select member, adm_bypassed, sum(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by  member, adm_bypassed ) select current timestamp as curr_timestamp, appmember, alloc_sortmem as allocated_sortmem, decimal( ( alloc_sortmem / SHEAPTHRESSHR) * 100, 5,2 ) as pct_sortmem_used,  admbypassed as adm_bypass, int(SHEAPTHRESSHR) as cfg_shrheap_thresh  from SORTMEM, ADMBYPASS where SHEAPMEMBER = appmember and alloc_sortmem > 0 order by appmember, pct_sortmem_used desc" 

            printf '\n\n%s:\n\n' "HEADER - Sort memory usage per apphandle across ALL members"
            db2 -v "with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), ESTSORTMEM( estapphandle, estappmember, estsortmem) as ( select application_handle, member,  max( estimated_sort_shrheap_top ) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE') group by application_handle, member ), APPSORTMEM( apphandle, appmember, admbypassed, alloc_sortmem) as ( select application_handle, member, adm_bypassed, sum(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by application_handle, member, adm_bypassed ) select current timestamp as timestamp, appmember, apphandle, admbypassed as adm_bypass, alloc_sortmem as allocated_sortmem, estsortmem as est_sortmem, decimal( ( alloc_sortmem / SHEAPTHRESSHR ) * 100, 5,2 ) as pct_sortmem_used, decimal( ( estsortmem / SHEAPTHRESSHR )*100, 5, 2) as pct_est_sortmem, int(SHEAPTHRESSHR) as cfg_shrheap_thresh  from SORTMEM, APPSORTMEM, ESTSORTMEM where SHEAPMEMBER = appmember and SHEAPMEMBER = estappmember and estapphandle = apphandle and alloc_sortmem > 0 order by appmember, pct_sortmem_used desc"

            printf '\n\n%s:\n\n' "HEADER - Memory consumption of currently running queries"
            db2 -v "with total_mem(cfg_mem) as (select max(bigint(value)) from sysibmadm.dbcfg where name = 'sheapthres_shr' ), max_mem_part(member) as (select member from table(mon_get_database(-2)) as t order by sort_shrheap_allocated desc fetch first 1 rows only), mem_usage_on_member(application_handle, uow_id, activity_id, sort_shrheap_allocated) as (select application_handle, uow_id, activity_id, sort_shrheap_allocated from max_mem_part q, table(mon_get_activity(null, q.member)) as t where activity_state = 'EXECUTING' or activity_state = 'IDLE') select current timestamp as timestamp, a.application_handle, a.uow_id, a.activity_id, a.local_start_time, timestampdiff(2, (current_timestamp-a.local_start_time)) as total_runtime_seconds, timestampdiff(2, (current_timestamp-a.local_start_time))-a.coord_stmt_exec_time/1000 as total_wait_on_client_time_seconds, a.wlm_queue_time_total / 1000 as time_queued_before_start_exec_seconds,b.application_name, b.session_auth_id, b.client_ipaddr, a.activity_state, a.adm_bypassed, a.estimated_sort_shrheap_top est_mem_usage, c.sort_shrheap_allocated as mem_usage_curr, d.cfg_mem, dec((float(c.sort_shrheap_allocated)/float(d.cfg_mem))*100,5,2) as query_pct_mem_used, substr(a.stmt_text, 1, 1024) as statement_text from table(mon_get_activity(null,-2)) as a, table(mon_get_connection(null,-2)) as b, mem_usage_on_member as c, total_mem as d where (a.application_handle = b.application_handle) AND (a.member = b.member) AND (a.application_handle = c.application_handle) AND (a.member=a.COORD_PARTITION_NUM) AND (a.uow_id = c.uow_id) AND (a.activity_id = c.activity_id) order by query_pct_mem_used"

            printf '\n\n%s\n\n' "HEADER - Estimated memory consumption of queued queries"
            db2 -v "with total_mem(cfg_mem) as (select bigint(max(value)) from sysibmadm.dbcfg where name = 'sheapthres_shr' ) select a.application_handle, a.uow_id, a.activity_id, a.entry_time, timestampdiff(2, (current_timestamp - a.entry_time)) as time_queued_seconds, b.application_name, b.session_auth_id, b.client_ipaddr, a.activity_state, a.estimated_sort_shrheap_top est_mem_usage, a.member, dec((float(a.estimated_sort_shrheap_top)/float(cfg_mem))*100,5,2) as est_query_pct_mem_usage, substr(a.stmt_text, 1, 1024) as statement_text from table(mon_get_activity(null,-2)) as a, table(mon_get_connection(null,-2)) as b, total_mem c where (a.application_handle = b.application_handle) AND (a.member = b.member) AND (a.activity_state = 'QUEUED') AND (a.member=a.COORD_PARTITION_NUM) AND (dec((float(a.estimated_sort_shrheap_top)/float(cfg_mem))*100,5,2)) > 25 order by est_mem_usage desc"

            printf '\n\n%s\n\n' "HEADER - Information on agents working for each apphandle"
            db2 -v "with activity_data( member, application_handle, rows_read, rows_returned, rows_modified, fcm_tq_recvs_total, fcm_tq_sends_total ) as ( select member, application_handle, sum( rows_read), sum(rows_returned), sum(rows_modified), sum(fcm_tq_recvs_total), sum(fcm_tq_sends_total)  from table( mon_get_activity( null, -2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by member, application_handle) SELECT current timestamp as timestamp, SUBSTR(CHAR(SCDETAILS.APPLICATION_HANDLE),1,7) AS APPHANDLE, SUBSTR(CHAR(SCDETAILS.MEMBER),1,4) AS MEMB, SUBSTR(EVENT_STATE,1,10) AS EVENT_STATE, SUBSTR(EVENT_TYPE,1,10) AS EVENT_TYPE, SUBSTR(EVENT_OBJECT,1,10) AS EVENT_OBJECT, SUBSTR(EVENT_STATE,1,10) as EVENT_STATE, SUBSTR(EVENT_OBJECT_NAME,1,30) as EVENT_OBJECT_NAME, SUBSTR(EVENT_OBJECT_DETAILS,1,30) as EVENT_OBJECT_DETAILS, SUBSTR(CHAR(SUBSECTION_NUMBER),1,4) AS SUBSECTN, TIMESTAMPDIFF(2, CHAR( AGENT_STATE_LAST_UPDATE_TIME - REQUEST_START_TIME) ) as ELAPSED_SECS, rows_read as rread, rows_returned as rret, rows_modified as rmod, fcm_tq_recvs_total as tq_recv, fcm_tq_sends_total as tq_send FROM TABLE(MON_GET_AGENT(CAST(NULL AS VARCHAR(128)), CAST(NULL AS VARCHAR(128)), NULL, -2)) AS SCDETAILS, activity_data  where SCDETAILS.member = activity_data.member and SCDETAILS.application_handle = activity_data.application_handle ORDER BY elapsed_secs desc, memb, subsectn"

            printf '\n\n%s\n\n' "HEADER - Lock wait details"
            db2 -v "select current timestamp as timestamp, hld_member as hld_m, req_member as req_m, hld_application_handle, req_application_handle,lock_wait_start_time, timestampdiff(2,to_char(current timestamp - lock_wait_start_time)) as lockwait_time_secs,lock_name, lock_current_mode,lock_mode_requested from table(mon_get_appl_lockwait(null,-2)) order by lockwait_time_secs desc with ur"

            printf '\n\n%s\n\n' "HEADER - Activity metrics"
            db2 -v "select current timestamp as current_time, coord_member, member, application_handle, entry_time, local_start_time, substr(activity_state,1,16) as state, substr(activity_type,1,12) as type, total_act_time, total_act_wait_time, lock_wait_time, pool_read_time, pool_write_time, total_extended_latch_wait_time, lock_wait_time, log_buffer_wait_time, log_disk_wait_time, diaglog_write_wait_time, evmon_wait_time, prefetch_wait_time, ext_table_recv_wait_time, ext_table_recvs_total, ext_table_read_volume, fcm_recv_wait_time, fcm_send_wait_time,  planid, stmtid, substr(stmt_text,1,100) as stmt_text from table(mon_get_activity(null,-2)) where  activity_type != 'DDL' order by total_act_time desc, application_handle, member  "

            printf '\n\n%s\n\n' "HEADER - Connection idle times"
            db2 -v "select current timestamp as timestamp, member, coord_member, application_handle, substr(client_applname,1,20) as client_appname, total_rqst_time, total_act_time, client_idle_wait_time, wlm_queue_time_total, total_act_wait_time, case when total_rqst_time > 0 then decimal(float(client_idle_wait_time) / total_rqst_time, 10, 2) else null end as idle_rqst_ratio from table(mon_get_connection(null,-2)) where client_applname is not null"

            printf '\n\n%s\n\n' "HEADER - Agent states per apphandle"
            db2 -v "with activity_handles(application_handle) as (select application_handle from table(mon_get_activity(null,-2)) where member=coord_partition_num and activity_type != 'DDL' ) select a.request_start_time, a.agent_state_last_update_time, current timestamp as current_time, a.application_handle, a.member,  a.agent_tid, substr(a.agent_type,1,11) as agenttype, substr(a.agent_state,1,10) as agentstate, substr(a.request_type,1,12) as reqtype, substr(a.event_object,1,16) as event_object, substr(a.event_state,1,16) as event_state, substr(event_object_name,1,32) as event_object_name, substr(event_object_details,1,32) as event_object_details,  a.uow_id, a.activity_id from table(mon_get_agent(null,null, null, -2)) a, activity_handles d where a.application_handle = d.application_handle order by application_handle, member"

            printf '\n\n%s\n\n' "HEADER - FCM Congestion details"
            db2 -v "select current timestamp as timestamp, member, remote_member, fcm_congested_sends, fcm_congestion_time, fcm_num_congestion_timeouts, connection_status from table(mon_get_fcm_connection_list(-2)) order by member"

            printf '\n\n%s\n\n' "HEADER - Latch activity per query"
            db2 -v "with activity_handles(application_handle) as (select application_handle from table(mon_get_activity(null,-2)) where member=coord_partition_num and activity_type != 'DDL' ) select current timestamp as current_time, l.member, substr(l.latch_name,1,40) latch_name, l.application_handle, l.edu_id, l.latch_status, l.latch_wait_time from table(mon_get_latch(null,-2)) l,  activity_handles d where l.application_handle = d.application_handle order by application_handle, member"

            printf '\n\n%s\n\n' "HEADER - Wait times within DB engine"
            db2 -v "select member, integer(sum(total_rqst_time)) as total_rqst_tm, integer(sum(total_wait_time)) as total_wait_tm, decimal((sum(total_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_rqst_wait, decimal((sum(lock_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_lock, decimal((sum(lock_wait_time_global) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_glb_lock, decimal((sum(total_extended_latch_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_ltch, decimal((sum(log_disk_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_lg_dsk, decimal((sum(reclaim_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_rclm, decimal((sum(cf_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_cf, decimal((sum(pool_read_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_pool_r, decimal((sum(direct_read_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_dir_r, decimal((sum(direct_write_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_dir_w, decimal((sum(fcm_recv_wait_time+fcm_send_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_fcm, decimal((sum(tcpip_send_wait_time+tcpip_recv_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_tcpip , decimal((sum(diaglog_write_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_diag from table( mon_get_database(-2)) group by member order by member"

            printf '\n\n%s\n\n' "HEADER - Overall Latch wait metrics ( the numbers are cumulative )"
            db2 -v "select current timestamp as timestamp,member, cast(substr(latch_name,1,60) as varchar(60)) as latch_name, total_extended_latch_wait_time as tot_ext_latch_wait_time_ms, total_extended_latch_waits as tot_ext_latch_waits, decimal( double(total_extended_latch_wait_time) / total_extended_latch_waits, 10, 2 ) as time_per_latch_wait_ms from table( mon_get_extended_latch_wait(-2)) where total_extended_latch_waits > 0 order by total_extended_latch_wait_time desc with UR" 

            printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_BP_UTILIZATION"
            db2 -v "select * from SYSIBMADM.MON_BP_UTILIZATION ORDER BY 1,2 with UR" 

            printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_TRANSACTION_LOG_UTILIZATION"
            db2 -v "select * from SYSIBMADM.MON_TRANSACTION_LOG_UTILIZATION ORDER BY 1 DESC WITH UR"
			
			printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_WORKLOAD_SUMMARY"
			db2 -v "select * from sysibmadm.MON_WORKLOAD_SUMMARY ORDER BY 1  WITH UR"
			
			printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_SERVICE_SUBCLASS_SUMMARY"
			db2 -v "select * from sysibmadm.MON_SERVICE_SUBCLASS_SUMMARY  ORDER BY 1  WITH UR"
			
			printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_DB_SUMMARY"
			db2 -v "select * from sysibmadm.MON_DB_SUMMARY  WITH UR"
			
			printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_CURRENT_UOW"
			db2 -v "select * from sysibmadm.MON_CURRENT_UOW   ORDER BY ELAPSED_TIME_SEC DESC  WITH UR"
						
			printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_CONNECTION_SUMMARY"
			db2 -v "select * from sysibmadm.MON_CONNECTION_SUMMARY ORDER BY RQST_WAIT_TIME_PERCENT DESC  WITH UR"
			
			printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_TBSP_UTILIZATION"
			db2 -v "select * from SYSIBMADM.MON_TBSP_UTILIZATION ORDER BY 1,2  WITH UR"
			
			printf '\n\n%s\n\n' "HEADER - SYSIBMADM.MON_PKG_CACHE_SUMMARY"
			db2 -v "select * from sysibmadm.MON_PKG_CACHE_SUMMARY ORDER BY AVG_STMT_EXEC_TIME DESC FETCH FIRST 10 rows only  WITH UR"

			printf '%s\n\n' "HEADER - $(date): CPU TIME PER APPLICATION_HANDLE ACROSS ALL MEMBERS"
			db2 -v "SELECT t.APPLICATION_HANDLE,count(t.member) as NUM_MEMBER,decimal(avg(t.TOTAL_CPU_TIME*1.00)/1000000, 12,2) as AVG_TOTAL_CPU_TIME_SEC,decimal(avg(t.TOTAL_WAIT_TIME*1.00)/1000, 12,2) as AVG_TOTAL_WAIT_TIME_SEC, decimal(avg(t.TOTAL_RQST_TIME*1.00)/1000, 12,2) as AVG_TOTAL_RQST_TIME_SEC, decimal(avg(t.TOTAL_SECTION_TIME*1.00)/1000,12,2) as AVG_TOTAL_SECTION_TIME_SEC, decimal(avg(t.TOTAL_SECTION_PROC_TIME*1.00)/1000, 12,2) as AVG_TOTAL_SECTION_PROC_TIME_SEC FROM TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS t GROUP BY t.APPLICATION_HANDLE"

			printf '%s\n\n' "HEADER - $(date): Bufferpool METRICS across all members"
			db2 -v "SELECT bp_name, sum( pool_data_l_reads + pool_temp_data_l_reads +  pool_index_l_reads + pool_temp_index_l_reads +  pool_xda_l_reads + pool_temp_xda_l_reads) as logical_reads,  sum( pool_data_p_reads + pool_temp_data_p_reads +  pool_index_p_reads + pool_temp_index_p_reads +  pool_xda_p_reads + pool_temp_xda_p_reads) as physical_reads  ,case when sum( pool_data_l_reads + pool_temp_data_l_reads +  pool_index_l_reads + pool_temp_index_l_reads +  pool_xda_l_reads + pool_temp_xda_l_reads) > 0  THEN DEC((1-(FLOAT(sum( pool_data_p_reads + pool_temp_data_p_reads +  pool_index_p_reads + pool_temp_index_p_reads +  pool_xda_p_reads + pool_temp_xda_p_reads)) / FLOAT (sum( pool_data_l_reads + pool_temp_data_l_reads +  pool_index_l_reads + pool_temp_index_l_reads +  pool_xda_l_reads + pool_temp_xda_l_reads))))*100,5,2)  ELSE NULL  END AS HITRATIO  FROM TABLE(MON_GET_BUFFERPOOL('',-2)) AS METRICS group by bp_name" 

			printf '%s\n\n' "HEADER - $(date): Tablespace METRICS across all members"
			db2 -v "with tbsp_metrics as (  SELECT varchar(tbsp_name, 20) as tbsp_name,  tbsp_type,  max (tbsp_page_size) as tbsp_page_size,  count(member) as num_member,  sum( pool_data_l_reads + pool_temp_data_l_reads + pool_index_l_reads + pool_temp_index_l_reads + pool_xda_l_reads + pool_temp_xda_l_reads) as sum_logical_reads,  sum( pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads) as sum_physical_reads,  sum( pool_data_p_reads + pool_index_p_reads) as sum_data_index_p_reads,  sum( pool_async_data_reads + pool_async_index_reads) as sum_async_data_index_reads,  sum(pool_data_writes) as sum_pool_data_writes,  sum(pool_async_data_writes) as sum_pool_async_data_writes  FROM TABLE(MON_GET_TABLESPACE('',-2)) AS t  group by tbsp_name, tbsp_type  )  select tbsp_name, tbsp_type, tbsp_page_size, num_member,  sum_logical_reads, sum_physical_reads,  case when sum_logical_reads > 0 then decimal((1 - float(sum_physical_reads)/float(sum_logical_reads)) * 100.0, 5,2) else null end as bp_hit_ratio,  sum_data_index_p_reads, sum_async_data_index_reads,  case when sum_data_index_p_reads > 0 then decimal(float(sum_async_data_index_reads)*100/float(sum_data_index_p_reads),5,2) else null end as async_data_index_read_ratio,  sum_pool_data_writes, sum_pool_async_data_writes,  case when sum_pool_data_writes > 0 then decimal(float(sum_pool_async_data_writes)*100/float(sum_pool_data_writes),5,2) else null end as async_data_write_ratio  from tbsp_metrics" 

			printf '%s\n\n' "HEADER - $(date): Memory USED Metrics across hosts"
			db2 -v "with mon_mem as (  SELECT varchar(host_name, 20) AS host_name,  varchar(memory_set_type, 20) AS set_type,  varchar(memory_pool_type,20) AS pool_type,  varchar(db_name, 20) AS db_name,  memory_pool_used,  memory_pool_used_hwm  FROM TABLE(  MON_GET_MEMORY_POOL(NULL, CURRENT_SERVER, -2))  )  select host_name, set_type, pool_type, db_name,  sum(memory_pool_used)/1000000 as memory_pool_used_MB,  sum(memory_pool_used_hwm)/1000000 as memory_pool_used_hwm_MB  from mon_mem  group by grouping sets ((set_type, pool_type, db_name), (host_name))" 

			printf '%s\n\n' "HEADER - $(date): LOCK WAITS PER APPLICATION_HANDLE"
			db2 -v "select APPLICATION_HANDLE,  count(MEMBER) as NUM_MEMBER,  max(connection_start_time) as connection_start_time,  sum(LOCK_ESCALS) as LOCK_ESCALS,  sum(LOCK_TIMEOUTS) as LOCK_TIMEOUTS,  integer(sum(LOCK_WAIT_TIME)/1000) as LOCK_WAIT_TIME_SEC,  sum(LOCK_WAITS) as LOCK_WAITS,  sum(DEADLOCKS) as DEADLOCKS  from TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS t  group by APPLICATION_HANDLE" 

			printf '%s\n\n' "HEADER - $(date): Blocked LockWaits"
			db2 -v "select REQ_APPLICATION_HANDLE, REQ_MEMBER,  HLD_APPLICATION_HANDLE, HLD_MEMBER,  LOCK_OBJECT_TYPE, LOCK_MODE,  varchar(TABSCHEMA, 20) as TABSCHEMA,  varchar(TABNAME, 20) as TABNAME  from SYSIBMADM.MON_LOCKWAITS" 

			printf '%s\n\n' "HEADER - $(date): db2 SORT-HASH JOINS per apphdl"
			db2 -v "SELECT APPLICATION_HANDLE,  count(*) as NUM_MEMBER,  sum(TOTAL_SORTS) as SUM_TOTAL_SORTS,  sum(TOTAL_SECTION_SORTS) as SUM_TOTAL_SECTION_SORTS,  sum(SORT_OVERFLOWS) as SUM_SORT_OVERFLOWS,  sum(POST_THRESHOLD_SORTS) as SUM_POST_THRESHOLD_SORTS,  decimal(avg(TOTAL_SECTION_PROC_TIME)/1000.0,8,2) as AVG_TOTAL_SECTION_PROC_TIME_SEC,  decimal(avg(TOTAL_SECTION_SORT_PROC_TIME)/1000.0,8,2) as AVG_TOTAL_SECTION_SORT_PROC_TIME_SEC,  sum(TOTAL_HASH_JOINS) as SUM_TOTAL_HASH_JOINS,  sum(TOTAL_HASH_LOOPS) as SUM_TOTAL_HASH_LOOPS,  sum(HASH_JOIN_OVERFLOWS) as SUM_HASH_JOIN_OVERFLOWS,  sum(ROWS_MODIFIED) as SUM_ROWS_MODIFIED,  sum(POOL_DATA_WRITES) as SUM_POOL_DATA_WRITES  FROM TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS t  GROUP BY APPLICATION_HANDLE" 

			printf '%s\n\n' "HEADER - $(date): DataSKew per apphdl"
			db2 -v "SELECT APPLICATION_HANDLE,  count( MEMBER) as NUM_PARTITIONS,  avg(TOTAL_CPU_TIME/1000) as AVG_TOTAL_CPU_TIME_MS,  max(TOTAL_CPU_TIME/1000) as MAX_TOTAL_CPU_TIME_MS,  decimal(case when max(TOTAL_CPU_TIME) > 0 then (1- avg(TOTAL_CPU_TIME*1.0)*1.0/max(TOTAL_CPU_TIME)) else 0 end, 8,4) as SKEW_TOTAL_CPU_TIME,  decimal(case when avg(TOTAL_CPU_TIME) > 0 then max(TOTAL_CPU_TIME)*1.0/avg(TOTAL_CPU_TIME) else 1 end, 8, 4) as SLOWDOWN_CPU_TIME,  avg(TOTAL_RQST_TIME) as AVG_TOTAL_RQST_TIME_MS,  max(TOTAL_RQST_TIME) as MAX_TOTAL_RQST_TIME_MS,  decimal(case when max(TOTAL_RQST_TIME) > 0 then (1- avg(TOTAL_RQST_TIME)*1.0/max(TOTAL_RQST_TIME)) else 0 end, 8, 4) as SKEW_TOTAL_RQST_TIME,  avg(ROWS_READ) as AVG_ROWS_READ,  max(ROWS_READ) as MAX_ROWS_READ,  decimal( case when max(ROWS_READ) > 0 then (1- avg(ROWS_READ)*1.0/max(ROWS_READ)) else 0 end, 8, 4) as SKEW_ROWS_READ,  avg(ROWS_MODIFIED) as AVG_ROWS_WRITTEN,  max(ROWS_MODIFIED) as MAX_ROWS_WRITTEN,  decimal(case when max(ROWS_MODIFIED) > 0 then (1- avg(ROWS_MODIFIED)*1.0/max(ROWS_MODIFIED)) else 0 end, 8, 4) as SKEW_ROWS_WRITTEN  FROM TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS t  group by APPLICATION_HANDLE" 

			printf '%s\n\n' "HEADER - $(date): FCM Traffic per apphdl"
			db2 -v "SELECT APPLICATION_HANDLE,  MEMBER,  decimal(FCM_RECV_VOLUME*1.0 /(1024*1024), 12,3) as FCM_RECV_VOLUME_MB,  FCM_RECVS_TOTAL,  decimal(FCM_SEND_VOLUME*1.0 /(1024*1024), 12,3) as FCM_SEND_VOLUME_MB,  FCM_SENDS_TOTAL,  decimal( (POOL_DATA_L_READS+POOL_INDEX_L_READS+POOL_TEMP_DATA_L_READS+POOL_TEMP_INDEX_L_READS+POOL_TEMP_XDA_L_READS+POOL_XDA_L_READS)*16.0/1024, 12,3) as L_READS_VOLUME_MB  FROM TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS t  ORDER BY APPLICATION_HANDLE, MEMBER" 

			printf '%s\n\n' "HEADER - $(date): CURRENT SQL"
			db2 -v "select APPLICATION_HANDLE,  varchar(substr(APPLICATION_NAME, 1, 20),20) as APPLICATION_NAME,  varchar(substr(SESSION_AUTH_ID, 1, 20),20) as SESSION_AUTH_ID,  varchar(substr(CLIENT_APPLNAME, 1, 20),20) as CLIENT_APPLNAME,  varchar(substr(STMT_TEXT, 1, 100), 100) as STMT_TEXT  from SYSIBMADM.MON_CURRENT_SQL" 

			printf '%s\n\n' "HEADER - $(date): CPU USAGE PER APPLICATION_HANDLE"
			db2 -v "with connect_agg as (  SELECT t.APPLICATION_HANDLE,  count(t.member) as NUM_MEMBER,  decimal(avg(t.TOTAL_CPU_TIME*1.00)/1000000, 12,2) as AVG_TOTAL_CPU_TIME_SEC,  decimal(avg(t.TOTAL_WAIT_TIME*1.00)/1000, 12,2) as AVG_TOTAL_WAIT_TIME_SEC,  decimal(avg(t.TOTAL_RQST_TIME*1.00)/1000, 12,2) as AVG_TOTAL_RQST_TIME_SEC,  decimal(avg(t.TOTAL_SECTION_TIME*1.00)/1000,12,2) as AVG_TOTAL_SECTION_TIME_SEC,  decimal(avg(t.TOTAL_SECTION_PROC_TIME*1.00)/1000, 12,2) as AVG_TOTAL_SECTION_PROC_TIME_SEC  FROM TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS t  WHERE t.MEMBER > 0  GROUP BY t.APPLICATION_HANDLE  )  select c.APPLICATION_HANDLE, NUM_MEMBER,  AVG_TOTAL_CPU_TIME_SEC, AVG_TOTAL_WAIT_TIME_SEC, AVG_TOTAL_RQST_TIME_SEC,  AVG_TOTAL_SECTION_TIME_SEC, AVG_TOTAL_SECTION_PROC_TIME_SEC,  decimal(t0.TOTAL_APP_RQST_TIME/1000.0, 12,2) as TOTAL_APP_RQST_TIME_SEC,  case when t0.TOTAL_APP_RQST_TIME > 0 then decimal(AVG_TOTAL_CPU_TIME_SEC*100000/(t0.TOTAL_APP_RQST_TIME*2),12,2) end as CPU_USAGE_PCT,  varchar(substr(STMT_TEXT, 1, 100), 100) as STMT_TEXT  FROM connect_agg c  inner join TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS t0 on (c.APPLICATION_HANDLE = t0.APPLICATION_HANDLE)  left outer join SYSIBMADM.MON_CURRENT_SQL m on ( c.APPLICATION_HANDLE = m.APPLICATION_HANDLE )  where t0.MEMBER = t0.COORD_MEMBER" 

			printf '%s\n\n' "HEADER - $(date): TOP CPUTIME PER MEMBER PER EXECUTABLE_ID"
			db2 -v "SELECT EXECUTABLE_ID,  max(SECTION_TYPE) as SECTION_TYPE,  integer(avg(NUM_EXEC_WITH_METRICS)) as AVG_NUM_EXEC_WITH_METRICS,  decimal(sum(TOTAL_CPU_TIME)/(1000000.0*count(distinct member)),10,2) as TOTAL_CPU_TIME_SEC_PER_MEMBER,  decimal(sum(TOTAL_CPU_TIME)/sum(NUM_EXEC_WITH_METRICS)/1000000.0, 10,2) as AVG_CPU_TIME_SEC_PER_MEMBER,  max(varchar( substr(STMT_TEXT, 1, 100), 100)) as STMT_TEXT  FROM TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) as T  WHERE T.NUM_EXEC_WITH_METRICS > 0  GROUP BY EXECUTABLE_ID  ORDER BY TOTAL_CPU_TIME_SEC_PER_MEMBER" 

			printf '%s\n\n' "HEADER - $(date): IO MONITORING per application_handle"
			db2 "WITH READ_METRICS as (  SELECT APPLICATION_HANDLE,  count(*) as NUM_MEMBER,  sum(ROWS_READ) as ROWS_READ,  sum(POOL_DATA_L_READS) as POOL_DATA_L_READS,  sum(POOL_INDEX_L_READS) as POOL_INDEX_L_READS,  sum(POOL_TEMP_DATA_L_READS+POOL_TEMP_INDEX_L_READS) as POOL_TEMP_L_READS  FROM TABLE(MON_GET_CONNECTION(cast(NULL as bigint), -2)) AS m  where member > 0  group by application_handle  )  select r.APPLICATION_HANDLE, NUM_MEMBER,  r.ROWS_READ,  case when POOL_DATA_L_READS+POOL_TEMP_L_READS > 0 then decimal(r.ROWS_READ*1.00/(POOL_DATA_L_READS+POOL_TEMP_L_READS), 8,2) end as ROWS_READ_PER_POOL_L_READ,  POOL_DATA_L_READS, POOL_INDEX_L_READS, POOL_TEMP_L_READS,  varchar(STMT_TEXT,100) as STMT_TEXT  from READ_METRICS r left outer join SYSIBMADM.MON_CURRENT_SQL s  ON r.APPLICATION_HANDLE = s.APPLICATION_HANDLE  order by pool_data_l_reads desc" 

			printf '%s\n\n' "HEADER - $(date): Tablescans for queries"
			db2 -v "with montable as (  SELECT varchar(tabschema,20) as tabschema,  varchar(tabname,20) as tabname,  max(table_scans) as table_scans,  sum(rows_read) as table_rows_read  FROM TABLE(MON_GET_TABLE('','',-2)) AS t  WHERE tabschema not in ('SYSCAT', 'SYSIBM', 'SYSIBMADM', 'SYSPUBLIC', 'SYSSTAT', 'SYSTOOLS' ) and rows_read > 0 GROUP BY tabschema, tabname  )  select tabschema, tabname, max(table_scans) as table_scans, max(table_rows_read) as table_rows_read,  count(member) as NUM_MEMBER,  max(NUM_EXEC_WITH_METRICS) as STMT_NUM_EXECS_WITH_METRICS,  decimal(sum(TOTAL_ACT_TIME)/1000.00,10,2) as STMT_ACT_TIME_SEC,  sum(ROWS_READ) as STMT_ROWS_READ,  sum(POOL_DATA_L_READS+POOL_INDEX_L_READS++POOL_TEMP_DATA_L_READS+POOL_TEMP_INDEX_L_READS) as STMT_POOL_L_READS,  sum(POOL_DATA_L_READS) as STMT_POOL_DATA_L_READS,  sum(POOL_INDEX_L_READS) as STMT_POOL_INDEX_L_READS,  sum(POOL_TEMP_DATA_L_READS+POOL_TEMP_INDEX_L_READS) as STMT_POOL_TEMP_L_READS,  varchar(substr(s.stmt_text, 1,100),100) as stmt_text  from montable t,  TABLE(MON_GET_PKG_CACHE_STMT('D', null, null, -2)) as s  where rows_read > 0 and lcase(s.stmt_text) like '%' || lcase(trim(t.tabschema)) || '%' || '.%' || lcase(trim(t.tabname)) || '%'  group by t.tabschema, t.tabname, varchar(substr(s.stmt_text, 1,100),100)  order by stmt_rows_read "

			printf '%s\n\n' "HEADER - $(date): SYSTEM RESOURCES INFO"
			db2 -v "select current timestamp ts,* from table (sysproc.env_get_system_resources())"
			
			printf '%s\n\n' "HEADER - $(date): Collecting ~/sqllib/samples/perf/db2mon.sql"
			db2 -tvf ~/sqllib/samples/perf/db2mon.sql >> $OUTDIR/db2mon_report.txt
			
            printf '\n\n%s\n\n' "Collecting some db2pd data"

            tstamp=$( date "+%Y-%m-%d-%H.%M.%S" )

            RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` $rah db2pd -alldbp -db $DBNAME -wlocks $quote > db2pd_wlocks.txt.$tstamp 2>&1

            RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` $rah db2pd -alldbp -db $DBNAME -active -apinfo $quote > db2pd_apinfo.txt.$tstamp 2>&1

            RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` $rah db2pd -alldbp -agents $quote > db2pd_agents.txt.$tstamp 2>&1

            printf '\n\n%s\n\n' "HEADER - $(date): Top 20 active tables"
            db2 "declare global temporary table session.temp_active_tables as (  select current timestamp as curr_tstamp, sum( OVERFLOW_ACCESSES ) as OVERFLOW_ACCESSES, sum( ROWS_READ ) as ROWS_READ, sum( rows_inserted ) as rows_inserted, sum( rows_updated ) as rows_updated, sum( rows_deleted ) as rows_deleted, tabschema, tabname from table(mon_get_table(null,null,-2)) where tab_type = 'USER_TABLE' group by tabschema, tabname ) with data on commit preserve rows not logged" > /dev/null 2>&1
            db2 "commit" > /dev/null

            printf '%s\n\n' "HEADER - $(date): sleeping 30 seconds"
            sleep 30

			db2 -v "with current_active_tables ( curr_tstamp  , OVERFLOW_ACCESSES, ROWS_READ  , rows_inserted  , rows_updated , rows_deleted , tabschema  , tabname ) as ( select current timestamp as  curr_timestamp , sum(OVERFLOW_ACCESSES) as OVERFLOW_ACCESSES, sum( ROWS_READ ) as ROWS_READ  , sum(rows_inserted) as rows_inserted  , sum( rows_updated )  as rows_updated , sum( rows_deleted )  as rows_deleted , tabschema  , tabname from table( mon_get_table(null,null,-2)) where tab_type = 'USER_TABLE' group by tabschema, tabname with ur ) select substr(to_char( current timestamp , 'YYYY-MM-DD-HH24.MI.SS' ),1,19) as curr_time  , substr( a.tabschema,1,20) as schema , substr( a.tabname,1,45) as tabname  , substr( to_char( ( b.OVERFLOW_ACCESSES  - a.OVERFLOW_ACCESSES ), '999,999,999,999' ), 1, 16 ) as OVERFLOW_ACCESSES  , substr( to_char( ( b.ROWS_READ  - a.ROWS_READ ), '999,999,999,999' ), 1, 16 ) as ROWS_READ  , substr( to_char( ( b.rows_inserted  - a.rows_inserted ), '999,999,999,999' ), 1, 16 ) as rows_inserted  , substr( to_char( ( b.rows_updated - a.rows_updated ), '999,999,999,999' ), 1, 16 )  as rows_updated , substr( to_char( ( b.rows_deleted - a.rows_deleted ), '999,999,999,999' ), 1, 16 )  as rows_deleted , substr( to_char( int( ( b.OVERFLOW_ACCESSES - a.OVERFLOW_ACCESSES ) / timestampdiff( 2, to_char( current timestamp - a.curr_tstamp )) ), '999,999,999' ), 1,11) as overflow_rows_p_sec, substr( to_char( int( ( b.ROWS_READ - a.ROWS_READ ) / timestampdiff( 2, to_char( current timestamp - a.curr_tstamp )) ), '999,999,999' ), 1,11) as read_rows_p_sec  , substr( to_char( int( ( b.rows_inserted - a.rows_inserted ) / timestampdiff( 2, to_char( current timestamp - a.curr_tstamp )) ), '999,999,999' ), 1,11) as ins_rows_p_sec , substr( to_char( int( ( b.rows_updated  - a.rows_updated ) / timestampdiff( 2, to_char( current timestamp - a.curr_tstamp )) ), '999,999,999' ), 1,11)  as upd_rows_p_sec , substr( to_char( int( ( b.rows_deleted  - a.rows_deleted ) / timestampdiff( 2, to_char( current timestamp - a.curr_tstamp )) ), '999,999,999' ), 1,11)  as del_rows_p_sec , 		(b.OVERFLOW_ACCESSES - a.OVERFLOW_ACCESSES)+(b.ROWS_READ - a.ROWS_READ)+( b.rows_inserted- a.rows_inserted )+( b.rows_updated - a.rows_updated )+( b.rows_deleted - a.rows_deleted ) as totalcnt from session.temp_active_tables a, current_active_tables b where ( a.tabschema = b.tabschema or ( a.tabschema IS NULL and b.tabschema is NULL )) and ( a.tabname = b.tabname or ( a.tabname is NULL AND b.tabname is NULL)) and ( ( b.OVERFLOW_ACCESSES - a.OVERFLOW_ACCESSES ) > 0 OR ( b.ROWS_READ - a.ROWS_READ ) > 0 OR ( b.rows_inserted - a.rows_inserted ) > 0 or ( b.rows_updated - a.rows_updated ) > 0 or ( b.rows_deleted - a.rows_deleted ) > 0 ) union all select substr(to_char( current timestamp , 'YYYY-MM-DD-HH24.MI.SS' ),1,19)  as curr_time  , substr( b.tabschema,1,20)  as schema , substr( b.tabname,1,45)  as tabname  , substr( to_char( ( b.OVERFLOW_ACCESSES ), '999,999,999,999' ), 1, 16 ) as OVERFLOW_ACCESSES  , substr( to_char( ( b.ROWS_READ ), '999,999,999,999' ), 1, 16 ) as ROWS_READ  , substr( to_char( ( b.rows_inserted ), '999,999,999,999' ), 1, 16 ) as rows_inserted  , substr( to_char( ( b.rows_updated ), '999,999,999,999' ), 1, 16 )  as rows_updated , substr( to_char( ( b.rows_deleted ), '999,999,999,999' ), 1, 16 )  as rows_deleted , NULL as overflow_rows_p_sec, NULL as read_rows_p_sec  , NULL as ins_rows_p_sec , NULL as upd_rows_p_sec , NULL as del_rows_p_sec , 		OVERFLOW_ACCESSES+b.ROWS_READ+b.rows_inserted+b.rows_updated+b.rows_deleted as totalcnt from current_active_tables b where not exists ( select null from session.temp_active_tables a where ( a.tabschema = b.tabschema or ( a.tabschema IS NULL and b.tabschema is NULL )) and ( a.tabname = b.tabname or ( a.tabname is NULL AND b.tabname is NULL)) and ( ( b.OVERFLOW_ACCESSES - a.OVERFLOW_ACCESSES ) > 0 OR ( b.ROWS_READ - a.ROWS_READ ) > 0 OR ( b.rows_inserted - a.rows_inserted ) > 0 or ( b.rows_updated - a.rows_updated ) > 0 or ( b.rows_deleted - a.rows_deleted ) > 0 ) ) order by totalcnt desc fetch first 20 rows only with ur"
            printf '%s\n\n' "$(date): Taking latch information"

            RAHBUFNAME=rahout.`od -x /dev/urandom | head -1 | awk '{OFS=""; print $2$3$4$5$6$7}'` $rah db2pd -alldbp -latches -rep 2 3 $quote > db2pd_latches.txt.$tstamp 2>&1

            printf '%s\n\n' "$(date): Check the files db2pd_*.$tstamp"

            db2 terminate
             
		$DB2_POSTFIX
            } 2>&1 | tee $OUTDIR/$OUTPUTFILE 

            if [[ $NUMHOSTS > 1 ]]; then
            
              for ihost in $HOSTS ; 
              do
                COPYSCP "$ihost" "$DB2INSTDIR" "$tstamp" "$OUTDIR"
                COPYSCP "$ihost" "$DB2INSTDIR" "bin" "$OUTDIR"
                COPYSCP "$ihost" "$CWD" "$tstamp" "$OUTDIR"
                COPYSCP "$ihost" "$CWD" "bin" "$OUTDIR"
				COPYSCP "$ihost" "$PWD" "$tstamp" "$OUTDIR"
                COPYSCP "$ihost" "$PWD" "bin" "$OUTDIR"
				printf '\n\n%s\n\n' "Checking Ping connectivity between hosts" 2>&1 | tee -a $OUTDIR/$OUTPUTFILE 
				ping -v -D -c 4 $ihost 2>&1 | tee -a $OUTDIR/$OUTPUTFILE 
				printf '\n\n' 2>&1 | tee -a $OUTDIR/$OUTPUTFILE 
              done
            
            else          
				mv $DB2INSTDIR/*.$tstamp $OUTDIR 1> /dev/null 2>&1 
				mv $DB2INSTDIR/*.bin $OUTDIR 1> /dev/null 2>&1 
				mv $CWD/*.$tstamp $OUTDIR 1> /dev/null 2>&1 
				mv $CWD/*.bin $OUTDIR 1> /dev/null 2>&1 
				mv $PWD/*.$tstamp $OUTDIR 1> /dev/null 2>&1 
				mv $PWD/*.bin $OUTDIR 1> /dev/null 2>&1 
            fi
                      
            printf '\n\n%s\n\n' "$(date): The terminal output is captured in $OUTPUTFILE and diagnostics are in $OUTDIR"
        
         else

            retchk "$RTNC" "$RLINE" "db2 connect to $DBNAME" "$(hostname)" "Unable to connect to $DBNAME" 

  		 fi

	fi
    if [[ "x$QUICKEXPLAIN" != "x" || "x$QUICKALL" != "x" ]]; then

         if [[ $ISROOT == 1 ]] ; then
           printf '\n%s\n' "This option cannot be executed as ROOT user."
		   cleanup 
           exit 0
         fi

         isNumeric=$( echo $QUICKEXPLAIN | awk '{ if( match( $0, "^[0-9]+$" ) ) print 1; else print 0; }' )	 
         
         if [ "x$isNumeric" = "x1" ]; then

             QUICKEXPLAIN=$( echo $QUICKEXPLAIN | awk '{ print int( $0 ); }' )

             QUICKEXPLAIN=$( echo "$QUICKEXPLAIN*60" | bc )

             # IF QUICKEXPLAIN is set to number of mins
             cmd=$( echo "select application_handle, coord_partition_num, executable_id from table(mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) and timestampdiff(2, to_char( current timestamp - local_start_time )) > $QUICKEXPLAIN  and member = coord_partition_num order by timestampdiff(2, to_char( current timestamp - local_start_time)) desc fetch first 10 rows only " )
             
             printf '\n%s\n' "$(date): Looking for queries running for greater than $QUICKEXPLAIN seconds"
             
         else
             # IF QUICKEXPLAIN is set to SORT
             cmd=$( echo "with SORTMEM (SHEAPTHRESSHR, SHEAPMEMBER) AS (SELECT VALUE, MEMBER FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr'), APPSORTMEM( apphandle, appmember, coord_part_num, executable_id, alloc_sortmem) as ( select application_handle, member, coord_partition_num, executable_id, sum(sort_shrheap_allocated) from table( mon_get_activity(null,-2)) where ( activity_state = 'EXECUTING' or activity_state = 'IDLE' ) group by application_handle, member, coord_partition_num, executable_id  ) select apphandle, coord_part_num, executable_id from SORTMEM, APPSORTMEM where SHEAPMEMBER = appmember and alloc_sortmem > 0 order by alloc_sortmem desc fetch first 5 rows only" )
             printf '\n%s\n' "$(date): Explaining queries with highest sort heap consumption ( top 5 )"
             
         fi

         printf '\n%s\n' "$(date): Running query: $cmd"

         db2 "connect to $DBNAME"  > /dev/null 2>&1
		 
		 RTNC=$?
		 RLINE=$LINENO
		 
         if [ "$RTNC" -eq 0 ]; then
         
            db2 -x "$cmd" | while read rec
            do                                                    
                  apphandle=$( echo "$rec" | awk '{print $1 }' )
                  coord=$( echo $rec | awk '{print $2 }' )
                  execid=$( echo $rec | awk '{print $3 }' )
				  fmtexecid=$( echo $execid | tr -d "'" )
                  check_success=0

                  db2 connect to $DBNAME  > /dev/null 2>&1
                  db2 "call explain_from_section( $execid, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? )" > $OUTDIR/explain.$apphandle.$fmtexecid.$tstamp  2>&1
   
                  check_success=$( cat $OUTDIR/explain.$apphandle.$fmtexecid.$tstamp | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
                  
                  if [ $check_success -eq 0 ]; then

                      param_values=$( cat $OUTDIR/explain.$apphandle.$fmtexecid.$tstamp | grep -i "Parameter Value" | awk '{ print $NF; }' )
                      param1=$( echo $param_values | awk '{ print $1; }' )
                      param3=$( echo $param_values | awk '{ print $3; }' )
                      param4=$( echo $param_values | awk '{ print $4; }' )
                      param5=$( echo $param_values | awk '{ print $5; }' )                    
                      fmtexecid=$( echo $execid | tr -d "'" )

                      db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $OUTDIR/exfmt.$apphandle.$fmtexecid.txt.$tstamp  2>&1

                      printf '\n%s\n\n' "$(date): Collected explain of Apphandle: $apphandle, Execid: $execid"
                  fi
            done

            check_exfmt=$( find $OUTDIR -maxdepth 1 -name "exfmt*" -mmin -15 -type f 2> /dev/null | wc -l )

            if [ $check_exfmt -gt 0 ]; then           
               printf '%s\n' "$(date): Pls. collect the exfmt files generated in this directory $OUTDIR . The format of file is exfmt.<apphandle>.<execid>.txt.tstamp"

            else
               printf '\n\n%s\n' "$(date): Could not find any queries satisfying criteria"
            fi

         else

            retchk "$RTNC" "$RLINE" "db2 connect to $DBNAME" "$(hostname)" "Unable to connect to $DBNAME"
			
         fi
         db2 terminate > /dev/null 2>&1
   
	fi
    if [[ "x$QUICKEXPLAINAPP" != "x" ]]; then
         
         if [[ $ISROOT == 1 ]] ; then
           printf '\n%s\n' "This option cannot be executed as ROOT user."
		   cleanup 
           exit 0
         fi

         APPHANDLES=$( echo $QUICKEXPLAINAPP | awk -F, '{ for( i = 1; i <= NF; i++ ) print $i; }' )

         db2 connect to $DBNAME > /dev/null 2>&1
         RTNC=$?
		 RLINE=$LINENO
		 
         if [ "$RTNC" -eq 0 ]; then

             for app in `echo $APPHANDLES`
             do
                cmd=$( echo "select application_handle, uow_id, activity_id, coord_partition_num, executable_id from table(mon_get_activity($app,-2)) where member = coord_partition_num order by activity_id desc with ur" )

                printf '\n%s\n' "$(date): Running query: $cmd"

                db2 -x $cmd | while read rec
                do
                     apphandle=$( echo $rec | awk '{ print $1; }' )
                     uowid=$( echo $rec | awk '{ print $2; }' )
                     actid=$( echo $rec | awk '{ print $3; }' )
                     coord=$( echo $rec | awk '{ print $4; }' )
                     execid=$( echo $rec | awk '{ print $5; }' )
					 fmtexecid=$( echo $execid | tr -d "'" )

                     check_success=0

                     db2 connect to $DBNAME  > /dev/null 2>&1

                     db2 "call explain_from_section( $execid, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? )" >  $OUTDIR/explain.$apphandle.$fmtexecid.$tstamp  2>&1

                     check_success=$( cat  $OUTDIR/explain.$apphandle.$fmtexecid.$tstamp | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )

                     if [ $check_success -eq 0 ]; then

                        param_values=$( cat  $OUTDIR/explain.$apphandle.$fmtexecid.$tstamp | grep -i "Parameter Value" | awk '{ print $NF; }' )
                        param1=$( echo $param_values | awk '{ print $1; }' )
                        param3=$( echo $param_values | awk '{ print $3; }' )
                        param4=$( echo $param_values | awk '{ print $4; }' )
                        param5=$( echo $param_values | awk '{ print $5; }' )						
                        fmtexecid=$( echo $execid | tr -d "'" )
						
                        db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $OUTDIR/exfmt.$apphandle.$uowid.$actid.$fmtexecid.txt.$tstamp  2>&1

                        printf '\n%s\n\n' "$(date): Collected explain of Apphandle: $apphandle, Execid: $execid"
                     fi
                 done
             done

             check_exfmt=$( find $OUTDIR -maxdepth 1 -name "exfmt*" -mmin -15 -type f 2> /dev/null  | wc -l )

             if [ $check_exfmt -gt 0 ]; then
                 printf '%s\n' "$(date): Pls. collect the exfmt files generated in this directory $OUTDIR . The format of file is exfmt.<apphandle>.<uow_id>.<activity_id>.<execid>.txt.tstamp"
             else
                 printf '\n\n%s\n' "$(date): No exfmt files generated in the last 15 mins to collect.. "               
             fi

         else
            retchk "$RTNC" "$RLINE" "db2 connect to $DBNAME" "$(hostname)" "Unable to connect to $DBNAME"			
         fi
	fi
	
    if [[ "x$QUICKTABLESPACES" != "x" || "x$QUICKALL" != "x" ]]; then


         db2 connect to $DBNAME > /dev/null 2>&1
         RTNC=$?
		 RLINE=$LINENO
		 
         if [ "$RTNC" -eq 0 ]; then
			[[ "x$QUICKALL" != "x" ]] &&  OUTPUTFILE=$( echo "db_monitor.txt" )
            OUTPUTFILE=$( echo $OUTPUTFILE".tablespaces.$( date "+%Y-%m-%d-%H.%M.%S" )" )

            {
$DB2_PREFIX <<- $DB2_POSTFIX

            printf '\n\n%s\n\n' "Tablespace info across ALL members"
           
            if [ "x$DEBUG" = "x1" ]; then
               set -xv
            fi

            db2 connect to $DBNAME 

			printf '\n\n%s\n\n' "Report on Tablespace details"
            db2 -v "select current timestamp as timestamp, member, cast(substr(tbsp_name,1,32) as varchar(32)) as tbsp_name, tbsp_id as tbsp_id, substr(char(tbsp_page_size),1,5)  as pgsz, substr(tbsp_type,1,4) as tbsp_type, substr(tbsp_state,1,10) as state, tbsp_used_pages, decimal( (double(tbsp_used_pages) * tbsp_page_size) / 1024 / 1024, 10, 2 ) as tbsp_mb_used, decimal( (double(tbsp_page_top) * tbsp_page_size) / 1024 / 1024, 10, 2) as tbsp_mb_hwm, tbsp_extent_size as tbsp_extent_size, ( case fs_caching when 2 then 'Default off' when 1 then 'Explicit off' else 'Explicit on' end) as fs_caching,  tbsp_prefetch_size as tbsp_prefetch_size, tbsp_usable_pages, decimal( decimal(double(tbsp_used_pages)/double(tbsp_usable_pages),10,5)*100,5,1) as pct_used from table( mon_get_tablespace( null, -2)) order by member asc, tbsp_used_pages desc with UR"

            printf '\n\n%s\n\n' "Report on extent movement"
            db2 -v "select current timestamp as timestamp, member, substr(tbsp_name,1,32) as tbsp_name, member, current_extent, last_extent, num_extents_moved, num_extents_left, total_move_time as total_move_time_ms from table( mon_get_extent_movement_status( null, -2 ))"

            printf '\n\n%s\n\n' "Tablespaces which can possibly be reduced in size"
            db2 -v "SELECT   substr('ALTER TABLESPACE ' || tbsp_name || ' REDUCE MAX',1,70) ALTER_STMT,VARCHAR(tbsp_name,  30) AS TBSP_NAME,decimal( ( sum ( ( tbsp_page_top - tbsp_used_pages ) * tbsp_page_size )  /(1024*1024*1024)),10,2) as possible_reduction_gb, cast ((sum(tbsp_free_pages )* 32768.0/1073741824.0) as decimal(10,2))  as gb_free ,cast ((sum(tbsp_used_pages )* 32768.0/1073741824.0) as decimal(10,2))  as gb_used,cast ((sum(tbsp_total_pages )* 32768.0/1073741824.0) as decimal(10,2))  as gb_total FROM     TABLE(mon_get_tablespace('', -2)) AS t WHERE    reclaimable_space_enabled = 1 AND      (tbsp_pending_free_pages + tbsp_free_pages) > 0 GROUP BY VARCHAR(tbsp_name,  30), 'ALTER TABLESPACE ' || tbsp_name || ' REDUCE MAX' order by 3 desc"
            db2 terminate 
            
$DB2_POSTFIX
            
            } 2>&1 | tee $OUTDIR/$OUTPUTFILE 

         else

            retchk "$RTNC" "$RLINE" "db2 connect to $DBNAME" "$(hostname)" "Unable to connect to $DBNAME"
			
         fi

	fi
    if [ "x$QUICKEXFMT" != "x" ]; then

         if [[ $ISROOT == 1 ]] ; then
           printf '\n%s\n' "This option cannot be executed as ROOT user."
		   cleanup
           exit 0
         fi
         
         if [[ -f "$QUICKEXFMT" ]]; then       # IF ITS A FILE
		 
			rc=$( db2 connect to $DBNAME > /dev/null 2>&1; db2 -v "set current explain mode explain"; db2 -v "set current explain snapshot explain"; db2 -tf $QUICKEXFMT 2>/dev/null )
			nosemicolon=$( echo $rc | awk '/End of file reached while reading the command/ { print 1; }' )
			success=$( echo $rc | awk '/The statement was not executed as only Explain information requests are being processed/ { print 1; }' )

			if [ "x$nosemicolon" = "x1" ]; then

				printf '\n%s\n' "No semi-colon at the end of SQL statement. Pls fix the file $QUICKEXFMT and re-run"         
				db2 terminate > /dev/null 2>&1
				cleanup
				exit 0

			elif [ "x$success" = "x1" ]; then
              
				printf '\n%s\n' "$(date): Running db2exfmt - Output: $OUTDIR/exfmt.$(basename ${QUICKEXFMT}) "
				db2exfmt -d $DBNAME -1 -o $OUTDIR/exfmt.$(basename ${QUICKEXFMT}) 
				db2 terminate > /dev/null 2>&1              	
			fi	
		 
		 elif [[ $QUICKEXFMT =~ "x'" || $QUICKEXFMT =~ "X'" ]] ; then    # EXECUTABLE_ID

			[[ $ecl1_SET -eq "1" ]] && printf '\n%s\n\n' "$(date): Ignored -ecl1 Y option as its only valid for explain from file. You can collect cl0 using -ecl0 Y option."
		 
			execid=$( echo $QUICKEXFMT | awk '{print tolower($0)}')
			fmtexecid=$( echo $execid | tr -d "'" )
			
			db2 connect to $DBNAME  > /dev/null 2>&1
            db2 "call explain_from_section( $execid, 'M', NULL, -1 , NULL, ?, ?, ?, ?, ? )" > $OUTDIR/explain.$fmtexecid 2>&1
   
            check_success=$( cat $OUTDIR/explain.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
                  
            if [ $check_success -eq 0 ]; then

                param_values=$( cat $OUTDIR/explain.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' )
                param1=$( echo $param_values | awk '{ print $1; }' )
                param3=$( echo $param_values | awk '{ print $3; }' )
                param4=$( echo $param_values | awk '{ print $4; }' )
                param5=$( echo $param_values | awk '{ print $5; }' )                    
            
                db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $OUTDIR/exfmt.$fmtexecid.txt  2>&1
                printf '\n%s\n\n' "$(date): Collected explain of Execid: $execid in file: $OUTDIR/exfmt.$fmtexecid.txt"
            else 
				printf '\n%s\n\n' "$(date): Cannot collect explain of Execid: $execid. See file $OUTDIR/explain.$fmtexecid for more details."
			fi
			
		 elif [[ $QUICKEXFMT == "SP" || $QUICKEXFMT == "sp" ]] ; then    # STORED PROCEDURE
			
			[[ $ecl1_SET -eq "1" ]] && printf '\n%s\n\n' "$(date): Ignored -ecl1 Y option as its only valid for explain from file. You can collect cl0 using -ecl0 Y option."
			
			 printf '\n\n'
			 read -p "Enter Stored Procedure Schama Name: " XPKGSCHEMA			 
			 printf '\n\n'
			 read -p "Enter Stored Procedure Name: " XPROCEDURENAME
			 
			 if [[ -z $XPROCEDURENAME || -z $XPKGSCHEMA ]]; then
				printf '\n%s\n\n' "Schema Name AND Procedure Name cannot be empty. Exiting!!"
				cleanup
			    exit 0	
			 fi
			 PKGSCHEMA=$(echo "$XPKGSCHEMA" | tr '[:lower:]' '[:upper:]')
			 PROCEDURENAME=$(echo "$XPROCEDURENAME" | tr '[:lower:]' '[:upper:]')
			 
			 printf '\n%s\n\n' "$(date): Collecting Explain for Stored Procedure: $PKGSCHEMA.$PROCEDURENAME"
			 
  			 db2 connect to $DBNAME  > /dev/null 2>&1
			 db2 -v "select * from SYSCAT.ROUTINES where ROUTINESCHEMA = '$PKGSCHEMA' and ROUTINENAME = '$PROCEDURENAME' WITH UR" > $OUTDIR/"$PKGSCHEMA.$PROCEDURENAME.syscat.routines.out"
			 db2 -v "select * from SYSCAT.STATEMENTS where PKGSCHEMA = '$PKGSCHEMA' and PKGNAME IN (SELECT DEPS.BNAME PACKAGE FROM SYSIBM.SYSDEPENDENCIES DEPS, SYSIBM.SYSROUTINES PROCS WHERE DEPS.DTYPE = 'F' AND DEPS.BTYPE  = 'K' AND PROCS.SPECIFICNAME  = DEPS.DNAME AND PROCS.ROUTINESCHEMA = DEPS.DSCHEMA AND PROCS.ROUTINESCHEMA = '$PKGSCHEMA' AND PROCS.ROUTINENAME  = '$PROCEDURENAME' ) WITH UR" > $OUTDIR/"$PKGSCHEMA.$PROCEDURENAME.syscat.statements.out"
			 db2 -x "select PKGSCHEMA,PKGNAME,SECTNO from SYSCAT.STATEMENTS where PKGSCHEMA = '$PKGSCHEMA' and PKGNAME IN (SELECT DEPS.BNAME PACKAGE FROM SYSIBM.SYSDEPENDENCIES DEPS, SYSIBM.SYSROUTINES PROCS WHERE DEPS.DTYPE = 'F' AND DEPS.BTYPE  = 'K' AND PROCS.SPECIFICNAME  = DEPS.DNAME AND PROCS.ROUTINESCHEMA = DEPS.DSCHEMA AND PROCS.ROUTINESCHEMA = '$PKGSCHEMA' AND PROCS.ROUTINENAME  = '$PROCEDURENAME' ) WITH UR" > $OUTDIR/"$PKGSCHEMA.$PROCEDURENAME.SECTNO.out"
			 db2 terminate > /dev/null 2>&1
			 
			 if [[ ! -s $OUTDIR/"$PKGSCHEMA.$PROCEDURENAME.SECTNO.out" ]]; then # FILE IS EMPTY
				
				printf '\n%s\n\n' "$(date): Procedure $PKGSCHEMA.$PROCEDURENAME does not have any dependend package. Check files $OUTDIR/$PKGSCHEMA.$PROCEDURENAME.syscat.routines.out and  $OUTDIR/$PKGSCHEMA.$PROCEDURENAME.syscat.statements.out for more details."
				cleanup
			    exit 0	
			 else 
				 cat $OUTDIR/"$PKGSCHEMA.$PROCEDURENAME.SECTNO.out" | while read rec 
				 do
				   pschema=$(echo $rec | awk '{print $1}')
				   pname=$(echo $rec | awk '{print $2}')
				   psno=$(echo $rec | awk '{print $3}')
				   
				   db2 connect to $DBNAME  > /dev/null 2>&1
				   db2 "CALL EXPLAIN_FROM_CATALOG( '$pschema', '$pname', '', $psno , NULL, ?, ?, ?, ?, ? )" > $OUTDIR/"explain_catalog.$pschema.$pname.$psno.out" 2>&1
				   db2 "SELECT DEPS.BSCHEMA SCHEMA,PROCS.ROUTINENAME PROCEDURE,DEPS.BNAME PACKAGE,PROCS.VALID VALID,PROCS.TEXT TEXT FROM SYSIBM.SYSDEPENDENCIES DEPS, SYSIBM.SYSROUTINES PROCS WHERE DEPS.DTYPE = 'F' AND   DEPS.BTYPE = 'K' AND   PROCS.SPECIFICNAME  = DEPS.DNAME AND   PROCS.ROUTINESCHEMA = DEPS.DSCHEMA AND PROCS.ROUTINESCHEMA = '$pschema' AND DEPS.BNAME = '$pname' ORDER   BY 1,2 WITH UR" > $OUTDIR/"db2_routine_text.$pschema.$pname.out" 2>&1
				   db2 terminate > /dev/null 2>&1  

				   check_success=$( cat $OUTDIR/"explain_catalog.$pschema.$pname.$psno.out" | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
								  
				   if [ $check_success -eq 0 ]; then

					  param_values=$( cat $OUTDIR/"explain_catalog.$pschema.$pname.$psno.out" | grep -i "Parameter Value" | awk '{ print $NF; }' )
					  param1=$( echo $param_values | awk '{ print $1; }' )
					  param3=$( echo $param_values | awk '{ print $3; }' )
					  param4=$( echo $param_values | awk '{ print $4; }' )
					  param5=$( echo $param_values | awk '{ print $5; }' )                    

					  db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $OUTDIR/"exfmt.$pschema.$pname.$psno.txt" 2>&1

					  printf '\n%s\n\n' "$(date): Collected explain of $pschema.$pname.$psno in file: $OUTDIR/exfmt.$pschema.$pname.$psno.txt"
				   fi
				 done
			 fi
			 
		 else 	# Error
			printf '\n%s\n' "File: $QUICKEXFMT does not exist OR $QUICKEXFMT is not a valid executable_id OR $QUICKEXFMT should be SP to explain a stored procedure. Exiting!! "
			cleanup
			exit 0			
		 fi
		 
		 if [[ $ecl1_SET -eq "1" && -f "$QUICKEXFMT" ]]; then
		  
			db2supportCMD="db2support . -s -d $DBNAME -cl 1 -sf $QUICKEXFMT -localhost -o $OUTDIR/db2support_cl1.$QUICKEXFMT.zip"			  
			printf '\n%s\n' "$(date): Running: $db2supportCMD "
			( eval " $db2supportCMD "  ) >> $OUTDIR/db2support_cl1.$QUICKEXFMT.log 2>&1 &
			childpiddb2support=$( echo $! )
			echo $childpiddb2support >> $TMPFILE
			log "$db2supportCMD PID: $childpiddb2support"
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "$db2supportCMD PID: $childpiddb2support"
		
			printf '\n%s\n' "$(date): db2support command PID: $( cat $TMPFILE | tr '\n' ' ' ) . Waiting for the db2support command to complete. You can see progress by tail -f $OUTDIR/db2support_cl1.$QUICKEXFMT.log" 
			#RefreshRunningpids  "$TMPFILE"
			waitforpid "$TMPFILE"
			printf '\n%s\n' "$(date): db2support command completed. Check log file for details: $OUTDIR/db2support_cl1.$QUICKEXFMT.log" 
		 fi
		 
		 if [[ $ecl0_SET -eq "1" ]]; then
		  
			  db2supportCMD="db2support . -s -d $DBNAME -cl 0 -localhost -o $OUTDIR/db2support_cl0.$QUICKEXFMT.zip"			  
			  printf '\n%s\n' "$(date): Running: $db2supportCMD "
			  ( eval " $db2supportCMD "  ) >> $OUTDIR/db2support_cl0.$QUICKEXFMT.log 2>&1 &
			  childpiddb2support=$( echo $! )
			  echo $childpiddb2support >> $TMPFILE
			  log "$db2supportCMD PID: $childpiddb2support"
			  [[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "$db2supportCMD PID: $childpiddb2support"
			  
			  printf '\n%s\n' "$(date): db2support command PID: $( cat $TMPFILE | tr '\n' ' ' ) . Waiting for the db2support command to complete. You can see progress by tail -f $OUTDIR/db2support_cl0.$QUICKEXFMT.log" 
			  #RefreshRunningpids  "$TMPFILE"
			  waitforpid "$TMPFILE"
			  printf '\n%s\n' "$(date): db2support command completed. Check log file for details: $OUTDIR/db2support_cl0.$QUICKEXFMT.log" 
		 fi		
		 printf '\n%s\n' "$(date): Data collected in directory $OUTDIR ."
		  
	fi
    
	if [ "x$QUICKTRACE" != "x" ]; then

         if [[ $ISROOT == 1 ]] ; then
           printf '\n%s\n' "This option cannot be executed as ROOT user."
		   cleanup
           exit 0
         fi

         checkifCDE=$( db2set | grep "DB2_WORKLOAD=" | awk '{ if( match($0,"ANALYTICS")) print 1; else print 0; } END { if (NR==0) print 0 ; else 1; } ' )
         
		 if [[ $ttableorg_SET -eq 0 ]]; then
		 
			 if [[ $checkifCDE -eq 1 ]]; then
				DTABLEORG="C"    
			 else
			   DTABLEORG="R"
			 fi
			 printf '\n\n'
			 read -t 20 -n 1 -p "Enter Table Organization in (R = ROW, C = COLUMN) (Default: $DTABLEORG {if not entered in 20 seconds}): " TTABLEORG
			 TTABLEORG=${TTABLEORG:-$DTABLEORG}
			 
			 if [[ $TTABLEORG != 'C' && $TTABLEORG != 'c' && $TTABLEORG != 'R' && $TTABLEORG != 'r' ]]; then
				printf '\n\n%s' "$(date): TTABLEORG: $TTABLEORG is invalid!. Can only be C or R. Defaulting to R."
			 fi
											   
			 printf '\n\n'
		 fi
         
		 if [[ $ttimeout_SET -eq 0 ]]; then
			 
			 printf '\n\n'
			 read -t 20 -p "Enter query timeout (Default: $TTIMEOUT {if not entered in 20 seconds}): " TTIMEOUT			 
			 TTIMEOUT=${TTIMEOUT:-600}
			 printf '\n\n'
			 
			 if [[ $( is_int "$TTIMEOUT" ) != 0 ]]; then
				printf '\n\n%s\n' "$(date): Setting default query timeout -ttimeout for -trace option to 600 seconds"
				TTIMEOUT=600
			 fi
		 fi

		 db2 connect to $DBNAME > /dev/null 2>&1
		 db2 -v set current explain mode explain
		 db2 -v set current explain snapshot explain
		 db2 -tvf $QUICKTRACE
		 db2 -v set current explain mode no
		 db2exfmt -d $DBNAME -1 -o $OUTDIR/$(basename ${QUICKTRACE}).exfmt
		 db2 terminate > /dev/null 2>&1

		 if [[ $tdb2batch_SET -eq 1 ]] ; then  #DB2BATCH
			
			printf '\n\n%s\n' "$(date): Appending db2batch options SYSPROC.WLM_SET_CLIENT_INFO and DBMS_ALERT.SLEEP to the file $QUICKTRACE ."
			printf '%s\n' "$(date): This is needed as when we run via db2batch, we sleep for 30 seconds which gives us time to start the db2trace for db2batch apphdl"
			
			echo -e "call DBMS_ALERT.SLEEP(30);\n$(cat $QUICKTRACE)" > $QUICKTRACE ; retchk "$?" "$LINENO" " echo -e call DBMS_ALERT.SLEEP(30) " "$(hostname)" "Cannot edit file: $QUICKTRACE"
			echo -e "CALL SYSPROC.WLM_SET_CLIENT_INFO(NULL, NULL, 'USER_ACTUALS', 'USER_ACTUALS', NULL); \n$(cat $QUICKTRACE)" > $QUICKTRACE ; retchk "$?" "$LINENO" " echo -e CALL SYSPROC.WLM_SET_CLIENT_INFO(NULL, NULL, 'USER_ACTUALS', 'USER_ACTUALS', NULL) " "$(hostname)" "Cannot edit file: $QUICKTRACE"
			
			[[ "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): Added following lines to file:  $QUICKTRACE" 
			[[ "x$VERBOSE" = "x1" ]] && cat $QUICKTRACE | head -2 
			
			if [[ $tdb2evmon_SET -eq 1 ]] ; then  #EVENT MONITOR IS SET
				
				db2 connect to $DBNAME > /dev/null 2>&1
				
				printf '\n\n%s\n' "$(date): Creating event monitor: USER_ACTUALS and enabling it."
				db2 -v "create event monitor USER_ACTUALS for activities write to table manualstart"
				db2 -v "set event monitor USER_ACTUALS state 1"				
				db2 -v "update database configuration using section_actuals base"
				db2 -v "Alter workload USER_ACTUALS DISABLE "
				db2 -v "drop workload USER_ACTUALS "
				db2 -v "create workload USER_ACTUALS current client_acctng('USER_ACTUALS') collect activity data ON ALL MEMBERS with details, section include actuals base"
				db2 -v "grant usage on workload USER_ACTUALS to public"
				db2 terminate > /dev/null 2>&1
			fi
			
			printf '\n\n%s\n' "$( date ): Calling db2batch now "
			
			TTIMEOUT=$(( TTIMEOUT + 30 ))  # Adding 30 seconds due to SLEEP 30
			
			db2batch -d $DBNAME -f $QUICKTRACE -i complete -iso CS -o p 5 o 5 r 0 -r $OUTDIR/QUICKTRACE.DB2BATCH.REPORT  > $OUTDIR/QUICKTRACE.DB2BATCH.OUT 2>&1 &
			childpidbatch=$!                       
			echo $childpidbatch >> $TMPFILE      
			log "db2batch PID: $childpidbatch"
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "db2batch PID: $childpidbatch"
			printf '%s\n' "$(date): DB2BATCH PID: `cat $TMPFILE`"
			printf '\n\n'
			ps -elf | grep -w $childpidbatch | grep -v grep
			printf '\n\n'
					
			XDATA=$( db2 list applications | grep -w db2batch | grep -iw $DBNAME | grep -iw $RUN_USER )
			apphdl=$( echo $XDATA | awk '{print $3}' )
			appid=$( echo $XDATA | awk '{print $4}' )

			
			[[ "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): Full Query file : $QUICKTRACE"  
			[[ "x$VERBOSE" = "x1" ]] && cat $QUICKTRACE
			
			[[ "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): Deleting 1st 2 lines from file:  $QUICKTRACE"  
			
			sed -i -e 1,2d $QUICKTRACE ; retchk "$?" "$LINENO" " sed -i -e 1,2d $QUICKTRACE " "$(hostname)" "Cannot edit file: $QUICKTRACE"
			
			[[ "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): After delete of 1st two lines: $QUICKTRACE"  
			[[ "x$VERBOSE" = "x1" ]] && cat $QUICKTRACE | head -2 
			
			printf '\n\n%s\n' "`date`: DB2BATCH: Starting trace on apphandle: $apphdl appid: $appid Timeout: $TTIMEOUT (Added 30 seconds due to sleep) TTableORG: $TTABLEORG "

			( eval "db2trc off $Db2trcMemAll" ) > /dev/null 2>&1

			if [[ $TTABLEORG == "C" || $TTABLEORG == "c" ]]; then
						
				( eval "db2trc on -m CDE_PERF_TRACE -t -apphdl $apphdl $Db2trcMemAll" )
			else
				( eval "db2trc on -l 512m -t -apphdl $apphdl $Db2trcMemAll" )
			fi
			
			printf '\n\n%s\n' "`date`: DB2BATCH: APPID: $appid  "
			check_if_query_still_running "$TTABLEORG" "$TMPFILE" "$OUTDIR" "$TTIMEOUT" "$(basename ${QUICKTRACE})" "$appid" "$apphdl" "$tdb2batch_SET" "$tdb2evmon_SET"
			
			 
		 else  # NORMAL RUN NO PARAMETER MARKERS
         			
			if [[ $tdb2evmon_SET -eq 1 ]] ; then  #EVENT MONITOR IS SET
				
				printf '\n\n%s\n' "$(date): Appending SYSPROC.WLM_SET_CLIENT_INFO to the file $QUICKTRACE ."
				echo -e "CALL SYSPROC.WLM_SET_CLIENT_INFO(NULL, NULL, 'USER_ACTUALS', 'USER_ACTUALS', NULL); \n$(cat $QUICKTRACE)" > $QUICKTRACE ; retchk "$?" "$LINENO" " echo -e CALL SYSPROC.WLM_SET_CLIENT_INFO(NULL, NULL, 'USER_ACTUALS', 'USER_ACTUALS', NULL) " "$(hostname)" "Cannot edit file: $QUICKTRACE"
			
				[[ "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): Full Query file : $QUICKTRACE"  
				[[ "x$VERBOSE" = "x1" ]] && cat $QUICKTRACE
			
				db2 connect to $DBNAME > /dev/null 2>&1
				
				printf '\n\n%s\n' "$(date): Creating event monitor: USER_ACTUALS and enabling it."
				db2 -v "create event monitor USER_ACTUALS for activities write to table manualstart"
				db2 -v "set event monitor USER_ACTUALS state 1"				
				db2 -v "update database configuration using section_actuals base"
				db2 -v "Alter workload USER_ACTUALS DISABLE "
				db2 -v "drop workload USER_ACTUALS "
				db2 -v "create workload USER_ACTUALS current client_acctng('USER_ACTUALS') collect activity data ON ALL MEMBERS with details, section include actuals base"
				db2 -v "grant usage on workload USER_ACTUALS to public"
				db2 terminate > /dev/null 2>&1
				
			fi

			db2 connect to $DBNAME 
			
			apphdl=$( db2 -x "values mon_get_application_handle()" )
			appid=$( db2 -x "values mon_get_application_id()" )
			
			appid=$( echo $appid | awk '{$1=$1;print}' )
			apphdl=$( echo $apphdl | awk '{ print int( $0 ); }' )	
			
			printf '\n\n%s\n' "`date`: Starting trace on appid: $appid apphandle: $apphdl Timeout: $TTIMEOUT TTableORG: $TTABLEORG "	

			 log "db2trc off $Db2trcMemAll"
			( eval "db2trc off $Db2trcMemAll" ) > /dev/null 2>&1			
			
			if [[ $TTABLEORG == "C" || $TTABLEORG == "c" ]]; then
			
				log "db2trc on -m CDE_PERF_TRACE -t -apphdl $apphdl $Db2trcMemAll"
			   ( eval "db2trc on -m CDE_PERF_TRACE -t -apphdl $apphdl $Db2trcMemAll" )
			else
				log "db2trc on  -l 512m -t -apphdl $apphdl $Db2trcMemAll"
			   ( eval "db2trc on  -l 512m -t -apphdl $apphdl $Db2trcMemAll" )
			fi

			echo "`date`: Starting query in $QUICKTRACE"
					
			db2 -tf $QUICKTRACE > /dev/null 2>&1 & 
			childpiddb2=$!                       
			echo $childpiddb2 >> $TMPFILE            
			log "db2 -tf $QUICKTRACE PID: $childpiddb2"
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] &&  echo "db2 -tf $QUICKTRACE PID: $childpiddb2"
			printf '\n%s\n' "$(date): Query PID: `cat $TMPFILE`"	
			printf '\n\n'
			ps -elf | grep -w $childpiddb2 | grep -v grep
			printf '\n\n'			
			
			sleep 5   # SLEEPING for 5 seconds to make sure the query is executed before editting the file.
			
			if [[ $tdb2evmon_SET -eq 1 ]] ; then  #EVENT MONITOR IS SET
				[[ "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): Deleting 1st line from file:  $QUICKTRACE"  			
				sed -i -e 1,1d $QUICKTRACE ; retchk "$?" "$LINENO" " sed -i -e 1,2d $QUICKTRACE " "$(hostname)" "Cannot edit file: $QUICKTRACE"			
				[[ "x$VERBOSE" = "x1" ]] && printf '\n\n%s\n' "$(date): After delete of 1st lines: $QUICKTRACE"  
				[[ "x$VERBOSE" = "x1" ]] && cat $QUICKTRACE | head -1
			fi
			
			check_if_query_still_running "$TTABLEORG" "$TMPFILE" "$OUTDIR" "$TTIMEOUT" "$(basename ${QUICKTRACE})" "$appid" "$apphdl" "$tdb2batch_SET" "$tdb2evmon_SET"
			
			db2 terminate > /dev/null 2>&1
			
		 fi
	fi	 

	if [[ "x$QUICKWATCH" != "x" ]]; then
	
	   if [[ $ISROOT == 1 ]] ; then
           printf '\n%s\n' "This option cannot be executed as ROOT user."
		   cleanup
           exit 0
       fi
	   
	   echo "`date`: Starting to watch (24 hours) query: $QUICKWATCH "
       log "Starting to watch (24 hours) query: $QUICKWATCH "

       log "Data will be dumped in $OUTDIR. "
       echo "`date`: Data will be dumped in $OUTDIR"
	  	  
	   ## WAIT FOR QUERY TO EXECUTE
   	   QUERYFOUND=0
	   start_time=$(date +%s)
	   cur_time=$(date +%s)
	   elapsed=$(( cur_time - start_time ))
	   
	   db2 connect to $DBNAME
	   
	   while [[ $QUERYFOUND -lt 1 && $elapsed -lt 86400 ]]
	   do																																																																																																																																															
		   db2 -x "select executable_id, application_handle, entry_time, local_start_time, substr(activity_state,1,10) as state, substr(activity_type,1,10) as act_type, total_cpu_time, substr(stmt_text,1,3000) as stmt from table(mon_get_activity(null,-2)) a where member=coord_partition_num and substr(stmt_text,1,3000) not like 'select executable_id, application_handle, entry_time, local_start_time, substr(activity_state,1,10) as state, substr(activity_type,1,10) as act_type, total_cpu_time, substr(stmt_text,1,3000) as stmt%' and upper(substr(stmt_text,1,3000)) like UPPER('%""$(echo "$QUICKWATCH")""%') " > "$OUTDIR"/mon_get_activity.out
			
		    if [[ $(cat "$OUTDIR"/mon_get_activity.out | wc -l ) -gt 0 ]]; then
				
				QUERYFOUND=$((QUERYFOUND + 1))	
				
				ctry=0
				ParallelSSH "db2pd $Db2pdMemAll -eve" "$OUTDIR/db2pd_eve1.txt" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
				
				cat "$OUTDIR"/mon_get_activity.out | while read rec
				do
					Xexecid=$( echo $rec | awk '{ print $1 ;} ' )
					Xapphdl=$( echo $rec | awk '{ print $2 ;} ' )
					
					printf '\n\n%s\n\n'  "$(date): Collecting explain_from_section and Dumping apphdl: $Xapphdl"
					
					ParallelSSH "db2pd $Db2pdMemAll -dump all apphdl=$Xapphdl dumpdir=$OUTDIR -rep 2 2" "$OUTDIR/db2pd_dumpall.$ctry.$Xapphdl.txt" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
									
					db2 connect to $DBNAME > /dev/null 2>&1
					db2 -v "CALL explain_from_section( "$Xexecid",'M', NULL,NULL,NULL,?,?,?,?,? )" > $OUTDIR/FILE.EXPLAIN_FROM_SECTION.$ctry.$Xapphdl.txt
					check_success=$( cat  $OUTDIR/FILE.EXPLAIN_FROM_SECTION.$ctry.$Xapphdl.txt | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
					 
					 if [ $check_success -eq 0 ]; then
						 
							param_values=$( cat  $OUTDIR/FILE.EXPLAIN_FROM_SECTION.$ctry.$Xapphdl.txt | grep -i "Parameter Value" | awk '{ print $NF; }' )
							param1=$( echo $param_values | awk '{ print $1; }' )
							param3=$( echo $param_values | awk '{ print $3; }' )
							param4=$( echo $param_values | awk '{ print $4; }' )
							param5=$( echo $param_values | awk '{ print $5; }' )						
							
							db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $OUTDIR/FILE.exfmt_section.$ctry.$Xapphdl.txt 	
							printf '\n\n%s\n\n' "$(date): Collected explain_from_section of Apphandle: $Xapphdl  , File: $OUTDIR/FILE.exfmt_section.$ctry.$Xapphdl.txt "								
					fi
					db2 terminate > /dev/null 2>&1 		  
					let ctry=$ctry+1
					printf '\n\n%s\n\n' "$(date): Waiting for background processes to complete if any."
				done 
				ParallelSSH "db2pd $Db2pdMemAll -eve" "$OUTDIR/db2pd_eve2.txt" "$ISROOT" "$NUMHOSTS" "DB2PD" "&"
			else
				sleep 5
				cur_time=$(date +%s)
				elapsed=$(( cur_time - start_time ))	
				[[ $(($(round10 "$elapsed") % 60)) -eq 0 ]] && echo "Waiting $elapsed (seconds)"
			fi			
	   done
	   
	   waitforpid "$TMPFILE"
		
	   printf '\n\n%s\n' "$(date): Background processes are complete"
	   log "Background processes are complete"	        
		
	   printf '\n\n%s\n\n' "$(date): QueryWatch ended. QUERYFOUND: $QUERYFOUND , elapsed: $elapsed"
       db2 terminate > /dev/null 2>&1	

    fi

    if [[ "x$QUICKHANGAPP" != "x" ]]; then

        echo "`date`: Starting to collect hang data. Background tasks will be started."
        log "Starting to collect hang data. Background tasks will be started."

        log "Data will be dumped in $OUTDIR. "
        echo "`date`: Data will be dumped in $OUTDIR"

		if [[ $hrounds_SET -eq 0 ]]; then
			HROUNDS=2
		fi
		
		tstamp=$( date "+%Y-%m-%d-%H.%M.%S" )
		
		log "Collecting Common data ONCE "
		CollectHangAPPONCE "$DBNAME" "$OUTDIR" "$HROUNDS" "$tstamp" "$HHREORGCHK_SET" &
		childpidCHAO=$( echo $! )
		echo $childpidCHAO >> $TMPFILE
		echo "CollectHangAPPONCE PID: $childpidCHAO" >> $PROCESSFILE 2>&1
		[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "CollectHangAPPONCE PID: $childpidCHAO"
				
	    for (( IH=1; IH<=$HROUNDS ; IH++ )) 
	    do
      
			printf '\n\n%s\n' "######################################################################################"
			printf '%s\n'     "########### $(date): START HANGAPP DATA COLLECTION ROUND $IH OF  $HROUNDS         "
			printf '%s\n\n'   "######################################################################################"
			
			printf '\n\n%s\n\n\n' "Tasks may be running in background, so please wait until finish. You can monitor file: $LOGFILE	"
			
			tstamp=$( date "+%Y-%m-%d-%H.%M.%S" )
			
			log "########### START HANGAPP DATA COLLECTION ROUND $IH OF $HROUNDS #########"

			CollectHangAPPCommonCMD "$DBNAME" "$OUTDIR" "$IH" "$tstamp" "$HHSTACKS_SET" &
			childpidCHAC=$( echo $! )
			echo $childpidCHAC >> $TMPFILE
			echo "CollectHangAPPCommonCMD PID: $childpidCHAC" >> $PROCESSFILE 2>&1
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "CollectHangAPPCommonCMD PID: $childpidCHAC"
			
			log "Collecting apphandle specific data - Round $IH of $HROUNDS"
			echo "`date`: Collecting apphandle specific data - Round $IH of $HROUNDS"
			
			#RefreshRunningpids "$TMPFILE"
			
			for apphandle in `echo $QUICKHANGAPP | awk -F, '{ for( i = 1; i <= NF; i++){ if( int( $i ) > 0 ) print $i; } }' `
			do
					log "Collecting data for apphandle $apphandle - Round $IH of $HROUNDS"
					echo "`date`: Collecting data for apphandle $apphandle - Round $IH of $HROUNDS"
					CollectHangAPPAPPHDL "$DBNAME" "$OUTDIR" "$apphandle" "$IH" "$tstamp" "$HANG_DB2TRC" 				
			done &
			childpidCHAA=$( echo $! )
			echo $childpidCHAA >> $TMPFILE		
			echo "for apphandle in CollectHangAPPAPPHDL PID: $childpidCHAA"	>> $PROCESSFILE 2>&1
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "for apphandle in CollectHangAPPAPPHDL PID: $childpidCHAA"				
			
			log "[MON data]: Collecting some overall info using MON tables - Round $IH of $HROUNDS"
			echo "`date`: [MON data]: Collecting some overall info using MON tables - Round $IH of $HROUNDS"
			
			CollectHangAPPCommonMON "$DBNAME" "$OUTDIR" "$IH" "$tstamp" &
			childpidCHACM=$( echo $! )
			echo $childpidCHACM >> $TMPFILE	
			echo "CollectHangAPPCommonMON PID: $childpidCHACM" >> $PROCESSFILE 2>&1
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "CollectHangAPPCommonMON PID: $childpidCHACM"
			
			
			suffix=$( echo "$IH.$tstamp" )
			
			if [[ $ADDITIONALCMD_SET -eq "1" ]] ; then
				AdditionalCommands "$OUTDIR" "$suffix" "ALL" &
				childpidACALL=$( echo $! )
				echo $childpidACALL >> $TMPFILE
				echo "AdditionalCommands PID: $childpidACALL" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "AdditionalCommands PID: $childpidACALL"
				log "Collecting AdditionalCommands Started - Round $IH of $HROUNDS"		
			fi		
	
			log "[DB2PD data]: Collecting intwlmadmission and sortheapconsumers - Round $IH of $HROUNDS"
			echo "`date`: [DB2PD data]: Collecting intwlmadmission and sortheapconsumers - Round $IH of $HROUNDS"						
			
			Collect_db2pd_WLM_SORT "$DBNAME" "$OUTDIR" "$suffix" "$SERVICEPASSWORD" &
			childpidWLM=$( echo $! )
			echo $childpidWLM >> $TMPFILE	
			echo "Collect_db2pd_WLM_SORT PID: $childpidWLM" >> $PROCESSFILE 2>&1
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "Collect_db2pd_WLM_SORT PID: $childpidWLM"
	
			log "[OS data]: Collecting ( round - $IH )"
			CollectHangAPPCommonOS "$OUTDIR" "$IH" "$tstamp" "$HROUNDS" &
			childpidCHACO=$( echo $! )
			echo $childpidCHACO >> $TMPFILE	
			echo "CollectHangAPPCommonOS PID: $childpidCHACO" >> $PROCESSFILE 2>&1
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "CollectHangAPPCommonOS PID: $childpidCHACO"
			
			waitforpid "$TMPFILE"   ## Added to make sure Round X data collection is complete, before triggering another round.
			
			printf '\n\n%s\n\n'     "########### $(date): FINISHED HANGAPP DATA COLLECTION ROUND $IH OF  $HROUNDS . "
			log  "########### FINISHED HANGAPP DATA COLLECTION ROUND $IH OF  $HROUNDS . "
			
		done
		
		#RefreshRunningpids  "$TMPFILE"
		waitforpid "$TMPFILE"
		#RefreshRunningpids  "$TMPFILE"
		
		printf '\n\n%s\n' "$(date): Background processes are complete"
		log "Background processes are complete"
		        
		log "Hang data collection finished"
        echo "`date`: Hang data collection finished. Check $OUTDIR"

    fi
    if [[ "x$QUICKHADR" != "x" ]]; then

        echo "`date`: Starting to collect HADR data. Background tasks will be started."
        log "Starting to collect HADR data. Background tasks will be started."

        log "Data will be dumped in $OUTDIR. "
        echo "`date`: Data will be dumped in $OUTDIR"

		if [[ $hrounds_SET -eq 0 ]]; then
			HROUNDS=2
		fi
				
	    for (( IH=1; IH<=$HROUNDS ; IH++ )) 
	    do
      
			printf '\n\n%s\n' "######################################################################################"
			printf '%s\n'     "########### $(date): START HADR DATA COLLECTION ROUND $IH OF  $HROUNDS         "
			printf '%s\n\n'   "######################################################################################"
			
			printf '\n\n%s\n\n\n' "Tasks may be running in background, so please wait until finish. You can monitor file: $LOGFILE	"
			
			tstamp=$( date "+%Y-%m-%d-%H.%M.%S" )
			suffix=$( echo "$IH.$tstamp" )
			
			log "########### START HADR DATA COLLECTION ROUND $IH OF $HROUNDS #########"
					
			log "Calling OS data ( round - $IH )"
			CollectHADR_OS "$OUTDIR" "$IH" "$tstamp" "$HROUNDS" &
			childpidHADROS=$( echo $! )
			echo $childpidHADROS >> $TMPFILE	
			echo "CollectHADR_OS PID: $childpidHADROS" >> $PROCESSFILE 2>&1
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "CollectHADR_OS PID: $childpidHADROS"
			
			log "Calling DB2PD data ( round - $IH )"
			CollectHADR_DB2PD "$DBNAME" "$OUTDIR" "$IH" "$tstamp" "$HROUNDS" &
			childpidHADRDB2PD=$( echo $! )
			echo $childpidHADRDB2PD >> $TMPFILE	
			echo "CollectHADR_DB2PD PID: $childpidHADRDB2PD" >> $PROCESSFILE 2>&1
			[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "CollectHADR_DB2PD PID: $childpidHADRDB2PD"	
			
			#RefreshRunningpids "$TMPFILE"
			
			if [[ $ADDITIONALCMD_SET -eq "1" ]] ; then
				AdditionalCommands "$OUTDIR" "$suffix" "ALL" &
				childpidACALL=$( echo $! )
				echo $childpidACALL >> $TMPFILE
				echo "AdditionalCommands PID: $childpidACALL" >> $PROCESSFILE 2>&1
				[[ "x$DEBUG" == "x1" || "x$PIDDETAILS" = "x1" ]] && echo "AdditionalCommands PID: $childpidACALL"
				log "Collecting AdditionalCommands Started"		
			fi			
			
			waitforpid "$TMPFILE"   ## Added to make sure Round X data collection is complete, before triggering another round.
			
			printf '\n\n%s\n\n'     "########### $(date): FINISHED HADR DATA COLLECTION ROUND $IH OF  $HROUNDS . "
			log  "########### FINISHED HADR DATA COLLECTION ROUND $IH OF  $HROUNDS . "
			
		done
		
		#RefreshRunningpids  "$TMPFILE"
		waitforpid "$TMPFILE"
		#RefreshRunningpids  "$TMPFILE"
		
		printf '\n\n%s\n' "$(date): Background processes are complete"
		log "Background processes are complete"
		        
		log "Hang data collection finished"
        echo "`date`: Hang data collection finished. Check $OUTDIR"

    fi
fi

if [[ "x$QUICKALL" != "x" ]] || [[ "x$QUICKWATCH" != "x" ]] || [[ "x$QUICKHADR" != "x" ]] || [[ "x$QUICKWLM" != "x" ]] || [[ "x$QUICKTRANSACTIONS" != "x" ]]  || [[ "x$QUICKSESSIONS" != "x" ]] || [[ "x$QUICKEXPLAIN" != "x" ]] || [[ "x$QUICKTABLESPACES" != "x" ]]; then 
 printf '\n\n%s\n' "`date` : Gather the files in $OUTDIR and upload"
fi

cleanup
