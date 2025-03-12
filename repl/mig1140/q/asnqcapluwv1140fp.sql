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
-- File name: asnqcapluwv1140fp.sql
--
-- Script to migrate Q Capture control tables from  V11.5 to the latest
-- fixpack.
--
-- Prior to running this script, customize it to your existing
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !CAPSCHEMA!
--     to the name of the Q Capture schema applicable to your
--     environment
--
--********************************************************************/

UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET CONTROL_TABLES_LEVEL = '1140.106';
UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET CURRENT_LEVEL = '1140.106';

ALTER TABLE !CAPSCHEMA!.IBMQREP_FILES_SENT ADD COLUMN FILE_SENDQ_NUM SMALLINT WITH DEFAULT NULL;
ALTER TABLE !CAPSCHEMA!.IBMQREP_FILESEND_MON ADD COLUMN FILES_BYTES_SENT BIGINT NOT NULL DEFAULT 0;
ALTER TABLE !CAPSCHEMA!.IBMQREP_FILE_SENDERS ADD COLUMN FILESEND_HEARTBEAT_SECONDS INT NOT NULL DEFAULT 10;

ALTER TABLE !CAPSCHEMA!.IBMQREP_FILESEND_MON RENAME COLUMN BYTES TO MQ_BYTES;
ALTER TABLE !CAPSCHEMA!.IBMQREP_FILESEND_MON RENAME COLUMN MESSAGES TO MQ_MESSAGES;	

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ALTER COLUMN CURRENT_MEMORY SET DATA TYPE BIGINT;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ALTER COLUMN MAX_TRANS_SIZE SET DATA TYPE BIGINT;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPQMON ALTER COLUMN MQ_BYTES SET DATA TYPE BIGINT;

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS ADD COLUMN DROPTAB_ACTION CHARACTER(1) NOT NULL WITH DEFAULT 'W';

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPQMON ADD COLUMN LOBXML_READ_TIME INT;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPQMON ADD COLUMN NUM_LOBXML_READ INT;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPQMON ADD COLUMN SEARCH_COND_EVAL_TIME INT;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPQMON ADD COLUMN NUM_SEARCH_COND_EVAL INT;

REORG TABLE !CAPSCHEMA!.IBMQREP_CAPMON;
REORG TABLE !CAPSCHEMA!.IBMQREP_CAPQMON;

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS ADD COLUMN TRANS_COMMIT_MODE INT;