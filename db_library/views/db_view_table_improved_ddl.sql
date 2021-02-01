--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns CREATE TABLE DDL that coresponds to the colum definitions of VIEWs but with NOT NULL used for columns without NULL values
 * 
 * Note you need to runstats your view for the NULL to NOT NULL feature to work. Otheriwse just use the DB_VIEW_TABLE_DDL view
 * E.g.
 *
 *      ALTER VIEW MY_SCHEMA.MY_VIEW ENABLE QUERY OPTIMIZATION@
 *      call admin_cmd('RUNSTATS ON VIEW MY_SCHEMA.MY_VIEW WITH DISTRIBUTION')@
 * 
 * Then if you don't need the view as a stat view, drop the optimization
 * 
 *      ALTER VIEW MY_SCHEMA.MY_VIEW DISABLE QUERY OPTIMIZATION@
 */

CREATE OR REPLACE VIEW DB_VIEW_TABLE_IMPROVED_DDL AS
SELECT
    TABSCHEMA  AS VIEWSCHEMA
,   TABNAME    AS VIEWNAME
,   'CREATE TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" (' 
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
            || CASE WHEN NULLS = 'N' THEN ' NOT NULL' 
                    WHEN COLCARD > 0 AND NUMNULLS = 0 THEN ' /* made */ NOT NULL' ELSE '' END                        AS DATATYPE_DDL
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
