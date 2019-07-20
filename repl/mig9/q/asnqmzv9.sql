-- Script to migrate Q Capture control tables from V8.2 to V9.1.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Replace '!DBNAME!' and '!TSNAME!' to the database name and 
--     the name of the tablespace where the control table 
--     IBMQREP_SRC_COLS currently resides
--
-- (3) The 2 tables IBMQREP_COLVERSION and IBMQREP_TABVERSION are used by a 
--     Capture program to decode z/OS DB2 V9 log records, they are needed for both 
--     SQL and Q Replication. Hence these tables are common between Q and SQL replication 
--     in a server, if the SQL and Q capture programs use the same schema name. 
--     If these tables are being created during SQL replication migration then 
--     you should receive the table already exist error during Q replication migration  
--     which is OK.

-- Please uncomment the required constraints to drop if they exist
-- in your IBMQREP_CAPPARMS control table.

-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_STARTMODE;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_MEMORY_LIMIT;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_COMMIT_INTERVAL;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_AUTOSTOP;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_MON_INTERVAL;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_MON_LIMIT;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_TRACE_LIMT;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_SIGNAL_LIMIT;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_PRUNE_INTERVAL;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_LOGREUSE;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_LOGSTDOUT;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_TERM;
-- ALTER TABLE !capschema!.IBMQREP_CAPPARMS DROP CHECK CC_SLEEP_INTERVAL;

ALTER TABLE !capschema!.IBMQREP_CAPPARMS
  ADD COMPATIBILITY CHAR(4) NOT NULL WITH DEFAULT '0901';
  
-- Please uncomment the required constraints to drop if they exist
-- in your IBMQREP_SENDQUEUES control table.

-- ALTER TABLE !capschema!.IBMQREP_SENDQUEUES DROP CHECK CC_MSG_FORMAT;
-- ALTER TABLE !capschema!.IBMQREP_SENDQUEUES DROP CHECK CC_MSG_CONT_TYPE;
-- ALTER TABLE !capschema!.IBMQREP_SENDQUEUES DROP CHECK CC_SENDQ_STATE;
-- ALTER TABLE !capschema!.IBMQREP_SENDQUEUES DROP CHECK CC_QERRORACTION;
-- ALTER TABLE !capschema!.IBMQREP_SENDQUEUES DROP CHECK CC_HTBEAT_INTERVAL;

ALTER TABLE !capschema!.IBMQREP_SENDQUEUES
  ADD MESSAGE_CODEPAGE INTEGER ; 

-- Please uncomment the required constraints to drop if they exist
-- in your IBMQREP_SUBS control table.
  
-- ALTER TABLE !capschema!.IBMQREP_SUBS DROP CHECK CC_SUBTYPE;
-- ALTER TABLE !capschema!.IBMQREP_SUBS DROP CHECK CC_ALL_CHGD_ROWS;
-- ALTER TABLE !capschema!.IBMQREP_SUBS DROP CHECK CC_BEFORE_VALUES;
-- ALTER TABLE !capschema!.IBMQREP_SUBS DROP CHECK CC_CHGD_COLS_ONLY;
-- ALTER TABLE !capschema!.IBMQREP_SUBS DROP CHECK CC_HAS_LOADPHASE;
-- ALTER TABLE !capschema!.IBMQREP_SUBS DROP CHECK CC_SUBS_STATE;
-- ALTER TABLE !capschema!.IBMQREP_SUBS DROP CHECK CC_SUPPRESS_DELS;

-- Please uncomment the required constraints to drop if they exist
-- in your IBMQREP_SIGNAL control table.

-- ALTER TABLE !capschema!.IBMQREP_SIGNAL DROP CHECK CC_SIGNAL_TYPE;
-- ALTER TABLE !capschema!.IBMQREP_SIGNAL DROP CHECK CC_SIGNAL_STATE;

ALTER TABLE !capschema!.IBMQREP_SRC_COLS
  ADD COL_OPTIONS_FLAG CHAR(10) NOT NULL WITH DEFAULT 'NNNNNNNNNN';

ALTER TABLE !capschema!.IBMQREP_CAPMON
  ADD LAST_EOL_TIME TIMESTAMP;    

UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0901';

UPDATE !capschema!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0802';

--
-- Starting V9.1, the values in the MONITOR_INTERVAL column
-- are interpreted as milliseconds. They were interpreted
-- as seconds in Version 8.
-- The following UPDATE statement is to change the unit
-- from second to millisecond by multiplying the current
-- values by 1000 during the migration of the control
-- tables from Version 8 to Version 9.1.
--

UPDATE !capschema!.IBMQREP_CAPPARMS
  SET MONITOR_INTERVAL = MONITOR_INTERVAL * 1000;

UPDATE !capschema!.IBMQREP_SUBS SET TARGET_TYPE = 1 
      WHERE TARGET_TYPE=3;

UPDATE !capschema!.IBMQREP_SRC_COLS SET COL_OPTIONS_FLAG= 'YNNNNNNNNN' 
   WHERE SUBNAME IN (SELECT A.SUBNAME FROM !capschema!.IBMQREP_SRC_COLS A, 
!capschema!.IBMQREP_SUBS B WHERE A.SUBNAME= B.SUBNAME AND B.BEFORE_VALUES='Y' );
   
UPDATE !capschema!.IBMQREP_SRC_COLS SET COL_OPTIONS_FLAG= 'YNNNNNNNNN'
   WHERE IS_KEY IN (SELECT A.IS_KEY FROM !capschema!.IBMQREP_SRC_COLS A,
 !capschema!.IBMQREP_SUBS B WHERE A.SUBNAME= B.SUBNAME AND B.BEFORE_VALUES='N'
 AND A.IS_KEY > 0 );


CREATE TABLE !capschema!.IBMQREP_COLVERSION
(  LSN            CHAR(10)     FOR BIT DATA NOT NULL,
  TABLEID1       SMALLINT                  NOT NULL,
  TABLEID2       SMALLINT                  NOT NULL,
  POSITION       SMALLINT                  NOT NULL,
  NAME           VARCHAR(128)              NOT NULL,
  TYPE           SMALLINT                  NOT NULL,
  LENGTH         INTEGER                   NOT NULL,
  NULLS          CHAR(1)                   NOT NULL,
  DEFAULT        VARCHAR(1536)
) in !DBNAME!.!TSNAME!;

CREATE UNIQUE INDEX !capschema!.IBMQREP_COLVERSIOX
  ON !capschema!.IBMQREP_COLVERSION(
  LSN, TABLEID1, TABLEID2, POSITION);   
  

CREATE TABLE !capschema!.IBMQREP_TABVERSION
(  LSN            CHAR(10)     FOR BIT DATA NOT NULL,
  TABLEID1       SMALLINT                  NOT NULL,
  TABLEID2       SMALLINT                  NOT NULL,
  VERSION        INTEGER                   NOT NULL,
  SOURCE_OWNER   VARCHAR(128)              NOT NULL,
  SOURCE_NAME    VARCHAR(128)              NOT NULL   
)in !DBNAME!.!TSNAME!;   
  
CREATE UNIQUE INDEX !capschema!.IBMQREP_TABVERSIOX
  ON !capschema!.IBMQREP_TABVERSION(
  LSN, TABLEID1, TABLEID2, VERSION);  

COMMIT;

------------------------------------------------------------------
--   New tables to ignore transactions    (All IBM platforms  )
--   Tables names starts with IBMQREP
------------------------------------------------------------------

CREATE TABLE !capschema!.IBMQREP_IGNTRAN
( AUTHID 	CHARACTER(128),
 AUTHTOKEN 	CHARACTER(30),
 PLANNAME 	CHARACTER(8)
)  IN !DBNAME!.!TSNAME!;

CREATE TABLE !capschema!.IBMQREP_IGNTRANTRC
( AUTHID 	CHARACTER(128),
 AUTHTOKEN 	HARACTER(30),
 PLANNAME 	CHARACTER(8),
 TRANSID 	CHARACTER(10) 	FOR BIT DATA NOT NULL,
 COMMITLSN 	CHARACTER(10) 	FOR BIT DATA NOT NULL
)  IN !DBNAME!.!TSNAME!;


------------------------------END---------------------------------------

-- Note:
-- Job to migrate Q Apply control tables from V8.2 to V9.1.
-- Run this job against a DB2 and V7 & V8 subsystem 
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string !appschema! 
--     to the name of the Q Apply schema applicable to your
--     environment
--  
--

-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_RECVQUEUES VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_TRG_COLS VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_SPILLQS VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_APPLYTRACE VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_APPLYMON VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_SPILLEDROW VOLATILE CARDINALITY;
-- ALTER TABLE !appschema!.IBMQREP_SAVERI VOLATILE CARDINALITY;

-- Please uncomment the required constraints to drop if they exist
-- in your IBMQREP_APPLYPARMS control table.

-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_MON_LIMIT;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_TRACE_LIMT;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_MON_INTERVAL;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_PRUNE_INTERVAL;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_AUTOSTOP;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_LOGREUSE;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_LOGSTDOUT;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_TERM;
-- ALTER TABLE !appschema!.IBMQREP_APPLYPARMS DROP CHECK CA_RETRIES;

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
 ADD SQL_CAP_SCHEMA VARCHAR(128) WITH DEFAULT NULL;
    
ALTER TABLE !appschema!.IBMQREP_RECVQUEUES DROP CHECK CC_SENDQ_STATE;

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES
  ALTER COLUMN CAPTURE_SCHEMA SET DATA TYPE VARCHAR(128);

-- Please uncomment the required constraints to drop if they exist
-- in your IBMQREP_TARGETS control table.
  
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_TARGTBL_STATE;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_UPDATEANY;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_CONFLICTACTION;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_ERRORACTION;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_UPANY_SOURCE;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_UPANY_TARGET;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_TARGET_TYPE;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_GROUP_INIT_ROLE;
-- ALTER TABLE !appschema!.IBMQREP_TARGETS DROP CHECK CA_LOAD_TYPE;

ALTER TABLE !appschema!.IBMQREP_TARGETS
  ADD MODELQ VARCHAR(36) WITH DEFAULT 'IBMQREP.SPILL.MODELQ';
ALTER TABLE !appschema!.IBMQREP_TARGETS
  ADD CCD_CONDENSED CHAR(1) DEFAULT NULL;
ALTER TABLE !appschema!.IBMQREP_TARGETS
  ADD CCD_COMPLETE CHAR(1) DEFAULT NULL;
ALTER TABLE !appschema!.IBMQREP_TARGETS
  ADD SOURCE_TYPE CHAR(1) DEFAULT ' ';
  
-- Please uncomment the sql to drop the constraint CA_IS_KEY if it exist
-- in your IBMQREP_TRG_COLS control table.

-- ALTER TABLE !appschema!.IBMQREP_TRG_COLS DROP CHECK CA_IS_KEY;

ALTER TABLE !appschema!.IBMQREP_TRG_COLS
  ALTER COLUMN SOURCE_COLNAME SET DATA TYPE VARCHAR(254);
ALTER TABLE !appschema!.IBMQREP_TRG_COLS
  ADD MAPPING_TYPE CHAR(1) DEFAULT NULL;
ALTER TABLE !appschema!.IBMQREP_TRG_COLS
  ADD SRC_COL_MAP VARCHAR(2000) DEFAULT NULL;
  
-- Kept BEF_TARG_COLNAME length as 128 to avoid future migration 
-- when DB2 started to support long column length.
ALTER TABLE !appschema!.IBMQREP_TRG_COLS  
  ADD BEF_TARG_COLNAME VARCHAR(128) DEFAULT NULL;

-- Please uncomment the sql to drop the constraint CA_IS_APPLIED if it exist
-- in your IBMQREP_EXCEPTIONS control table.

-- ALTER TABLE !appschema!.IBMQREP_EXCEPTIONS DROP CHECK CA_IS_APPLIED;
  
-- Please uncomment the alter on IBMQREP_EXCEPTIONS table
-- if you are running the migration script on subsystem V8 new-function
-- mode or later.
  
-- ALTER TABLE !appschema!.IBMQREP_EXCEPTIONS
--  ALTER COLUMN SRC_COMMIT_LSN SET DATA TYPE VARCHAR(48);

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES
  ADD SOURCE_TYPE CHAR(1) DEFAULT ' ';
    
ALTER TABLE !appschema!.IBMQREP_APPLYMON
  ADD OLDEST_INFLT_TRANS TIMESTAMP;
  
ALTER TABLE !appschema!.IBMQREP_SAVERI DROP CHECK CA_TYPE_OF_LOAD;

ALTER TABLE !appschema!.IBMQREP_SAVERI 
  ADD  DELETERULE CHAR(1) DEFAULT NULL;
ALTER TABLE !appschema!.IBMQREP_SAVERI  
  ADD  UPDATERULE CHAR(1) DEFAULT NULL; 
ALTER TABLE !appschema!.IBMQREP_SAVERI
  ALTER COLUMN CONSTNAME SET DATA TYPE VARCHAR(128);

UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0901';

UPDATE !appschema!.IBMQREP_TARGETS SET TARGET_TYPE = 1 
      WHERE TARGET_TYPE=3;
      
UPDATE !appschema!.IBMQREP_TRG_COLS SET MAPPING_TYPE = 'R';

--
-- Starting V9.1, the values in the MONITOR_INTERVAL column
-- are interpreted as milliseconds. They were interpreted
-- as seconds in Version 8.
-- The following UPDATE statement is to change the unit
-- from second to millisecond by multiplying the current
-- values by 1000 during the migration of the control
-- tables from Version 8 to Version 9.1.

UPDATE !appschema!.IBMQREP_APPLYPARMS
  SET MONITOR_INTERVAL = MONITOR_INTERVAL * 1000;
COMMIT;

---------------------------END--------------------------------------------

--  Script to migrate Monitor control tables from V8.2 to V9.1.
--  Run this script against DB2 V7 and V8 subsystems. 
--  Prior to running this script, customize it to your existing 
--  monitor control server environment:
--  (1) '!MONCNTL!' and '!TSMROW1!' to the database name and 
--       the name of the table space where the control table 
--       ASN.IBMSNAP_CONDITIONS currently resides
--

CREATE TABLE ASN.IBMSNAP_TEMPLATES(
  TEMPLATE_NAME                   VARCHAR(128) NOT NULL,
  START_TIME                      TIME NOT NULL,
  WDAY                            SMALLINT,
  DURATION                        INT NOT NULL,
  PRIMARY KEY(TEMPLATE_NAME))
  IN !MONCNTL!.!TSMROW1!;
  
CREATE UNIQUE INDEX ASN.IBMSNAP_TEMPLATESX
  ON ASN.IBMSNAP_TEMPLATES(
  TEMPLATE_NAME ASC);
  
CREATE TABLE ASN.IBMSNAP_SUSPENDS(
  SUSPENSION_NAME                 VARCHAR(128) NOT NULL,
  SERVER_NAME                     CHAR(18) NOT NULL,
  SERVER_ALIAS                    CHAR(8),
  TEMPLATE_NAME                   VARCHAR(128),
  START                           TIMESTAMP NOT NULL,
  STOP                            TIMESTAMP NOT NULL,
  PRIMARY KEY(SUSPENSION_NAME))
  IN !MONCNTL!.!TSMROW1!;
  
CREATE UNIQUE INDEX ASN.IBMSNAP_SUSPENDSX1
  ON ASN.IBMSNAP_SUSPENDS(
  SUSPENSION_NAME ASC);
  
CREATE UNIQUE INDEX ASN.IBMSNAP_SUSPENDSX2
  ON ASN.IBMSNAP_SUSPENDS(
  SERVER_NAME ASC,
  START ASC,
  TEMPLATE_NAME ASC);
  
ALTER TABLE ASN.IBMSNAP_MONTRAIL
  ADD SUSPENSION_NAME VARCHAR(128);
  
UPDATE ASN.IBMSNAP_MONPARMS SET ARCH_LEVEL = '0901';
COMMIT;

---------------------------END--------------------------------------------
