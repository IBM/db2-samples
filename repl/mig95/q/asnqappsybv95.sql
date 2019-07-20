-- Script to migrate Q Apply control tables from V9.1 to V9.5
-- Both the control tables created in the federated database and
-- in the Sybase database will be updated.
--
-- Prior to running this script, customize it to your existing 
-- Q Apply server environment:
-- (1) Locate and change all occurrences of the string 
--     !server_name! to the name of the Sybase server as
--     defined to the federated database
-- (2) Locate and change the string !local_schema! to the nickname 
--     defined on the federated database that maps to the schema 
--     of the replication control tables created in the Sybase 
--     database. This is also the schema of the Q Apply control
--     tables created in the federated database.
-- (3) Locate and change the string !remote_schema! to the schema
--     of the replication control tables created in the Sybase database

 
 CREATE TABLE !local_schema!.IBMQREP_APPENVINFO 
( NAME VARCHAR(30) NOT NULL,
  VALUE VARCHAR(3800) 
 ); 
 
ALTER TABLE !local_schema!.IBMQREP_APPLYPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0905';
  
UPDATE !local_schema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0905';

ALTER TABLE !local_schema!.IBMQREP_APPLYMON
  ADD COLUMN JOB_DEPENDENCIES INTEGER
  ADD COLUMN CAPTURE_LATENCY INTEGER;

ALTER TABLE !local_schema!.IBMQREP_APPLYTRACE
  ADD COLUMN REASON_CODE      INTEGER 
  ADD COLUMN MQ_CODE          INTEGER;
  
DROP NICKNAME !local_schema!.IBMQREP_RECVQUEUES;

COMMIT;

--

SET PASSTHRU !server_name!;

ALTER TABLE "!remote_schema!".IBMQREP_RECVQUEUES 
  ADD MAXAGENTS_CORRELID INTEGER NULL;
COMMIT;

-- 

SET PASSTHRU RESET;
CREATE NICKNAME !local_schema!.IBMQREP_RECVQUEUES FOR !server_name!."!remote_schema!".IBMQREP_RECVQUEUES;

COMMIT;
