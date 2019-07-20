----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2007 All rights reserved.
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
-----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: monitor.db2
--
-- SAMPLE: The sample will demonstrate the usage of the table functions 
--         MON_GET_CONNECTION, MON_GET_UTILITY and the views 
--         SYSIBMADM.SNAPUTIL_PROGRESS and SYSIBMADM.MON_TBSP_UTILIZATION in 
--         retrieving the monitor and snapshot data associated with the corresponding 
--         snapshot groupings and elements as follows.
--           
--         1.   Retrieve the connection statistics about the top CPU consuming
--              applications for the currently connected database on the
--              currently connected member using the table functions 
--              MON_GET_CONNECTION().
--
--         2.   Retrieve the statistics about the  progress of all
--              the active utilities on all members using the table function  
--              MON_GET_UTILITY and the view SYSIBMADM.SNAPUTIL_PROGRESS.
--
--         3.   Retrieve the statistics about the total amount of 
--              space used by all tablespaces in the currently connected 
--              database using the view SYSIBMADM.MON_TBSP_UTILIZATION.
--
-- SQL STATEMENTS USED:
--         CONNECT
--         SELECT
--         TERMINATE
--
-- OUTPUT FILE: monitor.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- Connect to SAMPLE
CONNECT TO sample;

-- List the top CPU consuming applications for the currently connected 
-- database on the currently connected member
SELECT s1.APPLICATION_NAME, 
       s1.APPLICATION_ID,
       s1.APPLICATION_HANDLE,
       s1.SYSTEM_AUTH_ID,
       s1.TOTAL_CPU_TIME
   FROM TABLE( MON_GET_CONNECTION( NULL, -1 )) as s1
   ORDER BY s1.TOTAL_CPU_TIME DESC, s1.APPLICATION_NAME;

-- Retrieving the statistics about the progress 
-- of all active utilities per member.
SELECT u1.OBJECT_NAME,
       u1.OBJECT_TYPE,
       u1.OBJECT_SCHEMA,
       u1.MEMBER,
       u1.UTILITY_INVOCATION_ID,
       u1.UTILITY_ID,
       u1.UTILITY_PRIORITY,
       u1.UTILITY_DETAIL,
       u2.UTILITY_STATE,
       u2.PROGRESS_WORK_METRIC,
       u2.PROGRESS_COMPLETED_UNITS,
       u2.PROGRESS_TOTAL_UNITS,
       DEC( ( FLOAT( u2.PROGRESS_COMPLETED_UNITS ) / FLOAT( u2.PROGRESS_TOTAL_UNITS ) ) * 100, 4, 2 ) 
         AS PERCENT_SEQ_COMPLETE
  FROM TABLE(MON_GET_UTILITY(-2)) as u1, SYSIBMADM.SNAPUTIL_PROGRESS as u2
  WHERE u1.UTILITY_ID = u2.UTILITY_ID and u1.MEMBER = u2.DBPARTITIONNUM
  ORDER BY u1.OBJECT_NAME, u1.MEMBER, u2.PROGRESS_SEQ_NUM;

-- Retrieving the statistics about total amount of space
-- used by all tablespaces per member in the currently connected member.
SELECT SUM( TBSP_TOTAL_SIZE_KB ) AS DBPART_TBSP_TOTAL_SIZE, 
       MEMBER  FROM SYSIBMADM.MON_TBSP_UTILIZATION 
   GROUP BY MEMBER  ORDER BY DBPART_TBSP_TOTAL_SIZE DESC;

-- Connect reset
CONNECT RESET;
