--****************************************************************
--*                                                              *
--*    IBM Websphere Replication Server 9.7                      *
--*             for zOS (5655-I60)                               *
--*                                                              *
--*    Sample Q Replication control tables for zOS               *
--*    Licensed Materials - Property of IBM                      *
--*                                                              *
--*    (C) Copyright IBM Corp. 1993, 2009. All Rights Reserved   *
--*                                                              *
--*    US Government Users Restricted Rights - Use, duplication  *
--*    or disclosure restricted by GSA ADP Schedule Contract     *
--*    with IBM Corp.                                            *
--****************************************************************

-------------------------------------------------------------------
--      Q Capture Migration script 
-------------------------------------------------------------------
--
-- Script to migrate Q Capture control tables from V95 to V97.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- 
-- (2) Run the script to migrate control tables into V97.
--
-- (3) Run asnqupdcompv97.sql to set CAPPARMS COMPATIBILITY to 
--  the correct value depending on the level of QApply ARCH_LEVEL.  


-- New Capture Parameter(s)

ALTER TABLE !capschema!.IBMQREP_CAPPARMS                  
  ADD  MSG_PERSISTENCE  CHAR(1) WITH DEFAULT 'Y' ;  
ALTER TABLE !capschema!.IBMQREP_CAPPARMS                   
  ADD  LOGRDBUFSZ INTEGER WITH DEFAULT 66;           
                                                     
-- SQL statements for alter adding new columns:      
ALTER TABLE !capschema!.IBMQREP_CAPQMON                    
  ADD MQ_BYTES INTEGER ;                             
ALTER TABLE !capschema!.IBMQREP_CAPQMON                    
  ADD MQ_MESSAGES INTEGER  ;                         
ALTER TABLE !capschema!.IBMQREP_CAPQMON                    
  ADD CURRENT_SEQ CHAR(10) FOR BIT DATA ;               
ALTER TABLE !capschema!.IBMQREP_CAPQMON                    
  ADD RESTART_SEQ CHAR(10) FOR BIT DATA ;            
                                                     
ALTER TABLE !capschema!.IBMQREP_CAPMON                     
  ADD LOGREAD_API_TIME   INTEGER ;
ALTER TABLE !capschema!.IBMQREP_CAPMON           
  ADD NUM_LOGREAD_CALLS INTEGER;          
ALTER TABLE !capschema!.IBMQREP_CAPMON           
  ADD NUM_END_OF_LOGS INTEGER ;            
ALTER TABLE !capschema!.IBMQREP_CAPMON           
  ADD LOGRDR_SLEEPTIME INTEGER;           

ALTER TABLE !capschema!.IBMQREP_SUBS 
  ADD CAPTURE_LOAD CHAR(1) WITH DEFAULT 'W';  


ALTER TABLE !capschema!.IBMQREP_SENDQUEUES               
  ADD LOB_TOO_BIG_ACTION CHAR(1) NOT NULL WITH DEFAULT 'Q' ;
ALTER TABLE !capschema!.IBMQREP_SENDQUEUES               
  ADD XML_TOO_BIG_ACTION CHAR(1) NOT NULL WITH DEFAULT 'Q'; 
 
ALTER TABLE !capschema!.IBMQREP_COLVERSION           
  ADD CODEPAGE INTEGER; 
ALTER TABLE !capschema!.IBMQREP_COLVERSION           
  ADD SCALE INTEGER;
                                           
ALTER TABLE !capschema!.IBMQREP_CAPMON 
  DROP PRIMARY KEY;
ALTER TABLE !capschema!.IBMQREP_CAPQMON 
  DROP PRIMARY KEY;
                   
DROP INDEX   !capschema!.PKIBMQREP_CAPMON ;                               
DROP INDEX   !capschema!.PKIBMQREP_CAPQMON  ;    
         

COMMIT;

CREATE INDEX !capschema!.IX1CTRCTMCOL 
ON !capschema!.IBMQREP_CAPTRACE
( TRACE_TIME DESC);

CREATE UNIQUE INDEX !capschema!.IX1CAPMON 
ON !capschema!.IBMQREP_CAPMON
( MONITOR_TIME DESC);

CREATE UNIQUE INDEX !capschema!.IX1CAPQMON 
ON !capschema!.IBMQREP_CAPQMON
( MONITOR_TIME DESC, SENDQ ASC);

CREATE  INDEX !capschema!.PKIBMQREP_SIGNAL 
ON !capschema!.IBMQREP_SIGNAL ( SIGNAL_TIME );

-- added during V97FP1

CREATE UNIQUE INDEX !capschema!.IGNTRANX ON !capschema!.IBMQREP_IGNTRAN
(
 AUTHID ASC,
 AUTHTOKEN ASC,
 PLANNAME ASC
);

-- added during V97FP1

CREATE INDEX !capschema!.IGNTRCX ON !capschema!.IBMQREP_IGNTRANTRC
(
 IGNTRAN_TIME ASC
);


UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0907';


--  Set CAPPARMS COMPATIBILITY to the correct value
--  depending on the level of QApply ARCH_LEVEL.  It should
--  be set to Qapply ARCH_LEVEL.
--
--  If Qapply is running in 9.1, this value should be  0901.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0901';
--
--  If Qapply is running in 8.2 this value should be  0802.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0802';
--
--  If Qapply is running with 91 APAR PK49430 or above (Qapply
--  ARCH_LEVEL 0905), then COMPATIBILTY value should be  0905.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0905';

-- IIf Qapply is running in 9.7, this value should be  0907.
--  UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0907';

UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0905';


-- update the compatibility column to '0907' once all the receiving applys 
-- have been migrated to '0907'.


-------------------------------------------------------------------
--       Q Apply SERVER Migration script 
-------------------------------------------------------------------
-- Script to migrate Q Apply control tables from V95 to V97.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string !appschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- 
-- (2) Run the script to migrate control tables into V97.
--

-- SQL statements for alter adding new columns:


-- New Apply Parameter(s)


ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD LOADCOPY_PATH  VARCHAR(1040) ;                          
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD NICKNAME_COMMIT_CT INTEGER WITH DEFAULT  10 ;           
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD SPILL_COMMIT_COUNT INTEGER WITH DEFAULT  10  ;          
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD LOAD_DATA_BUFF_SZ INTEGER WITH DEFAULT  8   ;           
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD CLASSIC_LOAD_FL_SZ INTEGER WITH DEFAULT  500000 ;       
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD MAX_PARALLEL_LOADS  INTEGER WITH DEFAULT  1  ;  
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD COMMIT_COUNT INTEGER WITH DEFAULT  1 ;                  
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS                          
  ADD INSERT_BIDI_SIGNAL CHAR(1) WITH DEFAULT 'Y';            

ALTER TABLE !appschema!.IBMQREP_APPLYMON             
  ADD OLDEST_COMMIT_LSN CHAR(10) FOR BIT DATA ;  
ALTER TABLE !appschema!.IBMQREP_APPLYMON  
  ADD Q_PERCENT_FULL SMALLINT ;   
ALTER TABLE !appschema!.IBMQREP_APPLYMON             
  ADD ROWS_PROCESSED INTEGER;  
ALTER TABLE !appschema!.IBMQREP_APPLYMON             
  ADD OLDEST_COMMIT_SEQ CHAR(10) FOR BIT DATA ;

ALTER TABLE !appschema!.IBMQREP_EXCEPTIONS 
  ADD SRC_TRANS_ID CHAR(48) FOR BIT DATA;

ALTER TABLE !appschema!.IBMQREP_TRG_COLS 
  ALTER COLUMN SOURCE_COLNAME SET DATA TYPE VARCHAR(1024);

ALTER TABLE !appschema!.IBMQREP_APPLYMON  DROP PRIMARY KEY;

DROP INDEX !appschema!.PKIBMQREP_APPLYMON;

DROP INDEX !appschema!.IX1TRCTMCOL ;

COMMIT;

CREATE INDEX !appschema!.IX1TRCTMCOL 
ON !appschema!.IBMQREP_APPLYTRACE( TRACE_TIME DESC);

CREATE UNIQUE INDEX !appschema!.IX1APPMON 
ON !appschema!.IBMQREP_APPLYMON
( MONITOR_TIME DESC, RECVQ ASC);

UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0907';


-------------------------------------------------------------------
--      MONITOR SERVER Migration script 
-------------------------------------------------------------------

CREATE  INDEX !monschema!.IBMSNAP_MONTRAILX   
ON !monschema!.IBMSNAP_MONTRAIL(              
MONITOR_QUAL                    ASC,  
LASTRUN                         ASC); 


