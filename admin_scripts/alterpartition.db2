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
-- SOURCE FILE NAME: alterpartition.db2
--
-- SAMPLE: How to perform addition/deletion of partitions on a partitioned 
--         table. 
--
--         This sample shows:
--         1. How to add a new partition to a partitioned table.
--         2. How to delete a partition from a partitioned table.
--
-- SQL STATEMENTS USED:
--         ALTER TABLE
--         CREATE TABLE
--         CREATE TABLESPACE
--         DROP TABLE
--         INSERT
--         SET INTEGRITY
--         TERMINATE
--
-- OUTPUT FILE: alterpartition.out (available in the online documentation)
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
CREATE TABLESPACE tbsp1 MANAGED BY DATABASE USING (FILE 'conta' 10000);
CREATE TABLESPACE tbsp2 MANAGED BY DATABASE USING (FILE 'contb' 10000);
CREATE TABLESPACE tbsp3 MANAGED BY DATABASE USING (FILE 'contc' 10000);

-- Creating a partitioned table on a list of tablespaces. A table 'emp_table'  
-- with three partitions will be created i.e. part0 is placed in tbsp1, part1  
-- is placed in tbsp2, and part2 is placed in tbsp3.
CREATE TABLE emp_table(emp_no INTEGER NOT NULL, 
                 emp_name VARCHAR(10),
                 dept VARCHAR(5), 
                 salary DOUBLE DEFAULT 3.14)
  IN  tbsp1, tbsp2, tbsp3
  PARTITION BY RANGE (emp_no)
    (STARTING FROM (1) ENDING (25) EVERY (5),
    STARTING FROM (26) ENDING (50) EVERY (10),
    STARTING FROM (51) ENDING (75) EVERY (15));

-- Show data partitions defined for the base table 'emp_table'.
SELECT seqno, datapartitionid, substr(datapartitionname, 1, 15) 
  AS datapartitionname, substr(lowvalue, 1, 10) AS lowvalue, 
     substr(highvalue, 1, 10) AS highvalue FROM SYSCAT.DATAPARTITIONS 
  WHERE tabname = 'EMP_TABLE' AND tabschema = CURRENT SCHEMA;

-- Insert data into the base table 'emp_table'.
INSERT INTO emp_table VALUES (1,  'John',  'E31', 4.34),
        	       (26, 'James', 'E32', 3.35),
    		       (51, 'Bill',  'E33', 4.00);

-- Display the contents of the base table and which partition the rows are 
-- in datapartitionnum returns the seqno of the partition.
-- WHERE predicate helps in partition elimination. 
SELECT datapartitionnum(emp_no) AS dpnum, emp_no, emp_name, dept, salary 
  FROM emp_table WHERE emp_no > 1 ORDER BY emp_no;

-- Detach a partition from the base table 'emp_table'. 
ALTER TABLE emp_table DETACH PARTITION part0 INTO TABLE emp_part0;

-- Display the contents of 'emp_part0'. This table contains DETACHed data.  
SELECT * FROM emp_part0;

-- Display the datapartitionnum of 'emp_table' after DETACH operation is 
-- performed.
SELECT datapartitionnum(emp_no) AS dpnum, emp_no, emp_name, dept, salary 
  FROM emp_table ORDER BY emp_no;

-- Create a temporary table 'tabletobeattached'. This table will be attached  
-- to the base table 'emp_table'.
CREATE TABLE tabletobeattached (emp_no INTEGER NOT NULL, 
                                emp_name VARCHAR(10),
                                dept VARCHAR(5), 
                                salary DOUBLE DEFAULT 3.14)IN tbsp1; 

-- Insert data into the table 'tabletobeattached'.
INSERT INTO tabletobeattached VALUES (80, 'Sam', 'E36', 3.75); 

-- Display the datapartitionnum of 'tabletobeattached'. Since it is 
-- non-partitioned table, datapartitionnum column should return 0.
SELECT datapartitionnum(emp_no) FROM tabletobeattached;

-- Attach a new partition to the table 'emp_table'. ALTER TABLE statement  
-- along with ATTACH clause is used to add a new partition to the base table.
ALTER TABLE emp_table ATTACH PARTITION attach_part 
  STARTING FROM (76) ENDING (100) INCLUSIVE FROM tabletobeattached;

-- The previous ATTACH statement puts the table 'emp_table' into check 
-- pending state.
-- Before performing SELECT operation on 'emp_table' it needs to be brought 
-- out of check pending state. The following SET INTEGRITY statement brings 
-- the table out of check pending state and makes the table availabe.
SET INTEGRITY FOR emp_table IMMEDIATE CHECKED;

-- Display the contents of 'emp_table' after ATTACH is performed.
-- The newely added rows are also displayed.
SELECT * FROM emp_table;

-- Drop the tables.
DROP TABLE emp_table;

-- Drop the tablespaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;

-- Disconnect from database.
CONNECT RESET;

TERMINATE;
