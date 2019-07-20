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
echo  1. Change to an empty directory                        ;
echo  2. Connect to database                                 ;
echo  3. Run with CLP as in 'db2 -tvf db2mon_export.sql'     ;
echo                                                         ;
echo  The script will create several IXF files to be         ;
echo  imported with db2mon_import.sql and analyzed with      ;
echo  db2mon_report.sql.  This is often done after the files ;
echo  have been moved to another system for analysis.        ;
echo                                                         ;
echo  Next step after db2mon_export: optionally move IXF     ;
echo  files to a new system for offline analysis, and then   ;
echo  run db2mon_import and then db2mon_report to analyze.   ;
echo                                                         ;
echo ********************************************************;
echo                                                         ;
echo                               ;
echo ***************************** ;
echo Checking db2mon prerequisites ;
echo ***************************** ;
echo                               ;
with
utemp_check as ( 
  select count(*) utemp_count from syscat.tablespaces where datatype = 'U' ),
config_check as (
  select 
    cast(substr(name,1,20) as varchar(20)) name, 
    cast(substr(value,1,20) as varchar(20)) value
  from table(db_get_cfg(-1)) where 
    name in ('mon_req_metrics','mon_act_metrics','mon_obj_metrics') ),
req_check as (
  select value req_value from config_check where name = 'mon_req_metrics' ),
act_check as (
  select value act_value from config_check where name = 'mon_act_metrics' ),
obj_check as (
  select value obj_value from config_check where name = 'mon_obj_metrics' )
select t.prereq "db2mon Prerequisite", t.msg "Status"
from
  utemp_check,
  req_check,
  act_check,
  obj_check,
  table( values
    ( 'MON_REQ_METRICS correct? ', 
       case when req_value in ('BASE','EXTENDED') then 'OK (currently ' || rtrim(req_value) || ')' 
       else '******** Needs to be BASE or EXTENDED to get full data collection' end ),
    ( 'MON_ACT_METRICS correct? ', case when act_value in ('BASE','EXTENDED') then 'OK (currently ' || rtrim(act_value) || ')' 
       else '******** Needs to be BASE or EXTENDED to get full data collection' end ),
    ( 'MON_OBJ_METRICS correct? ', case when obj_value in ('BASE','EXTENDED') then 'OK (currently ' || rtrim(obj_value) || ')' 
       else '******** Needs to be BASE or EXTENDED to get full data collection' end ) ) as t(prereq,msg);

select cast(substr(current schema,1,24) as varchar(24)) as current_schema from sysibm.sysdummy1;

export to db_get_cfg_start.ixf of ixf select current timestamp ts, t.* from table (db_get_cfg( -2) ) t with UR;
export to dbmcfg_start.ixf of ixf select current timestamp ts, t.* from sysibmadm.dbmcfg t with UR;
export to env_cf_sys_resources_start.ixf of ixf select current timestamp ts, t.* from sysibmadm.env_cf_sys_resources t with UR;
export to env_get_reg_variables_start.ixf of ixf select current timestamp ts, t.* from table (env_get_reg_variables( -2) ) t with UR;
export to env_get_system_resources_start.ixf of ixf select current timestamp ts, t.* from table (sysproc.env_get_system_resources( ) ) t with UR;
export to env_inst_info_start.ixf of ixf select current timestamp ts, t.* from sysibmadm.env_inst_info t with UR;
export to mon_get_bufferpool_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_bufferpool( null, -2) ) t with UR;
export to mon_get_cf_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_cf( null) ) t with UR;
export to mon_get_cf_cmd_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_cf_cmd( null) ) t with UR;
export to mon_get_cf_wait_time_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_cf_wait_time( -2) ) t with UR;
export to mon_get_connection_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_connection( null, -2) ) t with UR;
export to mon_get_extended_latch_wait_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_extended_latch_wait( -2) ) t with UR;
export to mon_get_group_bufferpool_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_group_bufferpool( -2) ) t with UR;
export to mon_get_memory_pool_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_memory_pool( 'database', null, -2) ) t with UR;
export to mon_get_memory_set_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_memory_set( null, null, -2) ) t with UR;
export to mon_get_page_access_info_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_page_access_info( null, null, -2) ) t with UR;
export to mon_get_pkg_cache_stmt_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_pkg_cache_stmt( null, null, null, -2) ) t where stmt_text not like 'CALL dbms_alert.sleep%' order by coord_stmt_exec_time desc with UR;
export to mon_get_serverlist_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_serverlist( -2) ) t with UR;
export to mon_get_table_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_table( null, null, -2) ) t with UR;
export to mon_get_tablespace_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_tablespace( null, -2) ) t with UR;
export to mon_get_transaction_log_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_transaction_log( -2) ) t with UR;
export to mon_get_utility_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_utility( -2) ) t with UR;
export to mon_get_workload_start.ixf of ixf select current timestamp ts, t.* from table (mon_get_workload( null, -2) ) t with UR;
export to mon_current_sql_plus_start.ixf of ixf with 
  mga ( ts, count,
coord_member,application_handle,uow_id,activity_id,executable_id,package_name,section_number,active_sorts,active_sorts_top,active_sort_consumers,active_sort_consumers_top,sort_shrheap_allocated,sort_shrheap_top,post_threshold_sorts,post_shrthreshold_sorts,post_threshold_hash_joins,post_shrthreshold_hash_joins,post_threshold_hash_grpbys,post_threshold_olap_funcs,total_act_time,total_act_wait_time,lock_wait_time,pool_read_time,direct_read_time,direct_write_time,fcm_recv_wait_time,fcm_send_wait_time,total_extended_latch_wait_time,log_disk_wait_time,cf_wait_time,reclaim_wait_time,spacemappage_reclaim_wait_time) as (
    select current timestamp, count(*),       coord_member,application_handle,uow_id,activity_id,
      min(executable_id),min(package_name),min(section_number),
      sum(active_sorts),sum(active_sorts_top),sum(active_sort_consumers),sum(active_sort_consumers_top),sum(sort_shrheap_allocated),sum(sort_shrheap_top),sum(post_threshold_sorts),sum(post_shrthreshold_sorts),sum(post_threshold_hash_joins),sum(post_shrthreshold_hash_joins),sum(post_threshold_hash_grpbys),sum(post_threshold_olap_funcs),sum(total_act_time),sum(total_act_wait_time),sum(lock_wait_time),sum(pool_read_time),sum(direct_read_time),sum(direct_write_time),sum(fcm_recv_wait_time),sum(fcm_send_wait_time),sum(total_extended_latch_wait_time),sum(log_disk_wait_time),sum(cf_wait_time),sum(reclaim_wait_time),sum(spacemappage_reclaim_wait_time) 
    from table(mon_get_activity(null,-2))
    group by coord_member,application_handle,uow_id,activity_id)
select ts, count,mcs.coord_member,mcs.application_handle,mcs.uow_id,mcs.activity_id,mcs.elapsed_time_sec,mcs.total_cpu_time,mcs.rows_read,mcs.direct_reads,mcs.direct_writes,mga.executable_id,mga.package_name,mga.section_number,mga.active_sorts,mga.active_sorts_top,mga.active_sort_consumers,mga.active_sort_consumers_top,mga.sort_shrheap_allocated,mga.sort_shrheap_top,mga.post_threshold_sorts,mga.post_shrthreshold_sorts,mga.post_threshold_hash_joins,mga.post_shrthreshold_hash_joins,mga.post_threshold_hash_grpbys,mga.post_threshold_olap_funcs,mga.total_act_time,mga.total_act_wait_time,mga.lock_wait_time,mga.pool_read_time,mga.direct_read_time,mga.direct_write_time,mga.fcm_recv_wait_time,mga.fcm_send_wait_time,mga.total_extended_latch_wait_time,mga.log_disk_wait_time,mga.cf_wait_time,mga.reclaim_wait_time,mga.spacemappage_reclaim_wait_time,mcs.stmt_text
from 
  sysibmadm.mon_current_sql mcs, mga 
where 
  mcs.application_handle = mga.application_handle and 
  mcs.coord_member = mga.coord_member and 
  mcs.uow_id = mga.uow_id and 
  mcs.activity_id = mga.activity_id
 with UR;
export to mon_get_locks_start.ixf of ixf select
   distinct
   member,
   application_handle,
   lock_mode,
   lock_status,
   lock_object_type,
   lock_name,
   tbsp_id,
   tab_file_id
from
   table ( mon_get_locks(null,-2) ) with UR;
call dbms_alert.sleep(30);
select current timestamp as monitor_end_time from sysibm.sysdummy1;
export to db_get_cfg_end.ixf of ixf select current timestamp ts, t.* from table (db_get_cfg( -2) ) t with UR;
export to dbmcfg_end.ixf of ixf select current timestamp ts, t.* from sysibmadm.dbmcfg t with UR;
export to env_cf_sys_resources_end.ixf of ixf select current timestamp ts, t.* from sysibmadm.env_cf_sys_resources t with UR;
export to env_get_reg_variables_end.ixf of ixf select current timestamp ts, t.* from table (env_get_reg_variables( -2) ) t with UR;
export to env_get_system_resources_end.ixf of ixf select current timestamp ts, t.* from table (sysproc.env_get_system_resources( ) ) t with UR;
export to env_inst_info_end.ixf of ixf select current timestamp ts, t.* from sysibmadm.env_inst_info t with UR;
export to mon_get_bufferpool_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_bufferpool( null, -2) ) t with UR;
export to mon_get_cf_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_cf( null) ) t with UR;
export to mon_get_cf_cmd_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_cf_cmd( null) ) t with UR;
export to mon_get_cf_wait_time_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_cf_wait_time( -2) ) t with UR;
export to mon_get_connection_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_connection( null, -2) ) t with UR;
export to mon_get_extended_latch_wait_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_extended_latch_wait( -2) ) t with UR;
export to mon_get_group_bufferpool_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_group_bufferpool( -2) ) t with UR;
export to mon_get_memory_pool_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_memory_pool( 'database', null, -2) ) t with UR;
export to mon_get_memory_set_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_memory_set( null, null, -2) ) t with UR;
export to mon_get_page_access_info_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_page_access_info( null, null, -2) ) t with UR;
export to mon_get_pkg_cache_stmt_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_pkg_cache_stmt( null, null, null, -2) ) t where stmt_text not like 'CALL dbms_alert.sleep%' order by coord_stmt_exec_time desc with UR;
export to mon_get_serverlist_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_serverlist( -2) ) t with UR;
export to mon_get_table_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_table( null, null, -2) ) t with UR;
export to mon_get_tablespace_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_tablespace( null, -2) ) t with UR;
export to mon_get_transaction_log_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_transaction_log( -2) ) t with UR;
export to mon_get_utility_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_utility( -2) ) t with UR;
export to mon_get_workload_end.ixf of ixf select current timestamp ts, t.* from table (mon_get_workload( null, -2) ) t with UR;
export to mon_current_sql_plus_end.ixf of ixf with 
  mga ( ts, count,
coord_member,application_handle,uow_id,activity_id,executable_id,package_name,section_number,active_sorts,active_sorts_top,active_sort_consumers,active_sort_consumers_top,sort_shrheap_allocated,sort_shrheap_top,post_threshold_sorts,post_shrthreshold_sorts,post_threshold_hash_joins,post_shrthreshold_hash_joins,post_threshold_hash_grpbys,post_threshold_olap_funcs,total_act_time,total_act_wait_time,lock_wait_time,pool_read_time,direct_read_time,direct_write_time,fcm_recv_wait_time,fcm_send_wait_time,total_extended_latch_wait_time,log_disk_wait_time,cf_wait_time,reclaim_wait_time,spacemappage_reclaim_wait_time) as (
    select current timestamp, count(*),       coord_member,application_handle,uow_id,activity_id,
      min(executable_id),min(package_name),min(section_number),
      sum(active_sorts),sum(active_sorts_top),sum(active_sort_consumers),sum(active_sort_consumers_top),sum(sort_shrheap_allocated),sum(sort_shrheap_top),sum(post_threshold_sorts),sum(post_shrthreshold_sorts),sum(post_threshold_hash_joins),sum(post_shrthreshold_hash_joins),sum(post_threshold_hash_grpbys),sum(post_threshold_olap_funcs),sum(total_act_time),sum(total_act_wait_time),sum(lock_wait_time),sum(pool_read_time),sum(direct_read_time),sum(direct_write_time),sum(fcm_recv_wait_time),sum(fcm_send_wait_time),sum(total_extended_latch_wait_time),sum(log_disk_wait_time),sum(cf_wait_time),sum(reclaim_wait_time),sum(spacemappage_reclaim_wait_time) 
    from table(mon_get_activity(null,-2))
    group by coord_member,application_handle,uow_id,activity_id)
select ts, count,mcs.coord_member,mcs.application_handle,mcs.uow_id,mcs.activity_id,mcs.elapsed_time_sec,mcs.total_cpu_time,mcs.rows_read,mcs.direct_reads,mcs.direct_writes,mga.executable_id,mga.package_name,mga.section_number,mga.active_sorts,mga.active_sorts_top,mga.active_sort_consumers,mga.active_sort_consumers_top,mga.sort_shrheap_allocated,mga.sort_shrheap_top,mga.post_threshold_sorts,mga.post_shrthreshold_sorts,mga.post_threshold_hash_joins,mga.post_shrthreshold_hash_joins,mga.post_threshold_hash_grpbys,mga.post_threshold_olap_funcs,mga.total_act_time,mga.total_act_wait_time,mga.lock_wait_time,mga.pool_read_time,mga.direct_read_time,mga.direct_write_time,mga.fcm_recv_wait_time,mga.fcm_send_wait_time,mga.total_extended_latch_wait_time,mga.log_disk_wait_time,mga.cf_wait_time,mga.reclaim_wait_time,mga.spacemappage_reclaim_wait_time,mcs.stmt_text
from 
  sysibmadm.mon_current_sql mcs, mga 
where 
  mcs.application_handle = mga.application_handle and 
  mcs.coord_member = mga.coord_member and 
  mcs.uow_id = mga.uow_id and 
  mcs.activity_id = mga.activity_id
 with UR;
export to mon_get_locks_end.ixf of ixf select
   distinct
   member,
   application_handle,
   lock_mode,
   lock_status,
   lock_object_type,
   lock_name,
   tbsp_id,
   tab_file_id
from
   table ( mon_get_locks(null,-2) ) with UR;
export to syscat_tables.ixf of ixf select * from syscat.tables with UR;
export to syscat_tablespaces.ixf of ixf select * from syscat.tablespaces with UR;
export to syscat_bufferpools.ixf of ixf select * from syscat.bufferpools with UR;
export to syscat_sequences.ixf of ixf select * from syscat.sequences with UR;
