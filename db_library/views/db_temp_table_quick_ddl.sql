--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Simple DDL generator for DB2 Declared Global Temp Tables
 * 
 * Note that it does NOT include the following as they are not avaiable from the ADMIN table function
 * - DISTRIBUTE ON
 * - ORGANIZE BY
 * -  String Units
 * 
 * NOTE that if your table DDL will end up being more than 32 thousand bytes, the DDL will be split over more than 1 row. 
 *    This is to avoid the length of the generate DDL breaking the max length of a VARCHAR used by LISTAGG 
 */

CREATE OR REPLACE VIEW DB_TEMP_TABLE_QUICK_DDL AS
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   C.DDL_SPLIT_SEQ + 1                   AS DDL_LINE_NO
,   CASE WHEN DDL_SPLIT_SEQ = 0 THEN      -- Top 
         'DECLARE GLOBAL TEMPORARY TABLE "' ||  TABSCHEMA || '"."' || TABNAME || '"' || CHR(10) || '(' || CHR(10) 
    ELSE '' END
    || COLUMNS || CHR(10)                 -- Middle
    || ')'                                -- End
      AS DDL
FROM
    TABLE(ADMIN_GET_TEMP_TABLES(NULL,NULL,NULL)) T
JOIN 
(
  SELECT
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000    AS DDL_SPLIT_SEQ
      ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS))
                  || CASE WHEN COL_SEQ > 1 THEN CHR(10) || ',   ' ELSE '    ' END 
                  || '"' || COLNAME || '"'
                  || CASE WHEN LENGTH(COLNAME) < 40 THEN REPEAT(' ',40-LENGTH(COLNAME)) ELSE ' ' END
                  || DATATYPE_DDL
                  || CASE WHEN DEFAULT_VALUE_DDL <> '' THEN ' ' || DEFAULT_VALUE_DDL ELSE '' END 
                  ) WITHIN GROUP (ORDER BY COLNO) AS COLUMNS
      FROM
          (SELECT C.*
           ,    SUM(50 + LENGTH(DATATYPE_DDL) + LENGTH(DEFAULT_VALUE_DDL) )
                     OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) AS CUMULATIVE_LENGTH
           FROM
           (
                SELECT
                    TABSCHEMA
                ,   TABNAME
                ,   COLNAME
                ,   COLNO
                ,   CASE
                        WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPH', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                        THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' WHEN TYPENAME = 'VARGRAPH' THEN 'VARGRAPHIC' ELSE TYPENAME END
                             || '(' || LENGTH
                             || CASE WHEN CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END || ')'
                        WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                        THEN TYPENAME || '(' || LENGTH || ')'  
                        WHEN TYPENAME LIKE 'TIMESTAM%' AND SCALE = 6
                        THEN 'TIMESTAMP'
                        WHEN TYPENAME LIKE ('TIMESTAM%')    -- cater for the DATATYPE column being truncated in the ADMIN function
                        THEN 'TIMESTAMP' || '(' || RTRIM(CHAR(SCALE))  || ')'
                        WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                        THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                        WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                        THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                        WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                        ELSE TYPENAME END 
                    || CASE WHEN INLINE_LENGTH <> 0 THEN ' INLINE LENGTH ' || INLINE_LENGTH ELSE '' END
                    || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        AS DATATYPE_DDL
                ,   CASE WHEN DEFAULT IS NOT NULL THEN ' DEFAULT ' || DEFAULT ELSE '' END        AS DEFAULT_VALUE_DDL 
                ,   COLNO + 1                                                                    AS COL_SEQ
                FROM
                    TABLE(ADMIN_GET_TEMP_COLUMNS(NULL,NULL,NULL)) C
           ) C
          )
      GROUP BY
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000
    ) AS C
USING ( TABSCHEMA, TABNAME )
