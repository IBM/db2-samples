--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                         */
--      Version 10 for Linux, UNIX AND Windows                      */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT         */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2011. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate Q Apply control tables from V97FP3 to V10.
-- Q Apply Migration script 
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string 
--     !server_name! to the name of the remote server as
--     defined to the federated database
-- (2) Locate and change the string !appschema! to schema of the Q Apply control
--     tables created in the Federated database.
-- (3) Locate and change the string !remote_schema! to the schema
--     of the replication control tables created in the remote database
--

ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS 
  ADD COLUMN TRACE_DDL CHAR(1) NOT NULL WITH DEFAULT 'N';
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS   
  ADD COLUMN REPORT_EXCEPTIONS CHARACTER(1) NOT NULL WITH DEFAULT 'Y';
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS   
  ADD COLUMN ORACLE_EMPTY_STR CHARACTER(1) NOT NULL WITH DEFAULT 'N';
ALTER TABLE !APPSCHEMA!.IBMQREP_APPLYPARMS   
  ADD COLUMN LOGMARKERTZ CHARACTER(8) NOT NULL WITH DEFAULT 'GMT';
  
UPDATE !APPSCHEMA!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '1001';  
   
SET PASSTHRU !SERVER_NAME!;

ALTER TABLE "!REMOTE_SCHEMA!"."IBMQREP_TARGETS" 
  ADD SCHEMA_SUBNAME VARCHAR2(64);
ALTER TABLE "!REMOTE_SCHEMA!"."IBMQREP_TARGETS"   
  ADD SUB_CREATOR VARCHAR2(12); 

ALTER TABLE "!REMOTE_SCHEMA!"."IBMQREP_RECVQUEUES"   
 MODIFY (BROWSER_THREAD_ID VARCHAR2(9));

SET PASSTHRU reset;  

DROP NICKNAME !LOCAL_SCHEMA!.IBMQREP_TARGETS;
CREATE NICKNAME !LOCAL_SCHEMA!.IBMQREP_TARGETS FOR !SERVER_NAME!."!REMOTE_SCHEMA!"."IBMQREP_TARGETS";

ALTER NICKNAME !LOCAL_SCHEMA!.IBMQREP_RECVQUEUES
 ALTER COLUMN BROWSER_THREAD_ID LOCAL TYPE VARCHAR(9);
