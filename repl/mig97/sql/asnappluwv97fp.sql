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
-- Script to migrate  Apply control tables from V97 to the latest fixpack
--
-- 1) Locate and change all occurances of the string !apptablespace!
--     to the name of the tablespace where the apply control tables
--     are created.

--***********************************************************
-- Segment to migrate SQL Apply to V97FP3 
--***********************************************************

-- Start of V97FP3  

--************************************************************
-- IBMSNAP_FEEDETL:

CREATE TABLE ASN.IBMSNAP_FEEDETL
        (APPLY_QUAL                     CHAR(18) NOT NULL,
         SET_NAME                        CHAR(18) NOT NULL,
         MIN_SYNCHPOINT              VARCHAR(16) FOR BIT DATA, 
         MAX_SYNCHPOINT             VARCHAR(16) FOR BIT DATA,
         DSX_CREATE_TIME   	        TIMESTAMP NOT NULL,
         PRIMARY KEY  (
APPLY_QUAL, SET_NAME)) IN !apptablespace!;

--************************************************************
-- IBMSNAP_APPLYMON 
 CREATE TABLE ASN.IBMSNAP_APPLYMON
        (MONITOR_TIME TIMESTAMP NOT NULL,
	 APPLY_QUAL   CHAR(18) NOT NULL,
	 WHOS_ON_FIRST CHAR(1),
	 STATE SMALLINT,
         CURRENT_SETNAME   CHAR(18),
	 CURRENT_TABOWNER VARCHAR(128),
	 CURRENT_TABNAME VARCHAR(128)
	 ) IN !apptablespace! ;
	 
CREATE INDEX ASN.IXIBMSNAP_APPLYMON ON ASN.IBMSNAP_APPLYMON( MONITOR_TIME, APPLY_QUAL, WHOS_ON_FIRST);

--************************************************************
-- IBMSNAP_APPLYPARMS 

ALTER TABLE ASN.IBMSNAP_APPPARMS         
ADD COLUMN   MONITOR_INTERVAL INT NOT NULL WITH DEFAULT 60000;   

ALTER TABLE ASN.IBMSNAP_APPPARMS         
ADD COLUMN   MONITOR_ENABLED CHAR(1) NOT NULL WITH DEFAULT 'N';   

-- IBMSNAP_SUBS_COLS:

ALTER TABLE ASN.IBMSNAP_SUBS_COLS  
ALTER COLUMN TARGET_NAME SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_SUBS_COLS
ALTER COLUMN TARGET_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_SUBS_COLS
ALTER COLUMN TARGET_NAME SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_SUBS_COLS
ALTER COLUMN EXPRESSION SET DATA TYPE VARCHAR(1024);

-- IBMSNAP_SUBS_MEMBR:

ALTER TABLE ASN.IBMSNAP_SUBS_MEMBR  
ALTER COLUMN LOADX_SRC_N_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_SUBS_MEMBR
ALTER COLUMN SOURCE_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_SUBS_MEMBR
ALTER COLUMN TARGET_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_SUBS_MEMBR
ALTER COLUMN LOADX_SRC_N_OWNER SET DATA TYPE VARCHAR(128);

-- IBMSNAP_SUBS_SET:

ALTER TABLE ASN.IBMSNAP_SUBS_SET
ALTER COLUMN CAPTURE_SCHEMA SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_SUBS_SET
ALTER COLUMN TGT_CAPTURE_SCHEMA SET DATA TYPE VARCHAR(128);

-- IBMSNAP_APPLYTRAIL:

ALTER TABLE ASN.IBMSNAP_APPLYTRAIL
ALTER COLUMN SOURCE_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_APPLYTRAIL
ALTER COLUMN TARGET_OWNER SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_APPLYTRAIL
ALTER COLUMN CAPTURE_SCHEMA SET DATA TYPE VARCHAR(128);

ALTER TABLE ASN.IBMSNAP_APPLYTRAIL
ALTER COLUMN TGT_CAPTURE_SCHEMA SET DATA TYPE VARCHAR(128);




-- End of V97FP3 

 
