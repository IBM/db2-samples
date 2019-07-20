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
-- SOURCE FILE NAME: rollindata.db2
--
-- SAMPLE: How to perform data-roll-in into a partitioned table.
--
-- SQL STATEMENTS USED:
--         ALTER TABLE
--         CREATE TABLE
--         CREATE TABLESPACE
--         DROP TABLE
--         EXPORT
--         IMPORT
--         INSERT
--         LOAD
--         SET INTEGRITY
--         TERMINATE
--
-- OUTPUT FILE: rollindata.out (available in the online documentation)
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

-- Connect to database.
CONNECT TO sample;

-- Create DMS tablespaces.
CREATE TABLESPACE tbsp1 MANAGED BY DATABASE USING (FILE 'conta' 1000);
CREATE TABLESPACE tbsp2 MANAGED BY DATABASE USING (FILE 'contb' 1000);
CREATE TABLESPACE tbsp3 MANAGED BY DATABASE USING (FILE 'contc' 1000);

-- Create a partitioned table on a list of tablespaces. A table 'emp_table'  
-- with three partitions will be created. i.e part0 will be placed in tbsp1,
-- part1 will be placed in tbps2, and part2 will be placed in tbsp3.
CREATE TABLE emp_table (emp_no INTEGER, emp_name VARCHAR(10))
  IN  tbsp1, tbsp2, tbsp3
  PARTITION BY RANGE (emp_no)
    (STARTING FROM (1) ENDING (10),
    STARTING FROM (11) ENDING (20),
    STARTING FROM (21) ENDING (30));

-- Create a temporary table.
CREATE TABLE temp_table(emp_no INTEGER, emp_name VARCHAR(10))
  IN  tbsp1, tbsp2, tbsp3
  PARTITION BY RANGE (emp_no)
    (STARTING FROM (1) ENDING (10),
    STARTING FROM (11) ENDING (20),
    STARTING FROM (21) ENDING (30));

-- Insert data into the table and export the data in order to obtain 
-- dummy.del file in the required format for load. 

INSERT INTO temp_table VALUES(1, 'John'), (11, 'Sam'), (21, 'Bill');
EXPORT TO dummy.del OF DEL SELECT * FROM temp_table;
LOAD FROM dummy.del OF DEL INSERT INTO emp_table;

-- Display the contents of 'emp_table' table.
SELECT * FROM emp_table;

-- The following scenario shows addition of a new partition to the base table
-- through ALTER statement along with ATTACH PARTITION clause to it.

-- Create a temporary table 'attach_part4' This table will be attached to the 
-- base table.
CREATE TABLE attach_part4(emp_no INTEGER, emp_name VARCHAR(10)) IN tbsp1;

-- Insert data into 'attach_part4'.
INSERT INTO attach_part4 VALUES(32, 'Chan'); 

-- Attach a partition to base table 'emp_table'. ALTER TABLE along with ATTACH 
-- clause is used to add a new partition to the existing base table.
ALTER TABLE emp_table ATTACH PARTITION part3 STARTING FROM (31) ENDING (40)
  FROM attach_part4;

-- Create a temporary table 'emp_exception'. This table will be used hold the 
-- exceptions returned by SET INTEGRITY statement.
CREATE TABLE emp_exception(emp_no INTEGER, emp_name VARCHAR(10));

-- The data in the ATTACHed partition is not yet visible, as it has not yet
-- been validated by set integrity.
-- The previous ALTER statement puts the table 'emp_table' into check pending 
-- state.
-- Before performing SELECT statement on 'emp_table' table, it need to be  
-- brought out of check pending state.
-- SET INTEGRITY statement brings the table out of check 
-- pending state and makes the table available. 
SET INTEGRITY FOR emp_table IMMEDIATE CHECKED 
  FOR EXCEPTION IN emp_table USE emp_exception;

-- Display the contents of 'emp_table' table. 
-- The rows added by the new partition are also displayed.
SELECT * FROM emp_table;
DROP TABLE emp_exception;

-- The following scenario shows addition of partition to the base table
-- through ALTER statement along with ADD PARTITION clause to it.

-- Create a temporary table 'attach_part3'. This table will be added to 
-- the base table.
CREATE TABLE attach_part3 (emp_no INTEGER, emp_name VARCHAR(10)) IN tbsp1;

-- Insert data into 'attach_part3'.
INSERT INTO attach_part3 VALUES(36, 'Steve');

-- Add partition to the base table. 
-- Similar to ALTER STATEMENT with ATTACH clause, ADD partition clause can  
-- also be used with ALTER TABLE statement to add a new partition to the 
-- existing base table.
ALTER TABLE emp_table ADD PARTITION part4 STARTING FROM (41) ENDING (50);

-- Export the data in order to obtain dummy.del file in the required format 
-- for load.

EXPORT TO dummy.del OF DEL SELECT * FROM attach_part3;
LOAD FROM dummy.del OF DEL INSERT INTO emp_table;

-- Display the contents of 'emp_table' table.
SELECT * FROM emp_table;

-- Drop the tables.
DROP TABLE temp_table;
DROP TABLE emp_table;

! rm dummy.del;

-- Drop the tablespaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;
 
-- Disconnect from database.
CONNECT RESET;

TERMINATE;
