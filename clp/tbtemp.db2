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
-- SOURCE FILE NAME: tbtemp.db2
--
-- SAMPLE: How to use a declared temporary table 
--
-- This sample:
--         1. Creates a user temporary table space required for declared
--            temporary tables
--         2. Creates and populates a declared temporary table
--         3. Shows that the declared temporary table exists after a commit
--            and shows the declared temporary table's use in a procedure
--         4. Shows that the temporary table can be recreated with the same
--            name using the "with replace" option and without "not logged"
--            clause, to enable logging.
--         5. Shows the creation of an index on the temporary table.
--         6. Show the usage of "describe" command to obtain information
--            regarding the temporary table.
--         7. Shows the usage of RUNSTATS command to update statistics
--            about the physical characteristics of a temp table and the
--            associated indexes.
--         8. Shows that the temporary table is implicitly dropped with a
--            disconnect from the database
--         9. Drops the user temporary table space
--
--         The following objects are made and later removed:
--         1. a user temporary table space named usertemp1
--         2. a declared global temporary table named temptb1
--         (If objects with these names already exist, an error message
--         will be printed out.)
-- 
-- SQL STATEMENTS USED:
--         CREATE USER TEMPORARY TABLESPACE
--         CREATE INDEX
--         DECLARE GLOBAL TEMPORARY TABLE
--         DESCRIBE
--         DROP TABLESPACE
--         INSERT
--         SELECT 
--         TERMINATE
--
-- OUTPUT FILE: tbtemp.out (available in the online documentation)
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

-- turn off the Auto-commit option
UPDATE COMMAND OPTIONS USING c OFF;

-- create a user temporary table space for the temporary table.  A user
-- temporary table space is required for temporary tables. This type of
-- table space is not created at database creation time. 

CREATE USER TEMPORARY TABLESPACE usertemp1
  MANAGED BY SYSTEM
  USING ('usertemp');

-- declare a temporary table with the same columns as in the 'department'
-- table. Populate the temporary table and show the contents.

DECLARE GLOBAL TEMPORARY TABLE temptb1
  LIKE department
  NOT LOGGED;

-- populating the temporary table is done the same way as a normal table
-- except the qualifier 'session' is required whenever the table name
-- is referenced. 

INSERT INTO session.temptb1
  (SELECT deptno, deptname, mgrno, admrdept, location
     FROM department);

-- show the contents of the temporary table 

SELECT * FROM session.temptb1;

-- show that the temporary table still exists after the commit. All the
-- rows will be deleted because the temporary table was declared, by default,
-- with "ON COMMIT DELETE ROWS".  If 'ON COMMIT PRESERVE ROWS' was used,
-- then the rows would have remained.  

COMMIT;

-- show the contents of the temporary table

SELECT * FROM session.temptb1;

-- declare the declared temporary table again, this time with the 'ON COMMIT 
-- PRESERVE ROWS' clause and without the NOT LOGGED clause to enable logging. 
-- it is created empty. The old one will be dropped and a new one will be 
-- made. If the "WITH REPLACE" option is not used, then an error will result
-- if the table name is already associated with an existing temporary table. 

DECLARE GLOBAL TEMPORARY TABLE temptb1
  LIKE department
  WITH REPLACE
  ON COMMIT PRESERVE ROWS;

-- populate the temporary table 

INSERT INTO session.temptb1
  (SELECT deptno, deptname, mgrno, admrdept, location
     FROM department);

-- show the contents of the temporary table

SELECT * FROM session.temptb1;

-- create an index for the global temporary table

-- indexes can be created for temporary tables. Indexing a table optimizes
-- query performance

CREATE INDEX session.tb1ind
             ON session.temptb1(deptno DESC)
             DISALLOW REVERSE SCANS;

-- following clauses in create index are not supported for temporary tables:
--                   SPECIFICATION ONLY
--                   CLUSTER
--                   EXTEND USING
-- option SHRLEVEL will have no effect when creating indexes on DGTTs and 
-- will be ignored                   

-- indexes can be dropped by issuing DROP INDEX statement, or they will be
-- implicitly dropped when the underlying temporary table is dropped.

-- RUNSTATS updates statistics about the characteristics of the temp
-- table and/or any associated indexes. These characteristics include,
-- among many others, number of records, number of pages, and average
-- record length.

RUNSTATS ON TABLE session.temptb1 FOR INDEXES ALL;

-- viewing of runstats data on declared temporary tables or indexes on 
-- declared temporary tables is not supported

-- use the DESCRIBE command to describe the temporary table created.
-- DESCRIBE TABLE command cannot be used with temp table.However,
-- DESCRIBE statement can be used with SELECT statement to get
-- table information.

DESCRIBE SELECT * FROM session.temptb1;

-- disconnect from the database. This implicitly drops the temporary table.
-- alternatively, an explicit DROP statement could have been used.

CONNECT RESET;

-- connect to database
CONNECT TO sample;

-- clean up - remove the table space that was created earlier.
-- note: The table space can only be dropped after the temporary table is
-- dropped.

DROP TABLESPACE usertemp1;

-- disconnect from the database 

CONNECT RESET;

TERMINATE;

