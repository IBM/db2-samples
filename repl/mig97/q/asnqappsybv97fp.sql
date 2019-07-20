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
-- Script to migrate Q Apply control tables from V97 to the latest V97 fixpack.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string !appschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Run the script to migrate control tables.
--
--***********************************************************
-- Segment to migrate Federated QApply to V97FP2 
--***********************************************************
-- Start v97FP2

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
  ADD COLUMN APPLY_ALIAS VARCHAR(8) WITH DEFAULT NULL ; 

ALTER NICKNAME !appschema!.IBMQREP_DONEMSG
  ALTER COLUMN MQMSGID OPTIONS (ADD BINARY_REP 'Y');
  
-- End of V97FP2     

-- Start v97FP3
DROP NICKNAME !appschema!.IBMQREP_RECVQUEUES;

SET PASSTHRU !server_name!;

ALTER TABLE "!remote_schema!"."IBMQREP_RECVQUEUES" 
  ADD ROLLBACK_R_REPORT CHARACTER(1) DEFAULT 'R' NOT NULL;

ALTER TABLE "!remote_schema!"."IBMQREP_RECVQUEUES"   
  ADD BROWSER_THREAD_ID CHARACTER(9);

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_T"
(
 ROLLBACK_TIME DATETIME default getDate(),
 QNAME VARCHAR(48),
 SUBNAME VARCHAR(132),
 SRC_TRANS_ID VARBINARY(48),
 FIRST_MQMSGID BINARY(24) null ,
 LAST_MQMSGID BINARY(24) default null null ,
 NUM_OF_ROWS INTEGER,
 REASON CHARACTER(1)
);

CREATE UNIQUE INDEX IX1ROLLBACK_T ON "!remote_schema!"."IBMQREP_ROLLBACK_T"
(
 QNAME,
 SRC_TRANS_ID
);

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_R"
(
 QNAME VARCHAR(48),
 SRC_TRANS_ID VARBINARY(48),
 ROW_NUMBER INTEGER default 0,
 STATUS CHARACTER(1),
 OPERATION CHARACTER(1),
 SQLCODE INTEGER default NULL null ,
 SQLSTATE VARCHAR(5) default null null ,
 SQLERRMC VARCHAR(70) default null null ,
 TEXT TEXT null 
);

CREATE UNIQUE INDEX IX2ROLLBACK_R ON "!remote_schema!"."IBMQREP_ROLLBACK_R"
(
 QNAME,
 SRC_TRANS_ID,
 ROW_NUMBER,
 STATUS
);


COMMIT; 

SET PASSTHRU RESET;

CREATE NICKNAME !appschema!.IBMQREP_RECVQUEUES FOR
 !server_name!."!remote_schema!"."IBMQREP_RECVQUEUES";

ALTER NICKNAME !appschema!.IBMQREP_RECVQUEUES
 ALTER COLUMN NUM_APPLY_AGENTS LOCAL TYPE INTEGER
 ALTER COLUMN MEMORY_LIMIT LOCAL TYPE INTEGER
 ALTER COLUMN MAXAGENTS_CORRELID LOCAL TYPE INTEGER;

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
  
-- End v97FP3  

-- Start of V97FP5

SET PASSTHRU !server_name!;

CREATE INDEX IX4TARGETS ON "!remote_schema!"."IBMQREP_TARGETS" ( SPILLQ, STATE);

CREATE INDEX IX1EXCEPTIONS  ON "!remote_schema!"."IBMQREP_EXCEPTIONS" ( EXCEPTION_TIME); 

set passthru reset;
-- End of V97FP5
