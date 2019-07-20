--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                         */
--      Version 10.2.1 for Linux, UNIX AND Windows                       */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND Windows    */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2015. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Q Capture Migration script (asnqcapluwv1021.sql)

-- Script to migrate Q Capture control tables from V10 or V105FP[1-6]
-- versions to V105FP7 or higher.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
--
-- (1) Locate and change all occurrences of the string !CAPSCHEMA! 
--     to the name of the Q Capture schema applicable to your
--     environment.
-- (2) Locate and change all occurrences of the string !CAPTABLESPACE! if exists
--     to the name of the tablespace where your Q Capture control tables
--     are created.
-- (3) Run the script to migrate control tables into V105FP6.
--
-- (4) Do not update the compatibility to 1021 unless all the Q apply instances are migrated to 1021.

UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '1021';

-- UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '1021';

UPDATE  !CAPSCHEMA!.IBMQREP_SENDQUEUES SET HEARTBEAT_INTERVAL = HEARTBEAT_INTERVAL *1000;
ALTER TABLE !CAPSCHEMA!.IBMQREP_SENDQUEUES ALTER COLUMN HEARTBEAT_INTERVAL SET DEFAULT 60000;

ALTER TABLE !CAPSCHEMA!.IBMQREP_SENDQUEUES ADD COLUMN MCGNAME VARCHAR(64) WITH DEFAULT NULL;

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS ALTER COLUMN MAX_TRANS SET DEFAULT 200;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS ADD COLUMN REPROCESS_SIGNALS CHAR(1) WITH DEFAULT 'N';
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS ADD COLUMN LOG_COMMIT_INTERVAL INTEGER WITH DEFAULT 30;

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD COLUMN NUM_LOGREAD_F_CALLS INTEGER;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD COLUMN TRANS_QUEUED INTEGER;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD COLUMN NUM_WARNTXS INTEGER;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD COLUMN NUM_WARNLOGAPI INTEGER;

ALTER TABLE !CAPSCHEMA!.IBMQREP_SRC_COLS ADD COLUMN CODEPAGE_OVERRIDE INTEGER WITH DEFAULT NULL;


ALTER TABLE !CAPSCHEMA!.IBMQREP_IGNTRANTRC ALTER COLUMN TRANSID SET DATA TYPE VARCHAR( 12) FOR BIT DATA;
REORG TABLE !CAPSCHEMA!.IBMQREP_IGNTRANTRC;
ALTER TABLE !CAPSCHEMA!.IBMQREP_TABVERSION ADD COLUMN PSID SMALLINT;
ALTER TABLE !CAPSCHEMA!.IBMQREP_TABVERSION ADD COLUMN VERSION_TIME TIMESTAMP DEFAULT ;
ALTER TABLE !CAPSCHEMA!.IBMQREP_COLVERSION ADD COLUMN VERSION_TIME TIMESTAMP DEFAULT ;

