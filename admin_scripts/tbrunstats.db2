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
-- SOURCE FILE NAME: tbrunstats.db2
--
-- SAMPLE: How to perform runstats on a table
--
-- SQL STATEMENT USED:
--         CREATE SCHEMA
--         CREATE TABLE
--         DROP SCHEMA
--         DROP TABLE
--         INSERT
--         SELECT
--         TERMINATE
--
-- OUTPUT FILE: tbrunstats.out (available in the online documentation)
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

-- create a schema
CREATE SCHEMA testschema;

-- create a table
CREATE TABLE testschema.employee_temp LIKE employee;

-- insert into the table employee_temp
INSERT INTO testschema.employee_temp (SELECT * FROM employee);

-- perform Runstats on the table

-- update statistics for the table employee_temp

-- perform runstats on table employee_temp for column empno
-- with the following options: 
--
--                 Distribution statistics for all partitions
--                 Frequent values for table set to 30
--                 Quantiles for table set to -1 (NUM_QUANTILES as in DB Cfg)
--                 Allow others to have read-only while gathering statistics

RUNSTATS ON TABLE testschema.employee_temp 
  ON COLUMNS(empno LIKE STATISTICS) 
  WITH DISTRIBUTION ON KEY COLUMNS 
  DEFAULT  
  NUM_FREQVALUES 30 
  NUM_QUANTILES -1 
  ALLOW READ ACCESS;

-- make sure to rebind all packages that use this table.

-- drop the table employee_temp
DROP TABLE testschema.employee_temp;

-- drop the schema
DROP SCHEMA testschema RESTRICT;

-- disconnect from the database
CONNECT RESET; 

TERMINATE;
