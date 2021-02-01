--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows the data skew of database partitioned tables.
 */

CREATE OR REPLACE VIEW DB_TABLE_SKEW AS
SELECT
    TABSCHEMA
,   TABNAME
,   M.MAX_DATA_BYTES / (1024*1024) AS MAX_DATA_MB
,   M.MIN_DATA_BYTES / (1024*1024) AS MIN_DATA_MB
--,   M.AVG_DATA_BYTES / (1024*1024) AS AVG_TABLE_MB
,   DECIMAL((((MAX_DATA_BYTES - AVG_DATA_BYTES) * MEMBERS) / (1024*1024)),17,1) AS WASTED_MB
,   M.SKEW
,   M.LARGEST_MEMBER
,   M.DATA_BYTES / (1024*1024)  AS DATA_MB
,   M.INDEX_BYTES / (1024*1024) AS INDEX_MB
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
    ,   MAX(DATA_BYTES)                                     AS MAX_DATA_BYTES
    ,   MIN(DATA_BYTES)                                     AS MIN_DATA_BYTES
    ,   AVG(DATA_BYTES)                                     AS AVG_DATA_BYTES
    ,   SUM(DATA_BYTES)                                     AS DATA_BYTES    
    ,   MAX(DATA_BYTES) - AVG(DATA_BYTES)::BIGINT           AS SKEWED_BYTES
    ,   CASE WHEN COUNT(*) > 1 THEN DECIMAL((1 - NULLIF(AVG(DECFLOAT(DATA_BYTES)),0)/ NULLIF(MAX(DECFLOAT(DATA_BYTES)),0))*100,5,2) END    AS SKEW
    ,   MAX(CASE WHEN MEMBER_ASC_RANK  = 1 THEN MEMBER END) AS SMALLEST_MEMBER
    ,   MAX(CASE WHEN MEMBER_DESC_RANK = 1 THEN MEMBER END) AS LARGEST_MEMBER
    ,   MAX(INDEX_BYTES)                                    AS MAX_INDEX_BYTES
    ,   MIN(INDEX_BYTES)                                    AS MIN_INDEX_BYTES
    ,   SUM(INDEX_BYTES)                                    AS INDEX_BYTES
    FROM
    (   SELECT 
            TABSCHEMA
        ,   TABNAME
        ,   MEMBER
        ,   SUM(DATA_L_KB)  * 1024                AS DATA_BYTES
        ,   SUM(INDEX_L_KB) * 1024                AS INDEX_BYTES
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(DATA_L_KB) ASC)  AS MEMBER_ASC_RANK
        ,   ROW_NUMBER() OVER (PARTITION BY TABSCHEMA, TABNAME ORDER BY SUM(DATA_L_KB) DESC) AS MEMBER_DESC_RANK
        FROM   
        (
        SELECT
            T.TABSCHEMA
        ,   T.TABNAME
        ,   I.DBPARTITIONNUM AS MEMBER
        ,   MAX(T.TABLEORG) AS TABLEORG
        ,   SUM(DATA_OBJECT_L_SIZE +                       LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE) AS DATA_L_KB
        ,   SUM(                      INDEX_OBJECT_L_SIZE                                                                                ) AS INDEX_L_KB
        ,   SUM(DATA_OBJECT_P_SIZE +                       LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE) AS DATA_P_KB
        ,   SUM(                      INDEX_OBJECT_P_SIZE                                                                                ) AS INDEX_P_KB
        ,   SUM(RECLAIMABLE_SPACE)  AS RECLAIMABLE_KB
        FROM
            SYSCAT.TABLES  T
        JOIN   
            TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
        ON  
            T.TABSCHEMA = I.TABSCHEMA
        AND T.TABNAME   = I.TABNAME
        AND T.TYPE IN ('T','S')
        AND NOT (T.TABSCHEMA = 'SYSIBM' AND SUBSTR(T.PROPERTY,21,1) = 'Y')      -- ignore synopsis tables
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
        ,   I.DBPARTITIONNUM
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

