 
--  
-- V8 Replication Migration backup script VERSION 1.51, 
-- generated "May  5 2003" "10:45:32" by CPP for "DB2 UDB V8" server:
--
-- DO NOT DELETE ANY SQL STATEMENTS FROM THIS SCRIPT.
--
 
-- Users must either create the tablespaces BACKUPTS and OTHERTS
-- before running this script, or change these tablespace names to
-- existing ones.
--
-- For example, to change all tablespace names to userspace1
-- with vi editor:
--
-- enter: :%s/in [A-Z]*TS/in userspace1/
--
-- At the end of migration, when it is clear that fallback is not
-- required, the BACKUP schema (and its tables) should be dropped to
-- clean up.
--
-- All Replication control tables will be backed up to 
-- tablespace BACKUPTS.
--
-- Tablespace OTHERTS is the tablespace where BACKUP.IBMSNV8 tables
-- need to be created by this script.  Migration will create the
-- new (migrated) DPROPR V8 control tables in this tablespace also.
 
--
-- Backup tablespaces must exist before backup tables can be created.
--
--    See "CREATE TABLESPACE" in your SQL Reference.
--
-- Choose parameters to optimize backup security rather than performance.
 
--
-- To estimate BACKUPTS tablespace size required, run a script
-- similar to this:
--
--
-- db2 connect to $1 user $2 using $3
--
-- db2 'drop table asn.ibmsnap_temp'
--
-- db2 "create table asn.ibmsnap_temp \
--     ( tabschema varchar( 30 ), tabname varchar( 128 ) )"
--
-- db2 "insert into asn.ibmsnap_temp               \
--     select rtrim( tabschema ), rtrim( tabname ) \
--     from syscat.tables where tabschema = 'ASN'"
--
-- db2 "insert into asn.ibmsnap_temp               \
--     select rtrim( tabschema ), rtrim( tabname ) \
--     from syscat.tables                          \
--     where type = 'T'                            \
--       and char( rtrim( tabschema ) || ',' || tabname ) \
--     in (  select rtrim( cd_owner ) || ',' || cd_table  \
--     from asn.ibmsnap_register )"
--
-- db2 'commit'
--
-- db2 "select 'runstats on table ' || tabschema || '.' || tabname || ' ;' \
--     from asn.ibmsnap_temp" | \
--     perl -e "while(<>) { s/ *$// ; print if /^runstats / ; }"  > temp.clp
--
-- db2 -tf temp.clp
--
-- # Round tablespace estimate up to next multiple of 100, times 3:
--
-- db2 "select 'create tablespace TS managed by database using ( file ''FILE'' ' \
--     || rtrim( char( ( sum( abs ( fpages ) ) / 100 + 10 ) * 300 ) )            \
--     || ' ) extentsize 2'                                                      \
--     from syscat.tables where ( tabschema, tabname )                           \
--     in ( select tabschema, tabname from asn.ibmsnap_temp ) "
--
-- db2 'drop table asn.ibmsnap_temp'
--
 
------------------------------------------------------------------------
-- The DB2 V8 Replication tables and indices:
------------------------------------------------------------------------
 
CREATE TABLE BACKUP.IBMSNV8_CAPSCHEMAS ( 
   CAP_SCHEMA_NAME    VARCHAR(030)                        )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_CAPSCHEMAX
ON BACKUP.IBMSNV8_CAPSCHEMAS ( 
   CAP_SCHEMA_NAME    ASC                                 ) ; 
 
CREATE TABLE BACKUP.IBMSNV8_RESTART ( 
   MAX_COMMITSEQ      CHAR(010)     FOR BIT DATA NOT NULL ,
   MAX_COMMIT_TIME    TIMESTAMP                  NOT NULL ,
   MIN_INFLIGHTSEQ    CHAR(010)     FOR BIT DATA NOT NULL , 
   CURR_COMMIT_TIME   TIMESTAMP                  NOT NULL , 
   CAPTURE_FIRST_SEQ  CHAR(010)     FOR BIT DATA NOT NULL )
in OTHERTS  ;
 
CREATE TABLE BACKUP.IBMSNV8_REGISTER (
   SOURCE_OWNER       VARCHAR(030)               NOT NULL , 
   SOURCE_TABLE       VARCHAR(128)               NOT NULL , 
   SOURCE_VIEW_QUAL   SMALLINT                   NOT NULL ,
   GLOBAL_RECORD      CHAR(001)                  NOT NULL ,
   SOURCE_STRUCTURE   SMALLINT                   NOT NULL ,
   SOURCE_CONDENSED   CHAR(001)                  NOT NULL ,
   SOURCE_COMPLETE    CHAR(001)                  NOT NULL ,
   CD_OWNER           VARCHAR(030)                        , 
   CD_TABLE           VARCHAR(128)                        , 
   PHYS_CHANGE_OWNER  VARCHAR(030)                        , 
   PHYS_CHANGE_TABLE  VARCHAR(128)                        , 
   CD_OLD_SYNCHPOINT  CHAR(010)     FOR BIT DATA          ,
   CD_NEW_SYNCHPOINT  CHAR(010)     FOR BIT DATA          ,
   DISABLE_REFRESH    SMALLINT                   NOT NULL ,
   CCD_OWNER          VARCHAR(030)                        , 
   CCD_TABLE          VARCHAR(128)                        , 
   CCD_OLD_SYNCHPOINT CHAR(010)     FOR BIT DATA          ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SYNCHTIME          TIMESTAMP                           ,
   CCD_CONDENSED      CHAR(001)                           ,
   CCD_COMPLETE       CHAR(001)                           ,
   ARCH_LEVEL         CHAR(004)                  NOT NULL ,
   DESCRIPTION        CHAR(254)                           ,
   BEFORE_IMG_PREFIX  VARCHAR(004)                        ,
   CONFLICT_LEVEL     CHAR(001)                           ,
   CHG_UPD_TO_DEL_INS CHAR(001)                           , 
   CHGONLY            CHAR(001)                           ,
   RECAPTURE          CHAR(001)                           , 
   OPTION_FLAGS       CHAR(004)                  NOT NULL ,
   STOP_ON_ERROR      CHAR(001)                           , 
   STATE              CHAR(001)                           , 
   STATE_INFO         CHAR(008)                           )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_REGISTERX
ON BACKUP.IBMSNV8_REGISTER (
   SOURCE_OWNER       ASC                                 ,
   SOURCE_TABLE       ASC                                 ,
   SOURCE_VIEW_QUAL   ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_REGISTERX1 
ON BACKUP.IBMSNV8_REGISTER (
   PHYS_CHANGE_OWNER  ASC                                 , 
   PHYS_CHANGE_TABLE  ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_REGISTERX2 
ON BACKUP.IBMSNV8_REGISTER (
   GLOBAL_RECORD      ASC                                 ) ; 

CREATE TABLE BACKUP.IBMSNV8_PRUNCNTL (
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   SYNCHTIME          TIMESTAMP                           ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SOURCE_OWNER       VARCHAR(030)               NOT NULL , 
   SOURCE_TABLE       VARCHAR(128)               NOT NULL , 
   SOURCE_VIEW_QUAL   SMALLINT                   NOT NULL ,
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   CNTL_SERVER        CHAR(018)                  NOT NULL ,
   TARGET_STRUCTURE   SMALLINT                   NOT NULL ,
   CNTL_ALIAS         CHAR(008)                           ,
   PHYS_CHANGE_OWNER  VARCHAR(030)                        , 
   PHYS_CHANGE_TABLE  VARCHAR(128)                        , 
   MAP_ID             VARCHAR(010)               NOT NULL )
in OTHERTS   ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_PRUNCNTLX
ON BACKUP.IBMSNV8_PRUNCNTL (
   SOURCE_OWNER       ASC                                 ,
   SOURCE_TABLE       ASC                                 ,
   SOURCE_VIEW_QUAL   ASC                                 ,
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   TARGET_SERVER      ASC                                 ,
   TARGET_TABLE       ASC                                 ,
   TARGET_OWNER       ASC                                 ) ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_PRUNCNTLX1
ON BACKUP.IBMSNV8_PRUNCNTL (
   MAP_ID             ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_PRUNCNTLX2 
ON BACKUP.IBMSNV8_PRUNCNTL (
   PHYS_CHANGE_OWNER  ASC                                 , 
   PHYS_CHANGE_TABLE  ASC                                 ) ; 

CREATE INDEX BACKUP.IBMSNAP_PRUNCNTLX3 
ON BACKUP.IBMSNV8_PRUNCNTL (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   TARGET_SERVER      ASC                                 
 ) ; 

CREATE TABLE BACKUP.IBMSNV8_PRUNE_SET (
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL , 
   SYNCHTIME          TIMESTAMP                           , 
   SYNCHPOINT         CHAR(010)     FOR BIT DATA NOT NULL )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_PRUNE_SETX
ON BACKUP.IBMSNV8_PRUNE_SET ( 
   TARGET_SERVER      ASC                                 ,
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ) ; 
 
CREATE TABLE BACKUP.IBMSNV8_CAPTRACE ( 
   OPERATION          CHAR(008)                  NOT NULL ,
   TRACE_TIME         TIMESTAMP                  NOT NULL ,
   DESCRIPTION        VARCHAR(1024)              NOT NULL )
in OTHERTS  ; 

CREATE INDEX BACKUP.IBMSNAP_CAPTRACEX 
ON BACKUP.IBMSNV8_CAPTRACE ( 
   TRACE_TIME         ASC                                 
) ;
 
CREATE TABLE BACKUP.IBMSNV8_CAPPARMS ( 
   RETENTION_LIMIT    INT                                 ,
   LAG_LIMIT          INT                                 ,
   COMMIT_INTERVAL    INT                                 ,
   PRUNE_INTERVAL     INT                                 ,
   TRACE_LIMIT        INT                                 ,
   MONITOR_LIMIT      INT                                 ,
   MONITOR_INTERVAL   INT                                 , 
   MEMORY_LIMIT       SMALLINT                            , 
   REMOTE_SRC_SERVER  CHAR(018)                           , 
   AUTOPRUNE          CHAR(001)                           , 
   TERM               CHAR(001)                           , 
   AUTOSTOP           CHAR(001)                           , 
   LOGREUSE           CHAR(001)                           , 
   LOGSTDOUT          CHAR(001)                           , 
   SLEEP_INTERVAL     SMALLINT                            , 
   CAPTURE_PATH       VARCHAR(1040)                       ,
   STARTMODE          VARCHAR(010)                        )
in OTHERTS  ; 
 
CREATE TABLE BACKUP.IBMSNV8_CAPENQ ( 
   LOCKNAME           CHAR(009)                           )
in OTHERTS  ;
 
CREATE TABLE BACKUP.IBMSNV8_SIGNAL (
   SIGNAL_TIME        TIMESTAMP                  NOT NULL WITH DEFAULT ,
   SIGNAL_TYPE        VARCHAR(030)               NOT NULL , 
   SIGNAL_SUBTYPE     VARCHAR(030)                        ,
   SIGNAL_INPUT_IN    VARCHAR(500)                        ,
   SIGNAL_STATE       CHAR(001)                  NOT NULL ,
   SIGNAL_LSN         CHAR(010)     FOR BIT DATA          )
in OTHERTS DATA CAPTURE CHANGES ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SIGNALX
ON BACKUP.IBMSNV8_SIGNAL (
   SIGNAL_TIME        ASC                                 
) ;

CREATE TABLE BACKUP.IBMSNV8_CAPMON ( 
   MONITOR_TIME       TIMESTAMP                  NOT NULL ,
   RESTART_TIME       TIMESTAMP                  NOT NULL ,
   CURRENT_MEMORY     INT                        NOT NULL ,
   CD_ROWS_INSERTED   INT                        NOT NULL ,
   RECAP_ROWS_SKIPPED INT                        NOT NULL , 
   TRIGR_ROWS_SKIPPED INT                        NOT NULL ,
   CHG_ROWS_SKIPPED   INT                        NOT NULL ,
   TRANS_PROCESSED    INT                        NOT NULL ,
   TRANS_SPILLED      INT                        NOT NULL , 
   MAX_TRANS_SIZE     INT                        NOT NULL ,
   LOCKING_RETRIES    INT                        NOT NULL ,
   JRN_LIB            CHAR(010)                           , 
   JRN_NAME           CHAR(010)                           ,
   LOGREADLIMIT       INT                        NOT NULL , 
   CAPTURE_IDLE       INT                        NOT NULL , 
   SYNCHTIME          TIMESTAMP                  NOT NULL )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_CAPMONX 
ON BACKUP.IBMSNV8_CAPMON (
   MONITOR_TIME       ASC                                 
) ;

CREATE TABLE BACKUP.IBMSNV8_PRUNE_LOCK (
   DUMMY              CHAR(001)                           )
in OTHERTS  ;

CREATE TABLE BACKUP.IBMSNV8_APPENQ (
   APPLY_QUAL         CHAR(018)                           )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_APPENQX 
ON BACKUP.IBMSNV8_APPENQ (
   APPLY_QUAL         ASC                                 
) ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_SET (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   SET_TYPE           CHAR(001)                  NOT NULL , 
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   ACTIVATE           SMALLINT                   NOT NULL ,
   SOURCE_SERVER      CHAR(018)                  NOT NULL ,
   SOURCE_ALIAS       CHAR(008)                           ,
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   TARGET_ALIAS       CHAR(008)                           ,
   STATUS             SMALLINT                   NOT NULL ,
   LASTRUN            TIMESTAMP                  NOT NULL ,
   REFRESH_TYPE       CHAR(001)                  NOT NULL , 
   SLEEP_MINUTES      INT                                 ,
   EVENT_NAME         CHAR(018)                           ,
   LASTSUCCESS        TIMESTAMP                           ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SYNCHTIME          TIMESTAMP                           ,
   CAPTURE_SCHEMA     VARCHAR(030)               NOT NULL , 
   TGT_CAPTURE_SCHEMA VARCHAR(030)                        , 
   FEDERATED_SRC_SRVR VARCHAR(018)                        , 
   FEDERATED_TGT_SRVR VARCHAR(018)                        , 
   JRN_LIB            CHAR(010)                           ,
   JRN_NAME           CHAR(010)                           ,
   OPTION_FLAGS       CHAR(004)                  NOT NULL , 
   COMMIT_COUNT       SMALLINT                            , 
   MAX_SYNCH_MINUTES  SMALLINT                            , 
   AUX_STMTS          SMALLINT                   NOT NULL ,
   ARCH_LEVEL         CHAR(004)                  NOT NULL )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_SETX
ON BACKUP.IBMSNV8_SUBS_SET (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ) ;

 CREATE TABLE BACKUP.IBMSNV8_SUBS_MEMBR ( 
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   SOURCE_OWNER       VARCHAR(030)               NOT NULL , 
   SOURCE_TABLE       VARCHAR(128)               NOT NULL , 
   SOURCE_VIEW_QUAL   SMALLINT                   NOT NULL ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   TARGET_CONDENSED   CHAR(001)                  NOT NULL ,
   TARGET_COMPLETE    CHAR(001)                  NOT NULL ,
   TARGET_STRUCTURE   SMALLINT                   NOT NULL ,
   PREDICATES         VARCHAR(1024)                       , 
   MEMBER_STATE       CHAR(001)                           , 
   TARGET_KEY_CHG     CHAR(001)                  NOT NULL , 
   UOW_CD_PREDICATES  VARCHAR(1024)                       , 
   JOIN_UOW_CD        CHAR(001)                           , 
   LOADX_TYPE         SMALLINT                            , 
   LOADX_SRC_N_OWNER  VARCHAR(030)                        , 
   LOADX_SRC_N_TABLE  VARCHAR(128)                        )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_MEMBX
ON BACKUP.IBMSNV8_SUBS_MEMBR (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ,
   SOURCE_OWNER       ASC                                 ,
   SOURCE_TABLE       ASC                                 ,
   SOURCE_VIEW_QUAL   ASC                                 ,
   TARGET_OWNER       ASC                                 ,
   TARGET_TABLE       ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_COLS (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   COL_TYPE           CHAR(001)                  NOT NULL ,
   TARGET_NAME        VARCHAR(030)               NOT NULL ,
   IS_KEY             CHAR(001)                  NOT NULL ,
   COLNO              SMALLINT                   NOT NULL , 
   EXPRESSION         VARCHAR(254)               NOT NULL )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_COLSX
ON BACKUP.IBMSNV8_SUBS_COLS (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ,
   TARGET_OWNER       ASC                                 ,
   TARGET_TABLE       ASC                                 ,
   TARGET_NAME        ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_STMTS (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   BEFORE_OR_AFTER    CHAR(001)                  NOT NULL ,
   STMT_NUMBER        SMALLINT                   NOT NULL ,
   EI_OR_CALL         CHAR(001)                  NOT NULL ,
   SQL_STMT           VARCHAR(1024)                       ,
   ACCEPT_SQLSTATES   VARCHAR(050)                        )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_STMTX
ON BACKUP.IBMSNV8_SUBS_STMTS (
   APPLY_QUAL         ASC                                 ,
   SET_NAME           ASC                                 ,
   WHOS_ON_FIRST      ASC                                 ,
   BEFORE_OR_AFTER    ASC                                 ,
   STMT_NUMBER        ASC                                 )
 ;

CREATE TABLE BACKUP.IBMSNV8_SUBS_EVENT (
   EVENT_NAME         CHAR(018)                  NOT NULL ,
   EVENT_TIME         TIMESTAMP                  NOT NULL ,
   END_SYNCHPOINT     CHAR(010)     FOR BIT DATA          , 
   END_OF_PERIOD      TIMESTAMP                           )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SUBS_EVENX
ON BACKUP.IBMSNV8_SUBS_EVENT (
   EVENT_NAME         ASC                                 ,
   EVENT_TIME         ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_APPLYTRAIL (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   SET_NAME           CHAR(018)                  NOT NULL ,
   SET_TYPE           CHAR(001)                  NOT NULL , 
   WHOS_ON_FIRST      CHAR(001)                  NOT NULL ,
   ASNLOAD            CHAR(001)                           ,
   FULL_REFRESH       CHAR(001)                           , 
   EFFECTIVE_MEMBERS  INT                                 ,
   SET_INSERTED       INT                        NOT NULL ,
   SET_DELETED        INT                        NOT NULL ,
   SET_UPDATED        INT                        NOT NULL ,
   SET_REWORKED       INT                        NOT NULL ,
   SET_REJECTED_TRXS  INT                        NOT NULL ,
   STATUS             SMALLINT                   NOT NULL ,
   LASTRUN            TIMESTAMP                  NOT NULL ,
   LASTSUCCESS        TIMESTAMP                           ,
   SYNCHPOINT         CHAR(010)     FOR BIT DATA          ,
   SYNCHTIME          TIMESTAMP                           ,
   SOURCE_SERVER      CHAR(018)                  NOT NULL ,
   SOURCE_ALIAS       CHAR(008)                           ,
   SOURCE_OWNER       VARCHAR(030)                        , 
   SOURCE_TABLE       VARCHAR(128)                        , 
   SOURCE_VIEW_QUAL   SMALLINT                            ,
   TARGET_SERVER      CHAR(018)                  NOT NULL ,
   TARGET_ALIAS       CHAR(008)                           ,
   TARGET_OWNER       VARCHAR(030)               NOT NULL , 
   TARGET_TABLE       VARCHAR(128)               NOT NULL , 
   CAPTURE_SCHEMA     VARCHAR(030)               NOT NULL , 
   TGT_CAPTURE_SCHEMA VARCHAR(030)                        , 
   FEDERATED_SRC_SRVR VARCHAR(018)                        , 
   FEDERATED_TGT_SRVR VARCHAR(018)                        , 
   JRN_LIB            CHAR(010)                           , 
   JRN_NAME           CHAR(010)                           ,
   COMMIT_COUNT       SMALLINT                            , 
   OPTION_FLAGS       CHAR(004)                  NOT NULL , 
   EVENT_NAME         CHAR(018)                           , 
   ENDTIME            TIMESTAMP                  NOT NULL WITH DEFAULT , 
   SOURCE_CONN_TIME   TIMESTAMP                           , 
   SQLSTATE           CHAR(005)                           ,
   SQLCODE            INT                                 ,
   SQLERRP            CHAR(008)                           ,
   SQLERRM            VARCHAR(070)                        ,
   APPERRM            VARCHAR(760)                        )
in OTHERTS  ;

CREATE INDEX BACKUP.IBMSNAP_APPLYTRLX
ON BACKUP.IBMSNV8_APPLYTRAIL (
   LASTRUN            DESC                                ,
   APPLY_QUAL         ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_COMPENSATE (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   MEMBER             SMALLINT                   NOT NULL ,
   INTENTSEQ          CHAR(010)     FOR BIT DATA NOT NULL ,
   OPERATION          CHAR(001)                  NOT NULL )
in OTHERTS  ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_COMPENSATX
ON BACKUP.IBMSNV8_COMPENSATE (
   APPLY_QUAL         ASC                                 ,
   MEMBER             ASC                                 ) ;

CREATE TABLE BACKUP.IBMSNV8_APPLYTRACE (
   APPLY_QUAL         CHAR(018)                  NOT NULL ,
   TRACE_TIME         TIMESTAMP                  NOT NULL ,
   OPERATION          CHAR(008)                  NOT NULL ,
   DESCRIPTION        VARCHAR(1024)              NOT NULL )
in OTHERTS  ; 

CREATE INDEX BACKUP.IBMSNAP_APPLYTRACX
ON BACKUP.IBMSNV8_APPLYTRACE (
   APPLY_QUAL                                             , 
   TRACE_TIME         ASC                                 ) ; 

CREATE TABLE BACKUP.IBMSNV8_APPPARMS (
   APPLY_QUAL         CHAR(018)                  NOT NULL , 
   APPLY_PATH         VARCHAR(1040)                       , 
   COPYONCE           CHAR(001)                           , 
   DELAY              INT                                 , 
   ERRWAIT            INT                                 , 
   INAMSG             CHAR(001)                           , 
   LOADXIT            CHAR(001)                           , 
   LOGREUSE           CHAR(001)                           , 
   LOGSTDOUT          CHAR(001)                           , 
   NOTIFY             CHAR(001)                           , 
   OPT4ONE            CHAR(001)                           , 
   SLEEP              CHAR(001)                           , 
   SQLERRCONTINUE     CHAR(001)                           , 
   SPILLFILE          VARCHAR(010)                        , 
   TERM               CHAR(001)                           , 
   TRLREUSE           CHAR(001)                           )
in OTHERTS  ; 

CREATE UNIQUE INDEX BACKUP.IBMSNAP_APPPARMSX 
ON BACKUP.IBMSNV8_APPPARMS (
   APPLY_QUAL         ASC                                 ) ;
 
------------------------------------------------------------------------
-- System-independent backups of key parts of system catalogs:
------------------------------------------------------------------------
 
CREATE TABLE BACKUP.IBMSNAP_MIGRATION (
   KIND          CHAR(7),           
   STATE         INTEGER,           
   WHAT8         CHAR(5),           
   WHAT4C        CHAR(5),           
   WHAT1         CHAR(5),           
   TIME          TIMESTAMP,         
   TABLE_SPACE   VARCHAR(100)       
)
in BACKUPTS ;
 
-- Insert 'CONTROL' row first to begin step 1.

INSERT INTO BACKUP.IBMSNAP_MIGRATION VALUES (
   'CONTROL', 1, '-', '-', '1.51', CURRENT TIMESTAMP,
   'in BACKUPTS'
) ;

--
-- A subset of the COLUMNS system catalog to restore pre-V8 Replication:
--

CREATE TABLE BACKUP.IBMSNAP_COLUMNS (
   tabschema          VARCHAR(30),    
   tabname            VARCHAR(128),
   colname            VARCHAR(128),
   colno              SMALLINT,
   typename           VARCHAR(018),
   length             INTEGER,
   default            VARCHAR(254),
   nulls              CHARACTER(001)
)
in BACKUPTS ;

INSERT INTO BACKUP.IBMSNAP_COLUMNS SELECT
   tabschema,
   tabname,
   COLNAME,
   COLNO,
   TYPENAME,
   LENGTH,
   DEFAULT,
   NULLS
FROM SYSCAT.COLUMNS
WHERE tabschema = 'ASN' OR tabschema = UCASE( 'BACKUP' )
OR CHAR( RTRIM( tabschema ) CONCAT ',' CONCAT TABNAME ) IN (
   SELECT CHAR( RTRIM( CD_OWNER ) CONCAT ',' CONCAT CD_TABLE )
   FROM ASN.IBMSNAP_REGISTER
) ;

--
-- A subset of the TABLES system catalog to restore pre-V8 Replication:
--

CREATE TABLE BACKUP.IBMSNAP_TABLES (
   tabschema          VARCHAR(30),
   tabname            VARCHAR(128),
   cd_alias           VARCHAR(7),
   type               CHARACTER(001),
   colcount           SMALLINT,
   datacapture        CHARACTER(001),
   tbspace            VARCHAR(100),
   implicit           CHARACTER(1)
)
in BACKUPTS ;

-- insert names of ASN.*, backup.* tables,
-- and CD tables (except Federated):

INSERT INTO BACKUP.IBMSNAP_TABLES
SELECT
   T.TABSCHEMA,
   T.TABNAME,
   '',
   T.TYPE,
   T.COLCOUNT,
     DATACAPTURE D,
     T.tbspace,
     '-' I

FROM SYSCAT.TABLES T
 
WHERE T.TABSCHEMA = 'ASN'
OR    T.TABSCHEMA = UCASE( 'BACKUP' )
;

INSERT INTO BACKUP.IBMSNAP_TABLES
SELECT
   T.TABSCHEMA,
   T.TABNAME,
   'B',
   T.TYPE,
   T.COLCOUNT,
     DATACAPTURE D,
     T.tbspace,
     '-' I

FROM SYSCAT.TABLES T
 
WHERE
   CHAR( RTRIM( T.TABSCHEMA ) CONCAT ',' CONCAT T.TABNAME ) IN (
   SELECT CHAR( RTRIM( CD_OWNER ) CONCAT ',' CONCAT CD_TABLE )
   FROM ASN.IBMSNAP_REGISTER
) ;

--
-- Save those view definitions dependent on Replication tables:
--

CREATE TABLE BACKUP.IBMSNAP_VIEWS (
   viewschema         VARCHAR(30),
   viewname           VARCHAR(128),
   tabschema          VARCHAR(30),
   tabname            VARCHAR(128),
   seqno              INTEGER,
   text               VARCHAR(3600)
)
in BACKUPTS ;

INSERT INTO BACKUP.IBMSNAP_VIEWS
SELECT
   VS.VIEWSCHEMA,
   VS.VIEWNAME,
   DP.BSCHEMA,
   DP.BNAME,
   VS.SEQNO,
   VS.TEXT
FROM  SYSCAT.VIEWS AS VS JOIN SYSCAT.VIEWDEP AS DP
ON VS.VIEWSCHEMA = DP.viewschema AND VS.VIEWNAME = DP.viewname
WHERE DP.BSCHEMA = 'ASN'
OR CHAR( RTRIM( DP.BSCHEMA ) CONCAT ',' CONCAT DP.BNAME ) IN (
      SELECT CHAR( RTRIM( CD_OWNER ) CONCAT ',' CONCAT CD_TABLE )
      FROM   ASN.IBMSNAP_REGISTER
   )
;

INSERT INTO BACKUP.IBMSNAP_COLUMNS SELECT
   tabschema,
   tabname,
   COLNAME,
   COLNO,
   TYPENAME,
   LENGTH,
   DEFAULT,
   NULLS
FROM  SYSCAT.COLUMNS
WHERE CHAR( RTRIM( tabschema ) CONCAT ',' CONCAT TABNAME ) IN (
   SELECT CHAR( RTRIM( viewschema ) CONCAT ',' CONCAT viewname )
   FROM   BACKUP.IBMSNAP_VIEWS
) ;

--
-- indexes dependent upon replication tables
--

CREATE TABLE BACKUP.IBMSNAP_INDEXES (
   ischema            VARCHAR(30),
   iname              VARCHAR(128),
   itschema           VARCHAR(30),
   itname             VARCHAR(128),
   colnames           VARCHAR(640),
   iunique            CHARACTER(001),
   icolcount          SMALLINT
)
in BACKUPTS ;
 
CREATE TABLE BACKUP.UDB_INDEXES LIKE SYSCAT.INDEXES
in BACKUPTS ;

INSERT INTO BACKUP.UDB_INDEXES
SELECT *
FROM   SYSCAT.INDEXES
WHERE  TABSCHEMA = 'ASN' OR TABSCHEMA = UCASE( 'BACKUP' )
   OR  CHAR( RTRIM( TABSCHEMA ) CONCAT ',' CONCAT TABNAME )
       IN ( SELECT CHAR( RTRIM( CD_OWNER  ) CONCAT ',' CONCAT CD_TABLE )
       FROM ASN.IBMSNAP_REGISTER ) ;

CREATE TABLE BACKUP.UDB_TABAUTH LIKE SYSCAT.TABAUTH
in BACKUPTS ;

INSERT INTO  BACKUP.UDB_TABAUTH
SELECT *
FROM   SYSCAT.TABAUTH
WHERE  TABSCHEMA = 'ASN'
   OR  CHAR( RTRIM( TABSCHEMA ) CONCAT ',' CONCAT TABNAME )
       IN ( SELECT CHAR( RTRIM( CD_OWNER  ) CONCAT ',' CONCAT CD_TABLE )
       FROM ASN.IBMSNAP_REGISTER ) ;

CREATE TABLE BACKUP.GRANTS( GRANT VARCHAR( 500 ) ) 
in BACKUPTS ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT ALTER      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where ALTERAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT ALTER      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where ALTERAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT DELETE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where DELETEAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT DELETE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where DELETEAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INDEX      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where INDEXAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INDEX      ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where INDEXAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INSERT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where INSERTAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT INSERT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where INSERTAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT SELECT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where SELECTAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT SELECT     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where SELECTAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT REFERENCES ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where REFAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT REFERENCES ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where REFAUTH = 'G' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT UPDATE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' ;'  
from  BACKUP.UDB_TABAUTH 
where UPDATEAUTH = 'Y' ;

INSERT INTO  BACKUP.GRANTS 
select 
  'GRANT UPDATE     ON "' || 
  rtrim( TABSCHEMA ) || '"."' || TABNAME || '" ' ||
  case when length( rtrim(TABSCHEMA)||TABNAME ) >= 30 then '' 
  else substr( '                              ', 1, 
               30 - length( rtrim(TABSCHEMA)||TABNAME ) ) 
  end || ' TO ' || GRANTEE || ' WITH GRANT OPTION ;'  
from  BACKUP.UDB_TABAUTH 
where UPDATEAUTH = 'G' ;
 
CREATE INDEX BACKUP.IBMSNAP_INDEXES_X ON BACKUP.IBMSNAP_INDEXES (
   itschema,
   itname
) ;

INSERT INTO BACKUP.IBMSNAP_INDEXES SELECT
   indschema,
   indname,
   tabschema,
   tabname,
   colnames,
   uniquerule,
   colcount
FROM SYSCAT.INDEXES
WHERE tabschema = 'ASN' OR tabschema = UCASE( 'BACKUP' )
   OR CHAR( RTRIM( tabschema ) CONCAT ',' CONCAT tabname )
      IN ( SELECT CHAR( RTRIM( CD_OWNER  ) CONCAT ',' CONCAT CD_TABLE )
      FROM ASN.IBMSNAP_REGISTER ) ;

CREATE TABLE BACKUP.IBMSNAP_KEYS (
   kschema            VARCHAR(30),
   kname              VARCHAR(128),
   kcolname           VARCHAR(018),
   kcolseq            SMALLINT NOT NULL,
   kordering          CHAR(1)  NOT NULL
)
in BACKUPTS ;

--
-- For connected AS/400's with JRN_LIB and JRN_NAME data, 
-- create IBMSNAP_AS400.
--
-- Notes:
-- 1.  For each subs_set key, choose any one (1) of the corresp. rows in
--     subs_membr to get source_owner, source_table, source_view_qual.
-- 2.  The jrn_lib and jrn_name cols are the same for all elements
--     sharing apply_qual, set_name, whos_on_first.
--
--  
--

CREATE TABLE BACKUP.IBMSNAP_AS400 (
   apply_qual        CHAR(18) NOT NULL,
   set_name          CHAR(18) NOT NULL,
   whos_on_first     CHAR(01) NOT NULL,
   source_owner      VARCHAR(30),
   source_table      VARCHAR(128),
   source_view_qual  SMALLINT,
   source_alias      CHAR(18),
   jrn_lib           CHAR(10),
   jrn_name          CHAR(10)
)
in BACKUPTS ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_AS400_X
ON BACKUP.IBMSNAP_AS400 (
   apply_qual,
   set_name,
   whos_on_first ) ;

INSERT INTO BACKUP.IBMSNAP_AS400
SELECT DISTINCT
   apply_qual,
   set_name,
   whos_on_first,
   nullif('',''),
   nullif('',''),
   -1,
   coalesce( source_alias, source_server ),
   nullif('',''),
   nullif('','')
FROM ASN.IBMSNAP_SUBS_SET ;

UPDATE BACKUP.IBMSNAP_AS400 A
SET            source_owner =
(  SELECT MIN( source_owner )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first
) ;

UPDATE BACKUP.IBMSNAP_AS400 A
SET            source_table =
(  SELECT MIN( source_table )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        source_owner = a.source_owner
) ;

UPDATE BACKUP.IBMSNAP_AS400 A
SET            source_view_qual =
(  SELECT MIN( source_view_qual ) FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        source_owner = a.source_owner  AND
        source_table = a.source_table
) ;

DELETE FROM BACKUP.IBMSNAP_AS400
  WHERE source_owner     is null
     OR source_table     is null
     OR source_view_qual is null
;

-- end IBMSNAP_AS400

--
-- For heterogeneous IBMSNAP_SUBS_SET migration:
--

CREATE TABLE BACKUP.IBMSNAP_SRVR (
   apply_qual         CHAR(18) NOT NULL,
   set_name           CHAR(18) NOT NULL,
   whos_on_first      CHAR(01) NOT NULL,
   source_alias       CHAR(18),
   source_owner       VARCHAR(030),
   source_table       VARCHAR(128),
   federated_src_srvr VARCHAR(18),
   federated_src_type VARCHAR(30),
   target_alias       CHAR(08),
   target_owner       VARCHAR(030),
   target_table       VARCHAR(128),
   federated_tgt_srvr VARCHAR(18),
   federated_tgt_type VARCHAR(30) 
)
in BACKUPTS ;

CREATE UNIQUE INDEX BACKUP.IBMSNAP_SRVR_X
ON BACKUP.IBMSNAP_SRVR (
   apply_qual,
   set_name,
   whos_on_first ) ;

INSERT INTO BACKUP.IBMSNAP_SRVR
SELECT DISTINCT
   apply_qual,
   set_name,
   whos_on_first,
   coalesce( source_alias, source_server ),
   nullif('',''),
   nullif('',''),
   nullif('',''),
   nullif('',''),
   coalesce( target_alias, target_server ),
   nullif('',''),
   nullif('',''),
   nullif('',''),
   nullif('','')
FROM ASN.IBMSNAP_SUBS_SET ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            source_owner =
(  SELECT MIN( source_owner )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first
) ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            source_table =
(  SELECT MIN( source_table )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        source_owner = a.source_owner
) ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            target_owner =
(  SELECT MIN( target_owner )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first
) ;

UPDATE BACKUP.IBMSNAP_SRVR A
SET            target_table =
(  SELECT MIN( target_table )     FROM ASN.IBMSNAP_SUBS_MEMBR
   WHERE  apply_qual = a.apply_qual    AND
            set_name = a.set_name      AND
       whos_on_first = a.whos_on_first AND
        target_owner = a.target_owner
) ;

DELETE FROM BACKUP.IBMSNAP_SRVR
   WHERE source_owner is null
      OR source_table is null
      OR target_owner is null
      OR target_table is null
;

-- end IBMSNAP_SRVR
 
--
-- isolated table for serialization only
--

CREATE TABLE BACKUP.IBMSNAP_MUTEX (
   I INTEGER
)
in BACKUPTS ;

-- arbitrary value for serialization only:
INSERT INTO BACKUP.IBMSNAP_MUTEX VALUES ( 0 ) ;
 
create table BACKUP.ibmsnap_hetero (
   remote_server     varchar(18)  not null,
   remote_tabschema  varchar(30)  not null,
   remote_option     varchar(80)  not null,
   server_type       varchar(30)  not null,
   server_version    varchar(18)  not null,
   triggers_save     long varchar not null,
   triggers_v8       long varchar not null,
   triggers_restore  long varchar not null,
   wrapper           varchar(128)
) 
in BACKUPTS ; 

create table BACKUP.ibmsnap_nicknames (
   schema            varchar(128) not null,
   table             varchar(128) not null,
   oem_schema        varchar(128) not null,
   oem_table         varchar(128) not null
) 
in BACKUPTS ; 

-- written in backup step (2), read in fallback step(4):

create table BACKUP.triggers_saved (
   trigger_id        int,
   seq_no            int,
   trigger           long varchar
)
in BACKUPTS ; 

create table BACKUP.procs_saved (
   proc_id           int,
   seq_no            int,
   proc              long varchar
)
in BACKUPTS ; 

insert into BACKUP.ibmsnap_hetero
   values( '', '', '', '', '', '', '', '', '' ) ;
 
-- Tables for Federated migration under 1 8.x 

update BACKUP.ibmsnap_hetero
   set remote_server = 
   ( select setting 
       from sysibm.systaboptions
      where tabschema = 'ASN'
        and   tabname = 'IBMSNAP_REGISTER' 
        and    option = 'SERVER' ) ;

update BACKUP.ibmsnap_hetero
   set remote_tabschema = 
   ( select setting 
       from sysibm.systaboptions
      where tabschema = 'ASN'
        and   tabname = 'IBMSNAP_REGISTER' 
        and    option = 'REMOTE_SCHEMA' ) ;

update BACKUP.ibmsnap_hetero h
   set (    server_type, server_version, wrapper  ) = 
   ( select servertype,  serverversion,  wrapname
       from sysibm.sysservers 
      where SERVERNAME = h.remote_server ) ;

insert into BACKUP.ibmsnap_nicknames
  select r.phys_change_owner, r.phys_change_table, s.setting, t.setting
  from ( asn.ibmsnap_register r INNER JOIN
         sysibm.systaboptions s
         on  s.option = 'REMOTE_SCHEMA'
         and r.phys_change_owner = s.tabschema
         and r.phys_change_table = s.tabname ) INNER JOIN
         sysibm.systaboptions t
         on  t.option = 'REMOTE_TABLE'
         and r.phys_change_owner = t.tabschema 
         and r.phys_change_table = t.tabname ;
 
update BACKUP.ibmsnap_hetero set triggers_save= 
   ''
|| '-DROP NICKNAME $BACKUP.OEM_TRIGGERS#'
|| '@CREATE NICKNAME $BACKUP.OEM_TRIGGERS '
|| 'FOR $REMOTE_DB_SERVER."informix"."systrigbody"#'
|| '@DELETE FROM $BACKUP.TRIGGERS_SAVED#'
|| '@INSERT INTO $BACKUP.TRIGGERS_SAVED '
|| 'SELECT TRIGID,0,DATA '
|| 'FROM $BACKUP.OEM_TRIGGERS '
|| 'WHERE DATAKEY=''D''#'
|| '@INSERT INTO $BACKUP.TRIGGERS_SAVED '
|| 'SELECT TRIGID,SEQNO+1,DATA '
|| 'FROM $BACKUP.OEM_TRIGGERS '
|| 'WHERE DATAKEY=''A''#'
|| '@UPDATE $BACKUP.TRIGGERS_SAVED '
|| 'SET TRIGGER_ID=-1 '
|| 'WHERE TRIGGER_ID=( '
|| 'SELECT TRIGGER_ID '
|| 'FROM $BACKUP.TRIGGERS_SAVED '
|| 'WHERE SEQ_NO=0 '
|| 'AND ( TRIGGER LIKE ''%"$REMOTE_TABSCHEMA".pruncntl_trigger%'''
|| 'OR TRIGGER LIKE ''%"$REMOTE_TABSCHEMA".PRUNCNTL_TRIGGER%'' ) '
|| ')#'
|| '-DROP NICKNAME $BACKUP.OEM_PROCS#'
|| '@CREATE NICKNAME $BACKUP.OEM_PROCS '
|| 'FOR $REMOTE_DB_SERVER."informix"."sysprocbody"#'
|| '@DELETE FROM $BACKUP.PROCS_SAVED#'
|| '@INSERT INTO $BACKUP.PROCS_SAVED '
|| 'SELECT PROCID,SEQNO,DATA '
|| 'FROM $BACKUP.OEM_PROCS '
|| 'WHERE DATAKEY=''T''#'
|| '@UPDATE $BACKUP.PROCS_SAVED '
|| 'SET PROC_ID=-1 '
|| 'WHERE PROC_ID=( '
|| 'SELECT PROC_ID '
|| 'FROM $BACKUP.PROCS_SAVED '
|| 'WHERE SEQ_NO=1 '
|| 'AND ( PROC LIKE ''%"$REMOTE_TABSCHEMA".pruncntl_proc%'''
|| 'OR PROC LIKE ''%"$REMOTE_TABSCHEMA".PRUNCNTL_PROC%'' ) '
|| ')#'
|| '@UPDATE $BACKUP.PROCS_SAVED '
|| 'SET PROC_ID=-2 '
|| 'WHERE PROC_ID=( '
|| 'SELECT PROC_ID '
|| 'FROM $BACKUP.PROCS_SAVED '
|| 'WHERE SEQ_NO=1 '
|| 'AND ( PROC LIKE ''%"$REMOTE_TABSCHEMA"%ibmsnap_synch_proc%'''
|| 'OR PROC LIKE ''%"$REMOTE_TABSCHEMA"%IBMSNAP_SYNCH_PROC%'' ) '
|| ')#'
|| '@COMMIT#'
where server_type='INFORMIX' and server_version='7.3';
update BACKUP.ibmsnap_hetero set triggers_v8= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc"#'
|| '@CREATE PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc" ( '
|| 'NEWSOURCE_OWNER CHAR(30), '
|| 'NEWSOURCE_TABLE CHAR(18), '
|| 'NEWPHYS_CHG_OWNER CHAR(30), '
|| 'NEWPHYS_CHG_TABLE CHAR(18) '
|| ') DEFINE MIN_SYNCHPOINT CHAR(10);'
|| 'SELECT MIN(SYNCHPOINT) '
|| 'INTO MIN_SYNCHPOINT '
|| 'FROM "$REMOTE_TABSCHEMA".ibmsnap_pruncntl '
|| 'WHERE SOURCE_OWNER=NEWSOURCE_OWNER '
|| 'AND SOURCE_TABLE=NEWSOURCE_TABLE;'
|| '${ select '
|| '''IF NEWPHYS_CHG_OWNER='''''' || rtrim( schema ) || '
|| ''''''' AND NEWPHYS_CHG_TABLE='''''' || rtrim( table ) || '
|| ''''''' THEN DELETE FROM "'' || rtrim( oem_schema ) || '
|| '''"."'' || rtrim( oem_table ) || '
|| '''" WHERE IBMSNAP_COMMITSEQ < MIN_SYNCHPOINT;END IF;'''
|| 'from BACKUP.ibmsnap_nicknames '
|| '} '
|| 'END PROCEDURE;#'
|| '@COMMIT#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."ibmsnap_synch_proc"#'
|| '@CREATE PROCEDURE "$REMOTE_TABSCHEMA"."ibmsnap_synch_proc"() '
|| 'DEFINE VARM INTEGER;'
|| 'DEFINE VARD INTEGER;DEFINE VARY INTEGER;DEFINE VARH CHAR(2);'
|| 'DEFINE VARMM CHAR(2);DEFINE VARSS CHAR(2);'
|| 'DEFINE VARDC CHAR(1);DEFINE VARHC CHAR(1);DEFINE VARMS CHAR(6);'
|| 'DEFINE VARYMC CHAR(1);DEFINE VARMMC CHAR(1);DEFINE VARSSC CHAR(1);'
|| 'DEFINE NEWSYNCH CHAR(10);'
|| 'SELECT MONTH(TODAY),YEAR(TODAY),DAY(TODAY),CURRENT HOUR TO HOUR, '
|| 'CURRENT MINUTE TO MINUTE,CURRENT SECOND TO SECOND, '
|| 'CURRENT FRACTION TO FRACTION(5) '
|| 'INTO VARM,VARY,VARD,VARH,VARMM,VARSS,VARMS '
|| 'FROM "$REMOTE_TABSCHEMA"."ibmsnap_seqtable";'
|| 'IF (VARY=2002 ) AND (VARM=6) THEN LET VARYMC=''0'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=7) THEN LET VARYMC=''1'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=8) THEN LET VARYMC=''2'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=9) THEN LET VARYMC=''3'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=10) THEN LET VARYMC=''4'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=11) THEN LET VARYMC=''5'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=12) THEN LET VARYMC=''6'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=1) THEN LET VARYMC=''7'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=2) THEN LET VARYMC=''8'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=3) THEN LET VARYMC=''9'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=4) THEN LET VARYMC=''A'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=5) THEN LET VARYMC=''B'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=6) THEN LET VARYMC=''C'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=7) THEN LET VARYMC=''D'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=8) THEN LET VARYMC=''E'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=9) THEN LET VARYMC=''F'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=10) THEN LET VARYMC=''G'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=11) THEN LET VARYMC=''H'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=12) THEN LET VARYMC=''I'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=1) THEN LET VARYMC=''J'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=2) THEN LET VARYMC=''K'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=3) THEN LET VARYMC=''L'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=4) THEN LET VARYMC=''M'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=5) THEN LET VARYMC=''N'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=6) THEN LET VARYMC=''O'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=7) THEN LET VARYMC=''P'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=8) THEN LET VARYMC=''Q'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=9) THEN LET VARYMC=''R'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=10) THEN LET VARYMC=''S'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=11) THEN LET VARYMC=''T'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=12) THEN LET VARYMC=''U'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=1) THEN LET VARYMC=''V'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=2) THEN LET VARYMC=''W'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=3) THEN LET VARYMC=''X'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=4) THEN LET VARYMC=''Y'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=5) THEN LET VARYMC=''Z'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=6) THEN LET VARYMC=''a'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=7) THEN LET VARYMC=''b'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=8) THEN LET VARYMC=''c'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=9) THEN LET VARYMC=''d'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=10) THEN LET VARYMC=''e'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=11) THEN LET VARYMC=''f'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=12) THEN LET VARYMC=''g'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=1) THEN LET VARYMC=''h'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=2) THEN LET VARYMC=''i'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=3) THEN LET VARYMC=''j'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=4) THEN LET VARYMC=''k'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=5) THEN LET VARYMC=''l'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=6) THEN LET VARYMC=''m'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=7) THEN LET VARYMC=''n'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=8) THEN LET VARYMC=''o'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=9) THEN LET VARYMC=''p'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=10) THEN LET VARYMC=''q'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=11) THEN LET VARYMC=''r'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=12) THEN LET VARYMC=''s'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=1) THEN LET VARYMC=''t'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''u'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''v'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''w'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''x'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''y'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''z'';END IF;'
|| 'IF (VARD=1) THEN LET VARDC=''A'';END IF;IF (VARD=2) THEN LET VARDC=''B'';END IF;'
|| 'IF (VARD=3) THEN LET VARDC=''C'';END IF;IF (VARD=4) THEN LET VARDC=''D'';END IF;'
|| 'IF (VARD=5) THEN LET VARDC=''E'';END IF;IF (VARD=6) THEN LET VARDC=''F'';END IF;'
|| 'IF (VARD=7) THEN LET VARDC=''G'';END IF;IF (VARD=8) THEN LET VARDC=''H'';END IF;'
|| 'IF (VARD=9) THEN LET VARDC=''I'';END IF;IF (VARD=10) THEN LET VARDC=''J'';END IF;'
|| 'IF (VARD=11) THEN LET VARDC=''K'';END IF;IF (VARD=12) THEN LET VARDC=''L'';END IF;'
|| 'IF (VARD=13) THEN LET VARDC=''M'';END IF;IF (VARD=14) THEN LET VARDC=''N'';END IF;'
|| 'IF (VARD=15) THEN LET VARDC=''O'';END IF;IF (VARD=16) THEN LET VARDC=''P'';END IF;'
|| 'IF (VARD=17) THEN LET VARDC=''Q'';END IF;IF (VARD=18) THEN LET VARDC=''R'';END IF;'
|| 'IF (VARD=19) THEN LET VARDC=''S'';END IF;IF (VARD=20) THEN LET VARDC=''T'';END IF;'
|| 'IF (VARD=21) THEN LET VARDC=''U'';END IF;IF (VARD=22) THEN LET VARDC=''V'';END IF;'
|| 'IF (VARD=23) THEN LET VARDC=''W'';END IF;IF (VARD=24) THEN LET VARDC=''X'';END IF;'
|| 'IF (VARD=25) THEN LET VARDC=''Y'';END IF;IF (VARD=26) THEN LET VARDC=''Z'';END IF;'
|| 'IF (VARD=27) THEN LET VARDC=''a'';END IF;IF (VARD=28) THEN LET VARDC=''b'';END IF;'
|| 'IF (VARD=29) THEN LET VARDC=''c'';END IF;IF (VARD=30) THEN LET VARDC=''d'';END IF;'
|| 'IF (VARD=31) THEN LET VARDC=''e'';END IF;IF (VARH=00) THEN LET VARHC=''A'';END IF;'
|| 'IF (VARH=01) THEN LET VARHC=''B'';END IF;IF (VARH=02) THEN LET VARHC=''C'';END IF;'
|| 'IF (VARH=03) THEN LET VARHC=''D'';END IF;IF (VARH=04) THEN LET VARHC=''E'';END IF;'
|| 'IF (VARH=05) THEN LET VARHC=''F'';END IF;IF (VARH=06) THEN LET VARHC=''G'';END IF;'
|| 'IF (VARH=07) THEN LET VARHC=''H'';END IF;IF (VARH=08) THEN LET VARHC=''I'';END IF;'
|| 'IF (VARH=09) THEN LET VARHC=''J'';END IF;IF (VARH=10) THEN LET VARHC=''K'';END IF;'
|| 'IF (VARH=11) THEN LET VARHC=''L'';END IF;IF (VARH=12) THEN LET VARHC=''M'';END IF;'
|| 'IF (VARH=13) THEN LET VARHC=''N'';END IF;IF (VARH=14) THEN LET VARHC=''O'';END IF;'
|| 'IF (VARH=15) THEN LET VARHC=''P'';END IF;IF (VARH=16) THEN LET VARHC=''Q'';END IF;'
|| 'IF (VARH=17) THEN LET VARHC=''R'';END IF;IF (VARH=18) THEN LET VARHC=''S'';END IF;'
|| 'IF (VARH=19) THEN LET VARHC=''T'';END IF;IF (VARH=20) THEN LET VARHC=''U'';END IF;'
|| 'IF (VARH=21) THEN LET VARHC=''V'';END IF;IF (VARH=22) THEN LET VARHC=''W'';END IF;'
|| 'IF (VARH=23) THEN LET VARHC=''X'';END IF;'
|| 'IF (VARMM=00) THEN LET VARMMC=''0'';END IF;'
|| 'IF (VARMM=01) THEN LET VARMMC=''1'';END IF;'
|| 'IF (VARMM=02) THEN LET VARMMC=''2'';END IF;'
|| 'IF (VARMM=03) THEN LET VARMMC=''3'';END IF;'
|| 'IF (VARMM=04) THEN LET VARMMC=''4'';END IF;'
|| 'IF (VARMM=05) THEN LET VARMMC=''5'';END IF;'
|| 'IF (VARMM=06) THEN LET VARMMC=''6'';END IF;'
|| 'IF (VARMM=07) THEN LET VARMMC=''7'';END IF;'
|| 'IF (VARMM=08) THEN LET VARMMC=''8'';END IF;'
|| 'IF (VARMM=09) THEN LET VARMMC=''9'';END IF;'
|| 'IF (VARMM=10) THEN LET VARMMC=''A'';END IF;'
|| 'IF (VARMM=11) THEN LET VARMMC=''B'';END IF;'
|| 'IF (VARMM=12) THEN LET VARMMC=''C'';END IF;'
|| 'IF (VARMM=13) THEN LET VARMMC=''D'';END IF;'
|| 'IF (VARMM=14) THEN LET VARMMC=''E'';END IF;'
|| 'IF (VARMM=15) THEN LET VARMMC=''F'';END IF;'
|| 'IF (VARMM=16) THEN LET VARMMC=''G'';END IF;'
|| 'IF (VARMM=17) THEN LET VARMMC=''H'';END IF;'
|| 'IF (VARMM=18) THEN LET VARMMC=''I'';END IF;'
|| 'IF (VARMM=19) THEN LET VARMMC=''J'';END IF;'
|| 'IF (VARMM=20) THEN LET VARMMC=''K'';END IF;'
|| 'IF (VARMM=21) THEN LET VARMMC=''L'';END IF;'
|| 'IF (VARMM=22) THEN LET VARMMC=''M'';END IF;'
|| 'IF (VARMM=23) THEN LET VARMMC=''N'';END IF;'
|| 'IF (VARMM=24) THEN LET VARMMC=''O'';END IF;'
|| 'IF (VARMM=25) THEN LET VARMMC=''P'';END IF;'
|| 'IF (VARMM=26) THEN LET VARMMC=''Q'';END IF;'
|| 'IF (VARMM=27) THEN LET VARMMC=''R'';END IF;'
|| 'IF (VARMM=28) THEN LET VARMMC=''S'';END IF;'
|| 'IF (VARMM=29) THEN LET VARMMC=''T'';END IF;'
|| 'IF (VARMM=30) THEN LET VARMMC=''U'';END IF;'
|| 'IF (VARMM=31) THEN LET VARMMC=''V'';END IF;'
|| 'IF (VARMM=32) THEN LET VARMMC=''W'';END IF;'
|| 'IF (VARMM=33) THEN LET VARMMC=''X'';END IF;'
|| 'IF (VARMM=34) THEN LET VARMMC=''Y'';END IF;'
|| 'IF (VARMM=35) THEN LET VARMMC=''Z'';END IF;'
|| 'IF (VARMM=36) THEN LET VARMMC=''a'';END IF;'
|| 'IF (VARMM=37) THEN LET VARMMC=''b'';END IF;'
|| 'IF (VARMM=38) THEN LET VARMMC=''c'';END IF;'
|| 'IF (VARMM=39) THEN LET VARMMC=''d'';END IF;'
|| 'IF (VARMM=40) THEN LET VARMMC=''e'';END IF;'
|| 'IF (VARMM=41) THEN LET VARMMC=''f'';END IF;'
|| 'IF (VARMM=42) THEN LET VARMMC=''g'';END IF;'
|| 'IF (VARMM=43) THEN LET VARMMC=''h'';END IF;'
|| 'IF (VARMM=44) THEN LET VARMMC=''i'';END IF;'
|| 'IF (VARMM=45) THEN LET VARMMC=''j'';END IF;'
|| 'IF (VARMM=46) THEN LET VARMMC=''k'';END IF;'
|| 'IF (VARMM=47) THEN LET VARMMC=''l'';END IF;'
|| 'IF (VARMM=48) THEN LET VARMMC=''m'';END IF;'
|| 'IF (VARMM=49) THEN LET VARMMC=''n'';END IF;'
|| 'IF (VARMM=50) THEN LET VARMMC=''o'';END IF;'
|| 'IF (VARMM=51) THEN LET VARMMC=''p'';END IF;'
|| 'IF (VARMM=52) THEN LET VARMMC=''q'';END IF;'
|| 'IF (VARMM=53) THEN LET VARMMC=''r'';END IF;'
|| 'IF (VARMM=54) THEN LET VARMMC=''s'';END IF;'
|| 'IF (VARMM=55) THEN LET VARMMC=''t'';END IF;'
|| 'IF (VARMM=56) THEN LET VARMMC=''u'';END IF;'
|| 'IF (VARMM=57) THEN LET VARMMC=''v'';END IF;'
|| 'IF (VARMM=58) THEN LET VARMMC=''w'';END IF;'
|| 'IF (VARMM=59) THEN LET VARMMC=''x'';END IF;'
|| 'IF (VARSS=00) THEN LET VARSSC=''0'';END IF;'
|| 'IF (VARSS=01) THEN LET VARSSC=''1'';END IF;'
|| 'IF (VARSS=02) THEN LET VARSSC=''2'';END IF;'
|| 'IF (VARSS=03) THEN LET VARSSC=''3'';END IF;'
|| 'IF (VARSS=04) THEN LET VARSSC=''4'';END IF;'
|| 'IF (VARSS=05) THEN LET VARSSC=''5'';END IF;'
|| 'IF (VARSS=06) THEN LET VARSSC=''6'';END IF;'
|| 'IF (VARSS=07) THEN LET VARSSC=''7'';END IF;'
|| 'IF (VARSS=08) THEN LET VARSSC=''8'';END IF;'
|| 'IF (VARSS=09) THEN LET VARSSC=''9'';END IF;'
|| 'IF (VARSS=10) THEN LET VARSSC=''A'';END IF;'
|| 'IF (VARSS=11) THEN LET VARSSC=''B'';END IF;'
|| 'IF (VARSS=12) THEN LET VARSSC=''C'';END IF;'
|| 'IF (VARSS=13) THEN LET VARSSC=''D'';END IF;'
|| 'IF (VARSS=14) THEN LET VARSSC=''E'';END IF;'
|| 'IF (VARSS=15) THEN LET VARSSC=''F'';END IF;'
|| 'IF (VARSS=16) THEN LET VARSSC=''G'';END IF;'
|| 'IF (VARSS=17) THEN LET VARSSC=''H'';END IF;'
|| 'IF (VARSS=18) THEN LET VARSSC=''I'';END IF;'
|| 'IF (VARSS=19) THEN LET VARSSC=''J'';END IF;'
|| 'IF (VARSS=20) THEN LET VARSSC=''K'';END IF;'
|| 'IF (VARSS=21) THEN LET VARSSC=''L'';END IF;'
|| 'IF (VARSS=22) THEN LET VARSSC=''M'';END IF;'
|| 'IF (VARSS=23) THEN LET VARSSC=''N'';END IF;'
|| 'IF (VARSS=24) THEN LET VARSSC=''O'';END IF;'
|| 'IF (VARSS=25) THEN LET VARSSC=''P'';END IF;'
|| 'IF (VARSS=26) THEN LET VARSSC=''Q'';END IF;'
|| 'IF (VARSS=27) THEN LET VARSSC=''R'';END IF;'
|| 'IF (VARSS=28) THEN LET VARSSC=''S'';END IF;'
|| 'IF (VARSS=29) THEN LET VARSSC=''T'';END IF;'
|| 'IF (VARSS=30) THEN LET VARSSC=''U'';END IF;'
|| 'IF (VARSS=31) THEN LET VARSSC=''V'';END IF;'
|| 'IF (VARSS=32) THEN LET VARSSC=''W'';END IF;'
|| 'IF (VARSS=33) THEN LET VARSSC=''X'';END IF;'
|| 'IF (VARSS=34) THEN LET VARSSC=''Y'';END IF;'
|| 'IF (VARSS=35) THEN LET VARSSC=''Z'';END IF;'
|| 'IF (VARSS=36) THEN LET VARSSC=''a'';END IF;'
|| 'IF (VARSS=37) THEN LET VARSSC=''b'';END IF;'
|| 'IF (VARSS=38) THEN LET VARSSC=''c'';END IF;'
|| 'IF (VARSS=39) THEN LET VARSSC=''d'';END IF;'
|| 'IF (VARSS=40) THEN LET VARSSC=''e'';END IF;'
|| 'IF (VARSS=41) THEN LET VARSSC=''f'';END IF;'
|| 'IF (VARSS=42) THEN LET VARSSC=''g'';END IF;'
|| 'IF (VARSS=43) THEN LET VARSSC=''h'';END IF;'
|| 'IF (VARSS=44) THEN LET VARSSC=''i'';END IF;'
|| 'IF (VARSS=45) THEN LET VARSSC=''j'';END IF;'
|| 'IF (VARSS=46) THEN LET VARSSC=''k'';END IF;'
|| 'IF (VARSS=47) THEN LET VARSSC=''l'';END IF;'
|| 'IF (VARSS=48) THEN LET VARSSC=''m'';END IF;'
|| 'IF (VARSS=49) THEN LET VARSSC=''n'';END IF;'
|| 'IF (VARSS=50) THEN LET VARSSC=''o'';END IF;'
|| 'IF (VARSS=51) THEN LET VARSSC=''p'';END IF;'
|| 'IF (VARSS=52) THEN LET VARSSC=''q'';END IF;'
|| 'IF (VARSS=53) THEN LET VARSSC=''r'';END IF;'
|| 'IF (VARSS=54) THEN LET VARSSC=''s'';END IF;'
|| 'IF (VARSS=55) THEN LET VARSSC=''t'';END IF;'
|| 'IF (VARSS=56) THEN LET VARSSC=''u'';END IF;'
|| 'IF (VARSS=57) THEN LET VARSSC=''v'';END IF;'
|| 'IF (VARSS=58) THEN LET VARSSC=''w'';END IF;'
|| 'IF (VARSS=59) THEN LET VARSSC=''x'';END IF;'
|| 'LET NEWSYNCH=TRIM(VARYMC)||TRIM(VARDC)||TRIM(VARHC)||TRIM(VARMMC)||TRIM(VARSSC)|| '
|| 'TRIM(LEADING ''.'' FROM VARMS);'
|| 'UPDATE "$REMOTE_TABSCHEMA"."ibmsnap_pruncntl" '
|| 'SET SYNCHPOINT=''0000000000'',SYNCHTIME=current year to fraction(5) '
|| 'WHERE SYNCHPOINT is null;'
|| 'UPDATE "$REMOTE_TABSCHEMA"."ibmsnap_register" '
|| 'SET (SYNCHPOINT,SYNCHTIME)= '
|| '(NEWSYNCH,CURRENT YEAR TO FRACTION(5));'
|| 'END PROCEDURE;#'
|| '@COMMIT#'
|| '-DROP TRIGGER "$REMOTE_TABSCHEMA"."pruncntl_trigger"#'
|| '@CREATE TRIGGER "$REMOTE_TABSCHEMA"."pruncntl_trigger" '
|| 'UPDATE OF "synchpoint" ON "$REMOTE_TABSCHEMA"."ibmsnap_pruncntl" '
|| 'REFERENCING NEW AS NEW OLD AS OLD '
|| 'FOR EACH ROW ( '
|| 'EXECUTE PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc" ( '
|| 'NEW."source_owner", '
|| 'NEW."source_table", '
|| 'NEW."phys_change_owner", '
|| 'NEW."phys_change_table" '
|| ') '
|| ');'
|| '${ select '''' from BACKUP.ibmsnap_nicknames }#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='INFORMIX' and server_version='7.3';
update BACKUP.ibmsnap_hetero set triggers_restore= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc"#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."PRUNCNTL_PROC"#'
|| '@ ${ select proc '
|| 'from $BACKUP .procs_saved '
|| 'where proc_id=-1 }#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."ibmsnap_synch_proc"#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."IBMSNAP_SYNCH_PROC"#'
|| '@ ${ select proc '
|| 'from $BACKUP .procs_saved '
|| 'where proc_id=-2 }#'
|| '-DROP TRIGGER "$REMOTE_TABSCHEMA"."pruncntl_trigger"#'
|| '-DROP TRIGGER "$REMOTE_TABSCHEMA"."PRUNCNTL_TRIGGER"#'
|| '@ ${ select trigger '
|| 'from $BACKUP .triggers_saved '
|| 'where trigger_id=-1 }#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='INFORMIX' and server_version='7.3';
 
update BACKUP.ibmsnap_hetero set triggers_save= 
   ''
|| '-DROP NICKNAME $BACKUP.OEM_TRIGGERS#'
|| '@CREATE NICKNAME $BACKUP.OEM_TRIGGERS '
|| 'FOR $REMOTE_DB_SERVER."informix"."systrigbody"#'
|| '@DELETE FROM $BACKUP.TRIGGERS_SAVED#'
|| '@INSERT INTO $BACKUP.TRIGGERS_SAVED '
|| 'SELECT TRIGID,0,DATA '
|| 'FROM $BACKUP.OEM_TRIGGERS '
|| 'WHERE DATAKEY=''D''#'
|| '@INSERT INTO $BACKUP.TRIGGERS_SAVED '
|| 'SELECT TRIGID,SEQNO+1,DATA '
|| 'FROM $BACKUP.OEM_TRIGGERS '
|| 'WHERE DATAKEY=''A''#'
|| '@UPDATE $BACKUP.TRIGGERS_SAVED '
|| 'SET TRIGGER_ID=-1 '
|| 'WHERE TRIGGER_ID=( '
|| 'SELECT TRIGGER_ID '
|| 'FROM $BACKUP.TRIGGERS_SAVED '
|| 'WHERE SEQ_NO=0 '
|| 'AND ( TRIGGER LIKE ''%"$REMOTE_TABSCHEMA".pruncntl_trigger%'''
|| 'OR TRIGGER LIKE ''%"$REMOTE_TABSCHEMA".PRUNCNTL_TRIGGER%'' ) '
|| ')#'
|| '-DROP NICKNAME $BACKUP.OEM_PROCS#'
|| '@CREATE NICKNAME $BACKUP.OEM_PROCS '
|| 'FOR $REMOTE_DB_SERVER."informix"."sysprocbody"#'
|| '@DELETE FROM $BACKUP.PROCS_SAVED#'
|| '@INSERT INTO $BACKUP.PROCS_SAVED '
|| 'SELECT PROCID,SEQNO,DATA '
|| 'FROM $BACKUP.OEM_PROCS '
|| 'WHERE DATAKEY=''T''#'
|| '@UPDATE $BACKUP.PROCS_SAVED '
|| 'SET PROC_ID=-1 '
|| 'WHERE PROC_ID=( '
|| 'SELECT PROC_ID '
|| 'FROM $BACKUP.PROCS_SAVED '
|| 'WHERE SEQ_NO=1 '
|| 'AND ( PROC LIKE ''%"$REMOTE_TABSCHEMA".pruncntl_proc%'''
|| 'OR PROC LIKE ''%"$REMOTE_TABSCHEMA".PRUNCNTL_PROC%'' ) '
|| ')#'
|| '@UPDATE $BACKUP.PROCS_SAVED '
|| 'SET PROC_ID=-2 '
|| 'WHERE PROC_ID=( '
|| 'SELECT PROC_ID '
|| 'FROM $BACKUP.PROCS_SAVED '
|| 'WHERE SEQ_NO=1 '
|| 'AND ( PROC LIKE ''%"$REMOTE_TABSCHEMA"%ibmsnap_synch_proc%'''
|| 'OR PROC LIKE ''%"$REMOTE_TABSCHEMA"%IBMSNAP_SYNCH_PROC%'' ) '
|| ')#'
|| '@COMMIT#'
where server_type='INFORMIX' and server_version='9.3';
update BACKUP.ibmsnap_hetero set triggers_v8= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc"#'
|| '@CREATE PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc" ( '
|| 'NEWSOURCE_OWNER CHAR(30), '
|| 'NEWSOURCE_TABLE CHAR(128), '
|| 'NEWPHYS_CHG_OWNER CHAR(30), '
|| 'NEWPHYS_CHG_TABLE CHAR(128) '
|| ') DEFINE MIN_SYNCHPOINT CHAR(10);'
|| 'SELECT MIN(SYNCHPOINT) '
|| 'INTO MIN_SYNCHPOINT '
|| 'FROM "$REMOTE_TABSCHEMA".ibmsnap_pruncntl '
|| 'WHERE SOURCE_OWNER=NEWSOURCE_OWNER '
|| 'AND SOURCE_TABLE=NEWSOURCE_TABLE;'
|| '${ select '
|| '''IF NEWPHYS_CHG_OWNER='''''' || rtrim( schema ) || '
|| ''''''' AND NEWPHYS_CHG_TABLE='''''' || rtrim( table ) || '
|| ''''''' THEN DELETE FROM "'' || rtrim( oem_schema ) || '
|| '''"."'' || rtrim( oem_table ) || '
|| '''" WHERE IBMSNAP_COMMITSEQ < MIN_SYNCHPOINT;END IF;'''
|| 'from BACKUP.ibmsnap_nicknames '
|| '} '
|| 'END PROCEDURE;#'
|| '@COMMIT#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."ibmsnap_synch_proc"#'
|| '@CREATE PROCEDURE "$REMOTE_TABSCHEMA"."ibmsnap_synch_proc"() '
|| 'DEFINE VARM INTEGER;'
|| 'DEFINE VARD INTEGER;DEFINE VARY INTEGER;DEFINE VARH CHAR(2);'
|| 'DEFINE VARMM CHAR(2);DEFINE VARSS CHAR(2);'
|| 'DEFINE VARDC CHAR(1);DEFINE VARHC CHAR(1);DEFINE VARMS CHAR(6);'
|| 'DEFINE VARYMC CHAR(1);DEFINE VARMMC CHAR(1);DEFINE VARSSC CHAR(1);'
|| 'DEFINE NEWSYNCH CHAR(10);'
|| 'SELECT MONTH(TODAY),YEAR(TODAY),DAY(TODAY),CURRENT HOUR TO HOUR, '
|| 'CURRENT MINUTE TO MINUTE,CURRENT SECOND TO SECOND, '
|| 'CURRENT FRACTION TO FRACTION(5) '
|| 'INTO VARM,VARY,VARD,VARH,VARMM,VARSS,VARMS '
|| 'FROM "$REMOTE_TABSCHEMA"."ibmsnap_seqtable";'
|| 'IF (VARY=2002 ) AND (VARM=6) THEN LET VARYMC=''0'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=7) THEN LET VARYMC=''1'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=8) THEN LET VARYMC=''2'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=9) THEN LET VARYMC=''3'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=10) THEN LET VARYMC=''4'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=11) THEN LET VARYMC=''5'';END IF;'
|| 'IF (VARY=2002 ) AND (VARM=12) THEN LET VARYMC=''6'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=1) THEN LET VARYMC=''7'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=2) THEN LET VARYMC=''8'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=3) THEN LET VARYMC=''9'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=4) THEN LET VARYMC=''A'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=5) THEN LET VARYMC=''B'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=6) THEN LET VARYMC=''C'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=7) THEN LET VARYMC=''D'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=8) THEN LET VARYMC=''E'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=9) THEN LET VARYMC=''F'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=10) THEN LET VARYMC=''G'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=11) THEN LET VARYMC=''H'';END IF;'
|| 'IF (VARY=2003 ) AND (VARM=12) THEN LET VARYMC=''I'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=1) THEN LET VARYMC=''J'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=2) THEN LET VARYMC=''K'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=3) THEN LET VARYMC=''L'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=4) THEN LET VARYMC=''M'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=5) THEN LET VARYMC=''N'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=6) THEN LET VARYMC=''O'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=7) THEN LET VARYMC=''P'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=8) THEN LET VARYMC=''Q'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=9) THEN LET VARYMC=''R'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=10) THEN LET VARYMC=''S'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=11) THEN LET VARYMC=''T'';END IF;'
|| 'IF (VARY=2004 ) AND (VARM=12) THEN LET VARYMC=''U'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=1) THEN LET VARYMC=''V'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=2) THEN LET VARYMC=''W'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=3) THEN LET VARYMC=''X'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=4) THEN LET VARYMC=''Y'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=5) THEN LET VARYMC=''Z'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=6) THEN LET VARYMC=''a'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=7) THEN LET VARYMC=''b'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=8) THEN LET VARYMC=''c'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=9) THEN LET VARYMC=''d'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=10) THEN LET VARYMC=''e'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=11) THEN LET VARYMC=''f'';END IF;'
|| 'IF (VARY=2005 ) AND (VARM=12) THEN LET VARYMC=''g'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=1) THEN LET VARYMC=''h'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=2) THEN LET VARYMC=''i'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=3) THEN LET VARYMC=''j'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=4) THEN LET VARYMC=''k'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=5) THEN LET VARYMC=''l'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=6) THEN LET VARYMC=''m'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=7) THEN LET VARYMC=''n'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=8) THEN LET VARYMC=''o'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=9) THEN LET VARYMC=''p'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=10) THEN LET VARYMC=''q'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=11) THEN LET VARYMC=''r'';END IF;'
|| 'IF (VARY=2006 ) AND (VARM=12) THEN LET VARYMC=''s'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=1) THEN LET VARYMC=''t'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''u'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''v'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''w'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''x'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''y'';END IF;'
|| 'IF (VARY=2007 ) AND (VARM=2) THEN LET VARYMC=''z'';END IF;'
|| 'IF (VARD=1) THEN LET VARDC=''A'';END IF;IF (VARD=2) THEN LET VARDC=''B'';END IF;'
|| 'IF (VARD=3) THEN LET VARDC=''C'';END IF;IF (VARD=4) THEN LET VARDC=''D'';END IF;'
|| 'IF (VARD=5) THEN LET VARDC=''E'';END IF;IF (VARD=6) THEN LET VARDC=''F'';END IF;'
|| 'IF (VARD=7) THEN LET VARDC=''G'';END IF;IF (VARD=8) THEN LET VARDC=''H'';END IF;'
|| 'IF (VARD=9) THEN LET VARDC=''I'';END IF;IF (VARD=10) THEN LET VARDC=''J'';END IF;'
|| 'IF (VARD=11) THEN LET VARDC=''K'';END IF;IF (VARD=12) THEN LET VARDC=''L'';END IF;'
|| 'IF (VARD=13) THEN LET VARDC=''M'';END IF;IF (VARD=14) THEN LET VARDC=''N'';END IF;'
|| 'IF (VARD=15) THEN LET VARDC=''O'';END IF;IF (VARD=16) THEN LET VARDC=''P'';END IF;'
|| 'IF (VARD=17) THEN LET VARDC=''Q'';END IF;IF (VARD=18) THEN LET VARDC=''R'';END IF;'
|| 'IF (VARD=19) THEN LET VARDC=''S'';END IF;IF (VARD=20) THEN LET VARDC=''T'';END IF;'
|| 'IF (VARD=21) THEN LET VARDC=''U'';END IF;IF (VARD=22) THEN LET VARDC=''V'';END IF;'
|| 'IF (VARD=23) THEN LET VARDC=''W'';END IF;IF (VARD=24) THEN LET VARDC=''X'';END IF;'
|| 'IF (VARD=25) THEN LET VARDC=''Y'';END IF;IF (VARD=26) THEN LET VARDC=''Z'';END IF;'
|| 'IF (VARD=27) THEN LET VARDC=''a'';END IF;IF (VARD=28) THEN LET VARDC=''b'';END IF;'
|| 'IF (VARD=29) THEN LET VARDC=''c'';END IF;IF (VARD=30) THEN LET VARDC=''d'';END IF;'
|| 'IF (VARD=31) THEN LET VARDC=''e'';END IF;IF (VARH=00) THEN LET VARHC=''A'';END IF;'
|| 'IF (VARH=01) THEN LET VARHC=''B'';END IF;IF (VARH=02) THEN LET VARHC=''C'';END IF;'
|| 'IF (VARH=03) THEN LET VARHC=''D'';END IF;IF (VARH=04) THEN LET VARHC=''E'';END IF;'
|| 'IF (VARH=05) THEN LET VARHC=''F'';END IF;IF (VARH=06) THEN LET VARHC=''G'';END IF;'
|| 'IF (VARH=07) THEN LET VARHC=''H'';END IF;IF (VARH=08) THEN LET VARHC=''I'';END IF;'
|| 'IF (VARH=09) THEN LET VARHC=''J'';END IF;IF (VARH=10) THEN LET VARHC=''K'';END IF;'
|| 'IF (VARH=11) THEN LET VARHC=''L'';END IF;IF (VARH=12) THEN LET VARHC=''M'';END IF;'
|| 'IF (VARH=13) THEN LET VARHC=''N'';END IF;IF (VARH=14) THEN LET VARHC=''O'';END IF;'
|| 'IF (VARH=15) THEN LET VARHC=''P'';END IF;IF (VARH=16) THEN LET VARHC=''Q'';END IF;'
|| 'IF (VARH=17) THEN LET VARHC=''R'';END IF;IF (VARH=18) THEN LET VARHC=''S'';END IF;'
|| 'IF (VARH=19) THEN LET VARHC=''T'';END IF;IF (VARH=20) THEN LET VARHC=''U'';END IF;'
|| 'IF (VARH=21) THEN LET VARHC=''V'';END IF;IF (VARH=22) THEN LET VARHC=''W'';END IF;'
|| 'IF (VARH=23) THEN LET VARHC=''X'';END IF;'
|| 'IF (VARMM=00) THEN LET VARMMC=''0'';END IF;'
|| 'IF (VARMM=01) THEN LET VARMMC=''1'';END IF;'
|| 'IF (VARMM=02) THEN LET VARMMC=''2'';END IF;'
|| 'IF (VARMM=03) THEN LET VARMMC=''3'';END IF;'
|| 'IF (VARMM=04) THEN LET VARMMC=''4'';END IF;'
|| 'IF (VARMM=05) THEN LET VARMMC=''5'';END IF;'
|| 'IF (VARMM=06) THEN LET VARMMC=''6'';END IF;'
|| 'IF (VARMM=07) THEN LET VARMMC=''7'';END IF;'
|| 'IF (VARMM=08) THEN LET VARMMC=''8'';END IF;'
|| 'IF (VARMM=09) THEN LET VARMMC=''9'';END IF;'
|| 'IF (VARMM=10) THEN LET VARMMC=''A'';END IF;'
|| 'IF (VARMM=11) THEN LET VARMMC=''B'';END IF;'
|| 'IF (VARMM=12) THEN LET VARMMC=''C'';END IF;'
|| 'IF (VARMM=13) THEN LET VARMMC=''D'';END IF;'
|| 'IF (VARMM=14) THEN LET VARMMC=''E'';END IF;'
|| 'IF (VARMM=15) THEN LET VARMMC=''F'';END IF;'
|| 'IF (VARMM=16) THEN LET VARMMC=''G'';END IF;'
|| 'IF (VARMM=17) THEN LET VARMMC=''H'';END IF;'
|| 'IF (VARMM=18) THEN LET VARMMC=''I'';END IF;'
|| 'IF (VARMM=19) THEN LET VARMMC=''J'';END IF;'
|| 'IF (VARMM=20) THEN LET VARMMC=''K'';END IF;'
|| 'IF (VARMM=21) THEN LET VARMMC=''L'';END IF;'
|| 'IF (VARMM=22) THEN LET VARMMC=''M'';END IF;'
|| 'IF (VARMM=23) THEN LET VARMMC=''N'';END IF;'
|| 'IF (VARMM=24) THEN LET VARMMC=''O'';END IF;'
|| 'IF (VARMM=25) THEN LET VARMMC=''P'';END IF;'
|| 'IF (VARMM=26) THEN LET VARMMC=''Q'';END IF;'
|| 'IF (VARMM=27) THEN LET VARMMC=''R'';END IF;'
|| 'IF (VARMM=28) THEN LET VARMMC=''S'';END IF;'
|| 'IF (VARMM=29) THEN LET VARMMC=''T'';END IF;'
|| 'IF (VARMM=30) THEN LET VARMMC=''U'';END IF;'
|| 'IF (VARMM=31) THEN LET VARMMC=''V'';END IF;'
|| 'IF (VARMM=32) THEN LET VARMMC=''W'';END IF;'
|| 'IF (VARMM=33) THEN LET VARMMC=''X'';END IF;'
|| 'IF (VARMM=34) THEN LET VARMMC=''Y'';END IF;'
|| 'IF (VARMM=35) THEN LET VARMMC=''Z'';END IF;'
|| 'IF (VARMM=36) THEN LET VARMMC=''a'';END IF;'
|| 'IF (VARMM=37) THEN LET VARMMC=''b'';END IF;'
|| 'IF (VARMM=38) THEN LET VARMMC=''c'';END IF;'
|| 'IF (VARMM=39) THEN LET VARMMC=''d'';END IF;'
|| 'IF (VARMM=40) THEN LET VARMMC=''e'';END IF;'
|| 'IF (VARMM=41) THEN LET VARMMC=''f'';END IF;'
|| 'IF (VARMM=42) THEN LET VARMMC=''g'';END IF;'
|| 'IF (VARMM=43) THEN LET VARMMC=''h'';END IF;'
|| 'IF (VARMM=44) THEN LET VARMMC=''i'';END IF;'
|| 'IF (VARMM=45) THEN LET VARMMC=''j'';END IF;'
|| 'IF (VARMM=46) THEN LET VARMMC=''k'';END IF;'
|| 'IF (VARMM=47) THEN LET VARMMC=''l'';END IF;'
|| 'IF (VARMM=48) THEN LET VARMMC=''m'';END IF;'
|| 'IF (VARMM=49) THEN LET VARMMC=''n'';END IF;'
|| 'IF (VARMM=50) THEN LET VARMMC=''o'';END IF;'
|| 'IF (VARMM=51) THEN LET VARMMC=''p'';END IF;'
|| 'IF (VARMM=52) THEN LET VARMMC=''q'';END IF;'
|| 'IF (VARMM=53) THEN LET VARMMC=''r'';END IF;'
|| 'IF (VARMM=54) THEN LET VARMMC=''s'';END IF;'
|| 'IF (VARMM=55) THEN LET VARMMC=''t'';END IF;'
|| 'IF (VARMM=56) THEN LET VARMMC=''u'';END IF;'
|| 'IF (VARMM=57) THEN LET VARMMC=''v'';END IF;'
|| 'IF (VARMM=58) THEN LET VARMMC=''w'';END IF;'
|| 'IF (VARMM=59) THEN LET VARMMC=''x'';END IF;'
|| 'IF (VARSS=00) THEN LET VARSSC=''0'';END IF;'
|| 'IF (VARSS=01) THEN LET VARSSC=''1'';END IF;'
|| 'IF (VARSS=02) THEN LET VARSSC=''2'';END IF;'
|| 'IF (VARSS=03) THEN LET VARSSC=''3'';END IF;'
|| 'IF (VARSS=04) THEN LET VARSSC=''4'';END IF;'
|| 'IF (VARSS=05) THEN LET VARSSC=''5'';END IF;'
|| 'IF (VARSS=06) THEN LET VARSSC=''6'';END IF;'
|| 'IF (VARSS=07) THEN LET VARSSC=''7'';END IF;'
|| 'IF (VARSS=08) THEN LET VARSSC=''8'';END IF;'
|| 'IF (VARSS=09) THEN LET VARSSC=''9'';END IF;'
|| 'IF (VARSS=10) THEN LET VARSSC=''A'';END IF;'
|| 'IF (VARSS=11) THEN LET VARSSC=''B'';END IF;'
|| 'IF (VARSS=12) THEN LET VARSSC=''C'';END IF;'
|| 'IF (VARSS=13) THEN LET VARSSC=''D'';END IF;'
|| 'IF (VARSS=14) THEN LET VARSSC=''E'';END IF;'
|| 'IF (VARSS=15) THEN LET VARSSC=''F'';END IF;'
|| 'IF (VARSS=16) THEN LET VARSSC=''G'';END IF;'
|| 'IF (VARSS=17) THEN LET VARSSC=''H'';END IF;'
|| 'IF (VARSS=18) THEN LET VARSSC=''I'';END IF;'
|| 'IF (VARSS=19) THEN LET VARSSC=''J'';END IF;'
|| 'IF (VARSS=20) THEN LET VARSSC=''K'';END IF;'
|| 'IF (VARSS=21) THEN LET VARSSC=''L'';END IF;'
|| 'IF (VARSS=22) THEN LET VARSSC=''M'';END IF;'
|| 'IF (VARSS=23) THEN LET VARSSC=''N'';END IF;'
|| 'IF (VARSS=24) THEN LET VARSSC=''O'';END IF;'
|| 'IF (VARSS=25) THEN LET VARSSC=''P'';END IF;'
|| 'IF (VARSS=26) THEN LET VARSSC=''Q'';END IF;'
|| 'IF (VARSS=27) THEN LET VARSSC=''R'';END IF;'
|| 'IF (VARSS=28) THEN LET VARSSC=''S'';END IF;'
|| 'IF (VARSS=29) THEN LET VARSSC=''T'';END IF;'
|| 'IF (VARSS=30) THEN LET VARSSC=''U'';END IF;'
|| 'IF (VARSS=31) THEN LET VARSSC=''V'';END IF;'
|| 'IF (VARSS=32) THEN LET VARSSC=''W'';END IF;'
|| 'IF (VARSS=33) THEN LET VARSSC=''X'';END IF;'
|| 'IF (VARSS=34) THEN LET VARSSC=''Y'';END IF;'
|| 'IF (VARSS=35) THEN LET VARSSC=''Z'';END IF;'
|| 'IF (VARSS=36) THEN LET VARSSC=''a'';END IF;'
|| 'IF (VARSS=37) THEN LET VARSSC=''b'';END IF;'
|| 'IF (VARSS=38) THEN LET VARSSC=''c'';END IF;'
|| 'IF (VARSS=39) THEN LET VARSSC=''d'';END IF;'
|| 'IF (VARSS=40) THEN LET VARSSC=''e'';END IF;'
|| 'IF (VARSS=41) THEN LET VARSSC=''f'';END IF;'
|| 'IF (VARSS=42) THEN LET VARSSC=''g'';END IF;'
|| 'IF (VARSS=43) THEN LET VARSSC=''h'';END IF;'
|| 'IF (VARSS=44) THEN LET VARSSC=''i'';END IF;'
|| 'IF (VARSS=45) THEN LET VARSSC=''j'';END IF;'
|| 'IF (VARSS=46) THEN LET VARSSC=''k'';END IF;'
|| 'IF (VARSS=47) THEN LET VARSSC=''l'';END IF;'
|| 'IF (VARSS=48) THEN LET VARSSC=''m'';END IF;'
|| 'IF (VARSS=49) THEN LET VARSSC=''n'';END IF;'
|| 'IF (VARSS=50) THEN LET VARSSC=''o'';END IF;'
|| 'IF (VARSS=51) THEN LET VARSSC=''p'';END IF;'
|| 'IF (VARSS=52) THEN LET VARSSC=''q'';END IF;'
|| 'IF (VARSS=53) THEN LET VARSSC=''r'';END IF;'
|| 'IF (VARSS=54) THEN LET VARSSC=''s'';END IF;'
|| 'IF (VARSS=55) THEN LET VARSSC=''t'';END IF;'
|| 'IF (VARSS=56) THEN LET VARSSC=''u'';END IF;'
|| 'IF (VARSS=57) THEN LET VARSSC=''v'';END IF;'
|| 'IF (VARSS=58) THEN LET VARSSC=''w'';END IF;'
|| 'IF (VARSS=59) THEN LET VARSSC=''x'';END IF;'
|| 'LET NEWSYNCH=TRIM(VARYMC)||TRIM(VARDC)||TRIM(VARHC)||TRIM(VARMMC)||TRIM(VARSSC)|| '
|| 'TRIM(LEADING ''.'' FROM VARMS);'
|| 'UPDATE "$REMOTE_TABSCHEMA"."ibmsnap_pruncntl" '
|| 'SET SYNCHPOINT=''0000000000'',SYNCHTIME=current year to fraction(5) '
|| 'WHERE SYNCHPOINT is null;'
|| 'UPDATE "$REMOTE_TABSCHEMA"."ibmsnap_register" '
|| 'SET (SYNCHPOINT,SYNCHTIME)= '
|| '(NEWSYNCH,CURRENT YEAR TO FRACTION(5));'
|| 'END PROCEDURE;#'
|| '@COMMIT#'
|| '-DROP TRIGGER "$REMOTE_TABSCHEMA"."pruncntl_trigger"#'
|| '@CREATE TRIGGER "$REMOTE_TABSCHEMA"."pruncntl_trigger" '
|| 'UPDATE OF "synchpoint" ON "$REMOTE_TABSCHEMA"."ibmsnap_pruncntl" '
|| 'REFERENCING NEW AS NEW OLD AS OLD '
|| 'FOR EACH ROW ( '
|| 'EXECUTE PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc" ( '
|| 'NEW."source_owner", '
|| 'NEW."source_table", '
|| 'NEW."phys_change_owner", '
|| 'NEW."phys_change_table" '
|| ') '
|| ');'
|| '${ select '''' from BACKUP.ibmsnap_nicknames }#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='INFORMIX' and server_version='9.3';
update BACKUP.ibmsnap_hetero set triggers_restore= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."pruncntl_proc"#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."PRUNCNTL_PROC"#'
|| '@ ${ select proc '
|| 'from $BACKUP .procs_saved '
|| 'where proc_id=-1 }#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."ibmsnap_synch_proc"#'
|| '-DROP PROCEDURE "$REMOTE_TABSCHEMA"."IBMSNAP_SYNCH_PROC"#'
|| '@ ${ select proc '
|| 'from $BACKUP .procs_saved '
|| 'where proc_id=-2 }#'
|| '-DROP TRIGGER "$REMOTE_TABSCHEMA"."pruncntl_trigger"#'
|| '-DROP TRIGGER "$REMOTE_TABSCHEMA"."PRUNCNTL_TRIGGER"#'
|| '@ ${ select trigger '
|| 'from $BACKUP .triggers_saved '
|| 'where trigger_id=-1 }#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='INFORMIX' and server_version='9.3';
 
update BACKUP.ibmsnap_hetero set triggers_save= 
   ''
|| '-SET SERVER OPTION TWO_PHASE_COMMIT TO ''N'' FOR SERVER $REMOTE_DB_SERVER#'
|| '@SET PASSTHRU $REMOTE_DB_SERVER#'
|| 'COMMIT#'
|| '-DROP VIEW $REMOTE_TABSCHEMA.OEM_TRIGGERS#'
|| '@CREATE VIEW $REMOTE_TABSCHEMA.OEM_TRIGGERS '
|| 'AS SELECT * '
|| 'FROM USER_TRIGGERS#'
|| 'COMMIT#'
|| '@SET PASSTHRU RESET#'
|| 'COMMIT#'
|| '-DROP NICKNAME $BACKUP.OEM_TRIGGERS#'
|| '@CREATE NICKNAME $BACKUP.OEM_TRIGGERS '
|| 'FOR $REMOTE_DB_SERVER.$REMOTE_TABSCHEMA.OEM_TRIGGERS#'
|| '@DELETE FROM $BACKUP.TRIGGERS_SAVED#'
|| '@INSERT INTO $BACKUP.TRIGGERS_SAVED '
|| 'SELECT 0,0,''CREATE TRIGGER '' || DESCRIPTION || TRIGGER_BODY '
|| 'FROM $BACKUP.OEM_TRIGGERS '
|| 'WHERE TABLE_NAME '
|| 'LIKE ''IBMSNAP%''#'
|| '@UPDATE $BACKUP.TRIGGERS_SAVED '
|| 'SET TRIGGER_ID=-1 '
|| 'WHERE TRIGGER LIKE ''%pruncntl_trigger%'''
|| 'OR TRIGGER LIKE ''%PRUNCNTL_TRIGGER%''#'
|| 'COMMIT#'
where server_type='ORACLE'
and ucase( wrapper )='SQLNET';
update BACKUP.ibmsnap_hetero set triggers_v8= 
   ''
|| '@SET PASSTHRU $REMOTE_DB_SERVER#'
|| '@COMMIT#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER '
|| 'AFTER INSERT '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_SIGNAL '
|| 'FOR EACH ROW '
|| 'BEGIN '
|| 'UPDATE $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'SET SYNCHPOINT=LPAD(TO_CHAR($REMOTE_TABSCHEMA.SGENERATOR001.NEXTVAL),20,''0''), '
|| 'SYNCHTIME=SYSDATE '
|| 'WHERE RTRIM( MAP_ID )=RTRIM( :NEW.SIGNAL_INPUT_IN ) '
|| 'AND SYNCHPOINT=HEXTORAW(''00000000000000000000'');'
|| 'END;#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER '
|| 'AFTER UPDATE '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'DECLARE MIN_SYNCHPOINT RAW(10);'
|| 'CURSOR C1 IS '
|| 'SELECT DISTINCT SOURCE_OWNER,SOURCE_TABLE,PHYS_CHANGE_OWNER,PHYS_CHANGE_TABLE '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'WHERE SYNCHPOINT IS NOT NULL;'
|| 'C1_REC C1%ROWTYPE;'
|| 'MUTATING EXCEPTION;'
|| 'PRAGMA EXCEPTION_INIT(MUTATING,-4091);'
|| 'BEGIN '
|| 'OPEN C1;'
|| 'LOOP FETCH C1 INTO C1_REC;'
|| 'EXIT WHEN C1%NOTFOUND;'
|| 'BEGIN '
|| 'SELECT MIN(SYNCHPOINT) INTO MIN_SYNCHPOINT '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'WHERE SOURCE_OWNER=C1_REC.SOURCE_OWNER '
|| 'AND SOURCE_TABLE=C1_REC.SOURCE_TABLE;'
|| 'EXCEPTION WHEN NO_DATA_FOUND THEN NULL;'
|| 'END;'
|| 'BEGIN '
|| 'IF C1_REC.PHYS_CHANGE_OWNER IS NULL AND C1_REC.PHYS_CHANGE_TABLE IS NULL THEN '
|| 'C1_REC.PHYS_CHANGE_TABLE:=NULL;'
|| '${ select '
|| '''ELSIF C1_REC.PHYS_CHANGE_OWNER='''''' || rtrim( schema ) || '
|| ''''''' AND C1_REC.PHYS_CHANGE_TABLE='''''' || rtrim( table ) || '
|| ''''''' THEN DELETE FROM '' || rtrim( oem_schema ) || '
|| '''.'' || rtrim( oem_table ) || '
|| ''' WHERE IBMSNAP_COMMITSEQ < MIN_SYNCHPOINT;'''
|| 'from BACKUP.ibmsnap_nicknames '
|| '} '
|| 'END IF;'
|| 'END;'
|| 'END LOOP;'
|| 'CLOSE C1;'
|| 'EXCEPTION WHEN MUTATING THEN NULL;'
|| 'END;#'
|| '-DROP INDEX $REMOTE_TABSCHEMA.IBMSNAP_SIGNALX#'
|| 'COMMIT#'
|| 'SET PASSTHRU RESET#'
|| 'COMMIT#'
where server_type='ORACLE'
and ucase( wrapper )='SQLNET';
update BACKUP.ibmsnap_hetero set triggers_restore= 
   ''
|| '-SET SERVER OPTION TWO_PHASE_COMMIT TO ''N'' FOR SERVER $REMOTE_DB_SERVER#'
|| 'COMMIT#'
|| '@SET PASSTHRU $REMOTE_DB_SERVER#'
|| 'COMMIT#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.PRUNSET_TRIGGER#'
|| '@${ select trigger '
|| 'from $BACKUP .triggers_saved '
|| 'where trigger_id=-1 }#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='ORACLE'
and ucase( wrapper )='SQLNET';
 
update BACKUP.ibmsnap_hetero set triggers_save= 
   ''
|| '+${ select '
|| '''ASN5031W Oracle NET8-wrapper users must manually save pruncntl_trigger before running asnmig8 migration.'''
|| 'from $BACKUP.ibmsnap_hetero }#'
|| '-SET PASSTHRU RESET#'
|| 'COMMIT#'
where server_type='ORACLE'
and ucase( wrapper )='NET8';
update BACKUP.ibmsnap_hetero set triggers_v8= 
   ''
|| '@SET PASSTHRU $REMOTE_DB_SERVER#'
|| '@COMMIT#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER '
|| 'AFTER INSERT '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_SIGNAL '
|| 'FOR EACH ROW '
|| 'BEGIN '
|| 'UPDATE $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'SET SYNCHPOINT=LPAD(TO_CHAR($REMOTE_TABSCHEMA.SGENERATOR001.NEXTVAL),20,''0''), '
|| 'SYNCHTIME=SYSDATE '
|| 'WHERE RTRIM( MAP_ID )=RTRIM( :NEW.SIGNAL_INPUT_IN ) '
|| 'AND SYNCHPOINT=HEXTORAW(''00000000000000000000'');'
|| 'END;#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER '
|| 'AFTER UPDATE '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'DECLARE MIN_SYNCHPOINT RAW(10);'
|| 'CURSOR C1 IS '
|| 'SELECT DISTINCT SOURCE_OWNER,SOURCE_TABLE,PHYS_CHANGE_OWNER,PHYS_CHANGE_TABLE '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'WHERE SYNCHPOINT IS NOT NULL;'
|| 'C1_REC C1%ROWTYPE;'
|| 'MUTATING EXCEPTION;'
|| 'PRAGMA EXCEPTION_INIT(MUTATING,-4091);'
|| 'BEGIN '
|| 'OPEN C1;'
|| 'LOOP FETCH C1 INTO C1_REC;'
|| 'EXIT WHEN C1%NOTFOUND;'
|| 'BEGIN '
|| 'SELECT MIN(SYNCHPOINT) INTO MIN_SYNCHPOINT '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'WHERE SOURCE_OWNER=C1_REC.SOURCE_OWNER '
|| 'AND SOURCE_TABLE=C1_REC.SOURCE_TABLE;'
|| 'EXCEPTION WHEN NO_DATA_FOUND THEN NULL;'
|| 'END;'
|| 'BEGIN '
|| 'IF C1_REC.PHYS_CHANGE_OWNER IS NULL AND C1_REC.PHYS_CHANGE_TABLE IS NULL THEN '
|| 'C1_REC.PHYS_CHANGE_TABLE:=NULL;'
|| '${ select '
|| '''ELSIF C1_REC.PHYS_CHANGE_OWNER='''''' || rtrim( schema ) || '
|| ''''''' AND C1_REC.PHYS_CHANGE_TABLE='''''' || rtrim( table ) || '
|| ''''''' THEN DELETE FROM '' || rtrim( oem_schema ) || '
|| '''.'' || rtrim( oem_table ) || '
|| ''' WHERE IBMSNAP_COMMITSEQ < MIN_SYNCHPOINT;'''
|| 'from BACKUP.ibmsnap_nicknames '
|| '} '
|| 'END IF;'
|| 'END;'
|| 'END LOOP;'
|| 'CLOSE C1;'
|| 'EXCEPTION WHEN MUTATING THEN NULL;'
|| 'END;#'
|| '-DROP INDEX $REMOTE_TABSCHEMA.IBMSNAP_SIGNALX#'
|| 'COMMIT#'
|| 'SET PASSTHRU RESET#'
|| 'COMMIT#'
where server_type='ORACLE'
and ucase( wrapper )='NET8';
update BACKUP.ibmsnap_hetero set triggers_restore= 
   ''
|| '+${ select '
|| '''ASN5032W Oracle NET8-wrapper users must manually restore pruncntl_trigger after running asnmig8 fallback.'''
|| 'from $BACKUP.ibmsnap_hetero }#'
|| '-SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='ORACLE'
and ucase( wrapper )='NET8';
 
update BACKUP.ibmsnap_hetero set triggers_save= 
   ''
|| '-DROP NICKNAME $BACKUP.OEM_TRIGGERS#'
|| '@CREATE NICKNAME $BACKUP.OEM_TRIGGERS '
|| 'FOR "$REMOTE_DB_SERVER"."dbo"."syscomments"#'
|| '@DELETE FROM $BACKUP.TRIGGERS_SAVED#'
|| '@INSERT INTO $BACKUP.TRIGGERS_SAVED '
|| 'SELECT ID,COLID,TEXT '
|| 'FROM $BACKUP.OEM_TRIGGERS#'
|| '@UPDATE $BACKUP.TRIGGERS_SAVED '
|| 'SET TRIGGER_ID=-1 '
|| 'WHERE TRIGGER_ID=( '
|| 'SELECT TRIGGER_ID '
|| 'FROM $BACKUP.TRIGGERS_SAVED '
|| 'WHERE SEQ_NO=1 '
|| 'AND TRIGGER LIKE ''%$REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER%'' )#'
where server_type='SYBASE';
update BACKUP.ibmsnap_hetero set triggers_v8= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'ADD TIMESTAMP NULL#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_PRUNE_SET '
|| 'ADD TIMESTAMP NULL#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_REGISTER '
|| 'ADD TIMESTAMP NULL#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_SIGNAL '
|| 'ADD TIMESTAMP NULL#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_SIGNAL '
|| 'FOR INSERT AS '
|| 'DECLARE @NEWSYNCH BINARY(10) '
|| 'BEGIN '
|| 'SELECT @NEWSYNCH=@@DBTS '
|| 'UPDATE $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'SET SYNCHPOINT=@NEWSYNCH,SYNCHTIME=GETDATE( ) '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL P,inserted I '
|| 'WHERE I.SIGNAL_INPUT_IN=P.MAP_ID '
|| 'AND P.SYNCHPOINT=CONVERT( BINARY( 10 ),0 ) '
|| 'END#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'FOR UPDATE AS '
|| 'DECLARE @MIN_SYNCHPOINT BINARY(10) '
|| 'DECLARE C1 CURSOR '
|| 'FOR SELECT DISTINCT '
|| 'SOURCE_OWNER,SOURCE_TABLE,PHYS_CHANGE_OWNER,PHYS_CHANGE_TABLE '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'WHERE SYNCHPOINT IS NOT NULL '
|| 'DECLARE @SOURCE_OWNER CHAR(30),@SOURCE_TABLE CHAR(128), '
|| '@PHYS_CHANGE_OWNER CHAR(30),@PHYS_CHANGE_TABLE CHAR(128) '
|| 'BEGIN '
|| 'OPEN C1 '
|| 'FETCH C1 '
|| 'INTO @SOURCE_OWNER,@SOURCE_TABLE, '
|| '@PHYS_CHANGE_OWNER,@PHYS_CHANGE_TABLE '
|| 'WHILE ( @@SQLSTATUS=0 ) '
|| 'BEGIN '
|| 'BEGIN '
|| 'SELECT @MIN_SYNCHPOINT=MIN( SYNCHPOINT ) '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'WHERE SOURCE_OWNER=@SOURCE_OWNER '
|| 'AND SOURCE_TABLE=@SOURCE_TABLE '
|| 'END '
|| 'BEGIN '
|| '${ '
|| 'select '
|| '''IF @PHYS_CHANGE_OWNER='''''' || rtrim( schema ) || '''''' '' || '
|| '''AND @PHYS_CHANGE_TABLE='''''' || rtrim( table ) || '''''' '' || '
|| ''' BEGIN DELETE FROM '' || rtrim( oem_schema ) || ''.'' || '
|| 'rtrim( oem_table ) || '
|| ''' WHERE IBMSNAP_COMMITSEQ < @MIN_SYNCHPOINT END '''
|| 'from BACKUP.ibmsnap_nicknames '
|| '} '
|| 'END '
|| 'FETCH C1 '
|| 'INTO @SOURCE_OWNER,@SOURCE_TABLE, '
|| '@PHYS_CHANGE_OWNER,@PHYS_CHANGE_TABLE '
|| 'END '
|| 'CLOSE C1 '
|| 'DEALLOCATE CURSOR C1 '
|| 'END#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='SYBASE';
update BACKUP.ibmsnap_hetero set triggers_restore= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER#'
|| '@${ select trigger '
|| 'from $BACKUP .triggers_saved '
|| 'where trigger_id=-1 '
|| 'order by seq_no '
|| '}#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='SYBASE';
 
update BACKUP.ibmsnap_hetero set triggers_save= 
   ''
|| '-DROP NICKNAME $BACKUP.OEM_TRIGGERS#'
|| '@CREATE NICKNAME $BACKUP.OEM_TRIGGERS '
|| 'FOR "$REMOTE_DB_SERVER"."dbo"."syscomments"#'
|| '@DELETE FROM $BACKUP.TRIGGERS_SAVED#'
|| '@INSERT INTO $BACKUP.TRIGGERS_SAVED '
|| 'SELECT ID,COLID,TEXT '
|| 'FROM $BACKUP.OEM_TRIGGERS#'
|| '@UPDATE $BACKUP.TRIGGERS_SAVED '
|| 'SET TRIGGER_ID=-1 '
|| 'WHERE TRIGGER_ID=( '
|| 'SELECT TRIGGER_ID '
|| 'FROM $BACKUP.TRIGGERS_SAVED '
|| 'WHERE SEQ_NO=1 '
|| 'AND TRIGGER LIKE ''%$REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER%'' )#'
where server_type='MSSQLSERVER' and server_version='2000';
update BACKUP.ibmsnap_hetero set triggers_v8= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'ADD TIMESTAMP NULL#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_PRUNE_SET '
|| 'ADD TIMESTAMP NULL#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_REGISTER '
|| 'ADD TIMESTAMP NULL#'
|| '@ALTER TABLE $REMOTE_TABSCHEMA.IBMSNAP_SIGNAL '
|| 'ADD TIMESTAMP NULL#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.SIGNAL_TRIGGER '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_SIGNAL '
|| 'FOR INSERT AS '
|| 'DECLARE @NEWSYNCH BINARY(10) '
|| 'BEGIN '
|| 'SELECT @NEWSYNCH=@@DBTS '
|| 'UPDATE $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'SET SYNCHPOINT=@NEWSYNCH,SYNCHTIME=GETDATE( ) '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL P,inserted I '
|| 'WHERE I.SIGNAL_INPUT_IN=P.MAP_ID '
|| 'AND P.SYNCHPOINT=CONVERT( BINARY( 10 ),0 ) '
|| 'END#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER#'
|| '@CREATE TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER '
|| 'ON $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'FOR UPDATE AS '
|| 'DECLARE @MIN_SYNCHPOINT BINARY(10) '
|| 'DECLARE C1 CURSOR '
|| 'FOR SELECT DISTINCT '
|| 'a.SOURCE_OWNER,a.SOURCE_TABLE,a.PHYS_CHANGE_OWNER,a.PHYS_CHANGE_TABLE '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL a,deleted d '
|| 'WHERE a.SYNCHPOINT IS NOT NULL '
|| 'AND d.SYNCHPOINT <> 0x00000000000000000000 '
|| 'DECLARE @SOURCE_OWNER CHAR(30),@SOURCE_TABLE CHAR(128), '
|| '@PHYS_CHANGE_OWNER CHAR(30),@PHYS_CHANGE_TABLE CHAR(128) '
|| 'BEGIN '
|| 'OPEN C1 '
|| 'FETCH C1 '
|| 'INTO @SOURCE_OWNER,@SOURCE_TABLE, '
|| '@PHYS_CHANGE_OWNER,@PHYS_CHANGE_TABLE '
|| 'WHILE ( @@FETCH_STATUS=0 ) '
|| 'BEGIN '
|| 'BEGIN '
|| 'SELECT @MIN_SYNCHPOINT=MIN( SYNCHPOINT ) '
|| 'FROM $REMOTE_TABSCHEMA.IBMSNAP_PRUNCNTL '
|| 'WHERE SOURCE_OWNER=@SOURCE_OWNER '
|| 'AND SOURCE_TABLE=@SOURCE_TABLE '
|| 'END '
|| 'BEGIN '
|| '${ '
|| 'select '
|| '''IF @PHYS_CHANGE_OWNER='''''' || rtrim( schema ) || '''''' '' || '
|| '''AND @PHYS_CHANGE_TABLE='''''' || rtrim( table ) || '''''' '' || '
|| ''' BEGIN DELETE FROM '' || rtrim( oem_schema ) || ''.'' || '
|| 'rtrim( oem_table ) || '
|| ''' WHERE IBMSNAP_COMMITSEQ < @MIN_SYNCHPOINT END '''
|| 'from BACKUP.ibmsnap_nicknames '
|| '} '
|| 'END '
|| 'FETCH C1 '
|| 'INTO @SOURCE_OWNER,@SOURCE_TABLE, '
|| '@PHYS_CHANGE_OWNER,@PHYS_CHANGE_TABLE '
|| 'END '
|| 'CLOSE C1 '
|| 'DEALLOCATE C1 '
|| 'END#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='MSSQLSERVER' and server_version='2000';
update BACKUP.ibmsnap_hetero set triggers_restore= 
   ''
|| '@SET PASSTHRU "$REMOTE_DB_SERVER"#'
|| '@COMMIT#'
|| '-DROP TRIGGER $REMOTE_TABSCHEMA.PRUNCNTL_TRIGGER#'
|| '@${ select trigger '
|| 'from $BACKUP .triggers_saved '
|| 'where trigger_id=-1 '
|| 'order by seq_no '
|| '}#'
|| '@COMMIT#'
|| '@SET PASSTHRU RESET#'
|| '@COMMIT#'
where server_type='MSSQLSERVER' and server_version='2000';
 
-- Test ibmsnap_hetero for readiness to migrate:
-- (Null assignment triggers error if create new trigger script not defined)

update BACKUP.ibmsnap_hetero set 
   triggers_v8 = 
   case when length(triggers_v8) > 0 THEN triggers_v8 else null end ; 
 
-- Insert 'SOURCE' row -- with VERSION -- last to end step 1.

INSERT INTO BACKUP.IBMSNAP_MIGRATION VALUES (
   'SOURCE ', 1, '-', '-', '1.51', CURRENT TIMESTAMP,
'in BACKUPTS'
) ;
 
-- END OF Replication Migration V8 Step 1 --
