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
-- SOURCE FILE NAME: tbeventmon.db2
--    
-- SAMPLE: How to create and use event monitors written to a table.
--
-- SQL STATEMENTS USED:
--         CREATE EVENT MONITOR
--         SET EVENT MONITOR
--         CONNECT
--         DROP TABLE
--
-- OUTPUT FILE: tbeventmon.out (available in the online documentation)
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

-- To create event monitors for event types statements , deadlocks and 
-- connections which are written to a table

CREATE EVENT MONITOR dlmon
           FOR STATEMENTS, DEADLOCKS WITH DETAILS, CONNECTIONS
           WRITE TO TABLE
                 CONNHEADER (TABLE CONNHEADER_dlmon,
                               INCLUDES (AGENT_ID,
                                         APPL_ID,
                                         APPL_NAME,
                                         TERRITORY_CODE )),
                 DEADLOCK (TABLE DEADLOCK_dlmon),
                 DLCONN (TABLE mydept.dlconnections,
                               EXCLUDES (
                                         LOCK_OBJECT_NAME,
                                         LOCK_OBJECT_TYPE,
                                         TABLESPACE_NAME )),
                 STMT (TABLE STMT_dlmon,
                               INCLUDES (AGENT_ID,
                                         APPL_ID,
                                         CREATOR,
                                         INT_ROWS_DELETED,
                                         INT_ROWS_INSERTED,
                                         INT_ROWS_UPDATED,
                                         ROWS_READ,
                                         ROWS_WRITTEN,
                                         SQLCODE,
                                         SQLSTATE,
                                         SQLWARN,
                                         START_TIME,
                                         STMT_OPERATION,
                                         STMT_TEXT )),
                 CONN ,
                 CONTROL (TABLE CONTROL_dlmon,
                               INCLUDES (EVENT_MONITOR_NAME,
                                         MESSAGE,
                                         MESSAGE_TIME ))
                 BUFFERSIZE 8 NONBLOCKED MANUALSTART;

-- Activate event monitor 
SET EVENT MONITOR dlmon STATE=1;

-- The following SQL statements generate sample events that populate
-- COLL_dlmon table
CONNECT RESET;
CONNECT TO SAMPLE;

-- Reactivate event monitor 
SET EVENT MONITOR dlmon STATE = 1;
  
-- Retrieve data from the event monitor tables
SELECT agent_id, appl_id, territory_code FROM CONNHEADER_dlmon;
SELECT agent_id, appl_id, int_rows_inserted,
       system_cpu_time FROM CONN_dlmon;
SELECT * FROM CONTROL_dlmon;

-- Deactivate event monitor 
SET EVENT MONITOR dlmon STATE = 0;

-- Drop event monitor
DROP EVENT MONITOR dlmon; 

-- Dropping the monitor doesn't remove tables. They have to be 
-- dropped explicitly
DROP TABLE CONNHEADER_dlmon;
DROP TABLE DEADLOCK_dlmon;
DROP TABLE mydept.dlconnections;
DROP TABLE STMT_dlmon;
DROP TABLE CONN_dlmon;
DROP TABLE CONTROL_dlmon;
 
-- db2evtbl is a tool that generates sample CREATE EVENT MONITOR SQL 
-- statements that can be used when defining event monitors that write 
-- to sql tables. 
-- Uuncomment the following statement to generate a CREATE EVENT 
-- MONITOR sql statement
-- ! db2evtbl -evm dlmon STATEMENTS, DEADLOCKS WITH DETAILS, CONNECTIONS;
