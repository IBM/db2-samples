--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version 11.4.0 for Linux, UNIX AND Windows                   */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND Windows    */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 2019. All Rights Reserved             */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate Q Apply control tables from V11.1 to V11.5 or higher
-- Q Apply Migration script (asnqappluwv1140.sql)
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string !APPSCHEMA! 
--     to the name of the Q Apply schema applicable to your
--     environment
-- (2) Locate and change all occurrences of the string !APPTABLESPACE! 
--     to the name of the tablespace where the Q Apply control tables 
--     are created
-- (3) Run the script to migrate control tables into V11.5
--

UPDATE !APPSCHEMA!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '1140';
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN POSSIBLE_LEVEL VARCHAR(10) WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN CURRENT_LEVEL VARCHAR(10) WITH DEFAULT '1140.101';
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN CONTROL_TABLES_LEVEL VARCHAR(10) WITH DEFAULT '1140.101';
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN SKIP_SPILLEDROW_TABLE CHARACTER(1) NOT NULL WITH DEFAULT 'Y';

ALTER TABLE !APPSCHEMA!.IBMQREP_RECVQUEUES ADD COLUMN HAS_FILERECV CHARACTER(1) WITH DEFAULT 'N';
ALTER TABLE !APPSCHEMA!.IBMQREP_RECVQUEUES ADD COLUMN NUM_STREAM_AGENTS INTEGER WITH DEFAULT 0;
ALTER TABLE !APPSCHEMA!.IBMQREP_RECVQUEUES ADD COLUMN CAPTURE_LEVEL VARCHAR(10) WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_RECVQUEUES ADD COLUMN DELAYIN_INTERVAL INTEGER NOT NULL WITH DEFAULT 3000;

ALTER TABLE !APPSCHEMA!.IBMQREP_TARGETS  ADD COLUMN SOURCE_IS_COLUMNAR CHARACTER(1) WITH DEFAULT 'N';

ALTER TABLE !APPSCHEMA!.IBMQREP_TRG_COLS  ADD COLUMN IS_PART_KEY SMALLINT NOT NULL WITH DEFAULT 0;

ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON  ADD COLUMN TRANS_STREAMING INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON  ADD COLUMN TRANS_STREAM_BEGIN INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON  ADD COLUMN TRANS_STREAM_COMMIT INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON  ADD COLUMN TRANS_STREAM_ROLLBACK INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON  ADD COLUMN STREAM_CHUNKS_APPLIED INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON  ADD COLUMN STREAM_CHUNKS_PROCESSED INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON  ADD COLUMN TABLE_DEPENDENCIES INTEGER WITH DEFAULT NULL;


CREATE TABLE !APPSCHEMA!.IBMQREP_FILE_RECEIVERS
(
 QMAPNAME VARCHAR(128) NOT NULL,
 FILERECV_PATH VARCHAR(1040) NOT NULL,
 FILERECV_QUEUE VARCHAR(48) NOT NULL,
 FILERECV_ACK_QUEUE VARCHAR(48) NOT NULL,
 FILERECV_PRUNE_LIMIT INTEGER NOT NULL WITH DEFAULT 1440 ,
 FILERECV_PARALLEL_DEGREE SMALLINT NOT NULL WITH DEFAULT 1 ,
 FILERECV_DELETE_IMMED CHARACTER(1) NOT NULL WITH DEFAULT 'N',
 FILERECV_MAX_DISK_SPACE BIGINT NOT NULL WITH DEFAULT 0
)
ORGANIZE BY ROW
 IN !APPTABLESPACE!;


CREATE UNIQUE INDEX !APPSCHEMA!.IX1FILERECVS ON !APPSCHEMA!.IBMQREP_FILE_RECEIVERS
(
 QMAPNAME
);


CREATE TABLE !APPSCHEMA!.IBMQREP_FILES_RECEIVED
(
 FILE_ID VARBINARY(16) NOT NULL,
 QMAPNAME VARCHAR(128) NOT NULL,
 SUB_ID INTEGER NOT NULL,
 UOW VARBINARY(12),
 TARGET_FILENAME VARCHAR(1040) NOT NULL,
 SOURCE_FILENAME VARCHAR(1040) NOT NULL,
 STATUS CHARACTER(1) NOT NULL,
 RC INTEGER,
 RC_TEXT VARCHAR(128),
 TOTAL_FILE_SIZE BIGINT,
 LAST_BYTE_RECEIVED BIGINT,
 LAST_MSG_TIME TIMESTAMP,
 LAST_MSG_SIZE BIGINT,
 LAST_MSG_ID BINARY(24),
 COORD_MSG_ID BINARY(24)
)
ORGANIZE BY ROW
 IN !APPTABLESPACE!;


CREATE UNIQUE INDEX !APPSCHEMA!.IX1FILESRECVD ON !APPSCHEMA!.IBMQREP_FILES_RECEIVED
(
 FILE_ID,
 QMAPNAME,
 SUB_ID
);

CREATE INDEX !APPSCHEMA!.IX3FILESRECVD ON !APPSCHEMA!.IBMQREP_FILES_RECEIVED
(
QMAPNAME,
STATUS
)
ALLOW REVERSE SCANS COLLECT SAMPLED DETAILED STATISTICS;


CREATE TABLE !APPSCHEMA!.IBMQREP_FILERECV_MON
(
 MONITOR_TIME TIMESTAMP NOT NULL,
 QMAPNAME VARCHAR(128) NOT NULL,
 BYTES BIGINT,
 MESSAGES INTEGER NOT NULL,
 QDEPTH INTEGER NOT NULL,
 FILES_STARTED INTEGER NOT NULL,
 FILES_COMPLETED INTEGER NOT NULL,
 FILES_DELETED INTEGER NOT NULL,
 FILES_FAILED INTEGER NOT NULL,
 FILES_HOLD INTEGER NOT NULL,
 MQGET_TIME INTEGER NOT NULL,
 DISK_USAGE BIGINT NOT NULL,
 DISK_USAGE_HOLD_FILES BIGINT NOT NULL,
 DISK_FULL_WAIT_TIME INTEGER NOT NULL,
 IDLE_TIME INTEGER NOT NULL
)
ORGANIZE BY ROW
 IN !APPTABLESPACE!;


CREATE UNIQUE INDEX !APPSCHEMA!.IX1FILERECVMON ON !APPSCHEMA!.IBMQREP_FILERECV_MON
(
 MONITOR_TIME,
 QMAPNAME
);

ALTER TABLE !APPSCHEMA!.IBMQREP_TARGETS ADD COLUMN HAS_PARTS CHAR(1) NOT NULL WITH DEFAULT 'N';
