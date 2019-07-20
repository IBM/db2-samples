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
-- SAMPLE FILE NAME: redistribute_cmd.db2 
--
-- PURPOSE         : To demonstrate how to redistribute the table data among 
--                   database partitions in a partitioned database environment 
--                   using REDISTRIBUTE DATABASE PARTITION GROUP command.  
--
-- USAGE SCENARIO  : The customer database initially has two partitions (0, 1)
--                   and a database partition group that is defined on (0, 1). 
--                   Due to business requirements the customer decides to add 
--                   a new partition to the existing database partition group 
--                   and redistribute the data in the database partition group.
--                   As the system has a very small maintenance window, 
--                   redistribution of table data can be done gradually.
--                   During redistribution, the customer wants to collect the
--                   statistics, rebuild the indexes and limit the data buffer
--                   to certain percentage of the utility heap.
--
--                   This sample demonstrates the operations described in the 
--                   above scenario.
--
-- PREREQUISITE    : Redistribute cannot work on single partition system. 
--                   This sample has to be run on multiple database partitions.
--                   The partition numbers need to be 0, 1, 2 and 3. 
--
-- EXECUTION       : db2 -tvf redistribute_cmd.db2 
--
-- INPUTS          : NONE
--
-- OUTPUTS         : Redistributes data into different database partitions.
--
-- OUTPUT FILE     : redistribute_cmd.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--                   BACKUP DATABASE
--                   CREATE DATABASE PARTITION GROUP
--                   CREATE INDEX
--                   CREATE TABLESPACE
--                   CREATE TABLE
--                   DROP TABLE
--                   DROP TABLESPACE
--                   DROP DATABASE PARTITION GROUP
--                   INSERT
--                   LIST DBPARTITIONNUMS
--                   REDISTRIBUTE DATABASE PARTITION GROUP
--                   TERMINATE
-- ****************************************************************************
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
-- http://www.software.ibm.com/data/db2/udb/ad
-- ****************************************************************************
--  SAMPLE DESCRIPTION
-- ****************************************************************************
-- The sample demonstrates the use and behavior of the various command options 
-- of the REDISTRIBUTE DATABASE PARTITION GROUP command including:
-- ADD, DROP, STOP AT, PARALLEL TABLE, FIRST | ONLY, STATISTICS USE PROFILE,
-- INDEXING MODE, DATA BUFFER MODE and COMPACT.

-- *NOTE: Perform a full database backup before executing REDISTRIBUTE DATABASE
-- PARTITION GROUP command, since this utility is not forward recoverable.
-- If no back up is taken and there is a catastrophic failure during 
-- REDISTRIBUTE DATABASE PARTITION GROUP command, then database containers may
-- be lost due to bad disk and there could be data loss.
-- ****************************************************************************
--  SETUP
-- ****************************************************************************
-- Connect to sample database.
CONNECT TO SAMPLE;

-- ****************************************************************************

-- Get the list of partitions. 
-- The below statement results in a list of 3 database partitions.
LIST DBPARTITIONNUMS; 

-- Create database partition group 'dbpg_1' on database partition (0, 1).
CREATE DATABASE PARTITION GROUP dbpg_1 ON dbpartitionnum (0,1);

-- Create table space 'tbsp1' in database partition group 'dbpg_1'.
CREATE TABLESPACE tbsp1 IN DATABASE PARTITION GROUP dbpg_1;

-- Create table space 'tbsp2' in database partition group 'dbpg_1'.
CREATE TABLESPACE tbsp2 IN DATABASE PARTITION GROUP dbpg_1;

-- Create table 'temp.tab_temp1' in tablespace 'tbsp1'.
CREATE TABLE temp.tab_temp1 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp1;

-- Populate table 'temp.tab_temp1' with the following data.
INSERT INTO temp.tab_temp1 VALUES ('a', 'b', 'c', 'd', 'e',
                              'f', 'g', 'h', 'i', 'j' );

-- Create index on 'temp.tab_temp1';
CREATE INDEX tab_temp1_index ON temp.tab_temp1 (c3);

-- Create table 'temp.tab_temp2' in tablespace 'tbsp1'.
CREATE TABLE temp.tab_temp2 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp1;

-- Populate table 'temp.tab_temp2' with the following data.
INSERT INTO temp.tab_temp2 VALUES ('k', 'l', 'm', 'n', 'o',
                              'p', 'q', 'r', 's', 't' );

-- Create table 'temp.tab_temp3' in tablespace 'tbsp2'.
CREATE TABLE temp.tab_temp3 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp2;

-- Populate table 'temp.tab_temp3' with the following data.
INSERT INTO temp.tab_temp3 VALUES ('u', 'v', 'w', 'x', 'y',
                              'z', 'a', 'b', 'c', 'd' );

-- Create index on 'temp.tab_temp3';
CREATE INDEX tab_temp3_index ON temp.tab_temp3 (c1);

-- Create table 'temp.tab_temp4' in tablespace 'tbsp2'.
CREATE TABLE temp.tab_temp4 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp2;

-- Populate table 'temp.tab_temp4' with the following data.
INSERT INTO temp.tab_temp4 VALUES ('a', 'b', 'c', 'd', 'e',
                              'f', 'g', 'h', 'i', 'j' );

-- Create table 'temp.tab_temp5' in tablespace 'tbsp2'.
CREATE TABLE temp.tab_temp5 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp2;

-- Populate table 'temp.tab_temp5' with the following data.
INSERT INTO temp.tab_temp5 VALUES ('k', 'l', 'm', 'n', 'o',
                              'p', 'q', 'r', 's', 't' );

-- Create index on 'temp.tab_temp5';
CREATE INDEX tab_temp5_index ON temp.tab_temp5 (c8);

-- Create table 'temp.tab_temp6' in tablespace 'tbsp1'
CREATE TABLE temp.tab_temp6 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp1;

-- Populate table 'temp.tab_temp6 with the following data.
INSERT INTO temp.tab_temp6 VALUES ('u', 'v', 'w', 'x', 'y',
                              'z', 'a', 'b', 'c', 'd' );

-- Take full database backup before executing the REDISTRIBUTE DATABASE
-- PARTITION GROUP command since REDISTRIBUTE DATABASE PARTITION GROUP
-- command is not forward recoverable.
CONNECT RESET;
BACKUP DATABASE sample;

-- Connect to sample database.
CONNECT TO SAMPLE;

-- The below command will add new database partition (2) to group 'dbpg_1' 
-- and change the group definition from (0, 1) to (0, 1, 2) and 
-- redistribute all the tables data into these partitions. 
-- INDEXING MODE parameter specifies how indexes are maintained during 
-- redistribute. REBUILD specifies that index pages will be clustered 
-- together on the disk. Indexes do not need to be valid to use this
-- option and indexes will be rebuilt from scratch.
REDISTRIBUTE DATABASE PARTITION GROUP dbpg_1 NOT ROLLFORWARD RECOVERABLE UNIFORM
  ADD dbpartitionnum(2)
  INDEXING MODE REBUILD;
 
-- The below command will add partition 3. This will redistribute 
-- tables 'temp.tab_temp6' and 'temp.tab_temp5' only with 5000 4K utility heap pages per 
-- table. 

-- The command below throws the following waring:
-- SQL1379W  Database partition group "DBPG_1" has been partially redistributed.
-- The number of tables redistributed is "2", and the number of tables yet to be
-- redistributed is "4". Reason code = "1". 

REDISTRIBUTE DATABASE PARTITION GROUP dbpg_1  NOT ROLLFORWARD RECOVERABLE UNIFORM
  ADD dbpartitionnums (3)
  TABLE (temp.tab_temp6, temp.tab_temp5) ONLY
  DATA BUFFER 5000;
!echo "Above warning is expected !";

-- Tables 'temp.tab_temp6' and 'temp.tab_temp5' are redistributed now.
-- Tables 'temp.tab_temp1', 'temp.tab_temp2', 'temp.tab_temp3' and 'temp.tab_temp4' are not
-- yet redistributed. The following command will first redistribute data on 
-- table 'temp.tab_temp1' and later redistributes the data on other tables in 
-- 'dbpg_1' in a arbitrary order.
REDISTRIBUTE DATABASE PARTITION GROUP dbpg_1 NOT ROLLFORWARD RECOVERABLE CONTINUE 
  TABLE (temp.tab_temp1) FIRST; 

-- Get the time statistic for table 'temp.tab_temp1'.
SELECT stats_time FROM SYSIBM.SYSTABLES WHERE name = 'TAB_TEMP1'
  ORDER BY NAME;

-- Perform RUNSTATS to make a profile and collect statistics at the same time. 
RUNSTATS ON TABLE temp.tab_temp1 WITH DISTRIBUTION DEFAULT NUM_FREQVALUES 50 
  AND SAMPLED DETAILED INDEXES ALL SET PROFILE;

-- Collect statistics for tables with statistic profile.
REDISTRIBUTE DATABASE PARTITION GROUP dbpg_1 NOT ROLLFORWARD RECOVERABLE UNIFORM
  DROP dbpartitionnums (3) STATISTICS USE PROFILE;

-- Get the time statistic for table 'temp.tab_temp1' after redistributing the data.
SELECT stats_time FROM SYSIBM.SYSTABLES WHERE name = 'TAB_TEMP1'
  ORDER BY NAME;

-- Redistribute will not only move records to their target partitions, 
-- but also uses the staying records from the logical end of the table to 
-- fill up holes. On completion of this command, tables data will be 
-- redistributed in partitions (0, 1) only. 
-- Partition 2 will be dropped from the database group 'dbpg_1'.
REDISTRIBUTE DATABASE PARTITION GROUP dbpg_1 NOT ROLLFORWARD RECOVERABLE UNIFORM
  DROP dbpartitionnums (2);

-- The below command will redistribute the tables' data into all remaining 
-- partitions (0 and 1) and into partitions (2 and 3) uniformly. 
-- The STOP AT option will stop data redistribution at the time specified
-- in the command.

-- The command below throws the following warning:
-- SQL1379W  Database partition group "DBPG_1" has been partially redistributed.
-- The number of tables redistributed is "0", and the number of tables yet to be
-- redistributed is "6". Reason code = "2". 
REDISTRIBUTE DATABASE PARTITION GROUP dbpg_1 NOT ROLLFORWARD RECOVERABLE UNIFORM
  ADD dbpartitionnums (2, 3)
  STOP AT 2007-04-02-04.00.00.000000;

!echo "Above warning is expected !";

-- The below command will abort redistribution of data on database partition
-- group level and undo tables 'temp.tab_temp1', 'temp.tab_temp2', 'temp.tab_temp3',
-- 'temp.tab_temp4' and 'temp.tab_temp5'. Once this is done, all the tables will be back
-- to their original state i.e. all tables data will be distributed only in
-- partition number (0 and 1).
-- The ABORT option in the following REDISTRIBUTE DATABASE PARTITION GROUP 
-- command is only appropriate if the STOP AT option in the previous 
-- REDISTRIBUTE DATABASE PARTITION GROUP command caused the utility to 
-- terminate before it had fully redistributed the entire database partition 
-- group.
REDISTRIBUTE DATABASE PARTITION GROUP dbpg_1 NOT ROLLFORWARD RECOVERABLE ABORT;

-- Drop tables.
DROP TABLE temp.tab_temp1;
DROP TABLE temp.tab_temp2;
DROP TABLE temp.tab_temp3;
DROP TABLE temp.tab_temp4;
DROP TABLE temp.tab_temp5;
DROP TABLE temp.tab_temp6;

-- Drop table spaces.
DROP TABLESPACE tbsp1;
DROP TABLESPACE tbsp2;

-- Drop database partition group.
DROP DATABASE PARTITION GROUP dbpg_1;

-- Disconnect from the sample database.
CONNECT RESET;
TERMINATE;
