--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version 10 (DB2 V10) for Linux, UNIX AND Windows             */
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
-- Script to migrate SQL Capture control tables from V97 to V10.
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
-- BEFORE UPGRADING to DB2 V10 and SQL Capture program V10:
-- * Ensure that Capture has caught up to the end of the log and that no further
--   DML is run after Capture has been stopped.
-- 
-- AFTER UPGRADING V10, you are ready to start SQL Capture migration.
--
-- You will do this migration in two parts. 
--
-- PART 1: 
-- * Migrate the Capture control tables. This includes: alter all the LSN and
--   synchpoint columns to VARCHAR(16) for bit data, add some new columns, and add new tables.
-- * Run Part 1A and Part 1B below.
-- * At this point, Capture will continue to populate LSN and synchpoint columns with 
--   10 byte length values.  The new COMPATIBILITY column in IBMSNAP_CAPPARMS is set to '0801'.
--
-- If full refresh of all subscription members is acceptable, then perform the following 
-- to start up SQL Replication:
-- * Before any DML occurs, start Capture with STARTMODE=COLD
--   This will deactivate all registrations.
-- * Start SQL Apply.  Apply will detect the inactive registrations, insert CAPSTART signals,
--   and perform full refresh.
-- 
-- If full refresh is not desired, then perform the following 
-- to start up SQL Replication and bypass full refresh.
-- * Before starting SQL Capture, go to the SQL Apply control server and
--   change the LOADX_TYPE value of affected subsscription members.
--      * Since Apply control tables can be shared by multiple Apply programs that may be running 
--        with different Captures, you need to be selective on which rows in 
--        ASN.IBMSNAP_SUBS_MEMBR are updated.  To determine this, first run the following
--        select statement:
--           SELECT APPLY_QUAL, SET_NAME, WHOS_ON_FIRST FROM ASN.IBMSNAP_SUBS_SET 
--           WHERE SOURCE_SERVER="dbname" AND CAPTURE_SCHEMA="capschema";
--        set dbname to the Capture server that is being migrated to V10
--        set capchema to the Capture schema that is being migrated to V10
--      * Based on above results, run the following update statement:
--          UPDATE ASN.IBMSNAP_SUBS_MEMBR SET LOADX_TYPE=6
--          WHERE APPLY_QUAL=? AND SET_NAME=? AND WHOS_ON_FIRST=?;
-- * Before any DML occurs, start Capture with STARTMODE=COLD
--   This will deactivate all registrations.
-- * Start SQL Apply with LOADXIT=Y option.  
--   Apply will detect the inactive registrations, insert CAPSTART signals,
--   and, because LOADX_TYPE=6, no full refresh will be performed.
-- * Notes:  
--     - The warning message ASN1051W (The Apply program detected a gap) will be
--       issued by SQL Apply and this can be ignored. LOADX_TYPE=6 setting will 
--       resolve the warning.
--     - If needed, set the LOADX_TYPE back to the original value after the 
--       subscriptions are successfully activated.
--     - You are not required to start SQL Apply with LOADXIT=Y after migration. 
--     - The above steps for SQL Apply are to be run for any level of SQL Apply,
--       whether it is being migrated or not.
-- 
-- If you are running any pre-V10 Applys, DO NOT RUN PART 2 YET.
--
-- PART 2: 
-- * This part for the Capture server is run only when you are ready to 
--  also run V10 Apply migration's Part 2 on the all related Apply control servers.
--  This part completes the move to 16 byte values.
-- * Here you run sql to concatenate x'0's to LSN and synchpoint columns
--  and update COMPATIBILITY to '1001'.
-- * Run Part 2A and Part 2B below.
-- 
--********************************************************************/
--
-- Prior to running this script, customize it to your existing 
-- SQL Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the SQL Capture schema applicable to your
--     environment.
-- (2) Locate and change all occurrences of the string !captablespace! 
--     to the name of the tablespace where your SQL Capture control tables
--     are created.   
-- (3) Run the script to migrate control tables into V10 and complete 
--     Part 1 of the Capture migration.
--
--***********************************************************
-- Migrate SQL Capture to V10 Part 1A
--***********************************************************

ALTER TABLE !capschema!.IBMSNAP_CAPPARMS         
ADD COLUMN   COMPATIBILITY CHAR(4) NOT NULL WITH DEFAULT '1001'; 

ALTER TABLE !capschema!.IBMSNAP_CAPPARMS         
ADD COLUMN   LOGRDBUFSZ INTEGER NOT NULL WITH DEFAULT 256;

UPDATE !capschema!.IBMSNAP_CAPPARMS SET ARCH_LEVEL = '1001';
UPDATE !capschema!.IBMSNAP_CAPPARMS SET COMPATIBILITY= '0801';

ALTER TABLE !capschema!.IBMSNAP_CAPMON ALTER COLUMN RESTART_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_CAPMON ALTER COLUMN CURRENT_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMSNAP_CAPMON;

ALTER TABLE !capschema!.IBMSNAP_PRUNCNTL ALTER COLUMN SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMSNAP_PRUNCNTL;

ALTER TABLE !capschema!.IBMSNAP_PRUNE_SET ALTER COLUMN SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMSNAP_PRUNE_SET;


ALTER TABLE !capschema!.IBMSNAP_REGISTER ALTER COLUMN CD_OLD_SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_REGISTER ALTER COLUMN CD_NEW_SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_REGISTER ALTER COLUMN CCD_OLD_SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMSNAP_REGISTER;
ALTER TABLE !capschema!.IBMSNAP_REGISTER ALTER COLUMN SYNCHPOINT SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMSNAP_REGISTER;

ALTER TABLE !capschema!.IBMSNAP_RESTART ALTER COLUMN MAX_COMMITSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_RESTART ALTER COLUMN MIN_INFLIGHTSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_RESTART ALTER COLUMN CAPTURE_FIRST_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMSNAP_RESTART;

ALTER TABLE !capschema!.IBMSNAP_SIGNAL DATA CAPTURE NONE;
ALTER TABLE !capschema!.IBMSNAP_SIGNAL ALTER COLUMN SIGNAL_LSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_SIGNAL DATA CAPTURE CHANGES;
REORG TABLE !capschema!.IBMSNAP_SIGNAL;

ALTER TABLE !capschema!.IBMSNAP_UOW ALTER COLUMN IBMSNAP_COMMITSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMSNAP_UOW;

ALTER TABLE !capschema!.IBMQREP_IGNTRANTRC ALTER COLUMN COMMITLSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMQREP_IGNTRANTRC;

-- CAPMON:  
ALTER TABLE !capschema!.IBMSNAP_CAPMON         
ADD COLUMN  RESTART_MAXCMTSEQ VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMSNAP_CAPMON         
ADD COLUMN  LOGREAD_API_TIME INTEGER;

ALTER TABLE !capschema!.IBMSNAP_CAPMON         
ADD COLUMN  NUM_LOGREAD_CALLS INTEGER;

------------------------------------------------------------------
--   New version tables 
--   Tables names start with IBMQREP, not IBMSNAP as it is common
--   to both QRep and SQL Rep.
------------------------------------------------------------------

CREATE TABLE !capschema!.IBMQREP_COLVERSION
(  LSN            CHAR(16)     FOR BIT DATA NOT NULL,
  TABLEID1       SMALLINT                  NOT NULL,
  TABLEID2       SMALLINT                  NOT NULL,
  POSITION       SMALLINT                  NOT NULL,
  NAME           VARCHAR(128)              NOT NULL,
  TYPE           SMALLINT                  NOT NULL,
  LENGTH         INTEGER                   NOT NULL,
  NULLS          CHAR(1)                   NOT NULL,
  DEFAULT        VARCHAR(1536),
  CODEPAGE   INTEGER,
  SCALE      INTEGER
) IN !captablespace!;

CREATE UNIQUE INDEX !capschema!.IBMQREP_COLVERSIOX
  ON !capschema!.IBMQREP_COLVERSION(
  LSN, TABLEID1, TABLEID2, POSITION);

CREATE INDEX !capschema!.IBMQREP_COLVERSIOX1 ON
 !capschema!.IBMQREP_COLVERSION
( TABLEID1 ASC, TABLEID2 ASC);


CREATE INDEX !capschema!.IBMQREP_PART_HISTIDX1 ON
 !capschema!.IBMQREP_PART_HIST
( TABSCHEMA, TABNAME, LSN);


CREATE TABLE !capschema!.IBMQREP_TABVERSION
(  LSN            CHAR(16)     FOR BIT DATA NOT NULL,
  TABLEID1       SMALLINT                  NOT NULL,
  TABLEID2       SMALLINT                  NOT NULL,
  VERSION        INTEGER                   NOT NULL,
  SOURCE_OWNER   VARCHAR(128)              NOT NULL,
  SOURCE_NAME    VARCHAR(128)              NOT NULL
) IN !captablespace!;

CREATE UNIQUE INDEX !capschema!.IBMQREP_TABVERSIOX
  ON !capschema!.IBMQREP_TABVERSION(
  LSN, TABLEID1, TABLEID2, VERSION);

CREATE INDEX !capschema!.IBMQREP_TABVERSIOX1 ON
 !capschema!.IBMQREP_TABVERSION
( TABLEID1 ASC, TABLEID2 ASC);

CREATE INDEX !capschema!.IBMQREP_TABVERSIOX2 ON
 !capschema!.IBMQREP_TABVERSION
( SOURCE_OWNER ASC, SOURCE_NAME ASC);


--***********************************************************
-- Migrate SQL Capture to V10 Part 1B
--***********************************************************
-- Uncomment this section and run sql to migrate the CD tables
-- 
-- To migrate the CD tables do one of the following (ONLY ONE a or b)
--       
--     a.Run the following sql statement 
--
--       select CD_OWNER, CD_TABLE from !capschema!.IBMSNAP_REGISTER
--       and for each CD table returned in this query run the following 
--       sql statement to migrate the CD table 
--       
--       ALTER TABLE !CD_OWNER!.!CD_TABLE! ALTER COLUMN IBMSNAP_COMMITSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
--       ALTER TABLE !CD_OWNER!.!CD_TABLE! ALTER COLUMN IBMSNAP_INTENTSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
--       REORG TABLE !CD_OWNER!.!CD_TABLE!;
--
--
--     b. Run the following sql to auto generate the sql statements to migrate all the CD tables 
--       select 'ALTER TABLE ' || CD_OWNER || '.' || CD_TABLE || ' ALTER COLUMN IBMSNAP_COMMITSEQ 
--       SET DATA TYPE VARCHAR(16) FOR BIT DATA ALTER COLUMN IBMSNAP_INTENTSEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;'
--       || CHR(10) || 'REORG TABLE ' || CD_OWNER || '.' || CD_TABLE || ';' FROM 
--       !capschema!.IBMSNAP_REGISTER WHERE SOURCE_STRUCTURE IN ('1','7');
--
--  Please note:
--  After migration Part 1A and Part 1B have been run, when you start the capture server
--  the first time, you need to start it with startmode=cold
--  Refer to overview of PART 1 for bypassing full refresh from SQL Apply.

--***********************************************************
-- Migrate SQL Capture to V10 Part 2A
--***********************************************************
--
-- Uncomment this section and run this section only after you have migrated 
-- all of your Apply programs and the Apply control tables and are ready to migrate the
-- V10 completely.
-- 
-- To migrate the CD tables do one of the following (ONLY ONE a or b)
--       
--     a.Run the following sql statement 
--
--       select CD_OWNER, CD_TABLE from !capschema!.IBMSNAP_REGISTER
--       and for each CD table returned in this query run the following 
--       sql statement to migrate the CD table 
--       
--       UPDATE !CD_OWNER!.!CD_TABLE! SET IBMSNAP_COMMITSEQ=CONCAT(x'000000000000', IBMSNAP_COMMITSEQ);
--       UPDATE !CD_OWNER!.!CD_TABLE! SET IBMSNAP_INTENTSEQ=CONCAT(x'000000000000', IBMSNAP_INTENTSEQ);
--
--
--     b. Run the following sql to auto generate the sql statements to migrate all the CD tables 
--       select 'UPDATE ' || CD_OWNER || '.' || 
--       CD_TABLE || ' SET IBMSNAP_COMMITSEQ = CONCAT(x''000000000000'', IBMSNAP_COMMITSEQ);'|| CHR(10) || 'UPDATE ' || 
--       CD_OWNER || '.' || CD_TABLE || ' SET IBMSNAP_INTENTSEQ = CONCAT(x''000000000000'', IBMSNAP_INTENTSEQ);' FROM 
--       !capschema!.IBMSNAP_REGISTER WHERE SOURCE_STRUCTURE IN ('1','7');
--
--***********************************************************
-- Migrate SQL Capture to V10 Part 2B
--***********************************************************
--
--     Even though the IBMSNAP_CAPMON, IBMSNAP_SIGNAL, IBMSNAP_IGNTRANTRC tables have only historical
--     data, we concat x'000000000000' so that select stmts with ORDER BY clause will return the rows in the
--     correct order.
--     
-- UPDATE !capschema!.IBMSNAP_CAPMON SET RESTART_SEQ=CONCAT(x'000000000000', RESTART_SEQ); 
-- UPDATE !capschema!.IBMSNAP_CAPMON SET CURRENT_SEQ=CONCAT(x'000000000000', CURRENT_SEQ);
-- UPDATE !capschema!.IBMSNAP_PRUNCNTL SET SYNCHPOINT=CONCAT(x'000000000000', SYNCHPOINT);
-- UPDATE !capschema!.IBMSNAP_PRUNE_SET SET SYNCHPOINT=CONCAT(x'000000000000', SYNCHPOINT);
-- UPDATE !capschema!.IBMSNAP_REGISTER SET CD_OLD_SYNCHPOINT=CONCAT(x'000000000000', CD_OLD_SYNCHPOINT);
-- UPDATE !capschema!.IBMSNAP_REGISTER SET CD_NEW_SYNCHPOINT=CONCAT(x'000000000000', CD_NEW_SYNCHPOINT);
-- UPDATE !capschema!.IBMSNAP_REGISTER SET CCD_OLD_SYNCHPOINT=CONCAT(x'000000000000', CCD_OLD_SYNCHPOINT);
-- UPDATE !capschema!.IBMSNAP_REGISTER SET SYNCHPOINT=CONCAT(x'000000000000', SYNCHPOINT);
-- UPDATE !capschema!.IBMSNAP_SIGNAL SET SIGNAL_LSN=CONCAT(x'000000000000', SIGNAL_LSN);
-- UPDATE !capschema!.IBMSNAP_UOW SET IBMSNAP_COMMITSEQ=CONCAT(x'000000000000', IBMSNAP_COMMITSEQ);
-- UPDATE !capschema!.IBMQREP_IGNTRANTRC SET COMMITLSN=CONCAT(x'000000000000', COMMITLSN);

-- UPDATE !capschema!.IBMSNAP_CAPPARMS SET COMPATIBILITY= '1001';


-- End of V10   
