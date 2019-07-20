--********************************************************************/
--                                                                   */
--          IBM Websphere Replication Server                         */
--      Version 9.7 for zOS (5655-I60)                               */
--                                                                   */
--     Sample SQL Replication optional migration script              */
--     for ZOS                                                       */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2009. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/

--------------------------------------------------------------------
--        Capture Migration script 
--------------------------------------------------------------------

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
  ADD CURRENT_LOG_TIME TIMESTAMP;
ALTER TABLE !capschema!.IBMSNAP_CAPMON  
  ADD RESTART_SEQ CHARACTER(10) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_CAPMON 
  ADD CURRENT_SEQ CHARACTER(10) FOR BIT DATA;
ALTER TABLE !capschema!.IBMSNAP_CAPMON 
  ADD LAST_EOL_TIME TIMESTAMP;

--  execute this SQL if !capschema!.IBMQREP_IGNTRAN table exist
--  otherwise you will get an sql error.
-- This is added as part of V97FP1

CREATE UNIQUE INDEX ASN5.IGNTRANX ON !capschema!.IBMQREP_IGNTRAN
(
 AUTHID ASC,
 AUTHTOKEN ASC,
 PLANNAME ASC
);

--  execute this SQL if !capschema!.IBMQREP_IGNTRANTRC table exist
--  otherwise you will get an sql error.
-- This is added as part of V97FP1

CREATE INDEX ASN5.IGNTRCX ON !capschema!.IBMQREP_IGNTRANTRC
(
 IGNTRAN_TIME ASC
);
