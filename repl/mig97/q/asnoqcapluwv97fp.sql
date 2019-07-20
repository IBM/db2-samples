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
-- Script to migrate Oracle Q Capture control tables from V97 to the latest fixpack.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string QASN 
--     to the name of the Q Capture schema applicable to your
--     environment
--
--
--***********************************************************
-- Segment to migrate QCapture to V97FP2 
--***********************************************************

-- Start v97FP2

-- create IBMQREP_PART_HIST table

CREATE TABLE QASN.IBMQREP_PART_HIST
(
LSN              RAW(16),
HISTORY_TIME      TIMESTAMP                 NOT NULL,
TABSCHEMA         VARCHAR2(128)              NOT NULL,
TABNAME           VARCHAR2(128)              NOT NULL,
DATAPARTITIONID   INTEGER                   NOT NULL,
TBSPACEID         INTEGER                   NOT NULL,
PARTITIONOBJECTID INTEGER                   NOT NULL,
PRIMARY KEY (LSN, TABSCHEMA, TABNAME, DATAPARTITIONID,
TBSPACEID, PARTITIONOBJECTID)
);

-- alter add new columns 

ALTER TABLE QASN.IBMQREP_CAPPARMS ADD CAPTURE_ALIAS VARCHAR2(8) DEFAULT NULL ;  

UPDATE QASN.IBMQREP_SRC_COLS
  SET COL_OPTIONS_FLAG= 'YNNNNNNNNN'
  WHERE IS_KEY > 0;
 
-- End of V97FP2    



-- Start of V97FP3    

-- CAPPARMS:

ALTER TABLE QASN.IBMQREP_CAPPARMS         
ADD STALE NUMBER(10) DEFAULT 3600 NOT NULL ;

ALTER TABLE QASN.IBMQREP_CAPPARMS         
ADD WARNLOGAPI NUMBER(10) DEFAULT 0 NOT NULL ;                                                 
                                                 
ALTER TABLE QASN.IBMQREP_CAPPARMS         
ADD TRANS_BATCH_SZ NUMBER(10) DEFAULT 1 NOT NULL ;          
                                                 
ALTER TABLE QASN.IBMQREP_CAPPARMS         
ADD PART_HIST_LIMIT  NUMBER(10) DEFAULT 10080 NOT NULL ;     
                                                 
ALTER TABLE QASN.IBMQREP_CAPPARMS         
ADD  STARTALLQ CHAR(1) DEFAULT 'Y' NOT NULL ;      

ALTER TABLE QASN.IBMQREP_CAPPARMS
ADD  NMI_ENABLE CHAR(1) DEFAULT 'N' NOT NULL ;

ALTER TABLE QASN.IBMQREP_CAPPARMS
ADD  NMI_SOCKET_NAME VARCHAR2(256) DEFAULT NULL;

UPDATE QASN.IBMQREP_CAPPARMS   SET ARCH_LEVEL = '0973';  


--************************************************************

-- SIGNAL
ALTER TABLE QASN.IBMQREP_SIGNAL 
  MODIFY SIGNAL_LSN  RAW(16);


--************************************************************

-- CAPMON:  
ALTER TABLE QASN.IBMQREP_CAPMON         
ADD RESTART_MAXCMTSEQ RAW(16);

ALTER TABLE QASN.IBMQREP_CAPMON         
MODIFY RESTART_SEQ  RAW(16);

ALTER TABLE QASN.IBMQREP_CAPMON         
MODIFY CURRENT_SEQ  RAW(16);

ALTER TABLE QASN.IBMQREP_CAPMON         
ADD MQCMIT_TIME NUMBER(10);

--************************************************************

-- CAPQMON:  
ALTER TABLE QASN.IBMQREP_CAPQMON         
ADD RESTART_MAXCMTSEQ RAW(16);

ALTER TABLE QASN.IBMQREP_CAPQMON         
MODIFY RESTART_SEQ  RAW(16);

ALTER TABLE QASN.IBMQREP_CAPQMON         
MODIFY CURRENT_SEQ  RAW(16);

ALTER TABLE QASN.IBMQREP_CAPQMON         
ADD MQPUT_TIME NUMBER(10);

-- IGNTRANTRC

ALTER TABLE QASN.IBMQREP_IGNTRANTRC         
MODIFY COMMITLSN  RAW(16);

-- SUBS:

ALTER TABLE QASN.IBMQREP_SUBS         
ADD CHANGE_CONDITION VARCHAR2(2048);

ALTER TABLE QASN.IBMQREP_SUBS         
ADD IGNCASDEL CHARACTER(1) DEFAULT 'N' NOT NULL;

ALTER TABLE QASN.IBMQREP_SUBS         
ADD IGNTRIG CHARACTER(1) DEFAULT 'N' NOT NULL;

ALTER TABLE QASN.IBMQREP_SUBS         
ADD LOGRD_ERROR_ACTION CHARACTER(1) DEFAULT 'D' NOT NULL;



-- End of V97FP3


-- Start of V97FP5

CREATE INDEX IX1SUBS ON QASN.IBMQREP_SUBS( SUB_ID );       

-- End of V97FP5  
