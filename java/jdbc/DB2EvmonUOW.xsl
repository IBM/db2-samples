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
                xmlns:um="http://www.ibm.com/xmlns/prod/db2/mon">

<xsl:output method="text"  indent="no"/>

<!-- ========================================================================== -->
<!-- Template   : Main                                                          -->
<!-- Description: Main template to process the entire XML document              -->
<!-- ========================================================================== -->
<xsl:template match="/">

<!-- ========================================================== -->
<!-- Print out each UOW event in details                       -->
<!-- ========================================================== -->
  <xsl:for-each select="um:db2_uow_event">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
</xsl:template>


<!-- ========================================================================== -->
<!-- Template   : UOW event details                                             -->
<!-- Description: Template will process each db2UOWEvent node contained in the  -->
<!--              XML document and print out the event details.                 -->
<!-- ========================================================================== -->
<xsl:template match="um:db2_uow_event">

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
  <xsl:text>Monitoring interval ID : </xsl:text>
    <xsl:value-of select="@mon_interval_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>-------------------------------------------------------&#10;</xsl:text>

  <!-- ========================================================== -->
  <!-- Print out the database level details                       -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Database Level Details&#10;</xsl:text>
  <xsl:text>----------------------&#10;</xsl:text>
  <xsl:text>Database Member Activation Time  : </xsl:text>
    <xsl:value-of select="concat(substring(um:member_activation_time/text(), 1, 10),
                                 '-',
                                 substring(um:member_activation_time/text(), 12, 2),
                                 '.',
                                 substring(um:member_activation_time/text(), 15, 2),
                                 '.',
                                 substring(um:member_activation_time/text(), 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Coordinator Member               : </xsl:text>
    <xsl:value-of select="um:coord_member/text()" />
  <xsl:text>&#10;</xsl:text>

  <!-- ========================================================== -->
  <!-- Print out the connection level details                     -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Connection Level Details&#10;</xsl:text>
  <xsl:text>------------------------&#10;</xsl:text>
  <xsl:text>Application ID             : </xsl:text>
    <xsl:value-of select="um:application_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Application Handle         : </xsl:text>
    <xsl:value-of select="um:application_handle/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Application Name           : </xsl:text>
    <xsl:value-of select="um:application_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Session Authorization ID   : </xsl:text>
    <xsl:value-of select="um:session_authid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>System Authorization ID    : </xsl:text>
    <xsl:value-of select="um:system_authid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Connection Timestamp       : </xsl:text>
    <xsl:value-of select="concat(substring(um:connection_time/text(), 1, 10),
                                 '-',
                                 substring(um:connection_time/text(), 12, 2),
                                 '.',
                                 substring(um:connection_time/text(), 15, 2),
                                 '.',
                                 substring(um:connection_time/text(), 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Process ID          : </xsl:text>
    <xsl:value-of select="um:client_pid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Platform            : </xsl:text>
    <xsl:value-of select="um:client_platform/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Product ID          : </xsl:text>
    <xsl:value-of select="um:client_product_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Protocol            : </xsl:text>
    <xsl:value-of select="um:client_protocol/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Hostname            : </xsl:text>
    <xsl:value-of select="um:client_hostname/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Port Number         : </xsl:text>
    <xsl:value-of select="um:client_port_number/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Member Subset Identifier   : </xsl:text>
    <xsl:value-of select="um:member_subset_id/text()" />

  <!-- ========================================================== -->
  <!-- Print out the UOW level details                            -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>UOW Level Details&#10;</xsl:text>
  <xsl:text>------------------------&#10;</xsl:text>
  <xsl:text>Start Time                 : </xsl:text>
    <xsl:value-of select="concat(substring(um:start_time/text(), 1, 10),
                                 '-',
                                 substring(um:start_time/text(), 12, 2),
                                 '.',
                                 substring(um:start_time/text(), 15, 2),
                                 '.',
                                 substring(um:start_time/text(), 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stop Time                  : </xsl:text>
    <xsl:value-of select="concat(substring(um:stop_time/text(), 1, 10),
                                 '-',
                                 substring(um:stop_time/text(), 12, 2),
                                 '.',
                                 substring(um:stop_time/text(), 15, 2),
                                 '.',
                                 substring(um:stop_time/text(), 18, 9))" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Completion Status          : </xsl:text>
    <xsl:value-of select="um:completion_status/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Intra-parallel State       : </xsl:text>
    <xsl:value-of select="um:intra_parallel_state/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>UOW ID                     : </xsl:text>
    <xsl:value-of select="um:uow_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Workoad Occurrence ID      : </xsl:text>
    <xsl:value-of select="um:workload_occurrence_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Workload Name              : </xsl:text>
    <xsl:value-of select="um:workload_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Workoad ID                 : </xsl:text>
    <xsl:value-of select="um:workload_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Service Superclass Name    : </xsl:text>
    <xsl:value-of select="um:service_superclass_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Service Subclass Name      : </xsl:text>
    <xsl:value-of select="um:service_subclass_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Service Class ID           : </xsl:text>
    <xsl:value-of select="um:service_class_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Userid              : </xsl:text>
    <xsl:value-of select="um:client_userid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Workstation Name    : </xsl:text>
    <xsl:value-of select="um:client_wrkstnname/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Application Name    : </xsl:text>
    <xsl:value-of select="um:client_applname/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Accounting String   : </xsl:text>
    <xsl:value-of select="um:client_acctng/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Local Transaction ID       : </xsl:text>
    <xsl:value-of select="um:local_transaction_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Global Transaction ID      : </xsl:text>
    <xsl:value-of select="um:global_transaction_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Log Space Used             : </xsl:text>
    <xsl:value-of select="um:uow_log_space_used/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Hash Group Bys Top              : </xsl:text>
    <xsl:value-of select="um:active_hash_grpbys_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Hash Joins Top                  : </xsl:text>
    <xsl:value-of select="um:active_hash_joins_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active OLAP Functions Top              : </xsl:text>
    <xsl:value-of select="um:active_olap_funcs_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Partial Early Aggregations Top  : </xsl:text>
    <xsl:value-of select="um:active_peas_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Partial Early Distincts Top     : </xsl:text>
    <xsl:value-of select="um:active_peds_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Sort Consumers Top              : </xsl:text>
    <xsl:value-of select="um:active_sort_consumers_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Sorts Top                       : </xsl:text>
    <xsl:value-of select="um:active_sorts_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Active Columnar Vector Consumers Top   : </xsl:text>
    <xsl:value-of select="um:active_col_vector_consumers_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Consumer Heap Top                 : </xsl:text>
    <xsl:value-of select="um:sort_consumer_heap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Consumer Shared Heap Top          : </xsl:text>
    <xsl:value-of select="um:sort_consumer_shrheap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Heap Top                          : </xsl:text>
    <xsl:value-of select="um:sort_heap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sort Shared Heap Top                   : </xsl:text>
    <xsl:value-of select="um:sort_shrheap_top/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Session Priority                       : </xsl:text>
    <xsl:value-of select="um:session_priority/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Tenant Name                            : </xsl:text>
    <xsl:value-of select="um:tenant_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Tenant Id                              : </xsl:text>
    <xsl:value-of select="um:tenant_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <!-- ========================================================== -->
  <!-- Print out the UOW metrics details                          -->
  <!-- Metrics that are not part of the document, are             -->
  <!-- printed as empty strings                                   -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>UOW Metrics&#10;</xsl:text>
  <xsl:text>------------------------&#10;</xsl:text>
  <xsl:text>TOTAL_CPU_TIME                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_cpu_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_WAIT_TIME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ACT_ABORTED_TOTAL              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:act_aborted_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ACT_COMPLETED_TOTAL            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:act_completed_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ACT_REJECTED_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:act_rejected_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AGENT_WAIT_TIME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:agent_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AGENT_WAITS_TOTAL              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:agent_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>APP_RQSTS_COMPLETED_TOTAL      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:app_rqsts_completed_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_EVENTS_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:audit_events_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_SUBSYSTEM_WAIT_TIME      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:audit_subsystem_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_SUBSYSTEM_WAITS_TOTAL    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:audit_subsystem_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_FILE_WRITE_WAIT_TIME     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:audit_file_write_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>AUDIT_FILE_WRITES_TOTAL        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:audit_file_writes_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_L_READS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_L_READS             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_DATA_L_READS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_data_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_INDEX_L_READS        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_index_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_XDA_L_READS          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_xda_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_L_READS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_P_READS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_P_READS             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_DATA_P_READS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_data_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_INDEX_P_READS        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_index_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_XDA_P_READS          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_xda_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_P_READS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_L_READS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GPB_P_READS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_LBP_PAGES_FOUND       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_INDEP_PAGES_FOUND_IN_LBP  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_INVALID_PAGES     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_L_READS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GPB_P_READS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_LBP_PAGES_FOUND       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_INDEP_PAGES_FOUND_IN_LBP  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_INVALID_PAGES     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GBP_L_READS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GPB_P_READS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_LBP_PAGES_FOUND       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GBP_INDEP_PAGES_FOUND_IN_LBP  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_GBP_INVALID_PAGES     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_WRITES               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_WRITES              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_WRITES                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_READ_TIME                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_read_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_WRITE_TIME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_write_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CLIENT_IDLE_WAIT_TIME          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:client_idle_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DEADLOCKS                      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:deadlocks/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIAGLOG_WRITES_TOTAL           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:diaglog_writes_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIAGLOG_WRITE_WAIT_TIME        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:diaglog_write_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_READS                   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:direct_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_READ_TIME               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:direct_read_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_WRITES                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:direct_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_WRITE_TIME              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:direct_write_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_READ_REQS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:direct_read_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DIRECT_WRITE_REQS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:direct_write_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECV_VOLUME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECVS_TOTAL                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SEND_VOLUME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SENDS_TOTAL                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECV_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SEND_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECV_VOLUME        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECVS_TOTAL        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECV_WAIT_TIME     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SEND_VOLUME        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SENDS_TOTAL        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SEND_WAIT_TIME     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECV_WAIT_TIME          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECVS_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECV_VOLUME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SEND_WAIT_TIME          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SENDS_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SEND_VOLUME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TQ_TOT_SEND_SPILLS             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tq_tot_send_spills/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IPC_RECV_VOLUME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ipc_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IPC_RECV_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ipc_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IPC_RECVS_TOTAL                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ipc_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IPC_SEND_VOLUME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ipc_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IPC_SEND_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ipc_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IPC_SENDS_TOTAL                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ipc_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_escals/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS_MAXLOCKS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_escals_maxlocks/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS_LOCKLIST           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_escals_locklist/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_ESCALS_GLOBAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_escals_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_TIMEOUTS                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_timeouts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_TIMEOUTS_GLOBAL           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_timeouts_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAIT_TIME                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAIT_TIME_GLOBAL          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_wait_time_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAITS                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOCK_WAITS_GLOBAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lock_waits_global/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_GBP_P_READS          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_GBP_P_READS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOG_BUFFER_WAIT_TIME           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:log_buffer_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>NUM_LOG_BUFFER_FULL            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:num_log_buffer_full/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOG_DISK_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:log_disk_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOG_DISK_WAITS_TOTAL           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:log_disk_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>RQSTS_COMPLETED_TOTAL          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:rqsts_completed_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_MODIFIED                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:rows_modified/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_READ                      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:rows_read/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_RETURNED                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:rows_returned/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TCPIP_RECV_VOLUME              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tcpip_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TCPIP_SEND_VOLUME              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tcpip_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TCPIP_RECV_WAIT_TIME           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tcpip_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TCPIP_RECVS_TOTAL              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tcpip_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TCPIP_SEND_WAIT_TIME           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tcpip_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TCPIP_SENDS_TOTAL              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tcpip_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_APP_RQST_TIME            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_app_rqst_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_RQST_TIME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_rqst_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>WLM_QUEUE_TIME_TOTAL           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:wlm_queue_time_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>WLM_QUEUE_ASSIGNMENTS_TOTAL    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:wlm_queue_assignments_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_routine_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COMPILE_PROC_TIME        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_compile_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COMPILE_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_compile_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COMPILATIONS             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_compilations/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_IMPLICIT_COMPILE_PROC_TIME : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_implicit_compile_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_IMPLICIT_COMPILE_TIME    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_implicit_compile_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_IMPLICIT_COMPILATIONS    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_implicit_compilations/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_RUNSTATS_PROC_TIME       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_runstats_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_RUNSTATS_TIME            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_runstats_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_RUNSTATS                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_runstats/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_REORG_PROC_TIME          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_reorg_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_REORG_TIME               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_reorg_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_REORGS                   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_reorgs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_LOAD_PROC_TIME           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_load_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_LOAD_TIME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_load_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_LOADS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_loads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SECTION_PROC_TIME        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_section_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SECTION_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_section_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_APP_SECTION_EXECUTIONS   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_app_section_executions/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COMMIT_PROC_TIME         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_commit_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COMMIT_TIME              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_commit_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_APP_COMMITS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_app_commits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROLLBACK_PROC_TIME       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_rollback_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROLLBACK_TIME            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_rollback_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_APP_ROLLBACKS            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_app_rollbacks/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_USER_CODE_PROC_TIME : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_routine_user_code_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_USER_CODE_TIME   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_routine_user_code_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>THRESH_VIOLATIONS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:thresh_violations/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>NUM_LW_THRESH_EXCEEDED         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:num_lw_thresh_exceeded/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_ROUTINE_INVOCATIONS      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_routine_invocations/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_COMMITS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:int_commits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_ROLLBACKS                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:int_rollbacks/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CAT_CACHE_INSERTS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:cat_cache_inserts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CAT_CACHE_LOOKUPS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:cat_cache_lookups/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>PKG_CACHE_INSERTS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pkg_cache_inserts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>PKG_CACHE_LOOKUPS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pkg_cache_lookups/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ACT_RQSTS_TOTAL                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:act_rqsts_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>RECLAIM_WAIT_TIME              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:reclaim_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>SPACEMAPPAGE_RECLAIM_WAIT_TIME : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:spacemappage_reclaim_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CF_WAIT_TIME                   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:cf_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CF_WAITS                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:cf_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>EVMON_WAIT_TIME                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:evmon_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>EVMON_WAITS_TOTAL              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:evmon_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_STATS_FABRICATION_PROC_TIME : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_stats_fabrication_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_STATS_FABRICATION_TIME   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_stats_fabrication_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_STATS_FABRICATIONS       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_stats_fabrications/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SYNC_RUNSTATS_PROC_TIME  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_sync_runstats_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SYNC_RUNSTATS_TIME       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_sync_runstats_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_SYNC_RUNSTATS            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_sync_runstats/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_EXTENDED_LATCH_WAIT_TIME : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_extended_latch_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_EXTENDED_LATCH_WAITS     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_extended_latch_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_DISP_RUN_QUEUE_TIME      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_disp_run_queue_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_DATA_REQS     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_INDEX_REQS    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_XDA_REQS      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_DATA_REQS     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_INDEX_REQS    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_XDA_REQS      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_OTHER_REQS      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_other_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_DATA_PAGES     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_data_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_INDEX_PAGES    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_index_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_XDA_PAGES      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_xda_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_DATA_PAGES     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_data_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_INDEX_PAGES    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_index_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_XDA_PAGES      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_xda_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_DATA_REQS        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_INDEX_REQS       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_XDA_REQS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_DATA_REQS        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_temp_data_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_INDEX_REQS       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_temp_index_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_XDA_REQS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_temp_xda_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_OTHER_REQS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_other_reqs/text()" />
  <xsl:text>&#10;</xsl:text>

  <xsl:text>APP_ACT_COMPLETED_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:app_act_completed_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>APP_ACT_ABORTED_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:app_act_aborted_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>APP_ACT_REJECTED_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:app_act_rejected_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_PEDS                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_peds/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DISABLED_PEDS                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:disabled_peds/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_PEDS            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:post_threshold_peds/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_PEAS                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_peas/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_PEAS            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:post_threshold_peas/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TQ_SORT_HEAP_REQUESTS          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tq_sort_heap_requests/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TQ_SORT_HEAP_REJECTIONS        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:tq_sort_heap_rejections/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_CONNECT_REQUEST_TIME     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_connect_request_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_CONNECT_REQUEST_PROC_TIME : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_connect_request_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_CONNECT_REQUESTS          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_connect_requests/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_CONNECT_AUTHENTICATION_TIME      : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_connect_authentication_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_CONNECT_AUTHENTICATION_PROC_TIME : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_connect_authentication_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_CONNECT_AUTHENTICATIONS          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_connect_authentications/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>PREFETCH_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:prefetch_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>PREFETCH_WAITS                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:prefetch_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>COMM_EXIT_WAIT_TIME            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:comm_exit_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>COMM_EXIT_WAITS                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:comm_exit_waits/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_RECV_WAITS_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_recv_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_RECV_WAITS_TOTAL        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_recv_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_TQ_SEND_WAITS_TOTAL             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_tq_send_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_MESSAGE_SEND_WAITS_TOTAL        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_message_send_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_SEND_WAITS_TOTAL                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_send_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FCM_RECV_WAITS_TOTAL                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fcm_recv_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_SEND_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ida_send_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_SENDS_TOTAL                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ida_sends_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_SEND_VOLUME                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ida_send_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_RECV_WAIT_TIME                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ida_recv_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_RECVS_TOTAL                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ida_recvs_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IDA_RECV_VOLUME                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ida_recv_volume/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_DELETED                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:rows_deleted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ROWS_INSERTED                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:rows_inserted/text()" />
  <xsl:text>&#10;</xsl:text> 
  <xsl:text>ROWS_UPDATED                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:rows_updated/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_HASH_JOINS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_hash_joins/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_HASH_LOOPS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_hash_loops/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>HASH_JOIN_OVERFLOWS                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:hash_join_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>HASH_JOIN_SMALL_OVERFLOWS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:hash_join_small_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_SHRTHRESHOLD_HASH_JOINS        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:post_shrthreshold_hash_joins/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_OLAP_FUNCS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_olap_funcs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>OLAP_FUNC_OVERFLOWS                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:olap_func_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DYNAMIC_SQL_STMTS                   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:dynamic_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>STATIC_SQL_STMTS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:static_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FAILED_SQL_STMTS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:failed_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>SELECT_SQL_STMTS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:select_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>UID_SQL_STMTS                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:uid_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DDL_SQL_STMTS                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:ddl_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>MERGE_SQL_STMTS                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:merge_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>XQUERY_STMTS                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:xquery_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>IMPLICIT_REBINDS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:implicit_rebinds/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>BINDS_PRECOMPLIES                   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:binds_precompiles/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_ROWS_DELETED                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:int_rows_deleted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_ROWS_INSERTED                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:int_rows_inserted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>INT_ROWS_UPDATED                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:int_rows_updated/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CALL_SQL_STMTS                          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:call_sql_stmts/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_L_READS                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_COL_L_READS                   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_col_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_P_READS                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_COL_P_READS                   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_col_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_LBP_PAGES_FOUND                : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_lbp_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_WRITES                         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_L_READS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_gbp_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_P_READS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_gbp_p_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_INVALID_PAGES              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_GBP_INDEP_PAGES_FOUND_IN_LBP   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_gbp_indep_pages_found_in_lbp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_COL_REQS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_COL_REQS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_COL_PAGES             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_col_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_QUEUED_ASYNC_TEMP_COL_PAGES        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_queued_async_temp_col_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_COL_REQS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_FAILED_ASYNC_TEMP_COL_REQS         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_failed_async_temp_col_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_TIME                          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_col_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_PROC_TIME                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_col_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_EXECUTIONS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_col_executions/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_HASH_JOINS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:post_threshold_hash_joins/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_L_READS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_L_READS             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_L_READS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_L_READS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_DATA_CACHING_TIER_L_READS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_data_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_INDEX_CACHING_TIER_L_READS             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_index_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_XDA_CACHING_TIER_L_READS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_xda_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_COL_CACHING_TIER_L_READS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_col_caching_tier_l_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_DATA_CACHING_TIER_PAGES_FOUND              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_data_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_INDEX_CACHING_TIER_PAGES_FOUND             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_index_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_XDA_CACHING_TIER_PAGES_FOUND               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_xda_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_TEMP_COL_CACHING_TIER_PAGES_FOUND               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_temp_col_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CACHING_TIER_DIRECT_READS             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:caching_tier_direct_reads/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CACHING_TIER_DIRECT_READ_TIME               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:caching_tier_direct_read_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CACHING_TIER_DIRECT_READ_REQS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:caching_tier_direct_read_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_PAGE_WRITES          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_PAGE_WRITES         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_PAGE_WRITES           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_PAGE_WRITES           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_caching_tier_page_writes/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_PAGE_UPDATES         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_PAGE_UPDATES        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_PAGE_UPDATES          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_PAGE_UPDATES          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_caching_tier_page_updates/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_CACHING_TIER_PAGE_READ_TIME           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_caching_tier_page_read_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_CACHING_TIER_PAGE_WRITE_TIME          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_caching_tier_page_write_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_PAGES_FOUND          : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_PAGES_FOUND         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_PAGES_FOUND           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_PAGES_FOUND           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_caching_tier_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_GBP_INVALID_PAGES    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_GBP_INVALID_PAGES   : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_GBP_INVALID_PAGES     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_GBP_INVALID_PAGES     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_caching_tier_gbp_invalid_pages/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_DATA_CACHING_TIER_GBP_INDEP_PAGES_FOUND  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_data_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_INDEX_CACHING_TIER_GBP_INDEP_PAGES_FOUND : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_index_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_XDA_CACHING_TIER_GBP_INDEP_PAGES_FOUND : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_xda_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POOL_COL_CACHING_TIER_GBP_INDEP_PAGES_FOUND : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:pool_col_caching_tier_gbp_indep_pages_found/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_HASH_GRPBYS                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_hash_grpbys/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>HASH_GRPBY_OVERFLOWS                    : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:hash_grpby_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_HASH_GRPBYS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:post_threshold_hash_grpbys/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_OLAP_FUNCS               : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:post_threshold_olap_funcs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>POST_THRESHOLD_COL_VECTOR_CONSUMERS     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:post_threshold_col_vector_consumers/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_VECTOR_CONSUMERS              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_col_vector_consumers/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ADM_OVERFLOWS     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:adm_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>ADM_BYPASS_ACT_TOTAL     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:adm_bypass_act_total/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_BACKUP_TIME                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_backup_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_BACKUP_PROC_TIME                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_backup_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_BACKUPS                           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_backups/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_INDEX_BUILD_TIME                  : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_index_build_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_INDEX_BUILD_PROC_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_index_build_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_INDEXES_BUILT                     : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_indexes_built/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>COL_VECTOR_CONSUMER_OVERFLOWS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:col_vector_consumer_overflows/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_SYNOPSIS_TIME                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_col_synopsis_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_SYNOPSIS_PROC_TIME            : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_col_synopsis_proc_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TOTAL_COL_SYNOPSIS_EXECUTIONS           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:total_col_synopsis_executions/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>COL_SYNOPSIS_ROWS_INSERTED              : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:col_synopsis_rows_inserted/text()" />
 <xsl:text>&#10;</xsl:text>
 <xsl:text>APPL_SECTION_INSERTS : </xsl:text>
   <xsl:value-of select="um:system_metrics/um:appl_section_inserts/text()" />
 <xsl:text>&#10;</xsl:text>
 <xsl:text>APPL_SECTION_LOOKUPS : </xsl:text>
   <xsl:value-of select="um:system_metrics/um:appl_section_lookups/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOB_PREFETCH_WAIT_TIME             : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lob_prefetch_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>LOB_PREFETCH_REQS                 : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:lob_prefetch_reqs/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_DELETED                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fed_rows_deleted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_INSERTED                       : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fed_rows_inserted/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_UPDATED                        : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fed_rows_updated/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_ROWS_READ                           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fed_rows_read/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_WAIT_TIME                           : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fed_wait_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>FED_WAITS_TOTAL                         : </xsl:text>
    <xsl:value-of select="um:system_metrics/um:fed_waits_total/text()" />
  <xsl:text>&#10;</xsl:text>

  <!-- ========================================================== -->
  <!-- Print out the Package List Details                         -->
  <!-- Print out at least the info about the package list, and    -->
  <!-- optionally print out the whole list if it is there         -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package List&#10;</xsl:text>
  <xsl:text>------------------------&#10;</xsl:text>
  <xsl:text>Package List Size              : </xsl:text>
    <xsl:value-of select="um:package_list/um:package_list_size/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package List Exceeded          : </xsl:text>
    <xsl:value-of select="um:package_list/um:package_list_exceeded/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>

  <xsl:if test="um:package_list/um:package_list_size &gt; 0">
     <xsl:text>PACKAGE_ID           NESTING_LEVEL ROUTINE_ID  INVOCATION_ID        PACKAGE_ELAPSED_TIME&#10;</xsl:text>
     <xsl:text>-------------------- ------------- ----------- -------------------- --------------------&#10;</xsl:text>
  </xsl:if>

  <xsl:apply-templates select="um:package_list/um:package_list_entries/um:package_entry" />



  <!-- ========================================================== -->
  <!-- Print out the Executable List Details                      -->
  <!-- Print out at least the info about the executable list, and -->
  <!-- optionally print out the whole list if it is there         -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Executable List&#10;</xsl:text>
  <xsl:text>------------------------&#10;</xsl:text>
  <xsl:text>Executable List Size              : </xsl:text>
    <xsl:value-of select="um:executable_list/um:executable_list_size/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Executable List Truncated          : </xsl:text>
    <xsl:value-of select="um:executable_list/um:executable_list_truncated/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>

  <xsl:if test="um:executable_list/um:executable_list_size &gt; 0">
     <xsl:text>EXECUTABLE_ID                                                    NUM_EXECUTIONS ROWS_READ   TOTAL_CPU_TIME  TOTAL_ACT_TIME  TOTAL_ACT_WAIT_TIME  LOCK_WAIT_TIME  LOCK_WAITS  TOTAL_SORTS  POST_THRESHOLD_SORTS  POST_SHRTHRESHOLD_SORTS  SORT_OVERFLOWS&#10;</xsl:text>
     <xsl:text>---------------------------------------------------------------- -------------- ----------- --------------- --------------- -------------------  --------------  ----------  -----------  --------------------  -----------------------  --------------&#10;</xsl:text>
  </xsl:if>

  <xsl:apply-templates select="um:executable_list/um:executable_list_entries/um:executable_entry" />

</xsl:template>



<!-- ========================================================================== -->
<!-- Template   : Print package list row                                        -->
<!-- Description: Template will print a single row of package list              -->
<!-- ========================================================================== -->
<xsl:template match="um:package_entry">

  <!-- ========================================================== -->
  <!-- Package ID                                                 -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:package_id/text())" />
    <xsl:with-param name="maxl"   select="'20'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Nesting level                                              -->
  <!-- ========================================================== -->

  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:nesting_level/text())" />
    <xsl:with-param name="maxl"   select="'13'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Routine ID                                                 -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:routine_id/text())" />
    <xsl:with-param name="maxl"   select="'11'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>


  <!-- ========================================================== -->
  <!-- Invocation ID                                              -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:invocation_id/text())" />
    <xsl:with-param name="maxl"   select="'20'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>


  <!-- ========================================================== -->
  <!-- Elapsed Time                                               -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:package_elapsed_time/text())" />
    <xsl:with-param name="maxl"   select="'20'" />
  </xsl:call-template>

  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : Print executable list row                                        -->
<!-- Description: Template will print a single row of executable list           -->
<!-- ========================================================================== -->
<xsl:template match="um:executable_entry">

  <!-- ========================================================== -->
  <!-- Executable ID                                              -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:executable_id/text())" />
    <xsl:with-param name="maxl"   select="'64'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Number of Executions                                       -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:num_executions/text())" />
    <xsl:with-param name="maxl"   select="'14'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Rows Read                                                  -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:rows_read/text())" />
    <xsl:with-param name="maxl"   select="'11'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Total CPU Time                                             -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:total_cpu_time/text())" />
    <xsl:with-param name="maxl"   select="'15'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Total Act Time                                             -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:total_act_time/text())" />
    <xsl:with-param name="maxl"   select="'15'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Total Act Wait Time                                        -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:total_act_wait_time/text())" />
    <xsl:with-param name="maxl"   select="'19'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Lock wait time                                             -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:lock_wait_time/text())" />
    <xsl:with-param name="maxl"   select="'14'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Lock Waits                                                 -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:lock_waits/text())" />
    <xsl:with-param name="maxl"   select="'10'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Total sorts                                                -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:total_sorts/text())" />
    <xsl:with-param name="maxl"   select="'11'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Post threshold sorts                                       -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:post_threshold_sorts/text())" />
    <xsl:with-param name="maxl"   select="'20'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Post shared threshold sorts                                -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:post_shrthreshold_sorts/text())" />
    <xsl:with-param name="maxl"   select="'23'" />
  </xsl:call-template>

  <xsl:text> </xsl:text>

  <!-- ========================================================== -->
  <!-- Sort overflows                                             -->
  <!-- ========================================================== -->
  <xsl:call-template name="print_list_value">
    <xsl:with-param name="value"  select="string(um:sort_overflows/text())" />
    <xsl:with-param name="maxl"   select="'14'" />
  </xsl:call-template>


<xsl:text>&#10;</xsl:text>
</xsl:template>



<!-- ========================================================================== -->
<!-- Template   : Print list value                                              -->
<!-- Description: Function to blank pad a value out to maximum length           -->
<!-- ========================================================================== -->
<xsl:template name="print_list_value">
  <xsl:param name="value"/>
  <xsl:param name="maxl"/>

  <xsl:variable name="spaces" select="'                                    '" />
  <xsl:variable name="val_length" select="string-length($value)"/>

  <xsl:choose>
    <xsl:when test="$val_length &lt; $maxl">
      <xsl:value-of select="concat( substring( $spaces,
                                               1,
                                               $maxl - $val_length ),
                                    $value)"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="substring($value, 1, $maxl)" />
    </xsl:otherwise>
  </xsl:choose>

</xsl:template>


</xsl:stylesheet>
