-- Script to migrate SQL Capture control tables from V8.2 to V9.1.
--
-- Prior to running this script, customize it to your existing 
-- Q Capture server environment:
--
-- (1) Replace '!DBNAME!'.'!TSNAME!' with any row level locking tablespace name.
--
-- (2) The 2 tables IBMQREP_COLVERSION and IBMQREP_TABVERSION are used by a 
--     Capture program to decode z/OS DB2 V9 log records, they are needed for both 
--     SQL and Q Replication. Hence these tables are common between Q and SQL replication 
--     in a server. If these tables are being created during Q replication migration then 
--     you should receive the table already exist error during SQL replication migration 
--     which is OK.
--         


CREATE TABLE !capschema!.IBMQREP_COLVERSION
(  LSN            CHAR(10)     FOR BIT DATA NOT NULL,
  TABLEID1       SMALLINT                  NOT NULL,
  TABLEID2       SMALLINT                  NOT NULL,
  POSITION       SMALLINT                  NOT NULL,
  NAME           VARCHAR(128)              NOT NULL,
  TYPE           SMALLINT                  NOT NULL,
  LENGTH         INTEGER                   NOT NULL,
  NULLS          CHAR(1)                   NOT NULL,
  DEFAULT        VARCHAR(1536)
) in !DBNAME!.!TSNAME!;

CREATE UNIQUE INDEX !capschema!.IBMQREP_COLVERSIOX
  ON !capschema!.IBMQREP_COLVERSION(
  LSN, TABLEID1, TABLEID2, POSITION);   
  

CREATE TABLE !capschema!.IBMQREP_TABVERSION
(  LSN            CHAR(10)     FOR BIT DATA NOT NULL,
  TABLEID1       SMALLINT                  NOT NULL,
  TABLEID2       SMALLINT                  NOT NULL,
  VERSION        INTEGER                   NOT NULL,
  SOURCE_OWNER   VARCHAR(128)              NOT NULL,
  SOURCE_NAME    VARCHAR(128)              NOT NULL   
)in !DBNAME!.!TSNAME!;   
  
CREATE UNIQUE INDEX !capschema!.IBMQREP_TABVERSIOX
  ON !capschema!.IBMQREP_TABVERSION(
  LSN, TABLEID1, TABLEID2, VERSION);  

COMMIT;

------------------------------------------------------------------
--   New tables to ignore transactions    (All IBM platforms  )
--   Tables names starts with IBMQREP, not IBMSNAP
------------------------------------------------------------------


CREATE TABLE !capschema!.IBMQREP_IGNTRAN
( AUTHID 	CHARACTER(128),
 AUTHTOKEN 	CHARACTER(30),
 PLANNAME 	CHARACTER(8)
)  IN !DBNAME!.!TSNAME!;

CREATE TABLE !capschema!.IBMQREP_IGNTRANTRC
( AUTHID 	CHARACTER(128),
 AUTHTOKEN 	HARACTER(30),
 PLANNAME 	CHARACTER(8),
 TRANSID 	CHARACTER(10) 	FOR BIT DATA NOT NULL,
 COMMITLSN 	CHARACTER(10) 	FOR BIT DATA NOT NULL
)  IN !DBNAME!.!TSNAME!;



COMMIT;
