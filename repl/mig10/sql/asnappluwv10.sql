--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version V10 (DB2 V10) for Linux, UNIX AND Windows            */
--                                                                   */
--     Sample SQL Replication migration script for UNIX AND NT       */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 2011. All Rights Reserved             */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate SQL Apply tables from V97 to V10.
--
-- IMPORTANT:
-- * Please refer to the SQL Rep migration doc before attempting this migration.
-- * DB2 V10 has many internal changes and requires a cold start of SQL Capture.
--   There are steps that can be performed to work around a full refresh by SQL Apply.
--
-- Most of the V10 migration is related to increase in the DB2 LSN length 
-- from 10 bytes to 16 bytes. Consequently all of the replication synchpoints and 
-- LSN columns need to change from CHAR(10) for bit data to VARCHAR(16) for bit data.
--
-- AFTER UPGRADING to DB2 and SQL Apply program V10, you are ready to start 
-- SQL Apply migration.
--
-- You will do this migration in three parts. 
--
-- PART 1: 
-- * Migrate the Apply control tables. This includes: alter all the LSN and
--   synchpoint columns to VARCHAR(16) for bit data, add some new columns, and add a new table.
-- * At this point, Apply will continue to expect LSN and synchpoint columns with
--   10 byte length values.
-- * Run Part 1A at the Apply control server.  
-- * Run Part 1B at the target server if you have CCD target tables.
--
-- If you are running any pre-V10 Captures, DO NOT RUN PART 2 OR PART 3 YET.
--
-- PART 2: 
-- * This part for the Apply control server is run only when you are ready to 
--   also run V10 Capture migration's Part 2 on the Capture server.
--   This part completes the move to 16 byte values for a given Apply program by Apply Qualifier. 
-- * Here you run sql to concatenate x'0's to LSN and synchpoint columns.  Apply V10 will check
--   Capture's IBMSNAP_CAPPARMS table for COMPATIBILITY='1001'.
-- * Run Part 2A and Part 2B below.
--
-- PART 3: 
-- * This part is run on the target server if you have CCD target tables.  
-- * You need to migrate the SEQ columns to 16 byte LSN values.
-- * This part is run at the same time as part 2.
--
--***********************************************************
-- Migrate SQL Apply to V10 Part 1A
--***********************************************************

-- IBMSNAP_APPPARMS

ALTER TABLE ASN.IBMSNAP_APPPARMS 
  ADD COLUMN REFRESH_COMMIT_CNT INT DEFAULT NULL;

-- IBMSNAP_SUBS_SET
ALTER TABLE ASN.IBMSNAP_SUBS_SET 
	ALTER COLUMN SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
	
REORG TABLE ASN.IBMSNAP_SUBS_SET;

-- IBMSNAP_SUBS_EVENT
ALTER TABLE ASN.IBMSNAP_SUBS_EVENT 
	ALTER COLUMN END_SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
	
REORG TABLE ASN.IBMSNAP_SUBS_EVENT;

-- IBMSNAP_APPLYTRAIL
ALTER TABLE ASN.IBMSNAP_APPLYTRAIL 
	ALTER COLUMN SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
	
REORG TABLE ASN.IBMSNAP_APPLYTRAIL;


-- IBMSNAP_COMPENSATE
ALTER TABLE ASN.IBMSNAP_COMPENSATE 
	ALTER COLUMN INTENTSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
	
REORG TABLE ASN.IBMSNAP_COMPENSATE;

-- IBMSNAP_APPLEVEL
CREATE TABLE ASN.IBMSNAP_APPLEVEL
( ARCH_LEVEL CHAR(4) NOT NULL WITH DEFAULT '1001');

INSERT INTO ASN.IBMSNAP_APPLEVEL (ARCH_LEVEL) VALUES('1001');

--***********************************************************
-- Migrate SQL Apply to V10 Part 1B
--***********************************************************
--
-- Update and run this part on the target server if you have CCD target tables.
-- This part is run at the same time as part 1A.
--
-- Choose one of the following options:
--       
--     a.Run the following sql statement
--       
--       select TARGET_OWNER, TARGET_TABLE from ASN.IBMSNAP_SUBS_MEMBR where TARGET_STRUCTURE IN ('3', '9');
--       and for each target table returned in this query run the following sql statement 
--       to migrate the CCD table 
--       
--       ALTER TABLE !TARGET_OWNER!.!TARGET_TABLE! ALTER COLUMN IBMSNAP_COMMITSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
--       ALTER TABLE !TARGET_OWNER!.!TARGET_TABLE! ALTER COLUMN IBMSNAP_INTENTSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
--       REORG TABLE !TARGET_OWNER!.!TARGET_TABLE!;
--
--       Or
--      
--      b. Run the following sql to auto generate the sql statements to migrate all the CCD tables
--        select 'ALTER TABLE ' || TARGET_OWNER || '.' || TARGET_TABLE || ' ALTER COLUMN IBMSNAP_COMMITSEQ 
--        SET DATA TYPE VARCHAR(16) FOR BIT DATA ALTER COLUMN IBMSNAP_INTENTSEQ SET DATA TYPE VARCHAR(16) 
--        FOR BIT DATA; '|| CHR(10) || 'REORG TABLE ' || TARGET_OWNER || '.' || TARGET_TABLE || ';' 
--        FROM ASN.IBMSNAP_SUBS_MEMBR WHERE TARGET_STRUCTURE IN ('3', '9'); 


--***********************************************************
-- Migrate SQL Apply to V10 Part 2
--***********************************************************
--
-- Update and run the following sql only when you are ready to 
-- completely move to 16 byte LSN and synchpoint values for a specific Apply program,
-- which is based on Apply qualifier, source server, and Capture schema.
--
-- Part 2A:
-- Apply control tables can be shared by multiple Apply programs that may be running 
-- at different levels.  For migration part 2, you need to be selective on which rows 
-- in ASN.IBMSNAP_SUBS_SET are updated.  To determine this, first run the following
-- select statement.
--
-- SELECT APPLY_QUAL, SET_NAME, WHOS_ON_FIRST FROM ASN.IBMSNAP_SUBS_SET WHERE SOURCE_SERVER='dbname'
-- AND CAPTURE_SCHEMA='capschema';
--     set dbname to the Capture server that is being migrated to V10
--     set capchema to the Capture schema that is being migrated to V10
--
-- Based on above results, run the following update statements:
--
-- UPDATE ASN.IBMSNAP_SUBS_SET SET ARCH_LEVEL='1001' WHERE APPLY_QUAL=? AND SET_NAME=? AND WHOS_ON_FIRST=?;
-- UPDATE ASN.IBMSNAP_SUBS_SET SET SYNCHPOINT=CONCAT(x'000000000000', SYNCHPOINT) WHERE APPLY_QUAL=? AND SET_NAME=? AND WHOS_ON_FIRST=?;
--     set values for APPLY_QUAL, SET_NAME, WHOS_ON_FIRST based on the results from above select statement. 
--     only want to update the rows of the specific Apply Qualifier whose related Capture server is being migrated
--
-- Part 2B:
-- ASN.IBMSNAP_SUBS_EVENT table also needs updating. Run the following update statement:
-- 
-- UPDATE ASN.IBMSNAP_SUBS_EVENT SET END_SYNCHPOINT=CONCAT(x'000000000000', END_SYNCHPOINT) WHERE EVENT_NAME=?;
--      set EVENT_NAME to events that are called by the sets being migrated.  
--
-- Please note: If you have multiple sets that share the same events and some of those sets are not being migrated,
-- you need to create a new set of events.  Have one set of events for use by pre-V10 sets (no concat x'0's), and
-- have a second set of events for V10 sets (with concat x'0's).  Migrated V10 events will not work for pre-V10 sets.
--
--***********************************************************
-- Migrate SQL Apply to V10 Part 3
--***********************************************************
--
-- Update and run this part on the target server if you have CCD target tables.
-- This part is run at the same time as part 2.
--
-- Choose one of the following options:
--       
--     a.Run the following sql statement
--       
--       select TARGET_OWNER, TARGET_TABLE from ASN.IBMSNAP_SUBS_MEMBR where TARGET_STRUCTURE in ('3','9');
--       and for each target table returned in this query run the following sql statement 
--       to migrate the CCD table 
--       
--       UPDATE !TARGET_OWNER!.!TARGET_TABLE! SET IBMSNAP_COMMITSEQ=CONCAT(x'000000000000', IBMSNAP_COMMITSEQ);
--       UPDATE !TARGET_OWNER!.!TARGET_TABLE! SET IBMSNAP_INTENTSEQ=CONCAT(x'000000000000', IBMSNAP_INTENTSEQ);
--      
--       Or
--      
--      b. Run the following sql to auto generate the sql statements to migrate all the CCD tables
--        select 
--        SELECT 'UPDATE ' || TARGET_OWNER || '.' || TARGET_TABLE || ' SET IBMSNAP_COMMITSEQ = CONCAT(x''000000000000'', IBMSNAP_COMMITSEQ);' 
--        || CHR(10) || 'UPDATE ' || TARGET_OWNER || '.' || TARGET_TABLE || ' SET IBMSNAP_INTENTSEQ = CONCAT(x''000000000000'', IBMSNAP_INTENTSEQ);'  
--        FROM ASN.IBMSNAP_SUBS_MEMBR WHERE TARGET_STRUCTURE IN ('3', '9'); 
--
-- End of V10 





