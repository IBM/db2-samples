--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.7 for Linux, UNIX AND Windows                      */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT          */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2010. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate Q Apply control tables from V9.5 to V9.7.
-- Both the control tables created in the federated database and
-- in the informix database will be updated.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string 
--     !server_name! to the name of the sybase server as
--     defined to the federated database
-- (2) Locate and change the string !appschema! to the nickname 
--     defined on the federated database that maps to the schema 
--     of the replication control tables created in the sybase 
--     database. This is also the schema of the Q Apply control
--     tables created in the Federated database.
-- (3) Locate and change the string !remote_schema! to the schema
--     of the replication control tables created in the informix database


ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
  ADD COLUMN LOADCOPY_PATH  VARCHAR(1040) 
  ADD COLUMN NICKNAME_COMMIT_CT INTEGER WITH DEFAULT  10
  ADD COLUMN SPILL_COMMIT_COUNT INTEGER WITH DEFAULT  10
  ADD COLUMN LOAD_DATA_BUFF_SZ INTEGER WITH DEFAULT  8
  ADD COLUMN CLASSIC_LOAD_FL_SZ INTEGER WITH DEFAULT  500000
  ADD COLUMN MAX_PARALLEL_LOADS  INTEGER WITH DEFAULT  15
  ADD COLUMN COMMIT_COUNT INTEGER WITH DEFAULT  1
  ADD COLUMN INSERT_BIDI_SIGNAL CHAR(1) WITH DEFAULT 'Y';

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0973';

ALTER TABLE !appschema!.IBMQREP_APPLYMON 
  ADD COLUMN OLDEST_COMMIT_LSN CHAR(10) FOR BIT DATA
  ADD COLUMN ROWS_PROCESSED INTEGER
  ADD COLUMN Q_PERCENT_FULL SMALLINT
  ADD COLUMN OLDEST_COMMIT_SEQ CHAR(10) FOR BIT DATA;

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES 
  ADD COLUMN ROLLBACK_R_REPORT CHARACTER(1) DEFAULT 'R' NOT NULL
  ADD COLUMN BROWSER_THREAD_ID CHARACTER(9);  

-- create indexes for performance improvement
CREATE UNIQUE INDEX !appschema!.IX1APPLYMON ON !appschema!.IBMQREP_APPLYMON 
(MONITOR_TIME DESC, RECVQ ASC);

DROP INDEX !appschema!.IX1TRCTMCOL;

CREATE INDEX !appschema!.IX1TRCTMCOL 
ON !appschema!.IBMQREP_APPLYTRACE (TRACE_TIME DESC);
  
UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0907';

DROP NICKNAME !appschema!.IBMQREP_TRG_COLS;
DROP NICKNAME !appschema!.IBMQREP_EXCEPTIONS;


CREATE NICKNAME !appschema!.IBMQREP_TRG_COLS
  FOR !server_name!."!remote_schema!"."IBMQREP_TRG_COLS";

ALTER NICKNAME !appschema!.IBMQREP_TRG_COLS
 ALTER COLUMN SRC_COL_MAP LOCAL TYPE VARCHAR(2000);
   
CREATE NICKNAME !appschema!.IBMQREP_EXCEPTIONS
  FOR !server_name!."!remote_schema!"."IBMQREP_EXCEPTIONS";


ALTER NICKNAME !appschema!.IBMQREP_EXCEPTIONS
 ALTER COLUMN TEXT LOCAL TYPE VARCHAR(32672);

CREATE NICKNAME !appschema!.IBMQREP_ROLLBACK_T FOR
 !server_name!."!remote_schema!"."IBMQREP_ROLLBACK_T";

CREATE NICKNAME !appschema!.IBMQREP_ROLLBACK_R FOR
 !server_name!."!remote_schema!"."IBMQREP_ROLLBACK_R";

ALTER NICKNAME !appschema!.IBMQREP_ROLLBACK_R
 ALTER COLUMN TEXT LOCAL TYPE
 VARCHAR(32672);

COMMIT;

--
SET PASSTHRU !server_name!;

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_T"
(
 ROLLBACK_TIME DATETIME default getDate(),
 QNAME VARCHAR(48),
 SUBNAME VARCHAR(132),
 SRC_TRANS_ID VARBINARY(48),
 FIRST_MQMSGID BINARY(24) null ,
 LAST_MQMSGID BINARY(24) default null null ,
 NUM_OF_ROWS INTEGER,
 REASON CHARACTER(1)
);

CREATE UNIQUE INDEX IX1ROLLBACK_T ON "!remote_schema!"."IBMQREP_ROLLBACK_T"
(
 QNAME,
 SRC_TRANS_ID
);

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_R"
(
 QNAME VARCHAR(48),
 SRC_TRANS_ID VARBINARY(48),
 ROW_NUMBER INTEGER default 0,
 STATUS CHARACTER(1),
 OPERATION CHARACTER(1),
 SQLCODE INTEGER default NULL null ,
 SQLSTATE VARCHAR(5) default null null ,
 SQLERRMC VARCHAR(70) default null null ,
 TEXT TEXT null 
);

CREATE UNIQUE INDEX IX2ROLLBACK_R ON "!remote_schema!"."IBMQREP_ROLLBACK_R"
(
 QNAME,
 SRC_TRANS_ID,
 ROW_NUMBER,
 STATUS
);

ALTER TABLE "!remote_schema!"."IBMQREP_TRG_COLS"
  MODIFY SOURCE_COLNAME VARCHAR(1024);

ALTER TABLE "!remote_schema!"."IBMQREP_EXCEPTIONS"
  ADD SRC_TRANS_ID BINARY(48) NULL;

COMMIT; 

SET PASSTHRU RESET;
--
