--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                         */
--      Version 9.7FPs for Linux, UNIX AND Windows                   */
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
-- Script to migrate Q Apply control tables from V97 to the latest V97 fixpack
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string 
--     !server_name! to the name of the informix server as
--     defined to the federated database
-- (2) Locate and change the string !appschema! to the nickname 
--     defined on the federated database that maps to the schema 
--     of the replication control tables created in the informix 
--     database. This is also the schema of the Q Apply control
--     tables created in the Federated database.
-- (3) Locate and change the string !remote_schema! to the schema
--     of the replication control tables created in the informix database
--
--***********************************************************
-- Segment to migrate Federated QApply to V97FP2 
--***********************************************************
-- Start v97FP2

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
  ADD COLUMN APPLY_ALIAS VARCHAR(8) WITH DEFAULT NULL ; 

-- End of V97FP2

-- Start v97fp3
DROP NICKNAME !appschema!.IBMQREP_RECVQUEUES;

SET PASSTHRU !server_name!;

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_T"
(
 ROLLBACK_TIME DATETIME YEAR TO FRACTION(5) DEFAULT CURRENT YEAR TO
 FRACTION(5) NOT NULL ,
 QNAME VARCHAR(48) NOT NULL ,
 SUBNAME VARCHAR(132) NOT NULL ,
 SRC_TRANS_ID BYTE NOT NULL ,
 FIRST_MQMSGID BYTE,
 LAST_MQMSGID BYTE DEFAULT NULL,
 NUM_OF_ROWS INTEGER NOT NULL ,
 REASON CHARACTER(1) NOT NULL 
);

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_R"
(
 QNAME VARCHAR(48) NOT NULL ,
 SRC_TRANS_ID BYTE NOT NULL ,
 ROW_NUMBER INTEGER DEFAULT 0 NOT NULL ,
 STATUS CHARACTER(1) NOT NULL ,
 OPERATION CHARACTER(1) NOT NULL ,
 SQLCODE INTEGER DEFAULT NULL,
 SQLSTATE VARCHAR(5) DEFAULT NULL,
 SQLERRMC VARCHAR(70) DEFAULT NULL,
 TEXT TEXT
);

ALTER TABLE "!remote_schema!"."IBMQREP_RECVQUEUES" 
  ADD ROLLBACK_R_REPORT CHARACTER(1) DEFAULT 'R' NOT NULL;

ALTER TABLE "!remote_schema!"."IBMQREP_RECVQUEUES"   
  ADD BROWSER_THREAD_ID CHARACTER(9);


COMMIT;
SET PASSTHRU RESET;

CREATE NICKNAME !appschema!.IBMQREP_RECVQUEUES FOR
 !server_name!."!remote_schema!"."IBMQREP_RECVQUEUES";

ALTER NICKNAME !appschema!.IBMQREP_RECVQUEUES
 ALTER COLUMN NUM_APPLY_AGENTS LOCAL TYPE INTEGER
 ALTER COLUMN MEMORY_LIMIT LOCAL TYPE INTEGER
 ALTER COLUMN MAXAGENTS_CORRELID LOCAL TYPE INTEGER;

CREATE NICKNAME !appschema!.IBMQREP_ROLLBACK_T FOR
 !server_name!."!remote_schema!"."IBMQREP_ROLLBACK_T";

ALTER NICKNAME !appschema!.IBMQREP_ROLLBACK_T
 ALTER COLUMN SRC_TRANS_ID
 LOCAL TYPE VARCHAR(48) FOR BIT DATA
 ALTER COLUMN FIRST_MQMSGID LOCAL
 TYPE CHARACTER(24) FOR BIT DATA
 ALTER COLUMN LAST_MQMSGID LOCAL TYPE
 CHARACTER(24) FOR BIT DATA;

CREATE NICKNAME !appschema!.IBMQREP_ROLLBACK_R FOR
 !server_name!."!remote_schema!"."IBMQREP_ROLLBACK_R";

ALTER NICKNAME !appschema!.IBMQREP_ROLLBACK_R
 ALTER COLUMN SRC_TRANS_ID
 LOCAL TYPE VARCHAR(48) FOR BIT DATA
 ALTER COLUMN TEXT LOCAL TYPE
 VARCHAR(32672);
 
-- APPLYPARMS table

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS     
ADD COLUMN PRUNE_METHOD INT DEFAULT 2;         
                                               
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS     
ADD COLUMN PRUNE_BATCH_SIZE INT DEFAULT 1000;  
                                               
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS     
ADD COLUMN   IGNBADDATA CHAR(1) NOT NULL WITH DEFAULT 'N';   
                                               
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS     
ADD COLUMN   P2P_2NODES CHAR(1) NOT NULL WITH DEFAULT 'N';   
                                               
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS     
ADD COLUMN   STARTALLQ CHAR(1) NOT NULL DEFAULT 'Y';    
                                               
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS     
ADD COLUMN RICHKLVL  INT DEFAULT 2;      

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS
ADD COLUMN   NMI_ENABLE CHAR(1) DEFAULT 'N';

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS
ADD COLUMN   NMI_SOCKET_NAME VARCHAR(256) ;

UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0973'; 
 
  
-- APPLYMON:

ALTER TABLE !appschema!.IBMQREP_APPLYMON 
ALTER COLUMN OLDEST_COMMIT_LSN SET DATA TYPE VARCHAR(16) FOR BIT DATA;
	
ALTER TABLE !appschema!.IBMQREP_APPLYMON 
ALTER COLUMN OLDEST_COMMIT_SEQ SET DATA TYPE VARCHAR(16) FOR BIT DATA;

ALTER TABLE !appschema!.IBMQREP_APPLYMON 
ADD COLUMN MQ_BYTES INTEGER;

ALTER TABLE !appschema!.IBMQREP_APPLYMON 
ADD COLUMN MQGET_TIME INTEGER;

ALTER TABLE !appschema!.IBMQREP_APPLYMON 
ADD COLUMN NUM_MQGETS INTEGER;

REORG TABLE !appschema!.IBMQREP_APPLYMON;  
  
COMMIT;

-- End of V97FP3 


-- Start of V97FP5

SET PASSTHRU !server_name!;

CREATE INDEX IX4TARGETS ON "!remote_schema!"."IBMQREP_TARGETS" ( SPILLQ, STATE); 

CREATE INDEX IX1EXCEPTIONS  ON "!remote_schema!"."IBMQREP_EXCEPTIONS" ( EXCEPTION_TIME); 

set passthru reset;
-- End of V97FP5

