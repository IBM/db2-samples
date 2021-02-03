--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Helps pick suitable columns for table distribution. Generates skew check and ADMIN_MOVE_TABLE sql for all columns. Up to you to pick which column(s) to use
 */

CREATE OR REPLACE VIEW DB_CHANGE_DISTRIBUTION_KEY AS
SELECT
    C.TABSCHEMA
,   C.TABNAME
,   C.COLNAME
,   C.COLNO
,   C.PARTKEYSEQ
,   C.COLCARD
,   QUANTIZE(100 * (C.COLCARD::DECFLOAT / T.CARD)         ,00.01) AS PCT_UNIQUE
,   QUANTIZE(100 * (D.VALCOUNT::DECFLOAT/NULLIF(T.CARD,0)),00.01) AS TOP_VALUE_PERCENT
,   C.TYPENAME
,   C.NULLS
,   C.NUMNULLS
,   'call admin_move_table(''' || RTRIM(C.TABSCHEMA) ||''',''' || C.TABNAME || ''','''','''','''','''',''"' || C.COLNAME 
        || '"'','''','''',''ALLOW_READ_ACCESS'
        || CASE WHEN CARD BETWEEN 1 AND 10000
                THEN ',COPY_USE_LOAD'  -- Use LOAD on small tables to force a dictonary to be created even though the table might have fewer rows per partition than the ADC threashold
                ELSE '' END            -- Use INSERT on large tables to benefit from improved string compression in Db2W
        || ''',''MOVE'')'
        AS CHANGE_STMT
--    , 'INSERT INTO DB.DB2_DISTRIBUTION' 
,   'SELECT ''' || RTRIM(C.TABSCHEMA) || ''' TABSCHEMA ,''' 
    || C.TABNAME || ''' TABNAME ,''' || C.COLNAME || ''' COLNAMES, SLICE, COUNT(*) AS ROW_COUNT FROM (SELECT'
    || ' COALESCE(MOD(ABS(COALESCE(HASH4("' || C.COLNAME || '"),-1)),23),0) + 1 AS SLICE FROM "'
    || RTRIM(C.TABSCHEMA) || '"."' || C.TABNAME || '"'
    || ') S GROUP BY SLICE'
        AS CHECK_SQL 
FROM
    SYSCAT.COLUMNS  C
JOIN
    SYSCAT.TABLES   T
ON  
    C.TABSCHEMA = T.TABSCHEMA 
AND C.TABNAME   = T.TABNAME
LEFT OUTER JOIN
    SYSCAT.COLDIST  D
ON  
    C.TABSCHEMA = D.TABSCHEMA 
AND C.TABNAME   = D.TABNAME
AND C.COLNAME   = D.COLNAME
AND D.TYPE = 'F'
AND D.SEQNO = 1