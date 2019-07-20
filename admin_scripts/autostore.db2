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
-- SOURCE FILE NAME: autostore.db2
--    
-- SAMPLE: How to create, backup & restore databases enabled with 
--         automatic storage. 
--
-- SQL STATEMENT USED:
--          ALTER DATABASE
--          ALTER TABLESPACE
--          BACKUP DATABASE
--          CONNECT RESET
--          CONNECT TO  
--          CREATE DATABASE
--          CREATE TABLESPACE
--          DROP DATABASE
--          DROP TABLESPACE
--          GET SNAPSHOT FOR
--          RESTORE DATABASE         
-- 
-- OUTPUT FILE: autostore.out (available in the online documentation)
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

-- If automatic storage option is set as NO, then only one storage path can be
-- specified to be used for creation of database
-- The storage paths must exist before CREATE DATABASE command is executed

-- Create the storage paths

!mkdir $HOME/storpath1;
!mkdir $HOME/storpath2;
!mkdir $HOME/storpath3;
!mkdir $HOME/dbpath;

-- Create a database enabled for automatic storage with two storage paths and
-- on a specified database path 
-- The storage paths used are: $HOME/storpath1, $HOME/storpath2
-- The database path use is  : $HOME/dbpath

! db2 CREATE DATABASE autodb AUTOMATIC STORAGE YES ON 
        $HOME/storpath1, $HOME/storpath2 DBPATH ON $HOME/dbpath;

CONNECT TO autodb;

-- Create a tablespace enabled for automatic storage. If no MANAGED BY clause 
-- is specified the tablespace is, by default, managed by automatic storage.
CREATE TABLESPACE TS1;

-- Create another tablespace enabled to auto-resize
-- TS2 is created with an initial size of 100 MB and with a maximum size of 1 GB
-- (By default AUTORESIZE is set to YES)
CREATE TABLESPACE TS2 INITIALSIZE 100 M MAXSIZE 1 G; 

-- Create tablespace without auto-resize enabled 
CREATE TABLESPACE TS3 AUTORESIZE NO;

-- Create tablespace enabled to auto-resize without any upper bound on 
-- maximum size 
CREATE TABLESPACE TS4
  MANAGED BY DATABASE
  USING (FILE 'TS3File' 1000)
  AUTORESIZE YES
  MAXSIZE NONE;

-- Alter tablespace to increase its size by 5 percent
ALTER TABLESPACE TS4 INCREASESIZE 5 PERCENT;

-- Alter database to add one more storage path, $HOME/storpath3, to the
-- existing space for automatic storage table spaces
-- Running the ALTER DATABASE statement in a shell as path substitution
-- can be done inside a sheell

!db2 "CONNECT TO AUTODB"; 
!db2 "ALTER DATABASE autodb ADD STORAGE ON '$HOME/storpath3'";


-- Check the status information of tablespaces for database AUTODB
GET SNAPSHOT FOR TABLESPACES ON autodb;

-- Disconnect from database
!db2 "CONNECT RESET";

-- Backup the database
BACKUP DATABASE autodb;

-- Connect to database
CONNECT TO autodb;

-- Drop the tablespaces
DROP TABLESPACE TS1;
DROP TABLESPACE TS2;
DROP TABLESPACE TS3;
DROP TABLESPACE TS4;

-- Disconnect from database
CONNECT RESET;

-- Drop the database
-- DROP DATABASE autodb;

-- Restore the database to a set of storage paths

! db2 "RESTORE DATABASE autodb ON '$HOME/storpath2', '$HOME/storpath3'
        DBPATH ON '$HOME/dbpath' WITHOUT PROMPTING";

-- Drop the database 'AUTODB'
DROP DB AUTODB;

-- Remove the directories.

!rm -rf $HOME/storpath1;
!rm -rf $HOME/storpath2;
!rm -rf $HOME/storpath3;
!rm -rf $HOME/dbpath;

TERMINATE;

