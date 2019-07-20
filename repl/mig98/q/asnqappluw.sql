--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.8FP2 for Linux, UNIX AND Windows                   */
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
-- Script to migrate Q Apply control tables from V97FP2 to V98FP2.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string !appschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Run the script to migrate control tables into V97FP2.
--
--***********************************************************
-- Segment to migrate Federated QApply to V98FP2 
--***********************************************************

-- Start v98FP2

ALTER TABLE !appschema!.IBMQREP_APPLYMON 
	ALTER COLUMN OLDEST_COMMIT_LSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;
	
ALTER TABLE !appschema!.IBMQREP_APPLYMON 
	ALTER COLUMN OLDEST_COMMIT_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;

REORG TABLE !appschema!.IBMQREP_APPLYMON;

UPDATE !appschema!.IBMQREP_APPLYMON SET OLDEST_COMMIT_LSN=CONCAT(x'000000000000', OLDEST_COMMIT_LSN);

UPDATE !appschema!.IBMQREP_APPLYMON SET OLDEST_COMMIT_SEQ=CONCAT(x'000000000000', OLDEST_COMMIT_SEQ);

UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0908';

-- End of V98FP2 
