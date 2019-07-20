-----------------------------------------------------------------------------
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
-- SOURCE FILE NAME: getlogs.db2
--
-- SAMPLE: How to get the customer view of diagnostic log file entries
-- 
--         This sample shows:
--         1. How to retrieve messages from the notification log starting 
--	      at a specified point in time.
--         2. How to retrieve messages from the notification log written 
--	      over the last week or over the last 24 hours.
--
-- SQL STATEMENTS USED:
--        CONNECT
--	  SELECT 
--        TERMINATE  	 
--
-- OUTPUT FILE: getlogs.out (available in the online documentation)
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

-- Connect to sample database. 
CONNECT TO sample;

-- Retrieve all notification messages written after the specified 
-- timestamp (for example '2006-02-22', '06.44.44')
-- If NULL is specified as the input timestamp to PD_GET_LOG_MSGS UDF, 
-- then all the log entries will be returned.
SELECT dbname,
       msgseverity
  FROM TABLE (PD_GET_LOG_MSGS(TIMESTAMP('2006-02-22','06.44.44'))) AS t
  ORDER BY TIMESTAMP;

-- Retrieve all notification messages written in the last week from 
-- all partitions in chronological order.
SELECT instancename,
       dbpartitionnum,
       dbname,
       msgtype
  FROM TABLE(PD_GET_LOG_MSGS(current_timestamp - 7 days)) AS t 
  ORDER BY TIMESTAMP;

-- Get all critical log messages logged over the last 24 hours, order 
-- by most recent 
SELECT timestamp,
       instancename,
       dbname,
       appl_id,
       msg
  FROM SYSIBMADM.PDLOGMSGS_LAST24HOURS WHERE msgseverity = 'C' 
  ORDER BY TIMESTAMP DESC;

-- Disconnect from database.
CONNECT RESET;

TERMINATE;
