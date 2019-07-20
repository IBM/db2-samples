--********************************************************************/
--                                                                   */
--          IBM InfoSphere Replication Server                         */
--      Version 10 for Linux, UNIX and Windows                       */
--                                                                   */
--     Sample SQL Replication control tables                         */
--     Licensed Materials - Property of IBM                          */
--                                                                   */
--     (C) Copyright IBM Corp. 2012. All Rights Reserved  nnnnnn     */
--                                                                   */
--     US Government Users Restricted Rights - Use, duplication      */
--     or disclosure restricted by GSA ADP Schedule Contract         */
--     with IBM Corp.                                                */
--                                                                   */
--                                                                   */
--********************************************************************/

------------------------------------------------------------------
--    Create SQL Replication Control Tables
--    (Linux, UNIX, and Windows edition)
------------------------------------------------------------------

-- BEGIN asnctlw.sql

-- UDB -- For the UDB platform, follow the directions given in the comments
-- UDB -- prefixed with "-- UDB --" (if any).

-- UDB -- TABLESPACE CONSIDERATIONS:

-- UDB -- Uncomment the drop statements below only if you are sure that they do
-- UDB -- not contain any important user tables!!!

--DROP TABLESPACE TSASNCA;
--DROP TABLESPACE TSASNUOW;
--DROP TABLESPACE TSASNAA;

-- UDB -- We recommend the use of two tablespaces to contain Q replication
-- UDB -- control tables, with one tablespace containing the Capture control tables
-- UDB -- and another to contain the Apply control tables.

-- UDB -- For each database, customize the following tablespace parameters:
-- UDB -- 1. File container must be different for each database.  You must
-- UDB --    change the sample file container when running this script on
-- UDB --    Unix platforms, for example: "FILE '/tmp/TSQCAP1.f1'".
-- UDB -- 2. Increase page allocation for large replication installations.
-- UDB -- 3. After making the customization changes, uncomment the
-- UDB --    CREATE TABLESPACE statements below as well as the IN clause
-- UDB --    from the CREATE TABLE statements later in this script.

-- UDB -- Note: tablespace parameters correspond to "FILE 'C:\TSASNCA.F1'"
-- UDB -- and "2000", respectively, in the following sample statement.

--CREATE TABLESPACE TSASNCA MANAGED BY DATABASE
--USING (FILE 'C:\TSASNCA.F1' 2000);

-- UDB -- Note: tablespace parameters correspond to "FILE 'C:\TSASNUOW.F1'"
-- UDB -- and "1000", respectively, in the following sample statement.

--CREATE TABLESPACE TSASNUOW MANAGED BY DATABASE
--USING (FILE 'C:\TSASNUOW.F1' 1000);

-- UDB -- Note: tablespace parameters correspond to "FILE 'C:\TSASNAA.F1'"
-- UDB -- and "2000", respectively, in the following sample statement.

--CREATE TABLESPACE TSASNAA MANAGED BY DATABASE
--USING (FILE 'C:\TSASNAA.F1' 2000);


--********************************************************************/
-- Create Capture Control tables                                     */
-- In this sample the Capture schema is ASN.
--********************************************************************/

-- CONNECT TO SRCDB2 USER XXXXX USING XXXXX ;


CREATE  TABLESPACE TSASNUOW
 IN DATABASE PARTITION GROUP IBMCATGROUP
 MANAGED BY DATABASE
 USING 
(
 FILE 'TSASNUOW' 10M
);


CREATE TABLE ASN.IBMSNAP_UOW(
IBMSNAP_UOWID                   CHAR( 10) FOR BIT DATA NOT NULL,
IBMSNAP_COMMITSEQ               VARCHAR( 16) FOR BIT DATA NOT NULL,
IBMSNAP_LOGMARKER               TIMESTAMP NOT NULL,
IBMSNAP_AUTHTKN                 VARCHAR(30) NOT NULL,
IBMSNAP_AUTHID                  VARCHAR(128) NOT NULL,
IBMSNAP_REJ_CODE                CHAR(  1) NOT NULL WITH DEFAULT ,
IBMSNAP_APPLY_QUAL              CHAR( 18) NOT NULL WITH DEFAULT )
IN TSASNUOW;


CREATE UNIQUE INDEX ASN.IBMSNAP_UOWX
ON ASN.IBMSNAP_UOW(
IBMSNAP_COMMITSEQ               ASC,
IBMSNAP_LOGMARKER               ASC);


ALTER TABLE ASN.IBMSNAP_UOW VOLATILE CARDINALITY;


CREATE  TABLESPACE TSASNCA
 IN DATABASE PARTITION GROUP IBMCATGROUP
 MANAGED BY DATABASE
 USING 
(
 FILE 'TSASNCA' 97M
);


CREATE TABLE ASN.IBMSNAP_CAPSCHEMAS(
CAP_SCHEMA_NAME                 VARCHAR(128) NOT NULL)
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IBMSNAP_CAPSCHEMASX
ON ASN.IBMSNAP_CAPSCHEMAS(
CAP_SCHEMA_NAME                 ASC);


ALTER TABLE ASN.IBMSNAP_CAPSCHEMAS VOLATILE CARDINALITY;


INSERT INTO ASN.IBMSNAP_CAPSCHEMAS(CAP_SCHEMA_NAME) VALUES (
'ASN');


CREATE TABLE ASN.IBMSNAP_REGISTER(
SOURCE_OWNER                    VARCHAR(128) NOT NULL,
SOURCE_TABLE                    VARCHAR(128) NOT NULL,
SOURCE_VIEW_QUAL                SMALLINT NOT NULL,
GLOBAL_RECORD                   CHAR( 1) NOT NULL,
SOURCE_STRUCTURE                SMALLINT NOT NULL,
SOURCE_CONDENSED                CHAR( 1) NOT NULL,
SOURCE_COMPLETE                 CHAR(  1) NOT NULL,
CD_OWNER                        VARCHAR(128),
CD_TABLE                        VARCHAR(128),
PHYS_CHANGE_OWNER               VARCHAR(128),
PHYS_CHANGE_TABLE               VARCHAR(128),
CD_OLD_SYNCHPOINT               VARCHAR( 16) FOR BIT DATA,
CD_NEW_SYNCHPOINT               VARCHAR( 16) FOR BIT DATA,
DISABLE_REFRESH                 SMALLINT NOT NULL,
CCD_OWNER                       VARCHAR(128),
CCD_TABLE                       VARCHAR(128),
CCD_OLD_SYNCHPOINT              VARCHAR( 16) FOR BIT DATA,
SYNCHPOINT                      VARCHAR( 16) FOR BIT DATA,
SYNCHTIME                       TIMESTAMP,
CCD_CONDENSED                   CHAR(  1),
CCD_COMPLETE                    CHAR(  1),
ARCH_LEVEL                      CHAR(  4) NOT NULL,
DESCRIPTION                     CHAR(254),
BEFORE_IMG_PREFIX               VARCHAR(   4),
CONFLICT_LEVEL                  CHAR(   1),
CHG_UPD_TO_DEL_INS              CHAR(   1),
CHGONLY                         CHAR(   1),
RECAPTURE                       CHAR(   1),
OPTION_FLAGS                    CHAR(   4) NOT NULL,
STOP_ON_ERROR                   CHAR(  1) WITH DEFAULT 'Y',
STATE                           CHAR(  1) WITH DEFAULT 'I',
STATE_INFO                      CHAR(  8))
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IBMSNAP_REGISTERX
ON ASN.IBMSNAP_REGISTER(
SOURCE_OWNER                    ASC,
SOURCE_TABLE                    ASC,
SOURCE_VIEW_QUAL                ASC);


CREATE  INDEX ASN.IBMSNAP_REGISTERX1
ON ASN.IBMSNAP_REGISTER(
PHYS_CHANGE_OWNER               ASC,
PHYS_CHANGE_TABLE               ASC);


CREATE  INDEX ASN.IBMSNAP_REGISTERX2
ON ASN.IBMSNAP_REGISTER(
GLOBAL_RECORD                   ASC);


ALTER TABLE ASN.IBMSNAP_REGISTER VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_PRUNCNTL(
TARGET_SERVER                   CHAR(18) NOT NULL,
TARGET_OWNER                    VARCHAR(128) NOT NULL,
TARGET_TABLE                    VARCHAR(128) NOT NULL,
SYNCHTIME                       TIMESTAMP,
SYNCHPOINT                      VARCHAR( 16) FOR BIT DATA,
SOURCE_OWNER                    VARCHAR(128) NOT NULL,
SOURCE_TABLE                    VARCHAR(128) NOT NULL,
SOURCE_VIEW_QUAL                SMALLINT NOT NULL,
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
CNTL_SERVER                     CHAR( 18) NOT NULL,
TARGET_STRUCTURE                SMALLINT NOT NULL,
CNTL_ALIAS                      CHAR( 8),
PHYS_CHANGE_OWNER               VARCHAR(128),
PHYS_CHANGE_TABLE               VARCHAR(128),
MAP_ID                          VARCHAR(10) NOT NULL)
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IBMSNAP_PRUNCNTLX
ON ASN.IBMSNAP_PRUNCNTL(
SOURCE_OWNER                    ASC,
SOURCE_TABLE                    ASC,
SOURCE_VIEW_QUAL                ASC,
APPLY_QUAL                      ASC,
SET_NAME                        ASC,
TARGET_SERVER                   ASC,
TARGET_TABLE                    ASC,
TARGET_OWNER                    ASC);


CREATE UNIQUE INDEX ASN.IBMSNAP_PRUNCNTLX1
ON ASN.IBMSNAP_PRUNCNTL(
MAP_ID                          ASC);


CREATE  INDEX ASN.IBMSNAP_PRUNCNTLX2
ON ASN.IBMSNAP_PRUNCNTL(
PHYS_CHANGE_OWNER               ASC,
PHYS_CHANGE_TABLE               ASC);


CREATE  INDEX ASN.IBMSNAP_PRUNCNTLX3
ON ASN.IBMSNAP_PRUNCNTL(
APPLY_QUAL                      ASC,
SET_NAME                        ASC,
TARGET_SERVER                   ASC);


ALTER TABLE ASN.IBMSNAP_PRUNCNTL VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_CAPTRACE(
OPERATION                       CHAR( 8) NOT NULL,
TRACE_TIME                      TIMESTAMP NOT NULL,
DESCRIPTION                     VARCHAR(1024) NOT NULL)
IN TSASNCA;


CREATE  INDEX ASN.IBMSNAP_CAPTRACEX
ON ASN.IBMSNAP_CAPTRACE(
TRACE_TIME                      ASC);


ALTER TABLE ASN.IBMSNAP_CAPTRACE VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_CAPPARMS(
RETENTION_LIMIT                 INT,
LAG_LIMIT                       INT,
COMMIT_INTERVAL                 INT,
PRUNE_INTERVAL                  INT,
TRACE_LIMIT                     INT,
MONITOR_LIMIT                   INT,
MONITOR_INTERVAL                INT,
MEMORY_LIMIT                    SMALLINT,
REMOTE_SRC_SERVER               CHAR( 18),
AUTOPRUNE                       CHAR(  1),
TERM                            CHAR(  1),
AUTOSTOP                        CHAR(  1),
LOGREUSE                        CHAR(  1),
LOGSTDOUT                       CHAR(  1),
SLEEP_INTERVAL                  SMALLINT,
CAPTURE_PATH                    VARCHAR(1040),
STARTMODE                       VARCHAR( 10),
ARCH_LEVEL                      CHAR( 4) NOT NULL WITH DEFAULT '1021',
COMPATIBILITY                   CHAR( 4) NOT NULL WITH DEFAULT '1021',
LOGRDBUFSZ                      INT NOT NULL WITH DEFAULT 256)
IN TSASNCA;


CREATE TABLE ASN.IBMSNAP_RESTART(
MAX_COMMITSEQ                   VARCHAR( 16) FOR BIT DATA NOT NULL,
MAX_COMMIT_TIME                 TIMESTAMP NOT NULL,
MIN_INFLIGHTSEQ                 VARCHAR( 16) FOR BIT DATA NOT NULL,
CURR_COMMIT_TIME                TIMESTAMP NOT NULL,
CAPTURE_FIRST_SEQ               VARCHAR( 16) FOR BIT DATA NOT NULL)
IN TSASNCA;


CREATE TABLE ASN.IBMSNAP_PRUNE_SET(
TARGET_SERVER                   CHAR( 18) NOT NULL,
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
SYNCHTIME                       TIMESTAMP,
SYNCHPOINT                      VARCHAR( 16) FOR BIT DATA NOT NULL)
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IBMSNAP_PRUNE_SETX
ON ASN.IBMSNAP_PRUNE_SET(
TARGET_SERVER                   ASC,
APPLY_QUAL                      ASC,
SET_NAME                        ASC);


ALTER TABLE ASN.IBMSNAP_PRUNE_SET VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_CAPENQ(
LOCK_NAME                       CHAR(  9))
IN TSASNCA;


CREATE TABLE ASN.IBMSNAP_SIGNAL(
SIGNAL_TIME                     TIMESTAMP NOT NULL WITH DEFAULT ,
SIGNAL_TYPE                     VARCHAR( 30) NOT NULL,
SIGNAL_SUBTYPE                  VARCHAR( 30),
SIGNAL_INPUT_IN                 VARCHAR(500),
SIGNAL_STATE                    CHAR( 1) NOT NULL,
SIGNAL_LSN                      VARCHAR( 16) FOR BIT DATA)
IN TSASNCA
DATA CAPTURE CHANGES;


CREATE  INDEX ASN.IBMSNAP_SIGNALX
ON ASN.IBMSNAP_SIGNAL(
SIGNAL_TIME                     ASC);


ALTER TABLE ASN.IBMSNAP_SIGNAL VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_CAPMON(
MONITOR_TIME                    TIMESTAMP NOT NULL,
RESTART_TIME                    TIMESTAMP NOT NULL,
CURRENT_MEMORY                  INT NOT NULL,
CD_ROWS_INSERTED                INT NOT NULL,
RECAP_ROWS_SKIPPED              INT NOT NULL,
TRIGR_ROWS_SKIPPED              INT NOT NULL,
CHG_ROWS_SKIPPED                INT NOT NULL,
TRANS_PROCESSED                 INT NOT NULL,
TRANS_SPILLED                   INT NOT NULL,
MAX_TRANS_SIZE                  INT NOT NULL,
LOCKING_RETRIES                 INT NOT NULL,
JRN_LIB                         CHAR( 10),
JRN_NAME                        CHAR( 10),
LOGREADLIMIT                    INT NOT NULL,
CAPTURE_IDLE                    INT NOT NULL,
SYNCHTIME                       TIMESTAMP NOT NULL,
CURRENT_LOG_TIME                TIMESTAMP NOT NULL WITH DEFAULT ,
LAST_EOL_TIME                   TIMESTAMP,
RESTART_SEQ                     VARCHAR( 16) FOR BIT DATA NOT NULL WITH DEFAULT ,
CURRENT_SEQ                     VARCHAR( 16) FOR BIT DATA NOT NULL WITH DEFAULT ,
RESTART_MAXCMTSEQ               VARCHAR( 16) FOR BIT DATA NOT NULL WITH DEFAULT ,
LOGREAD_API_TIME                INT,
NUM_LOGREAD_CALLS               INT,
NUM_END_OF_LOGS                 INT,
LOGRDR_SLEEPTIME                INT,
NUM_LOGREAD_F_CALLS             INT,
TRANS_QUEUED                    INT,
NUM_WARNTXS                     INT,
NUM_WARNLOGAPI                  INT)
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IBMSNAP_CAPMONX
ON ASN.IBMSNAP_CAPMON(
MONITOR_TIME                    ASC);


ALTER TABLE ASN.IBMSNAP_CAPMON VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_PRUNE_LOCK(
DUMMY                           CHAR( 1))
IN TSASNCA;


CREATE TABLE ASN.IBMQREP_PART_HIST(
LSN                             VARCHAR(16) FOR BIT DATA NOT NULL,
HISTORY_TIME                    TIMESTAMP NOT NULL,
TABSCHEMA                       VARCHAR(128) NOT NULL,
TABNAME                         VARCHAR(128) NOT NULL,
DATAPARTITIONID                 INT NOT NULL,
TBSPACEID                       INT NOT NULL,
PARTITIONOBJECTID               INT NOT NULL,
PRIMARY KEY (LSN,TABSCHEMA,TABNAME,DATAPARTITIONID,TBSPACEID,PARTITIONOBJECTID)
);


CREATE  INDEX ASN.IX1PARTHISTORY
ON ASN.IBMQREP_PART_HIST(
TABSCHEMA                       ASC,
TABNAME                         ASC,
LSN                             ASC);


CREATE TABLE ASN.IBMQREP_IGNTRAN(
AUTHID                          CHAR(128),
AUTHTOKEN                       CHAR( 30),
PLANNAME                        CHAR(  8),
IGNTRANTRC                      CHARACTER(  1) NOT NULL WITH DEFAULT 'N')
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IGNTRANX
ON ASN.IBMQREP_IGNTRAN(
AUTHID                          ASC,
AUTHTOKEN                       ASC,
PLANNAME                        ASC);


CREATE TABLE ASN.IBMQREP_IGNTRANTRC(
IGNTRAN_TIME                    TIMESTAMP NOT NULL WITH DEFAULT ,
AUTHID                          CHAR(128),
AUTHTOKEN                       CHAR( 30),
PLANNAME                        CHAR(  8),
TRANSID                         VARCHAR( 12) FOR BIT DATA NOT NULL,
COMMITLSN                       VARCHAR( 16) FOR BIT DATA)
IN TSASNCA;


CREATE  INDEX ASN.IGNTRCX
ON ASN.IBMQREP_IGNTRANTRC(
IGNTRAN_TIME                    ASC);


CREATE TABLE ASN.IBMQREP_TABVERSION(
LSN                             VARCHAR( 16) FOR BIT DATA NOT NULL,
TABLEID1                        SMALLINT NOT NULL,
TABLEID2                        SMALLINT NOT NULL,
VERSION                         INTEGER NOT NULL,
SOURCE_OWNER                    VARCHAR(128) NOT NULL,
SOURCE_NAME                     VARCHAR(128) NOT NULL,
VERSION_TIME                    TIMESTAMP NOT NULL WITH DEFAULT )
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IBMQREP_TABVERSIOX
ON ASN.IBMQREP_TABVERSION(
LSN                             ASC,
TABLEID1                        ASC,
TABLEID2                        ASC,
VERSION                         ASC);


CREATE  INDEX ASN.IX2TABVERSION
ON ASN.IBMQREP_TABVERSION(
TABLEID1                        ASC,
TABLEID2                        ASC);


CREATE  INDEX ASN.IX3TABVERSION
ON ASN.IBMQREP_TABVERSION(
SOURCE_OWNER                    ASC,
SOURCE_NAME                     ASC);


CREATE TABLE ASN.IBMQREP_COLVERSION(
LSN                             VARCHAR( 16) FOR BIT DATA NOT NULL,
TABLEID1                        SMALLINT NOT NULL,
TABLEID2                        SMALLINT NOT NULL,
POSITION                        SMALLINT NOT NULL,
NAME                            VARCHAR(128) NOT NULL,
TYPE                            SMALLINT NOT NULL,
LENGTH                          INTEGER NOT NULL,
NULLS                           CHAR(  1) NOT NULL,
DEFAULT                         VARCHAR(1536),
CODEPAGE                        INTEGER,
SCALE                           INTEGER,
VERSION_TIME                    TIMESTAMP NOT NULL WITH DEFAULT )
IN TSASNCA;


CREATE UNIQUE INDEX ASN.IBMQREP_COLVERSIOX
ON ASN.IBMQREP_COLVERSION(
LSN                             ASC,
TABLEID1                        ASC,
TABLEID2                        ASC,
POSITION                        ASC);


CREATE  INDEX ASN.IX2COLVERSION
ON ASN.IBMQREP_COLVERSION(
TABLEID1                        ASC,
TABLEID2                        ASC);


INSERT INTO ASN.IBMSNAP_CAPPARMS(
RETENTION_LIMIT,
LAG_LIMIT,
COMMIT_INTERVAL,
PRUNE_INTERVAL,
TRACE_LIMIT,
MONITOR_LIMIT,
MONITOR_INTERVAL,
MEMORY_LIMIT,
SLEEP_INTERVAL,
AUTOPRUNE,
TERM,
AUTOSTOP,
LOGREUSE,
LOGSTDOUT,
CAPTURE_PATH,
STARTMODE,
COMPATIBILITY)
VALUES (
10080,
10080,
30,
300,
10080,
10080,
300,
32,
5,
'Y',
'Y',
'N',
'N',
'N',
NULL,
'WARMSI',
'1021'
);


-- COMMIT;


-- connect to apply_control_server

-- All Apply tables must have schema ASN

-- CONNECT TO TRGDB2 USER XXXXX USING XXXXX ;


CREATE  TABLESPACE TSASNAA
 IN DATABASE PARTITION GROUP IBMCATGROUP
 MANAGED BY DATABASE
 USING 
(
 FILE 'TSASNAA' 23M
);


CREATE TABLE ASN.IBMSNAP_APPENQ(
APPLY_QUAL                      CHAR( 18))
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_APPENQX
ON ASN.IBMSNAP_APPENQ(
APPLY_QUAL                      ASC);


ALTER TABLE ASN.IBMSNAP_APPENQ VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_SUBS_SET(
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
SET_TYPE                        CHAR(  1) NOT NULL,
WHOS_ON_FIRST                   CHAR(  1) NOT NULL,
ACTIVATE                        SMALLINT NOT NULL,
SOURCE_SERVER                   CHAR( 18) NOT NULL,
SOURCE_ALIAS                    CHAR(  8),
TARGET_SERVER                   CHAR( 18) NOT NULL,
TARGET_ALIAS                    CHAR(  8),
STATUS                          SMALLINT NOT NULL,
LASTRUN                         TIMESTAMP NOT NULL,
REFRESH_TYPE                    CHAR( 1) NOT NULL,
SLEEP_MINUTES                   INT,
EVENT_NAME                      CHAR( 18),
LASTSUCCESS                     TIMESTAMP,
SYNCHPOINT                      VARCHAR( 16) FOR BIT DATA,
SYNCHTIME                       TIMESTAMP,
CAPTURE_SCHEMA                  VARCHAR(128) NOT NULL,
TGT_CAPTURE_SCHEMA              VARCHAR(128),
FEDERATED_SRC_SRVR              VARCHAR( 18),
FEDERATED_TGT_SRVR              VARCHAR( 18),
JRN_LIB                         CHAR( 10),
JRN_NAME                        CHAR( 10),
OPTION_FLAGS                    CHAR(  4) NOT NULL,
COMMIT_COUNT                    SMALLINT,
MAX_SYNCH_MINUTES               SMALLINT,
AUX_STMTS                       SMALLINT NOT NULL,
ARCH_LEVEL                      CHAR( 4) NOT NULL)
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_SUBS_SETX
ON ASN.IBMSNAP_SUBS_SET(
APPLY_QUAL                      ASC,
SET_NAME                        ASC,
WHOS_ON_FIRST                   ASC);


ALTER TABLE ASN.IBMSNAP_SUBS_SET VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_SUBS_MEMBR(
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
WHOS_ON_FIRST                   CHAR(  1) NOT NULL,
SOURCE_OWNER                    VARCHAR(128) NOT NULL,
SOURCE_TABLE                    VARCHAR(128) NOT NULL,
SOURCE_VIEW_QUAL                SMALLINT NOT NULL,
TARGET_OWNER                    VARCHAR(128) NOT NULL,
TARGET_TABLE                    VARCHAR(128) NOT NULL,
TARGET_CONDENSED                CHAR(  1) NOT NULL,
TARGET_COMPLETE                 CHAR(  1) NOT NULL,
TARGET_STRUCTURE                SMALLINT NOT NULL,
PREDICATES                      VARCHAR(1024),
MEMBER_STATE                    CHAR(  1),
TARGET_KEY_CHG                  CHAR(  1) NOT NULL,
UOW_CD_PREDICATES               VARCHAR(1024),
JOIN_UOW_CD                     CHAR(  1),
LOADX_TYPE                      SMALLINT,
LOADX_SRC_N_OWNER               VARCHAR( 128),
LOADX_SRC_N_TABLE               VARCHAR(128))
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_SUBS_MEMBRX
ON ASN.IBMSNAP_SUBS_MEMBR(
APPLY_QUAL                      ASC,
SET_NAME                        ASC,
WHOS_ON_FIRST                   ASC,
SOURCE_OWNER                    ASC,
SOURCE_TABLE                    ASC,
SOURCE_VIEW_QUAL                ASC,
TARGET_OWNER                    ASC,
TARGET_TABLE                    ASC);


ALTER TABLE ASN.IBMSNAP_SUBS_MEMBR VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_APPLYTRACE(
APPLY_QUAL                      CHAR(18) NOT NULL,
TRACE_TIME                      TIMESTAMP NOT NULL,
OPERATION                       CHAR(  8) NOT NULL,
DESCRIPTION                     VARCHAR(1024) NOT NULL)
IN TSASNAA;


CREATE  INDEX ASN.IBMSNAP_APPLYTRACEX
ON ASN.IBMSNAP_APPLYTRACE(
APPLY_QUAL                      ASC,
TRACE_TIME                      ASC);


ALTER TABLE ASN.IBMSNAP_APPLYTRACE VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_SUBS_COLS(
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
WHOS_ON_FIRST                   CHAR(  1) NOT NULL,
TARGET_OWNER                    VARCHAR(128) NOT NULL,
TARGET_TABLE                    VARCHAR(128) NOT NULL,
COL_TYPE                        CHAR(  1) NOT NULL,
TARGET_NAME                     VARCHAR(128) NOT NULL,
IS_KEY                          CHAR(  1) NOT NULL,
COLNO                           SMALLINT NOT NULL,
EXPRESSION                      VARCHAR(1024) NOT NULL)
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_SUBS_COLSX
ON ASN.IBMSNAP_SUBS_COLS(
APPLY_QUAL                      ASC,
SET_NAME                        ASC,
WHOS_ON_FIRST                   ASC,
TARGET_OWNER                    ASC,
TARGET_TABLE                    ASC,
TARGET_NAME                     ASC);


ALTER TABLE ASN.IBMSNAP_SUBS_COLS VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_SUBS_STMTS(
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
WHOS_ON_FIRST                   CHAR(  1) NOT NULL,
BEFORE_OR_AFTER                 CHAR(  1) NOT NULL,
STMT_NUMBER                     SMALLINT NOT NULL,
EI_OR_CALL                      CHAR(  1) NOT NULL,
SQL_STMT                        VARCHAR(1024),
ACCEPT_SQLSTATES                VARCHAR( 50))
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_SUBS_STMTSX
ON ASN.IBMSNAP_SUBS_STMTS(
APPLY_QUAL                      ASC,
SET_NAME                        ASC,
WHOS_ON_FIRST                   ASC,
BEFORE_OR_AFTER                 ASC,
STMT_NUMBER                     ASC);


ALTER TABLE ASN.IBMSNAP_SUBS_STMTS VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_SUBS_EVENT(
EVENT_NAME                      CHAR( 18) NOT NULL,
EVENT_TIME                      TIMESTAMP NOT NULL,
END_SYNCHPOINT                  VARCHAR( 16) FOR BIT DATA,
END_OF_PERIOD                   TIMESTAMP)
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_SUBS_EVENTX
ON ASN.IBMSNAP_SUBS_EVENT(
EVENT_NAME                      ASC,
EVENT_TIME                      ASC);


ALTER TABLE ASN.IBMSNAP_SUBS_EVENT VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_APPLYTRAIL(
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
SET_TYPE                        CHAR(  1) NOT NULL,
WHOS_ON_FIRST                   CHAR(  1) NOT NULL,
ASNLOAD                         CHAR(  1),
FULL_REFRESH                    CHAR(  1),
EFFECTIVE_MEMBERS               INT,
SET_INSERTED                    INT NOT NULL,
SET_DELETED                     INT NOT NULL,
SET_UPDATED                     INT NOT NULL,
SET_REWORKED                    INT NOT NULL,
SET_REJECTED_TRXS               INT NOT NULL,
STATUS                          SMALLINT NOT NULL,
LASTRUN                         TIMESTAMP NOT NULL,
LASTSUCCESS                     TIMESTAMP,
SYNCHPOINT                      VARCHAR( 16) FOR BIT DATA,
SYNCHTIME                       TIMESTAMP,
SOURCE_SERVER                   CHAR( 18) NOT NULL,
SOURCE_ALIAS                    CHAR(  8),
SOURCE_OWNER                    VARCHAR(128),
SOURCE_TABLE                    VARCHAR(128),
SOURCE_VIEW_QUAL                SMALLINT,
TARGET_SERVER                   CHAR( 18) NOT NULL,
TARGET_ALIAS                    CHAR(  8),
TARGET_OWNER                    VARCHAR(128) NOT NULL,
TARGET_TABLE                    VARCHAR(128) NOT NULL,
CAPTURE_SCHEMA                  VARCHAR(128) NOT NULL,
TGT_CAPTURE_SCHEMA              VARCHAR(128),
FEDERATED_SRC_SRVR              VARCHAR( 18),
FEDERATED_TGT_SRVR              VARCHAR( 18),
JRN_LIB                         CHAR( 10),
JRN_NAME                        CHAR( 10),
COMMIT_COUNT                    SMALLINT,
OPTION_FLAGS                    CHAR(  4) NOT NULL,
EVENT_NAME                      CHAR( 18),
ENDTIME                         TIMESTAMP NOT NULL WITH DEFAULT ,
SOURCE_CONN_TIME                TIMESTAMP,
SQLSTATE                        CHAR(  5),
SQLCODE                         INT,
SQLERRP                         CHAR(  8),
SQLERRM                         VARCHAR( 70),
APPERRM                         VARCHAR(760))
IN TSASNAA;


CREATE  INDEX ASN.IBMSNAP_APPLYTRLX
ON ASN.IBMSNAP_APPLYTRAIL(
LASTRUN                         DESC,
APPLY_QUAL                      ASC);


ALTER TABLE ASN.IBMSNAP_APPLYTRAIL VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_APPPARMS(
APPLY_QUAL                      CHAR( 18) NOT NULL,
APPLY_PATH                      VARCHAR(1040),
COPYONCE                        CHAR(  1) WITH DEFAULT 'N',
DELAY                           INT WITH DEFAULT 6,
ERRWAIT                         INT WITH DEFAULT 300,
INAMSG                          CHAR(  1) WITH DEFAULT 'Y',
LOADXIT                         CHAR(  1) WITH DEFAULT 'N',
LOGREUSE                        CHAR(  1) WITH DEFAULT 'N',
LOGSTDOUT                       CHAR(  1) WITH DEFAULT 'N',
NOTIFY                          CHAR(  1) WITH DEFAULT 'N',
OPT4ONE                         CHAR(  1) WITH DEFAULT 'N',
SLEEP                           CHAR(  1) WITH DEFAULT 'Y',
SQLERRCONTINUE                  CHAR(  1) WITH DEFAULT 'N',
SPILLFILE                       VARCHAR( 10) WITH DEFAULT 'DISK',
TERM                            CHAR(  1) WITH DEFAULT 'Y',
TRLREUSE                        CHAR(  1) WITH DEFAULT 'N',
MONITOR_ENABLED                 CHAR( 1) WITH DEFAULT 'N',
MONITOR_INTERVAL                INT WITH DEFAULT 60000,
REFRESH_COMMIT_CNT              INT)
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_APPPARMSX
ON ASN.IBMSNAP_APPPARMS(
APPLY_QUAL                      ASC);


ALTER TABLE ASN.IBMSNAP_APPPARMS VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_COMPENSATE(
APPLY_QUAL                      CHAR( 18) NOT NULL,
MEMBER                          SMALLINT NOT NULL,
INTENTSEQ                       VARCHAR( 16) FOR BIT DATA NOT NULL,
OPERATION                       CHAR(  1) NOT NULL)
IN TSASNAA;


CREATE UNIQUE INDEX ASN.IBMSNAP_COMPENSATEX
ON ASN.IBMSNAP_COMPENSATE(
APPLY_QUAL                      ASC,
MEMBER                          ASC);


ALTER TABLE ASN.IBMSNAP_COMPENSATE VOLATILE CARDINALITY;


CREATE TABLE ASN.IBMSNAP_APPLEVEL(
ARCH_LEVEL                      CHAR(  4) NOT NULL WITH DEFAULT '1021')
IN TSASNAA;


CREATE TABLE ASN.IBMSNAP_FEEDETL(
APPLY_QUAL                      CHAR( 18) NOT NULL,
SET_NAME                        CHAR( 18) NOT NULL,
MIN_SYNCHPOINT                  VARCHAR( 16) FOR BIT DATA,
MAX_SYNCHPOINT                  VARCHAR( 16) FOR BIT DATA,
DSX_CREATE_TIME                 TIMESTAMP NOT NULL,
PRIMARY KEY (APPLY_QUAL,SET_NAME)
)
IN TSASNAA;


CREATE TABLE ASN.IBMSNAP_APPLYMON(
MONITOR_TIME                    TIMESTAMP NOT NULL,
APPLY_QUAL                      CHAR( 18) NOT NULL,
WHOS_ON_FIRST                   CHAR(  1),
STATE                           SMALLINT,
CURRENT_SETNAME                 CHAR( 18),
CURRENT_TABOWNER                VARCHAR(128),
CURRENT_TABNAME                 VARCHAR(128))
IN TSASNAA;


CREATE  INDEX ASN.IXIBMSNAP_APPLYMON
ON ASN.IBMSNAP_APPLYMON(
MONITOR_TIME                    ASC,
APPLY_QUAL                      ASC,
WHOS_ON_FIRST                   ASC);


ALTER TABLE ASN.IBMSNAP_APPLYMON VOLATILE CARDINALITY;


INSERT INTO ASN.IBMSNAP_APPLEVEL(ARCH_LEVEL) VALUES (
'1021');


-- COMMIT;




