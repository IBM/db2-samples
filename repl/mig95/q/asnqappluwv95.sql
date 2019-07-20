-- Script to migrate Q Apply control tables from V9.1 to V9.5.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string !appschema! 
--     to the name of the Q Apply schema applicable to your
--     environment
--
-- (2) The new table !appschema!.IBMQREP_APPENVINFO added in V9.5. . 
--     This table is necessary for Repl Admin to operate with either 
--     Replication engine components or MQ server components successfully. 
-- 
-- (3) Run the script to migrate control tables into V9.
--

CREATE TABLE !appschema!.IBMQREP_APPENVINFO 
( NAME VARCHAR(30) NOT NULL,
  VALUE VARCHAR(3800) 
 ); 
 
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0905';
  
UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0905';

ALTER TABLE !appschema!.IBMQREP_RECVQUEUES
  ADD COLUMN MAXAGENTS_CORRELID INTEGER;

ALTER TABLE !appschema!.IBMQREP_APPLYMON
  ADD COLUMN JOB_DEPENDENCIES INTEGER
  ADD COLUMN CAPTURE_LATENCY INTEGER;

ALTER TABLE !appschema!.IBMQREP_APPLYTRACE
  ADD COLUMN REASON_CODE      INTEGER 
  ADD COLUMN MQ_CODE          INTEGER;
  
  


