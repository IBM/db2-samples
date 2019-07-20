<?xml version="1.0" encoding="UTF-8"?>
<!-- ************************************************************************** -->
<!-- (c) Copyright IBM Corp. 2008 All rights reserved.                          -->
<!--                                                                            -->
<!-- The following sample of source code ("Sample") is owned by International   -->
<!-- Business Machines Corporation or one of its subsidiaries ("IBM") and is    -->
<!-- copyrighted and licensed, not sold. You may use, copy, modify, and         -->
<!-- distribute the Sample in any form without payment to IBM, for the purpose  -->
<!-- of assisting you in the development of your applications.                  -->
<!--                                                                            -->
<!-- The Sample code is provided to you on an "AS IS" basis, without warranty   -->
<!-- of any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER         -->
<!-- EXPRESS OR  IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES -->
<!-- OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some              -->
<!-- jurisdictions do not allow for the exclusion or limitation of implied      -->
<!-- warranties, so the above limitations or exclusions may not apply to you.   -->
<!-- IBM shall not be liable for any damages you suffer as a result of using,   -->
<!-- copying, modifying or distributing the Sample, even if IBM has been        -->
<!-- advised of the possibility of such damages.                                -->
<!-- ************************************************************************** -->
<xsl:stylesheet version="1.0"
                xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
                xmlns:xs="http://www.w3.org/2001/XMLSchema"
                xmlns:pkg="http://www.ibm.com/xmlns/prod/db2/mon">

<xsl:output method="text"  indent="no"/>

<!-- ========================================================================== -->
<!-- Template   : Main                                                          -->
<!-- Description: Main template to process the entire XML document              -->
<!-- ========================================================================== -->
<xsl:template match="/">

<!-- ========================================================== -->
<!-- Print out each PKG Cache event in details                  -->
<!-- ========================================================== -->
  <xsl:for-each select="pkg:db2_pkgcache_event">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
</xsl:template>


<!-- ========================================================================== -->
<!-- Template   : Package cache event details                                   -->
<!-- Description: Template will process each db2_pkgcache_event node contained in the  -->
<!--              XML document and print out the event details.                 -->
<!-- ========================================================================== -->
<xsl:template match="pkg:db2_pkgcache_event">

  <xsl:text>&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>

  <!-- ========================================================== -->
  <!-- Print out the Event details header                         -->
  <!-- ========================================================== -->
  <xsl:text>-------------------------------------------------------&#10;</xsl:text>
  <xsl:text>Event ID               : </xsl:text>
    <xsl:value-of select="@id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Event Type             : </xsl:text>
    <xsl:value-of select="@type" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Event Timestamp        : </xsl:text>
    <xsl:value-of select="concat(substring(@timestamp, 1, 10),
                                 '-',
                                 substring(@timestamp, 12, 2),
                                 '.',
                                 substring(@timestamp, 15, 2),
                                 '.',
                                 substring(@timestamp, 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Member                 : </xsl:text>
    <xsl:value-of select="@member" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Release                : </xsl:text>
    <xsl:value-of select="@release" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>-------------------------------------------------------&#10;</xsl:text>

  <!-- ========================================================== -->
  <!-- Print out the package cache details                        -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Cache Details&#10;</xsl:text>
  <xsl:text>---------------------&#10;</xsl:text>
  <xsl:text>Section Type                           : </xsl:text>
    <xsl:value-of select="pkg:section_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Insert Timestamp                       : </xsl:text>
    <xsl:value-of select="concat(substring(pkg:insert_timestamp, 1, 10),
                                 '-',
                                 substring(pkg:insert_timestamp, 12, 2),
                                 '.',
                                 substring(pkg:insert_timestamp, 15, 2),
                                 '.',
                                 substring(pkg:insert_timestamp, 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Executable ID                          : </xsl:text>
    <xsl:value-of select="pkg:executable_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Schema                         : </xsl:text>
    <xsl:value-of select="pkg:package_schema/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Name                           : </xsl:text>
    <xsl:value-of select="pkg:package_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Version ID                     : </xsl:text>
    <xsl:value-of select="pkg:package_version_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Section Number                         : </xsl:text>
    <xsl:value-of select="pkg:section_number/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt No                                : </xsl:text>
    <xsl:value-of select="pkg:stmtno/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Num Routines                           : </xsl:text>
    <xsl:value-of select="pkg:num_routines/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Semantic Env Id                        : </xsl:text>
    <xsl:value-of select="pkg:semantic_env_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt Id                                : </xsl:text>
    <xsl:value-of select="pkg:stmtid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Plan ID                                : </xsl:text>
    <xsl:value-of select="pkg:planid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Prep Warning                           : </xsl:text>
    <xsl:value-of select="pkg:prep_warning/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Prep Warning Reason                    : </xsl:text>
    <xsl:value-of select="pkg:prep_warning_reason/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Effective Isolation                    : </xsl:text>
    <xsl:value-of select="pkg:effective_isolation/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Number Of Executions                   : </xsl:text>
    <xsl:value-of select="pkg:num_executions/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Number Of Executions With Metrics      : </xsl:text>
    <xsl:value-of select="pkg:num_exec_with_metrics/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Prep Time                              : </xsl:text>
    <xsl:value-of select="pkg:prep_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Last Metrics Update                    : </xsl:text>
    <xsl:value-of select="concat(substring(pkg:last_metrics_update, 1, 10),
                                 '-',
                                 substring(pkg:last_metrics_update, 12, 2),
                                 '.',
                                 substring(pkg:last_metrics_update, 15, 2),
                                 '.',
                                 substring(pkg:last_metrics_update, 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Executions By Coordinator              : </xsl:text>
    <xsl:value-of select="pkg:num_coord_exec/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Executions By Coordinator With Metrics : </xsl:text>
    <xsl:value-of select="pkg:num_coord_exec_with_metrics/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Statement Type                         : </xsl:text>
    <xsl:value-of select="pkg:stmt_type_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Query Cost Estimate                    : </xsl:text>
    <xsl:value-of select="pkg:query_cost_estimate/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Statement Package Cache ID             : </xsl:text>
    <xsl:value-of select="pkg:stmt_pkg_cache_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Statement Text                         : </xsl:text>
    <xsl:value-of select="pkg:stmt_text/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Compilation Environment                : </xsl:text>
    <xsl:value-of select="pkg:comp_env_desc/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Section Environment                    : </xsl:text>
    <xsl:value-of select="pkg:section_env/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Routine Identifier                     : </xsl:text>
    <xsl:value-of select="pkg:routine_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Query Data Tag List                    : </xsl:text>
    <xsl:value-of select="pkg:query_data_tag_list/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Total Stats Fabrication Time           : </xsl:text>
    <xsl:value-of select="pkg:total_stats_fabrication_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Total Stats Fabrications               : </xsl:text>
    <xsl:value-of select="pkg:total_stats_fabrications/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Total Synchronous Runstats Time        : </xsl:text>
    <xsl:value-of select="pkg:total_sync_runstats_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Total Synchronous Runstats             : </xsl:text>
    <xsl:value-of select="pkg:total_sync_runstats/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Hash Group Bys Top              : </xsl:text>
    <xsl:value-of select="pkg:active_hash_grpbys_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Hash Joins Top                  : </xsl:text>
    <xsl:value-of select="pkg:active_hash_joins_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active OLAP Functions Top              : </xsl:text>
    <xsl:value-of select="pkg:active_olap_funcs_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Partial Early Aggregations Top  : </xsl:text>
    <xsl:value-of select="pkg:active_peas_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Partial Early Distincts Top     : </xsl:text>
    <xsl:value-of select="pkg:active_peds_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Sort Consumers Top              : </xsl:text>
    <xsl:value-of select="pkg:active_sort_consumers_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Sorts Top                       : </xsl:text>
    <xsl:value-of select="pkg:active_sorts_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Columnar Vector Consumers Top   : </xsl:text>
    <xsl:value-of select="pkg:active_col_vector_consumers_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Consumer Heap Top                 : </xsl:text>
    <xsl:value-of select="pkg:sort_consumer_heap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Consumer Shared Heap Top          : </xsl:text>
    <xsl:value-of select="pkg:sort_consumer_shrheap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Heap Top                          : </xsl:text>
    <xsl:value-of select="pkg:sort_heap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Shared Heap Top                   : </xsl:text>
    <xsl:value-of select="pkg:sort_shrheap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Estimated Sort Shared Heap Top         : </xsl:text>
    <xsl:value-of select="pkg:estimated_sort_shrheap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Estimated Sort Consumers Top           : </xsl:text>
    <xsl:value-of select="pkg:estimated_sort_consumers_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Estimated Runtime                      : </xsl:text>
    <xsl:value-of select="pkg:estimated_runtime/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Agents Top                             : </xsl:text>
    <xsl:value-of select="pkg:agents_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Last Exec Error SQLCODE                : </xsl:text>
    <xsl:value-of select="pkg:last_exec_error/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Last Exec Error SQLERRMC               : </xsl:text>
    <xsl:value-of select="pkg:last_exec_error_sqlerrmc/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Last Exec Error Timestamp              : </xsl:text>
    <xsl:value-of select="pkg:last_exec_error_timestamp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Last Exec Warning SQLCODE              : </xsl:text>
    <xsl:value-of select="pkg:last_exec_warning/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Last Exec Warning SQLERRMC             : </xsl:text>
    <xsl:value-of select="pkg:last_exec_warning_sqlerrmc/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Last Exec Warning Timestamp            : </xsl:text>
    <xsl:value-of select="pkg:last_exec_warning_timestamp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Number Executions with Error           : </xsl:text>
    <xsl:value-of select="pkg:num_exec_with_error/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Number Executions with Warning         : </xsl:text>
    <xsl:value-of select="pkg:num_exec_with_warning/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Statement Comments                     : </xsl:text>
    <xsl:value-of select="pkg:stmt_comments/text()" />
  <xsl:text>&#10;</xsl:text>

  <!-- =================================================== -->
  <!-- Max_COORD_STMT_EXEC_TIME/TIMESTAMP and input args   -->
  <!-- =================================================== -->
  <xsl:text>Max Coordinator Stmt Exec Timestamp    : </xsl:text>
    <xsl:value-of select="concat(substring(pkg:max_coord_stmt_exec_timestamp, 1, 10),
                                 '-',
                                 substring(pkg:max_coord_stmt_exec_timestamp, 12, 2),
                                 '.',
                                 substring(pkg:max_coord_stmt_exec_timestamp, 15, 2),
                                 '.',
                                 substring(pkg:max_coord_stmt_exec_timestamp, 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Max Coordinator Stmt Exec Time         : </xsl:text>
    <xsl:value-of select="pkg:max_coord_stmt_exec_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:for-each select="pkg:db2_input_variable">
    <xsl:apply-templates select="." />
  </xsl:for-each>

  <!-- =================================================== -->
  <!-- Package Cache Metrics                               -->
  <!-- =================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Metrics&#10;</xsl:text>
  <xsl:text>-------------------&#10;</xsl:text>
  <xsl:text>WLM_QUEUE_TIME_TOTAL                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:wlm_queue_time_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>WLM_QUEUE_ASSIGNMENTS_TOTAL         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:wlm_queue_assignments_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECV_WAIT_TIME               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECV_WAIT_TIME          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SEND_WAIT_TIME               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SEND_WAIT_TIME          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAIT_TIME                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAIT_TIME_GLOBAL               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_wait_time_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAITS                          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAITS_GLOBAL                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_waits_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_READ_TIME                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:direct_read_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_READ_REQS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:direct_read_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_WRITE_TIME                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:direct_write_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_WRITE_REQS                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:direct_write_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOG_BUFFER_WAIT_TIME                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:log_buffer_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>NUM_LOG_BUFFER_FULL                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:num_log_buffer_full/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOG_DISK_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:log_disk_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOG_DISK_WAITS_TOTAL                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:log_disk_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_WRITE_TIME                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_write_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_READ_TIME                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_read_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_FILE_WRITE_WAIT_TIME          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:audit_file_write_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_FILE_WRITES_TOTAL             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:audit_file_writes_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_SUBSYSTEM_WAIT_TIME           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:audit_subsystem_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_SUBSYSTEM_WAITS_TOTAL         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:audit_subsystem_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIAGLOG_WRITE_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:diaglog_write_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIAGLOG_WRITES_TOTAL                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:diaglog_writes_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SEND_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECV_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ACT_WAIT_TIME                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_act_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SECTION_SORT_PROC_TIME        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_section_sort_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SECTION_SORTS                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_section_sorts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SECTION_SORT_TIME             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_section_sort_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ACT_TIME                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_act_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_routine_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>STMT_EXEC_TIME                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:stmt_exec_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>COORD_STMT_EXEC_TIME                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:coord_stmt_exec_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_NON_SECTION_PROC_TIME : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_routine_non_sect_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_NON_SECTION_TIME      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_routine_non_sect_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SECTION_PROC_TIME             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_section_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SECTION_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_section_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_USER_CODE_PROC_TIME   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_routine_user_code_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_USER_CODE_TIME        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_routine_user_code_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_READ                           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:rows_read/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_MODIFIED                       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:rows_modified/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_L_READS                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_L_READS                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_DATA_L_READS              : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_data_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_INDEX_L_READS             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_index_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_L_READS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_XDA_L_READS               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_xda_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_CPU_TIME                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_cpu_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_P_READS                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_DATA_P_READS              : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_data_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_P_READS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_XDA_P_READS               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_xda_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_P_READS                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_INDEX_P_READS             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_index_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_L_READS               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_P_READS               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_LBP_PAGES_FOUND           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_INDEP_PAGES_FOUND_IN_LBP  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_INVALID_PAGES         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_L_READS              : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_P_READS              : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_LBP_PAGES_FOUND          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_INDEP_PAGES_FOUND_IN_LBP  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_INVALID_PAGES        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GBP_L_READS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GBP_P_READS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_LBP_PAGES_FOUND            : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GBP_INDEP_PAGES_FOUND_IN_LBP  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GBP_INVALID_PAGES          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_WRITES                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_WRITES                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_WRITES                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_READS                        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:direct_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_WRITES                       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:direct_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_RETURNED                       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:rows_returned/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DEADLOCKS                           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:deadlocks/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_TIMEOUTS                       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_timeouts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_TIMEOUTS_GLOBAL                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_timeouts_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS                         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_escals/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS_MAXLOCKS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_escals_maxlocks/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS_LOCKLIST                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_escals_locklist/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS_GLOBAL                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lock_escals_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SENDS_TOTAL                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECVS_TOTAL                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SEND_VOLUME                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECV_VOLUME                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SENDS_TOTAL             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECVS_TOTAL             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SEND_VOLUME             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECV_VOLUME             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SENDS_TOTAL                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECVS_TOTAL                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SEND_VOLUME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECV_VOLUME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TQ_TOT_SEND_SPILLS                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:tq_tot_send_spills/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_SORTS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_threshold_sorts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_SHRTHRESHOLD_SORTS             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_shrthreshold_sorts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>SORT_OVERFLOWS                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:sort_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_EVENTS_TOTAL                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:audit_events_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SORTS                         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_sorts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>THRESH_VIOLATIONS                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:thresh_violations/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>NUM_LW_THRESH_EXCEEDED              : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:num_lw_thresh_exceeded/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_INVOCATIONS           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_routine_invocations/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_EXTENDED_LATCH_WAIT_TIME      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_extended_latch_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_EXTENDED_LATCH_WAITS          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_extended_latch_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_DISP_RUN_QUEUE_TIME           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_disp_run_queue_time/text()" />
  <xsl:text>&#10;</xsl:text>  <xsl:text>RECLAIM_WAIT_TIME                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:reclaim_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>SPACEMAPPAGE_RECLAIM_WAIT_TIME      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:spacemappage_reclaim_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CF_WAIT_TIME                        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:cf_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CF_WAITS                            : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:cf_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_PEDS                          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_peds/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DISABLED_PEDS                       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:disabled_peds/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_PEDS                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_threshold_peds/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_PEAS                          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_peas/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_PEAS                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_threshold_peas/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TQ_SORT_HEAP_REQUESTS               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:tq_sort_heap_requests/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TQ_SORT_HEAP_REJECTIONS             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:tq_sort_heap_rejections/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_DATA_REQS         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_INDEX_REQS        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_XDA_REQS          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_DATA_REQS    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_INDEX_REQS   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_XDA_REQS     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_OTHER_REQS        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_other_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_DATA_PAGES        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_data_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_INDEX_PAGES       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_index_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_XDA_PAGES         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_xda_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_DATA_PAGES   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_data_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_INDEX_PAGES  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_index_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_XDA_PAGES    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_xda_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_DATA_REQS         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_INDEX_REQS        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_XDA_REQS          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_DATA_REQS    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_temp_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_INDEX_REQS   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_temp_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_XDA_REQS     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_temp_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_OTHER_REQS        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_other_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>PREFETCH_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:prefetch_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>PREFETCH_WAITS                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:prefetch_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECV_WAITS_TOTAL             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_recv_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECV_WAITS_TOTAL        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_recv_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SEND_WAITS_TOTAL             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_tq_send_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SEND_WAITS_TOTAL        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_message_send_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SEND_WAITS_TOTAL                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_send_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECV_WAITS_TOTAL                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fcm_recv_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_SEND_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:ida_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_SENDS_TOTAL                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:ida_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_SEND_VOLUME                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:ida_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_RECV_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:ida_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_RECVS_TOTAL                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:ida_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_RECV_VOLUME                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:ida_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_DELETED                        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:rows_deleted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_INSERTED                       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:rows_inserted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_UPDATED                        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:rows_updated/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_HASH_JOINS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_hash_joins/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_HASH_LOOPS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_hash_loops/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>HASH_JOIN_OVERFLOWS                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:hash_join_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>HASH_JOIN_SMALL_OVERFLOWS           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:hash_join_small_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_SHRTHRESHOLD_HASH_JOINS        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_shrthreshold_hash_joins/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_OLAP_FUNCS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_olap_funcs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>OLAP_FUNC_OVERFLOWS                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:olap_func_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_ROWS_DELETED                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:int_rows_deleted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_ROWS_INSERTED                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:int_rows_inserted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_ROWS_UPDATED                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:int_rows_updated/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_L_READS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_COL_L_READS               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_col_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_P_READS                    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_COL_P_READS               : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_temp_col_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_LBP_PAGES_FOUND            : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_WRITES                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_L_READS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_P_READS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_INVALID_PAGES          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_INDEP_PAGES_FOUND_IN_LBP   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_COL_REQS          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_COL_REQS     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_COL_PAGES         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_col_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_COL_PAGES    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_queued_async_temp_col_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_COL_REQS          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_COL_REQS     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_failed_async_temp_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_TIME                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_PROC_TIME                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_EXECUTIONS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_executions/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_HASH_JOINS           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_threshold_hash_joins/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_L_READS      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_L_READS     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_L_READS       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_L_READS       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_PAGE_WRITES  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_PAGE_WRITES : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_PAGE_WRITES   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_PAGE_WRITES   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_PAGE_UPDATES : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_PAGE_UPDATES : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_PAGE_UPDATES  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_PAGE_UPDATES  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_CACHING_TIER_PAGE_READ_TIME    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_caching_tier_page_read_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_CACHING_TIER_PAGE_WRITE_TIME   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_caching_tier_page_write_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_PAGES_FOUND  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_PAGES_FOUND : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_PAGES_FOUND   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_PAGES_FOUND   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_GBP_INVALID_PAGES    : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_GBP_INVALID_PAGES   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_GBP_INVALID_PAGES     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_GBP_INVALID_PAGES     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_GBP_INDEP_PAGES_FOUND  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_data_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_GBP_INDEP_PAGES_FOUND : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_index_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_GBP_INDEP_PAGES_FOUND : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_xda_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_GBP_INDEP_PAGES_FOUND : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:pool_col_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_HASH_GRPBYS                   : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_hash_grpbys/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>HASH_GRPBY_OVERFLOWS                : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:hash_grpby_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_HASH_GRPBYS          : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_threshold_hash_grpbys/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_OLAP_FUNCS           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_threshold_olap_funcs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_COL_VECTOR_CONSUMERS     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:post_threshold_col_vector_consumers/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_VECTOR_CONSUMERS              : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_vector_consumers/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_VECTOR_CONSUMER_OVERFLOWS     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_vector_consumer_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ADM_OVERFLOWS: </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:adm_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ADM_BYPASS_ACT_TOTAL: </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:adm_bypass_act_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_INDEX_BUILD_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_index_build_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_INDEX_BUILD_PROC_TIME             : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_index_build_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_INDEXES_BUILT                     : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_indexes_built/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_SYNOPSIS_TIME                 : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_synopsis_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_SYNOPSIS_PROC_TIME            : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_synopsis_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_SYNOPSIS_EXECUTIONS           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:total_col_synopsis_executions/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>COL_SYNOPSIS_ROWS_INSERTED              : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:col_synopsis_rows_inserted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOB_PREFETCH_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lob_prefetch_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOB_PREFETCH_REQS                      : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:lob_prefetch_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_DELETED                        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fed_rows_deleted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_INSERTED                       : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fed_rows_inserted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_UPDATED                        : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fed_rows_updated/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_READ                           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fed_rows_read/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_WAIT_TIME                           : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fed_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_WAITS_TOTAL                         : </xsl:text>
    <xsl:value-of select="pkg:activity_metrics/pkg:fed_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : Input variables                                               -->
<!-- Description: Template will print in details each input variable contained  -->
<!--              in the XML document for a statement.                          -->
<!-- ========================================================================== -->
<xsl:template match="pkg:db2_input_variable">

  <xsl:variable name="spaces" select="'                                '" />

  <xsl:variable name="hdr" select="concat('Input variable ',
                                           pkg:stmt_value_index)" />
  <xsl:value-of select="concat( $hdr,
                                substring($spaces,
                                          0, 21 - string-length($hdr)))" />

  <xsl:text>&#10;</xsl:text>
  <xsl:text> Type              : </xsl:text>
    <xsl:value-of select="pkg:stmt_value_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text> Data              : </xsl:text>
    <xsl:value-of select="pkg:stmt_value_data/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text> Reopt             : </xsl:text>
    <xsl:value-of select="pkg:stmt_value_isreopt/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text> Null              : </xsl:text>
    <xsl:value-of select="pkg:stmt_value_isnull/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>
