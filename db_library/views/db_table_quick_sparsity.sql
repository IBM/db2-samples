--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns a simplistic estimate of how the size of each table compares to what you might expect given the column encoding rates
 * 
 * In otherwords, this view can help spot tables that have had many random UPDATEs or DELETEs 
 *    where extents of pages can't be reclaimed as not *all* rows in those extents have been deleted
 * It is very much only an estimate, and for various reasons is not particually accurate.
 * Still it can be a usefull, quick indication of tables that might benifit from re-building or reinserting.
 * 
 * Very loosly based on detectSparseBluTables.sh  from https://www.ibm.com/support/pages/node/305221
 * 
 */
   
CREATE OR REPLACE VIEW DB_TABLE_QUICK_SPARSITY AS
SELECT
    ROW_NUMBER() OVER( ORDER BY COL_SIZE_GB - EST_MEM_SIZE_GB DESC NULLS LAST)  AS RANK
,   QUANTIZE( ( ( COL_SIZE_GB - EST_MEM_SIZE_GB ) / COL_SIZE_GB ) * 100, 0.1 ) AS SPARSE_PCT
,   COL_SIZE_GB - EST_MEM_SIZE_GB       AS DELTA_GB  
,   *
FROM
(   SELECT
        T.TABSCHEMA
    ,   T.TABNAME
    ,   QUANTIZE( ( AVGENCODEDCOLLEN * CARD ) / POWER(2,30) ,.00)     AS EST_MEM_SIZE_GB
    ,   QUANTIZE( ( COALESCE(COL_OBJECT_L_PAGES, T.FPAGES)* TS.PAGESIZE::DECFLOAT) / POWER(2,30),.00)  AS COL_SIZE_GB
    ,   QUANTIZE(AVGENCODEDCOLLEN,0)            AS EST_MEM_BYTES
    ,   RAW_LEN_BYTES 
    ,   ROWS_DELETED
    ,   QUANTIZE(  COALESCE(COL_OBJECT_L_PAGES, T.FPAGES)* TS.PAGESIZE::DECFLOAT / DECFLOAT(NULLIF(CARD,0)),0) AS BYTES_PER_ROW
    ,   T.NPAGES
    ,   T.FPAGES
    ,   T.PCTPAGESSAVED
    ,   AVG_PCTENCODED
    ,   MIN_PCTENCODED
    ,   T.CARD
    --    ,   DECIMAL((1 - DECFLOAT(NULLIF(ST.AVG_TABLE_BYTES,0))/ NULLIF(ST.MAX_TABLE_BYTES,0))*100,5,2)     AS SKEW
    --,   RECLAIMABLE_SPACE*1000 as RECLAIMABLE
    FROM
        SYSCAT.TABLES  T
    JOIN
    (   SELECT
            TABSCHEMA
        ,   TABNAME
        ,   DECIMAL(SUM(CASE WHEN TYPENAME NOT IN ('CLOB','LOB','DBCLOB') THEN AVGENCODEDCOLLEN END),9,3) AS AVGENCODEDCOLLEN -- Ignore spurious values for LOBs. They are not encoded in BLU.
        ,   DECIMAL(SUM(CASE WHEN AVGCOLLEN > 0 THEN AVGCOLLEN ELSE LENGTH END)) AS RAW_LEN_BYTES
        ,   AVG(PCTENCODED)         AS AVG_PCTENCODED
        ,   MIN(PCTENCODED)         AS MIN_PCTENCODED
        FROM
            SYSCAT.COLUMNS C
        WHERE
            AVGENCODEDCOLLEN > 0
        GROUP BY
            C.TABSCHEMA
        ,   C.TABNAME
    )
        USING ( TABSCHEMA, TABNAME )
    LEFT OUTER JOIN
            SYSCAT.TABLESPACES              TS
    ON
        T.TBSPACEID = TS.TBSPACEID      
    LEFT JOIN
    (   SELECT
            T.TABSCHEMA
        ,   T.TABNAME
        ,   SUM(M.COL_OBJECT_L_PAGES)   AS COL_OBJECT_L_PAGES
        ,   SUM(ROWS_DELETED)           AS ROWS_DELETED
        FROM
            SYSCAT.TABLES  T
        ,   TABLE(MON_GET_TABLE(T.TABSCHEMA, T.TABNAME, -2)) M
        WHERE
            T.TABSCHEMA = M.TABSCHEMA
        AND T.TABNAME   = M.TABNAME
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
    ) M
        USING ( TABSCHEMA, TABNAME )
WHERE
    TABSCHEMA NOT LIKE 'SYS%'
AND T.TYPE IN ('T','S')
)
