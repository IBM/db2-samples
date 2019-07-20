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
-- (3) This is rollback script to update capture server ibmqrep_capparms table 
--     compatibility columns to '0901' and ARCH_LEVEL column to '0901'.
--     This will tell capture to send V9.1 messages to apply.
--     Control table structure will not fallback to V9.1 structure.
--     V9.5 new columns will be tolerated by V9.1 Q Capture and Q Apply.
--     Only the COMPATIBILITY and ARCH_LEVEL need to be updated
--     to '0901'.
-- (4) This is only applicable for z/OS environment; For LUW when you fallback
--     V9.1 Q Capture and Q Apply you get the V9.1 replication control table too.

-- For Q Capture server

UPDATE !capschema!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0901';
UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0901'; 

COMMIT;

-- For Q Apply Server

UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0901'; 

COMMIT;

---------------------------END--------------------------------------------
