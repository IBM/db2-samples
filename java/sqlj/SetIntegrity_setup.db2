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
-- SOURCE FILE NAME: SetIntegrity_setup.db2
--
-- SAMPLE: This sample serves as the setup script for the sample
--         SetIntegrity.sqlj 
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--
-- To run this script from the CLP issue the below command:
--            "db2 -tvf SetIntegrity_setup.db2"
--
----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad

----------------------------------------------------------------------------

connect to sample;

----------------------------------------------------------------------------
-- Creating the tablespaces
----------------------------------------------------------------------------

-- create regular DMS table space tbspace

CREATE REGULAR TABLESPACE tbspace
             MANAGED BY DATABASE USING (FILE 'cont.dat' 10000);

-- create regular DMS table space tbspace1

CREATE REGULAR TABLESPACE tbspace1
             MANAGED BY DATABASE USING (FILE 'cont1.dat' 10000);

-- create regular DMS table space tbspace2

CREATE REGULAR TABLESPACE tbspace2
             MANAGED BY DATABASE USING (FILE 'cont2.dat' 10000);

-- create regular DMS table space tbspace3

CREATE REGULAR TABLESPACE tbspace3
             MANAGED BY DATABASE USING (FILE 'cont3.dat' 10000);

----------------------------------------------------------------------------
-- Creating tables for the function partitionedTbCreate 
----------------------------------------------------------------------------

-- creates a partitioned table with 'part1' in 'tbspace1', 'part2' in
-- 'tbspace2', and 'part3' in 'tbspace3' and inserts data into the
-- table.

CREATE TABLE fact_table1 (max INTEGER NOT NULL, CONSTRAINT CC CHECK (max>0))
                PARTITION BY RANGE (max)
                (PART  part1 STARTING FROM (-1) ENDING (3) IN tbspace1,
                PART part2 STARTING FROM (4) ENDING (6) IN tbspace2,
                PART part3 STARTING FROM (7) ENDING (9) IN tbspace3);

-- create a temporary table

CREATE TABLE temp_table1 (max INT);

-- create temporary table to hold exceptions thrown by SET INTEGRITY statement

CREATE TABLE fact_exception (max INTEGER NOT NULL);

----------------------------------------------------------------------------
-- Creating temporary tables for createtb_Temp function 
----------------------------------------------------------------------------

-- creates a partitioned table with 'part1' in 'tbspace1', 'part2' in
-- 'tbspace2' and 'part3' in 'tbspace3' with GENERATE IDENTITY clause

CREATE TABLE  fact_table2 (min SMALLINT NOT NULL,
                            max SMALLINT GENERATED ALWAYS AS IDENTITY,
                            CONSTRAINT CC CHECK (min>0))
             PARTITION BY RANGE (min)
               (PART  part1 STARTING FROM (1) ENDING (3) IN tbspace1,
               PART part2 STARTING FROM (4) ENDING (6) IN tbspace2,
               PART part3 STARTING FROM (7) ENDING (9) IN tbspace3);

-- create temporary table

CREATE TABLE temp_table2 (min SMALLINT NOT NULL);

----------------------------------------------------------------------------
-- Creating temporary tables for createptb_Temp function
----------------------------------------------------------------------------

-- creates a partitioned table with 'part1' in 'tbspace1', 'part2' in
-- 'tbspace2' and 'part3' in 'tbspace3' with GENERATE IDENTITY clause
-- 'tbspace2' and 'part3' in 'tbspace3' with GENERATE IDENTITY clause

CREATE TABLE  fact_table3 (min SMALLINT NOT NULL,
                            max SMALLINT GENERATED ALWAYS AS IDENTITY,
                            CONSTRAINT CC CHECK (min>0))
             PARTITION BY RANGE (min)
               (PART  part1 STARTING FROM (1) ENDING (3) IN tbspace1,
               PART part2 STARTING FROM (4) ENDING (6) IN tbspace2,
               PART part3 STARTING FROM (7) ENDING (9) IN tbspace3);

-- create temporary table

CREATE TABLE temp_table3 (max INTEGER);

----------------------------------------------------------------------------
-- Creating temporary tables for alterTable function
----------------------------------------------------------------------------

-- creates a partitioned table with 'part1' in 'tbspace1', 'part2' in
-- 'tbspace2' and 'part3' in 'tbspace3' with GENERATE IDENTITY clause
-- 'tbspace2' and 'part3' in 'tbspace3' with GENERATE IDENTITY clause

CREATE TABLE  fact_table4 (min SMALLINT NOT NULL,
                            max SMALLINT GENERATED ALWAYS AS IDENTITY,
                            CONSTRAINT CC CHECK (min>0))
             PARTITION BY RANGE (min)
               (PART  part1 STARTING FROM (1) ENDING (3) IN tbspace1,
               PART part2 STARTING FROM (4) ENDING (6) IN tbspace2,
               PART part3 STARTING FROM (7) ENDING (9) IN tbspace3);

-- create temporary tables

CREATE TABLE attach_part (min SMALLINT NOT NULL,
                         max SMALLINT GENERATED ALWAYS AS IDENTITY,
                         CONSTRAINT CC CHECK (min>0)) IN tbspace1;

CREATE TABLE attach(min SMALLINT NOT NULL);

connect reset;
