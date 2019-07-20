--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                        */
--      Version 10 for Linux, UNIX AND Windows                       */
--                                                                   */
--     Sample Q Replication migration script for UNIX AND NT         */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2011. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate Oracle Q Capture control tables from V97 to V10
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
-- (1) Locate and change all occurrences of the string !CAPSCHEMA! 
--     to the name of the Q Capture schema applicable to your
--     environment
--

UPDATE !CAPSCHEMA!.IBMQREP_CAPPARMS   SET ARCH_LEVEL = '1001';  

ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS 
  ADD WARNTXSZ NUMBER(10) DEFAULT 0 NOT NULL;
ALTER TABLE !CAPSCHEMA!.IBMQREP_CAPPARMS 
  ADD LOGSPOOLING CHARACTER(1) DEFAULT 'N' NOT NULL;  
  
ALTER TABLE !CAPSCHEMA!.IBMQREP_SUBS 
  ADD SCHEMA_SUBNAME VARCHAR2(64);  
ALTER TABLE !CAPSCHEMA!.IBMQREP_SUBS   
  ADD REPL_ADDCOL CHARACTER(1) DEFAULT 'N' NOT NULL;
ALTER TABLE !CAPSCHEMA!.IBMQREP_SUBS 
  ADD IGNSETNULL CHARACTER(1) DEFAULT 'N' NOT NULL ;
ALTER TABLE !CAPSCHEMA!.IBMQREP_SUBS   
  ADD CAPTURE_TRUNCATE CHARACTER(1) DEFAULT 'R' NOT NULL;  
ALTER TABLE !CAPSCHEMA!.IBMQREP_SUBS   
  ADD SUB_CREATOR VARCHAR2(12);
  
  
  
CREATE TABLE !CAPSCHEMA!.IBMQREP_TABVERSION
( LSN             RAW(16),
 TABLEID1         SMALLINT NOT NULL,
 TABLEID2         SMALLINT NOT NULL,
 VERSION          INTEGER NOT NULL,
 SOURCE_OWNER     VARCHAR2(128) NOT NULL,
 SOURCE_NAME      VARCHAR2(128) NOT NULL)
  ;

CREATE UNIQUE INDEX !CAPSCHEMA!.IBMQREP_TABVERSIOX ON
 !CAPSCHEMA!.IBMQREP_TABVERSION
( LSN, TABLEID1, TABLEID2, VERSION);

CREATE INDEX !CAPSCHEMA!.IBMQREP_TABVERSIOX1 ON
 !CAPSCHEMA!.IBMQREP_TABVERSION
( TABLEID1, TABLEID2);

CREATE INDEX !CAPSCHEMA!.IBMQREP_TABVERSIOX2 ON
 !CAPSCHEMA!.IBMQREP_TABVERSION
( SOURCE_OWNER, SOURCE_NAME);

CREATE TABLE !CAPSCHEMA!.IBMQREP_COLVERSION
( LSN       RAW(16),
 TABLEID1   SMALLINT NOT NULL,
 TABLEID2   SMALLINT NOT NULL,
 POSITION   SMALLINT NOT NULL,
 NAME       VARCHAR2(128) NOT NULL,
 TYPE       SMALLINT NOT NULL,
 LENGTH     NUMBER(10) NOT NULL,
 NULLS      CHAR(1) NOT NULL,
 DATA_DEFAULT    VARCHAR2(1536),
 CODEPAGE   NUMBER(10),
 SCALE      NUMBER(10))
  ;

CREATE UNIQUE INDEX !CAPSCHEMA!.IBMQREP_COLVERSIOX ON
 !CAPSCHEMA!.IBMQREP_COLVERSION
( LSN, TABLEID1, TABLEID2, POSITION);

 
CREATE INDEX !CAPSCHEMA!.IBMQREP_COLVERSIOX1 ON
 !CAPSCHEMA!.IBMQREP_COLVERSION
( TABLEID1, TABLEID2);


