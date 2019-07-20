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
-- SOURCE FILE NAME: tbumqt.db2
--
-- SAMPLE: How to use user-maintained materialized query tables (summary
--         tables).
--
--         This sample:
--         1. Creates a non-partitioned User-Maintained Materialized 
--            Query Table (UMQT) for the 'employee' table.
--         2. Shows the usage and update mechanisms for non-partitioned UMQTs.
--         3. Creates a new partitioned Materialized Query Table (MQT). 
--         4. Shows the availability of partitioned MQTs during SET INTEGRITY 
--            after add/detach of a partition via ALTER ADD PARTITION and 
--            ALTER DETACH PARTITION.
--
-- SQL STATEMENTS USED:
--         ALTER TABLE
--         CREATE TABLE
--         DROP
--         INSERT
--         SELECT
--         SET CURRENT
--         SET INTEGRITY
--         REFRESH TABLE
--         TERMINATE
--
-- OUTPUT FILE: tbumqt.out (available in the online documentation)
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

-- The following scenario shows how to use non-partitioned UMQTs.

-- Create Summary Tables.
-- Create UMQT on 'employee' table.
CREATE TABLE adefuser AS
  (SELECT workdept, count(*) AS no_of_employees
     FROM employee GROUP BY workdept)
  DATA INITIALLY DEFERRED REFRESH DEFERRED
  MAINTAINED BY USER;

-- Creating a summary table to create a UMQT with 'IMMEDIATE' refresh 
-- option is not supported.
CREATE TABLE aimdusr AS
  (SELECT workdept, count(*) AS no_of_employees
     FROM employee GROUP BY workdept)
  DATA INITIALLY DEFERRED REFRESH DEFERRED 
  MAINTAINED BY USER;

-- Bring the summary table out of check-pending state.
SET INTEGRITY FOR adefuser ALL IMMEDIATE UNCHECKED;

-- Populate the base table and update the contents of the summary table.

-- 'adefuser' table must be updated manually by the user.
INSERT INTO adefuser (SELECT workdept, count(*) AS no_of_employees 
                       FROM employee GROUP BY workdept);

-- Set registers to optimize query processing by routing queries to UMQT.

-- The CURRENT REFRESH AGE special register must be set to a value other
-- than zero for the specified table types to be considered when optimizing
-- the processing of dynamic SQL queries.

-- The following registers must be set to route queries to UMQT. 
-- SET CURRENT REFRESH AGE ANY 
-- indicates that any table types specified by CURRENT MAINTAINED TABLE TYPES
-- FOR OPTIMIZATION and MQTs defined with REFRESH IMMEDIATE option can be 
-- used to optimize the processing of a query.
SET CURRENT REFRESH AGE ANY;

-- SET CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION USER Specifies that 
-- user-maintained refresh-deferred materialized query tables can be 
-- considered to optimize the processing of dynamic SQL queries.

SET CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION USER;

-- Issue a select statement that is routed to the summary table.

-- This SELECT statement is routed to the UMQT 'adefuser'.
SELECT workdept, count(*) AS no_of_employees
  FROM employee GROUP BY workdept;

-- A SELECT query on the table 'adefuser' yields similar results
SELECT * FROM adefuser;

-- Drop the UMQT.
DROP TABLE adefuser;
DROP TABLE aimdusr;

-- This following scenario shows the availability of read and write access to
-- the attached table and its dependent refresh immediate MQT.

-- Create DMS tablespaces.
CREATE TABLESPACE tbsp1 MANAGED BY DATABASE USING (FILE 'conta' 1000);
CREATE TABLESPACE tbsp2 MANAGED BY DATABASE USING (FILE 'contb' 1000);
CREATE TABLESPACE tbsp3 MANAGED BY DATABASE USING (FILE 'contc' 1000);

-- Create a partitioned table.
CREATE TABLE fact_table (max SMALLINT NOT NULL, CONSTRAINT CC CHECK (max>0))
  PARTITION BY RANGE (max)
    (PART  part1 STARTING FROM (1) ENDING (3) IN tbsp1,
    PART part2 STARTING FROM (4) ENDING (6) IN tbsp2,
    PART part3 STARTING FROM (7) ENDING (9) IN tbsp3);

-- Insert data into table.
INSERT INTO fact_table VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9);

-- Create a refresh immediate MQT on 'fact_table'.
CREATE TABLE mqt_fact_table AS 
  (SELECT max, COUNT (*) AS no_of_rows FROM fact_table GROUP BY max) 
    DATA INITIALLY DEFERRED REFRESH IMMEDIATE;

-- Bring 'mqt_fact_table' out of check pending state.
SET INTEGRITY FOR mqt_fact_table IMMEDIATE CHECKED; 

-- Display the contents of each table.
SELECT * FROM fact_table;
SELECT * FROM mqt_fact_table;

-- Create temporary table to be attached to 'fact_table' later.
CREATE TABLE attach_part (max SMALLINT NOT NULL);

-- Insert data into the table.
INSERT INTO attach_part VALUES (10), (11), (12);

-- Attach partition to 'fact_table' table.
ALTER TABLE fact_table ATTACH PARTITION STARTING (10) ENDING (12) 
  FROM TABLE attach_part;

-- Create a temporary table to hold exceptions thrown by SET INTEGRITY 
-- statement.
CREATE TABLE fact_exception (max SMALLINT NOT NULL);

-- The refresh immediate 'mqt_fact_table' depends on the 
-- 'fact_table', the below SET INTEGRITY statement will check the attached  
-- partition of 'fact_table' for constraint violations and incrementally 
-- refresh the 'mqt_fact_table' with respect to the attached partitions while 
-- providing read and write access to both tables during SET INTEGRITY  
-- processing.  

SET INTEGRITY FOR fact_table ALLOW WRITE ACCESS, mqt_fact_table 
  ALLOW WRITE ACCESS IMMEDIATE CHECKED 
    FOR EXCEPTION IN fact_table USE fact_exception;

-- Display the contents of each table.
SELECT * FROM fact_table;
SELECT * FROM mqt_fact_table;

-- Drop the tables.
DROP TABLE fact_table;
DROP TABLE fact_exception;

-- The following scenario shows how partitioned MQT can be maintained
-- during SET INTEGRITY processing.

-- Create a partitioned table.
CREATE TABLE fact_table (max SMALLINT NOT NULL, CONSTRAINT CC CHECK (max>0))
  PARTITION BY RANGE (max)
    (PART  part1 STARTING FROM (1) ENDING (3) IN tbsp1,
    PART part2 STARTING FROM (4) ENDING (6) IN tbsp2,
    PART part3 STARTING FROM (7) ENDING (9) IN tbsp3);

-- Insert data into table.
INSERT INTO fact_table VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9);

-- Create a partitioned refresh immediate MQT on fact_table whose range 
-- is smaller then fact_table.

CREATE TABLE mqt_fact_table AS 
  (SELECT max, COUNT (*) AS NO_OF_ROWS FROM FACT_TABLE GROUP BY max) 
    DATA INITIALLY DEFERRED REFRESH IMMEDIATE PARTITION BY RANGE (max) 
    (STARTING 0 ENDING 6 EVERY 3);

-- Add partition to MQT, since attach cannot be performed on MQT.
ALTER TABLE mqt_fact_table ADD PARTITION part4 STARTING (7) ENDING (9); 

-- Refresh 'mqt_fact_table' to get the changes reflected.
REFRESH TABLE mqt_fact_table;

-- Display the contents of each table.
SELECT * FROM fact_table;
SELECT * FROM mqt_fact_table;

-- Detach partition from 'fact_table'. 
ALTER TABLE fact_table DETACH PARTITION part2 INTO TABLE detach_part1;

-- The above alter statement puts 'mqt_fact_table' into check pending state.
-- So before performing select operation on 'mqt_fact_table', it has to be 
-- brought out of check pending state.
 
SET INTEGRITY FOR mqt_fact_table IMMEDIATE CHECKED;

-- Detach partition from 'mqt_fact_table'.
ALTER TABLE mqt_fact_table DETACH PARTITION part2 INTO TABLE detach_part2;

-- The above alter statement puts 'mqt_fact_table' into check pending state.
-- So before performing select operation on 'mqt_fact_table', it has to be
-- brought out of check pending state.

-- Perform refresh on 'mqt_fact_table' to get changes reflected.
REFRESH TABLE mqt_fact_table;

-- Display the contents of tables.
SELECT * FROM fact_table;
SELECT * FROM mqt_fact_table;

-- Drop the tables.
DROP TABLE fact_table;
DROP TABLE detach_part1;
DROP TABLE detach_part2;

-- Drop the tablespaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;

-- Disconnect from database.
CONNECT RESET;

TERMINATE;
