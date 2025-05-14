--********************************************************************/
--                                                                   */
--    IBM InfoSphere Replication Server                              */
--    Version 11.5 FPs for Linux, UNIX AND Windows                   */
--                                                                   */
--    Sample Q Replication migration script for UNIX AND NT          */
--    Licensed Materials - Property of IBM                           */
--                                                                   */
--    (C) Copyright IBM Corp. 2019. All Rights Reserved              */
--                                                                   */
--    US Government Users Restricted Rights - Use, duplication       */
--    or disclosure restricted by GSA ADP Schedule Contract          */
--    with IBM Corp.                                                 */
--                                                                   */
--********************************************************************/
-- File name: asnqappluwv1140fp.sql
--
-- Script to migrate Q Apply control tables from V11.5 to the latest
-- fixpack.
--
-- Prior to running this script, customize it to your existing
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !appschema!
--     to the name of the Q Capture schema applicable to your
--     environment
--
--
--********************************************************************/

UPDATE !APPSCHEMA!.IBMQREP_APPLYPARMS SET CONTROL_TABLES_LEVEL = '1140.106';
UPDATE !APPSCHEMA!.IBMQREP_APPLYPARMS SET CURRENT_LEVEL = '1140.106';

ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN SERIALIZE_TRUNCATES CHARACTER(1) NOT NULL DEFAULT 'N';

ALTER TABLE !APPSCHEMA!.IBMQREP_TARGETS ADD COLUMN LOAD_CREATETAB_REMOTESOURCE SMALLINT NOT NULL DEFAULT 0;

ALTER TABLE !APPSCHEMA!.IBMQREP_FILES_RECEIVED ADD COLUMN FILE_RECVQ_NUM SMALLINT WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_FILE_RECEIVERS ADD COLUMN SEQREAD_THRES_DISK_SPACE SMALLINT NOT NULL DEFAULT 50;
ALTER TABLE !APPSCHEMA!.IBMQREP_FILERECV_MON ADD COLUMN FILES_BYTES_RECEIVED BIGINT NOT NULL DEFAULT 0;

ALTER TABLE !APPSCHEMA!.IBMQREP_FILERECV_MON RENAME COLUMN BYTES TO MQ_BYTES;
ALTER TABLE !APPSCHEMA!.IBMQREP_FILERECV_MON RENAME COLUMN MESSAGES TO MQ_MESSAGES;	
ALTER TABLE !APPSCHEMA!.IBMQREP_FILE_RECEIVERS RENAME COLUMN FILERECV_MAX_DISK_SPACE TO MAX_DISK_SPACE;

ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN CURRENT_DELAYIN INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN NUM_DELAY_OPS INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN NUM_DELAY_ROWS INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN NUM_DELAY_ROWS_APPLIED INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ALTER COLUMN CURRENT_MEMORY SET DATA TYPE BIGINT;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ALTER COLUMN MQ_BYTES SET DATA TYPE BIGINT;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN TABLES_LOADED INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN ROWS_LOADED BIGINT WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN TABLES_LOADED_PHYSICAL_SIZE BIGINT WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN TABLES_LOADED_LOGICAL_SIZE BIGINT WITH DEFAULT NULL;


REORG TABLE !APPSCHEMA!.IBMQREP_APPLYMON;

