-- Script to migrate Q Capture control tables from V9.1 to V9.5.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Run the script to  update capture server ibmqrep_capparms table compatibility
--   columns to '0905'. This will tell capture to send V9.5 messages to apply.
--


UPDATE !capschema!.IBMQREP_CAPPARMS SET COMPATIBILITY = '0905';
COMMIT;
