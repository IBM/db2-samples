--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns the size of each table. For tables not touched since the last Db2 restart, the size is an estimate based on catalog statistics
 */

CREATE OR REPLACE VIEW DB_TABLE_QUICK_SIZE AS
WITH MON AS
(   SELECT  
        TABSCHEMA
    ,   TABNAME
    ,   COUNT(*)                                            AS MEMBERS
    ,   SUM(TABLE_BYTES)                                    AS TABLE_BYTES
    ,   SUM(INDEX_BYTES)                                    AS INDEX_BYTES
    ,   MAX(TABLE_BYTES)                                    AS MAX_TABLE_BYTES
    ,   AVG(TABLE_BYTES)                                    AS AVG_TABLE_BYTES
    FROM
    (   SELECT 
            TABSCHEMA
        ,   TABNAME
        ,   MEMBER
        ,   SUM(TABLE_OBJECT_L_BYTES)                 AS TABLE_BYTES
        ,   SUM(INDEX_OBJECT_L_BYTES)                 AS INDEX_BYTES
--        ,   SUM(ROWS_READ)                            AS ROWS_READ
--        ,   SUM(ROWS_INSERTED)                        AS ROWS_INSERTED
--        ,   SUM(ROWS_UPDATED)                         AS ROWS_UPDATED
--        ,   SUM(ROWS_DELETED)                         AS ROWS_DELETED
        FROM   
        (
            SELECT  
                M.*
            , ( COALESCE( DATA_OBJECT_L_PAGES,0)
              + COALESCE(  COL_OBJECT_L_PAGES,0)
              + COALESCE( LONG_OBJECT_L_PAGES,0)
              + COALESCE(  LOB_OBJECT_L_PAGES,0)
              + COALESCE(  XDA_OBJECT_L_PAGES,0)) * TS.PAGESIZE  AS TABLE_OBJECT_L_BYTES
            --
            ,   COALESCE(INDEX_OBJECT_L_PAGES,0)  * TS.PAGESIZE  AS INDEX_OBJECT_L_BYTES 
            FROM
                TABLE(MON_GET_TABLE(DEFAULT, DEFAULT, -2)) AS M
            INNER JOIN
                SYSCAT.TABLESPACES TS ON M.TBSP_ID = TS.TBSPACEID
        ) M
        GROUP BY
                TABSCHEMA
        ,       TABNAME
        ,       MEMBER
        ) ST
    GROUP BY
            TABSCHEMA
    ,       TABNAME
)
SELECT
    SMALLINT(RANK() OVER(ORDER BY COALESCE(ST.TABLE_BYTES, T.NPAGES      * TS.PAGESIZE) DESC NULLS LAST)) AS RANK
,   RTRIM(T.TABSCHEMA)                                  AS TABSCHEMA
,   T.TABNAME
,   T.COLCOUNT                                          AS COLS
,   T.CARD                                                              AS CARD
--,   T.OWNER                                             AS OWNER
--,   T.TBSPACE                                           AS TBSPACE
,   CASE WHEN ST.TABLE_BYTES IS NOT NULL THEN 'L_PAGES' ELSE 'STATS' END                            AS SIZE_SOURCE
,   INTEGER( ROUND((COALESCE(ST.TABLE_BYTES, T.NPAGES      * TS.PAGESIZE)) / DECFLOAT(1048576)))    AS DATA_MB
,   INTEGER( ROUND((COALESCE(ST.INDEX_BYTES, IS.INDEX_PAGES * TS.PAGESIZE)) / DECFLOAT(1048576)))   AS INDEX_MB
,   COALESCE(INTEGER( ROUND(S.TABLE_BYTES / DECFLOAT(1048576))),0)                                  AS SYN_MB
,   DECIMAL((S.TABLE_BYTES / DECFLOAT(ST.TABLE_BYTES))*100,7,2)                                     AS SYN_PCT
,   DECIMAL((1 - DECFLOAT(NULLIF(ST.AVG_TABLE_BYTES,0))/ NULLIF(ST.MAX_TABLE_BYTES,0))*100,5,2)     AS SKEW
,   QUANTIZE((COALESCE(ST.TABLE_BYTES, T.NPAGES      * TS.PAGESIZE) / DECFLOAT(NULLIF(CARD,0))),0.01)     AS BYTES_PER_ROW
,   QUANTIZE(MEM_LEN,0.01)                                                                          AS MEM_LEN
,   T.PCTPAGESSAVED
,   RTRIM(DECIMAL(100/NULLIF(DECFLOAT(100)-NULLIF(PCTPAGESSAVED,-1),0),5,2)) || ':1'                AS RATIO
,   C.AVG_PCTENCODED                                                                                AS PCTENCODED
,   C.AVG_ENCODED_LEN_BYTES                                                                         AS AVGENCODEDLEN
,   CASE T.TABLEORG WHEN 'C' THEN 'COLUMN' WHEN 'R' THEN 'ROW' END      AS TABLE_ORG
,   T.STATS_TIME
,   T.LASTUSED                                                          AS LAST_USED_DATE
,   DATE(T.CREATE_TIME)                                                 AS CREATE_DATE
--,   COALESCE(ST.ROWS_READ,-1)                           AS ROWS_READ
--,   COALESCE(ST.ROWS_INSERTED,-1)                       AS ROWS_INSERTED
--,   COALESCE(ST.ROWS_UPDATED,-1)                        AS ROWS_UPDATED
--,   COALESCE(ST.ROWS_DELETED,-1)                        AS ROWS_DELETED
FROM    SYSCAT.TABLES                   T
JOIN    (
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   SUM(CASE WHEN AVGENCODEDCOLLEN >= 0 THEN AVGENCODEDCOLLEN END)              AS MEM_LEN 
    ,   DECIMAL(AVG(PCTENCODED),5,2)       AS AVG_PCTENCODED 
    ,   DECIMAL(AVG(CASE WHEN TYPENAME NOT IN ('CLOB','LOB','DBCLOB') THEN AVGENCODEDCOLLEN END),9,3) AS AVG_ENCODED_LEN_BYTES -- Ignore spurious values for LOBs. They are not encoded in BLU.
    FROM
        SYSCAT.COLUMNS              
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ) AS C
ON  
     T.TABSCHEMA = C.TABSCHEMA
AND  T.TABNAME   = C.TABNAME      
LEFT OUTER JOIN
        SYSCAT.TABLESPACES              TS
ON
    T.TBSPACEID = TS.TBSPACEID      
LEFT OUTER JOIN
        MON           ST
ON      
    T.TABSCHEMA = ST.TABSCHEMA
AND T.TABNAME   = ST.TABNAME
LEFT OUTER JOIN
    SYSCAT.TABDEP   SD
ON
    T.TABSCHEMA = SD.BSCHEMA
AND T.TABNAME   = SD.BNAME
AND               SD.DTYPE = '7'
LEFT OUTER JOIN
    MON           S --Synonpsis tables
ON
    SD.TABSCHEMA = S.TABSCHEMA
AND SD.TABNAME   = S.TABNAME
LEFT OUTER JOIN
        (SELECT 
                TABSCHEMA
        ,       TABNAME
        ,       SUM(NLEAF) * 1.3                        AS INDEX_PAGES
        FROM    SYSCAT.INDEXES
        WHERE
                NLEAF >= 0
        GROUP BY
                TABSCHEMA
        ,       TABNAME
        )
            IS
ON      T.TABSCHEMA = IS.TABSCHEMA
AND     T.TABNAME   = IS.TABNAME
WHERE
        T.TYPE      NOT IN ('A','N','V','W')
AND NOT (T.TABSCHEMA = 'SYSIBM' AND T.TABNAME LIKE 'SYN%')