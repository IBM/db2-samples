-- ****************************************************************************
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
-- ****************************************************************************
--
-- SAMPLE FILE NAME: tbsreduce.db2
--
-- PURPOSE         : To demonstrate how unused storage at the end of a table
--                   space can be freed up and reused.
--
-- USAGE SCENARIO  : Reclaim space from dropped tables. 
--                   User can drop old tables in the table space and reclaim 
--                   the space held by the dropped tables. User can perform
--                   'ALTER TABLESPACE REDUCE' on the table space to reclaim 
--                   the space of the dropped tables.
--                   This sample shows how users can reuse this space for 
--                   the creation of new tables in the table space.
--
-- PREREQUISITE    : NONE
--
-- EXECUTION       : db2 -tvf tbsreduce.db2
--
-- INPUTS          : NONE
--
-- OUTPUTS         : 
--
-- OUTPUT FILE     : tbsreduce.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--                   ALTER TABLESPACE
-- 	             CREATE TABLE
--                   CREATE TABLESPACE
--		     DROP TABLE
--		     DROP TABLESPACE
--		     INSERT
--                   SELECT
--                   UPDATE
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
--  1. How to utilize the unused space of a table space created with 
--     AUTOMATIC STORAGE.
--  2. How to utilize the unused space of a table space created with DATABASE
--     MANAGED SPACE.
-- ****************************************************************************
--    SETUP
-- ****************************************************************************
-- Set auto-commit of SQL statements to OFF.
UPDATE COMMAND OPTIONS USING c OFF;

-- Create database.
!db2start;
CREATE DB testdb1;

-- Connect to database.
CONNECT TO testdb1;

-- ****************************************************************************
--  1. How to utilize the unused space of a table space created with
--     AUTOMATIC STORAGE.
-- ****************************************************************************

-- Create table space 'tbsp_auto' managed by AUTOMATIC STORAGE.
CREATE TABLESPACE tbsp_auto PAGESIZE 4096 MANAGED BY AUTOMATIC STORAGE 
  EXTENTSIZE 2 AUTORESIZE NO INITIALSIZE 107K;

-- Create table 'tab_auto1' in table space 'tbsp_auto'.
CREATE TABLE tab_auto1 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp_auto;

-- Populate table 'tab_auto1' with the following data.
INSERT INTO tab_auto1 VALUES ('a', 'b', 'c', 'd', 'e', 
                              'f', 'g', 'h', 'i', 'j' );

-- Create table 'tab_auto2' in table space 'tbsp_auto'.
CREATE TABLE tab_auto2 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp_auto;

-- Populate table 'tab_auto2' with data so that the table space is full.
-------------------------------------------------------------------------------
-- Table space 'tbsp_auto' will be full after the five INSERT statements shown 
-- below. Creation of new tables in table space 'tbsp_auto' will fail with an
-- error: "Unable to allocate new pages in table space".
-------------------------------------------------------------------------------
INSERT INTO tab_auto2 VALUES ('a', 'b', 'c', 'd', 'e', 
                              'f', 'g', 'h', 'i', 'j' );
INSERT INTO tab_auto2 (SELECT * FROM tab_auto2);
INSERT INTO tab_auto2 (SELECT * FROM tab_auto2);
INSERT INTO tab_auto2 (SELECT * FROM tab_auto1);
INSERT INTO tab_auto2 (SELECT * FROM tab_auto2);

-- Create table 'tab_auto3' in table space 'tbsp_auto'. Table creation 
-- will fail with the following error:
-- "Unable to allocate new pages in table space".
CREATE TABLE tab_auto3 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp_auto;

! echo "Above error is expected !";

-- Take a snapshot of the table space. This will give details such as:
-- table space name, high water mark, extent size, used pages, free pages, 
-- pending free pages for table space 'tbsp_auto'.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_AUTO', -1)) AS mon_get_tablespace ;

-- Drop tables 'tab_auto1' and 'tab_auto2'. 
-- Take a table space snapshot to show the HWM hasn't changed after performing a 
-- drop. The above and below snapshots show the same value for the HWM. 
DROP TABLE tab_auto2;
DROP TABLE tab_auto1;

SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_AUTO', -1)) AS mon_get_tablespace ;

-- Try to create new table 'tab_auto3' in the table space 'tbsp_auto'.
-- This will fail with the error: 
-- "Unable to allocate new pages in table space" because there isn't any 
-- free space available to accomodate the new table. 
CREATE TABLE tab_auto3 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp_auto;

! echo "Above error is expected !";

-- Perform REDUCE on 'tbsp_auto'. This will fail with an error:
-- "The table space could not be reduced in size". 
-- Table space cannot be reduced in size until the transaction containing the
-- DROP TABLE statements is committed.  
-- After the transaction is committed, the space can be reused and new 
-- tables can be created.
ALTER TABLESPACE tbsp_auto REDUCE;

! echo "Above error is expected !";

-- Perform a COMMIT to permanently free extents used by the dropped tables and
-- allow the table space to be reduced in size.
-- The COMMIT will not reduce the HWM. The HWM will remain the same until a 
-- REDUCE is performed on the table space.   
COMMIT;

-- Take a table space snapshot to show the HWM hasn't changed after 
-- performing COMMIT.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_AUTO', -1)) AS mon_get_tablespace ;

-- Perform REDUCE on table space 'tbsp_auto' to reduce HWM. 
ALTER TABLESPACE tbsp_auto REDUCE;

-- Take a table space snapshot to show the HWM has been reduced after
-- performing REDUCE on table space 'tbsp_auto'. 
-- Pending free pages will be freed after REDUCE. After this is done,
-- creation of a new table in the table space will be successful.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_AUTO', -1)) AS mon_get_tablespace ;

-- New tables can now be created in the table space 'tbsp_auto' since 
-- space has been reclaimed by the REDUCE operation. 
-- Create table 'tab_auto3'. The size of the new table should be either 
-- less than, or almost the same size as, the dropped tables.
-- Table creation will now be successful.
CREATE TABLE tab_auto3 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                         c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                         c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                         c10 char( 250 ) )
  IN tbsp_auto;

-- Take a table space snapshot to show that the HWM has changed after
-- the new table was created.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_AUTO', -1)) AS mon_get_tablespace ;

-- Drop table 'tab_auto3'.
DROP TABLE tab_auto3;

-- Drop table space 'tbsp_auto'.
DROP TABLESPACE tbsp_auto;

-- ****************************************************************************
--  2. How to utilize the unused space of a table space created with DATABASE
--     MANAGED SPACE.
-- ****************************************************************************

-- Create table space 'tbsp_dms' managed by database.
CREATE TABLESPACE tbsp_dms PAGESIZE 4096 
  MANAGED BY database using (file 'mycontainer' 28) EXTENTSIZE 2 AUTORESIZE NO;

-- Create table 'tab_1' in the table space 'tbsp_dms'.
CREATE TABLE tab_1 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                     c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                     c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                     c10 char( 250 ) ) 
  IN tbsp_dms;

-- Populate the table 'tab_1' with the following data.
INSERT INTO tab_1 VALUES ('a', 'b', 'c', 'd', 'e', 'f', 'g', 'h', 'i', 'j' );
INSERT INTO tab_1 (SELECT * FROM tab_1);
INSERT INTO tab_1 (SELECT * FROM tab_1);
INSERT INTO tab_1 (SELECT * FROM tab_1);

-- Create table 'tab_2' in table space 'tbsp_auto'.
CREATE TABLE tab_2 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                     c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                     c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                     c10 char( 250 ) )
  IN tbsp_dms;

-- Populate the table with data so that the container is full. Creation of new 
-- tables in the table space will fail with the error:
-- "Unable to allocate new pages in table space".
INSERT INTO tab_2 (select * from tab_1);

-- Try creating new table 'tab_3'. It will fail with the error:
-- "Unable to allocate new pages in table space".
CREATE TABLE tab_3 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                     c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                     c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                     c10 char( 250 ) )
  IN tbsp_dms;

! echo "Above error is expected !";

-- Commit the transaction.
COMMIT;

-- Take a snapshot of the table space. This gives details such as: 
-- table space name, high water mark, extent size, used pages, free pages,
-- pending free pages for table space 'tbsp_dms'.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME, 
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,  
       tbsp_free_pages, tbsp_pending_free_pages 
  FROM TABLE (mon_get_tablespace ('TBSP_DMS', -1)) AS mon_get_tablespace ;

-- Drop table 'tab_2' and take a table space snapshot to show that the HWM 
-- hasn't changed after dropping the table. The above and below snapshots show 
-- the same value for HWM.
DROP TABLE tab_2;

SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,  
       tbsp_free_pages, tbsp_pending_free_pages 
  FROM TABLE (mon_get_tablespace ('TBSP_DMS', -1)) AS mon_get_tablespace ;

-- Try creating new table 'tab_3'. It will fail with the error: 
-- "Unable to allocate new pages in table space".
CREATE TABLE tab_3 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                     c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                     c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                     c10 char( 250 ) )
  IN tbsp_dms;

! echo "Above error is expected !";

-- Perform REDUCE on table space 'tbsp_dms'. This will result in the error:
-- "There is no enough space in the table space "TBSP_DMS". The amount of 
-- space being removed is greater than the amount of space above the 
-- high-water mark". The error occurs because the transaction has not been
-- committed and there isn't any free space on which to perform a REDUCE
-- statement.
ALTER TABLESPACE tbsp_dms REDUCE (FILE 'mycontainer' 3);

! echo "Above error is expected !";

-- Perform COMMIT to make the free space available and allow the table 
-- space to be reduced in size.
-- COMMIT will not reduce the HWM. The HWM will remain the same until a 
-- REDUCE is performed on the table space.   
COMMIT;

-- Take a table space snapshot to show the HWM hasn't changed after 
-- performing COMMIT.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages, 
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_DMS', -1)) AS mon_get_tablespace ;

-- Perform REDUCE on the table space 'tbsp_dms' to reduce the HWM and 
-- to free pending pages.
ALTER TABLESPACE tbsp_dms REDUCE (FILE 'mycontainer' 3);

-- Take a table space snapshot to show the HWM has been reduceed after
-- performing a REDUCE on table space 'tbsp_dms'. 
-- Pending free pages will be freed after a REDUCE. After this is done,
-- creation of a new table in the table space will be successful.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_DMS', -1)) AS mon_get_tablespace ;

-- Create table 'tab_3'. The size of the table should be either 
-- less than, or almost the same size as, the dropped table.
-- Table creation will now be successful.
CREATE TABLE tab_3 ( c1 char( 250 ),c2 char( 250 ),c3 char( 250 ),
                     c4 char( 250 ),c5 char( 250 ),c6 char( 250 ),
                     c7 char( 250 ),c8 char( 250 ),c9 char( 250 ),
                     c10 char( 250 ) )
  IN tbsp_dms;

-- Take a table space snapshot to show that the HWM has changed after
-- the new table was created.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_DMS', -1)) AS mon_get_tablespace ;

-- Drop table 'tab_1'
DROP TABLE tab_1;

-- Commit the transaction.
COMMIT;

-- Perform REDUCE on table space 'tbsp_dms'.
ALTER TABLESPACE tbsp_dms REDUCE (FILE 'mycontainer' 3);

-- Take a table space snapshot to show that the HWM has not been reduced and 
-- is the same as in the previous table space snapshot. The HWM will not be 
-- reduced because it is held static by table 'tab_3'. So before table 'tab_1' 
-- is dropped, table 'tab_3' needs to be dropped.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_DMS', -1)) AS mon_get_tablespace ;

-- Drop table 'tab_3'.
DROP TABLE tab_3;

-- Commit the transaction.
COMMIT;

-- Perform REDUCE on table space 'tbsp_dms'.
ALTER TABLESPACE tbsp_dms REDUCE (FILE 'mycontainer' 3);

-- Take a table space snapshot to show that the HWM has been reduced after table
-- 'tab_3' was dropped.
SELECT SUBSTR (tbsp_name, 1, 10) AS TBSP_NAME,
       tbsp_page_top, tbsp_extent_size, tbsp_used_pages,
       tbsp_free_pages, tbsp_pending_free_pages
  FROM TABLE (mon_get_tablespace ('TBSP_DMS', -1)) AS mon_get_tablespace ;

-- Drop table space 'tbsp_dms'.
DROP TABLESPACE tbsp_dms;

-- Disconnect from database.
CONNECT RESET;

-- Drop database.
DROP DB testdb1;
TERMINATE;
