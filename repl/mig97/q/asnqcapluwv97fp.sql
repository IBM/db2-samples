--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                         */
--      Version 9.7FPs for Linux, UNIX AND Windows                   */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT         */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2011. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate Q Capture control tables from V97 to the latest fixpack.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Locate and change all occurrences of the string !appschema! 
--     (for bidi !appschema! is the same as !capschema!) to the name 
--     of the Q Apply schema applicable to your environment.
-- 
-- (3) Locate and change all occurances of the string !captablespace!
--     to the name of the tablespace where the Q Capture control
--     tables are created.
--
-- (4) Locate and change all occurances of the string !qcsubbp!,
--     and !qcsubts!. These are the Bufferpool and tablespace where the 
--     !capschema!.IBMQREP_SUBS  table is to be created. Please note that
--     the IBMQREP_SUBS table needs to be created in a tablespace with 8k pagesize.
--
-- (5) Locate and change all occurances of the string !qcsubts!
--     to the name of the tablespace where the !capschema!.IBMQREP_SUBS 
--     table is to be created
--
--***********************************************************
-- Segment to migrate QCapture to V97FP2 
--***********************************************************

-- Start v97FP2

-- create IBMQREP_PART_HIST table

CREATE TABLE !capschema!.IBMQREP_PART_HIST
(
LSN              VARCHAR(16)     FOR BIT DATA NOT NULL,
HISTORY_TIME      TIMESTAMP                 NOT NULL,
TABSCHEMA         VARCHAR(128)              NOT NULL,
TABNAME           VARCHAR(128)              NOT NULL,
DATAPARTITIONID   INTEGER                   NOT NULL,
TBSPACEID         INTEGER                   NOT NULL,
PARTITIONOBJECTID INTEGER                   NOT NULL,
PRIMARY KEY (LSN, TABSCHEMA, TABNAME, DATAPARTITIONID,
TBSPACEID, PARTITIONOBJECTID)
) IN !captablespace!;

-- alter add new columns 

ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
  ADD COLUMN CAPTURE_ALIAS VARCHAR(8) WITH DEFAULT NULL ;  

UPDATE !capschema!.IBMQREP_SRC_COLS
  SET COL_OPTIONS_FLAG= 'YNNNNNNNNN'
  WHERE IS_KEY > 0;

-- The following section is only to fix your bidi subs in case 
-- they are not correct.

-- If you do not have bidi, this script will fail with
-- sqlcode -104.  Pl ignore the error.

UPDATE !capschema!.IBMQREP_SRC_COLS
 SET COL_OPTIONS_FLAG= 'YNNNNNNNNN'
 WHERE EXISTS (SELECT 1 FROM !appschema!.IBMQREP_TARGETS T, !capschema!.IBMQREP_SUBS S
 WHERE 
 S.SOURCE_NAME = T.TARGET_NAME AND S.SOURCE_OWNER = T.TARGET_OWNER AND S.SUBGROUP =    T.SUBGROUP AND T.SUBTYPE='B' AND T.CONFLICT_RULE IN ('C', 'A'));

UPDATE !capschema!.IBMQREP_SUBS 
 SET BEFORE_VALUES = 'Y'
 WHERE EXISTS (SELECT 1 FROM !appschema!.IBMQREP_TARGETS T, !capschema!.IBMQREP_SUBS S
 WHERE 
 S.SOURCE_NAME = T.TARGET_NAME AND S.SOURCE_OWNER = T.TARGET_OWNER AND S.SUBGROUP =   T.SUBGROUP AND T.SUBTYPE='B' AND T.CONFLICT_RULE IN ('C', 'A'));


UPDATE !capschema!.IBMQREP_SRC_COLS
 SET COL_OPTIONS_FLAG= 'YNNNNNNNNN'
 WHERE EXISTS (SELECT 1 FROM !appschema!.IBMQREP_TARGETS T, !capschema!.IBMQREP_SUBS S
 WHERE 
 S.SOURCE_NAME = T.TARGET_NAME AND S.SOURCE_OWNER = T.TARGET_OWNER AND S.SUBGROUP =    T.SUBGROUP AND T.SUBTYPE='B' AND T.CONFLICT_RULE = 'K');

UPDATE !capschema!.IBMQREP_SUBS 
 SET BEFORE_VALUES = 'Y'
 WHERE EXISTS (SELECT 1 FROM !appschema!.IBMQREP_TARGETS T, !capschema!.IBMQREP_SUBS S
 WHERE 
 S.SOURCE_NAME = T.TARGET_NAME AND S.SOURCE_OWNER = T.TARGET_OWNER AND S.SUBGROUP =   T.SUBGROUP AND T.SUBTYPE='B' AND T.CONFLICT_RULE = 'K');

 
-- remove Foereign key constraint on IBMQREP_SUBS table
 
ALTER TABLE !capschema!.IBMQREP_SUBS
      DROP FOREIGN KEY FKSENDQ;

-- remove Foereign key constraint on IBMQREP_SUBS table
 
ALTER TABLE !capschema!.IBMQREP_SRC_COLS
      DROP FOREIGN KEY FKSUBS;

-- End of V97FP2    



-- Start of V97FP3    

-- CAPPARMS:

ALTER TABLE !capschema!.IBMQREP_CAPPARMS         
ADD COLUMN  STALE    INT NOT NULL DEFAULT 3600;

ALTER TABLE !capschema!.IBMQREP_CAPPARMS         
ADD COLUMN  WARNLOGAPI INT NOT NULL DEFAULT 0;                                                 
                                                 
ALTER TABLE !capschema!.IBMQREP_CAPPARMS         
ADD COLUMN  TRANS_BATCH_SZ INT NOT NULL DEFAULT 1;          
                                                 
ALTER TABLE !capschema!.IBMQREP_CAPPARMS         
ADD COLUMN  PART_HIST_LIMIT  INT NOT NULL DEFAULT 10080;     
                                                 
ALTER TABLE !capschema!.IBMQREP_CAPPARMS         
ADD COLUMN   STARTALLQ CHAR(1) NOT NULL DEFAULT 'Y';      

ALTER TABLE !capschema!.IBMQREP_CAPPARMS
ADD COLUMN   NMI_ENABLE CHAR(1) NOT NULL DEFAULT 'N';

ALTER TABLE !capschema!.IBMQREP_CAPPARMS
ADD COLUMN   NMI_SOCKET_NAME VARCHAR(256) WITH DEFAULT NULL;

UPDATE !capschema!.IBMQREP_CAPPARMS   SET ARCH_LEVEL = '0973';  


--************************************************************

-- SIGNAL
ALTER TABLE !capschema!.IBMQREP_SIGNAL DATA CAPTURE NONE;
ALTER TABLE !capschema!.IBMQREP_SIGNAL 
  ALTER COLUMN SIGNAL_LSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMQREP_SIGNAL DATA CAPTURE CHANGES;

REORG TABLE !capschema!.IBMQREP_SIGNAL;


--************************************************************

-- CAPMON:  
ALTER TABLE !capschema!.IBMQREP_CAPMON         
ADD COLUMN  RESTART_MAXCMTSEQ VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMQREP_CAPMON         
ALTER COLUMN  RESTART_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMQREP_CAPMON         
ALTER COLUMN  CURRENT_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMQREP_CAPMON         
ADD COLUMN  MQCMIT_TIME INT;

ALTER TABLE !capschema!.IBMQREP_CAPMON 
VOLATILE CARDINALITY;

REORG TABLE !capschema!.IBMQREP_CAPMON;

--************************************************************

-- CAPQMON:  
ALTER TABLE !capschema!.IBMQREP_CAPQMON         
ADD COLUMN  RESTART_MAXCMTSEQ VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMQREP_CAPQMON         
ALTER COLUMN  RESTART_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMQREP_CAPQMON         
ALTER COLUMN  CURRENT_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMQREP_CAPQMON         
ADD COLUMN  MQPUT_TIME INT;

REORG TABLE !capschema!.IBMQREP_CAPQMON;

-- IGNTRANTRC

ALTER TABLE !capschema!.IBMQREP_IGNTRANTRC         
ALTER COLUMN  COMMITLSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;

REORG TABLE !capschema!.IBMQREP_IGNTRANTRC;

-- IBMQREP_CAPPARMS:
ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
VOLATILE CARDINALITY;

-- IBMQREP_SENDQUEUES:
ALTER TABLE !capschema!.IBMQREP_SUBS 
VOLATILE CARDINALITY;

-- IBMQREP_SRC_COLS:
ALTER TABLE !capschema!.IBMQREP_SRC_COLS 
VOLATILE CARDINALITY;

-- IBMQREP_SRCH_COND:
ALTER TABLE !capschema!.IBMQREP_SRCH_COND 
VOLATILE CARDINALITY;

-- IBMQREP_CAPQMON:
ALTER TABLE !capschema!.IBMQREP_CAPQMON 
VOLATILE CARDINALITY;

-- IBMQREP_CAPENQ:
ALTER TABLE !capschema!.IBMQREP_CAPENQ 
VOLATILE CARDINALITY;

-- IBMQREP_ADMINMSG:
ALTER TABLE !capschema!.IBMQREP_ADMINMSG 
VOLATILE CARDINALITY;

-- BMQREP_CAPENVINFO:
ALTER TABLE !capschema!.IBMQREP_CAPENVINFO 
VOLATILE CARDINALITY;

-- IGNTRAN:
ALTER TABLE !capschema!.IBMQREP_IGNTRAN 
VOLATILE CARDINALITY;


-- SUBS:

DROP   TABLE !capschema!.IBMQREP_SUBS_BACKUP;

COMMIT;

RENAME TABLE !capschema!.IBMQREP_SUBS TO IBMQREP_SUBS_BACKUP;
COMMIT;


CREATE BUFFERPOOL !qcsubbp! SIZE 125 PAGESIZE 8192;


CREATE TABLESPACE !qcsubts! PAGESIZE 8192 MANAGED BY SYSTEM USING 
('!qcsubts!_TSC') BUFFERPOOL !qcsubbp!;

CREATE TABLE !capschema!.IBMQREP_SUBS
(
 SUBNAME VARCHAR(132) NOT NULL,
 SOURCE_OWNER VARCHAR(128) NOT NULL,
 SOURCE_NAME VARCHAR(128) NOT NULL,
 TARGET_SERVER VARCHAR(18),
 TARGET_ALIAS VARCHAR(8),
 TARGET_OWNER VARCHAR(128),
 TARGET_NAME VARCHAR(128),
 TARGET_TYPE INTEGER,
 APPLY_SCHEMA VARCHAR(128),
 SENDQ VARCHAR(48) NOT NULL,
 SEARCH_CONDITION VARCHAR(2048) WITH DEFAULT NULL,
 SUB_ID INTEGER WITH DEFAULT NULL,
 SUBTYPE CHARACTER(1) NOT NULL WITH DEFAULT 'U',
 ALL_CHANGED_ROWS CHARACTER(1) NOT NULL WITH DEFAULT 'N',
 BEFORE_VALUES CHARACTER(1) NOT NULL WITH DEFAULT 'N',
 CHANGED_COLS_ONLY CHARACTER(1) NOT NULL WITH DEFAULT 'Y',
 HAS_LOADPHASE CHARACTER(1) NOT NULL WITH DEFAULT 'I',
 STATE CHARACTER(1) NOT NULL WITH DEFAULT 'N',
 STATE_TIME TIMESTAMP NOT NULL WITH DEFAULT,
 STATE_INFO CHARACTER(8),
 STATE_TRANSITION VARCHAR(256) FOR BIT DATA,
 SUBGROUP VARCHAR(30) WITH DEFAULT NULL,
 SOURCE_NODE SMALLINT NOT NULL WITH DEFAULT 0,
 TARGET_NODE SMALLINT NOT NULL WITH DEFAULT 0,
 GROUP_MEMBERS CHARACTER(254) FOR BIT DATA WITH DEFAULT NULL,
 OPTIONS_FLAG CHARACTER(4) NOT NULL WITH DEFAULT 'NNNN',
 SUPPRESS_DELETES CHARACTER(1) NOT NULL WITH DEFAULT 'N',
 DESCRIPTION VARCHAR(200),
 TOPIC VARCHAR(256),
 CAPTURE_LOAD CHARACTER(1) NOT NULL WITH DEFAULT 'W',
 CHANGE_CONDITION VARCHAR(2048),
 IGNCASDEL CHARACTER(1) NOT NULL WITH DEFAULT 'N',
 IGNTRIG CHARACTER(1) NOT NULL WITH DEFAULT 'N',
 LOGRD_ERROR_ACTION CHARACTER(1) NOT NULL WITH DEFAULT 'D',
 PRIMARY KEY(SUBNAME)
) IN !qcsubts!;


INSERT INTO !capschema!.IBMQREP_SUBS
(SUBNAME  ,SOURCE_OWNER ,SOURCE_NAME,TARGET_SERVER,
  TARGET_ALIAS ,TARGET_OWNER ,TARGET_NAME ,TARGET_TYPE,
  APPLY_SCHEMA  ,SENDQ ,SEARCH_CONDITION ,SUB_ID,
  SUBTYPE ,ALL_CHANGED_ROWS ,BEFORE_VALUES ,
  CHANGED_COLS_ONLY ,HAS_LOADPHASE ,STATE  ,
  STATE_TIME ,STATE_INFO ,STATE_TRANSITION ,
  SUBGROUP ,SOURCE_NODE ,TARGET_NODE,
  GROUP_MEMBERS ,OPTIONS_FLAG ,SUPPRESS_DELETES ,
  DESCRIPTION, TOPIC, CAPTURE_LOAD  )
 SELECT  SUBNAME  ,SOURCE_OWNER ,SOURCE_NAME,TARGET_SERVER,
  TARGET_ALIAS ,TARGET_OWNER ,TARGET_NAME ,TARGET_TYPE,
  APPLY_SCHEMA  ,SENDQ ,SEARCH_CONDITION ,SUB_ID,
  SUBTYPE ,ALL_CHANGED_ROWS ,BEFORE_VALUES ,
  CHANGED_COLS_ONLY ,HAS_LOADPHASE ,STATE  ,
  STATE_TIME ,STATE_INFO ,STATE_TRANSITION ,
  SUBGROUP ,SOURCE_NODE ,TARGET_NODE,
  GROUP_MEMBERS ,OPTIONS_FLAG ,SUPPRESS_DELETES ,
  DESCRIPTION, TOPIC, CAPTURE_LOAD  FROM !capschema!.IBMQREP_SUBS_BACKUP;



-- End of V97FP3   


-- Start of V97FP5

CREATE INDEX !capschema!.IX1SUBS ON !capschema!.IBMQREP_SUBS( SUB_ID );       

-- End of V97FP5 
