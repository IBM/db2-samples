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
-- SOURCE FILE NAME: LargeRid_setup.db2
--
-- SAMPLE: This sample serves as the setup script for the sample
--         LargeRid.sqlj 
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--
-- To run this script from the CLP issue the below command:
--            "db2 -tvf LargeRid_setup.db2"
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

connect to sample@

-- create regular DMS table space dms_tspace

CREATE REGULAR TABLESPACE dms_tspace
             MANAGED BY DATABASE
             USING (FILE 'dms_cont.dat' 10000)@

-- create regular DMS table space dms_tspace1

CREATE REGULAR TABLESPACE dms_tspace1
              MANAGED BY DATABASE
              USING (FILE 'dms_cont1.dat' 10000)@

-- create regular DMS table space dms_tspace2

CREATE REGULAR TABLESPACE dms_tspace2
             MANAGED BY DATABASE
             USING (FILE 'dms_cont2.dat' 10000)@

-- create regular DMS table space dms_tspace3

CREATE REGULAR TABLESPACE dms_tspace3
             MANAGED BY DATABASE
             USING (FILE 'dms_cont3.dat' 10000)@

-- create table in 'dms_tspace' regular DMS tablespace

CREATE TABLE large (max INT, min INT) IN dms_tspace@

-- create index

CREATE INDEX large_ind ON large (max)@

-- create a partitioned table in regular DMS tablespaces i.e; part1 is
-- placed at dms_tspace1, part2 is placed at dms_tspace2 and
-- part3 at dms_tspace3

CREATE TABLE large_ptab (max SMALLINT NOT NULL,
                                    CONSTRAINT CC CHECK (max>0))
             PARTITION BY RANGE (max)
               (PART  part1 STARTING FROM (1) ENDING (3) IN dms_tspace1,
               PART part2 STARTING FROM (4) ENDING (6) IN dms_tspace2,
               PART part3 STARTING FROM (7) ENDING (9) IN dms_tspace3)@


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

    END IF;
  END LOOP;

END@

connect reset@
