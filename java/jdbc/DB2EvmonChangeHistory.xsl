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
                xmlns:chghist="http://www.ibm.com/xmlns/prod/db2/mon">

<xsl:output method="text"  indent="no"/>

<!-- ========================================================================== -->
<!-- Template   : Main                                                          -->
<!-- Description: Main template to process the entire XML document              -->
<!-- ========================================================================== -->
<xsl:template match="/">

<!-- ========================================================== -->
<!-- Print out each change history event in details             -->
<!-- ========================================================== -->
  <xsl:for-each select="chghist:db2_change_history_event">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : db2_change_history_event                                      -->
<!-- Description: Process db2_change_history_event element                      -->
<!-- ========================================================================== -->

<xsl:template match="chghist:db2_change_history_event">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>------------------------------------------------------&#10;</xsl:text>
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
  
  <!-- ===================================================================== -->
  <!-- Print out info from each change hist event table                      -->
  <!-- ===================================================================== -->
  <xsl:for-each select="chghist:event_summary">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:dbcfg_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:ddlstmt_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:evmonstart_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:regvar_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:txn_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:utilstart_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:utilstop_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:utilloc_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
  <xsl:for-each select="chghist:utilphase_rows">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ========================================================================= -->
<!-- Template   : Event Summary                                                -->
<!-- Description: Print out info of event summary                              -->
<!-- ========================================================================= -->
<xsl:template match="chghist:event_summary">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Event Summary&#10;</xsl:text>
  <xsl:text>=============&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Application ID                  : </xsl:text>
    <xsl:value-of select="chghist:appl_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Application Name                : </xsl:text>
    <xsl:value-of select="chghist:appl_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Application Handle              : </xsl:text>
    <xsl:value-of select="chghist:application_handle/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Backup Timestamp                : </xsl:text>
    <xsl:value-of select="chghist:backup_timestamp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Acctng                   : </xsl:text>
    <xsl:value-of select="chghist:client_acctng/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Application Name         : </xsl:text>
    <xsl:value-of select="chghist:client_applname/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Host Name                : </xsl:text>
    <xsl:value-of select="chghist:client_hostname/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client PID                      : </xsl:text>
    <xsl:value-of select="chghist:client_pid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Platform                 : </xsl:text>
    <xsl:value-of select="chghist:client_platform/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Port Number              : </xsl:text>
    <xsl:value-of select="chghist:client_port_number/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Protocol                 : </xsl:text>
    <xsl:value-of select="chghist:client_protocol/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Client Wrkstnname               : </xsl:text>
    <xsl:value-of select="chghist:client_wrknname/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Coord Member                    : </xsl:text>
    <xsl:value-of select="chghist:coord_member/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Session Authid                  : </xsl:text>
    <xsl:value-of select="chghist:session_authid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>System Authid                   : </xsl:text>
    <xsl:value-of select="chghist:system_authid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Invocation ID           : </xsl:text>
    <xsl:value-of select="chghist:utility_invocation_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Type                    : </xsl:text>
    <xsl:value-of select="chghist:utility_type/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : DBDBMCFG                                                   -->
<!-- Description: Print out info of each row of dbdbmcfg table               -->
<!-- ======================================================================= -->
<xsl:template match="chghist:dbcfg_rows">
  <xsl:for-each select="chghist:dbcfg_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : DDLSTMTEXEC                                                -->
<!-- Description: Print out info of each row of ddlstmtexec table            -->
<!-- ======================================================================= -->
<xsl:template match="chghist:ddlstmt_rows">
  <xsl:for-each select="chghist:ddlstmt_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : EVMONSTART                                                 -->
<!-- Description: Print out info of each row of evmonstart table             -->
<!-- ======================================================================= -->
<xsl:template match="chghist:evmonstart_rows">
  <xsl:for-each select="chghist:evmonstart_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : REGVAR                                                     -->
<!-- Description: Print out info of each row of regvar table                 -->
<!-- ======================================================================= -->
<xsl:template match="chghist:regvar_rows">
  <xsl:for-each select="chghist:regvar_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : TXNCOMPLETION                                              -->
<!-- Description: Print out info of each row of txncompletion table          -->
<!-- ======================================================================= -->
<xsl:template match="chghist:txn_rows">
  <xsl:for-each select="chghist:txn_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : UTILSTART                                                  -->
<!-- Description: Print out info of each row of utilstart table              -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilstart_rows">
  <xsl:for-each select="chghist:utilstart_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : UTILLOCATION                                               -->
<!-- Description: Print out info of each row of utillocation table           -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilloc_rows">
  <xsl:for-each select="chghist:utilloc_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : UTILSTOP                                                   -->
<!-- Description: Print out info of each row of utilstop table               -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilstop_rows">
  <xsl:for-each select="chghist:utilstop_row">
    <xsl:apply-templates select="." /> 
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : UTILPHASE                                                  -->
<!-- Description: Print out info of each row of utilphase table              -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilphase_rows">
  <xsl:for-each select="chghist:utilphase_row">
    <xsl:apply-templates select="." />
  </xsl:for-each>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : dbcfg_row                                                  -->
<!-- Description: Print out info of dbcfg_row                                -->
<!-- ======================================================================= -->
<xsl:template match="chghist:dbcfg_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Database Config Change Details&#10;</xsl:text>
  <xsl:text>==============================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CFG Name                        : </xsl:text>
    <xsl:value-of select="chghist:cfg_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CFG Value                       : </xsl:text>
    <xsl:value-of select="chghist:cfg_value/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CFG Value Flags                 : </xsl:text>
    <xsl:value-of select="chghist:cfg_value_flags/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CFG Old Value                   : </xsl:text>
    <xsl:value-of select="chghist:cfg_old_value/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>CFG Old Value Flags             : </xsl:text>
    <xsl:value-of select="chghist:cfg_old_value_flags/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Collection Type                 : </xsl:text>
    <xsl:value-of select="chghist:collection_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Deferred                        : </xsl:text>
    <xsl:value-of select="chghist:deferred/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : ddlstmt_row                                                -->
<!-- Description: Print out info of ddlstmt_row                              -->
<!-- ======================================================================= -->
<xsl:template match="chghist:ddlstmt_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DDL Statement Change Details&#10;</xsl:text>
  <xsl:text>============================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Partition Key                   : </xsl:text>
    <xsl:value-of select="chghist:partition_key/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Global Transaction ID           : </xsl:text>
    <xsl:value-of select="chghist:global_transaction_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Local Transaction ID            : </xsl:text>
    <xsl:value-of select="chghist:local_transaction_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Save Point ID                   : </xsl:text>
    <xsl:value-of select="chghist:savepoint_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>UOW ID                          : </xsl:text>
    <xsl:value-of select="chghist:uow_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DDL Classification              : </xsl:text>
    <xsl:value-of select="chghist:ddl_classification/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Statement Text                  : </xsl:text>
    <xsl:value-of select="chghist:stmt_text/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : evmonstart_row                                             -->
<!-- Description: Print out info of evmonstart_row                           -->
<!-- ======================================================================= -->
<xsl:template match="chghist:evmonstart_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Evmon Start Change Details&#10;</xsl:text>
  <xsl:text>==========================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DB2 Start Time                  : </xsl:text>
    <xsl:value-of select="chghist:db2start_time/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>DB Connect Time                 : </xsl:text>
    <xsl:value-of select="chghist:db_conn_time/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : regvar_row                                                 -->
<!-- Description: Print out info of regvar_row                               -->
<!-- ======================================================================= -->
<xsl:template match="chghist:regvar_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Register Variable Change Details&#10;</xsl:text>
  <xsl:text>================================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Register Variable Collection Type : </xsl:text>
    <xsl:value-of select="chghist:regvar_collection_level/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Register Variable Level         : </xsl:text>
    <xsl:value-of select="chghist:regvar_level/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Register Variable Name          : </xsl:text>
    <xsl:value-of select="chghist:regvar_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Register Variable Old Value     : </xsl:text>
    <xsl:value-of select="chghist:regvar_old_value/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Register Variable Value         : </xsl:text>
    <xsl:value-of select="chghist:regvar_value/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : txn_row                                                    -->
<!-- Description: Print out info of txn_row                                  -->
<!-- ======================================================================= -->
<xsl:template match="chghist:txn_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TXN Completion Change Details&#10;</xsl:text>
  <xsl:text>=============================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Global Transaction ID           : </xsl:text>
    <xsl:value-of select="chghist:global_transaction_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Local Transaction ID            : </xsl:text>
    <xsl:value-of select="chghist:local_transaction_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Save Point ID                   : </xsl:text>
    <xsl:value-of select="chghist:savepoint_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TXN Completion Status           : </xsl:text>
    <xsl:value-of select="chghist:txn_completion_status/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>UOW ID                          : </xsl:text>
    <xsl:value-of select="chghist:uow_id/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : utilstart_row                                              -->
<!-- Description: Print out info of utilstart_row                            -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilstart_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Start Change Details&#10;</xsl:text>
  <xsl:text>============================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Number of TBSP                  : </xsl:text>
    <xsl:value-of select="chghist:num_tbsps/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Object Name                     : </xsl:text>
    <xsl:value-of select="chghist:object_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Object Schema                   : </xsl:text>
    <xsl:value-of select="chghist:object_shema/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Object Type                     : </xsl:text>
    <xsl:value-of select="chghist:object_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>TBSP Names                      : </xsl:text>
    <xsl:value-of select="chghist:tbsp_names/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Detail                  : </xsl:text>
    <xsl:value-of select="chghist:utility_detail/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Invocation ID           : </xsl:text>
    <xsl:value-of select="chghist:utility_invocation_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Invoker Type            : </xsl:text>
    <xsl:value-of select="chghist:utility_invoker_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Operation Type          : </xsl:text>
    <xsl:value-of select="chghist:utility_operation_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Priority                : </xsl:text>
    <xsl:value-of select="chghist:utility_priority/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Start Type              : </xsl:text>
    <xsl:value-of select="chghist:utility_start_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Type                    : </xsl:text>
    <xsl:value-of select="chghist:utility_type/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : utilloc_row                                                -->
<!-- Description: Print out info of utilloc_row                              -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilloc_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Location Change Details&#10;</xsl:text>
  <xsl:text>===============================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Device Type                     : </xsl:text>
    <xsl:value-of select="chghist:device_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Location                        : </xsl:text>
    <xsl:value-of select="chghist:location/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Location Type                   : </xsl:text>
    <xsl:value-of select="chghist:location_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Invocation ID           : </xsl:text>
    <xsl:value-of select="chghist:utility_invocation_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Type                    : </xsl:text>
    <xsl:value-of select="chghist:utility_type/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : utilstop_row                                               -->
<!-- Description: Print out info of utilstop_row                             -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilstop_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Stop Change Details&#10;</xsl:text>
  <xsl:text>===========================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlcabc                         : </xsl:text>
    <xsl:value-of select="chghist:sqlcabc/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlcaid                         : </xsl:text>
    <xsl:value-of select="chghist:sqlcaid/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlerrd1                        : </xsl:text>
    <xsl:value-of select="chghist:sqlerrd1/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlerrd2                        : </xsl:text>
    <xsl:value-of select="chghist:sqlerrd2/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlerrd3                        : </xsl:text>
    <xsl:value-of select="chghist:sqlerrd3/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlerrd4                        : </xsl:text>
    <xsl:value-of select="chghist:sqlerrd4/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlerrd5                        : </xsl:text>
    <xsl:value-of select="chghist:sqlerrd5/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlerrd6                        : </xsl:text>
    <xsl:value-of select="chghist:sqlerrd6/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlerrm                         : </xsl:text>
    <xsl:value-of select="chghist:sqlerrm/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlstate                        : </xsl:text>
    <xsl:value-of select="chghist:sqlstate/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Sqlwarn                         : </xsl:text>
    <xsl:value-of select="chghist:sqlwarn/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Start Event ID                  : </xsl:text>
    <xsl:value-of select="chghist:start_event_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Start Event Timestamp           : </xsl:text>
    <xsl:value-of select="chghist:start_event_timestamp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Invocation ID           : </xsl:text>
    <xsl:value-of select="chghist:utility_invovation_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Stop Type               : </xsl:text>
    <xsl:value-of select="chghist:utility_stop_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Type                    : </xsl:text>
    <xsl:value-of select="chghist:utility_type/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ======================================================================= -->
<!-- Template   : utilphase_row                                              -->
<!-- Description: Print out info of utilphase_row                            -->
<!-- ======================================================================= -->
<xsl:template match="chghist:utilphase_row">
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Phase Change Details&#10;</xsl:text>
  <xsl:text>============================&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Object Name                     : </xsl:text>
    <xsl:value-of select="chghist:object_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Object Schema                   : </xsl:text>
    <xsl:value-of select="chghist:object_schema/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Object Type                     : </xsl:text>
    <xsl:value-of select="chghist:object_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Phase Start Event ID            : </xsl:text>
    <xsl:value-of select="chghist:phase_start_event_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Phase Start Event Timestamp     : </xsl:text>
    <xsl:value-of select="chghist:phase_start_event_timestamp/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Invocation ID           : </xsl:text>
    <xsl:value-of select="chghist:utility_invocation_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Phase Detail            : </xsl:text>
    <xsl:value-of select="chghist:utility_phase_detail/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Phase Type              : </xsl:text>
    <xsl:value-of select="chghist:utility_phase_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Utility Type                    : </xsl:text>
    <xsl:value-of select="chghist:utility_type/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

</xsl:stylesheet>
