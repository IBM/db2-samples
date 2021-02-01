--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows the size of each Synopsis table created for each Column Organized Table
 */

CREATE OR REPLACE VIEW DB_SYNOPSIS_SIZE AS
SELECT
     T.TABSCHEMA
,    T.TABNAME
,    DATA_L_KB
,    SYN_L_KB
,    BIGINT(((MIN(1012, (COLCOUNT * 2) + 2 )) * EXTENTSIZE * DATASLICES * PAGESIZE ::BIGINT * 4 /* assume 4 insert ranges */ ) /1024) AS MIN_SYN_KB
,    COLCOUNT
,    EXTENTSIZE
,    DATASLICES
,    PAGESIZE
,    CARD
,    PCTPAGESSAVED
,    DATA_P_KB
,    SYN_P_KB
,    INDEX_L_KB
,    INDEX_P_KB
,    TBSPACE
,    SYN_TABNAME
FROM
(
    SELECT
        T.*
    ,   COALESCE(   -- Get Synopsis logical table size for BLU tables
            (SELECT SUM(DATA_OBJECT_L_SIZE + INDEX_OBJECT_L_SIZE + LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE)
                FROM
                    TABLE(ADMIN_GET_TAB_INFO(T.SYN_TABSCHEMA, T.SYN_TABNAME)) S
                WHERE
                    S.TABSCHEMA = T.SYN_TABSCHEMA
                AND S.TABNAME   = T.SYN_TABNAME
                AND T.TABLEORG = 'C'
        ),0) AS SYN_L_KB
    ,   COALESCE(   -- Get Synopsis physical table size for BLU tables
            (SELECT SUM(DATA_OBJECT_P_SIZE + INDEX_OBJECT_P_SIZE + LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE)
                FROM
                    TABLE(ADMIN_GET_TAB_INFO(T.SYN_TABSCHEMA, T.SYN_TABNAME)) S
                WHERE
                    S.TABSCHEMA = T.SYN_TABSCHEMA
                AND S.TABNAME   = T.SYN_TABNAME
                AND T.TABLEORG = 'C'
        ),0) AS SYN_P_KB
        FROM
    (
        SELECT
            T.TABSCHEMA
        ,   T.TABNAME
        ,   MAX(T.COLCOUNT) AS COLCOUNT
        ,   MAX(T.CARD)     AS CARD
        ,   MAX(T.PCTPAGESSAVED)  AS PCTPAGESSAVED
        ,   MAX(T.TBSPACE)  AS TBSPACE
        ,   MAX(T.TABLEORG) AS TABLEORG
        ,   COUNT(DBPARTITIONNUM)   AS DATASLICES
        ,   SUM(DATA_OBJECT_L_SIZE +                       LONG_OBJECT_L_SIZE + LOB_OBJECT_L_SIZE + XML_OBJECT_L_SIZE + COL_OBJECT_L_SIZE) AS DATA_L_KB
        ,   SUM(                      INDEX_OBJECT_L_SIZE                                                                                ) AS INDEX_L_KB
        ,   SUM(DATA_OBJECT_P_SIZE +                       LONG_OBJECT_P_SIZE + LOB_OBJECT_P_SIZE + XML_OBJECT_P_SIZE + COL_OBJECT_P_SIZE) AS DATA_P_KB
        ,   SUM(                      INDEX_OBJECT_P_SIZE                                                                                ) AS INDEX_P_KB
        ,   SUM(RECLAIMABLE_SPACE)  AS RECLAIMABLE_KB
        ,   'SYSIBM'  AS SYN_TABSCHEMA
        ,   COALESCE(   (SELECT D.TABNAME FROM SYSCAT.TABDEP D WHERE T.TABSCHEMA = D.BSCHEMA AND T.TABNAME = D.BNAME AND D.DTYPE = '7')
                        ,'00DUMMY00'
                    ) AS SYN_TABNAME
        FROM
            SYSCAT.TABLES  T
        JOIN   
            TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
        ON  T.TYPE IN ('T','S')
        AND NOT (T.TABSCHEMA = 'SYSIBM' AND SUBSTR(T.PROPERTY,21,1) = 'Y')  
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
    )
        T
) T
JOIN SYSCAT.TABLESPACES USING (TBSPACE )
