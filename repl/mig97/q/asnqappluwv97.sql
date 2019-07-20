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

-- New Capture Parameter(s)
ALTER TABLE !appschema!.IBMQREP_APPLYPARMS 
  ADD COLUMN LOADCOPY_PATH  VARCHAR(1040) 
  ADD COLUMN NICKNAME_COMMIT_CT INTEGER WITH DEFAULT  10
  ADD COLUMN SPILL_COMMIT_COUNT INTEGER WITH DEFAULT  10
  ADD COLUMN LOAD_DATA_BUFF_SZ INTEGER WITH DEFAULT  8
  ADD COLUMN CLASSIC_LOAD_FL_SZ INTEGER WITH DEFAULT  500000
  ADD COLUMN MAX_PARALLEL_LOADS  INTEGER WITH DEFAULT  15
  ADD COLUMN COMMIT_COUNT INTEGER WITH DEFAULT  1
  ADD COLUMN INSERT_BIDI_SIGNAL CHAR(1) NOT NULL WITH DEFAULT 'Y';

ALTER TABLE !appschema!.IBMQREP_APPLYMON 
  ADD COLUMN OLDEST_COMMIT_LSN CHAR(10) FOR BIT DATA
  ADD COLUMN ROWS_PROCESSED INTEGER
  ADD COLUMN Q_PERCENT_FULL SMALLINT WITH DEFAULT NULL
  ADD COLUMN OLDEST_COMMIT_SEQ CHAR(10) FOR BIT DATA;

ALTER TABLE !appschema!.IBMQREP_EXCEPTIONS 
  ADD COLUMN SRC_TRANS_ID CHAR(48) FOR BIT DATA;

ALTER TABLE !appschema!.IBMQREP_TRG_COLS 
  ALTER COLUMN SOURCE_COLNAME SET DATA TYPE VARCHAR(1024);

ALTER TABLE !appschema!.IBMQREP_APPLYPARMS
  ALTER COLUMN ARCH_LEVEL SET DEFAULT '0907';

UPDATE !appschema!.IBMQREP_APPLYPARMS SET ARCH_LEVEL = '0907';

-- create indexes for performance improvement
ALTER TABLE !appschema!.IBMQREP_APPLYMON DROP PRIMARY KEY;
CREATE UNIQUE INDEX !appschema!.IX1APPMON ON !appschema!.IBMQREP_APPLYMON
(MONITOR_TIME DESC, RECVQ ASC);

DROP INDEX !appschema!.IX1TRCTMCOL;

CREATE INDEX !appschema!.IX1TRCTMCOL 
ON !appschema!.IBMQREP_APPLYTRACE (TRACE_TIME DESC);
