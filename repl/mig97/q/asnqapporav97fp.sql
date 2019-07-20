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
--     to the name of the Q Apply schema applicable to your
--     environment
-- (2) Locate and change all occurrences of the string !remote_schema!
--     to the name of the remote Oracle user applicable to your
--     environment
-- (3) Locate and change all occurrences of !server_name! to the name of 
--     server definition
-- (4) Run the script to migrate control tables to the latest v97 fixpack.
--
--***********************************************************
-- Segment to migrate QApply to V97FP2 
--***********************************************************
-- Start v97FP2

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
  ADD COLUMN APPLY_ALIAS VARCHAR(8) WITH DEFAULT NULL ; 

ALTER NICKNAME !appschema!.IBMQREP_DONEMSG
  ALTER COLUMN RECVQ OPTIONS (ADD VARCHAR_NO_TRAILING_BLANKS 'Y');
     
ALTER NICKNAME !appschema!.IBMQREP_SPILLEDROW 
  ALTER COLUMN SPILLQ
  OPTIONS (ADD VARCHAR_NO_TRAILING_BLANKS 'Y');

ALTER NICKNAME !appschema!.IBMQREP_SPILLQS
  ALTER COLUMN SPILLQ
  OPTIONS (ADD VARCHAR_NO_TRAILING_BLANKS 'Y');

COMMIT;
  
-- End of V97FP2  

--***********************************************************
-- Segment to migrate QApply to V97FP3 
--***********************************************************
-- Start v97FP3

--
DROP NICKNAME !appschema!.IBMQREP_RECVQUEUES;

SET PASSTHRU !server_name!;

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_T"
(
 ROLLBACK_TIME TIMESTAMP DEFAULT SYSDATE NOT NULL ,
 QNAME VARCHAR2(48) NOT NULL ,
 SUBNAME VARCHAR2(132) NOT NULL ,
 SRC_TRANS_ID RAW(48) NOT NULL ,
 FIRST_MQMSGID RAW(24),
 LAST_MQMSGID RAW(24) DEFAULT NULL,
 NUM_OF_ROWS NUMBER(10) NOT NULL ,
 REASON CHARACTER(1) NOT NULL 
);

CREATE UNIQUE INDEX IX1ROLLBACK_T ON "!remote_schema!"."IBMQREP_ROLLBACK_T"
(
 QNAME,
 SRC_TRANS_ID
);

CREATE TABLE "!remote_schema!"."IBMQREP_ROLLBACK_R"
(
 QNAME VARCHAR2(48) NOT NULL ,
 SRC_TRANS_ID RAW(48) NOT NULL ,
 ROW_NUMBER NUMBER(10) DEFAULT 0 NOT NULL ,
 STATUS CHARACTER(1) NOT NULL ,
 OPERATION CHARACTER(1) NOT NULL ,
 SQLCODE NUMBER(10) DEFAULT NULL,
 SQLSTATE VARCHAR2(5) DEFAULT NULL,
 SQLERRMC VARCHAR2(70) DEFAULT NULL,
 TEXT CLOB
);

CREATE UNIQUE INDEX IX2ROLLBACK_R ON "!remote_schema!"."IBMQREP_ROLLBACK_R"
(
 QNAME,
 SRC_TRANS_ID,
 ROW_NUMBER,
 STATUS
);

-- RECVQUEUES table

ALTER TABLE !remote_schema!.IBMQREP_RECVQUEUES
ADD ROLLBACK_R_REPORT CHAR(1) DEFAULT 'R' NOT NULL;

ALTER TABLE !remote_schema!.IBMQREP_RECVQUEUES
ADD BROWSER_THREAD_ID CHAR(9) ;


set passthru reset;

CREATE NICKNAME !appschema!.IBMQREP_RECVQUEUES FOR
 !server_name!."!remote_schema!"."IBMQREP_RECVQUEUES";

ALTER NICKNAME !appschema!.IBMQREP_RECVQUEUES
 ALTER COLUMN NUM_APPLY_AGENTS LOCAL TYPE INTEGER
 ALTER COLUMN MEMORY_LIMIT LOCAL TYPE INTEGER
 ALTER COLUMN MAXAGENTS_CORRELID LOCAL TYPE INTEGER;

CREATE NICKNAME !appschema!.IBMQREP_ROLLBACK_T FOR
 !server_name!."!remote_schema!"."IBMQREP_ROLLBACK_T";

ALTER NICKNAME !appschema!.IBMQREP_ROLLBACK_T
 ALTER COLUMN NUM_OF_ROWS LOCAL
 TYPE INTEGER;

CREATE NICKNAME !appschema!.IBMQREP_ROLLBACK_R FOR
 !server_name!."!remote_schema!"."IBMQREP_ROLLBACK_R";

ALTER NICKNAME !appschema!.IBMQREP_ROLLBACK_R
 ALTER COLUMN ROW_NUMBER LOCAL
 TYPE INTEGER
 ALTER COLUMN SQLCODE LOCAL TYPE INTEGER
 ALTER COLUMN
 TEXT LOCAL TYPE CLOB(32768);

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
