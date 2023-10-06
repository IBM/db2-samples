
#!/bin/bash

#/*
#Copyright <holder> All Rights Reserved.
#
#SPDX-License-Identifier: Apache-2.0
#*/
#
#Signed-off-by: Bharat Goyal <bharat.goyal@ibm.com>

function absPath
{
 if [[ -d "$1" ]]; then
     cd "$1"
     echo "$(pwd -P)"
 else
     cd "$(dirname "$1")"
     echo "$(pwd -P)/$(basename "$1")"
 fi
}

if [ $# -eq 4 ]
then
	DBNAME=$1
	SDIR=$(absPath "$2")
	DPF=$3
	APPDHL=$4
elif [ $# -eq 3 ]
then
	DBNAME=$1
	SDIR=$(absPath "$2")
	DPF=$3
	APPDHL=-1
elif [ $# -eq 2 ]
then
	DBNAME=$1
	SDIR=$(absPath "$2")
	DPF="N"
	APPDHL=-1
else	
	echo "Usage:"
	echo " collect.sh <db-name> <SDIR> [DPF] [APPHDL]"
	echo "DPF and APPHDL are optional, If not given then Single Node and NO APPHDL is considered"
	echo "In DPF, if you want to collect data from single node then say DPF = N"
	echo "example:"
	echo " collect.sh MYDB /scratch Y/N APPHDL"
	exit
fi

exec  1> >(tee -ia $SDIR/bash.log)
exec  2> >(tee -ia $SDIR/bash.log >& 2)
exec &> >(tee -i "$SDIR/output.log")

# Notice no leading $
exec {FD}> $SDIR/bash.log

# If you want to append instead of wiping previous logs
#exec {FD}>> $2/bash.log

export BASH_XTRACEFD="$FD"

#set -xv

function collect_data
{
DUMPDIR=$1
X1=`date '+%Y-%m-%d-%H.%M.%S'`
TS=$X1

mkdir -p $DUMPDIR
if [ $? -eq 0 ]; then
	chmod 777 "$DUMPDIR"
else     
	echo "Unable to create directory: $DUMPDIR .. bailing out !!"
	exit 0
fi

echo "`date`:Starting to run data collections on host `hostname` in DIR: $DUMPDIR at $TS"

if [[ $DPF == "Y" ]] 
then
		rah="rah \"||"
		quote="\""
		memberall=" -member all "
else
		rah=""
		quote=""
		memberall=" "
fi

if [ $APPDHL -gt "0" ]
then
	db2pd $memberall -dump all apphdl=$APPDHL dumpdir=$DUMPDIR -rep 5 3 &
else
	db2pd $memberall -stack all dumpdir=$DUMPDIR -rep 5 3 &
fi	


OS="`uname`"
case $OS in
  'Linux')
    OS='Linux'
	MEMORY='free'
	VMSTAT='vmstat -w -t 1 30'
	IOSTAT='iostat -xtzk 1 30'
	PSTH='ps -elfT'
	PSETO='ps -eTo state,stat,pid,ppid,tid,time,wchan:30,policy,pri,psr,sgi_p,time,command'
	TPROF='uname'
	TOP='top -b -d 3 -n 2'
    ;;
  'AIX') 
	OS='AIX'
	MEMORY='svmon'
	VMSTAT='vmstat -w -t 1 30'
	IOSTAT='iostat -RDasl -T 1 30'
	PSTH='ps -mo THREAD -elf'
	PSETO='ps -mo THREAD -elf'
	TPROF='tprof -skeul -x sleep 60'
	TOP=''
   ;;
  *) 
	MEMORY='uname'
	VMSTAT='uname'
	IOSTAT='uname'
	PSTH='uname'
	PSETO='uname'
	TPROF='uname'
	TOP='uname'
  ;;
esac

echo "`date`: $OS"

eval $rah  $VMSTAT $quote > $DUMPDIR/vmstat.$TS &
eval $rah  $IOSTAT $quote > $DUMPDIR/iostat.$TS &
eval $rah  $MEMORY $quote > $DUMPDIR/free.$TS
eval $rah  ls -l /dev/mapper $quote > $DUMPDIR/Mapper
eval $rah  ps -elf $quote > $DUMPDIR/ps_elf.$TS
eval $rah  $TPROF $quote > $DUMPDIR/TPROF.$TS &
eval $rah  $TOP $quote > $DUMPDIR/TOP.$TS &

for j in 1 2 3 4
do
	eval $rah  $PSTH $quote > $DUMPDIR/ps_thread.$j.$TS
	eval $rah $PSETO $quote > $DUMPDIR/psETO.$j.$TS 
	sleep 2
done
	
eval $rah  db2 update monitor switches using BUFFERPOOL on LOCK on SORT on STATEMENT on TIMESTAMP on TABLE on UOW on $quote
 
db2 connect to $DBNAME

db2 "call SYSPROC.SYSINSTALLOBJECTS( 'EXPLAIN', 'C' , '', CURRENT USER )"
db2 "call monreport.dbsummary(30)" > $DUMPDIR/monrpt_dbsummary.$TS &
db2 "call monreport.lockwait" > $DUMPDIR/mon_lockwait.$TS &
db2 "call monreport.connection(30)" > $DUMPDIR/mon_con.$TS &

db2pd $memberall -inst -dbptnmem -memsets -mempools -file $DUMPDIR/db2pdMem.$TS &
db2pd $memberall -edus -file $DUMPDIR/db2pdEdu.$TS -rep 5 3 &
db2pd $memberall -edus interval=5 top=10 -file $DUMPDIR/db2pdEduTOP.$TS &
db2pd $memberall -latches -file $DUMPDIR/db2pdLatches.$TS  -rep 5 3 &
db2pd -db $DBNAME $memberall -wlocks -file $DUMPDIR/db2pdWlocks.$TS -rep 5 3 &
db2pd -db $DBNAME $memberall -locks showlocks -file $DUMPDIR/db2pdShowlocks.$TS -rep 5 3 &
db2pd -db $DBNAME $memberall -bufferpool -file $DUMPDIR/db2pd_BP.$TS -rep 5 3 &

db2pd -db $DBNAME $memberall -cleaner -file $DUMPDIR/db2pd_cleaner.$TS -rep 5 3 &
db2pd -db $DBNAME $memberall -dirtypages summary -file $DUMPDIR/db2pd_dirtySumm.$TS -rep 5 3 &

if [ $APPDHL -gt "0" ] 
then
	db2pd -db $DBNAME $memberall -apinfo $APPDHL metrics -file $DUMPDIR/db2pd.$APPDHL.apinfo.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -applications $APPDHL -file $DUMPDIR/db2pd_applications.$APPDHL.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -transactions app=$APPDHL -file $DUMPDIR/db2pd_transactions.$APPDHL.$TS -rep 5 3 &
	db2pd $memberall -age app=$APPDHL -file $DUMPDIR/db2pd_agents.$APPDHL.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -active apphdl=$APPDHL -file $DUMPDIR/db2pd_active.$APPDHL.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -sort apphdl=$APPDHL -file $DUMPDIR/db2pd.sort.$APPDHL.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -locks app=$APPDHL > $DUMPDIR/db2pd.locks.$APPDHL.$TS -rep 5 3 &
else	
	db2pd -db $DBNAME $memberall -apinfo metrics -file $DUMPDIR/db2pd.apinfo.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -applications -file $DUMPDIR/db2pd_applications.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -transactions -file $DUMPDIR/db2pd_transactions.$TS -rep 5 5 &
	db2pd $memberall -age -file $DUMPDIR/db2pd_agents.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -active -file $DUMPDIR/db2pd_active.$TS -rep 5 3 &
	db2pd -db $DBNAME $memberall -sort -file $DUMPDIR/db2pd.sort.$TS -rep 5 3 &
fi	

db2pd -db $DBNAME $memberall -load stacks file=$DUMPDIR/db2pd.load.$TS  -rep 5 3 &
db2pd -db $DBNAME $memberall -runstats file=$DUMPDIR/db2pd.runstats.$TS  -rep 5 3 &
db2pd -db $DBNAME $memberall -reorgs index file=$DUMPDIR/db2pd.reorg_index.$TS  -rep 5 3 & 
db2pd  $memberall -util -file $DUMPDIR/db2pd.util.$TS -rep 5 3 &
db2pd -db $DBNAME $memberall -logs -file $DUMPDIR/db2pd.logs.$TS -rep 5 3 &
db2pd -db $DBNAME $memberall -extent -file $DUMPDIR/db2pd.extent.$TS -rep 5 3 &
db2pd -db $DBNAME $memberall -tcbstat index -file $DUMPDIR/db2pd.tcbstat.$TS -rep 5 3 &
db2pd  $memberall -gfw -file $DUMPDIR/db2pd.gfw.$TS -rep 5 3 &

db2pd -db $DBNAME -memblocks all top $memberall > $DUMPDIR/db2pd.memblocks.all.$TS &

db2pd -fmpexechistory n=512 genquery $memberall > $DUMPDIR/db2pd.fmphist.$TS &
db2pd -fmp $memberall -rep 5 3 > $DUMPDIR/db2pd.fmp.$TS &

db2pd -db $DBNAME $memberall -tablespace -file $DUMPDIR/db2pd.tablespace.$TS &
db2pd -db $DBNAME $memberall -workload -file $DUMPDIR/db2pd.workload.$TS &
db2pd -db $DBNAME $memberall -dynamic -file $DUMPDIR/db2pd_dynamic.$TS &

echo "`date`: dumping MON FUNCTIONS"
db2 "select executable_id,num_executions, total_act_time, total_act_wait_time, total_extended_latch_wait_time as latch_w_time, total_cpu_time, rows_read, rows_returned,stmt_text from table(mon_get_pkg_cache_stmt(null,null,null,null)) order by total_extended_latch_wait_time desc fetch first 20 rows only"  > $DUMPDIR/mon_get_pkg_cache_stmt.latch.$TS
db2 "SELECT * FROM TABLE ( MON_GET_LATCH(CLOB('<latch_status>W</latch_status>'), -2 ) ) ORDER BY LATCH_NAME, LATCH_STATUS" > $DUMPDIR/get_latch_wait.$TS
db2 "SELECT * FROM sysibmadm.mon_current_sql ORDER BY ELAPSED_TIME_SEC desc" > $DUMPDIR/mon_get_sql.$TS
db2 "select EXECUTABLE_ID, t.* from table(MON_GET_ACTIVITY(NULL, -2)) as t order by TOTAL_EXTENDED_LATCH_WAIT_TIME desc" > $DUMPDIR/EXECUTABLE_ID.LATCH.mon_get_activity.$TS
db2 "select EXECUTABLE_ID, t.* from table(MON_GET_ACTIVITY(NULL, -2)) as t order by TOTAL_ACT_WAIT_TIME desc" > $DUMPDIR/EXECUTABLE_ID.ACTIVITY.mon_get_activity.$TS
db2 "select EXECUTABLE_ID,TOTAL_CPU_TIME/NUM_EXEC_WITH_METRICS,TOTAL_CPU_TIME,COORD_STMT_EXEC_TIME/NUM_EXEC_WITH_METRICS,COORD_STMT_EXEC_TIME,NUM_EXEC_WITH_METRICS, STMT_TEXT from table(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2)) where NUM_EXEC_WITH_METRICS <> 0 order by COORD_STMT_EXEC_TIME/NUM_EXEC_WITH_METRICS desc fetch first 20 rows only" > $DUMPDIR/elap_top_package_cache.$TS
db2 "select EXECUTABLE_ID, substr(stmt_text,1,250) as stmt_text, decimal(float(total_extended_latch_wait_time)/num_executions,10,5) as avg_latch_time from table(mon_get_pkg_cache_stmt(null,null,null,null))  where num_executions > 0  order by avg_latch_time desc fetch first 10 rows only" > $DUMPDIR/mon_get_pkg_cache_stmt.Avglatch.$TS

ctr=1
cat $DUMPDIR/mon_get_pkg_cache_stmt.latch.$TS | awk '{print $1}' | grep "^x" | sort | uniq | while read execid
do
   db2 connect to $DBNAME 
   db2 "call explain_from_section( $execid, 'M', null, -1, '', ?,?,?,?,? )"
   db2exfmt -d $DBNAME  -1 -o $DUMPDIR/exfmt.mon_get_pkg_cache_stmt.latch.$( echo $execid | tr -d "'" ).$ctr
   ((ctr=$ctr+1))
done 
ctr=1
cat $DUMPDIR/elap_top_package_cache.$TS | awk '{print $1}' | grep "^x" | sort | uniq | while read execid
do
   db2 connect to $DBNAME 
   db2 "call explain_from_section( $execid, 'M', null, -1, '', ?,?,?,?,? )"
   db2exfmt -d $DBNAME  -1 -o $DUMPDIR/exfmt.elap_top_package_cache.$( echo $execid | tr -d "'" ).$ctr
   ((ctr=$ctr+1))
done 
ctr=1
cat $DUMPDIR/EXECUTABLE_ID.LATCH.mon_get_activity.$TS | awk '{print $1}' | grep "^x" | sort | uniq | while read execid
do
   db2 connect to $DBNAME 
   db2 "call explain_from_section( $execid, 'M', null, -1, '', ?,?,?,?,? )"
   db2exfmt -d $DBNAME  -1 -o $DUMPDIR/exfmt.LATCH.mon_get_activity.$( echo $execid | tr -d "'" ).$ctr
   ((ctr=$ctr+1))
done 
ctr=1
cat $DUMPDIR/EXECUTABLE_ID.ACTIVITY.mon_get_activity.$TS | awk '{print $1}' | grep "^x" | sort | uniq | while read execid
do
   db2 connect to $DBNAME 
   db2 "call explain_from_section( $execid, 'M', null, -1, '', ?,?,?,?,? )"
   db2exfmt -d $DBNAME  -1 -o $DUMPDIR/exfmt.ACTIVITY.mon_get_activity.$( echo $execid | tr -d "'" ).$ctr
   ((ctr=$ctr+1))
done 

if [ $APPDHL -gt "0" ] 
then
	echo "`date`: Executing db2trc apphdl $APPDHL"
	db2trc on -t -apphdl $APPDHL $memberall
	sleep 10
	db2trc dmp trc1.ROW.$TS -sdir $DUMPDIR $memberall
	sleep 10
	db2trc dmp trc2.ROW.$TS -sdir $DUMPDIR $memberall
	sleep 10
	db2trc dmp trc3.ROW.$TS -sdir $DUMPDIR $memberall
	db2trc off $memberall

	echo "`date`: Executing db2trc CDE apphdl $APPDHL"
	db2trc on -t -Madd CDE_PERF_TRACE -apphdl $APPDHL $memberall
	sleep 10 
	db2trc dmp trc1.CDE.$TS -sdir $DUMPDIR $memberall
	sleep 10 
	db2trc dmp trc2.CDE.$TS -sdir $DUMPDIR $memberall
	sleep 10 
	db2trc dmp trc3.CDE.$TS -sdir $DUMPDIR $memberall
	db2trc off $memberall
else
	echo "`date`: Executing perfcount"
	eval $rah  db2trc on -perfcount -t -edu $quote
	sleep 10
	eval $rah  db2trc dmp trc1.perfcount.$TS -sdir $DUMPDIR $quote
	sleep 10
	eval $rah  db2trc dmp trc2.perfcount.$TS -sdir $DUMPDIR $quote
	eval $rah  db2trc off $quote

	echo "`date`: Executing sqlbfix"
	db2trc on -t -Madd sqlbfix $memberall
	sleep 5
	db2trc dmp trc1.sqlbfix.$TS -sdir $DUMPDIR $memberall
	sleep 5
	db2trc dmp trc2.sqlbfix.$TS -sdir $DUMPDIR $memberall
	db2trc off $memberall
fi

echo "`date`: Executing db2mon 60"
~/sqllib/samples/perf/db2mon.sh $DBNAME 60 >> $DUMPDIR/db2mon_report.$TS 

cat $DUMPDIR/db2mon_report.$TS  | sed '/INF#EXPLN/,/record(s) selected./!d;//d' | awk ' { if ( $1 ~ /^[0-9]+$/ && tolower(substr($2,1,2)) == "x\x27" ) { print $1, $2} }' > $DUMPDIR/db2mon_report.$TS.execids1
cat $DUMPDIR/db2mon_report.$TS  | egrep "^COORD_MEMBER|^EXECUTABLE_ID" | awk '{print $NF}' | sed 'N;s/\n/ /g' | awk '{ if ( $1 ~ /^[0-9]+$/ && tolower(substr($2,1,2)) == "x\x27" ) { print $1, $2} }' > $DUMPDIR/db2mon_report.$TS.execids2

ctr=1
cat $DUMPDIR/db2mon_report.$TS.execids1 $DUMPDIR/db2mon_report.$TS.execids2  | sort | uniq | while read rec
do
	 coord=$( echo $rec | awk '{ print $1; }' )
	 executable_id=$( echo $rec | awk '{ print $2 }' )
	 fmtexecid=$( echo $executable_id | tr -d "'" )
		 
	 if ls $DUMPDIR/exfmt."db2mon_report.$TS".*."$fmtexecid" 1> /dev/null 2>&1  ; then
		 
		  echo "`date`: Skipping exfmt: in $DUMPDIR/exfmt."db2mon_report.$TS".*."$fmtexecid" for filename: db2mon_report.$TS"
	 else 
		 
		db2 connect to $DBNAME
		db2 "call explain_from_section( $executable_id, 'M', NULL, $coord, NULL, ?, ?, ?, ?, ? ) "  >> $DUMPDIR/explain_section.db2mon_report.$TS.$ctr.$fmtexecid
		db2 terminate 
		check_success=$( cat $DUMPDIR/explain_section.db2mon_report.$TS.$ctr.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' | grep "20.*-" > /dev/null; echo $? )
			 
		if [ $check_success -eq 0 ]; then
			 
			param_values=$( cat $DUMPDIR/explain_section.db2mon_report.$TS.$ctr.$fmtexecid | grep -i "Parameter Value" | awk '{ print $NF; }' )
			param1=$( echo $param_values | awk '{ print $1; }' )
			param3=$( echo $param_values | awk '{ print $3; }' )
			param4=$( echo $param_values | awk '{ print $4; }' )
			param5=$( echo $param_values | awk '{ print $5; }' )						
			
			db2exfmt -d $DBNAME -e $param1 -w $param3 -n $param4 -s $param5 -t -# 0 > $DUMPDIR/exfmt.db2mon_report.$TS.$ctr.$fmtexecid 
			echo "Collected explain ( db2mon_report.$TS ) Execid: $executable_id , File: $DUMPDIR/exfmt.db2mon_report.$TS.$ctr.$fmtexecid "
		 fi
	 fi	
	 ((ctr=$ctr+1))
done
	
QH1="select executable_id, STMTID, PLANID, max_coord_stmt_exec_time, STMT_TEXT , XMLPARSE(DOCUMENT max_coord_stmt_exec_time_args) max_coord_stmt_exec_time_args FROM TABLE(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2)) where max_coord_stmt_exec_time_args IS NOT NULL AND STMTID in ( "
QH2=$( cat $DUMPDIR/db2mon_report.$TS | sed '/INF#EXPLN/,/record(s) selected./!d;//d' | awk ' { if ( $1 ~ /^[0-9]+$/ && tolower(substr($2,1,2)) == "x\x27" ) { print  $4","} }' | sort | uniq | tr '\n' ' ' )
QH3=" 0) "
FQ="$QH1 $QH2 $QH3"
db2 connect to $DBNAME
db2 -v "$FQ" > $DUMPDIR/values.db2mon_report.$TS.out
db2 terminate
}

TM=`date '+%Y-%m-%d-%H.%M.%S'`
HDIR=$SDIR/"db2Dump_$TM"
mkdir -p $HDIR
if [ $? -eq 0 ]; then
	chmod 777 "$HDIR"
else     
	echo "Unable to create directory: $HDIR .. bailing out !!"
	exit 0
fi

for TIMES in {1..3}
do
	TM=`date '+%Y-%m-%d-%H.%M.%S'`
	echo "`date`: Running $TIMES at $TM dumping in $HDIR/$TM"
	collect_data $HDIR/$TM
	sleep 5
done

echo "`date`: Formatting db2traces"

if [ $APPDHL -gt "0" ] 
then
	for files in `ls $HDIR/*/trc*.CDE.*`
	do
			echo "`date`: Formatting file: $files "
			fname=$(basename "$files")
	        fdirname=$(dirname $(absPath "$files"))	
			db2trc fmt $files $fdirname/fmt.$fname 
	done
	for files in `ls $HDIR/*/trc*.ROW.*`
	do
			echo "`date`: Formatting file: $files "
			fname=$(basename "$files")
	        fdirname=$(dirname $(absPath "$files"))	
			db2trc fmt $files $fdirname/fmt.$fname 
			db2trc flw -t $files $fdirname/flw.$fname 
			db2trc flw -t -data $files $fdirname/data.flw.$fname 
			db2trc flw -t -rds $files $fdirname/rds.flw.$fname 
			db2trc perfrep -rds -g -sort timeelapsed $files $fdirname/perfrep.$fname 
	done
else
	for files in `ls $HDIR/*/trc*.perfcount.*`
	do
			echo "`date`: Formatting file: $files "
			fname=$(basename "$files")
	        fdirname=$(dirname $(absPath "$files"))	
			db2trc perffmt $files $fdirname/perffmt.$fname 
	done
	for files in `ls $HDIR/*/trc*.sqlbfix.*`
	do
			echo "`date`: Formatting file: $files "
			fname=$(basename "$files")
	        fdirname=$(dirname $(absPath "$files"))	
			db2trc fmt $files $fdirname/fmt.$fname 
			db2trc flw -t $files $fdirname/flw.$fname 
			db2trc flw -t -data $files $fdirname/data.flw.$fname 
			db2trc perfrep -rds -g -sort timeelapsed $files $fdirname/perfrep.$fname 
	done
fi	

db2 connect to $DBNAME
db2 +c -v "call REORGCHK_TB_STATS('T','ALL')" > $HDIR/REORGCHK_TB_STATS.`hostname`.out
db2 +c -v "select table_schema, table_name,DATAPARTITIONNAME,card,overflow,  f1,  f2,  f3,  reorg  from SESSION.TB_STATS where REORG LIKE '%*%'" > $HDIR/NeedTSReorg.`hostname`.out
db2 +c -v "CALL SYSPROC.REORGCHK_IX_STATS('T', 'ALL')" > $HDIR/REORGCHK_IX_STATS.`hostname`.out
db2 +c -v "SELECT TABLE_SCHEMA,TABLE_NAME,INDEX_SCHEMA,INDEX_NAME,DATAPARTITIONNAME,INDCARD,F4,F5,F6,F7,F8,REORG FROM SESSION.IX_STATS  WHERE REORG LIKE '%*%'" > $HDIR/NeedTXReorg.`hostname`.out
db2 -v "select TABSCHEMA,TABNAME,CREATE_TIME,ALTER_TIME,INVALIDATE_TIME,STATS_TIME,COLCOUNT,TABLEID,TBSPACEID,CARD,NPAGES,MPAGES,FPAGES,OVERFLOW,LASTUSED,TABLEORG from syscat.tables WHERE TABSCHEMA NOT LIKE 'SYS%' AND TYPE = 'T' order by STATS_TIME,TABSCHEMA,TABNAME " > $HDIR/syscat_tables.`hostname`.out		

mv $SDIR/bash.log $HDIR
mv $SDIR/output.log $HDIR
