-- Script to migrate Q Capture control tables from V9.1 to V9.5.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) The new table !capschema!.IBMQREP_CAPENVINFO added in V9.5. . 
--     This table is necessary for Repl Admin to operate with either 
--     Replication engine components or MQ server components successfully. 
--
-- (3) Please uncomment the "alter add column IGNTRAN_TIME" if  the
--    capture control tables are created using V91GA level.
-- 
-- (4) Run the script to migrate control tables into V95.
--

CREATE TABLE !capschema!.IBMQREP_CAPENVINFO 
( NAME VARCHAR(30) NOT NULL,
  VALUE VARCHAR(3800) 
 ); 

ALTER TABLE !capschema!.IBMQREP_CAPPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0905';
  

ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
  ADD COLUMN LOB_SEND_OPTION   CHAR(1) DEFAULT 'I'
  ADD COLUMN QFULL_NUM_RETRIES   INTEGER NOT NULL DEFAULT 30
  ADD COLUMN QFULL_RETRY_DELAY INTEGER NOT NULL DEFAULT 250;
 
UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0905'; 

UPDATE !capschema!.IBMQREP_CAPPARMS SET LOB_SEND_OPTION = 'S'; 
  

ALTER TABLE !capschema!.IBMQREP_SENDQUEUES 
  ADD COLUMN SENDRAW_IFERROR   CHAR(1) NOT NULL DEFAULT 'N'
  ADD COLUMN COLUMN_DELIMITER  CHAR(1) 
  ADD COLUMN STRING_DELIMITER  CHAR(1) 
  ADD COLUMN RECORD_DELIMITER  CHAR(1)  
  ADD COLUMN DECIMAL_POINT     CHAR(1);
  
ALTER TABLE !capschema!.IBMQREP_CAPQMON 
  ADD COLUMN LOBS_TOO_BIG       INTEGER NOT NULL DEFAULT 0
  ADD COLUMN XMLDOCS_TOO_BIG   INTEGER NOT NULL DEFAULT 0
  ADD COLUMN QFULL_ERROR_COUNT INTEGER NOT NULL DEFAULT 0
  ;
   
ALTER TABLE !capschema!.IBMQREP_CAPTRACE 
  ADD COLUMN REASON_CODE      INTEGER 
  ADD COLUMN MQ_CODE          INTEGER ;
  
ALTER TABLE !capschema!.IBMQREP_IGNTRAN
  ADD COLUMN IGNTRANTRC       CHAR(1) NOT NULL DEFAULT 'Y';  

-- this particular alter applicable only if customer created 
-- capture control tables using V91GA level.

-- ALTER TABLE !capschema!.IBMQREP_IGNTRANTRC
-- ADD COLUMN IGNTRAN_TIME TIMESTAMP NOT NULL DEFAULT CURRENT TIMESTAMP;  




