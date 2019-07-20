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
                xmlns:lm="http://www.ibm.com/xmlns/prod/db2/mon">

<xsl:output method="html" version="1.0" encoding="UTF-8" indent="yes"/>

<xsl:template match="/">
  <html>
     <head>
       <style type="text/css"> .indent  { padding-left: 30pt; padding-right: 0pt; } </style>
       <style type="text/css"> .font14  { font-size: 14pt } </style>
       <style type="text/css"> .numbers { list-style-type: arabic numbers } </style>

       <title>DB2 Lock Event Report </title>
     </head>

     <body>
       <!-- ******************************************************************* -->
       <!-- Create the Report Header                                            -->
       <!-- ******************************************************************* -->

       <h1><center>DB2 Lock Event Report</center></h1>

       <p class="font14">
       This generated report consists of a summary of lock events captured
       followed by the details of each event. To find details for a specific
       event,search this file using entry=# where '#' is the value in the entry
       column for the specific event.
       </p>

       <table border="0" cellpadding="3">
         <tr>
            <td align="left" valign="top"><b>Database Name: </b></td>
            <td align="left" valign="top"><xsl:value-of select="lm:db2LockReport/lm:dbname"/> </td>
         </tr>
         <tr>
            <td align="left" valign="top"><b>Instance Name: </b></td>
            <td align="left" valign="top"><xsl:value-of select="lm:db2LockReport/lm:instname"/> </td>
         </tr>
         <tr>
            <td align="left" valign="top"><b>Event Monitor: </b></td>
            <td align="left" valign="top"><xsl:value-of select="lm:db2LockReport/lm:evmonname"/> </td>
         </tr>
         <tr>
            <td align="left" valign="top"><b>Raw table: </b></td>
            <td align="left" valign="top"><xsl:value-of select="lm:db2LockReport/lm:rawtable"/> </td>
         </tr>
       </table>
       <br/>

       <!-- ******************************************************************* -->
       <!-- Create the Report Summary                                           -->
       <!-- ******************************************************************* -->

       <table border="0" rules="rows" cellpadding="4">
         <tr bgcolor="Silver">
           <th align="left" valign="top">Entry '#'</th>
           <th align="left" valign="top">Timestamp</th>
           <th align="left" valign="top">Type</th>
           <th align="left" valign="top">LockType</th>
           <th align="left" valign="top">Participants</th>
           <th align="left" valign="top">ReqMode</th>
           <th align="left" valign="top">HeldMode</th>
           <th align="left" valign="top">Requestor</th>
           <th align="left" valign="top">Holder</th>
         </tr>
         <xsl:for-each select="lm:db2LockReport/lm:db2LockEvent">
         <tr>
           <xsl:variable name="link"><xsl:value-of select="position()"/></xsl:variable>
           <td align="center" valign="top">
             <a href="#{$link}">
               <xsl:value-of select="position()"/>
             </a>
           </td>
           <td align="left" valign="top">  <xsl:value-of select="@timestamp"/></td>
           <td align="center" valign="top"><xsl:value-of select="lm:db2Lock/lm:type/@id"/></td>
           <td align="left" valign="top">  <xsl:value-of select="@type"/></td>
           <td align="left" valign="top">  2</td>
           <td align="left" valign="top">  <xsl:value-of select="lm:db2LockRequestor/lm:lockModeReq/@id"/></td>
           <td align="left" valign="top">  <xsl:value-of select="lm:db2LockOwner/lm:lockModeHeld/@id"/></td>
           <td align="left" valign="top">  <xsl:value-of select="lm:db2LockRequestor/lm:applName/."/></td>
           <td align="left" valign="top">  <xsl:value-of select="lm:db2LockOwner/lm:applName/."/></td>
         </tr>
         </xsl:for-each>
       </table>

       <br/>
       <xsl:for-each select="lm:db2LockReport/lm:db2LockEvent">
       <xsl:variable name="ref"><xsl:value-of select="position()"/></xsl:variable>

       <!-- ******************************************************************* -->
       <!-- Entry Header                                                        -->
       <!-- ******************************************************************* -->
       <hr/>
       <h2>
         <a name="{$ref}"> Entry #: <xsl:value-of select="position()"/> </a>
       </h2>
       <table border ="0" cellpadding="0">
         <tr>
           <td align = "left"><b>Event ID:</b></td>
           <td align = "left"><xsl:value-of select="@id"/></td>
         </tr>
         <tr>
           <td align = "left"><b>Event Timestamp:</b></td>
           <td align = "left"><xsl:value-of select="@timestamp"/></td>
         </tr>
         <tr>
           <td align = "left"><b>Event Type:</b></td>
           <td align = "left"><xsl:value-of select="@type"/></td>
         </tr>
       </table>

       <!-- ******************************************************************* -->
       <!-- Lock Details                                                        -->
       <!-- ******************************************************************* -->
       <h4><u>Lock Details</u></h4>

       <table border = "0" >
         <tr>
           <td align = "left"><b>Lock Name: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/@name"/></td>
         </tr>
         <tr>
           <td align = "left"><b>Lock Type: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:type/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Lock Specifics: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:specifics/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Lock Attributes: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:attributes/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Lock Count: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:count/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Lock Hold Count: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:holdCount/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Lock rrIID: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:rrIID/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Lock Status: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:status/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Cursor Bitamp: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:cursorBitmap/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Tablespace FID: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:tablespace/@id"/></td>
         </tr>
         <tr>
           <td align = "left"><b>Tablespace Name: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:tablespace/."/></td>
         </tr>
         <tr>
           <td align = "left"><b>Table TID: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:table/@id"/></td>
         </tr>
         <tr>
           <td align = "left"><b>Table Name: </b></td>
           <td align = "left"><xsl:value-of select="lm:db2Lock/lm:table/."/></td>
         </tr>
       </table>

       <br/>

       <xsl:if test="not(boolean(lm:db2LockOwner))">
       Unable to obtain Lock Holder information during the occurence of the lock event.
       <br/>
       <br/>
       </xsl:if>

       <!-- ******************************************************************* -->
       <!-- Lock Requestor/Owner Details                                        -->
       <!-- ******************************************************************* -->
       <table border ="0" rules = "all" cellpadding="5" cellspacing="0">
         <tr >
            <th align="left"></th>
            <th align="left">Requestor</th>
            <th align="left">Holder</th>
         </tr>
         <tr>
            <td align="left"><b>Application Handle:</b></td>
            <td align="left">[<xsl:value-of select="lm:db2LockRequestor/lm:appHandle/@coordNode"/>
                             -<xsl:value-of select="lm:db2LockRequestor/lm:appHandle/@coordAgentIndex"/>
                             ]</td>
            <td align="left">[<xsl:value-of select="lm:db2LockOwner/lm:appHandle/@coordNode"/>
                             -<xsl:value-of select="lm:db2LockOwner/lm:appHandle/@coordAgentIndex"/>
                             ]</td>
         </tr>
         <tr>
            <td align="left"><b>Application ID:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:applID/."/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:applID/."/></td>
         </tr>
         <tr>
            <td align="left"><b>Application Name:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:applName/."/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:applName/."/></td>
         </tr>
         <tr>
            <td align="left"><b>Authentication ID:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:authID/."/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:authID/."/></td>
         </tr>
         <tr>
            <td align="left"><b>Requesting Agent ID:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:reqAgentID/@id"/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:reqAgentID/@id"/></td>
         </tr>
         <tr>
            <td align="left"><b>Coordinating Agent ID:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:coordAgentID/@id"/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:coordAgentID/@id"/></td>
         </tr>
         <tr>
            <td align="left"><b>Application Status:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:applStatus/."/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:applStatus/."/></td>
         </tr>
         <tr>
            <td align="left"><b>Lock timeout:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:timeoutVal/."/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:timeoutVal/."/></td>
         </tr>
         <tr>
            <td align="left"><b>Workload ID:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:workload/@id"/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:workload/@id"/></td>
         </tr>
         <tr>
            <td align="left"><b>Workload Name:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:workload/."/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:workload/."/></td>
         </tr>
         <tr>
            <td align="left"><b>Service subclass ID:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:serviceClass/@id"/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:serviceClass/@id"/></td>
         </tr>
         <tr>
            <td align="left"><b>Service subclass:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:serviceClass/."/></td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:serviceClass/."/></td>
         </tr>
         <tr>
            <td align="left"><b>Current Request:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:currRequest/."/>
                             (<xsl:value-of select="lm:db2LockRequestor/lm:currRequest/@id"/>)
            </td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:currRequest/."/>
                             (<xsl:value-of select="lm:db2LockOwner/lm:currRequest/@id"/>)
            </td>
         </tr>
         <tr>
            <td align="left"><b>Lock Mode:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:lockModeReq/."/>
                             (<xsl:value-of select="lm:db2LockRequestor/lm:lockModeReq/@id"/>)
            </td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:lockModeHeld/."/>
                             (<xsl:value-of select="lm:db2LockOwner/lm:lockModeHeld/@id"/>)
            </td>
         </tr>
         <tr>
            <td align="left"><b>Lock Mode:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:lockEscalation/."/>
            </td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:lockEscalation/."/>
            </td>
         </tr>
         <tr>
            <td align="left"><b>Tpmon userid:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:tpmon/lm:userid/."/>
            </td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:tpmon/lm:userid/."/>
            </td>
         </tr>
         <tr>
            <td align="left"><b>Tpmon workstation:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:tpmon/lm:wkstn/."/>
            </td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:tpmon/lm:wkstn/."/>
            </td>
         </tr>
         <tr>
            <td align="left"><b>Tpmon application:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:tpmon/lm:app/."/>
            </td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:tpmon/lm:app/."/>
            </td>
         </tr>
         <tr>
            <td align="left"><b>Tpmon account string:</b></td>
            <td align="left"><xsl:value-of select="lm:db2LockRequestor/lm:tpmon/lm:accString/."/>
            </td>
            <td align="left"><xsl:value-of select="lm:db2LockOwner/lm:tpmon/lm:accString/."/>
            </td>
         </tr>
       </table>

       <!-- ******************************************************************* -->
       <!-- Current Activities Requestor                                        -->
       <!-- ******************************************************************* -->
       <h4><u>Lock Requestor Current Activities</u></h4>

       <xsl:choose>
         <xsl:when test="boolean(lm:db2LockRequestor/lm:db2CurrActivities/lm:db2Activity)">
           <xsl:for-each select="lm:db2LockRequestor/lm:db2CurrActivities">
             <xsl:apply-templates select="lm:db2Activity"/>
           </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
         Current Activities not available.
         </xsl:otherwise>
      </xsl:choose>

       <h4><u>Lock Requestor Past Activities</u></h4>
       <xsl:choose>
         <xsl:when test="boolean(lm:db2LockRequestor/lm:db2PastActivities/lm:db2Activity)">
           <b>Past Activities wrapped: </b>
           <xsl:value-of select="lm:db2LockRequestor/lm:db2PastActivities/@wrapped"/>
           <br/>
           <br/>
           <xsl:for-each select="lm:db2LockRequestor/lm:db2PastActivities">
             <xsl:apply-templates select="lm:db2Activity"/>
           </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
         Past Activities not available.
         </xsl:otherwise>
      </xsl:choose>

       <h4><u>Lock Owner Current Activities</u></h4>
       <xsl:choose>
         <xsl:when test="boolean(lm:db2LockOwner/lm:db2CurrActivities/lm:db2Activity)">
           <xsl:for-each select="lm:db2LockOwner/lm:db2CurrActivities">
             <xsl:apply-templates select="lm:db2Activity"/>
           </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
         Current Activities not available.
         </xsl:otherwise>
      </xsl:choose>

       <h4><u>Lock Owner Past Activities</u></h4>
       <xsl:choose>
         <xsl:when test="boolean(lm:db2LockOwner/lm:db2PastActivities/lm:db2Activity)">
           <b>Past Activities wrapped:  </b>
           <xsl:value-of select="lm:db2LockOwner/lm:db2PastActivities/@wrapped"/>
           <br/>
           <br/>
           <xsl:for-each select="lm:db2LockOwner/lm:db2PastActivities">
             <xsl:apply-templates select="lm:db2Activity"/>
           </xsl:for-each>
         </xsl:when>
         <xsl:otherwise>
         Past Activities not available.
         </xsl:otherwise>
      </xsl:choose>
      </xsl:for-each>

     </body>
  </html>
</xsl:template>

<xsl:template match="lm:db2Activity">
  <table border="0">
   <tr>
    <tr>
       <td align="left"><b>Activity ID:</b></td>
       <td align="left"><xsl:value-of select="@id"/></td>
    </tr>
    <tr>
       <td align="left"><b>Uow ID:</b></td>
       <td align="left"><xsl:value-of select="lm:uowID/@id"/></td>
    </tr>
    <tr>
       <td align="left"><b>Package Name:</b></td>
       <td align="left"><xsl:value-of select="lm:package/lm:name/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Package Schema:</b></td>
       <td align="left"><xsl:value-of select="lm:package/lm:schema/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Package Version:</b></td>
       <td align="left"><xsl:value-of select="lm:package/lm:version/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Package Token:</b></td>
       <td align="left"><xsl:value-of select="lm:package/@token"/></td>
    </tr>
    <tr>
       <td align="left"><b>Package SectNo:</b></td>
       <td align="left"><xsl:value-of select="lm:package/@sectionNo"/></td>
    </tr>
    <tr>
       <td align="left"><b>Reopt value:</b></td>
       <td align="left"><xsl:value-of select="lm:package/lm:reopt/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Incremental bind: </b></td>
       <td align="left"><xsl:value-of select="lm:package/lm:incrementalBind/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Eff locktimeout</b></td>
       <td align="left"><xsl:value-of select="lm:effLockTimeout/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Eff isolation</b></td>
       <td align="left"><xsl:value-of select="lm:effIsolation/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Eff degree</b></td>
       <td align="left"><xsl:value-of select="lm:effDegree/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Stmt unicode</b></td>
       <td align="left"><xsl:value-of select="lm:statement/@unicode"/></td>
    </tr>
    <tr>
       <td align="left"><b>Stmt type</b></td>
       <td align="left"><xsl:value-of select="lm:statement/@type"/></td>
    </tr>
    <tr>
       <td align="left"><b>Stmt operation</b></td>
       <td align="left"><xsl:value-of select="lm:statement/lm:stmtType/."/></td>
    </tr>
    <tr>
       <td align="left"><b>Stmt text</b></td>
       <td align="left"><xsl:value-of select="lm:statement/lm:text/."/></td>
    </tr>
    <xsl:if test="boolean(lm:statement/lm:inputvars)">
       <xsl:apply-templates select="lm:statement/lm:inputvars"/>
    </xsl:if>
    <xsl:if test="boolean(lm:statement/lm:reoptvars)">
       <xsl:apply-templates select="lm:statement/lm:reoptvars"/>
    </xsl:if>
   </tr>
  </table>
  <br/>
</xsl:template>

<xsl:template match="lm:inputvars">
  <xsl:for-each select="lm:inputvar">
    <tr>
      <td align="left"><b>Inputvar <xsl:value-of select="@num"/>:</b></td>
      <td align="left">Type(<xsl:value-of select="@type"/>)
        <xsl:if test="boolean(text())">
          Value(<xsl:value-of select="text()"/>)
        </xsl:if>
      </td>
    </tr>
  </xsl:for-each>
</xsl:template>

<xsl:template match="lm:reoptvars">
  <xsl:for-each select="lm:reoptvar">
    <tr>
      <td align="left"><b>Reoptvar <xsl:value-of select="@num"/>:</b></td>
      <td align="left">Type(<xsl:value-of select="@type"/>)
        <xsl:if test="boolean(text())">
          Value(<xsl:value-of select="text()"/>)
        </xsl:if>
      </td>
    </tr>
  </xsl:for-each>
</xsl:template>

</xsl:stylesheet>
