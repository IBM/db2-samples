--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Check table sparisty by comparing row counts in base tables vs sum of tuple span ranges from their synopsis tables
 *
 * When Db2 UPDATEs or DELETEs from a ORGANIZE BY COLUMN table, it marks the exiting row as deleted
 *   and if it was a INSERT, writes a new row to the "end of the" tables
 * 
 * This can cause "sparsity" issue as Db2 can (currenlty) only RECLAIM EXTENTs on a COL table
 *   if *all* rows in an extent have been marked as deleted.
 * 
 * This is fine if you are doing mass deleted based on some date range (and if the data in the table was ordered on insert)
 *  or if you are doing mass updated of whole ranges of rows.
 * But if you do more random updates or deletes, you can end up with many extents with only a few non-deleted rows
 * 
 * 
 * The script below uses the fact that Db2 only removes synopsis rows when all references tuples have been RECLAIMed
 * By compating the TSN Range from the Synopsis table to the acutal table row count, you can have some idea on how 
 *   much sparsity a table has.
 *
 */

--DROP TABLE     DB_TSN_SPAN
--TRUNCATE TABLE DB_TSN_SPAN IMMEDIATE

CREATE TABLE DB_TSN_SPAN (
    TABSCHEMA    VARCHAR(128) NOT NULL
,   TABNAME      VARCHAR(128) NOT NULL
,   ROW_COUNT    BIGINT NOT NULL
,   SYN_ROWS     BIGINT NOT NULL
,   TSN_SPAN     BIGINT NOT NULL
--,   PRIMARY KEY (TABSCHEMA, TABNAME ) ENFORCED
) DISTRIBUTE ON ( TABSCHEMA, TABNAME )
@
CREATE OR REPLACE VIEW DB_TABLE_SPARCITY AS
SELECT
    T.*
,   TSN_SPAN  / NULLIF(SYN_ROWS,0)   AS AVG_TSN_SPAN
,   ROW_COUNT / NULLIF(SYN_ROWS,0)   AS ROWS_PER_SYN_ROW 
,   MAX(TSN_SPAN - ROW_COUNT,0)      AS ROWS_NOT_RECLAIMED
,   QUANTIZE(100 * (MAX(TSN_SPAN - ROW_COUNT,0)) / NULLIF(ROW_COUNT,0)::DECFLOAT,0.01)  AS PCT_DELETED 
FROM
    DB_TSN_SPAN T
@
    
BEGIN
    DECLARE NOT_ALLOWED    CONDITION FOR SQLSTATE '57016'; -- Skip LOAD pending tables etc. I.e. SQL0668N Operation not allowed 
    DECLARE UNDEFINED_NAME CONDITION FOR SQLSTATE '42704'; -- Skip tables that no longer exist/not commited
    DECLARE CONTINUE HANDLER FOR NOT_ALLOWED, UNDEFINED_NAME BEGIN END;
    ---
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            VARCHAR(      'INSERT INTO DB_TSN_SPAN'
            || CHR(10) || ' SELECT'
            || CHR(10) || '   ''' || T.TABSCHEMA || ''' AS TABSCHEMA'
            || CHR(10) || ',  ''' || T.TABNAME   || ''' AS TABNAME'
            || CHR(10) || ',  ROW_COUNT'
            || CHR(10) || ',  SYN_ROWS'
            || CHR(10) || ',  TSN_SPAN' 
            || CHR(10) || 'FROM (SELECT COUNT(*) SYN_ROWS, SUM(TSNMAX-TSNMIN+1) AS TSN_SPAN FROM SYSIBM."' || S.TABNAME || '") AS S'
            || CHR(10) || ',    (SELECT COUNT(*) ROW_COUNT                                        FROM "' || RTRIM(T.TABSCHEMA) || '"."' || T.TABNAME || '") AS T'
            || CHR(10) || 'WHERE SYN_ROWS > 0'
            || CHR(10) || 'WITH UR'
            ,4000)  AS INSERT_STMT
        ,   'DELETE FROM DB_TSN_SPAN WHERE TABSCHEMA = ''' || T.TABSCHEMA || ''' AND TABNAME = ''' || T.TABNAME   || '''' AS DELETE_STMT
        FROM
            SYSCAT.TABLES T
        ,   SYSCAT.TABDEP D
        ,   SYSCAT.TABLES S
        WHERE T.TABSCHEMA = D.BSCHEMA
        AND   T.TABNAME   = D.BNAME
        AND   D.DTYPE     = '7'
        AND   S.TABSCHEMA = D.TABSCHEMA
        AND   S.TABNAME   = D.TABNAME
        AND  (T.TABSCHEMA, T.TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM DB_TSN_SPAN)
        AND   T.TABSCHEMA IN ('SSSS')      -- add your own filters here if you wish
        AND   T.TABNAME   IN ('TTTT')      -- add your own filters here if you wish
        ORDER BY
            T.TABSCHEMA, T.TABNAME
        WITH UR
    DO
--          EXECUTE IMMEDIATE C.DELETE_STMT;
          EXECUTE IMMEDIATE C.INSERT_STMT;
          COMMIT;
    END FOR;
END
@

SELECT * FROM DB_TABLE_SPARCITY ORDER BY PCT_DELETED DESC
@
