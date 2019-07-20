--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                         */
--      Version 9.7FP2 for Linux, UNIX AND Windows                   */
--                                                                   */
--     Sample SQL Replication migration script for UNIX AND NT       */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 1993, 2010. All Rights Reserved       */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--********************************************************************/
-- Script to migrate  Capture control tables from V97 to the latest fixpack.
--
-- Prior to running this script, customize it to your existing 
-- Capture server environment:
-- (1) Locate and change all occurrences of the string !capschema! 
--     to the name of the  Capture schema applicable to your
--     environment
--
-- (2) Run the script to migrate control tables into V97.
--
-- (3) Locate and change all occurances of the string !captablespace!
--     to the name of the tablespace where the capture control tables
--     are created.

--***********************************************************
-- Segment to migrate SQL Capture to V97FP2 
--***********************************************************

-- Start v97FP2

-- create IBMQREP_PART_HIST table

CREATE TABLE !capschema!.IBMQREP_PART_HIST
(
LSN              VARCHAR(16)     FOR BIT DATA NOT NULL,
HISTORY_TIME      TIMESTAMP                 NOT NULL,
TABSCHEMA         VARCHAR(128)              NOT NULL,
TABNAME           VARCHAR(128)              NOT NULL,
DATAPARTITIONID   INTEGER                   NOT NULL,
TBSPACEID         INTEGER                   NOT NULL,
PARTITIONOBJECTID INTEGER                   NOT NULL,
PRIMARY KEY (LSN, TABSCHEMA, TABNAME, DATAPARTITIONID,
TBSPACEID, PARTITIONOBJECTID)
) IN !captablespace!;

-- End of V97FP2  



-- Start of V97FP3  

-- IBMSNAP_CAPMON:  

ALTER TABLE !capschema!.IBMSNAP_CAPMON ALTER CURRENT_SEQ SET
DATA TYPE VARCHAR(16) FOR BIT DATA;

ALTER TABLE !capschema!.IBMSNAP_CAPMON ALTER RESTART_SEQ SET
DATA TYPE VARCHAR(16) FOR BIT DATA;

-- IBMSNAP_CAPPARMS:  
ALTER TABLE !capschema!.IBMSNAP_CAPPARMS         
ADD COLUMN   ARCH_LEVEL CHAR(4) NOT NULL WITH DEFAULT '0973';  

--************************************************************

-- IBMSNAP_SIGNAL:
CREATE  INDEX !capschema!.PKIBMSNAP_SIGNAL ON !capschema!.IBMSNAP_SIGNAL
( SIGNAL_TIME );

--************************************************************

-- IBMSNAP_PRUNCNTL:

ALTER TABLE !capschema!.IBMSNAP_PRUNCNTL
ALTER COLUMN TARGET_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE !capschema!.IBMSNAP_PRUNCNTL
ALTER COLUMN SOURCE_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE !capschema!.IBMSNAP_PRUNCNTL
ALTER COLUMN PHYS_CHANGE_OWNER SET DATA TYPE VARCHAR(128);

-- IBMSNAP_REGISTER:

ALTER TABLE !capschema!.IBMSNAP_REGISTER
ALTER COLUMN SOURCE_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE !capschema!.IBMSNAP_REGISTER
ALTER COLUMN CD_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE !capschema!.IBMSNAP_REGISTER
ALTER COLUMN PHYS_CHANGE_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE !capschema!.IBMSNAP_REGISTER
ALTER COLUMN CCD_OWNER SET DATA TYPE VARCHAR(128);

-- IBMSNAP_UOW:

ALTER TABLE !capschema!.IBMSNAP_UOW
ALTER COLUMN IBMSNAP_AUTHID SET DATA TYPE VARCHAR(128);


-- IBMSNAP_REGISTER:
ALTER TABLE !capschema!.IBMSNAP_REGISTER 
VOLATILE CARDINALITY;

-- IBMSNAP_PRUNCNTL:
ALTER TABLE !capschema!.IBMSNAP_PRUNCNTL 
VOLATILE CARDINALITY;

-- IBMSNAP_PRUNE_SET:
ALTER TABLE !capschema!.IBMSNAP_PRUNE_SET 
VOLATILE CARDINALITY;

-- IBMSNAP_RESTART:
ALTER TABLE !capschema!.IBMSNAP_RESTART 
VOLATILE CARDINALITY;

-- IBMSNAP_CAPTRACE:
ALTER TABLE !capschema!.IBMSNAP_CAPTRACE 
VOLATILE CARDINALITY;

-- IBMSNAP_CAPPARMS:
ALTER TABLE !capschema!.IBMSNAP_CAPPARMS 
VOLATILE CARDINALITY;

-- IBMSNAP_UOW:
ALTER TABLE !capschema!.IBMSNAP_UOW 
VOLATILE CARDINALITY;

-- IBMSNAP_CAPMON:
ALTER TABLE !capschema!.IBMSNAP_CAPMON 
VOLATILE CARDINALITY;

-- End of V97FP3  
