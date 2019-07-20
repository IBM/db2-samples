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
-- SOURCE FILE NAME: onlineload.db2
--    
-- SAMPLE: How to do online loading using the ALLOW READ ACCESS option
--         for both partitioned and non-partitioned tables.
--        
--         Note:
--           This sample assumes that the configuration parameters
--           LOGRETAIN and USEREXIT are disabled. Otherwise the tablespace
--           enters into a 'backup pending' state after the load.  
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         DELETE  
--         DROP TABLE
--         EXPORT
--         INSERT
--         LOAD
--
-- OUTPUT FILE: onlineload.out (available in the online documentation)
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

--Use of LOAD utility on non-partitioned table

-- Connect to sample database.
CONNECT TO sample;

CREATE TABLE ed(ed INT);

-- Insert data into the table and export that data in order to obtain File1 
-- and File2 in the required format for load.
INSERT INTO ed VALUES(1);
INSERT INTO ed VALUES(2);
INSERT INTO ed VALUES(3);

EXPORT TO file1 OF DEL SELECT * FROM ed;

DELETE FROM ed;

INSERT INTO ed VALUES(4);
INSERT INTO ed VALUES(5);

EXPORT TO file2 OF del SELECT * FROM ed;

DELETE FROM ed;

-- Now table ED is empty. 
-- Load 3 rows
LOAD FROM file1 OF del MESSAGES loadmsg.txt INSERT INTO ed;

-- Query the table
SELECT * FROM ed;

-- Perform a load operation with the ALLOW READ ACCESS option specified 
-- and load two more rows of data.
LOAD FROM file2 OF DEL MESSAGES loadmsg.txt INSERT INTO ed ALLOW READ ACCESS;

-- At the same time, on another connection the table could be queried while 
-- the load operation is in progress 
-- SELECT * FROM ed
-- ED         
-- -----------
--           1
--           2
--           3

-- Wait for the load operation to finish and then query the table
SELECT * FROM ed; 
-- ED         
-- -----------
--           1
--           2
--           3
--           4
--           5

-- In case eitherthe LOGRETAIN or USEREXIT parameter is not disabled,
-- the tablespace enters into a 'backup pending' state. To prevent this 
-- the following two SQL statements must be uncommented.
-- BACKUP DB SAMPLE;
-- CONNECT TO SAMPLE;

DROP TABLE ed;
COMMIT;

-- The following two system commands delete the temporary files created for
-- load.
! rm file1;
! rm file2;

-- uncomment the below line for deleting the file created to hold the
-- progress messages generated during load. 
-- ! rm loadmsg.txt;
--End: Use of LOAD utility on non-partitioned table
 ------------------------------------------------------------------------
--Use of LOAD utility on partitioned table

--Create tablespaces
CREATE TABLESPACE tbsp1 MANAGED BY SYSTEM USING('tbsp1');
GRANT USE OF TABLESPACE tbsp1 TO PUBLIC;

CREATE TABLESPACE tbsp2 MANAGED BY SYSTEM USING('tbsp2');
GRANT USE OF TABLESPACE tbsp2 TO PUBLIC;

CREATE TABLESPACE tbsp3 MANAGED BY SYSTEM USING('tbsp3');
GRANT USE OF TABLESPACE tbsp3 TO PUBLIC;

--Create a partition table 
CREATE TABLE employee_details (emp_id INT NOT NULL PRIMARY KEY, 
                              dept_name VARCHAR (10))
  IN tbsp1, tbsp2, tbsp3
  PARTITION BY RANGE (emp_id)
  (STARTING 1 ENDING 100 EVERY 10);

-- Create Exception table.(This table will hold the rows rejected by
-- the LOAD utility)
CREATE TABLE exception_tab AS (SELECT employee_details.*, 
                               CURRENT TIMESTAMP AS TIMESTAMP,
                               cast ('' AS CLOB (32K))
                               AS MSG FROM employee_details) 
  WITH NO DATA;

--Create a non partition table
CREATE TABLE table_for_creating_datafile(emp_id INT, dept_name VARCHAR(10));

--Insert into the partition table, having rows such that EMP_ID has
-- duplicate values and some values exceeding the Range limits, and
-- export that data in order to obtain a file in the required format
-- for load.
INSERT INTO table_for_creating_datafile VALUES  (1, 'D1'),
                                                (2, 'D2'),
                                                (10, 'D3'),
                                                (10, 'D4'),
                                                (100, 'D5'),
                                                (110, 'D6');  

--Create the file data_unique_range.del
EXPORT TO data_unique_range.del
  OF DEL MESSAGES msg.txt 
  SELECT * FROM table_for_creating_datafile;

--The load below demonstrates the usage of NOUNIQUEEXC 
--and ALLOW NO READ ACCESS together.
LOAD FROM data_unique_range.del 
  OF DEL INSERT INTO employee_details
  FOR EXCEPTION exception_tab 
  NOUNIQUEEXC NONRECOVERABLE ALLOW READ ACCESS;

SELECT * FROM employee_details;

-- Check rows inserted into the exception table.
SELECT emp_id,dept_name FROM exception_tab;

LOAD FROM data_unique_range.del 
  OF DEL REPLACE INTO employee_details 
  FOR EXCEPTION exception_tab
  NORANGEEXC NONRECOVERABLE  ALLOW NO ACCESS;

SELECT * FROM employee_details;

-- Check rows inserted into the exception table.
SELECT emp_id,dept_name FROM exception_tab;

DROP TABLE employee_details;
DROP TABLE exception_tab;
DROP TABLE table_for_creating_datafile;
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;
COMMIT;

-- The following system command delete the temporary files created for
-- load.
! rm data_unique_range.del;

-- uncomment the below line for deleting the file created to hold the
-- progress messages generated during load. 
-- ! rm msg.txt;
--End: Use of LOAD utility on a partitioned table.
