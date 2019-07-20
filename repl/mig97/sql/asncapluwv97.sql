--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.7 for Linux, UNIX AND Windows                      */
--                                                                   */
--     Sample SQL Replication optional migration script              */
--     for UNIX AND NT                                               */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2009. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/

-- Capture Migration script for V97

-- Script to migrate  Capture control tables from V95 to V97.
--
-- Prior to running this script, customize it to your existing 
-- Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the  Capture schema applicable to your
--     environment
--
-- (2) Run the script to migrate control tables into V97.
--


ALTER TABLE !capschema!.IBMSNAP_CAPMON 
  ADD COLUMN CURRENT_LOG_TIME TIMESTAMP;
ALTER TABLE !capschema!.IBMSNAP_CAPMON  
  ADD COLUMN RESTART_SEQ CHARACTER(10) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_CAPMON 
  ADD COLUMN CURRENT_SEQ CHARACTER(10) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_CAPMON 
  ADD COLUMN LAST_EOL_TIME TIMESTAMP;
  
  
-- added during V97FP1
-- run this sql if IBMQREP_IGNTRAN exist as part of the capture control tables
-- otherwise you will get SQL error
    
CREATE UNIQUE INDEX !capschema!.IGNTRANX ON !capschema!.IBMQREP_IGNTRAN
(
     AUTHID ASC,
     AUTHTOKEN ASC,
     PLANNAME ASC
  );
    
-- added during V97FP1
-- run this sql if IBMQREP_IGNTRANTRC exist as part of the capture control tables
-- otherwise you will get SQL error
    
CREATE INDEX !capschema!.IGNTRCX ON !capschema!.IBMQREP_IGNTRANTRC
(
     IGNTRAN_TIME ASC
);



