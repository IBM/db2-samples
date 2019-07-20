--********************************************************************/
--                                                                   */
--    IBM InfoSphere Replication Server                              */
--    Version 10 FPs for Linux, UNIX AND Windows                     */
--                                                                   */
--    Sample Q Replication migration script for UNIX AND NT          */
--    Licensed Materials - Property of IBM                           */
--                                                                   */
--    (C) Copyright IBM Corp. 1993, 2011. All Rights Reserved        */
--                                                                   */
--    US Government Users Restricted Rights - Use, duplication       */
--    or disclosure restricted by GSA ADP Schedule Contract          */
--    with IBM Corp.                                                 */
--                                                                   */
--********************************************************************/
-- File name: asnqappluwv10fp.sql
--
-- Script to migrate Q Apply control tables from V10GA to the latest
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

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
ADD COLUMN MULTI_ROW_INSERT CHARACTER(1) WITH DEFAULT 'Y'
ADD COLUMN EVENT_LIMIT INTEGER NOT NULL WITH DEFAULT 100080
ADD COLUMN EVENT_GEN CHARACTER(1) NOT NULL WITH DEFAULT 'N'
ADD COLUMN EVENT_INTERVAL INTEGER NOT NULL WITH DEFAULT 1000
ADD COLUMN EIF_HBINT INTEGER NOT NULL WITH DEFAULT 10000
ADD COLUMN EIF_CONN1 VARCHAR(291)
ADD COLUMN EIF_CONN2 VARCHAR(291);

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES 
ADD COLUMN PARALLEL_SENDQS CHARACTER(1) NOT NULL WITH DEFAULT 'N';

ALTER TABLE !appschema!.IBMQREP_EXCEPTIONS 
ADD COLUMN SRC_INTENTSEQ VARCHAR(16) FOR BIT DATA
ADD COLUMN AUTHID VARCHAR(128)
ADD COLUMN AUTHTOKEN VARCHAR(30)
ADD COLUMN PLANNAME VARCHAR(8);

