--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Write reorg check output for tables to a table. Also, run REORGs for tables recommended
 * 
 * Db2 provides a REORGCHK_IX_STATS procedure that returns a dynamic result set.
 * 
 * This code writes that data to a persistent table which is much easier to work with
 */


DROP  TABLE DB_REORGCHK_TB_STATS
@

CREATE TABLE DB_REORGCHK_TB_STATS (
    TABSCHEMA           VARCHAR(128) NOT NULL
,   TABNAME             VARCHAR(128) NOT NULL
,   DATAPARTITIONNAME   VARCHAR(128) NOT NULL
,   CARD                BIGINT   NOT NULL
,   OVERFLOW            BIGINT   NOT NULL
,   NPAGES              BIGINT   NOT NULL
,   FPAGES              BIGINT   NOT NULL
,   ACTIVE_BLOCKS       BIGINT   NOT NULL
,   TSIZE               BIGINT   NOT NULL
,   F1                  INTEGER  NOT NULL
,   F2                  INTEGER  NOT NULL
,   F3                  INTEGER  NOT NULL
,   REORG               CHAR(3)  NOT NULL
,   PRIMARY KEY (TABSCHEMA, TABNAME, DATAPARTITIONNAME) ENFORCED
)
@

TRUNCATE TABLE DB_REORGCHK_TB_STATS IMMEDIATE
@

BEGIN
    DECLARE SQLSTATE CHAR(5);
    DECLARE V_TABSCHEMA           VARCHAR(128);
    DECLARE V_TABNAME             VARCHAR(128);
    DECLARE V_DATAPARTITIONNAME   VARCHAR(128);
    DECLARE V_CARD                BIGINT;
    DECLARE V_OVERFLOW            BIGINT;
    DECLARE V_NPAGES              BIGINT;
    DECLARE V_FPAGES              BIGINT;
    DECLARE V_ACTIVE_BLOCKS       BIGINT;
    DECLARE V_TSIZE               BIGINT;
    DECLARE V_F1                  INTEGER;
    DECLARE V_F2                  INTEGER;
    DECLARE V_F3                  INTEGER;
    DECLARE V_REORG               CHAR(3);
    DECLARE V1 RESULT_SET_LOCATOR VARYING;
    --
--    CALL SYSPROC.REORGCHK_TB_STATS('S', 'PAUL');  -- run for schema PAUL
--    CALL SYSPROC.REORGCHK_TB_STATS('T', 'ALL');  -- run for ALL tables
--    CALL SYSPROC.REORGCHK_TB_STATS('T', 'USER');  -- run for ALL USER tables
    CALL SYSPROC.REORGCHK_TB_STATS('T', 'SYSTEM');  -- run for ALL SYSTEM tables
    ASSOCIATE RESULT SET LOCATOR (V1) WITH PROCEDURE SYSPROC.REORGCHK_TB_STATS;
    ALLOCATE C1 CURSOR FOR RESULT SET V1;
    --
    L1: LOOP
        FETCH C1                             INTO V_TABSCHEMA, V_TABNAME, V_DATAPARTITIONNAME, V_CARD, V_OVERFLOW, V_NPAGES, V_FPAGES, V_ACTIVE_BLOCKS, V_TSIZE, V_F1, V_F2, V_F3, V_REORG;
        IF SQLSTATE<>'00000' THEN LEAVE L1; END IF;        
        INSERT INTO DB_REORGCHK_TB_STATS VALUES ( V_TABSCHEMA, V_TABNAME, V_DATAPARTITIONNAME, V_CARD, V_OVERFLOW, V_NPAGES, V_FPAGES, V_ACTIVE_BLOCKS, V_TSIZE, V_F1, V_F2, V_F3, V_REORG) ;
    END LOOP L1;
  CLOSE C1;
END
@

SELECT 'CALL ADMIN_CMD(''REORG TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'')' AS REORG_CMD
,   *
FROM DB_REORGCHK_TB_STATS 
WHERE REORG <> '---'
@

/*
Table statistics:

F1: 100 * OVERFLOW / CARD < 5
F2: 100 * (Effective Space Utilization of Data Pages) > 70
F3: 100 * (Required Pages / Total Pages) > 80

 */

DROP   TABLE DB_REORG_LOG IF EXISTS
@

CREATE TABLE DB_REORG_LOG
(
    TS  TIMESTAMP NOT NULL
,   REORG_TYPE VARCHAR(16) NOT NULL
,   TABSCHEMA VARCHAR(128) NOT NULL
,   TABNAME   VARCHAR(128) NOT NULL
)
@

-- Now run the reorgs
--   Note that we use an ARRARY rather than a CURSOR as ADMIN_CMD REORG closes our cursors and  we get
--   SQL Error [24501]: The cursor specified in a FETCH statement or CLOSE statement is not open or a cursor variable in a cursor scalar function reference is not open
BEGIN
    DECLARE    TYPE VARCHAR_ARRAY AS VARCHAR(128)ARRAY[];
    DECLARE SCHEMAS VARCHAR_ARRAY;
    DECLARE TABLES  VARCHAR_ARRAY;
    DECLARE i INTEGER DEFAULT 1;
    --
    DECLARE LOAD_PENDING CONDITION FOR SQLSTATE '57016';    -- Skip LOAD pending tables 
    DECLARE NOT_ALLOWED  CONDITION FOR SQLSTATE '57007';    -- Skip Set Integrity Pending  tables  I.e. SQL0668N Operation not allowed
    --    DECLARE UNDEFINED_NAME CONDITION FOR SQLSTATE '42704';  -- Skip tables that no longer exist/not commited
    DECLARE CONTINUE HANDLER FOR LOAD_PENDING, NOT_ALLOWED BEGIN END;
    --
    SELECT
        ARRAY_AGG(TABSCHEMA ORDER BY TABSCHEMA, TABNAME)
     ,  ARRAY_AGG(TABNAME   ORDER BY TABSCHEMA, TABNAME)
            INTO  SCHEMAS, TABLES
    FROM
        DB_REORGCHK_TB_STATS
    WHERE
        REORG <> '---'
    WITH UR;
    WHILE i <= CARDINALITY(TABLES)
    DO
          CALL ADMIN_CMD('REORG TABLE "' || SCHEMAS[i] || '"."' || TABLES[i] || '"' );
          INSERT INTO DB_REORG_LOG VALUES (CURRENT_TIMESTAMP, 'TABLE', SCHEMAS[1], TABLES[i]);
          CALL ADMIN_CMD('RUNSTATS ON TABLE "' || SCHEMAS[i] || '"."' || TABLES[i] || '" WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL');
          SET i = i + 1;
    END WHILE;
END
@

