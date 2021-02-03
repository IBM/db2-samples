--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns an accurate size of each table using ADMIN_GET_TAB_INFO(). The view can be slow to return on large systems if you don't filter
 */

CREATE OR REPLACE VIEW DB_TABLE_SIZE AS
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   MAX(DATA_L_KB + INDEX_L_KB + SYN_L_KB, DATA_P_KB + INDEX_P_KB + SYN_P_KB) AS SIZE_KB
,   CASE WHEN  DATA_L_KB + INDEX_L_KB + SYN_L_KB > DATA_P_KB + INDEX_P_KB + SYN_P_KB THEN 'LOGICAL'
          WHEN DATA_L_KB + INDEX_L_KB + SYN_L_KB < DATA_P_KB + INDEX_P_KB + SYN_P_KB THEN 'PHYSICAL'
          ELSE 'LOG = PHYS' END AS SIZE_SOURCE
,   DATA_L_KB
,   DATA_P_KB
,   INDEX_L_KB
,   INDEX_P_KB
,   SYN_L_KB
,   SYN_P_KB
,   RECLAIMABLE_KB
,   PCTPAGESSAVED
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
        ,   MAX(T.TABLEORG)      AS TABLEORG
        ,   MAX(T.PCTPAGESSAVED) AS PCTPAGESSAVED
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
        AND I.TABSCHEMA = T.TABSCHEMA
        AND I.TABNAME   = T.TABNAME
        GROUP BY
            T.TABSCHEMA
        ,   T.TABNAME
    )
        T
) T