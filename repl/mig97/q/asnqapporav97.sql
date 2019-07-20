--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.7 for Linux, UNIX AND Windows                      */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT          */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2009. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate Q Apply control tables from V9.5 to V9.7.
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


ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
  ADD COLUMN LOADCOPY_PATH  VARCHAR(1040) 
  ADD COLUMN NICKNAME_COMMIT_CT INTEGER WITH DEFAULT  10
  ADD COLUMN SPILL_COMMIT_COUNT INTEGER WITH DEFAULT  10
  ADD COLUMN LOAD_DATA_BUFF_SZ INTEGER WITH DEFAULT  8
  ADD COLUMN CLASSIC_LOAD_FL_SZ INTEGER WITH DEFAULT  500000
  ADD COLUMN MAX_PARALLEL_LOADS  INTEGER WITH DEFAULT  15
  ADD COLUMN COMMIT_COUNT INTEGER WITH DEFAULT  1
  ADD COLUMN INSERT_BIDI_SIGNAL CHAR(1) WITH DEFAULT 'Y';

ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0907';

ALTER TABLE !local_schema!.IBMQREP_APPLYMON 
  ADD COLUMN OLDEST_COMMIT_LSN CHAR(10) FOR BIT DATA
  ADD COLUMN ROWS_PROCESSED INTEGER
  ADD COLUMN Q_PERCENT_FULL SMALLINT
  ADD COLUMN OLDEST_COMMIT_SEQ CHAR(10) FOR BIT DATA;  

-- create indexes for performance improvement
CREATE UNIQUE INDEX !local_schema!.IX1APPLYMON ON !local_schema!.IBMQREP_APPLYMON 
(MONITOR_TIME DESC, RECVQ ASC);

DROP INDEX !local_schema!.IX1TRCTMCOL;

CREATE INDEX !local_schema!.IX1TRCTMCOL 
ON !local_schema!.IBMQREP_APPLYTRACE (TRACE_TIME DESC);
  
UPDATE !local_schema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0907';

DROP NICKNAME !local_schema!.IBMQREP_TRG_COLS;
DROP NICKNAME !local_schema!.IBMQREP_EXCEPTIONS;

--
SET PASSTHRU !server_name!;


ALTER TABLE "!remote_schema!"."IBMQREP_TRG_COLS"
  MODIFY (SOURCE_COLNAME VARCHAR2(1024));

ALTER TABLE "!remote_schema!"."IBMQREP_EXCEPTIONS"
  ADD (SRC_TRANS_ID RAW (48) );

COMMIT;
SET PASSTHRU RESET;
--

  
CREATE NICKNAME !local_schema!.IBMQREP_TRG_COLS
  FOR !server_name!."!remote_schema!"."IBMQREP_TRG_COLS";
   
ALTER NICKNAME !local_schema!.IBMQREP_TRG_COLS
 ALTER COLUMN TARGET_COLNO LOCAL TYPE INTEGER
 ALTER COLUMN MSG_COL_CODEPAGE LOCAL TYPE INTEGER
 ALTER COLUMN MSG_COL_NUMBER LOCAL TYPE SMALLINT
 ALTER COLUMN MSG_COL_TYPE LOCAL TYPE SMALLINT
 ALTER COLUMN MSG_COL_LENGTH LOCAL TYPE INTEGER;
CREATE NICKNAME !local_schema!.IBMQREP_EXCEPTIONS
  FOR !server_name!."!remote_schema!"."IBMQREP_EXCEPTIONS";

ALTER NICKNAME !local_schema!.IBMQREP_EXCEPTIONS
 ALTER COLUMN SQLCODE LOCAL TYPE INTEGER
 ALTER COLUMN TEXT LOCAL TYPE CLOB(32768);

COMMIT;
