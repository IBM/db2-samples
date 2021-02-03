--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Tables, Views, Nicknames, MQTs and other objects from the SYSCAT.TABLES catalog view 
 */

CREATE OR REPLACE VIEW DB_TABLES AS
SELECT
     TABSCHEMA
,    TABNAME
,       CASE TYPE
            WHEN 'T' THEN 'TABLE'
            WHEN 'V' THEN 'VIEW'
            WHEN 'S' THEN 'MQT'
            WHEN 'G' THEN 'CGTT'
            WHEN 'N' THEN 'NNAME'   -- Nickname
            WHEN 'A' THEN 'ALIAS'
            ELSE TYPE
        END AS TABLE_TYPE
/*DB_BLU*/,       CASE WHEN TYPE IN ('T','S','G') THEN 
/*DB_BLU*/            CASE TABLEORG WHEN 'C' THEN 'COL' WHEN 'R' THEN 'ROW' END ELSE '' 
/*DB_BLU*/         END   AS ORG
,       CARD
,       CASE WHEN FPAGES > 0
             THEN FPAGES * (SELECT PAGESIZE FROM SYSCAT.TABLESPACES TB WHERE T.TBSPACE = TB.TBSPACE)
        ELSE 0 END                                  AS DATA_BYTES /*! Size of data  pages allocated to this object. Excludes index pages */
,       PCTPAGESSAVED  AS PCT_PAGES_SAVED                  /*! Percentage pages saved by ROW or COLUMN compression. PCTPAGESSAVED */
,       AVGROWSIZE     AS AVG_ROW_SIZE                     /* AVGROWLEN */
,       INT(100.0 * NPAGES / FPAGES)                AS FILL       /*  The percentage of pages allocated that actually have rows. NPAGES / FPAGES */
,       SUBSTR(CREATE_TIME,1,19)                    AS CREATE_DATETIME
/*DB_09_7_0_0*/,       LASTUSED
,       COALESCE(RTRIM(BASE_TABSCHEMA) || '.' || RTRIM(BASE_TABNAME),'') || COALESCE(REMARKS,'') AS ALIAS_OR_COMMENT
FROM
    SYSCAT.TABLES    T
    