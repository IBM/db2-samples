--********************************************************************/
--                                                                   */
--    IBM InfoSphere Replication Server                              */
--    Version 10.2.1 FPs for Linux, UNIX AND Windows                     */
--                                                                   */
--    Sample Q Replication migration script for UNIX AND NT          */
--    Licensed Materials - Property of IBM                           */
--                                                                   */
--    (C) Copyright IBM Corp. 1993, 2016. All Rights Reserved        */
--                                                                   */
--    US Government Users Restricted Rights - Use, duplication       */
--    or disclosure restricted by GSA ADP Schedule Contract          */
--    with IBM Corp.                                                 */
--                                                                   */
--********************************************************************/
-- File name: asnmonluwv1021fp.sql
--
-- Script to migrate Alert Monitor control tables from V10.5 Fixpak 7 to the latest
-- fixpack.
--
-- Prior to running this script, customize it to your existing
-- Alert Monitor server environment:
-- (1) Locate and change all occurrences of the string !SCHEMA!
--     to the name of the Alert Monitor schema applicable to your
--     environment
--
--
--********************************************************************/

ALTER TABLE !SCHEMA!.IBMSNAP_ALERTS ALTER COLUMN CONDITION_NAME SET DATA TYPE VARCHAR(20);
ALTER TABLE !SCHEMA!.IBMSNAP_CONDITIONS ALTER COLUMN CONDITION_NAME SET DATA TYPE VARCHAR(20);
ALTER TABLE !SCHEMA!.IBMSNAP_CONDITIONS ADD COLUMN SERVER_DBMS_TYPE CHAR(1) NOT NULL DEFAULT 'D';
ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ADD COLUMN ALERTS_TOTABLE CHAR (1) NOT NULL DEFAULT 'Y';
ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ADD COLUMN ALERTS_TOFILE CHAR (1) NOT NULL DEFAULT 'N';
ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ADD COLUMN ALERTS_FILESZ INTEGER NOT NULL DEFAULT 1;
ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ADD COLUMN ALERTS_FILE_PATH VARCHAR (128);
ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ALTER COLUMN ARCH_LEVEL SET DEFAULT '1021';
UPDATE !SCHEMA!.IBMSNAP_MONPARMS SET ARCH_LEVEL='1021';
reorg table !SCHEMA!.IBMSNAP_ALERTS;
reorg table !SCHEMA!.IBMSNAP_CONDITIONS;
reorg table !SCHEMA!.IBMSNAP_MONPARMS;
