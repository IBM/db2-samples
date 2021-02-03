--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Force a dictionary to be built on small tables that have not had enough rows to trigger Automatic Dictionary Creation
 * 
 * Calls ADMIN_MOVE_TABLE with the LOAD option to force tables with rows, but without dictonaries to be rebuilt
 * 
 */

DROP  TABLE DB_ADMIN_MOVE_TABLE_RESULT
@

CREATE TABLE DB_ADMIN_MOVE_TABLE_RESULT (
    TABSCHEMA   VARCHAR(128 OCTETS) NOT NULL
,   TABNAME     VARCHAR(128 OCTETS) NOT NULL
,   KEY         VARCHAR(32 OCTETS)  NOT NULL-- Name of the attribute.
,   VALUE       CLOB(10M  OCTETS)       --Value of the attribute.
,   PRIMARY KEY (TABSCHEMA, TABNAME, KEY) NOT ENFORCED
)
@

TRUNCATE TABLE DB_ADMIN_MOVE_TABLE_RESULT
@

BEGIN
    DECLARE    TYPE VARCHAR_ARRAY AS VARCHAR(128)ARRAY[];
    DECLARE SCHEMAS VARCHAR_ARRAY;
    DECLARE TABLES  VARCHAR_ARRAY;
    DECLARE i INTEGER DEFAULT 1;
    --
    DECLARE SQLSTATE CHAR(5);
    DECLARE V_KEY         VARCHAR(32 OCTETS) ;
    DECLARE V_VALUE       CLOB(10M  OCTETS)  ;
    DECLARE V1 RESULT_SET_LOCATOR   VARYING;
    --
    DECLARE LOAD_PENDING CONDITION FOR SQLSTATE '57016';    -- Skip LOAD pending tables 
    DECLARE NOT_ALLOWED  CONDITION FOR SQLSTATE '57007';    -- Skip Set Integrity Pending  tables  I.e. SQL0668N Operation not allowed
    DECLARE UNDEFINED_NAME CONDITION FOR SQLSTATE '42704';  -- Skip tables that no longer exist/not commited
    DECLARE CONTINUE HANDLER FOR LOAD_PENDING, NOT_ALLOWED, UNDEFINED_NAME BEGIN END;
    --
    SELECT
        ARRAY_AGG(T.TABSCHEMA ORDER BY T.TABSCHEMA, T.TABNAME)
     ,  ARRAY_AGG(T.TABNAME   ORDER BY T.TABSCHEMA, T.TABNAME)
            INTO  SCHEMAS, TABLES
    --SELECT T.TABSCHEMA, T.TABNAME
    FROM
        SYSCAT.TABLES  T
    ,   TABLE(ADMIN_GET_TAB_DICTIONARY_INFO( T.TABSCHEMA, T.TABNAME)) AS I
    WHERE TYPE IN ('T','S') 
    AND T.TABSCHEMA NOT LIKE 'SYS%'
    AND T.TABLEORG = 'C'  
    AND T.CARD > 0                  -- Only consider tables with rows (according to runstats)
    AND I.SIZE = 0                  -- and tables with no dictonary  (needs Db2 11.5.4)
    WITH UR
    ;
    WHILE i <= CARDINALITY(TABLES)
    DO
        CALL SYSPROC.ADMIN_MOVE_TABLE( SCHEMAS[i], TABLES[i], '','','','','','','','ALLOW_READ_ACCESS,COPY_USE_LOAD','MOVE'); 
        --
        ASSOCIATE RESULT SET LOCATOR (V1) WITH PROCEDURE SYSPROC.ADMIN_MOVE_TABLE;
        ALLOCATE C1 CURSOR FOR RESULT SET V1;
        --
        L1: LOOP
            FETCH C1                                   INTO V_KEY, V_VALUE ;
            IF SQLSTATE<>'00000' THEN LEAVE L1; END IF;
            INSERT INTO DB_ADMIN_MOVE_TABLE_RESULT VALUES ( SCHEMAS[i], TABLES[i], V_KEY, V_VALUE);
        END LOOP L1;
        CLOSE C1;
        -- 
        COMMIT;
        SET i = i + 1;
    END WHILE;
    COMMIT;
END
@

SELECT * FROM DB_ADMIN_MOVE_TABLE_RESULT
