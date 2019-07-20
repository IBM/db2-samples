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
-- SOURCE FILE NAME: autorestore.db2
--    
-- SAMPLE: How to restore a database with automatic storage. 
--
-- SQL STATEMENT USED:
--         CREATE DATABASE
--         DROP DATABASE
--         RESTORE DATABASE
--         BACKUP DATABASE
--         TERMINATE
--
-- Note: This sample requires an MPP environment with 3 nodes. 
--
-- OUTPUT FILE: autorestore.out (available in the online documentation)
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

-- Following directories will be used for restoring the database on new
-- storage paths.
!mkdir $HOME/storpath1;
!mkdir $HOME/storpath2;
!mkdir $HOME/dbpath;
!mkdir $HOME/storpath3;
!mkdir $HOME/storpath4;
!mkdir $HOME/storpath5;
!mkdir $HOME/storpath6;

-- Create a database enabled for automatic storage with two storage paths and
-- on a specified database path.
-- The storage paths used are: $HOME/storpath1, $HOME/storpath2
-- The database path use is  : $HOME/dbpath

! db2 CREATE DATABASE TESTDB AUTOMATIC STORAGE YES ON 
        $HOME/storpath1, $HOME/storpath2 DBPATH ON $HOME/dbpath;

-- Backup the database 'TESTDB' on all partitions.
! db2_all "db2 BACKUP DATABASE TESTDB";

-- The sample demonstrates three scenarios of database restore.
-- CASE 1: Database with automatic storage enabled pre-exists. User wants
-- to restore all db partitions, using old storage paths.
-- User can issue restore on each db partition in any order, or in parallel.

-- Use 'db2_all' utility to execute restore on all partitions.
-- A warning is expected for all restore commands as the database is
-- identical to the backup.
-- Following command will be executed on all db partitions.
! db2_all "db2 RESTORE DATABASE TESTDB WITHOUT PROMPTING";

-- CASE 2: Database with automatic storage enabled pre-exists.User wants to
-- restore from the catalog partition, using a new set of storage paths.

-- Use 'db2_all' utility to execute restore command on individual partitions.
-- Following command will be executed on partition 0(catalog partition).
! db2_all "<<+0<db2 RESTORE DATABASE TESTDB ON $HOME/storpath3,
                                               $HOME/storpath4
                      WITHOUT PROMPTING";

-- Following command will be executed on partition 1(non-catalog partition).
! db2_all "<<+1<db2 RESTORE DATABASE TESTDB WITHOUT PROMPTING";

-- Following command will be executed on partition 2(non-catalog partition).
! db2_all "<<+2<db2 RESTORE DATABASE TESTDB WITHOUT PROMPTING";

-- CASE 3: Database with automatic storage enabled pre-exists.User performs
-- a restore on a non-catalog partition, specifying a list of paths.
-- In this case, restore will fail for non-catalog partitions as new storage
-- paths can only be specified for catalog-partition.

-- Following command will be executed on partition 1(non-catalog partition).
-- SQL1172N is expected for the following command.
! db2_all "<<+1<db2 RESTORE DATABASE TESTDB ON $HOME/storpath5,
                                               $HOME/storpath6
                      WITHOUT PROMPTING";

-- Following command will be executed on partition 2(non-catalog partition).
-- SQL1172N is expected for the following command.
! db2_all "<<+2<db2 RESTORE DATABASE TESTDB ON $HOME/storpath5,
                                               $HOME/storpath6
                      WITHOUT PROMPTING";

-- Drop the database 'TESTDB'
DROP DB TESTDB;

-- Remove the directories.

!rm -rf $HOME/storpath1;
!rm -rf $HOME/storpath2;
!rm -rf $HOME/dbpath;
!rm -rf $HOME/storpath3;
!rm -rf $HOME/storpath4;
!rm -rf $HOME/storpath5;
!rm -rf $HOME/storpath6;

TERMINATE;


