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
---(2) Locate and change all occurances of the string !apptablespace!
--     to the name of the tablespace where the Q Capture control
--     tables are created.
--***********************************************************
-- Segment to migrate QApply to V97FP2 
--***********************************************************

-- Start v97FP2

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
  ADD COLUMN APPLY_ALIAS VARCHAR(8) WITH DEFAULT NULL ; 
  
-- End of V97FP2 


-- Start of V97FP3

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

-- RECVQUEUES:

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES
ADD COLUMN   ROLLBACK_R_REPORT CHAR(1) NOT NULL WITH DEFAULT 'R';

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES
ADD COLUMN   BROWSER_THREAD_ID CHAR(9) ;

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

CREATE TABLE !appschema!.IBMQREP_ROLLBACK_T
(
 ROLLBACK_TIME TIMESTAMP NOT NULL WITH DEFAULT CURRENT TIMESTAMP,
 QNAME VARCHAR(48) NOT NULL,
 SUBNAME VARCHAR(132) NOT NULL,
 SRC_TRANS_ID VARCHAR(48) FOR BIT DATA NOT NULL,
 FIRST_MQMSGID CHARACTER(24) FOR BIT DATA,
 LAST_MQMSGID CHARACTER(24) FOR BIT DATA WITH DEFAULT NULL,
 NUM_OF_ROWS INTEGER NOT NULL,
 REASON CHARACTER(1) NOT NULL
)
 IN !apptablespace!;


CREATE UNIQUE INDEX !appschema!.IX1ROLLBACK_T ON !appschema!.IBMQREP_ROLLBACK_T
(
 QNAME ASC,
 SRC_TRANS_ID ASC
);


CREATE TABLE !appschema!.IBMQREP_ROLLBACK_R
(
 QNAME VARCHAR(48) NOT NULL,
 SRC_TRANS_ID VARCHAR(48) FOR BIT DATA NOT NULL,
 ROW_NUMBER INTEGER NOT NULL WITH DEFAULT 0,
 STATUS CHARACTER(1) NOT NULL,
 OPERATION CHARACTER(1) NOT NULL,
 SQLCODE INTEGER WITH DEFAULT NULL,
 SQLSTATE VARCHAR(5) WITH DEFAULT NULL,
 SQLERRMC VARCHAR(70) WITH DEFAULT NULL,
 TEXT CLOB(32768) NOT LOGGED NOT COMPACT
)
 IN !apptablespace!;


CREATE UNIQUE INDEX !appschema!.IX2ROLLBACK_R ON !appschema!.IBMQREP_ROLLBACK_R
(
 QNAME ASC,
 SRC_TRANS_ID ASC,
 ROW_NUMBER ASC,
 STATUS ASC
);

-- End of V97FP3

-- Start of V97FP5

CREATE INDEX !appschema!.IX4TARGETS ON !appschema!.IBMQREP_TARGETS ( SPILLQ, STATE); 

CREATE INDEX !appschema!.IX1EXCEPTIONS  ON !appschema!.IBMQREP_EXCEPTIONS ( EXCEPTION_TIME); 

-- End of V97FP5
