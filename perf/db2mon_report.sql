--****************************************************************************
-- (c) Copyright IBM Corp. 2017 All rights reserved.
--
-- The following sample of source code ("Sample") is owned by International
-- Business Machines Corporation or one of its subsidiaries ("IBM") and is
-- copyrighted and licensed, not sold. You may use, copy, modify, and
-- distribute the Sample in any form without payment to IBM, for the purpose of
-- assisting you in the development of your applications.
--
-- The Sample code is provided to you on an "AS IS" basis, without warranty of
-- any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
-- IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
-- not allow for the exclusion or limitation of implied warranties, so the above
-- limitations or exclusions may not apply to you. IBM shall not be liable for
-- any damages you suffer as a result of using, copying, modifying or
-- distributing the Sample, even if IBM has been advised of the possibility of
-- such damages.
--*****************************************************************************

echo ********************************************************;
echo                                                         ;
echo  This script was generated                              ;
echo                                                         ;
echo    by db2mon.pl version 1.2.0                           ;
echo                                                         ;
echo    for DB2 version 11.1                                 ;
echo                                                         ;
echo    on Tue Nov  6 17:55:45 2018                          ;
echo                                                         ;
echo    with 30 seconds pause between collections  ;
echo    in db2mon.sql and db2mon_export.sql                  ;
echo    (0 seconds pause means script will wait for <ENTER>) ;
echo                                                         ;
echo  Changes to this script will be overwritten the next    ;
echo  time db2mon.pl is run.                                 ;
echo                                                         ;
echo  1. Connect to the analysis database where you ran      ;
echo     db2mon_import                                       ;
echo  2. Run with CLP as in 'db2 -tvf db2mon_report.sql'     ;
echo                                                         ;
echo                                                         ;
echo ********************************************************;
echo                                                         ;

select cast(substr(current schema,1,24) as varchar(24)) as current_schema from sysibm.sysdummy1;

echo REPORT STARTS HERE;
echo;

echo ################################################################################################################### ;
echo  Point-in-time data: Current executing SQL, lock waits and utilities at start of capture ;
echo ################################################################################################################### ;
echo;

select min(ts) capture_time from mon_current_sql_plus_start;

echo ================================================================================= ;
echo  START#EXSQL: Currently executing SQL at start of capture (non-zero metrics only  ;
echo ================================================================================= ;
echo ;

with mon as (select ts,
count,
coord_member,application_handle,uow_id,activity_id,elapsed_time_sec,total_cpu_time,rows_read,direct_reads,direct_writes,executable_id,package_name,section_number,active_sorts,active_sorts_top,active_sort_consumers,active_sort_consumers_top,sort_shrheap_allocated,sort_shrheap_top,post_threshold_sorts,post_shrthreshold_sorts,post_threshold_hash_joins,post_shrthreshold_hash_joins,post_threshold_hash_grpbys,post_threshold_olap_funcs,total_act_time,total_act_wait_time,lock_wait_time,pool_read_time,direct_read_time,direct_write_time,fcm_recv_wait_time,fcm_send_wait_time,total_extended_latch_wait_time,log_disk_wait_time,cf_wait_time,reclaim_wait_time,spacemappage_reclaim_wait_time,stmt_text
from
  mon_current_sql_plus_start )
select
  t.metric "Metric", t.value "Value"
from
  mon,
  table( values
    ('COORD_MEMBER',varchar(coord_member)),
    ('STMT_TEXT', cast(substr(stmt_text,1,120) as varchar(120))),
    ('EXECUTABLE_ID', 'x'''||hex(executable_id)||''''),
    ('PACKAGE_NAME', package_name || '    (Section '||cast(section_number as varchar(10))||')'),
    ('Partition count', varchar(count)),
    ('APPLICATION_HANDLE',varchar(application_handle) || '  (UOW_ID '||cast(uow_id as varchar(8))||', ACTIVITY_ID '||cast(activity_id as varchar(8))||')' ),
    ('ELAPSED_TIME_SEC',varchar(elapsed_time_sec)),
    ('TOTAL_CPU_TIME',varchar(total_cpu_time)),
    ('ROWS_READ',varchar(rows_read)),
    ('DIRECT_READS',varchar(direct_reads)),
    ('DIRECT_WRITES',varchar(direct_writes)),
    ('ACTIVE_SORTS',varchar(active_sorts)),
    ('ACTIVE_SORTS_TOP',varchar(active_sorts_top)),
    ('ACTIVE_SORT_CONSUMERS',varchar(active_sort_consumers)),
    ('ACTIVE_SORT_CONSUMERS_TOP',varchar(active_sort_consumers_top)),
    ('SORT_SHRHEAP_ALLOCATED',varchar(sort_shrheap_allocated)),
    ('SORT_SHRHEAP_TOP',varchar(sort_shrheap_top)),
    ('POST_THRESHOLD_SORTS',varchar(post_threshold_sorts)),
    ('POST_SHRTHRESHOLD_SORTS',varchar(post_shrthreshold_sorts)),
    ('POST_THRESHOLD_HASH_JOINS',varchar(post_threshold_hash_joins)),
    ('POST_SHRTHRESHOLD_HASH_JOINS',varchar(post_shrthreshold_hash_joins)),
    ('POST_THRESHOLD_HASH_GRPBYS',varchar(post_threshold_hash_grpbys)),
    ('POST_THRESHOLD_OLAP_FUNCS',varchar(post_threshold_olap_funcs)),
    ('Pct wait times',
        'Total: '      || cast(case when total_act_time > 0 then smallint( (total_act_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Lock: '    || cast(case when total_act_time > 0 then smallint( (lock_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Pool rd: ' || cast(case when total_act_time > 0 then smallint( (pool_read_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Dir IO: '  || cast(case when total_act_time > 0 then smallint( ((direct_read_time+direct_write_time) / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   FCM: '     || cast(case when total_act_time > 0 then smallint( ((fcm_recv_wait_time+fcm_send_wait_time) / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Latch: '   || cast(case when total_act_time > 0 then smallint( (total_extended_latch_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Log: '     || cast(case when total_act_time > 0 then smallint( (log_disk_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   CF: '      || cast(case when total_act_time > 0 then smallint( (cf_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Reclaim: ' || cast(case when total_act_time > 0 then smallint( ((reclaim_wait_time+spacemappage_reclaim_wait_time) / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ),
    (cast(repeat('-',32) as varchar(32)),cast(repeat('-',120) as varchar(120))) )
  as t(metric,value)
  where t.metric = 'COORD_MEMBER' or t.value <> '0'
  order by elapsed_time_sec desc
with UR;

echo ===================================================== ;
echo  START#LOCKW: Current lock waits at start of capture  ;
echo ===================================================== ;
echo ;

select
(select cast(substr(tbspace,1,20) as varchar(20)) from syscat_tablespaces where tbspaceid = tbsp_id) tbspace,
(select cast(substr(tabname,1,30) as varchar(30)) from syscat_tables where tab_file_id = tableid and tbspaceid = tbsp_id) tabname,
  cast(substr(lock_object_type,1,12) as varchar(12)) lock_obj_type,
  lock_name,
  lock_mode,
  lock_status,
  member,
  integer(application_handle) apphdl
from
  mon_get_locks_start
where
  lock_name in (select lock_name from mon_get_locks_start where lock_status = 'W')
order by
  lock_object_type, lock_name, lock_status, lock_mode
with UR;

echo ================================================================ ;
echo  START#EXUTL: Currently executing utilities at start of capture  ;
echo ================================================================ ;
echo ;

  select
    coord_member,
    application_handle,
    utility_start_time,
    utility_type,
    utility_operation_type,
    cast(substr(utility_detail,1,100) as varchar(100)) utility_detail
  from
        mon_get_utility_start
  order by
        utility_start_time asc
  with UR;

echo ################################################################################################################### ;
echo  Point-in-time data: Current executing SQL, lock waits and utilities at end of capture ;
echo ################################################################################################################### ;
echo;

select min(ts) capture_time from mon_current_sql_plus_end;

echo ============================================================================= ;
echo  END#EXSQL: Currently executing SQL at end of capture (non-zero metrics only  ;
echo ============================================================================= ;
echo ;

with mon as (select ts,
count,
coord_member,application_handle,uow_id,activity_id,elapsed_time_sec,total_cpu_time,rows_read,direct_reads,direct_writes,executable_id,package_name,section_number,active_sorts,active_sorts_top,active_sort_consumers,active_sort_consumers_top,sort_shrheap_allocated,sort_shrheap_top,post_threshold_sorts,post_shrthreshold_sorts,post_threshold_hash_joins,post_shrthreshold_hash_joins,post_threshold_hash_grpbys,post_threshold_olap_funcs,total_act_time,total_act_wait_time,lock_wait_time,pool_read_time,direct_read_time,direct_write_time,fcm_recv_wait_time,fcm_send_wait_time,total_extended_latch_wait_time,log_disk_wait_time,cf_wait_time,reclaim_wait_time,spacemappage_reclaim_wait_time,stmt_text
from
  mon_current_sql_plus_end )
select
  t.metric "Metric", t.value "Value"
from
  mon,
  table( values
    ('COORD_MEMBER',varchar(coord_member)),
    ('STMT_TEXT', cast(substr(stmt_text,1,120) as varchar(120))),
    ('EXECUTABLE_ID', 'x'''||hex(executable_id)||''''),
    ('PACKAGE_NAME', package_name || '    (Section '||cast(section_number as varchar(10))||')'),
    ('Partition count', varchar(count)),
    ('APPLICATION_HANDLE',varchar(application_handle) || '  (UOW_ID '||cast(uow_id as varchar(8))||', ACTIVITY_ID '||cast(activity_id as varchar(8))||')' ),
    ('ELAPSED_TIME_SEC',varchar(elapsed_time_sec)),
    ('TOTAL_CPU_TIME',varchar(total_cpu_time)),
    ('ROWS_READ',varchar(rows_read)),
    ('DIRECT_READS',varchar(direct_reads)),
    ('DIRECT_WRITES',varchar(direct_writes)),
    ('ACTIVE_SORTS',varchar(active_sorts)),
    ('ACTIVE_SORTS_TOP',varchar(active_sorts_top)),
    ('ACTIVE_SORT_CONSUMERS',varchar(active_sort_consumers)),
    ('ACTIVE_SORT_CONSUMERS_TOP',varchar(active_sort_consumers_top)),
    ('SORT_SHRHEAP_ALLOCATED',varchar(sort_shrheap_allocated)),
    ('SORT_SHRHEAP_TOP',varchar(sort_shrheap_top)),
    ('POST_THRESHOLD_SORTS',varchar(post_threshold_sorts)),
    ('POST_SHRTHRESHOLD_SORTS',varchar(post_shrthreshold_sorts)),
    ('POST_THRESHOLD_HASH_JOINS',varchar(post_threshold_hash_joins)),
    ('POST_SHRTHRESHOLD_HASH_JOINS',varchar(post_shrthreshold_hash_joins)),
    ('POST_THRESHOLD_HASH_GRPBYS',varchar(post_threshold_hash_grpbys)),
    ('POST_THRESHOLD_OLAP_FUNCS',varchar(post_threshold_olap_funcs)),
    ('Pct wait times',
        'Total: '      || cast(case when total_act_time > 0 then smallint( (total_act_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Lock: '    || cast(case when total_act_time > 0 then smallint( (lock_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Pool rd: ' || cast(case when total_act_time > 0 then smallint( (pool_read_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Dir IO: '  || cast(case when total_act_time > 0 then smallint( ((direct_read_time+direct_write_time) / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   FCM: '     || cast(case when total_act_time > 0 then smallint( ((fcm_recv_wait_time+fcm_send_wait_time) / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Latch: '   || cast(case when total_act_time > 0 then smallint( (total_extended_latch_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Log: '     || cast(case when total_act_time > 0 then smallint( (log_disk_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   CF: '      || cast(case when total_act_time > 0 then smallint( (cf_wait_time / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ||
        '   Reclaim: ' || cast(case when total_act_time > 0 then smallint( ((reclaim_wait_time+spacemappage_reclaim_wait_time) / double(total_act_time)) * 100 ) else 0 end as varchar(5)) ),
    (cast(repeat('-',32) as varchar(32)),cast(repeat('-',120) as varchar(120))) )
  as t(metric,value)
  where t.metric = 'COORD_MEMBER' or t.value <> '0'
  order by elapsed_time_sec desc
with UR;

echo ================================================= ;
echo  END#LOCKW: Current lock waits at end of capture  ;
echo ================================================= ;
echo ;

select
(select cast(substr(tbspace,1,20) as varchar(20)) from syscat_tablespaces where tbspaceid = tbsp_id) tbspace,
(select cast(substr(tabname,1,30) as varchar(30)) from syscat_tables where tab_file_id = tableid and tbspaceid = tbsp_id) tabname,
  cast(substr(lock_object_type,1,12) as varchar(12)) lock_obj_type,
  lock_name,
  lock_mode,
  lock_status,
  member,
  integer(application_handle) apphdl
from
  mon_get_locks_end
where
  lock_name in (select lock_name from mon_get_locks_end where lock_status = 'W')
order by
  lock_object_type, lock_name, lock_status, lock_mode
with UR;

echo ============================================================ ;
echo  END#EXUTL: Currently executing utilities at end of capture  ;
echo ============================================================ ;
echo ;

  select
    coord_member,
    application_handle,
    utility_start_time,
    utility_type,
    utility_operation_type,
    cast(substr(utility_detail,1,100) as varchar(100)) utility_detail
  from
        mon_get_utility_end
  order by
        utility_start_time asc
  with UR;

echo ################################################################################################################### ;
echo  Data collected from start to end of monitor interval;
echo ################################################################################################################### ;
echo;
echo ================================================ ;
echo  DB#THRUP: Throughput metrics at database level  ;
echo ================================================ ;
echo ;

select
   min(ts_delta) ts_delta,
   member,
   decimal((sum(act_completed_total) / float(min(ts_delta))), 10, 1) as act_per_s,
   decimal((sum(total_app_commits) / float(min(ts_delta))), 10, 1) as cmt_per_s,
   decimal((sum(total_app_rollbacks) / float(min(ts_delta))), 10, 1) as rb_per_s,
   decimal((sum(deadlocks) / float(min(ts_delta))), 10, 1) as ddlck_per_s,


   decimal((sum(select_sql_stmts) / float(min(ts_delta))), 10, 1) as sel_p_s,
   decimal((sum(uid_sql_stmts) / float(min(ts_delta))), 10, 1) as uid_p_s,
   decimal((sum(rows_inserted) / float(min(ts_delta))), 10, 1) as rows_ins_p_s,
   decimal((sum(rows_updated) / float(min(ts_delta))), 10, 1) as rows_upd_p_s,


   decimal((sum(rows_returned) / float(min(ts_delta))), 10, 1) as rows_ret_p_s,
   decimal((sum(rows_modified) / float(min(ts_delta))), 10, 1) as rows_mod_p_s,
   decimal((sum(pkg_cache_inserts) / float(min(ts_delta))), 10, 1) as pkg_cache_ins_p_s,
   decimal((sum((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads)) / float(min(ts_delta))) , 10, 1) as p_rd_per_s
from
   mon_get_workload_diff
where
        ts_delta > 0
group by
   member
order by
   member asc
with UR;

echo ======================================================================= ;
echo  DB#CLACT: Client activity (active connections have at least 1 stmt/s)  ;
echo ======================================================================= ;
echo ;

with
   total_clients as
       (  select
             member,
             count(*) count,
             sum(client_idle_wait_time) client_idle_wait_time,
             sum(total_rqst_time) total_rqst_time,
             case when sum(total_rqst_time) > 0 then decimal(float(sum(client_idle_wait_time)) / sum(total_rqst_time), 10, 2) else null end as idle_rqst_ratio
          from
             mon_get_connection_diff
          group by
             member
       ),
   active_clients as
       (  select
             member,
             count(*) count,
             decimal(float(sum(rqsts_completed_total)) / min(ts_delta), 10, 2) rqst_per_s,
             sum(client_idle_wait_time) client_idle_wait_time,
             sum(total_rqst_time) total_rqst_time,
             case when sum(total_rqst_time) > 0 then decimal(float(sum(client_idle_wait_time)) / sum(total_rqst_time), 10, 2) else null end as idle_rqst_ratio
          from
             mon_get_connection_diff
          where
             rqsts_completed_total > ts_delta or                                        -- at least one request per second, or
             (total_rqst_time > 0 and client_idle_wait_time / total_rqst_time < 2)      -- long requests, at least half as long as the client idle wait time
          group by
             member
       )
select
   t.member,
   t.count as total_clients,
   t.client_idle_wait_time total_ciwt,
   t.total_rqst_time total_rqst,
   t.idle_rqst_ratio tot_ciwt_rq_ratio,
   a.count as active_clients,
   a.rqst_per_s active_rq_per_s,
   a.client_idle_wait_time active_ciwt,
   a.total_rqst_time active_rqst,
   a.idle_rqst_ratio active_ciwt_rq_ratio
from
   total_clients t,
   active_clients a
where
   a.member = t.member
with UR;

echo ================================================================ ;
echo  DB#TIMEB: Time breakdown at database level (wait + processing)  ;
echo ================================================================ ;
echo ;

select
   member,
   integer(sum(total_rqst_time)) as total_rqst_tm,
   decimal(sum(total_compile_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_compile,
   decimal(sum(total_section_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_section,
   decimal(sum(total_section_sort_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_sort,
decimal(sum(total_col_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_col,
decimal(sum(total_col_synopsis_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_col_synop,
decimal(sum(total_commit_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_commit,
decimal(sum(total_rollback_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_rback,
decimal(sum(total_connect_request_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_conn,
decimal(sum(total_routine_user_code_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_rtn_usr_code,
decimal(sum(total_backup_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_backup,
decimal(sum(total_index_build_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_idx_bld,
   decimal(sum(total_runstats_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_runstats,
   decimal(sum(total_reorg_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_reorg,
   decimal(sum(total_load_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_load

from
   mon_get_workload_diff
group by
   member
order by
   member asc
with UR;

echo ======================================== ;
echo  DB#WAITT: Wait times at database level  ;
echo ======================================== ;
echo ;

select
   w.member,
   integer(sum(total_rqst_time)) as total_rqst_tm,
   integer(sum(total_wait_time)) as total_wait_tm,
   decimal((sum(total_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_rqst_wait,
   decimal((sum(lock_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_lock,
   decimal((sum(lock_wait_time_global) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_glb_lock,
   decimal((sum(total_extended_latch_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_ltch,
   decimal((sum(log_disk_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_lg_dsk,
   decimal((sum(log_buffer_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_lg_buf,
   decimal((sum(reclaim_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_rclm,
   decimal((sum(cf_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_cf,
   decimal((sum(prefetch_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_pftch,
   decimal((sum(diaglog_write_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_diag,
   decimal((sum(pool_read_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_pool_r,
   decimal((sum(direct_read_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_dir_r,
   decimal((sum(direct_write_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_dir_w,
   decimal((sum(fcm_recv_wait_time+fcm_send_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_fcm,
   decimal((sum(tcpip_send_wait_time+tcpip_recv_wait_time) / float(sum(total_rqst_time))) * 100, 5, 2) as pct_tcpip
from
   mon_get_workload_diff w
group by
   w.member
order by
   w.member asc
with UR;

echo ============================================== ;
echo  DB#PROCT: Processing times at database level  ;
echo ============================================== ;
echo ;

select
   member,
   integer(sum(total_rqst_time)) as total_rqst_tm,
   integer(sum(total_rqst_time) - sum(total_wait_time)) as total_proc_time,
   decimal(sum(total_compile_proc_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_comp_proc,
   decimal(sum(total_section_proc_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_sect_proc,
   decimal(sum(total_section_sort_proc_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_sect_sort_proc,
   decimal(sum(total_commit_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_commit,
   decimal(sum(total_rollback_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_rback
,
decimal(sum(total_col_proc_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_col_proc,
decimal(sum(total_connect_request_proc_time) / float(sum(total_rqst_time)) * 100, 5, 2) as pct_conn_proc
from
   mon_get_workload_diff
group by
   member
order by
   member asc
with UR;

echo ========================================= ;
echo  DB#SORT: Sort metrics at database level  ;
echo ========================================= ;
echo ;

select
   member,
   integer(sum(total_sorts)) total_sorts,
   integer(sum(sort_overflows)) sort_overflows,
   sum(total_section_sort_time) tot_sect_sort_tm,
   sum(total_section_sort_proc_time) tot_sect_sort_proc_tm
   ,
   sum(sort_shrheap_allocated) sort_shrheap_allocated,
   integer(sum(total_hash_joins)) total_hsjn,
   integer(sum(hash_join_overflows)) hsjn_ovfl,
   integer(sum(post_threshold_hash_joins)) pst_thr_hsjn,
   integer(sum(post_shrthreshold_hash_joins)) pst_shrthr_hsjn
from
   mon_get_workload_diff
group by
   member
order by
   member asc
with UR;

echo ==================================================== ;
echo  SQL#TOPEXECT: Top SQL statements by execution time  ;
echo ==================================================== ;
echo ;

select
   member,
   integer(num_exec_with_metrics) as num_exec,

   coord_stmt_exec_time,
   decimal(coord_stmt_exec_time / double(num_exec_with_metrics), 10, 2) as avg_coord_exec_time,
   decimal( (coord_stmt_exec_time / double(total_coord_stmt_exec_time)) * 100, 5, 2 ) as pct_coord_stmt_exec_time,

   total_cpu_time,
   total_cpu_time / num_exec_with_metrics as avg_cpu_time,
   decimal( (total_act_wait_time / double(total_act_time)) * 100, 5, 2 ) as pct_wait_time,
   decimal(total_section_time / double(num_exec_with_metrics), 10, 2) as avg_sect_time,
decimal(total_col_time / double(num_exec_with_metrics), 10, 2) as avg_col_time,
   replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text
from
        mon_get_pkg_cache_stmt_diff,
  (  select
        sum(coord_stmt_exec_time) as total_coord_stmt_exec_time
     from
        mon_get_pkg_cache_stmt_diff   )
where
        coord_stmt_exec_time <> 0 and total_act_time <> 0 and num_exec_with_metrics <> 0
order by
        coord_stmt_exec_time desc
fetch first 100 rows only
with UR;

echo ========================================================================== ;
echo  SQL#TOPEXECP: Top SQL statements by execution time, aggregated by PLANID  ;
echo ========================================================================== ;
echo ;

select
   member,
   count(*) num_stmts,
   integer(sum(num_exec_with_metrics)) total_exec,

   sum(coord_stmt_exec_time) coord_stmt_exec_time,
   decimal(sum(coord_stmt_exec_time) / double(sum(num_exec_with_metrics)), 10, 2) as avg_coord_exec_time,
   decimal( (sum(coord_stmt_exec_time) / double(sum(total_coord_stmt_exec_time))) * 100, 5, 2 ) as pct_coord_stmt_exec_time,

   sum(total_cpu_time) total_cpu_time,
   sum(total_cpu_time) / sum(num_exec_with_metrics) as avg_cpu_time,
   decimal( (sum(total_act_wait_time) / double(sum(total_act_time))) * 100, 5, 2 ) as pct_wait_time,
   decimal(sum(total_section_time) / double(sum(num_exec_with_metrics)), 10, 2) as avg_sect_time,
   decimal(sum(total_col_time) / double(sum(num_exec_with_metrics)), 10, 2) as avg_col_time,
  (select replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text from mon_get_pkg_cache_stmt_diff mgpcs4planid
   where mgpcs4planid.member = t.member and mgpcs4planid.planid = t.planid
   fetch first 1 row only)
from
  mon_get_pkg_cache_stmt_diff t,
  (  select
        sum(coord_stmt_exec_time) as total_coord_stmt_exec_time
     from
        mon_get_pkg_cache_stmt_diff   )
where
  coord_stmt_exec_time <> 0 and total_act_time <> 0 and num_exec_with_metrics <> 0
group by
  member,planid
order by
  coord_stmt_exec_time desc
fetch first 100 rows only
with UR;
echo ============================================ ;
echo  PKG#EXECT: Time spent executing by package  ;
echo ============================================ ;
echo ;

select
    member,
    cast(substr(package_name,1,20) as varchar(20)) as package_name,
    sum(num_exec_with_metrics) as num_stmts_exec,
    sum(coord_stmt_exec_time) as coord_stmt_exec_time
from
    mon_get_pkg_cache_stmt_diff
where
    coord_stmt_exec_time > 0
group by
    member, package_name
order by
    coord_stmt_exec_time desc
fetch first 100 rows only
with UR;

echo ============================================================================ ;
echo  SQL#TOPWAITT: Wait time breakdown for top SQL statements by execution time  ;
echo ============================================================================ ;
echo ;

select
   member,
   decimal((total_act_wait_time / double(total_act_time)) * 100, 5, 2) as pct_wait,
   decimal((log_disk_wait_time / double(total_act_time)) * 100, 5, 2) as pct_lg_dsk,
   decimal((log_buffer_wait_time/double(total_act_time)) * 100, 5, 2) as pct_lg_buf,
   decimal((lock_wait_time / double(total_act_time)) * 100, 5, 2) as pct_lock,

   decimal((lock_wait_time_global / double(total_act_time)) * 100, 5, 2) as pct_glb_lock,
   decimal((total_extended_latch_wait_time / double(total_act_time)) * 100, 5, 2) as pct_ltch,
   decimal((reclaim_wait_time / double(total_act_time)) * 100, 5, 2) as pct_rclm,
   decimal((cf_wait_time / double(total_act_time)) * 100, 5, 2) as pct_cf,
   decimal((prefetch_wait_time / double(total_act_time)) * 100, 5, 2) as pct_pftch,
   decimal((diaglog_write_wait_time / double(total_act_time)) * 100, 5, 2) as pct_diag,


   decimal((pool_read_time / double(total_act_time)) * 100, 5, 2) as pct_pool_r,
   decimal((direct_read_time / double(total_act_time)) * 100, 5, 2) as pct_dir_r,
   decimal((direct_write_time / double(total_act_time)) * 100, 5, 2) as pct_dir_w,
   decimal(((fcm_recv_wait_time+fcm_send_wait_time) / double(total_act_time)) * 100, 5, 2) as pct_fcm,
   replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text
from
        mon_get_pkg_cache_stmt_diff
where
        coord_stmt_exec_time <> 0 and total_act_time <> 0
order by
        coord_stmt_exec_time desc
fetch first 100 rows only
with UR;

echo ======================================================== ;
echo  SQL#TOPWAITW: Top SQL statements by time spent waiting  ;
echo ======================================================== ;
echo ;

select
   member,
   decimal((total_act_wait_time / double(total_act_time)) * 100, 5, 2) as pct_wait,
   decimal((log_disk_wait_time / double(total_act_time)) * 100, 5, 2) as pct_lg_dsk,
   decimal((log_buffer_wait_time/double(total_act_time)) * 100, 5, 2) as pct_lg_buf,
   decimal((lock_wait_time / double(total_act_time)) * 100, 5, 2) as pct_lock,


   decimal((lock_wait_time_global / double(total_act_time)) * 100, 5, 2) as pct_glb_lock,
   decimal((total_extended_latch_wait_time / double(total_act_time)) * 100, 5, 2) as pct_ltch,
   decimal((reclaim_wait_time / double(total_act_time)) * 100, 5, 2) as pct_rclm,
   decimal((cf_wait_time / double(total_act_time)) * 100, 5, 2) as pct_cf,
   decimal((prefetch_wait_time / double(total_act_time)) * 100, 5, 2) as pct_pftch,
   decimal((diaglog_write_wait_time / double(total_act_time)) * 100, 5, 2) as pct_diag,


   decimal((pool_read_time / double(total_act_time)) * 100, 5, 2) as pct_pool_r,
   decimal((direct_read_time / double(total_act_time)) * 100, 5, 2) as pct_dir_r,
   decimal((direct_write_time / double(total_act_time)) * 100, 5, 2) as pct_dir_w,
   decimal(((fcm_recv_wait_time+fcm_send_wait_time) / double(total_act_time)) * 100, 5, 2) as pct_fcm,
   replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text
from
        mon_get_pkg_cache_stmt_diff
where
        total_act_time <> 0
order by
        total_act_wait_time desc
fetch first 100 rows only
with UR;

echo ========================================================================= ;
echo  SQL#TOPIOSTA: IO statistics per stmt - top statements by execution time  ;
echo ========================================================================= ;
echo ;

select
   member,
   integer(num_exec_with_metrics) num_exec,
   decimal(pool_data_l_reads/double(num_exec_with_metrics), 16,1) as avg_d_lrd,
   decimal(pool_data_p_reads/double(num_exec_with_metrics), 10,1) as avg_d_prd,
   decimal(pool_index_l_reads/double(num_exec_with_metrics), 16,1) as avg_i_lrd,
   decimal(pool_index_p_reads/double(num_exec_with_metrics), 10,1) as avg_i_prd,
   decimal(pool_temp_data_p_reads/double(num_exec_with_metrics), 10,1) as avg_td_prd,
   decimal(pool_temp_index_p_reads/double(num_exec_with_metrics), 10,1) as avg_ti_prd,
decimal(pool_col_l_reads/double(num_exec_with_metrics), 16,1) as avg_col_lrd,
decimal(pool_col_p_reads/double(num_exec_with_metrics), 10,1) as avg_col_prd,
   decimal(direct_read_reqs/double(num_exec_with_metrics), 8,1) avg_dir_r_rqs,
   decimal(direct_write_reqs/double(num_exec_with_metrics), 8,1) avg_dir_w_rqs,
   replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text
from
   mon_get_pkg_cache_stmt_diff
where
        coord_stmt_exec_time <> 0 and num_exec_with_metrics <> 0
order by
        coord_stmt_exec_time desc
fetch first 100 rows only
with UR;

echo =============================================================================== ;
echo  SQL#TOPROWS: Row level statistics per stmt - top statements by execution time  ;
echo =============================================================================== ;
echo ;

select
  member,
  integer(num_exec_with_metrics) as num_exec,
  decimal(rows_modified/double(num_exec_with_metrics), 12,1) as avg_rows_mod,
  decimal(rows_read/double(num_exec_with_metrics), 12,1) as avg_rows_read,
  decimal(rows_returned/double(num_exec_with_metrics), 12,1) as avg_rows_ret,
col_synopsis_rows_inserted,
  replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text
from
        mon_get_pkg_cache_stmt_diff
where
        coord_stmt_exec_time <> 0
order by
        coord_stmt_exec_time desc
fetch first 100 rows only
with UR;

echo ========================================================================== ;
echo  SQL#TOPSORT: Sort statistics per stmt - top statements by execution time  ;
echo ========================================================================== ;
echo ;

select
  member,
  decimal((total_section_sort_time / double(total_act_time)) * 100, 5, 2) as pct_sort_time,
  decimal(total_sorts/double(num_exec_with_metrics), 8,1) as avg_tot_sorts,
  decimal(sort_overflows/double(num_exec_with_metrics), 8,1) as avg_sort_ovflws,
  integer(active_sorts_top) active_sorts_top,
  integer(sort_heap_top) sort_heap_top,
  --integer(sort_shrheap_top) sort_shrheap_top,
  replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text
from
        mon_get_pkg_cache_stmt_diff
where
        coord_stmt_exec_time <> 0 and total_act_time <> 0 and num_exec_with_metrics <> 0
order by
        coord_stmt_exec_time desc
fetch first 100 rows only
with UR;

echo ============================================================================================ ;
echo  INF#EXPLN: Statement & plan identifiers - top statements by execution time  ;
echo  To populate the explain tables:  ;
echo    db2 -tvf $HOME/sqllib/misc/explain.ddl  ;
echo    db2 "call explain_from_section(x'<executable id>','M',NULL,0,'<current user>',?,?,?,?,?)  ;
echo ============================================================================================ ;
echo ;

select
  member,
  executable_id,
  planid,
  stmtid,
  semantic_env_id,
  replace(replace(cast(substr(stmt_text,1,200) as varchar(200)), chr(10), ' '), chr(13), ' ') as stmt_text
from
        mon_get_pkg_cache_stmt_diff
where
        coord_stmt_exec_time <> 0
order by
        coord_stmt_exec_time desc
fetch first 100 rows only
with UR;

echo ====================================================== ;
echo  DB#SYSRE: Database system resource usage information  ;
echo ====================================================== ;
echo ;

select
   member,
   cast(substr(os_name,1,8) as varchar(8)) as os,
   cast(substr(host_name,1,16) as varchar(16)) host_name,
   cast(substr(os_version,1,8) as varchar(8)) os_ver,
   cast(substr(os_release,1,8) as varchar(8)) os_rel,
   smallint(cpu_total) cpu_tot,
   smallint(cpu_online) cpu_onl,
   smallint(cpu_configured) cpu_cfg,
   integer(cpu_speed) cpu_speed,
   smallint(cpu_hmt_degree) cpu_hmt,
   integer(memory_total) memory_total,
   integer(memory_free) memory_free,
   decimal(cpu_load_short,6,1) cpu_load_shrt,
   decimal(cpu_load_medium,6,1) cpu_load_med,
   decimal(cpu_load_long,6,1) cpu_load_lng,
   decimal(cpu_usage_total,6,1) cpu_usage_tot,
   integer(swap_pages_in) swap_pages_in,
   integer(swap_pages_out) swap_pages_out
from
   env_get_system_resources_diff
order by
   member
with UR;


echo ==================================== ;
echo  DB#LOGWR: Database log write times  ;
echo ==================================== ;
echo ;

select
   member,
   num_log_write_io,
   case when ts_delta > 0
      then decimal( double(num_log_write_io) / ts_delta, 10, 4 )
      else null
   end as log_write_io_per_s,
   case when ts_delta > 0
      then decimal( double(log_writes*4096/1024/1024) / ts_delta, 10, 4 )
      else null
   end as log_write_MB_per_s,
   log_write_time,
   case when num_log_write_io > 0
      then decimal( double(log_write_time) / num_log_write_io, 10, 4 )
      else null
   end as log_write_time_per_io_ms,
   num_log_buffer_full
from
   mon_get_transaction_log_diff
order by
   member asc
with UR;

echo =================================== ;
echo  DB#LOGRE: Database log read times  ;
echo =================================== ;
echo ;

select
   member,
   integer(num_log_read_io) num_log_read_io,
   case when ts_delta > 0
      then decimal( double(num_log_read_io) / ts_delta, 10, 4 )
      else null
   end as log_read_io_per_s,
   integer(log_reads) log_reads,
   integer(log_read_time) log_read_time,
   case when num_log_read_io > 0
      then decimal( double(log_read_time) / num_log_read_io, 10, 4 )
      else null
   end as log_read_time_per_io_ms,
   integer(num_log_data_found_in_buffer) num_log_data_in_buffer,
   integer(cur_commit_log_buff_log_reads) cur_com_log_buff_log_reads,
   integer(cur_commit_disk_log_reads) cur_com_disk_log_reads
from
   mon_get_transaction_log_diff
order by
   member asc
with UR;

echo ========================================= ;
echo  DB#LOGST: Other database log statistics  ;
echo ========================================= ;
echo ;

select
   member,
   num_log_write_io,
   num_log_part_page_io,
   case when num_log_part_page_io > 0
      then decimal( double(num_log_part_page_io) / num_log_write_io, 10, 4 )
      else null
   end as log_part_page_ratio,
   case when log_hadr_waits_total > 0
      then decimal( double(log_hadr_wait_time) / log_hadr_waits_total, 10, 4 )
      else null
   end as avg_log_hadr_wait_time
from
   mon_get_transaction_log_diff
order by
   member asc
with UR;

echo ========================================== ;
echo  TSP#DSKIO: Disk read and write I/O times  ;
echo ========================================== ;
echo ;

select
   member,
   cast(substr(tbsp_name,1,20) as varchar(20)) as tbsp_name,

   -- Reads

   (pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) as num_reads,
   case when ((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads)) > 0
      then decimal( pool_read_time / double((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads)), 5, 2 )
      else null
   end as avg_read_time,

   direct_read_reqs,
   case when direct_read_reqs > 0
      then decimal( direct_read_time / direct_read_reqs, 5, 2 )
      else null
   end as avg_drct_read_time,

   -- Writes

   (pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) as num_writes,
   case when ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes)) > 0
      then decimal( pool_write_time / double((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes)), 5, 2 )
      else null
   end as avg_write_time,

   direct_write_reqs,
   case when direct_write_reqs > 0
      then decimal( direct_write_time / direct_write_reqs, 5, 2 )
      else null
   end as avg_drct_write_time
from
   mon_get_tablespace_diff
where
   ((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) + direct_read_reqs + (pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) + direct_write_reqs) > 0
order by
   ((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) + direct_read_reqs + (pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) + direct_write_reqs) desc
with UR;

echo ============================================================ ;
echo  TSP#DSKIOSYNC: Disk read and write I/O times (synchronous)  ;
echo ============================================================ ;
echo ;

select
   member,
   cast(substr(tbsp_name,1,20) as varchar(20)) as tbsp_name,

   -- Reads

   ((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)) as num_reads,
   case when (((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads))) > 0
      then decimal( (pool_read_time - pool_async_read_time) / double(((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads))), 5, 2 )
      else null
   end as avg_sync_read_time,

   -- Writes

   ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)) as num_writes,
   case when (((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes))) > 0
      then decimal( (pool_write_time - pool_async_write_time) / double(((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes))), 5, 2 )
      else null
   end as avg_sync_write_time
from
   mon_get_tablespace_diff
where
   (((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)) + ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes))) > 0
order by
   (((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)) + ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes))) desc
with UR;

echo ============================================================== ;
echo  TSP#DSKIOASYNC: Disk read and write I/O times (asynchronous)  ;
echo ============================================================== ;
echo ;

select
   member,
   cast(substr(tbsp_name,1,20) as varchar(20)) as tbsp_name,

   -- Reads

   (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads) as num_reads,
   case when ((pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)) > 0
      then decimal( pool_async_read_time / double((pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)), 5, 2 )
      else null
   end as avg_async_read_time,

   -- Writes

   (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes) as num_writes,
   case when ((pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)) > 0
      then decimal( pool_async_write_time / double((pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)), 5, 2 )
      else null
   end as avg_async_write_time
from
   mon_get_tablespace_diff
where
   ((pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads) + (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)) > 0
order by
   ((pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads) + (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)) desc
with UR;

echo ================================== ;
echo  DB#EXTBM: External table metrics  ;
echo ================================== ;
echo ;

select
   min(ts_delta) ts_delta,
   member,
   sum(ext_table_recvs_total) as ext_table_recvs_total,
   sum(ext_table_recv_wait_time) as ext_table_recv_wait_time,
   sum(ext_table_recv_volume) as ext_table_recv_volume,
   sum(ext_table_read_volume) as ext_table_read_volume,
   sum(ext_table_sends_total) as ext_table_sends_total,
   sum(ext_table_send_wait_time) as ext_table_send_wait_time,
   sum(ext_table_send_volume) as ext_table_send_volume,
   sum(ext_table_write_volume) as ext_table_write_volume,
   decimal((sum(ext_table_recv_volume) / float(min(ts_delta))), 10, 1) as recv_per_s,
   decimal((sum(ext_table_read_volume) / float(min(ts_delta))), 10, 1) as read_per_s,
   decimal((sum(ext_table_send_volume) / float(min(ts_delta))), 10, 1) as send_per_s,
   decimal((sum(ext_table_write_volume) / float(min(ts_delta))), 10, 1) as write_per_s
from
   mon_get_workload_diff
group by
   member
order by
   member asc
with UR;

echo =============================== ;
echo  LTC#WAITT: Latch wait metrics  ;
echo =============================== ;
echo ;

select
   member,
   cast(substr(latch_name,1,60) as varchar(60)) as latch_name,
   total_extended_latch_wait_time as tot_ext_latch_wait_time_ms,
   total_extended_latch_waits as tot_ext_latch_waits,
   decimal( double(total_extended_latch_wait_time) / total_extended_latch_waits, 10, 2 ) as time_per_latch_wait_ms
from
   mon_get_extended_latch_wait_diff
where
  total_extended_latch_waits > 0
order by
   total_extended_latch_wait_time desc
with UR;


echo -------------------------------------------------------------------------------- ;
echo ;
echo Latch waits generally indicate contention on a common resource. ;
echo These can be avoided by application changes, schema changes, or Db2 tuning. ;
echo Before this can be achieved, an understanding of what the common resource is ;
echo and potential remedies must be determined. ;
echo ;
echo Generally additional data collection is required to support root cause analysis ;
echo and typically requires engaging Db2 Support. An excellent source of additional ;
echo context can be obtained using the db2latchtrace tool. ;
echo ;
echo -------------------------------------------------------------------------------- ;
echo ;
 
echo ========================================================= ;
echo  DB#DLCKS: Deadlocks, lock timeouts and lock escalations  ;
echo ========================================================= ;
echo ;

select
   member,
   integer(sum(deadlocks)) as deadlocks,
   integer(sum(lock_timeouts)) as lock_timeouts,
   integer(sum(lock_escals)) as lock_escals

   ,
   integer(sum(lock_timeouts - lock_timeouts_global)) as lock_timeouts_local,
   integer(sum(lock_timeouts_global)) as lock_timeouts_global,
   integer(sum(lock_escals_maxlocks)) as lock_escals_maxlocks,
   integer(sum(lock_escals_locklist)) as lock_escals_locklist,
   integer(sum(lock_escals_global)) as lock_escals_global

from
   mon_get_workload_diff
group by
   member
order by
   member asc
with UR;

echo ======================================== ;
echo  TBL#ROWMC: Various table level metrics  ;
echo ======================================== ;
echo ;

select
  mgt.member,
  cast(substr(mgt.tabname,1,32) as varchar(32)) as tabname,
  smallint(mgt.data_partition_id) data_part_id,
  smallint(mgt.tbsp_id) tbsp_id,
  sum(mgt.rows_read) rows_read,
  sum(mgt.rows_inserted) rows_inserted,
  sum(mgt.rows_updated) rows_updated,
  sum(mgt.rows_deleted) rows_deleted,
  min(systab.append_mode) append,

  integer(sum(mgt.direct_read_reqs))dir_read_reqs,
  integer(sum(mgt.direct_write_reqs))dir_write_reqs,
  integer(sum(mgt.object_data_p_reads))obj_data_p_rds,
  case when sum(mgt.object_data_l_reads) > 0
    then decimal(float(sum(mgt.object_data_l_reads - mgt.object_data_p_reads)) / sum(mgt.object_data_l_reads) * 100, 5, 2)
    else null
  end as table_hr,

  sum(mgt.col_object_l_pages)col_object_l_pages,

  integer(sum(mgt.overflow_accesses))ovfl_accesses,
  integer(sum(mgt.overflow_creates))ovfl_creates,
  integer(sum(mgt.page_reorgs))page_reorgs,
  max(systab.pctpagessaved) pctpagessaved
from
  mon_get_table_diff mgt,
syscat_tables systab
where
  mgt.tabname = systab.tabname and
  mgt.tabschema = systab.tabschema
group by
  mgt.member,mgt.tabname,mgt.tabschema,mgt.data_partition_id,mgt.tbsp_id    -- we'll roll up over tab_file_id as it's an unimportant difference
having
  sum(rows_read + rows_inserted + rows_updated + rows_deleted + page_reorgs) > 0
order by
  mgt.tabname asc
with UR;

echo ================================= ;
echo  TBL#DATSH: Data sharing metrics  ;
echo ================================= ;
echo ;

select
  member,
  cast(substr(tabname,1,40) as varchar(40)) as tabname,
  data_partition_id as data_part_id,
  data_sharing_state_change_time,
  data_sharing_state,
  data_sharing_remote_lockwait_count,
  data_sharing_remote_lockwait_time
from
  mon_get_table_diff
where
  rows_read + rows_inserted + rows_updated + rows_deleted + page_reorgs > 0
  and data_sharing_state_change_time is not null
order by
  tabname asc
with UR;

echo =========================== ;
echo  DB#SIZE: Size of database  ;
echo =========================== ;
echo ;

select
        member,
        decimal( sum( double(tbsp_used_pages) * tbsp_page_size ) / 1024 / 1024, 10, 2 ) as db_mb_used
from
        mon_get_tablespace_end
group by
        member
order by
        member asc
with UR;

echo ================================= ;
echo  TSP#SIZE: Tablespace properties  ;
echo ================================= ;
echo ;

select
  member,
  cast(substr(tbsp_name,1,32) as varchar(32)) as tbsp_name,
  tbsp_id,
  tbsp_page_size,
  tbsp_used_pages,
  decimal( (double(tbsp_used_pages) * tbsp_page_size) / 1024 / 1024, 10, 2 ) as tbsp_mb_used,
  decimal( (double(tbsp_page_top) * tbsp_page_size) / 1024 / 1024, 10, 2) as tbsp_mb_hwm,
  tbsp_extent_size,
  case fs_caching when 2 then 'Default off' when 1 then 'Explicit off' else 'Explicit on' end fs_caching,
  tbsp_prefetch_size
from
        mon_get_tablespace_end
order by
        member asc, tbsp_used_pages desc
with UR;

echo ====================================================== ;
echo  TSP#USAGE: Tablespace usage over monitoring interval  ;
echo ====================================================== ;
echo ;

select
  member,
  cast(substr(tbsp_name,1,30) as varchar(30)) as tbsp_name,
  tbsp_used_pages,
  decimal( (double(tbsp_used_pages) * tbsp_page_size) / 1024 / 1024, 10, 2 ) as tbsp_mb_used
from
        mon_get_tablespace_diff
where
        tbsp_used_pages > 0
order by
        member asc, tbsp_used_pages desc
with UR;

echo ================================================ ;
echo  BPL#STATS: Bufferpool statistics by tablespace  ;
echo ================================================ ;
echo ;

select
   member,
   cast(substr(tbsp_name,1,20) as varchar(20)) as tbsp_name,

   -- Data pages

   pool_data_l_reads + pool_temp_data_l_reads as data_l_reads,
   pool_data_p_reads + pool_temp_data_p_reads as data_p_reads,
   pool_data_p_reads + pool_temp_data_p_reads - pool_async_data_reads as sync_data_p_reads,
   case when (pool_data_l_reads + pool_temp_data_l_reads) > 1000
      then decimal(float(pool_data_l_reads + pool_temp_data_l_reads - (pool_data_p_reads + pool_temp_data_p_reads - pool_async_data_reads))/(pool_data_l_reads + pool_temp_data_l_reads)*100,5,2)
      else null
   end as data_hr,
   case when (pool_data_l_reads + pool_temp_data_l_reads) > 1000
      then
         decimal((pool_data_lbp_pages_found - pool_async_data_lbp_pages_found) / float(pool_data_l_reads + pool_temp_data_l_reads) * 100, 5, 2)
      else null
   end as data_lbp_hr,
   -- Columnar pages

   pool_col_l_reads + pool_temp_col_l_reads as col_l_reads,
   pool_col_p_reads + pool_temp_col_p_reads as col_p_reads,
   pool_col_p_reads + pool_temp_col_p_reads - pool_async_col_reads as sync_col_p_reads,
   case when (pool_col_l_reads + pool_temp_col_l_reads) > 1000
      then decimal(float(pool_col_l_reads + pool_temp_col_l_reads - (pool_col_p_reads + pool_temp_col_p_reads - pool_async_col_reads))/(pool_col_l_reads + pool_temp_col_l_reads)*100,5,2)
      else null
   end as col_hr,
   -- Index pages

   pool_index_l_reads + pool_temp_index_l_reads as index_l_reads,
   pool_index_p_reads + pool_temp_index_p_reads as index_p_reads,
   pool_index_p_reads + pool_temp_index_p_reads - pool_async_index_reads as sync_index_p_reads,
   case when (pool_index_l_reads + pool_temp_index_l_reads) > 1000
      then decimal(float(pool_index_l_reads + pool_temp_index_l_reads - (pool_index_p_reads + pool_temp_index_p_reads - pool_async_index_reads))/(pool_index_l_reads + pool_temp_index_l_reads)*100,5,2)
      else null
   end as index_hr,
   case when (pool_index_l_reads + pool_temp_index_l_reads) > 1000
      then
         decimal((pool_index_lbp_pages_found - pool_async_index_lbp_pages_found ) / float(pool_index_l_reads + pool_temp_index_l_reads) * 100, 5, 2)
      else null
   end as index_lbp_hr
from
   mon_get_tablespace_diff
where
   (pool_data_l_reads + pool_temp_data_l_reads + pool_index_l_reads + pool_temp_index_l_reads + pool_xda_l_reads + pool_temp_xda_l_reads + pool_col_l_reads + pool_temp_col_l_reads) > 0
order by
   pool_read_time desc
with UR;


echo ============================================== ;
echo  TSP#PRFST: Tablespace prefetching statistics  ;
echo ============================================== ;
echo ;

select
  member,
  cast(substr(tbsp_name,1,30) as varchar(30)) as tbsp_name,
  pool_async_data_reads,
  pool_data_p_reads,
  case when pool_data_p_reads > 0 then decimal(pool_async_data_reads / float(pool_data_p_reads) * 100, 5, 2) else null end as pct_data_pftch,
  pool_async_index_reads,
  pool_index_p_reads,
  case when pool_index_p_reads > 0 then decimal(pool_async_index_reads / float(pool_index_p_reads) * 100, 5, 2) else null end as pct_index_pftch,

  pool_async_col_reads,
  pool_col_p_reads,
  case when pool_col_p_reads > 0 then decimal(pool_async_col_reads / float(pool_col_p_reads) * 100, 5, 2) else null end as pct_col_pftch,
  prefetch_wait_time,
  prefetch_waits,

  unread_prefetch_pages

from
        mon_get_tablespace_diff
where
        (pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) > 0
order by
        member asc, (pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) desc
with UR;

select
  member,
  cast(substr(tbsp_name,1,30) as varchar(30)) as tbsp_name,
  vectored_ios,
  pages_from_vectored_ios,
  case when vectored_ios > 0 then decimal(pages_from_vectored_ios / float(vectored_ios), 5, 2) else null end as avg_vio_sz,
  block_ios,
  pages_from_block_ios,
  case when block_ios > 0 then decimal(pages_from_block_ios / float(block_ios), 5, 2) else null end as avg_bio_sz
from
        mon_get_tablespace_diff
where
   (vectored_ios + block_ios) > 0
order by
        member asc, (vectored_ios + block_ios) desc
with UR;

echo ============================================= ;
echo  TSP#BPMAP: Tablespace to bufferpool mapping  ;
echo ============================================= ;
echo ;

select
   cast(substr(tbspace,1,20) as varchar(20)) as tbsp_name,
   datatype,
   cast(substr(bpname,1,20) as varchar(20)) as bpname
from
  syscat_tablespaces t, syscat_bufferpools b
where
   t.bufferpoolid = b.bufferpoolid
with UR;

echo ============================= ;
echo  BPL#SIZES: Bufferpool sizes  ;
echo ============================= ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   b.pagesize,
   mgb.bp_cur_buffsz as num_pages,
   decimal(double(b.pagesize) * mgb.bp_cur_buffsz / 1024 / 1024, 10, 2) as size_mb,
   automatic
from
  syscat_bufferpools b, mon_get_bufferpool_diff mgb
where
   b.bpname = mgb.bp_name
order by
   member
with UR;

echo ================================================= ;
echo  BPL#HITRA: Bufferpool data and index hit ratios  ;
echo ================================================= ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   case when (pool_data_l_reads) > 0
      then
         decimal( ( double(pool_data_lbp_pages_found - pool_async_data_lbp_pages_found ) / (pool_data_l_reads + pool_temp_data_l_reads) ) * 100, 5, 2 )
      else 0
   end as row_data_lbp_hitratio,
   case when (pool_col_l_reads) > 0
      then
         decimal( ( double(pool_col_lbp_pages_found - pool_async_col_lbp_pages_found ) / (pool_col_l_reads + pool_temp_col_l_reads) ) * 100, 5, 2 )
      else 0
   end as col_data_lbp_hitratio,
   case when (pool_index_l_reads) > 0
      then
         decimal( ( double(pool_index_lbp_pages_found - pool_async_index_lbp_pages_found ) / (pool_index_l_reads + pool_temp_index_l_reads) ) * 100, 5, 2 )
      else 0
   end as index_lbp_hitratio
from
   mon_get_bufferpool_diff
where
   (pool_data_l_reads + pool_temp_data_l_reads + pool_index_l_reads + pool_temp_index_l_reads + pool_xda_l_reads + pool_temp_xda_l_reads + pool_col_l_reads + pool_temp_col_l_reads) > 0
order by
   (pool_data_l_reads + pool_temp_data_l_reads + pool_index_l_reads + pool_temp_index_l_reads + pool_xda_l_reads + pool_temp_xda_l_reads + pool_col_l_reads + pool_temp_col_l_reads) desc
with UR;

echo ================================================= ;
echo  BPL#READS: Bufferpool read statistics (overall)  ;
echo ================================================= ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   pool_data_l_reads,
   pool_data_p_reads,
   pool_index_l_reads,
   pool_index_p_reads,
   pool_col_l_reads,
   pool_col_p_reads,
   pool_read_time,
   case when ((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads)) > 0
      then decimal( pool_read_time / double((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads)), 5, 2 )
      else null
   end as avg_read_time
from
   mon_get_bufferpool_diff
where
   (pool_data_l_reads + pool_temp_data_l_reads + pool_index_l_reads + pool_temp_index_l_reads + pool_xda_l_reads + pool_temp_xda_l_reads + pool_col_l_reads + pool_temp_col_l_reads) > 0
order by
   (pool_data_l_reads + pool_temp_data_l_reads + pool_index_l_reads + pool_temp_index_l_reads + pool_xda_l_reads + pool_temp_xda_l_reads + pool_col_l_reads + pool_temp_col_l_reads) desc
with UR;

echo ============================================================ ;
echo  BPL#RDSYNC: Bufferpool read statistics (synchronous reads)  ;
echo ============================================================ ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   (pool_data_p_reads - pool_async_data_reads) as pool_sync_data_reads,
   (pool_index_p_reads - pool_async_index_reads) as pool_sync_index_reads,
   (pool_col_p_reads - pool_async_col_reads) as pool_sync_col_reads,
   (pool_read_time - pool_async_read_time) as pool_sync_read_time,
   case when (((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads))) > 0
      then decimal( (pool_read_time - pool_async_read_time) / double(((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads))), 5, 2 )
      else null
   end as avg_sync_read_time
from
   mon_get_bufferpool_diff
where
   ((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)) > 0
order by
   ((pool_data_p_reads + pool_temp_data_p_reads + pool_index_p_reads + pool_temp_index_p_reads + pool_xda_p_reads + pool_temp_xda_p_reads + pool_col_p_reads + pool_temp_col_p_reads) - (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)) desc
with UR;

echo ============================================================== ;
echo  BPL#RDASYNC: Bufferpool read statistics (asynchronous reads)  ;
echo ============================================================== ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   pool_async_data_reads,
   pool_async_index_reads,
   pool_async_col_reads,
   pool_async_read_time,
   case when ((pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)) > 0
      then decimal( pool_async_read_time / double((pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads)), 5, 2 )
      else null
   end as avg_async_read_time
from
   mon_get_bufferpool_diff
where
   (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads) > 0
order by
   (pool_async_data_reads + pool_async_index_reads + pool_async_xda_reads + pool_async_col_reads) desc
with UR;

echo ================================================== ;
echo  BPL#WRITE: Bufferpool write statistics (overall)  ;
echo ================================================== ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   pool_data_writes,
   pool_index_writes,
   pool_xda_writes,
   pool_col_writes,
   pool_write_time,
   case when ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes)) > 0
      then decimal( pool_write_time / double((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes)), 5, 2 )
      else null
   end as avg_write_time
from
   mon_get_bufferpool_diff
where
   (pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) > 0
order by
   (pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) desc
with UR;

echo ============================================================== ;
echo  BPL#WRSYNC: Bufferpool write statistics (synchronous writes)  ;
echo ============================================================== ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   (pool_data_writes - pool_async_data_writes) as pool_sync_data_writes,
   (pool_index_writes - pool_async_index_writes) as pool_sync_index_writes,
   (pool_xda_writes - pool_async_xda_writes) as pool_sync_xda_writes,
   (pool_col_writes - pool_async_col_writes) as pool_sync_col_writes,
   (pool_write_time - pool_async_write_time) as pool_sync_write_time,
   case when (((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes))) > 0
      then decimal( (pool_write_time - pool_async_write_time) / double(((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes))), 5, 2 )
      else null
   end as avg_write_time
from
   mon_get_bufferpool_diff
where
   ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)) > 0
order by
   ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes) - (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)) desc
with UR;

echo ================================================================ ;
echo  BPL#WRASYNC: Bufferpool write statistics (asynchronous writes)  ;
echo ================================================================ ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,
   pool_async_data_writes,
   pool_async_index_writes,
   pool_async_xda_writes,
   pool_async_col_writes,
   pool_async_write_time,
   case when ((pool_data_writes + pool_index_writes + pool_xda_writes + pool_col_writes)) > 0
      then decimal( pool_async_write_time / double((pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes)), 5, 2 )
      else null
   end as avg_write_time
from
   mon_get_bufferpool_diff
where
   (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes) > 0
order by
   (pool_async_data_writes + pool_async_index_writes + pool_async_xda_writes + pool_async_col_writes) desc
with UR;

echo =========================================== ;
echo  CON#WAITT: Wait times at connection level  ;
echo =========================================== ;
echo ;

select
   member,
   cast(substr(application_name,1,20) as varchar(20)) as app_name,
   cast(substr(client_applname,1,20) as varchar(20)) as client_name,
   integer(application_handle) as handle,
   decimal((client_idle_wait_time / double(total_rqst_time)), 10, 2) as idle_rq_ratio,
   decimal((total_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_rqst_wt,
   decimal((lock_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_lock,
   decimal((log_disk_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_lg_dsk,
   decimal((log_buffer_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_lg_buf,


   decimal((lock_wait_time_global / double(total_rqst_time)) * 100, 5, 2) as pct_glb_lock,
   decimal((total_extended_latch_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_ltch,
   decimal((reclaim_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_rclm,
   decimal((cf_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_cf,
   decimal((prefetch_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_pftch,
   decimal((diaglog_write_wait_time / double(total_rqst_time)) * 100, 5, 2) as pct_diag,


   decimal((pool_read_time / double(total_rqst_time)) * 100, 5, 2) as pct_pool_r,
   decimal((direct_read_time / float(total_rqst_time)) * 100, 5, 2) as pct_dir_r,
   decimal((direct_write_time / float(total_rqst_time)) * 100, 5, 2) as pct_dir_w,
   decimal(((fcm_recv_wait_time+fcm_send_wait_time) / float(total_rqst_time)) * 100, 5, 2) as pct_fcm
from
   mon_get_connection_diff
where
   total_rqst_time <> 0
order by
   member asc, total_wait_time / double(total_rqst_time) desc
with UR;

echo ================================================ ;
echo  CON#STATS: Various metrics at connection level  ;
echo ================================================ ;
echo ;

select
   member,
   cast(substr(application_name,1,20) as varchar(20)) as app_name,
   cast(substr(client_applname,1,20) as varchar(20)) as client_name,
   integer(application_handle) as handle,
   total_app_commits,
   total_app_rollbacks,
   deadlocks,
   rows_modified,
   rows_read,
   rows_returned,
   total_sorts
,connection_reusability_status reuse_status,
cast(substr(reusability_status_reason,1,32) as varchar(32)) reusability_status_reason
from
   mon_get_connection_diff
where
   total_rqst_time <> 0
order by
   member asc, total_wait_time / double(total_rqst_time) desc
with UR;

echo =========================================================================== ;
echo  CON#PAGRW: Physical and logical page reads and writes at connection level  ;
echo =========================================================================== ;
echo ;

select
   member,
   cast(substr(application_name,1,20) as varchar(20)) as app_name,
   cast(substr(client_applname,1,20) as varchar(20)) as client_name,
   integer(application_handle) as handle,
   total_app_commits,
   total_app_rollbacks,
   pool_data_l_reads,
   pool_data_p_reads,
   pool_index_l_reads,
   pool_index_p_reads
, pool_col_l_reads, pool_col_p_reads from
   mon_get_connection_diff
where
   total_rqst_time <> 0
order by
   member asc, total_wait_time / double(total_rqst_time) desc
with UR;


echo =========================================== ;
echo  WLB#SLIST: Workload balancing server list  ;
echo =========================================== ;
echo ;

select
  member,
  cached_timestamp,
  cast(substr(hostname,1,20) as varchar(20)) as hostname,
  port_number,
  ssl_port_number,
  priority
from
  mon_get_serverlist_end
order by
  member asc, priority desc
with UR;

echo =========================================== ;
echo  CFG#REGVA: DB2 registry variable settings  ;
echo =========================================== ;
echo ;

select
   member,
   cast(substr(reg_var_name,1,50) as varchar(50)) as reg_var_name,
   cast(substr(reg_var_value,1,50) as varchar(50)) as reg_var_value,
   level
from
   env_get_reg_variables_end
order by
  reg_var_name,member
with UR;

echo ========================================= ;
echo  CFG#DB: Database configuration settings  ;
echo ========================================= ;
echo ;

select
   member,
   cast(substr(name,1,24) as varchar(24)) as name,
   case when value_flags = 'NONE' then '' else value_flags end flags,
   cast(substr(value,1,64) as varchar(64)) as current_value
from
   db_get_cfg_end
order by
  name asc, member asc
with UR;



echo ================================================== ;
echo  CFG#DBM: Database manager configuration settings  ;
echo ================================================== ;
echo ;

select
   cast(substr(name,1,24) as varchar(24)) as name,
   case when value_flags = 'NONE' then '' else value_flags end flags,
   cast(substr(value,1,64) as varchar(64)) as current_value
from
   dbmcfg_end
order by
   name asc
with UR;

echo ================================ ;
echo  INS#INFO: Instance information  ;
echo ================================ ;
echo ;

select
   cast(substr(inst_name,1,20) as varchar(20)) as inst_name,
   num_dbpartitions,
   num_members,
   cast(substr(service_level,1,20) as varchar(20)) as service_level,
   cast(substr(bld_level,1,40) as varchar(40)) as bld_level,
   cast(substr(ptf,1,40) as varchar(40)) as ptf
from
   env_inst_info_end
with UR;

echo ================================================= ;
echo  DB#MEMST: Database memory set information @ end  ;
echo ================================================= ;
echo ;

select
   member,
   cast(substr(memory_set_type,1,20) as varchar(20)) as set_type,
   cast(substr(db_name,1,20) as varchar(20)) as dbname,
   decimal( double(memory_set_used) / 1024, 10, 2 ) as memory_set_used_mb,
   decimal( double(memory_set_used_hwm) / 1024, 10, 2 ) as memory_set_used_hwm_mb
from
   mon_get_memory_set_end
order by
   member asc, memory_set_used desc
with UR;

echo ========================================= ;
echo  DB#MEMPL: Memory pool information @ end  ;
echo ========================================= ;
echo ;

select
   member,
   cast(substr(memory_pool_type,1,20) as varchar(20)) as memory_pool_type,
   cast(substr(db_name,1,20) as varchar(20)) as db_name,
   decimal( double(memory_pool_used) / 1024, 10, 2 ) as memory_pool_used_mb,
   decimal( double(memory_pool_used_hwm) / 1024, 10, 2 ) as memory_pool_used_hwm_mb
from
   mon_get_memory_pool_end
order by
   member asc, memory_pool_used desc
with UR;

echo ================================= ;
echo  DB#SEQIN: Sequences information  ;
echo ================================= ;
echo ;

select
   cast(substr(seqschema,1,40) as varchar(40)) as seqschema,
   cast(substr(seqname,1,40) as varchar(40)) as seqname,
   seqtype,
   cache,
   order
from
  syscat_sequences
with UR;

echo ################################################################################################################### ;
echo  pureScale-specific metrics ;
echo ################################################################################################################### ;
echo;

echo ======================================================== ;
echo  CF#GBPIO: Group bufferpool IO statistics by tablespace  ;
echo ======================================================== ;
echo ;

select
   member,
   cast(substr(tbsp_name,1,20) as varchar(20)) as tbsp_name,

   -- Data pages

   case when pool_data_gbp_l_reads > 0
      then decimal( (double(pool_data_gbp_l_reads - pool_data_gbp_p_reads) / pool_data_gbp_l_reads) * 100, 5, 2 )
      else null
   end as data_gbp_hitratio,

   case when (pool_data_l_reads + pool_temp_data_l_reads) > 0
      then decimal( (double(pool_data_lbp_pages_found - pool_async_data_lbp_pages_found) / (pool_data_l_reads + pool_temp_data_l_reads)) * 100, 5, 2 )
      else null
   end as data_lbp_hitratio,

   case when pool_data_gbp_l_reads > 0
      then decimal( (double(pool_data_gbp_invalid_pages - pool_async_data_gbp_invalid_pages) / pool_data_gbp_l_reads) * 100, 5, 2 )
      else null
   end as pct_data_invalid,

   -- Index pages

   case when pool_index_gbp_l_reads > 0
      then decimal( (double(pool_index_gbp_l_reads - pool_index_gbp_p_reads) / pool_index_gbp_l_reads) * 100, 5, 2 )
      else null
   end as index_gbp_hitratio,

   case when (pool_index_l_reads + pool_temp_index_l_reads) > 0
      then decimal( (double(pool_index_lbp_pages_found - pool_async_index_lbp_pages_found) / (pool_index_l_reads + pool_temp_index_l_reads)) * 100, 5, 2 )
      else null
   end as index_lbp_hitratio,

   case when pool_index_gbp_l_reads > 0
      then decimal( (double(pool_index_gbp_invalid_pages - pool_async_index_gbp_invalid_pages) / pool_index_gbp_l_reads) * 100, 5, 2 )
      else null
   end as pct_index_invalid
from
   mon_get_tablespace_diff
where
   pool_data_gbp_l_reads + pool_index_gbp_l_reads > 0
order by
   pool_data_gbp_l_reads + pool_data_gbp_p_reads + pool_index_gbp_l_reads + pool_index_gbp_p_reads desc
with UR;


echo ====================================================== ;
echo  CF#GBPHR: Group bufferpool data and index hit ratios  ;
echo ====================================================== ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,

   -- Data pages

   pool_data_gbp_l_reads,
   pool_data_gbp_p_reads,
   case when pool_data_gbp_l_reads > 0
      then decimal( ( double(pool_data_gbp_l_reads - pool_data_gbp_p_reads) / pool_data_gbp_l_reads ) * 100 , 5, 2 )
      else null
   end as data_gbp_hitratio,

   -- Index pages

   pool_index_gbp_l_reads,
   pool_index_gbp_p_reads,
   case when pool_index_gbp_l_reads > 0
      then decimal( ( double(pool_index_gbp_l_reads - pool_index_gbp_p_reads) / pool_index_gbp_l_reads ) * 100, 5, 2 )
      else null
   end as index_gbp_hitratio
from
   mon_get_bufferpool_diff
where
   (pool_data_gbp_l_reads ) > 0 or (pool_index_gbp_l_reads ) > 0
order by
   pool_read_time desc
with UR;


echo ==================================================== ;
echo  CF#GBPIV: Group bufferpool invalid page statistics  ;
echo ==================================================== ;
echo ;

select
   member,
   cast(substr(bp_name,1,20) as varchar(20)) as bp_name,

   -- Data pages

   case when pool_data_gbp_l_reads > 0
      then decimal( ( double(pool_data_gbp_invalid_pages - pool_async_data_gbp_invalid_pages) / pool_data_gbp_l_reads ) * 100, 5, 2 )
      else null
   end as pct_data_gbp_invalid,

   -- Index pages

   case when pool_index_gbp_l_reads > 0
      then decimal( ( double(pool_index_gbp_invalid_pages - pool_async_index_gbp_invalid_pages) / pool_index_gbp_l_reads ) * 100, 5, 2 )
      else null
   end as pct_index_gbp_invalid
from
   mon_get_bufferpool_diff
where
   (pool_data_gbp_l_reads) > 0 or (pool_index_gbp_l_reads) > 0
order by
   pool_read_time desc
with UR;

echo ============================================================================ ;
echo  CF#GBPDP: Tablespace data page prefetching statistics for group bufferpool  ;
echo ============================================================================ ;
echo ;

select
  member,
  cast(substr(tbsp_name,1,30) as varchar(30)) as tbsp_name,
  pool_async_data_gbp_l_reads,
  pool_async_data_gbp_p_reads,
  pool_async_data_lbp_pages_found,
  pool_async_data_gbp_invalid_pages,
  pool_async_data_gbp_indep_pages_found_in_lbp
from
        mon_get_tablespace_diff
where
   pool_async_data_gbp_l_reads > 0
order by
        member asc, pool_async_data_gbp_l_reads  desc
with UR;

echo ============================================================================= ;
echo  CF#GBPIP: Tablespace index page prefetching statistics for group bufferpool  ;
echo ============================================================================= ;
echo ;

select
  member,
  cast(substr(tbsp_name,1,30) as varchar(30)) as tbsp_name,
  pool_async_index_gbp_l_reads,
  pool_async_index_gbp_p_reads,
  pool_async_index_lbp_pages_found,
  pool_async_index_gbp_invalid_pages,
  pool_async_index_gbp_indep_pages_found_in_lbp
from
        mon_get_tablespace_diff
where
   pool_async_index_gbp_l_reads > 0
order by
        member asc, pool_async_index_gbp_l_reads  desc
with UR;

echo ===================================================== ;
echo  CF#GBPFL: Count of group bufferpool full conditions  ;
echo ===================================================== ;
echo ;

select
   member,
   num_gbp_full
from
   mon_get_group_bufferpool_diff
order by
   member asc
with UR;

echo ======================================================== ;
echo  PAG#RCM: Page reclaim metrics for index and data pages  ;
echo ======================================================== ;
echo ;

select
   member,
   cast(substr(tabschema,1,20) as varchar(20)) as tabschema,
   cast(substr(tabname,1,40) as varchar(40)) as tabname,
   cast(substr(objtype,1,10) as varchar(10)) as objtype,
   data_partition_id,
   iid,
   (page_reclaims_x + page_reclaims_s) as page_reclaims,
   reclaim_wait_time
from
   mon_get_page_access_info_diff
where
  reclaim_wait_time > 0
order by
   reclaim_wait_time desc
with UR;

echo =============================================== ;
echo  PAG#RCSMP: Page reclaim metrics for SMP pages  ;
echo =============================================== ;
echo ;

select
   member,
   cast(substr(tabschema,1,20) as varchar(20)) as tabschema,
   cast(substr(tabname,1,40) as varchar(40)) as tabname,
   cast(substr(objtype,1,10) as varchar(10)) as objtype,
   data_partition_id,
   iid,
   (spacemappage_page_reclaims_x + spacemappage_page_reclaims_s) as smp_page_reclaims,
   spacemappage_reclaim_wait_time as smp_page_reclaim_wait_time
from
   mon_get_page_access_info_diff
where
  spacemappage_reclaim_wait_time > 0
order by
   spacemappage_reclaim_wait_time desc
with UR;

echo ============================================================================= ;
echo  CF#RTTIM: Round-trip CF command execution counts and average response times  ;
echo ============================================================================= ;
echo ;

select
   member,
   id,
   cast(substr(cf_cmd_name,1,30) as varchar(30)) as cf_cmd_name,
   total_cf_requests,
   decimal( double(total_cf_wait_time_micro) / total_cf_requests, 15, 2 ) as avg_cf_request_time_micro
from
   mon_get_cf_wait_time_diff
where
   total_cf_requests > 0
order by
   id asc, total_cf_requests desc
with UR;

echo ================================================= ;
echo  CF#CMDCT: Aggregate CF command execution counts  ;
echo ================================================= ;
echo ;

select
   member,
   id,
   sum(total_cf_requests) as total_cf_requests
from
   mon_get_cf_wait_time_diff
group by
   rollup(member, id)
order by
   member asc, id asc, total_cf_requests desc
with UR;

echo ======================================================================= ;
echo  CF#CMDTM: CF-side command execution counts and average response times  ;
echo ======================================================================= ;
echo ;

select
   d.id,
   cast(substr(cf_cmd_name,1,50) as varchar(50)) as cf_cmd_name,
   total_cf_requests,
   decimal( (total_cf_requests / double(total_total_cf_requests)) * 100, 5, 2 ) as pct_total_cf_cmd,
   decimal( double(total_cf_cmd_time_micro) / total_cf_requests, 15, 2 ) as avg_cf_request_time_micro
from
   mon_get_cf_cmd_diff as d,
   ( select id, sum(total_cf_requests) as total_total_cf_requests
     from mon_get_cf_cmd_diff
     group by id ) as c
where
   d.total_cf_requests > 0 and d.id = c.id
order by
   id asc, total_cf_requests desc
with UR;

echo ================================================== ;
echo  CF#CMDTO: CF-side total command execution counts  ;
echo ================================================== ;
echo ;

select
   id,
   sum(total_cf_requests) as total_cf_requests
from
   mon_get_cf_cmd_diff
group by
   id
order by
   id asc
with UR;


echo ========================================== ;
echo  CF#SYSRE: CF system resource information  ;
echo ========================================== ;
echo ;

select
   id,
   cast(substr(name,1,30) as varchar(30)) as name,
   cast(substr(value,1,50) as varchar(50)) as value,
   cast(substr(unit,1,10) as varchar(10)) as unit
from
   env_cf_sys_resources_end
order by
   id asc, name asc
with UR;

echo ======================================== ;
echo  CF#SIZE: CF structure size information  ;
echo ======================================== ;
echo ;

select
   id,
   cast(substr(host_name,1,40) as varchar(40)) as hostname,

   decimal(((double(current_cf_mem_size) * 4) / 1024), 10, 2) as curr_mem_mb,
   decimal(((double(configured_cf_mem_size) * 4) / 1024), 10, 2) as conf_mem_mb,

   decimal(((double(current_cf_gbp_size) * 4) / 1024), 10, 2) as curr_gbp_mb,
   decimal(((double(configured_cf_gbp_size) * 4) / 1024), 10, 2) as conf_gbp_mb,
   decimal(((double(target_cf_gbp_size) * 4) / 1024), 10, 2) as trgt_gbp_mb,

   decimal(((double(current_cf_lock_size) * 4) / 1024), 10, 2) as curr_lock_mb,
   decimal(((double(configured_cf_lock_size) * 4) / 1024), 10, 2) as conf_lock_mb,
   decimal(((double(target_cf_lock_size) * 4) / 1024), 10, 2) as trgt_lock_mb,

   decimal(((double(current_cf_sca_size) * 4) / 1024), 10, 2) as curr_sca_mb,
   decimal(((double(configured_cf_sca_size) * 4) / 1024), 10, 2) as conf_sca_mb,
   decimal(((double(target_cf_sca_size) * 4) / 1024), 10, 2) as trgt_sca_mb

from
   mon_get_cf_end
order by
   id asc
with UR;


echo ################################################################################################################### ;
echo BLU-related metrics ;
echo ################################################################################################################### ;
echo;

echo ================================================== ;
echo  BLU#PAGDI: Partial early aggregation / distincts  ;
echo ================================================== ;
echo ;

select
   member,
   sum(total_peds) total_peds,
   sum(post_threshold_peds) post_threshold_peds,
   sum(disabled_peds) disabled_peds,
   sum(total_peas) total_peas,
   sum(post_threshold_peas) post_threshold_peas
from
   mon_get_workload_diff
group by
   member
order by
   member
with UR;

