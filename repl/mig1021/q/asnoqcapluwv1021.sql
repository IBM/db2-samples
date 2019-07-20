--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
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
-- Script to migrate Oracle Q Capture control tables from V10 
-- or V105FP[1-6] to V10.5 FP7 or higher
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !CAPSCHEMA! 
--     to the name of the Q Capture schema applicable to your
--     environment
-- (2) Update the compatibility only after all the Q apply instances are migrated to 1021 level

UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '1021';
-- UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '1021';

UPDATE  !CAPSCHEMA!.IBMQREP_SENDQUEUES SET HEARTBEAT_INTERVAL = HEARTBEAT_INTERVAL *1000;
ALTER TABLE IBMQREP_SENDQUEUES MODIFY (HEARTBEAT_INTERVAL  DEFAULT 60000);
ALTER TABLE !CAPSCHEMA!.IBMQREP_SENDQUEUES ADD MCGNAME VARCHAR2(64) DEFAULT NULL;

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS MODIFY (MAX_TRANS DEFAULT 200);
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS ADD REPROCESS_SIGNALS CHAR(1) DEFAULT 'N';
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS ADD LOG_COMMIT_INTERVAL NUMBER(10) DEFAULT 30;

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD NUM_LOGREAD_F_CALLS NUMBER(10);
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD TRANS_QUEUED NUMBER(10);
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD NUM_WARNTXS NUMBER(10);
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPMON ADD NUM_WARNLOGAPI NUMBER(10);

ALTER TABLE !CAPSCHEMA!.IBMQREP_SRC_COLS ADD CODEPAGE_OVERRIDE NUMBER(10) DEFAULT NULL;


ALTER TABLE !CAPSCHEMA!.IBMQREP_IGNTRANTRC MODIFY (TRANSID RAW( 12));
ALTER TABLE !CAPSCHEMA!.IBMQREP_TABVERSION ADD PSID NUMBER(10);
ALTER TABLE !CAPSCHEMA!.IBMQREP_TABVERSION ADD VERSION_TIME TIMESTAMP DEFAULT SYSTIMESTAMP ;
ALTER TABLE !CAPSCHEMA!.IBMQREP_COLVERSION ADD VERSION_TIME TIMESTAMP DEFAULT SYSTIMESTAMP ;

