--********************************************************************/
--                                                                   */
--    IBM InfoSphere Replication Server                              */
--    Version 10.5 FPs for Linux, UNIX AND Windows                     */
--                                                                   */
--    Sample Q Replication migration script for UNIX AND NT          */
--    Licensed Materials - Property of IBM                           */
--                                                                   */
--    (C) Copyright IBM Corp. 1993, 2015. All Rights Reserved        */
--                                                                   */
--    US Government Users Restricted Rights - Use, duplication       */
--    or disclosure restricted by GSA ADP Schedule Contract          */
--    with IBM Corp.                                                 */
--                                                                   */
--********************************************************************/
-- File name: asnqappluwv1021fp.sql
--
-- Script to migrate Q Apply control tables from V10.5 Fixpak 7 to the latest
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

ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN NUM_MQMSGS INTEGER WITH DEFAULT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN WARNTXLATENCY INTEGER WITH DEFAULT 0 NOT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN WARNTXEVTS INTEGER WITH DEFAULT 10 NOT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN WARNTXRESET INTEGER WITH DEFAULT 300000 NOT NULL;
ALTER TABLE !APPSCHEMA!.IBMQREP_TARGETS ADD COLUMN CODEPAGE_EXPAND_FACTOR SMALLINT WITH DEFAULT 1;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD OLDEST_COMMIT_TIME TIMESTAMP;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYMON ADD COLUMN NUM_DBMS_COMMITS INTEGER WITH DEFAULT 0;
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS ADD COLUMN COMMIT_COUNT_UNIT CHAR(1) WITH DEFAULT 'T';
ALTER TABLE !APPSCHEMA!.IBMQREP_TARGETS ADD COLUMN CCD_KEYUPD_AS_DELINS CHAR(1) WITH DEFAULT 'N';

