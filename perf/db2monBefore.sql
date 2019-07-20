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
echo  1. Connect to database                                 ;
echo  2. Ensure a user temporary tablespace already exists   ;
echo     e.g. 'db2 create user temporary tablespace utemp'   ;
echo  3. Run with CLP as in 'db2 -tvf db2mon.sql'            ;
echo                                                         ;
echo  You can also run with db2mon.sh, which connects to the ;
echo  database and creates the tablespace, etc. automatically;
echo                                                         ;
echo  Report starts at string 'REPORT STARTS HERE'.          ;
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
    ( 'User temp tablespace? ', 
       case when utemp_count != 0 then 'OK (' || varchar(utemp_count) || ' defined)'  
       else '******** Missing - ensure user temp tablespace exists before running db2mon.sql' end ),
    ( 'MON_REQ_METRICS correct? ', 
       case when req_value in ('BASE','EXTENDED') then 'OK (currently ' || rtrim(req_value) || ')' 
       else '******** Needs to be BASE or EXTENDED to get full data collection' end ),
    ( 'MON_ACT_METRICS correct? ', case when act_value in ('BASE','EXTENDED') then 'OK (currently ' || rtrim(act_value) || ')' 
       else '******** Needs to be BASE or EXTENDED to get full data collection' end ),
    ( 'MON_OBJ_METRICS correct? ', case when obj_value in ('BASE','EXTENDED') then 'OK (currently ' || rtrim(obj_value) || ')' 
       else '******** Needs to be BASE or EXTENDED to get full data collection' end ) ) as t(prereq,msg);

select cast(substr(current schema,1,24) as varchar(24)) as current_schema from sysibm.sysdummy1;

drop table session.db_get_cfg_start;
drop table session.db_get_cfg_end;
declare global temporary table db_get_cfg_start as ( select current timestamp ts,member, name, value, value_flags from table (db_get_cfg( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table db_get_cfg_end like session.db_get_cfg_start on commit preserve rows not logged organize by row;
drop table session.db_get_cfg_diff;
declare global temporary table db_get_cfg_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, name, value, value_flags from table (db_get_cfg( -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_db_get_cfg_start on session.db_get_cfg_start (member, name);
create index session.idx_db_get_cfg_end on session.db_get_cfg_end (member, name);
drop table session.dbmcfg_start;
drop table session.dbmcfg_end;
declare global temporary table dbmcfg_start as ( select current timestamp ts,name, value, value_flags from sysibmadm.dbmcfg) with no data on commit preserve rows not logged organize by row;
declare global temporary table dbmcfg_end like session.dbmcfg_start on commit preserve rows not logged organize by row;
drop table session.dbmcfg_diff;
declare global temporary table dbmcfg_diff as ( select cast(null as integer) ts_delta, current timestamp ts,name, value, value_flags from sysibmadm.dbmcfg) with no data on commit preserve rows not logged organize by row;
create index session.idx_dbmcfg_start on session.dbmcfg_start (name);
create index session.idx_dbmcfg_end on session.dbmcfg_end (name);
drop table session.env_cf_sys_resources_start;
drop table session.env_cf_sys_resources_end;
declare global temporary table env_cf_sys_resources_start as ( select current timestamp ts,id, name, value, unit from sysibmadm.env_cf_sys_resources) with no data on commit preserve rows not logged organize by row;
declare global temporary table env_cf_sys_resources_end like session.env_cf_sys_resources_start on commit preserve rows not logged organize by row;
drop table session.env_cf_sys_resources_diff;
declare global temporary table env_cf_sys_resources_diff as ( select cast(null as integer) ts_delta, current timestamp ts,id, name, value, unit from sysibmadm.env_cf_sys_resources) with no data on commit preserve rows not logged organize by row;
create index session.idx_env_cf_sys_resources_start on session.env_cf_sys_resources_start (id, name);
create index session.idx_env_cf_sys_resources_end on session.env_cf_sys_resources_end (id, name);
drop table session.env_get_reg_variables_start;
drop table session.env_get_reg_variables_end;
declare global temporary table env_get_reg_variables_start as ( select current timestamp ts,member, reg_var_name, reg_var_value, level from table (env_get_reg_variables( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table env_get_reg_variables_end like session.env_get_reg_variables_start on commit preserve rows not logged organize by row;
drop table session.env_get_reg_variables_diff;
declare global temporary table env_get_reg_variables_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, reg_var_name, reg_var_value, level from table (env_get_reg_variables( -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_env_get_reg_variables_start on session.env_get_reg_variables_start (member, reg_var_name);
create index session.idx_env_get_reg_variables_end on session.env_get_reg_variables_end (member, reg_var_name);
drop table session.env_get_system_resources_start;
drop table session.env_get_system_resources_end;
declare global temporary table env_get_system_resources_start as ( select current timestamp ts,member, os_name, host_name, os_version, os_release, cpu_total, cpu_online, cpu_configured, cpu_speed, cpu_hmt_degree, memory_total, memory_free, cpu_load_short, cpu_load_medium, cpu_load_long, cpu_usage_total, swap_pages_in, swap_pages_out from table (sysproc.env_get_system_resources( ) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table env_get_system_resources_end like session.env_get_system_resources_start on commit preserve rows not logged organize by row;
drop table session.env_get_system_resources_diff;
declare global temporary table env_get_system_resources_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, os_name, host_name, os_version, os_release, cpu_total, cpu_online, cpu_configured, cpu_speed, cpu_hmt_degree, memory_total, memory_free, cpu_load_short, cpu_load_medium, cpu_load_long, cpu_usage_total, swap_pages_in, swap_pages_out from table (sysproc.env_get_system_resources( ) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_env_get_system_resources_start on session.env_get_system_resources_start (member);
create index session.idx_env_get_system_resources_end on session.env_get_system_resources_end (member);
drop table session.env_inst_info_start;
drop table session.env_inst_info_end;
declare global temporary table env_inst_info_start as ( select current timestamp ts,inst_name, num_dbpartitions, service_level, bld_level, ptf, num_members from sysibmadm.env_inst_info) with no data on commit preserve rows not logged organize by row;
declare global temporary table env_inst_info_end like session.env_inst_info_start on commit preserve rows not logged organize by row;
drop table session.mon_get_bufferpool_start;
drop table session.mon_get_bufferpool_end;
declare global temporary table mon_get_bufferpool_start as ( select current timestamp ts,member, bp_name, bp_cur_buffsz, automatic, pool_read_time, pool_data_l_reads, pool_data_p_reads, pool_async_read_time, pool_async_data_reads, pool_async_index_reads, pool_async_xda_reads, pool_data_writes, pool_async_data_writes, pool_data_lbp_pages_found, pool_async_data_lbp_pages_found, pool_temp_data_l_reads, pool_temp_data_p_reads, pool_index_lbp_pages_found, pool_async_index_lbp_pages_found, pool_temp_index_l_reads, pool_temp_index_p_reads, pool_write_time, pool_async_write_time, pool_index_l_reads, pool_index_p_reads, pool_index_writes, pool_async_index_writes, pool_xda_l_reads, pool_temp_xda_l_reads, pool_xda_p_reads, pool_temp_xda_p_reads, pool_xda_writes, pool_async_xda_writes, pool_data_gbp_l_reads, pool_data_gbp_p_reads, pool_index_gbp_l_reads, pool_index_gbp_p_reads, pool_data_gbp_invalid_pages, pool_async_data_gbp_invalid_pages, pool_index_gbp_invalid_pages, pool_async_index_gbp_invalid_pages, pool_col_l_reads, pool_col_p_reads, pool_async_col_reads, pool_col_writes, pool_async_col_writes, pool_col_lbp_pages_found, pool_async_col_lbp_pages_found, pool_temp_col_l_reads, pool_temp_col_p_reads from table (mon_get_bufferpool( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_bufferpool_end like session.mon_get_bufferpool_start on commit preserve rows not logged organize by row;
drop table session.mon_get_bufferpool_diff;
declare global temporary table mon_get_bufferpool_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, bp_name, bp_cur_buffsz, automatic, pool_read_time, pool_data_l_reads, pool_data_p_reads, pool_async_read_time, pool_async_data_reads, pool_async_index_reads, pool_async_xda_reads, pool_data_writes, pool_async_data_writes, pool_data_lbp_pages_found, pool_async_data_lbp_pages_found, pool_temp_data_l_reads, pool_temp_data_p_reads, pool_index_lbp_pages_found, pool_async_index_lbp_pages_found, pool_temp_index_l_reads, pool_temp_index_p_reads, pool_write_time, pool_async_write_time, pool_index_l_reads, pool_index_p_reads, pool_index_writes, pool_async_index_writes, pool_xda_l_reads, pool_temp_xda_l_reads, pool_xda_p_reads, pool_temp_xda_p_reads, pool_xda_writes, pool_async_xda_writes, pool_data_gbp_l_reads, pool_data_gbp_p_reads, pool_index_gbp_l_reads, pool_index_gbp_p_reads, pool_data_gbp_invalid_pages, pool_async_data_gbp_invalid_pages, pool_index_gbp_invalid_pages, pool_async_index_gbp_invalid_pages, pool_col_l_reads, pool_col_p_reads, pool_async_col_reads, pool_col_writes, pool_async_col_writes, pool_col_lbp_pages_found, pool_async_col_lbp_pages_found, pool_temp_col_l_reads, pool_temp_col_p_reads from table (mon_get_bufferpool( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_bufferpool_start on session.mon_get_bufferpool_start (member, bp_name);
create index session.idx_mon_get_bufferpool_end on session.mon_get_bufferpool_end (member, bp_name);
drop table session.mon_get_cf_start;
drop table session.mon_get_cf_end;
declare global temporary table mon_get_cf_start as ( select current timestamp ts,id, host_name, current_cf_mem_size, configured_cf_mem_size, current_cf_gbp_size, configured_cf_gbp_size, target_cf_gbp_size, current_cf_lock_size, configured_cf_lock_size, target_cf_lock_size, current_cf_sca_size, configured_cf_sca_size, target_cf_sca_size from table (mon_get_cf( null) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_cf_end like session.mon_get_cf_start on commit preserve rows not logged organize by row;
drop table session.mon_get_cf_diff;
declare global temporary table mon_get_cf_diff as ( select cast(null as integer) ts_delta, current timestamp ts,id, host_name, current_cf_mem_size, configured_cf_mem_size, current_cf_gbp_size, configured_cf_gbp_size, target_cf_gbp_size, current_cf_lock_size, configured_cf_lock_size, target_cf_lock_size, current_cf_sca_size, configured_cf_sca_size, target_cf_sca_size from table (mon_get_cf( null) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_cf_start on session.mon_get_cf_start (id);
create index session.idx_mon_get_cf_end on session.mon_get_cf_end (id);
drop table session.mon_get_cf_cmd_start;
drop table session.mon_get_cf_cmd_end;
declare global temporary table mon_get_cf_cmd_start as ( select current timestamp ts,hostname, id, cf_cmd_name, total_cf_requests, total_cf_cmd_time_micro from table (mon_get_cf_cmd( null) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_cf_cmd_end like session.mon_get_cf_cmd_start on commit preserve rows not logged organize by row;
drop table session.mon_get_cf_cmd_diff;
declare global temporary table mon_get_cf_cmd_diff as ( select cast(null as integer) ts_delta, current timestamp ts,hostname, id, cf_cmd_name, total_cf_requests, total_cf_cmd_time_micro from table (mon_get_cf_cmd( null) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_cf_cmd_start on session.mon_get_cf_cmd_start (hostname, id, cf_cmd_name);
create index session.idx_mon_get_cf_cmd_end on session.mon_get_cf_cmd_end (hostname, id, cf_cmd_name);
drop table session.mon_get_cf_wait_time_start;
drop table session.mon_get_cf_wait_time_end;
declare global temporary table mon_get_cf_wait_time_start as ( select current timestamp ts,member, hostname, id, cf_cmd_name, total_cf_requests, total_cf_wait_time_micro from table (mon_get_cf_wait_time( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_cf_wait_time_end like session.mon_get_cf_wait_time_start on commit preserve rows not logged organize by row;
drop table session.mon_get_cf_wait_time_diff;
declare global temporary table mon_get_cf_wait_time_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, hostname, id, cf_cmd_name, total_cf_requests, total_cf_wait_time_micro from table (mon_get_cf_wait_time( -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_cf_wait_time_start on session.mon_get_cf_wait_time_start (member, hostname, id, cf_cmd_name);
create index session.idx_mon_get_cf_wait_time_end on session.mon_get_cf_wait_time_end (member, hostname, id, cf_cmd_name);
drop table session.mon_get_connection_start;
drop table session.mon_get_connection_end;
declare global temporary table mon_get_connection_start as ( select current timestamp ts,member, application_name, application_handle, client_applname, connection_reusability_status, reusability_status_reason, client_idle_wait_time, total_rqst_time, rqsts_completed_total, total_wait_time, lock_wait_time, log_disk_wait_time, fcm_recv_wait_time, fcm_send_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, total_section_sort_time, total_commit_time, total_runstats_time, total_reorg_time, total_load_time, total_app_commits, total_app_rollbacks, deadlocks, rows_modified, rows_read, rows_returned, total_sorts, total_reorgs, total_loads, total_runstats, pool_data_l_reads, pool_data_p_reads, pool_index_l_reads, pool_index_p_reads, cf_wait_time, reclaim_wait_time, total_extended_latch_wait_time, prefetch_wait_time, diaglog_write_wait_time, log_buffer_wait_time, lock_wait_time_global, pool_col_l_reads, pool_col_p_reads from table (mon_get_connection( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_connection_end like session.mon_get_connection_start on commit preserve rows not logged organize by row;
drop table session.mon_get_connection_diff;
declare global temporary table mon_get_connection_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, application_name, application_handle, client_applname, connection_reusability_status, reusability_status_reason, client_idle_wait_time, total_rqst_time, rqsts_completed_total, total_wait_time, lock_wait_time, log_disk_wait_time, fcm_recv_wait_time, fcm_send_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, total_section_sort_time, total_commit_time, total_runstats_time, total_reorg_time, total_load_time, total_app_commits, total_app_rollbacks, deadlocks, rows_modified, rows_read, rows_returned, total_sorts, total_reorgs, total_loads, total_runstats, pool_data_l_reads, pool_data_p_reads, pool_index_l_reads, pool_index_p_reads, cf_wait_time, reclaim_wait_time, total_extended_latch_wait_time, prefetch_wait_time, diaglog_write_wait_time, log_buffer_wait_time, lock_wait_time_global, pool_col_l_reads, pool_col_p_reads from table (mon_get_connection( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_connection_start on session.mon_get_connection_start (member, application_name, application_handle, client_applname);
create index session.idx_mon_get_connection_end on session.mon_get_connection_end (member, application_name, application_handle, client_applname);
drop table session.mon_get_extended_latch_wait_start;
drop table session.mon_get_extended_latch_wait_end;
declare global temporary table mon_get_extended_latch_wait_start as ( select current timestamp ts,member, latch_name, total_extended_latch_wait_time, total_extended_latch_waits from table (mon_get_extended_latch_wait( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_extended_latch_wait_end like session.mon_get_extended_latch_wait_start on commit preserve rows not logged organize by row;
drop table session.mon_get_extended_latch_wait_diff;
declare global temporary table mon_get_extended_latch_wait_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, latch_name, total_extended_latch_wait_time, total_extended_latch_waits from table (mon_get_extended_latch_wait( -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_extended_latch_wait_start on session.mon_get_extended_latch_wait_start (member, latch_name);
create index session.idx_mon_get_extended_latch_wait_end on session.mon_get_extended_latch_wait_end (member, latch_name);
drop table session.mon_get_group_bufferpool_start;
drop table session.mon_get_group_bufferpool_end;
declare global temporary table mon_get_group_bufferpool_start as ( select current timestamp ts,member, num_gbp_full from table (mon_get_group_bufferpool( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_group_bufferpool_end like session.mon_get_group_bufferpool_start on commit preserve rows not logged organize by row;
drop table session.mon_get_group_bufferpool_diff;
declare global temporary table mon_get_group_bufferpool_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, num_gbp_full from table (mon_get_group_bufferpool( -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_group_bufferpool_start on session.mon_get_group_bufferpool_start (member);
create index session.idx_mon_get_group_bufferpool_end on session.mon_get_group_bufferpool_end (member);
drop table session.mon_get_memory_pool_start;
drop table session.mon_get_memory_pool_end;
declare global temporary table mon_get_memory_pool_start as ( select current timestamp ts,member, memory_pool_type, db_name, memory_pool_used, memory_pool_used_hwm from table (mon_get_memory_pool( 'database', null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_memory_pool_end like session.mon_get_memory_pool_start on commit preserve rows not logged organize by row;
drop table session.mon_get_memory_pool_diff;
declare global temporary table mon_get_memory_pool_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, memory_pool_type, db_name, memory_pool_used, memory_pool_used_hwm from table (mon_get_memory_pool( 'database', null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_memory_pool_start on session.mon_get_memory_pool_start (member);
create index session.idx_mon_get_memory_pool_end on session.mon_get_memory_pool_end (member);
drop table session.mon_get_memory_set_start;
drop table session.mon_get_memory_set_end;
declare global temporary table mon_get_memory_set_start as ( select current timestamp ts,member, memory_set_type, db_name, memory_set_used, memory_set_used_hwm from table (mon_get_memory_set( null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_memory_set_end like session.mon_get_memory_set_start on commit preserve rows not logged organize by row;
drop table session.mon_get_memory_set_diff;
declare global temporary table mon_get_memory_set_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, memory_set_type, db_name, memory_set_used, memory_set_used_hwm from table (mon_get_memory_set( null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_memory_set_start on session.mon_get_memory_set_start (member);
create index session.idx_mon_get_memory_set_end on session.mon_get_memory_set_end (member);
drop table session.mon_get_page_access_info_start;
drop table session.mon_get_page_access_info_end;
declare global temporary table mon_get_page_access_info_start as ( select current timestamp ts,member, tabschema, tabname, objtype, data_partition_id, iid, page_reclaims_x, page_reclaims_s, reclaim_wait_time, spacemappage_page_reclaims_x, spacemappage_page_reclaims_s, spacemappage_reclaim_wait_time from table (mon_get_page_access_info( null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_page_access_info_end like session.mon_get_page_access_info_start on commit preserve rows not logged organize by row;
drop table session.mon_get_page_access_info_diff;
declare global temporary table mon_get_page_access_info_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, tabschema, tabname, objtype, data_partition_id, iid, page_reclaims_x, page_reclaims_s, reclaim_wait_time, spacemappage_page_reclaims_x, spacemappage_page_reclaims_s, spacemappage_reclaim_wait_time from table (mon_get_page_access_info( null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_page_access_info_start on session.mon_get_page_access_info_start (member, tabschema, tabname, objtype, data_partition_id, iid);
create index session.idx_mon_get_page_access_info_end on session.mon_get_page_access_info_end (member, tabschema, tabname, objtype, data_partition_id, iid);
drop table session.mon_get_pkg_cache_stmt_start;
drop table session.mon_get_pkg_cache_stmt_end;
declare global temporary table mon_get_pkg_cache_stmt_start as ( select current timestamp ts,member, planid, executable_id, package_name, stmt_text, stmtid, semantic_env_id, active_sorts_top, sort_heap_top, sort_shrheap_top, num_exec_with_metrics, coord_stmt_exec_time, total_act_time, total_cpu_time, total_act_wait_time, lock_wait_time, log_disk_wait_time, log_buffer_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, rows_modified, rows_read, rows_returned, total_sorts, sort_overflows, total_section_time, total_section_sort_time, pool_data_l_reads, pool_index_l_reads, pool_data_p_reads, pool_index_p_reads, pool_data_writes, pool_index_writes, pool_temp_data_p_reads, pool_temp_index_p_reads, direct_read_reqs, direct_write_reqs, cf_wait_time, reclaim_wait_time, total_extended_latch_wait_time, lock_wait_time_global, prefetch_wait_time, diaglog_write_wait_time, fcm_recv_wait_time, fcm_send_wait_time, pool_col_l_reads, pool_col_p_reads, total_col_time, col_synopsis_rows_inserted from table (mon_get_pkg_cache_stmt( null, null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_pkg_cache_stmt_end like session.mon_get_pkg_cache_stmt_start on commit preserve rows not logged organize by row;
drop table session.mon_get_pkg_cache_stmt_diff;
declare global temporary table mon_get_pkg_cache_stmt_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, planid, executable_id, package_name, stmt_text, stmtid, semantic_env_id, active_sorts_top, sort_heap_top, sort_shrheap_top, num_exec_with_metrics, coord_stmt_exec_time, total_act_time, total_cpu_time, total_act_wait_time, lock_wait_time, log_disk_wait_time, log_buffer_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, rows_modified, rows_read, rows_returned, total_sorts, sort_overflows, total_section_time, total_section_sort_time, pool_data_l_reads, pool_index_l_reads, pool_data_p_reads, pool_index_p_reads, pool_data_writes, pool_index_writes, pool_temp_data_p_reads, pool_temp_index_p_reads, direct_read_reqs, direct_write_reqs, cf_wait_time, reclaim_wait_time, total_extended_latch_wait_time, lock_wait_time_global, prefetch_wait_time, diaglog_write_wait_time, fcm_recv_wait_time, fcm_send_wait_time, pool_col_l_reads, pool_col_p_reads, total_col_time, col_synopsis_rows_inserted from table (mon_get_pkg_cache_stmt( null, null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_pkg_cache_stmt_start on session.mon_get_pkg_cache_stmt_start (member, planid, executable_id);
create index session.idx_mon_get_pkg_cache_stmt_end on session.mon_get_pkg_cache_stmt_end (member, planid, executable_id);
drop table session.mon_get_serverlist_start;
drop table session.mon_get_serverlist_end;
declare global temporary table mon_get_serverlist_start as ( select current timestamp ts,member, cached_timestamp, hostname, port_number, ssl_port_number, priority from table (mon_get_serverlist( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_serverlist_end like session.mon_get_serverlist_start on commit preserve rows not logged organize by row;
drop table session.mon_get_serverlist_diff;
declare global temporary table mon_get_serverlist_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, cached_timestamp, hostname, port_number, ssl_port_number, priority from table (mon_get_serverlist( -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_serverlist_start on session.mon_get_serverlist_start (member);
create index session.idx_mon_get_serverlist_end on session.mon_get_serverlist_end (member);
drop table session.mon_get_table_start;
drop table session.mon_get_table_end;
declare global temporary table mon_get_table_start as ( select current timestamp ts,member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id, data_sharing_state_change_time, data_sharing_state, rows_read, rows_inserted, rows_updated, rows_deleted, overflow_accesses, overflow_creates, page_reorgs, direct_read_reqs, direct_write_reqs, object_data_p_reads, object_data_l_reads, data_sharing_remote_lockwait_count, data_sharing_remote_lockwait_time, col_object_l_pages from table (mon_get_table( null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_table_end like session.mon_get_table_start on commit preserve rows not logged organize by row;
drop table session.mon_get_table_diff;
declare global temporary table mon_get_table_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id, data_sharing_state_change_time, data_sharing_state, rows_read, rows_inserted, rows_updated, rows_deleted, overflow_accesses, overflow_creates, page_reorgs, direct_read_reqs, direct_write_reqs, object_data_p_reads, object_data_l_reads, data_sharing_remote_lockwait_count, data_sharing_remote_lockwait_time, col_object_l_pages from table (mon_get_table( null, null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_table_start on session.mon_get_table_start (member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id);
create index session.idx_mon_get_table_end on session.mon_get_table_end (member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id);
drop table session.mon_get_tablespace_start;
drop table session.mon_get_tablespace_end;
declare global temporary table mon_get_tablespace_start as ( select current timestamp ts,member, tbsp_name, tbsp_page_size, tbsp_id, tbsp_extent_size, tbsp_prefetch_size, fs_caching, pool_read_time, pool_async_read_time, pool_write_time, pool_async_write_time, pool_data_writes, pool_async_data_writes, pool_index_writes, pool_async_index_writes, pool_data_l_reads, pool_temp_data_l_reads, pool_async_data_reads, pool_data_p_reads, pool_temp_data_p_reads, pool_async_index_reads, pool_index_l_reads, pool_temp_index_l_reads, pool_index_p_reads, pool_temp_index_p_reads, pool_xda_l_reads, pool_temp_xda_l_reads, pool_async_xda_reads, pool_xda_p_reads, pool_temp_xda_p_reads, pool_xda_writes, pool_async_xda_writes, unread_prefetch_pages, vectored_ios, pages_from_vectored_ios, block_ios, pages_from_block_ios, pool_data_lbp_pages_found, pool_index_lbp_pages_found, pool_async_data_lbp_pages_found, pool_async_index_lbp_pages_found, direct_read_reqs, direct_write_reqs, direct_read_time, direct_write_time, tbsp_used_pages, tbsp_page_top, pool_data_gbp_l_reads, pool_data_gbp_p_reads, pool_index_gbp_l_reads, pool_index_gbp_p_reads, pool_data_gbp_invalid_pages, pool_async_data_gbp_invalid_pages, pool_index_gbp_invalid_pages, pool_async_index_gbp_invalid_pages, pool_async_data_gbp_l_reads, pool_async_data_gbp_p_reads, pool_async_data_gbp_indep_pages_found_in_lbp, pool_async_index_gbp_l_reads, pool_async_index_gbp_p_reads, pool_async_index_gbp_indep_pages_found_in_lbp, prefetch_wait_time, prefetch_waits, skipped_prefetch_data_p_reads, skipped_prefetch_index_p_reads, skipped_prefetch_temp_data_p_reads, skipped_prefetch_temp_index_p_reads, pool_col_l_reads, pool_col_p_reads, pool_async_col_reads, pool_col_writes, pool_async_col_writes, pool_col_lbp_pages_found, pool_async_col_lbp_pages_found, pool_temp_col_l_reads, pool_temp_col_p_reads from table (mon_get_tablespace( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_tablespace_end like session.mon_get_tablespace_start on commit preserve rows not logged organize by row;
drop table session.mon_get_tablespace_diff;
declare global temporary table mon_get_tablespace_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, tbsp_name, tbsp_page_size, tbsp_id, tbsp_extent_size, tbsp_prefetch_size, fs_caching, pool_read_time, pool_async_read_time, pool_write_time, pool_async_write_time, pool_data_writes, pool_async_data_writes, pool_index_writes, pool_async_index_writes, pool_data_l_reads, pool_temp_data_l_reads, pool_async_data_reads, pool_data_p_reads, pool_temp_data_p_reads, pool_async_index_reads, pool_index_l_reads, pool_temp_index_l_reads, pool_index_p_reads, pool_temp_index_p_reads, pool_xda_l_reads, pool_temp_xda_l_reads, pool_async_xda_reads, pool_xda_p_reads, pool_temp_xda_p_reads, pool_xda_writes, pool_async_xda_writes, unread_prefetch_pages, vectored_ios, pages_from_vectored_ios, block_ios, pages_from_block_ios, pool_data_lbp_pages_found, pool_index_lbp_pages_found, pool_async_data_lbp_pages_found, pool_async_index_lbp_pages_found, direct_read_reqs, direct_write_reqs, direct_read_time, direct_write_time, tbsp_used_pages, tbsp_page_top, pool_data_gbp_l_reads, pool_data_gbp_p_reads, pool_index_gbp_l_reads, pool_index_gbp_p_reads, pool_data_gbp_invalid_pages, pool_async_data_gbp_invalid_pages, pool_index_gbp_invalid_pages, pool_async_index_gbp_invalid_pages, pool_async_data_gbp_l_reads, pool_async_data_gbp_p_reads, pool_async_data_gbp_indep_pages_found_in_lbp, pool_async_index_gbp_l_reads, pool_async_index_gbp_p_reads, pool_async_index_gbp_indep_pages_found_in_lbp, prefetch_wait_time, prefetch_waits, skipped_prefetch_data_p_reads, skipped_prefetch_index_p_reads, skipped_prefetch_temp_data_p_reads, skipped_prefetch_temp_index_p_reads, pool_col_l_reads, pool_col_p_reads, pool_async_col_reads, pool_col_writes, pool_async_col_writes, pool_col_lbp_pages_found, pool_async_col_lbp_pages_found, pool_temp_col_l_reads, pool_temp_col_p_reads from table (mon_get_tablespace( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_tablespace_start on session.mon_get_tablespace_start (member, tbsp_name);
create index session.idx_mon_get_tablespace_end on session.mon_get_tablespace_end (member, tbsp_name);
drop table session.mon_get_transaction_log_start;
drop table session.mon_get_transaction_log_end;
declare global temporary table mon_get_transaction_log_start as ( select current timestamp ts,member, log_writes, log_write_time, num_log_write_io, num_log_part_page_io, num_log_buffer_full, log_reads, log_read_time, num_log_read_io, log_hadr_wait_time, log_hadr_waits_total, num_log_data_found_in_buffer, cur_commit_log_buff_log_reads, cur_commit_disk_log_reads from table (mon_get_transaction_log( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_transaction_log_end like session.mon_get_transaction_log_start on commit preserve rows not logged organize by row;
drop table session.mon_get_transaction_log_diff;
declare global temporary table mon_get_transaction_log_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, log_writes, log_write_time, num_log_write_io, num_log_part_page_io, num_log_buffer_full, log_reads, log_read_time, num_log_read_io, log_hadr_wait_time, log_hadr_waits_total, num_log_data_found_in_buffer, cur_commit_log_buff_log_reads, cur_commit_disk_log_reads from table (mon_get_transaction_log( -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_transaction_log_start on session.mon_get_transaction_log_start (member);
create index session.idx_mon_get_transaction_log_end on session.mon_get_transaction_log_end (member);
drop table session.mon_get_utility_start;
drop table session.mon_get_utility_end;
declare global temporary table mon_get_utility_start as ( select current timestamp ts,coord_member, application_handle, utility_start_time, utility_type, utility_operation_type, utility_detail from table (mon_get_utility( -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_utility_end like session.mon_get_utility_start on commit preserve rows not logged organize by row;
drop table session.mon_get_workload_start;
drop table session.mon_get_workload_end;
declare global temporary table mon_get_workload_start as ( select current timestamp ts,member, workload_name, sort_shrheap_allocated, act_completed_total, total_act_time, total_rqst_time, total_wait_time, lock_wait_time, log_disk_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, tcpip_recv_wait_time, tcpip_send_wait_time, fcm_recv_wait_time, fcm_send_wait_time, total_cpu_time, total_compile_time, total_compile_proc_time, total_routine_time, total_section_sort_time, total_section_sort_proc_time, total_section_time, total_section_proc_time, total_commit_time, total_rollback_time, total_runstats_time, total_reorg_time, total_load_time, total_app_commits, total_app_rollbacks, deadlocks, lock_timeouts, lock_escals, client_idle_wait_time, rows_modified, rows_read, rows_returned, pkg_cache_inserts, total_sorts, sort_overflows, post_threshold_sorts, post_shrthreshold_sorts, total_reorgs, total_loads, total_runstats, pool_data_l_reads, pool_data_p_reads, pool_temp_data_p_reads, pool_index_l_reads, pool_index_p_reads, pool_temp_index_p_reads, pool_xda_p_reads, pool_temp_xda_p_reads, lock_wait_time_global, total_extended_latch_wait_time, reclaim_wait_time, cf_wait_time, prefetch_wait_time, log_buffer_wait_time, lock_timeouts_global, lock_escals_maxlocks, lock_escals_locklist, lock_escals_global, total_routine_user_code_time, diaglog_write_wait_time, total_connect_request_time, total_connect_request_proc_time, select_sql_stmts, uid_sql_stmts, rows_inserted, rows_updated, total_col_time, total_col_proc_time, total_backup_time, total_index_build_time, total_hash_joins, hash_join_overflows, post_threshold_hash_joins, post_shrthreshold_hash_joins, total_peds, post_threshold_peds, disabled_peds, total_peas, post_threshold_peas, pool_col_l_reads, pool_col_p_reads, pool_temp_col_p_reads, total_col_synopsis_time, ext_table_recv_wait_time, ext_table_recvs_total, ext_table_recv_volume, ext_table_read_volume, ext_table_send_wait_time, ext_table_sends_total, ext_table_send_volume, ext_table_write_volume from table (mon_get_workload( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
declare global temporary table mon_get_workload_end like session.mon_get_workload_start on commit preserve rows not logged organize by row;
drop table session.mon_get_workload_diff;
declare global temporary table mon_get_workload_diff as ( select cast(null as integer) ts_delta, current timestamp ts,member, workload_name, sort_shrheap_allocated, act_completed_total, total_act_time, total_rqst_time, total_wait_time, lock_wait_time, log_disk_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, tcpip_recv_wait_time, tcpip_send_wait_time, fcm_recv_wait_time, fcm_send_wait_time, total_cpu_time, total_compile_time, total_compile_proc_time, total_routine_time, total_section_sort_time, total_section_sort_proc_time, total_section_time, total_section_proc_time, total_commit_time, total_rollback_time, total_runstats_time, total_reorg_time, total_load_time, total_app_commits, total_app_rollbacks, deadlocks, lock_timeouts, lock_escals, client_idle_wait_time, rows_modified, rows_read, rows_returned, pkg_cache_inserts, total_sorts, sort_overflows, post_threshold_sorts, post_shrthreshold_sorts, total_reorgs, total_loads, total_runstats, pool_data_l_reads, pool_data_p_reads, pool_temp_data_p_reads, pool_index_l_reads, pool_index_p_reads, pool_temp_index_p_reads, pool_xda_p_reads, pool_temp_xda_p_reads, lock_wait_time_global, total_extended_latch_wait_time, reclaim_wait_time, cf_wait_time, prefetch_wait_time, log_buffer_wait_time, lock_timeouts_global, lock_escals_maxlocks, lock_escals_locklist, lock_escals_global, total_routine_user_code_time, diaglog_write_wait_time, total_connect_request_time, total_connect_request_proc_time, select_sql_stmts, uid_sql_stmts, rows_inserted, rows_updated, total_col_time, total_col_proc_time, total_backup_time, total_index_build_time, total_hash_joins, hash_join_overflows, post_threshold_hash_joins, post_shrthreshold_hash_joins, total_peds, post_threshold_peds, disabled_peds, total_peas, post_threshold_peas, pool_col_l_reads, pool_col_p_reads, pool_temp_col_p_reads, total_col_synopsis_time, ext_table_recv_wait_time, ext_table_recvs_total, ext_table_recv_volume, ext_table_read_volume, ext_table_send_wait_time, ext_table_sends_total, ext_table_send_volume, ext_table_write_volume from table (mon_get_workload( null, -2) ) ) with no data on commit preserve rows not logged organize by row;
create index session.idx_mon_get_workload_start on session.mon_get_workload_start (member, workload_name);
create index session.idx_mon_get_workload_end on session.mon_get_workload_end (member, workload_name);

drop table session.mon_current_sql_plus_start;
drop table session.mon_current_sql_plus_end;

declare global temporary table session.mon_current_sql_plus_start as
( with 
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

) with no data on commit preserve rows not logged organize by row;
;

declare global temporary table mon_current_sql_plus_end like session.mon_current_sql_plus_start on commit preserve rows not logged organize by row;
;


drop table session.mon_get_locks_start;
drop table session.mon_get_locks_end;

declare global temporary table session.mon_get_locks_start as
( select
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
   table ( mon_get_locks(null,-2) )
) with no data on commit preserve rows not logged organize by row;
;

declare global temporary table session.mon_get_locks_end like session.mon_get_locks_start on commit preserve rows not logged organize by row;
;

insert into session.db_get_cfg_start select current timestamp,member, name, value, value_flags from table (db_get_cfg( -2) );
insert into session.dbmcfg_start select current timestamp,name, value, value_flags from sysibmadm.dbmcfg;
insert into session.env_cf_sys_resources_start select current timestamp,id, name, value, unit from sysibmadm.env_cf_sys_resources;
insert into session.env_get_reg_variables_start select current timestamp,member, reg_var_name, reg_var_value, level from table (env_get_reg_variables( -2) );
insert into session.env_get_system_resources_start select current timestamp,member, os_name, host_name, os_version, os_release, cpu_total, cpu_online, cpu_configured, cpu_speed, cpu_hmt_degree, memory_total, memory_free, cpu_load_short, cpu_load_medium, cpu_load_long, cpu_usage_total, swap_pages_in, swap_pages_out from table (sysproc.env_get_system_resources( ) );
insert into session.env_inst_info_start select current timestamp,inst_name, num_dbpartitions, service_level, bld_level, ptf, num_members from sysibmadm.env_inst_info;
insert into session.mon_get_bufferpool_start select current timestamp,member, bp_name, bp_cur_buffsz, automatic, pool_read_time, pool_data_l_reads, pool_data_p_reads, pool_async_read_time, pool_async_data_reads, pool_async_index_reads, pool_async_xda_reads, pool_data_writes, pool_async_data_writes, pool_data_lbp_pages_found, pool_async_data_lbp_pages_found, pool_temp_data_l_reads, pool_temp_data_p_reads, pool_index_lbp_pages_found, pool_async_index_lbp_pages_found, pool_temp_index_l_reads, pool_temp_index_p_reads, pool_write_time, pool_async_write_time, pool_index_l_reads, pool_index_p_reads, pool_index_writes, pool_async_index_writes, pool_xda_l_reads, pool_temp_xda_l_reads, pool_xda_p_reads, pool_temp_xda_p_reads, pool_xda_writes, pool_async_xda_writes, pool_data_gbp_l_reads, pool_data_gbp_p_reads, pool_index_gbp_l_reads, pool_index_gbp_p_reads, pool_data_gbp_invalid_pages, pool_async_data_gbp_invalid_pages, pool_index_gbp_invalid_pages, pool_async_index_gbp_invalid_pages, pool_col_l_reads, pool_col_p_reads, pool_async_col_reads, pool_col_writes, pool_async_col_writes, pool_col_lbp_pages_found, pool_async_col_lbp_pages_found, pool_temp_col_l_reads, pool_temp_col_p_reads from table (mon_get_bufferpool( null, -2) );
insert into session.mon_get_cf_start select current timestamp,id, host_name, current_cf_mem_size, configured_cf_mem_size, current_cf_gbp_size, configured_cf_gbp_size, target_cf_gbp_size, current_cf_lock_size, configured_cf_lock_size, target_cf_lock_size, current_cf_sca_size, configured_cf_sca_size, target_cf_sca_size from table (mon_get_cf( null) );
insert into session.mon_get_cf_cmd_start select current timestamp,hostname, id, cf_cmd_name, total_cf_requests, total_cf_cmd_time_micro from table (mon_get_cf_cmd( null) );
insert into session.mon_get_cf_wait_time_start select current timestamp,member, hostname, id, cf_cmd_name, total_cf_requests, total_cf_wait_time_micro from table (mon_get_cf_wait_time( -2) );
insert into session.mon_get_connection_start select current timestamp,member, application_name, application_handle, client_applname, connection_reusability_status, reusability_status_reason, client_idle_wait_time, total_rqst_time, rqsts_completed_total, total_wait_time, lock_wait_time, log_disk_wait_time, fcm_recv_wait_time, fcm_send_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, total_section_sort_time, total_commit_time, total_runstats_time, total_reorg_time, total_load_time, total_app_commits, total_app_rollbacks, deadlocks, rows_modified, rows_read, rows_returned, total_sorts, total_reorgs, total_loads, total_runstats, pool_data_l_reads, pool_data_p_reads, pool_index_l_reads, pool_index_p_reads, cf_wait_time, reclaim_wait_time, total_extended_latch_wait_time, prefetch_wait_time, diaglog_write_wait_time, log_buffer_wait_time, lock_wait_time_global, pool_col_l_reads, pool_col_p_reads from table (mon_get_connection( null, -2) );
insert into session.mon_get_extended_latch_wait_start select current timestamp,member, latch_name, total_extended_latch_wait_time, total_extended_latch_waits from table (mon_get_extended_latch_wait( -2) );
insert into session.mon_get_group_bufferpool_start select current timestamp,member, num_gbp_full from table (mon_get_group_bufferpool( -2) );
insert into session.mon_get_memory_pool_start select current timestamp,member, memory_pool_type, db_name, memory_pool_used, memory_pool_used_hwm from table (mon_get_memory_pool( 'database', null, -2) );
insert into session.mon_get_memory_set_start select current timestamp,member, memory_set_type, db_name, memory_set_used, memory_set_used_hwm from table (mon_get_memory_set( null, null, -2) );
insert into session.mon_get_page_access_info_start select current timestamp,member, tabschema, tabname, objtype, data_partition_id, iid, page_reclaims_x, page_reclaims_s, reclaim_wait_time, spacemappage_page_reclaims_x, spacemappage_page_reclaims_s, spacemappage_reclaim_wait_time from table (mon_get_page_access_info( null, null, -2) );
insert into session.mon_get_pkg_cache_stmt_start select current timestamp,member, planid, executable_id, package_name, stmt_text, stmtid, semantic_env_id, active_sorts_top, sort_heap_top, sort_shrheap_top, num_exec_with_metrics, coord_stmt_exec_time, total_act_time, total_cpu_time, total_act_wait_time, lock_wait_time, log_disk_wait_time, log_buffer_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, rows_modified, rows_read, rows_returned, total_sorts, sort_overflows, total_section_time, total_section_sort_time, pool_data_l_reads, pool_index_l_reads, pool_data_p_reads, pool_index_p_reads, pool_data_writes, pool_index_writes, pool_temp_data_p_reads, pool_temp_index_p_reads, direct_read_reqs, direct_write_reqs, cf_wait_time, reclaim_wait_time, total_extended_latch_wait_time, lock_wait_time_global, prefetch_wait_time, diaglog_write_wait_time, fcm_recv_wait_time, fcm_send_wait_time, pool_col_l_reads, pool_col_p_reads, total_col_time, col_synopsis_rows_inserted from table (mon_get_pkg_cache_stmt( null, null, null, -2) ) where stmt_text not like 'CALL dbms_alert.sleep%' order by coord_stmt_exec_time desc;
insert into session.mon_get_serverlist_start select current timestamp,member, cached_timestamp, hostname, port_number, ssl_port_number, priority from table (mon_get_serverlist( -2) );
insert into session.mon_get_table_start select current timestamp,member, tabname, tabschema, data_partition_id, tbsp_id, tab_file_id, data_sharing_state_change_time, data_sharing_state, rows_read, rows_inserted, rows_updated, rows_deleted, overflow_accesses, overflow_creates, page_reorgs, direct_read_reqs, direct_write_reqs, object_data_p_reads, object_data_l_reads, data_sharing_remote_lockwait_count, data_sharing_remote_lockwait_time, col_object_l_pages from table (mon_get_table( null, null, -2) );
insert into session.mon_get_tablespace_start select current timestamp,member, tbsp_name, tbsp_page_size, tbsp_id, tbsp_extent_size, tbsp_prefetch_size, fs_caching, pool_read_time, pool_async_read_time, pool_write_time, pool_async_write_time, pool_data_writes, pool_async_data_writes, pool_index_writes, pool_async_index_writes, pool_data_l_reads, pool_temp_data_l_reads, pool_async_data_reads, pool_data_p_reads, pool_temp_data_p_reads, pool_async_index_reads, pool_index_l_reads, pool_temp_index_l_reads, pool_index_p_reads, pool_temp_index_p_reads, pool_xda_l_reads, pool_temp_xda_l_reads, pool_async_xda_reads, pool_xda_p_reads, pool_temp_xda_p_reads, pool_xda_writes, pool_async_xda_writes, unread_prefetch_pages, vectored_ios, pages_from_vectored_ios, block_ios, pages_from_block_ios, pool_data_lbp_pages_found, pool_index_lbp_pages_found, pool_async_data_lbp_pages_found, pool_async_index_lbp_pages_found, direct_read_reqs, direct_write_reqs, direct_read_time, direct_write_time, tbsp_used_pages, tbsp_page_top, pool_data_gbp_l_reads, pool_data_gbp_p_reads, pool_index_gbp_l_reads, pool_index_gbp_p_reads, pool_data_gbp_invalid_pages, pool_async_data_gbp_invalid_pages, pool_index_gbp_invalid_pages, pool_async_index_gbp_invalid_pages, pool_async_data_gbp_l_reads, pool_async_data_gbp_p_reads, pool_async_data_gbp_indep_pages_found_in_lbp, pool_async_index_gbp_l_reads, pool_async_index_gbp_p_reads, pool_async_index_gbp_indep_pages_found_in_lbp, prefetch_wait_time, prefetch_waits, skipped_prefetch_data_p_reads, skipped_prefetch_index_p_reads, skipped_prefetch_temp_data_p_reads, skipped_prefetch_temp_index_p_reads, pool_col_l_reads, pool_col_p_reads, pool_async_col_reads, pool_col_writes, pool_async_col_writes, pool_col_lbp_pages_found, pool_async_col_lbp_pages_found, pool_temp_col_l_reads, pool_temp_col_p_reads from table (mon_get_tablespace( null, -2) );
insert into session.mon_get_transaction_log_start select current timestamp,member, log_writes, log_write_time, num_log_write_io, num_log_part_page_io, num_log_buffer_full, log_reads, log_read_time, num_log_read_io, log_hadr_wait_time, log_hadr_waits_total, num_log_data_found_in_buffer, cur_commit_log_buff_log_reads, cur_commit_disk_log_reads from table (mon_get_transaction_log( -2) );
insert into session.mon_get_utility_start select current timestamp,coord_member, application_handle, utility_start_time, utility_type, utility_operation_type, utility_detail from table (mon_get_utility( -2) );
insert into session.mon_get_workload_start select current timestamp,member, workload_name, sort_shrheap_allocated, act_completed_total, total_act_time, total_rqst_time, total_wait_time, lock_wait_time, log_disk_wait_time, pool_write_time, pool_read_time, direct_write_time, direct_read_time, tcpip_recv_wait_time, tcpip_send_wait_time, fcm_recv_wait_time, fcm_send_wait_time, total_cpu_time, total_compile_time, total_compile_proc_time, total_routine_time, total_section_sort_time, total_section_sort_proc_time, total_section_time, total_section_proc_time, total_commit_time, total_rollback_time, total_runstats_time, total_reorg_time, total_load_time, total_app_commits, total_app_rollbacks, deadlocks, lock_timeouts, lock_escals, client_idle_wait_time, rows_modified, rows_read, rows_returned, pkg_cache_inserts, total_sorts, sort_overflows, post_threshold_sorts, post_shrthreshold_sorts, total_reorgs, total_loads, total_runstats, pool_data_l_reads, pool_data_p_reads, pool_temp_data_p_reads, pool_index_l_reads, pool_index_p_reads, pool_temp_index_p_reads, pool_xda_p_reads, pool_temp_xda_p_reads, lock_wait_time_global, total_extended_latch_wait_time, reclaim_wait_time, cf_wait_time, prefetch_wait_time, log_buffer_wait_time, lock_timeouts_global, lock_escals_maxlocks, lock_escals_locklist, lock_escals_global, total_routine_user_code_time, diaglog_write_wait_time, total_connect_request_time, total_connect_request_proc_time, select_sql_stmts, uid_sql_stmts, rows_inserted, rows_updated, total_col_time, total_col_proc_time, total_backup_time, total_index_build_time, total_hash_joins, hash_join_overflows, post_threshold_hash_joins, post_shrthreshold_hash_joins, total_peds, post_threshold_peds, disabled_peds, total_peas, post_threshold_peas, pool_col_l_reads, pool_col_p_reads, pool_temp_col_p_reads, total_col_synopsis_time, ext_table_recv_wait_time, ext_table_recvs_total, ext_table_recv_volume, ext_table_read_volume, ext_table_send_wait_time, ext_table_sends_total, ext_table_send_volume, ext_table_write_volume from table (mon_get_workload( null, -2) );

  insert into session.mon_current_sql_plus_start
    with 
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

  insert into session.mon_get_locks_start
    select
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
   table ( mon_get_locks(null,-2) )
  with UR;

commit work;
select current timestamp as monitor_start_time from sysibm.sysdummy1;
