--********************************************************************/
--                                                                   */
--    IBM InfoSphere Replication Server                              */
--    Version 11.4.0 FPs for Linux, UNIX AND Windows                 */
--                                                                   */
--    Sample Q Replication migration script for UNIX AND NT          */
--    Licensed Materials - Property of IBM                           */
--                                                                   */
--    (C) Copyright IBM Corp. 1993, 2019. All Rights Reserved        */
--                                                                   */
--    US Government Users Restricted Rights - Use, duplication       */
--    or disclosure restricted by GSA ADP Schedule Contract          */
--    with IBM Corp.                                                 */
--                                                                   */
--********************************************************************/
-- File name: asnmonluwv1140fp.sql
--
-- Script to migrate Alert Monitor control tables from V11.5 to the latest
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
DROP INDEX !SCHEMA!.IBMSNAP_MONSERVERSX;
CREATE UNIQUE INDEX !SCHEMA!.IBMSNAP_MONSERVERSX ON !SCHEMA!.IBMSNAP_MONSERVERS(MONITOR_QUAL ASC,SERVER_NAME ASC,SERVER_ALIAS ASC);
reorg table !SCHEMA!.IBMSNAP_MONSERVERS;

ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ADD TLS_KEYDB varchar(1040);
ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ADD TLS_LABEL varchar(128);
ALTER TABLE !SCHEMA!.IBMSNAP_MONPARMS ALTER COLUMN ALERTS_FILE_PATH SET DATA TYPE VARCHAR(4096) FOR BIT DATA;
reorg table !SCHEMA!.IBMSNAP_MONPARMS;
