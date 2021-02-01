--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows the data skew of database partitioned tables. Only shows data for tables touched since the last Db2 restart
 */

CREATE OR REPLACE VIEW DB_TABLE_QUICK_SKEW AS
SELECT
    TABSCHEMA
,   TABNAME
,   M.MAX_TABLE_BYTES / (1024*1024) AS MAX_TABLE_MB
,   M.MIN_TABLE_BYTES / (1024*1024) AS MIN_TABLE_MB
,   DECIMAL((((MAX_TABLE_BYTES - AVG_TABLE_BYTES) * MEMBERS) / (1024*1024)),17,3) AS WASTED_MB
,   M.SKEW
,   M.LARGEST_MEMBER
--,   TBSPACE
--,   D.DISTRIBUTION_KEY
--,   T.CARD
--,   T.PCTPAGESSAVED                                     AS PCT_COMPRESSED
--,   D.MAX_DIST_COLCARD
--,   T.OWNER
--,   T.LASTUSED
--,   T.CREATE_TIME
FROM
(   SELECT  
        TABSCHEMA
    ,   TABNAME
    ,   COUNT(*)                                            AS MEMBERS
    ,   MAX(TABLE_BYTES)                                    AS MAX_TABLE_BYTES
    ,   MIN(TABLE_BYTES)                                    AS MIN_TABLE_BYTES
    ,   MAX(TABLE_BYTES) - AVG(TABLE_BYTES)::BIGINT         AS SKEWED_BYTES
    ,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(TABLE_BYTES)),0)/ NULLIF(MAX(DECFLOAT(TABLE_BYTES)),0))*100,5,2) END    AS SKEW
    ,   MAX(CASE WHEN MEMBER_ASC_RANK  = 1 THEN MEMBER END) AS SMALLEST_MEMBER
    ,   MAX(CASE WHEN MEMBER_DESC_RANK = 1 THEN MEMBER END) AS LARGEST_MEMBER
    ,   AVG(TABLE_BYTES)                                    AS AVG_TABLE_BYTES
    ,   SUM(TABLE_BYTES)                                    AS SUM_TABLE_BYTES
    ,   MAX(INDEX_BYTES)                                    AS MAX_INDEX_BYTES
    ,   MIN(INDEX_BYTES)                                    AS MIN_INDEX_BYTES
    FROM
    (   SELECT 
            TABSCHEMA
        ,   TABNAME
        ,   MEMBER
        ,   SUM(TABLE_OBJECT_L_BYTES)                 AS TABLE_BYTES
        ,   SUM(INDEX_OBJECT_L_BYTES)                 AS INDEX_BYTES
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(TABLE_OBJECT_L_BYTES) ASC)  AS MEMBER_ASC_RANK
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(TABLE_OBJECT_L_BYTES) DESC) AS MEMBER_DESC_RANK
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
        ) M
    GROUP BY
            TABSCHEMA
    ,       TABNAME
) M
