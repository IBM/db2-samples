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
-- SOURCE FILE NAME: setintegrity.db2
--
-- SAMPLE: How to perform online SET INTEGRITY on a table. 
--
--         This sample shows:
--         1. Availability of table during SET INTEGRITY after LOAD utility.
--         2. Availability of table during SET INTEGRITY after adding a new 
--            partition is added to the table via the ALTER ATTACH.
--         3. Shows how SET INTEGRITY statement will generate the proper 
--            values for both generated columns and identity values whenever  
--            a partition which violates the constraint is attached a data
--            partitioned table.
--         4. Shows new ALL IMMEDIATE UNCHECKED option in the SET INTEGRITY 
--            statement which can skip range and constraints violation checking, 
--            making the newly attached data visible immediately. 
--         
--            Note:- New otion ALL IMMEDIATE UNCHECKED in SET INTEGRITY
--                   statement skips the range and constraints violation  
--                   checking, user assumes full responsibility for the data 
--                   integrity.
--
-- SQL STATEMENTS USED:
--         ALTER TABLE
--         CREATE TABLE
--         CREATE TABLE
--         DROP TABLE
--         EXPORT
--         IMPORT
--         INSERT
--         LOAD
--         SELECT
--         SET INTEGRITY
--         TERMINATE
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

-- The following scenario shows the availability of table during 
-- SET INTEGRITY after LOAD utility.

-- Create a partitioned table.

CREATE TABLE fact_table (min SMALLINT NOT NULL, CONSTRAINT CC CHECK (min>0))
  PARTITION BY RANGE (min)
    (PART  part1 STARTING FROM (-1) ENDING (3) IN tbsp1,
    PART part2 STARTING FROM (4) ENDING (6) IN tbsp2,
    PART part3 STARTING FROM (7) ENDING (9) IN tbsp3);

-- Insert data into table.
INSERT INTO fact_table VALUES (1), (2), (3);

-- Create a temporary table.
CREATE TABLE temp_table (min SMALLINT NOT NULL);

-- Insert data into temporary table and export the data in order to obtain
-- 'dummy.del' file in the required format for load.

INSERT INTO temp_table VALUES (4), (5), (6), (7), (0), (-1);
EXPORT TO dummy.del OF DEL SELECT * FROM temp_table;
LOAD FROM dummy.del OF DEL INSERT INTO fact_table;

-- Create a temporary table to hold exceptions thrown by SET INTEGRITY statement.
CREATE TABLE fact_exception (min SMALLINT NOT NULL);

-- The following SET INTEGRITY statement will check the table 'fact_table' for 
-- constraint violations and at the same time it provides read access to the 
-- table 'fact_table'. If there are any constraint violations then the 
-- violating data will be deleted from fact_table and inserted into 
-- 'fact_exception' table (a temporary table).
  
SET INTEGRITY FOR fact_table ALLOW READ ACCESS IMMEDIATE CHECKED 
  FOR EXCEPTION IN fact_table USE fact_exception;

-- Display the contents of each table.
SELECT * FROM fact_table;
SELECT * FROM fact_exception;

-- Drop the tables.
DROP TABLE fact_table;
DROP TABLE fact_exception;
DROP TABLE temp_table;

-- The following scenario shows the availability of table during SET INTEGRITY
-- along with GENERATE IDENTITY clause after LOAD.

-- Create a partitioned table.
CREATE TABLE fact_table (min SMALLINT NOT NULL,
                         max SMALLINT GENERATED ALWAYS AS IDENTITY,
                         CONSTRAINT CC CHECK (min>0))
  PARTITION BY RANGE (min)
    (PART  part1 STARTING FROM (1) ENDING (3) IN tbsp1,
    PART part2 STARTING FROM (4) ENDING (6) IN tbsp2,
    PART part3 STARTING FROM (7) ENDING (9) IN tbsp3);  

-- Create temporary table to load data into base table.
CREATE TABLE temp_table(min  SMALLINT NOT NULL);

-- Insert data into temporary table and export the data in order to obtain
-- 'dummy.del' file in the required format for load.

INSERT INTO temp_table VALUES (1), (2), (3), (4), (5), (6), (7), (8), (9);
EXPORT TO dummy.del OF DEL SELECT * FROM temp_table;
 
-- Load data from 'dummy.del' into 'fact_table'.
LOAD FROM dummy.del OF DEL INSERT INTO fact_table;

-- The following SET INTEGRITY statement will check the table fact_table for 
-- constraint violations and at the same time the GENERATE IDENTITY along with
-- NOT INCREMENTAL options will generate new identity values for all rows 
-- currently in the table and all loaded rows. 
 
SET INTEGRITY FOR fact_table GENERATE IDENTITY IMMEDIATE CHECKED 
  NOT INCREMENTAL;

-- Display the contents of 'fact_table'.
SELECT * FROM fact_table;

-- Drop the tables. 
DROP TABLE fact_table;

-- The following scenario show the availability of table during SET INTEGRITY
-- along with FORCE GENERATED clause after LOAD.

-- Create a partitioned table.
CREATE TABLE fact_table (min SMALLINT NOT NULL, 
                         max SMALLINT GENERATED ALWAYS AS IDENTITY,
                         CONSTRAINT CC CHECK (min>0))
  PARTITION BY RANGE (min)
    (PART  part1 STARTING FROM (1) ENDING (3) IN tbsp1,
    PART part2 STARTING FROM (4) ENDING (6) IN tbsp2,
    PART part3 STARTING FROM (7) ENDING (9) IN tbsp3);

-- Load data from 'dummy.del' into 'fact_table'.
LOAD FROM dummy.del OF DEL INSERT INTO fact_table;

-- The following SET INTEGRITY statement will check the table fact_table for 
-- constraint violations and at the same time the force generated clause 
-- will operate on rows that do not evaluate to the proper expression.

SET INTEGRITY FOR fact_table IMMEDIATE CHECKED FORCE GENERATED; 
  
-- Display the contents of 'fact_table'.
SELECT * FROM fact_table;

-- Drop the tables.
DROP TABLE fact_table;

-- The following scenario shows the availability of table during SET INTEGRITY
-- after ATTACH.

-- Create a partitioned table.
CREATE TABLE fact_table (min SMALLINT NOT NULL,
                         max SMALLINT GENERATED ALWAYS AS IDENTITY,
                         CONSTRAINT CC CHECK (min>0))
  PARTITION BY RANGE (min)
   (PART  part1 STARTING FROM (1) ENDING (3) IN tbsp1,
   PART part2 STARTING FROM (4) ENDING (6) IN tbsp2,
   PART part3 STARTING FROM (7) ENDING (9) IN tbsp3);

LOAD FROM dummy.del OF DEL INSERT INTO fact_table;

-- Create a table to be attached.
CREATE TABLE attach_part (min SMALLINT NOT NULL,
                          max SMALLINT GENERATED ALWAYS AS IDENTITY,
                          CONSTRAINT CC CHECK (min>0));

-- Create a  temporary table to load data into base table.
CREATE TABLE attach(min SMALLINT NOT NULL);

INSERT INTO attach VALUES (10), (11), (12);
EXPORT TO dummy1.del OF DEL SELECT * FROM attach;

-- Load data from 'dummy1.del' into 'fact_table'.
LOAD FROM dummy1.del OF DEL INSERT INTO attach_part;

-- Attach partition to 'fact_table' table.
ALTER TABLE fact_table ATTACH PARTITION part4 STARTING FROM (10) ENDING AT (12)
  FROM TABLE attach_part;

-- The following SET INTEGRITY statement will check the table fact_table for
-- constraint violations and at the same time the GENERATE IDENTITY along with
-- INCREMENTAL options will generate new identity values for attached
-- rows only.

SET INTEGRITY FOR fact_table GENERATE IDENTITY IMMEDIATE CHECKED INCREMENTAL;

-- Display the contents of 'fact_table' table.
SELECT * FROM fact_table;


-- Drop the tables.
DROP TABLE fact_table;
DROP TABLE temp_table;
DROP TABLE attach;

-- The SET INTEGRITY statement is used for checking constraints and 
-- integrity violations. It is a long-running operation, and the cost 
-- is proportional to the amount of newly attached data. In scenarios
-- where the constraints and integrity checking of the data in 
-- the attached partition has already been done using application 
-- logic outside of the database then there is no need to check for 
-- violations again using the SET INTEGRITY statement.

-- The following scenario shows the quick availability of table after 
-- ATTACH with the new option ALL IMMEDIATE UNCHECKED in SET INTEGRITY 
-- which skips the range and constraints violation checking, making the 
-- newly attached data visible immediately.

-- Create a partitioned table.
CREATE TABLE fact_table (min SMALLINT NOT NULL,
                         max SMALLINT GENERATED ALWAYS AS IDENTITY,
                         CONSTRAINT CC CHECK (min>0))
  PARTITION BY RANGE (min)
   (PART  part1 STARTING FROM (1) ENDING (3) IN tbsp1,
   PART part2 STARTING FROM (4) ENDING (6) IN tbsp2,
   PART part3 STARTING FROM (7) ENDING (9) IN tbsp3);

LOAD FROM dummy.del OF DEL INSERT INTO fact_table;

-- Create a table to be attached.
CREATE TABLE attach_part (min SMALLINT NOT NULL,
                          max SMALLINT GENERATED ALWAYS AS IDENTITY,
                          CONSTRAINT CC CHECK (min>0));

-- Create a  temporary table to load data into base table.
CREATE TABLE attach(min SMALLINT NOT NULL);

INSERT INTO attach VALUES (10), (11), (12);
EXPORT TO dummy1.del OF DEL SELECT * FROM attach;

-- Load data from 'dummy1.del' into 'fact_table'.
LOAD FROM dummy1.del OF DEL INSERT INTO attach_part;

-- Attach partition to 'fact_table' table.
ALTER TABLE fact_table ATTACH PARTITION part4 STARTING FROM (10) ENDING AT (12)
  FROM TABLE attach_part;

-- The following SET INTEGRITY statement skips the range and constraints 
-- violation checking for table fact_table, making the newly attached data 
-- visible immediately.

SET INTEGRITY FOR fact_table ALL IMMEDIATE UNCHECKED;

-- Display the contents of 'fact_table' table.
SELECT * FROM fact_table;

-- Drop the tables.
DROP TABLE fact_table;
DROP TABLE temp_table;
DROP TABLE attach;

-- Drop the tablespaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;

-- Remove created temporary files.
! rm -rf dummy.del;
! rm -rf dummy1.del;

-- Disconnect from database.
CONNECT RESET;

TERMINATE;
