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
-- File name: asnoqcapluwv10fp.sql
--
-- Script to migrate Oracle Q Capture control tables from  V10GA to
-- the latest fixpack.
--
-- Prior to running this script, customize it to your existing
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema!
--     to the name of the Q Capture schema applicable to your
--     environment
--
--********************************************************************/

ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
ADD (MAX_TRANS SMALLINT DEFAULT 128);

ALTER TABLE !capschema!.IBMQREP_SENDQUEUES 
ADD (NUM_PARALLEL_SENDQS INTEGER DEFAULT 1 NOT NULL);

ALTER TABLE !capschema!.IBMQREP_CAPQMON 
ADD (XMITQDEPTH INTEGER);

