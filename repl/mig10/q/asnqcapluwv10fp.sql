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
-- File name: asnqcapluwv10fp.sql
--
-- Script to migrate Q Capture control tables from  V10GA to the latest
-- fixpack.
--
-- Prior to running this script, customize it to your existing
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !CAPSCHEMA!
--     to the name of the Q Capture schema applicable to your
--     environment
--
--********************************************************************/

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS 
ADD COLUMN MAX_TRANS SMALLINT WITH DEFAULT 128;

ALTER TABLE !CAPSCHEMA!.IBMQREP_SENDQUEUES 
ADD COLUMN NUM_PARALLEL_SENDQS INTEGER NOT NULL WITH DEFAULT 1;

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPQMON 
ADD COLUMN XMITQDEPTH INTEGER;

