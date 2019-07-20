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
-- SOURCE FILE NAME: partitionindex.db2
--
-- SAMPLE: How to create indexes on a partitioned table. 
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         CREATE TABLESPACE
--         CREATE INDEX
--         TERMINATE
--
-- OUTPUT FILE: partitionindex.out (available in the online documentation)
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

-- Create a partitioned table on a list of tablespaces. A table 'number1'with
-- four partitions will be created i.e. part0 is placed in tbsp1, part1 is
-- placed in tbsp2, part2 is placed in tbsp3, and part3 is placed in tbsp1.
-- The partitions will be placed in Round Robin fashion in tablespaces.
CREATE TABLE number1(num0 INT, 
                     num1 INT) 
  PARTITION BY (num0)
    (PART part1 STARTING FROM (1) ENDING AT (10000),
    PART part2 STARTING FROM (10001) ENDING AT (20000),
    PART part3 STARTING FROM (20001)  ENDING AT (20010),
    PART part4 STARTING FROM (20011)  ENDING AT (20020));

-- Create index without IN clause. The default for indexes on partitioned 
-- tables is NOT PARTITIONED.
-- Index should be placed in the tablespace of the first data partition.
CREATE INDEX idx1_tab1 ON number1(num0);

-- Create index with IN clause.
-- Index will be placed in the mentioned tablespace.
-- This overrides the tablespace specified in CREATE TABLE statement   
-- regardless of whether the base table's table space is DMS or SMS.
CREATE INDEX idx2_tab2 ON number1(num1) IN tbsp3;

-- Drop the indexes.
DROP INDEX idx1_tab1;
DROP INDEX idx2_tab2;

-- Create a partitioned table with the IN clause for the index creation. 
-- A table 'number2' with four partitions will be created. i.e part0 is 
-- placed in tbsp1, part1 is placed in tbsp2, part3 is placed in tbsp1, 
-- part4 is placed in tbsp2. 
CREATE TABLE number2(num1 INT NOT NULL PRIMARY KEY, 
                     num2 INT) LONG IN tbsp1 CYCLE INDEX IN tbsp2 
  PARTITION BY (num1)
    (PART part1 STARTING FROM (1) ENDING AT (10000),
    PART part2 STARTING FROM (10001) ENDING AT (20000),
    PART part3 STARTING FROM (20001)  ENDING AT (20010),
    PART part4 STARTING FROM (20011)  ENDING AT (20020));

-- Create index with IN clause.
-- Index should be placed in the tablespace specified.
CREATE INDEX idx1_tab2 ON number2(num2) IN tbsp3;

-- Drop the index.
DROP INDEX idx1_tab2;

-- Drop the partitioned tables.
DROP TABLE number1;
DROP TABLE number2;

-- Drop the tablespaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;
DROP TABLESPACE tbsp3;

-- Disconnect from database.
CONNECT RESET;

TERMINATE;
