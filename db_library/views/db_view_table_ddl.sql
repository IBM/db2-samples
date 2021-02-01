--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns CREATE TABLE DDL that corresponds to the column definitions of VIEWs
 */

CREATE OR REPLACE VIEW DB_VIEW_TABLE_DDL AS
SELECT
    TABSCHEMA  AS VIEWSCHEMA
,   TABNAME    AS VIEWNAME
,   'CREATE TABLE "' || TABSCHEMA || '"."' || TABNAME || '" (' 
    || LISTAGG(CAST(CHR(10) AS VARCHAR(32000 OCTETS)) || CASE WHEN COL_SEQ > 0 THEN ',   ' ELSE '    ' END 
          || '"' || COLNAME || '"'
          || CASE WHEN LENGTH(COLNAME) < 40 THEN REPEAT(' ',40-LENGTH(COLNAME)) ELSE ' ' END
          || DATATYPE_DDL
          ) WITHIN GROUP (ORDER BY COLNO) 
    || CHR(10) || ')' AS DDL
,   CUMULATIVE_LENGTH/32000    AS DDL_SPLIT_SEQ
FROM
(   SELECT C.*
       ,    SUM(50 + LENGTH(DATATYPE_DDL) )
                 OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) AS CUMULATIVE_LENGTH
       FROM
       (
            SELECT
                TABSCHEMA
            ,   TABNAME
            ,   COLNAME
            ,   COLNO
            ,   CASE
                WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                     || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                     || CASE WHEN C.CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END                WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                THEN TYPENAME || '(' || LENGTH || ')'  
                WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                THEN TYPENAME
                WHEN TYPENAME IN ('TIMESTAMP')
                THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                ELSE TYPENAME END 
            || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        AS DATATYPE_DDL
            ,    COLNO                                                                    AS COL_SEQ
        FROM
            SYSCAT.COLUMNS C JOIN SYSCAT.TABLES USING ( TABSCHEMA, TABNAME ) 
        WHERE   TYPE IN ('V')
       ) C
      )
GROUP BY
    TABSCHEMA
,   TABNAME
,   CUMULATIVE_LENGTH/32000
