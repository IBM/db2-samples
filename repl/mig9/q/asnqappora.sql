-- Script to migrate Q Apply control tables from V8.2 to V9.1.
-- Both the control tables created in the federated database and
-- in the Oracle database will be updated.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string 
--     !server_name! to the name of the Oracle server as
--     defined to the federated database
-- (2) Locate and change the string !local_schema! to the nickname 
--     defined on the federated database that maps to the schema 
--     of the replication control tables created in the Oracle 
--     database. This is also the schema of the Q Apply control
--     tables created in the Federated database.
-- (3) Locate and change the string !remote_schema! to the schema
--     of the replication control tables created in the Oracle database

--
-- Re-apply changes to control tables since Version 8.2 GA
--
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS VOLATILE CARDINALITY;
ALTER TABLE !local_schema!.IBMQREP_APPLYTRACE VOLATILE CARDINALITY;
ALTER TABLE !local_schema!.IBMQREP_APPLYMON VOLATILE CARDINALITY;

--
-- Changes to control tables for Version 9
--
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_MON_LIMIT;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_TRACE_LIMT;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_MON_INTERVAL;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_PRUNE_INTERVAL;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_AUTOSTOP;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_LOGREUSE;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_LOGSTDOUT;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_TERM;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS DROP CHECK CA_RETRIES;
  
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS
  ADD COLUMN SQL_CAP_SCHEMA VARCHAR(128) WITH DEFAULT NULL;
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0901'
  ALTER COLUMN MONITOR_INTERVAL SET DEFAULT 300000;
  
ALTER TABLE !local_schema!.IBMQREP_APPLYMON
  ADD COLUMN OLDEST_INFLT_TRANS TIMESTAMP;
  
UPDATE !local_schema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0901';
--
-- Starting V9.1, the values in the MONITOR_INTERVAL column
-- are interpreted as milliseconds. They were interpreted
-- as seconds in Version 8.
-- The following UPDATE statement is to change the unit
-- from second to millisecond by multiplying the current
-- values by 1000 during the migration of the control
-- tables from Version 8 to Version 9.1.
--
UPDATE !local_schema!.IBMQREP_APPLYPARMS
  SET MONITOR_INTERVAL = MONITOR_INTERVAL * 1000;
  
DROP NICKNAME !local_schema!.IBMQREP_RECVQUEUES;
DROP NICKNAME !local_schema!.IBMQREP_TARGETS;
DROP NICKNAME !local_schema!.IBMQREP_TRG_COLS;
DROP NICKNAME !local_schema!.IBMQREP_DONEMSG;
DROP NICKNAME !local_schema!.IBMQREP_EXCEPTIONS;
DROP NICKNAME !local_schema!.IBMQREP_SAVERI;
DROP NICKNAME !local_schema!.IBMQREP_SPILLEDROW;
--
SET PASSTHRU !server_name!;
ALTER TABLE !remote_schema!."IBMQREP_RECVQUEUES"
  DROP CONSTRAINT CC_SENDQ_STATE;
ALTER TABLE !remote_schema!."IBMQREP_RECVQUEUES"
  MODIFY (CAPTURE_SCHEMA VARCHAR2(128));
ALTER TABLE !remote_schema!."IBMQREP_RECVQUEUES"
  ADD (SOURCE_TYPE CHAR(1) DEFAULT ' ');  
  
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_TARGTBL_STATE;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_UPDATEANY;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_CONFLICTACTION;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_ERRORACTION;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_UPANY_SOURCE;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_UPANY_TARGET;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_TARGET_TYPE;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_GROUP_INIT_ROLE;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  DROP CONSTRAINT CA_LOAD_TYPE;
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  ADD (MODELQ VARCHAR2(36) DEFAULT 'IBMQREP.SPILL.MODELQ',
       CCD_CONDENSED CHARACTER(1)DEFAULT NULL,
       CCD_COMPLETE CHARACTER(1) DEFAULT NULL);
ALTER TABLE !remote_schema!."IBMQREP_TARGETS"
  ADD (SOURCE_TYPE CHAR(1) DEFAULT ' ');  
       
ALTER TABLE !remote_schema!."IBMQREP_TRG_COLS"
  DROP CONSTRAINT CA_IS_KEY;
ALTER TABLE !remote_schema!.IBMQREP_TRG_COLS
  MODIFY (SOURCE_COLNAME VARCHAR2(254) );
ALTER TABLE !remote_schema!.IBMQREP_TRG_COLS
  ADD (MAPPING_TYPE CHARACTER(1) DEFAULT NULL,
       SRC_COL_MAP VARCHAR2(2000) DEFAULT NULL,
       BEF_TARG_COLNAME VARCHAR2(128) DEFAULT NULL);

ALTER TABLE !remote_schema!."IBMQREP_EXCEPTIONS"
  DROP CONSTRAINT CA_IS_APPLIED;
ALTER TABLE !remote_schema!."IBMQREP_EXCEPTIONS"
  MODIFY (SRC_COMMIT_LSN RAW(48));
  
ALTER TABLE !remote_schema!."IBMQREP_SAVERI"
  DROP CONSTRAINT CA_TYPE_OF_LOAD;
ALTER TABLE !remote_schema!."IBMQREP_SAVERI"
  MODIFY (CONSTNAME VARCHAR2(128))
  ADD (DELETERULE CHARACTER(1) DEFAULT NULL,
       UPDATERULE CHARACTER(1) DEFAULT NULL);

COMMIT;
SET PASSTHRU RESET;
--
CREATE NICKNAME !local_schema!.IBMQREP_RECVQUEUES
  FOR !server_name!.!remote_schema!."IBMQREP_RECVQUEUES";
ALTER NICKNAME !local_schema!.IBMQREP_RECVQUEUES
  ALTER COLUMN NUM_APPLY_AGENTS LOCAL TYPE INTEGER
  ALTER COLUMN MEMORY_LIMIT LOCAL TYPE INTEGER;
  
CREATE NICKNAME !local_schema!.IBMQREP_TARGETS
  FOR !server_name!.!remote_schema!."IBMQREP_TARGETS";
ALTER NICKNAME !local_schema!.IBMQREP_TARGETS
  ALTER COLUMN SUB_ID LOCAL TYPE INTEGER
  ALTER COLUMN TARGET_TYPE LOCAL TYPE INTEGER
  ALTER COLUMN SOURCE_NODE LOCAL TYPE SMALLINT
  ALTER COLUMN TARGET_NODE LOCAL TYPE SMALLINT
  ALTER COLUMN LOAD_TYPE LOCAL TYPE SMALLINT;
  
CREATE NICKNAME !local_schema!.IBMQREP_TRG_COLS
  FOR !server_name!.!remote_schema!."IBMQREP_TRG_COLS";
  
CREATE NICKNAME !local_schema!.IBMQREP_DONEMSG
  FOR !server_name!.!remote_schema!."IBMQREP_DONEMSG";
  
CREATE NICKNAME !local_schema!.IBMQREP_EXCEPTIONS
  FOR !server_name!.!remote_schema!."IBMQREP_EXCEPTIONS";
ALTER NICKNAME !local_schema!.IBMQREP_EXCEPTIONS
  ALTER COLUMN SQLCODE LOCAL TYPE INTEGER;
  
CREATE NICKNAME !local_schema!.IBMQREP_SAVERI
  FOR !server_name!.!remote_schema!."IBMQREP_SAVERI";
  
CREATE NICKNAME !local_schema!.IBMQREP_SPILLEDROW
  FOR !server_name!.!remote_schema!."IBMQREP_SPILLEDROW";
  
UPDATE !local_schema!.IBMQREP_TARGETS SET TARGET_TYPE = 1 
      WHERE TARGET_TYPE=3;

UPDATE !local_schema!.IBMQREP_TRG_COLS SET MAPPING_TYPE = 'R';
COMMIT;
