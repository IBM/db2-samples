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
                xmlns:lm="http://www.ibm.com/xmlns/prod/db2/mon"
                xmlns:fn="http://www.w3.org/2005/02/xpath-functions" >

<xsl:output method="text"  indent="no"/>

<!-- ========================================================================== -->
<!-- Template   : Main                                                          -->
<!-- Description: Main template to process the entire XML document              -->
<!-- ========================================================================== -->
<xsl:template match="/">
  <!-- ========================================================== -->
  <!-- Print out each lock event in details                       -->
  <!-- ========================================================== -->
  <xsl:for-each select="lm:db2_lock_event">
    <xsl:apply-templates select="." mode="details"/>
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : Lock event details                                            -->
<!-- Description: Template will process each db2LockEvent node contained in the -->
<!--              XML document and print out the event details.                 -->
<!-- ========================================================================== -->
<xsl:template match="lm:db2_lock_event" mode="details">

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
  <xsl:text>Partition of detection : </xsl:text>
    <xsl:value-of select="@member" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>-------------------------------------------------------&#10;</xsl:text>

  <!-- ========================================================== -->
  <!-- Print out the lock event report                            -->
  <!-- ========================================================== -->
  <xsl:choose>
    <xsl:when test="not(boolean(lm:db2_message))" >
      <xsl:if test="boolean(lm:db2_deadlock_graph)">
        <xsl:apply-templates select="lm:db2_deadlock_graph" />
      </xsl:if>
      <xsl:apply-templates select="."  mode="participants" />
    </xsl:when>
    <xsl:when test="boolean(lm:db2_message)" >
      <xsl:text>&#10;</xsl:text>
      <xsl:value-of select="lm:db2_message/text()" />
      <xsl:if test="boolean(lm:db2_event_file)">
        <xsl:text>&#10;</xsl:text>
        <xsl:text>Filename: </xsl:text>
        <xsl:value-of select="lm:db2_event_file/text()" />
      </xsl:if>
      <xsl:text>&#10;</xsl:text>
    </xsl:when>
  </xsl:choose>

</xsl:template>


<!-- ========================================================== -->
<!-- Template   : db2ObjectRequested                            -->
<!-- Description: Print out the details regarding the lock in   -->
<!--              contention                                    -->
<!-- ========================================================== -->
<xsl:template match="lm:db2_object_requested">
  <xsl:choose>
    <xsl:when test="@type = 'lock'">
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Participant No </xsl:text>
        <xsl:value-of select="../@no" />
      <xsl:text> requesting lock </xsl:text>
      <xsl:text>&#10;</xsl:text>
      <xsl:text>----------------------------------&#10;</xsl:text>
      <xsl:text>Lock Name            : 0x</xsl:text>
        <xsl:value-of select="lm:lock_name/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock wait start time : </xsl:text>
        <xsl:value-of select="concat(substring(lm:lock_wait_start_time, 1, 10),
                                     '-',
                                     substring(lm:lock_wait_start_time, 12, 2),
                                     '.',
                                     substring(lm:lock_wait_start_time, 15, 2),
                                     '.',
                                     substring(lm:lock_wait_start_time, 18, 9))" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock wait end time   : </xsl:text>
        <xsl:value-of select="concat(substring(lm:lock_wait_end_time, 1, 10),
                                     '-',
                                     substring(lm:lock_wait_end_time, 12, 2),
                                     '.',
                                     substring(lm:lock_wait_end_time, 15, 2),
                                     '.',
                                     substring(lm:lock_wait_end_time, 18, 9))" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock Type            : </xsl:text>
        <xsl:value-of select="lm:lock_object_type/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock Specifics       : </xsl:text>
        <xsl:value-of select="lm:lock_specifics/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock Attributes      : </xsl:text>
        <xsl:value-of select="lm:lock_attributes/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock mode requested  : </xsl:text>
        <xsl:value-of select="lm:lock_mode_requested/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock mode held       : </xsl:text>
        <xsl:value-of select="lm:lock_mode/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:if test="boolean(lm:current_lock_mode)">
         <xsl:text>Current Lock mode    : </xsl:text>
           <xsl:value-of select="lm:current_Lock_mode/text()" />
         <xsl:text>&#10;</xsl:text>
      </xsl:if>
      <xsl:text>Lock Count           : </xsl:text>
        <xsl:value-of select="lm:lock_count/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock Hold Count      : </xsl:text>
        <xsl:value-of select="lm:lock_hold_count/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock rrIID           : </xsl:text>
        <xsl:value-of select="lm:lock_rriid/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock Status          : </xsl:text>
        <xsl:value-of select="lm:lock_status/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Lock release flags   : </xsl:text>
        <xsl:value-of select="lm:lock_release_flags/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Tablespace TID       : </xsl:text>
        <xsl:value-of select="lm:tablespace_name/@id" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Tablespace Name      : </xsl:text>
        <xsl:value-of select="lm:tablespace_name/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Table FID            : </xsl:text>
        <xsl:value-of select="lm:table_name/@id" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Table Schema         : </xsl:text>
        <xsl:value-of select="lm:table_schema/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Table Name           : </xsl:text>
        <xsl:value-of select="lm:table_name/text()" />
      <xsl:text>&#10;</xsl:text>
    </xsl:when>
    <xsl:when test="@type = 'ticket'">
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Participant No </xsl:text>
        <xsl:value-of select="../@no" />
      <xsl:text> requesting threshold ticket </xsl:text>
      <xsl:text>&#10;</xsl:text>
      <xsl:text>---------------------------------------------&#10;</xsl:text>
      <xsl:text>Threshold Name       : </xsl:text>
        <xsl:value-of select="lm:threshold_name/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Threshold Id         : </xsl:text>
        <xsl:value-of select="lm:threshold_id/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Queued agents        : </xsl:text>
        <xsl:value-of select="lm:queued_agents/text()" />
      <xsl:text>&#10;</xsl:text>
      <xsl:text>Queue start time     : </xsl:text>
        <xsl:value-of select="concat(substring(lm:queue_start_time, 1, 10),
                                     '-',
                                     substring(lm:queue_start_time, 12, 2),
                                     '.',
                                     substring(lm:queue_start_time, 15, 2),
                                     '.',
                                     substring(lm:queue_start_time, 18, 9))" />
      <xsl:text>&#10;</xsl:text>
    </xsl:when>
 </xsl:choose>
</xsl:template>

<!-- ========================================================== -->
<!-- Template   : db2LockEvent                                  -->
<!-- Mode       : applinfo                                      -->
<!-- Description: Print out the application information         -->
<!-- ========================================================== -->
<xsl:template match="lm:db2_lock_event" mode="participants">

  <xsl:variable name="nodes" select="lm:db2_participant" />
  <xsl:variable name="count" select="count(lm:db2_participant)" />

  <!-- ========================================================== -->
  <!-- Print details of all Locks that are being requested       -->
  <!-- ========================================================== -->
  <xsl:for-each select="$nodes[position() &lt;= $count]">
     <xsl:variable name="pos" select="position()"/>
     <xsl:apply-templates select="$nodes[$pos]/lm:db2_object_requested" />
  </xsl:for-each>

  <!-- ========================================================== -->
  <!-- Print out a message indicating whether the lock holder     -->
  <!-- information is available or not.                           -->
  <!-- ========================================================== -->
  <xsl:text>&#10;</xsl:text>
  <xsl:if test="$count = 1 and @type != 'DEADLOCK'">
    <xsl:text>Unable to obtain Lock Holder information during the occurence of the lock event.&#10; </xsl:text>
  </xsl:if>


  <!-- ========================================================== -->
  <!-- Print all participants involved in the deadlock            -->
  <!-- ========================================================== -->
  <xsl:for-each select="$nodes[position() &lt;= $count]">
    <xsl:if test="position() mod 2">
      <xsl:choose>
      <xsl:when test="string($nodes[position()]/@type) = 'REQUESTER'">
        <xsl:text>&#10;</xsl:text>
        <xsl:variable name="pos1" select="position()"/>
        <xsl:variable name="pos2" select="position()+1"/>
  
      <!-- ========================================================== -->
      <!-- Print out the application details in a table format        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Attributes')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/@type)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/@type)" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('--------------------- ')" />
        <xsl:with-param name="reqvalue"  select="string('------------------------------ ')" />
        <xsl:with-param name="ownvalue"  select="string('------------------------------ ')" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Participant No                                       -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Participant No')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/@no" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/@no" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application Handle                                   -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application Handle')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:application_handle" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:application_handle" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application ID                                       -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:appl_id/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:appl_id/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application Name                                     -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application Name')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:appl_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:appl_name/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Authentication ID                                    -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Authentication ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:auth_id/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:auth_id/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Requesting Agent ID                                  -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Requesting AgentID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:agent_tid)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:agent_tid)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Coordinating Agent ID                                -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Coordinating AgentID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:coord_agent_tid)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:coord_agent_tid)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application Status                                   -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Agent Status')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:agent_status/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:agent_status/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Application action                                         -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application Action')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:appl_action/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:appl_action/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Locktimeout                                          -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Lock timeout value')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:lock_timeout_val/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:lock_timeout_val/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Lock wait value                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Lock wait value')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:lock_wait_val/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:lock_wait_val/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Workload ID                                          -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Workload ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:workload_id)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:workload_id)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Workload name                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Workload Name')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:workload_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:workload_name/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Service subclass ID                                  -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Service subclass ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:service_class_id)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:service_class_id)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Service superclass                                     -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Service superclass')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:service_superclass_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:service_superclass_name/text())" />
      </xsl:call-template>


      <!-- ========================================================== -->
      <!-- Print Service subclass                                     -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Service subclass')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:service_subclass_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:service_subclass_name/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Current Request                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Current Request')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:current_request" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:current_request" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print TEntry state                                         -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('TEntry state')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:tentry_state/@id" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:tentry_state/@id" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print TEntry flags1                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('TEntry flags1')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:tentry_flag1" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:tentry_flag1" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print TEntry flags2                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('TEntry flags2')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:tentry_flag2" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:tentry_flag2" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Lock escalation                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Lock escalation')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:lock_escalation/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:lock_escalation/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print client userid                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client userid')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_userid/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_userid/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print client wrkstnname                                    -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client wrkstnname')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_wrkstnname/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_wrkstnname/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Client applname                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client applname')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_applname/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_applname/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Client acctng                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client acctng')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_acctng/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_acctng/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Utility ID                                           -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Utility ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:utility_id)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:utility_id)" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:utility_id,
                                                  31,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:utility_id))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:utility_id,
                                                  31,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:utility_id))" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print XID                                                  -->
      <!-- ========================================================== -->
      <xsl:if test="string-length($nodes[$pos1]/lm:db2_app_details/lm:xid) &gt; 0">
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('XID')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:xid" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:xid" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:xid,
                                                  31,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:xid))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:xid,
                                                  31,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:xid))" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:xid,
                                                  62,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:xid))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:xid,
                                                  62,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:xid))" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:xid,
                                                  93,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:xid))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:xid,
                                                  93,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:xid))" />
      </xsl:call-template>
      </xsl:if>
    
      </xsl:when>
    
      <xsl:otherwise>
        <xsl:text>&#10;</xsl:text>
        <xsl:variable name="pos1" select="position()"/>
        <xsl:variable name="pos2" select="position()+1"/>

      <!-- ========================================================== -->
      <!-- Print out the application details in a table format        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Attributes')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/@type)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/@type)" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('--------------------- ')" />
        <xsl:with-param name="reqvalue"  select="string('------------------------------ ')" />
        <xsl:with-param name="ownvalue"  select="string('------------------------------ ')" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Participant No                                       -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Participant No')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/@no" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/@no" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application Handle                                   -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application Handle')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:application_handle" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:application_handle" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application ID                                       -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:appl_id/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:appl_id/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application Name                                     -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application Name')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:appl_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:appl_name/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Authentication ID                                    -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Authentication ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:auth_id/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:auth_id/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Requesting Agent ID                                  -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Requesting AgentID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:agent_tid)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:agent_tid)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Coordinating Agent ID                                -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Coordinating AgentID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:coord_agent_tid)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:coord_agent_tid)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Application Status                                   -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Agent Status')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:agent_status/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:agent_status/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Application action                                         -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Application Action')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:appl_action/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:appl_action/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Locktimeout                                          -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Lock timeout value')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:lock_timeout_val/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:lock_timeout_val/text())" />
      </xsl:call-template>


      <!-- ========================================================== -->
      <!-- Print Lock wait value                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Lock wait value')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:lock_wait_val/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:lock_wait_val/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Tenant ID                                            -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Tenant ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:tenant_id/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:tenant_id/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Tenant name                                          -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Tenant Name')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:tenant_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:tenant_name/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Workload ID                                          -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Workload ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:workload_id)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:workload_id)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Workload name                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Workload Name')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:workload_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:workload_name/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Service subclass ID                                  -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Service subclass ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:service_class_id)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:service_class_id)" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Service superclass                                     -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Service superclass')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:service_superclass_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:service_superclass_name/text())" />
      </xsl:call-template>
      <!-- ========================================================== -->
      <!-- Print Service subclass                                     -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Service subclass')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:service_subclass_name/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:service_subclass_name/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Current Request                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Current Request')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:current_request" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:current_request" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print TEntry state                                         -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('TEntry state')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:tentry_state/@id" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:tentry_state/@id" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print TEntry flags1                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('TEntry flags1')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:tentry_flag1" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:tentry_flag1" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print TEntry flags2                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('TEntry flags2')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:tentry_flag2" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:tentry_flag2" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Lock escalation                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Lock escalation')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:lock_escalation/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:lock_escalation/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print client userid                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client userid')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_userid/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_userid/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print client wrkstnname                                    -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client wrkstnname')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_wrkstnname/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_wrkstnname/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Client applname                                      -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client applname')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_applname/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_applname/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Client acctng                                        -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Client acctng')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:client_acctng/text())" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:client_acctng/text())" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print Utility ID                                           -->
      <!-- ========================================================== -->
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('Utility ID')" />
        <xsl:with-param name="reqvalue"  select="string($nodes[$pos1]/lm:db2_app_details/lm:utility_id)" />
        <xsl:with-param name="ownvalue"  select="string($nodes[$pos2]/lm:db2_app_details/lm:utility_id)" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:utility_id,
                                                  31,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:utility_id))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:utility_id,
                                                  31,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:utility_id))" />
      </xsl:call-template>

      <!-- ========================================================== -->
      <!-- Print XID                                                  -->
      <!-- ========================================================== -->
      <xsl:if test="string-length($nodes[$pos1]/lm:db2_app_details/lm:xid) &gt; 0">
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string('XID')" />
        <xsl:with-param name="reqvalue"  select="$nodes[$pos1]/lm:db2_app_details/lm:xid" />
        <xsl:with-param name="ownvalue"  select="$nodes[$pos2]/lm:db2_app_details/lm:xid" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:xid,
                                                  31,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:xid))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:xid,
                                                  31,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:xid))" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:xid,
                                                  62,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:xid))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:xid,
                                                  62,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:xid))" />
      </xsl:call-template>
      <xsl:call-template name="print_row">
        <xsl:with-param name="attribute" select="string(' ')" />
        <xsl:with-param name="reqvalue"  select="substring($nodes[$pos1]/lm:db2_app_details/lm:xid,
                                                  93,
                                                  string-length($nodes[$pos1]/lm:db2_app_details/lm:xid))" />
        <xsl:with-param name="ownvalue"  select="substring($nodes[$pos2]/lm:db2_app_details/lm:xid,
                                                  93,
                                                  string-length($nodes[$pos2]/lm:db2_app_details/lm:xid))" />
      </xsl:call-template>
      </xsl:if>

    </xsl:otherwise>
    </xsl:choose>
    </xsl:if>
  </xsl:for-each>


  <!-- ========================================================== -->
  <!-- List all activities past and current for requestor and     -->
  <!-- holder                                                     -->
  <!-- ========================================================== -->
  <xsl:for-each select="$nodes[position() &lt;= $count]">

    <xsl:variable name="pos" select="position()"/>
    <xsl:variable name="curracts" select="$nodes[$pos]/lm:db2_activity[@type='current']" />
    <xsl:variable name="pastacts" select="$nodes[$pos]/lm:db2_activity[@type='past']" />

    <xsl:text>&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>Current Activities of Participant No </xsl:text>
       <xsl:value-of select="$nodes[$pos]/@no"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>----------------------------------------&#10;</xsl:text>
    <xsl:choose>
       <xsl:when test="count($curracts)">
          <xsl:for-each select="$curracts">
             <xsl:apply-templates select="." />
             <xsl:text>&#10;</xsl:text>
          </xsl:for-each>
       </xsl:when>
       <xsl:otherwise>
          <xsl:text>Activities not available</xsl:text>
          <xsl:text>&#10;</xsl:text>
       </xsl:otherwise>
    </xsl:choose>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>Past Activities of Participant No </xsl:text>
       <xsl:value-of select="$nodes[$pos]/@no"/>
    <xsl:text>&#10;</xsl:text>
    <xsl:text>-------------------------------------&#10;</xsl:text>
    <xsl:choose>
       <xsl:when test="count($pastacts)">
          <xsl:value-of select="concat('Past Activities wrapped: ',
                                $nodes[$pos]/lm:db2_app_details/lm:past_activities_wrapped)" />
          <xsl:text>&#10;</xsl:text>
          <xsl:text>&#10;</xsl:text>
          <xsl:for-each select="$pastacts">
             <xsl:apply-templates select="." />
             <xsl:text>&#10;</xsl:text>
          </xsl:for-each>
       </xsl:when>
       <xsl:otherwise>
          <xsl:text>Activities not available</xsl:text>
          <xsl:text>&#10;</xsl:text>
       </xsl:otherwise>
    </xsl:choose>
  </xsl:for-each>
</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : Print row                                                     -->
<!-- Description: Template will print a single row of application details       -->
<!-- ========================================================================== -->
<xsl:template name="print_row">
  <xsl:param name="attribute"/>
  <xsl:param name="reqvalue"/>
  <xsl:param name="ownvalue"/>

  <xsl:variable name="spaces" select="'                                    '" />

  <xsl:choose>
    <xsl:when test="string-length($attribute) &lt; 23">
      <xsl:value-of select="concat(
                              $attribute,
                               substring($spaces,
                                         0,
                                         23 - string-length($attribute)))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="substring($attribute, 0, 23)" />
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="string-length($reqvalue) &lt; 34">
      <xsl:value-of select="concat(
                              $reqvalue,
                               substring($spaces,
                                         0,
                                         34 - string-length($reqvalue)))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="substring($reqvalue, 1, 31)" />
    </xsl:otherwise>
  </xsl:choose>
  <xsl:choose>
    <xsl:when test="string-length($ownvalue) &lt; 33">
      <xsl:value-of select="concat(
                              $ownvalue,
                               substring($spaces,
                                         0,
                                         33 - string-length($ownvalue)))"/>
    </xsl:when>
    <xsl:otherwise>
      <xsl:value-of select="substring($ownvalue, 1, 31)" />
    </xsl:otherwise>
  </xsl:choose>

  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : Activity Details                                              -->
<!-- Description: Template will print in details each activity node contained   -->
<!--              in the XML document.                                          -->
<!-- ========================================================================== -->
<xsl:template match="lm:db2_activity">

  <xsl:text>Activity ID        : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:activity_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Uow ID             : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:uow_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Name       : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:package_name/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Schema     : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:package_schema/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Version    : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:package_version_id/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Token      : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:consistency_token" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Package Sectno     : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:section_number" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Reopt value        : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:reopt/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Incremental Bind   : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:incremental_bind/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Eff isolation      : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:effective_isolation/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Eff degree         : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:effective_query_degree/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Actual degree      : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:query_actual_degree/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Eff locktimeout    : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_lock_timeout/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt first use     : </xsl:text>
  <xsl:choose>
    <xsl:when test="string-length(lm:db2_activity_details/lm:stmt_first_use_time) &gt; 0">
    <xsl:value-of select="concat(substring(lm:db2_activity_details/lm:stmt_first_use_time, 1, 10),
                                 '-',
                                 substring(lm:db2_activity_details/lm:stmt_first_use_time, 12, 2),
                                 '.',
                                 substring(lm:db2_activity_details/lm:stmt_first_use_time, 15, 2),
                                 '.',
                                 substring(lm:db2_activity_details/lm:stmt_first_use_time, 18, 9))" />
    </xsl:when>
    <xsl:otherwise>
       <xsl:text>                      </xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt last use      : </xsl:text>
  <xsl:choose>
    <xsl:when test="string-length(lm:db2_activity_details/lm:stmt_last_use_time) &gt; 0">
    <xsl:value-of select="concat(substring(lm:db2_activity_details/lm:stmt_last_use_time, 1, 10),
                                 '-',
                                 substring(lm:db2_activity_details/lm:stmt_last_use_time, 12, 2),
                                 '.',
                                 substring(lm:db2_activity_details/lm:stmt_last_use_time, 15, 2),
                                 '.',
                                 substring(lm:db2_activity_details/lm:stmt_last_use_time, 18, 9))" />
    </xsl:when>
    <xsl:otherwise>
       <xsl:text>                      </xsl:text>
    </xsl:otherwise>
  </xsl:choose>
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt unicode       : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_unicode" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt query ID      : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_query_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt nesting level : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_nest_level" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt invocation ID : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_invocation_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt source ID     : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_source_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt pkgcache ID   : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_pkgcache_id" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt type          : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_type" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt operation     : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_operation/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt no            : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmtno/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Stmt text          : </xsl:text>
    <xsl:value-of select="lm:db2_activity_details/lm:stmt_text/text()" />
  <xsl:text>&#10;</xsl:text>

  <xsl:for-each select="lm:db2_input_variable">
    <xsl:apply-templates select="." />
  </xsl:for-each>


</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : Input variables                                               -->
<!-- Description: Template will print in details each input variable contained  -->
<!--              in the XML document for a statement.                          -->
<!-- ========================================================================== -->
<xsl:template match="lm:db2_input_variable">

  <xsl:variable name="spaces" select="'                                '" />

  <xsl:variable name="hdr" select="concat('Input variable ',
                                           lm:stmt_value_index)" />
  <xsl:value-of select="concat( $hdr,
                                substring($spaces,
                                          0, 21 - string-length($hdr)))" />

  <xsl:text>&#10;</xsl:text>
  <xsl:text> Type              : </xsl:text>
    <xsl:value-of select="lm:stmt_value_type/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text> Data              : </xsl:text>
    <xsl:value-of select="lm:stmt_value_data/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text> Reopt             : </xsl:text>
    <xsl:value-of select="lm:stmt_value_isreopt/text()" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text> Null              : </xsl:text>
    <xsl:value-of select="lm:stmt_value_isnull/text()" />
  <xsl:text>&#10;</xsl:text>
</xsl:template>

<!-- ========================================================================== -->
<!-- Template   : db2DeadlockGraph                                              -->
<!-- Description: Template will print in details the deadlock graph             -->
<!-- ========================================================================== -->
<xsl:template match="lm:db2_deadlock_graph">

  <xsl:text>&#10;</xsl:text>
  <xsl:text>Deadlock Graph&#10;</xsl:text>
  <xsl:text>--------------&#10;</xsl:text>
  <xsl:text>Total number of deadlock participants : </xsl:text>
    <xsl:value-of select="@dl_conns" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Participant that was rolled back      : </xsl:text>
    <xsl:value-of select="@rolled_back_participant_no" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>Type of deadlock                      : </xsl:text>
    <xsl:value-of select="@type" />
  <xsl:text>&#10;</xsl:text>
  <xsl:text>&#10;</xsl:text>

  <xsl:value-of select="string('Participant     ')" />
  <xsl:value-of select="string('Participant     ')" />
  <xsl:value-of select="string('Deadlock Member ')" />
  <xsl:value-of select="string('Application Handle ')" />
  <xsl:text>&#10;</xsl:text>
  <xsl:value-of select="string('Requesting Lock ')" />
  <xsl:value-of select="string('Holding Lock    ')" />
  <xsl:value-of select="string('                              ')" />
  <xsl:text>&#10;</xsl:text>
  <xsl:value-of select="string('--------------- ')" />
  <xsl:value-of select="string('--------------- ')" />
  <xsl:value-of select="string('--------------- ')" />
  <xsl:value-of select="string('------------------ ')" />
  <xsl:text>&#10;</xsl:text>

  <xsl:for-each select="lm:db2_participant">
     <xsl:variable name="spaces" select="'                                '" />
     <xsl:variable name="id"  select="@no" />
     <xsl:variable name="id2" select="@participant_no_holding_lk" />
     <xsl:variable name="part"     select="@deadlock_member" />
     <xsl:variable name="hdl"      select="@application_handle" />
     <xsl:value-of select="concat( substring($id, 0, 17),
                                   substring($spaces,
                                             0, 17 - string-length($id)),
                                   substring($id2, 0, 17),
                                   substring($spaces,
                                             0, 17 - string-length($id2)),
                                   substring($part, 0, 17),
                                   substring($spaces,
                                             0, 17 - string-length($part)),
                                   substring($hdl, 0, 17),
                                   substring($spaces,
                                             0, 17 - string-length($hdl)))" />
     <xsl:text>&#10;</xsl:text>
  </xsl:for-each>
  <xsl:text>&#10;</xsl:text>
</xsl:template>


</xsl:stylesheet>
