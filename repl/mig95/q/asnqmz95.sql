
-- Script to migrate Q Capture control tables from V9.1 to V9.5
-- Run this job against a DB2 and V7,V8 and V9 subsystem where you
-- already have V9 replication control tables.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
--
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Replace '!DBNAME!' and '!TSNAME!' to the database name and 
--     the name of the tablespace where the control table 
--     IBMQREP_CAPPARMS currently resides
--
-- (3) The new table !capschema!.IBMQREP_CAPENVINFO added in V9.5. . 
--     This table is necessary for Repl Admin to operate with either 
--     Replication engine components or MQ server components successfully. 

--------------------------------------------------------------------------
--    SEC1   Q CAPTURE SERVER
--------------------------------------------------------------------------
CREATE TABLE !capschema!.IBMQREP_CAPENVINFO
( NAME  VARCHAR(30) NOT NULL,
  VALUE VARCHAR(3800) 
 ) IN !DBNAME!.!TSNAME!; 
 
 -- DEFAULT value of ARCH_LEVEL also needs to updated. In DB2 z/OS
 -- we can't alter/update the default value of a column.
 -- Hence the below sql statement is commented out. However
 -- Capture works  fine if you update arch_level value in the 
 -- IBMQREP_CAPPARMS table.
 
 -- ALTER TABLE !capschema!.IBMQREP_CAPPARMS
 -- ALTER COLUMN ARCH_LEVEL SET DEFAULT '0905';
  

ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
  ADD LOB_SEND_OPTION   CHAR(1) NOT NULL DEFAULT 'I';
ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
  ADD QFULL_NUM_RETRIES   INTEGER NOT NULL DEFAULT 30;
ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
  ADD QFULL_RETRY_DELAY INTEGER NOT NULL DEFAULT 250;
 
UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0905';
 
UPDATE !capschema!.IBMQREP_CAPPARMS SET LOB_SEND_OPTION = 'S'; 
  

ALTER TABLE !capschema!.IBMQREP_SENDQUEUES 
  ADD SENDRAW_IFERROR   CHAR(1) NOT NULL DEFAULT 'N';
ALTER TABLE !capschema!.IBMQREP_SENDQUEUES 
  ADD COLUMN_DELIMITER  CHAR(1) ;
ALTER TABLE !capschema!.IBMQREP_SENDQUEUES 
  ADD STRING_DELIMITER  CHAR(1);
ALTER TABLE !capschema!.IBMQREP_SENDQUEUES 
  ADD RECORD_DELIMITER  CHAR(1);
ALTER TABLE !capschema!.IBMQREP_SENDQUEUES 
  ADD DECIMAL_POINT     CHAR(1);
  
ALTER TABLE !capschema!.IBMQREP_CAPQMON 
  ADD LOBS_TOO_BIG       INTEGER NOT NULL DEFAULT 0;
ALTER TABLE !capschema!.IBMQREP_CAPQMON 
  ADD XMLDOCS_TOO_BIG   INTEGER NOT NULL DEFAULT 0;
ALTER TABLE !capschema!.IBMQREP_CAPQMON   
  ADD QFULL_ERROR_COUNT INTEGER NOT NULL DEFAULT 0
  ;
   
ALTER TABLE !capschema!.IBMQREP_CAPTRACE 
  ADD REASON_CODE      INTEGER ;
ALTER TABLE !capschema!.IBMQREP_CAPTRACE 
  ADD MQ_CODE          INTEGER;

  
ALTER TABLE !capschema!.IBMQREP_IGNTRAN
  ADD IGNTRANTRC       CHAR(1) NOT NULL DEFAULT 'Y';

-- this particular alter applicable only if customer created 
-- capture control tables using V91GA level.

-- ALTER TABLE !capschema!.IBMQREP_IGNTRANTRC
-- ADD IGNTRAN_TIME TIMESTAMP NOT NULL DEFAULT CURRENT TIMESTAMP;  

  
COMMIT;
------------------------------END-----------------------------------------
--
--------------------------------------------------------------------------
--    SEC2  Q APPLY SERVER
--------------------------------------------------------------------------

-- Note:
-- Job to migrate Q Apply control tables from V9.1 to V9.5.
-- Run this job against a DB2 and V7,V8 and V9 subsystem where you
-- already have V9 replication control tables.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
--
-- (1) Locate and change all occurrences of the string !appschema! 
--     to the name of the Q Apply schema applicable to your
--     environment
--
-- (2) Replace '!DBNAME!' and '!TSNAME!' to the database name and 
--     the name of the tablespace where the control table 
--     IBMQREP_APPPARMS currently resides
--
-- (3) The new table !appschema!.IBMQREP_APPENVINFO added in V9.5. . 
--     This table is necessary for Repl Admin to operate with either 
--     Replication engine components or MQ server components successfully.  
--


CREATE TABLE !appschema!.IBMQREP_APPENVINFO
( NAME VARCHAR(30) NOT NULL,
  VALUE VARCHAR(3800) DEFAULT NULL
 ) IN !DBNAME!.!TSNAME!;  
 
 -- DEFAULT value of ARCH_LEVEL also needs to updated. In DB2 z?OS
 -- we can't alter/update the default value of a column.
 -- Hence the below sql statement is commented out. However
 -- Capture works  fine if you update arch_level value in the 
 -- IBMQREP_APPLYPARMS table.
 
--   ALTER TABLE !appschema!.IBMQREP_APPLYPARMS
--   ALTER COLUMN ARCH_LEVEL SET DEFAULT '0905';
  
UPDATE !appschema!.IBMQREP_APPLYPARMS 
  SET ARCH_LEVEL = '0905';

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES
  ADD MAXAGENTS_CORRELID INTEGER DEFAULT NULL;

ALTER TABLE !appschema!.IBMQREP_APPLYMON
  ADD JOB_DEPENDENCIES INTEGER DEFAULT NULL;

ALTER TABLE !appschema!.IBMQREP_APPLYMON
  ADD CAPTURE_LATENCY INTEGER DEFAULT NULL;

ALTER TABLE !appschema!.IBMQREP_APPLYTRACE
  ADD REASON_CODE      INTEGER DEFAULT NULL; 
  
ALTER TABLE !appschema!.IBMQREP_APPLYTRACE
  ADD MQ_CODE          INTEGER DEFAULT NULL;
  
COMMIT;
---------------------------END--------------------------------------------

--
--------------------------------------------------------------------------
--    SEC3 MONITOR SERVER
--------------------------------------------------------------------------

-- Note:
-- Job to migrate Monitor control tables from V9.1 to V9.5.
-- Run this job against a DB2 and V7,V8 and V9 subsystem where you
-- already have V9 replication control tables.
--

ALTER TABLE ASN.IBMQREP_MONPARMS
    ADD DELAY       CHAR(1) DEFAULT 'N';

  
UPDATE ASN.IBMSNAP_MONPARMS SET ARCH_LEVEL = '0905';
COMMIT;

---------------------------END--------------------------------------------
--   This is to update capture server ibmqrep_capparms table compatibility
--   columns to '0905'. This will tell capture to send V9.5 messages to apply.
--
--------------------------------------------------------------------------
--    SEC4   UPDATE CAPTURE SERVR COMPATIBILITY COLUMN to '0905'
--------------------------------------------------------------------------
UPDATE !capschema!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0905';

---------------------------END--------------------------------------------

--   This is rollback script to update capture server ibmqrep_capparms table 
--   compatibility columns to '0901' and ARCH_LEVEL column to '0901'.
--   This will tell capture to send V9.1 messages to apply.
--   Control table structure will not fallback to V9.1 structure.
--   V9.5 new columns will be tolerated by V9.1 Q Capture and Q Apply.
--   Only the COMPATIBILITY and ARCH_LEVEL need to be updated
--   to '0901'.
--
--------------------------------------------------------------------------
--    SEC5    ROLLBACK to V9.1 Q CAPTURE & Q APPLY 
--------------------------------------------------------------------------
-- For Q Capture server
UPDATE !capschema!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0901';
UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0901'; 

COMMIT;

-- For Q Apply Server

UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0901'; 

COMMIT;

---------------------------END--------------------------------------------



