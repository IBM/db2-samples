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
-- SOURCE FILE NAME: rolloutdata.db2
--
-- SAMPLE: How to perform data-roll-out from a partitioned table.
--
-- SQL STATEMENTS USED:
--         ALTER TABLE
--         CREATE TABLE
--         CREATE TABLESPACE
--         DROP TABLE
--         INSERT
--         TERMINATE
--
-- OUTPUT FILE: rolloutdata.out (available in the online documentation)
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
CONNECT TO sample@

-- Create DMS tablespaces.
CREATE TABLESPACE tbsp1 MANAGED BY DATABASE USING (FILE 'conta' 1000)@
CREATE TABLESPACE tbsp2 MANAGED BY DATABASE USING (FILE 'contb' 1000)@

-- Create a partitioned table on a list of tablespaces. A table 'emp_table'
-- with three partitions will be created i.e. part0 is placed in tbsp1,
-- part1 is placed in tbsp2, and part2 is placed in tbsp1. Data partitions
-- are placed in tablespaces in Round Robin fashion.

CREATE TABLE emp_table (emp_no INTEGER NOT NULL,
                  emp_name VARCHAR(10),
                  dept VARCHAR(5),
                  salary DOUBLE DEFAULT 3.14)
  IN  tbsp1, tbsp2
  PARTITION BY RANGE (emp_no)
    (STARTING FROM (1) ENDING (100),
    STARTING FROM (101) ENDING (200),
    STARTING FROM (201) ENDING (300))@

-- Insert data into 'emp_table'.
INSERT INTO emp_table VALUES
                  (1,   'Sam',  'E31', 3.34),
                  (101, 'James','E32', 4.00),
                  (201, 'Bill', 'E33', 3.75)@

-- Detach a partition from 'emp_table'.
-- ALTER TABLE statement along with DETACH PARTITION clause is used to
-- remove a partition from the base table.
create procedure tableExists (IN schemaName varchar(128), IN tableName varchar(128), OUT notFound int)
  specific tableExists
  language SQL
BEGIN

  declare dpid int;

  declare tabCheck cursor for
      select DATAPARTITIONID from sysibm.sysdatapartitions where tabschema = schemaName and tabname = tableName;
  declare exit handler for NOT FOUND
    set notFound = 1;

  open tabCheck;
  fetch tabCheck into dpid;
  close tabCheck;

END@

create procedure waitForDetach (OUT msg varchar(128), IN schemaName varchar(128), IN tableName varchar(128), IN partName varchar(128) DEFAULT NULL)
  specific waitForDetach
  language SQL
BEGIN

  declare dpid int;
  declare dpstate char;
  declare done int default 0;
  declare tabNotFound int default 0;

  declare allDetachCheck cursor for
      select DATAPARTITIONID, STATUS from sysibm.sysdatapartitions
        where tabschema = schemaName and tabname = tableName and (status = 'L' OR status = 'D');

  declare oneDetachCheck cursor for
      select DATAPARTITIONID, STATUS from sysibm.sysdatapartitions
        where tabschema = schemaName and tabname = tableName and datapartitionname = partName;

  declare continue handler for NOT FOUND
    set done = 1;

  set current lock timeout 120;

  -- if table does not exist in sysdatapartitions, return error
  call tableExists (schemaName, tableName, tabNotFound);
  if tabNotFound = 1
  THEN
    set msg = 'Table not found';
    RETURN -1;
  END IF;

wait_loop:
  LOOP
    if partName IS NOT NULL
    THEN
      open oneDetachCheck;
      fetch oneDetachCheck into dpid, dpstate;

      -- two cases here:
      --  (i) detach has already completed hence partition entry not found in catalogs (indicated by done == 1, handled later)
      -- (ii) detach in progress, partition state should not be visible
      IF done <> 1 AND (dpstate = '' OR dpstate = 'A')
      THEN
        set msg = 'Cannot waitForDetach if DETACH was not issued on this partition';
        return -1;
      END IF;

      close oneDetachCheck;
    ELSE
      open allDetachCheck;
      fetch allDetachCheck into dpid, dpstate;
      close allDetachCheck;
    END IF;
    if done = 1
    THEN
      set msg = 'DETACH completed';
      LEAVE wait_loop;
    ELSE
      ITERATE wait_loop;
    END IF;
  END LOOP;

END@

ALTER TABLE emp_table DETACH PARTITION part1 INTO emp_part0@
CALL waitForDetach(?, CURRENT SCHEMA, 'EMP_TABLE')@

-- Display the contents of each table.
SELECT emp_no, emp_name, dept, salary FROM emp_part0@
SELECT emp_no, emp_name, dept, salary FROM emp_table@

-- Drop the tables.
DROP TABLE emp_part0@
DROP TABLE emp_table@

-- Drop the tablespaces.
DROP TABLESPACE tbsp1@
DROP TABLESPACE tbsp2@

-- Disconnect from database.
CONNECT RESET@

TERMINATE@

