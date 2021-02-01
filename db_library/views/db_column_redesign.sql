--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generates SQL that can be run to find max used sizes for column data-types, which can then be used to generate redesigned DDL
 */

CREATE OR REPLACE VIEW DB_COLUMN_REDESIGN AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNAME
,   COLNO
,   'INSERT INTO DBT_COLUMN_REDESIGN'  AS INSERT_LINE
,   'SELECT'
    || CHR(10) || '    ''' || TABSCHEMA || ''' AS TABSCHEMA'
    || CHR(10) || ',   ''' || TABNAME   || ''' AS TABNAME'
    || CHR(10) || ',   ''' || COLNAME   || ''' AS COLNAME'
    || CHR(10) || ',   '   || COLNO     || '   AS COLNAME'
    || CHR(10) || ',   ''' || TYPESCHEMA || ''' AS TYPESCHEMA'
    || CHR(10) || ',   ''' || TYPENAME   || ''' AS TYPENAME'
    || CHR(10) || ',   '   || LENGTH     || ' AS LENGTH'
    || CHR(10) || ',   '   || SCALE      || ' AS SCALE'
    || CHR(10) || ',   ' || COALESCE('''' || TYPESTRINGUNITS   || '''','NULL') || ' AS TYPESTRINGUNITS'
    || CHR(10) || ',   ' || COALESCE(CHAR(STRINGUNITSLENGTH),'NULL') || ' AS STRINGUNITSLENGTH'
    || CHR(10) || ',   ''' || NULLS             || ''' AS NULLS'
    || CHR(10) || ',   ' || COALESCE('' || C.CODEPAGE         || '','NULL') || ' AS CODEPAGE'
    || CHR(10) || ',   COUNT(*) AS ROW_COUNT'
    || CHR(10) || ',   ' || CASE WHEN CARD < 50000000 AND (COLCARD/CARD::DECFLOAT) > .95     THEN 'COUNT(DISTINCT ' || '"' || COLNAME || '"'  || ')' ELSE 'NULL' END || ' AS DISTINCT_COUNT'
    || CHR(10) || ',   COUNT(*) - COUNT(' || '"' || COLNAME || '"'  || ') AS NULL_COUNT'
    || CHR(10) || ',   MAX(' || '"' || COLNAME || '"'  || ') AS MAX_VALUE'
    || CHR(10) || ',   MIN(' || '"' || COLNAME || '"'  || ') AS MIN_VALUE'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('SMALLINT','INTEGER','DECFLOAT','DECIMAL','FLOAT','REAL','DOUBLE')  THEN  'AVG(' || '"' || COLNAME || '"'  || ') '
                                 WHEN TYPENAME IN ('BIGINT')                                                           THEN  'AVG(DECFLOAT("' || COLNAME || '")'  || ') '
                                                         ELSE 'NULL' END || ' AS AVG_VALUE'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR','VARGRAPHIC') THEN 'MAX(LENGTH(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'MAX(LENGTH(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                 WHEN TYPENAME IN ('DECIMAL','SMALLINT','INTEGER','BIGINT','DECFLOAT' ) THEN 'MAX(BIGINT(LOG10(ABS(NULLIF(' || '"' || RTRIM(COLNAME) || '"'  || ',0))))+1)'
                                     ELSE 'NULL' END || ' AS MAX_LENGTH'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR')    AND TYPESTRINGUNITS = 'OCTETS' THEN 'MAX(LENGTH4(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER' ) AND TYPESTRINGUNITS = 'OCTETS' THEN 'MAX(LENGTH4(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                                         ELSE 'NULL' END || ' AS MAX_LENGTH4'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR','VARGRAPHIC') THEN 'MIN(LENGTH(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'MIN(LENGTH(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                                         ELSE 'NULL' END || ' AS MIN_LENGTH'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('VARCHAR','VARGRAPHIC') THEN 'AVG(LENGTH(' || '"' || COLNAME || '"'  || '))' 
                                 WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'AVG(LENGTH(' || '"' || RTRIM(COLNAME) || '"'  || '))'
                                                         ELSE 'NULL' END || ' AS AVG_LENGTH'
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('DECFLOAT','FLOAT','REAL','DOUBLE') OR (TYPENAME = 'DECIMAL' AND SCALE > 0 )
                                THEN 'MAX(LENGTH(RTRIM(DECIMAL(ABS(' || '"' || COLNAME || '"'  || ') -TRUNC(ABS(' || '"' || COLNAME || '"'  || ')),31,31),''0'')) -1)' 
                      WHEN TYPENAME IN ('TIMESTAMP')                                  AND SCALE > 0 THEN 'MAX(LENGTH(RTRIM("' || COLNAME || '",''0'')) - 20)' ELSE 'NULL' END || ' AS MAX_SCALE'
--
    || CHR(10) || ',   ' || CASE WHEN TYPENAME IN ('CHARACTER','VARCHAR','GRAPHIC','VARGRAPHIC' ) AND C.CODEPAGE <> 0 THEN 'SUM(REGEXP_LIKE("' || COLNAME || '",''^[0-9]+$''))' ELSE 'NULL' END || ' AS ONLY_DIGITS_COUNT' 
--  trailing spaces
--  only hex values    
--  only ascii / single byte UTF-8 characters
--                     
    || CHR(10) || ' FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
            AS SELECT_STMT
FROM
    SYSCAT.COLUMNS C JOIN SYSCAT.TABLES T USING ( TABSCHEMA, TABNAME )
WHERE
    T.TYPE NOT IN ('A','N','V','W')
AND T.TABSCHEMA NOT LIKE 'SYS%'
AND C.TYPESCHEMA NOT IN ('DB2GSE')
