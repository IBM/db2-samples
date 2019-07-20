--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.7 for Linux, UNIX AND Windows                      */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT          */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2009. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Q Capture Migration script (asnqcapluwv97.sql)

-- Script to migrate Q Capture control tables from V95 to V97.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
--
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the Q Capture schema applicable to your
--     environment
--
-- (2) Run the script to migrate control tables into V97.
--
-- (3) Run asnqupdcompv97.sql to set CAPPARMS COMPATIBILITY to 
--  the correct value depending on the level of QApply ARCH_LEVEL.  
--  
--
-- SQL statements for alter adding new columns:

-- New Capture Parameter(s)

ALTER TABLE !capschema!.IBMQREP_CAPPARMS 
  ADD COLUMN MSG_PERSISTENCE  CHAR(1) WITH DEFAULT 'Y'
  ADD COLUMN LOGRDBUFSZ INTEGER WITH DEFAULT 256;


ALTER TABLE !capschema!.IBMQREP_CAPQMON 
  ADD COLUMN MQ_BYTES INTEGER
  ADD COLUMN MQ_MESSAGES INTEGER
  ADD COLUMN CURRENT_SEQ CHAR(10) FOR BIT DATA
  ADD COLUMN RESTART_SEQ CHAR(10) FOR BIT DATA ;

ALTER TABLE !capschema!.IBMQREP_CAPMON 
  ADD COLUMN LOGREAD_API_TIME   INTEGER
  ADD COLUMN NUM_LOGREAD_CALLS INTEGER 
  ADD COLUMN NUM_END_OF_LOGS INTEGER
  ADD COLUMN LOGRDR_SLEEPTIME INTEGER;

ALTER TABLE !capschema!.IBMQREP_SUBS 
  ADD COLUMN CAPTURE_LOAD CHAR(1) NOT NULL WITH DEFAULT 'W';

ALTER TABLE !capschema!.IBMQREP_SENDQUEUES
  ADD COLUMN LOB_TOO_BIG_ACTION CHAR(1) NOT NULL WITH DEFAULT 'Q'
  ADD COLUMN XML_TOO_BIG_ACTION CHAR(1) NOT NULL WITH DEFAULT 'Q';
  
  
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

ALTER TABLE !capschema!.IBMQREP_CAPPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0907';

UPDATE !capschema!.IBMQREP_CAPPARMS SET ARCH_LEVEL = '0907';

--  Run asnqupdcompv97.sql to set CAPPARMS COMPATIBILITY to the correct value
--  depending on the level of QApply ARCH_LEVEL.  


-- create indexes for performance improvement

ALTER TABLE !capschema!.IBMQREP_CAPMON DROP PRIMARY KEY;
CREATE UNIQUE INDEX !capschema!.IX1CAPMON ON !capschema!.IBMQREP_CAPMON (MONITOR_TIME DESC);

ALTER TABLE !capschema!.IBMQREP_CAPQMON DROP PRIMARY KEY;
CREATE UNIQUE INDEX !capschema!.IX1CAPQMON ON !capschema!.IBMQREP_CAPQMON (MONITOR_TIME DESC, SENDQ ASC);

DROP INDEX !capschema!.IX1TRCTMCOL;
CREATE INDEX !capschema!.IX1TRCTMCOL ON !capschema!.IBMQREP_CAPTRACE (TRACE_TIME DESC);

