--
-- This is an optional migration.
-- Edit command, changing 'capture_server' to match your environment
-- before executing.
--
ALTER TABLE capture_schema.IBMQREP_IGNTRAN
ADD COLUMN IGNTRANTRC CHAR(1) NOT NULL DEFAULT 'Y'; 

