--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version 10.5 Fixpak 7 for Linux, UNIX AND Windows             */
--                                                                   */
--     Sample SQL Replication migration script for UNIX AND NT       */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 2015. All Rights Reserved             */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate SQL Capture control tables from V10 to V10.5 Fixpak 7.
--
-- IMPORTANT:
-- * Please refer to the SQL Rep migration doc before attempting this migration.
--
-- Prior to running this script, customize it to your existing 
-- SQL Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the SQL Capture schema applicable to your
--     environment.
-- (2) Locate and change all occurrences of the string !captablespace! 
--     to the name of the tablespace where your SQL Capture control tables
--     are created.   
-- (3) Run the script to migrate control tables into V10.5 
--
--***********************************************************
UPDATE !capschema!.IBMSNAP_CAPPARMS SET ARCH_LEVEL = '1021';
UPDATE !capschema!.IBMSNAP_CAPPARMS SET COMPATIBILITY = '1021';
ALTER TABLE !capschema!.IBMQREP_IGNTRANTRC ALTER COLUMN TRANSID 
SET DATA TYPE VARCHAR( 12) FOR BIT DATA;

ALTER TABLE !capschema!.IBMSNAP_CAPMON ADD NUM_END_OF_LOGS INTEGER;
ALTER TABLE !capschema!.IBMSNAP_CAPMON ADD LOGRDR_SLEEPTIME INTEGER;
ALTER TABLE !capschema!.IBMSNAP_CAPMON ADD NUM_LOGREAD_F_CALLS INTEGER;
ALTER TABLE !capschema!.IBMSNAP_CAPMON ADD TRANS_QUEUED INTEGER;
ALTER TABLE !capschema!.IBMSNAP_CAPMON ADD NUM_WARNTXS INTEGER;
ALTER TABLE !capschema!.IBMSNAP_CAPMON ADD NUM_WARNLOGAPI INTEGER;

