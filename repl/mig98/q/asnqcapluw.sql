--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.8 (DB2 V9.8FP2) for Linux, UNIX AND Windows        */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT         */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2010. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate Q Capture control tables from V97FP2 to V98FP2.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Run the script to migrate control tables into V97FP2.
--
--***********************************************************
-- Segment to migrate QCapture to V98FP2 
--***********************************************************

-- Start v98FP2

ALTER TABLE !capschema!.IBMQREP_SIGNAL DATA CAPTURE NONE;
ALTER TABLE !capschema!.IBMQREP_SIGNAL ALTER COLUMN SIGNAL_LSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMQREP_SIGNAL DATA CAPTURE CHANGES;
REORG TABLE !capschema!.IBMQREP_SIGNAL;
UPDATE !capschema!.IBMQREP_SIGNAL SET SIGNAL_LSN=CONCAT(x'000000000000', SIGNAL_LSN);

ALTER TABLE !capschema!.IBMQREP_CAPMON ALTER COLUMN RESTART_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMQREP_CAPMON ALTER COLUMN CURRENT_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMQREP_CAPMON;
UPDATE !capschema!.IBMQREP_CAPMON SET RESTART_SEQ=CONCAT(x'000000000000', RESTART_SEQ);
UPDATE !capschema!.IBMQREP_CAPMON SET CURRENT_SEQ=CONCAT(x'000000000000', CURRENT_SEQ);

ALTER TABLE !capschema!.IBMQREP_CAPQMON ALTER COLUMN RESTART_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
ALTER TABLE !capschema!.IBMQREP_CAPQMON ALTER COLUMN CURRENT_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMQREP_CAPQMON;
UPDATE !capschema!.IBMQREP_CAPQMON SET RESTART_SEQ=CONCAT(x'000000000000', RESTART_SEQ);
UPDATE !capschema!.IBMQREP_CAPQMON SET CURRENT_SEQ=CONCAT(x'000000000000', CURRENT_SEQ);

ALTER TABLE !capschema!.IBMQREP_IGNTRANTRC ALTER COLUMN COMMITLSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;
REORG TABLE !capschema!.IBMQREP_IGNTRANTRC;
UPDATE !capschema!.IBMQREP_IGNTRANTRC SET COMMITLSN=CONCAT(x'000000000000', COMMITLSN);

UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0908';
UPDATE !capschema!.IBMQREP_CAPPARMS SET COMPATIBILITY= '0908';


-- End of V98FP2    

