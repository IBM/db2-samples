--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Check how well a table is sorted for each column based on it's synopsis table.
 * 
 * Adapted from the IIAS script db_sort_order
 * 
 *  https://www.ibm.com/support/knowledgecenter/en/SSHRBY/com.ibm.swg.im.dashdb.apdv.porting.doc/doc/db_sort_order_v21.html
 * 
 * Probably could be improved. E.g. cater for columsn with NULL values
 *   Also, a useful metric to calculate is the average span of values each synopsis row covers. 
 *      I.e. it is not just sorting that matters, but clustering. Especally on character columns
 */

--DROP TABLE     DB_TABLE_SORT_ORDER
--TRUNCATE TABLE DB_TABLE_SORT_ORDER IMMEDIATE

CREATE TABLE DB_TABLE_SORT_ORDER (
    TABSCHEMA    VARCHAR(128) NOT NULL
,   TABNAME      VARCHAR(128) NOT NULL
,   COLNAME      VARCHAR(128) NOT NULL
,   DATASLICE    SMALLINT NOT NULL
,   SYN_ROWS     BIGINT   NOT NULL
,   MAX_LESS_MIN                     BIGINT  --NOT NULL
,   MIN_LESS_MIN_AND_MAX_LESS_MAX    BIGINT  --NOT NULL
--,   PRIMARY KEY (TABSCHEMA, TABNAME, COLNAME, DATASLICE) ENFORCED
) DISTRIBUTE ON ( DATASLICE )
@

-- View to help you look at the results of the compond statment below
CREATE OR REPLACE VIEW DB_TABLE_SORTING AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNAME
,   QUANTIZE(SUM(MAX_LESS_MIN)::DECFLOAT                  / SUM(SYN_ROWS) * 100.00,0) AS "%SORT1"
,   QUANTIZE(SUM(MIN_LESS_MIN_AND_MAX_LESS_MAX)::DECFLOAT / SUM(SYN_ROWS) * 100.00,0) AS "%SORT2"
FROM
    DB_TABLE_SORT_ORDER
GROUP BY
    TABSCHEMA
,   TABNAME
,   COLNAME
@
    
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
           'INSERT INTO DB_TABLE_SORT_ORDER' || CHR(10) ||
           'WITH D AS'                       || CHR(10) ||
           '(   SELECT'                      || CHR(10) ||
           '        ROW_NUMBER () OVER (PARTITION BY DATASLICEID ORDER BY TSNMIN) AS EXTENT' || CHR(10) ||
           '    ,   DATASLICEID AS DS'      || CHR(10) ||
           '    ,   ' || C.COLNAME || 'MIN  AS  MIN_VAL' || CHR(10) ||
           '    ,   ' || C.COLNAME || 'MAX  AS  MAX_VAL' || CHR(10) ||
           '    FROM SYSIBM.' || D.TABNAME || CHR(10) ||
           ')' || CHR(10) ||
           'SELECT' || CHR(10) ||
           '   ''' || C.TABSCHEMA || ''' AS TABSCHEMA'  || CHR(10) ||
           ',  ''' || C.TABNAME   || ''' AS TABNAME'    || CHR(10) ||
           ',  ''' || C.COLNAME   || ''' AS COLNAME'    || CHR(10) ||
           ',   DS      AS DATASLICE' || CHR(10) ||
           ',   SUM(1)  AS SYN_ROWS' || CHR(10) ||
           ',   SUM(S1) AS MAX_LESS_MIN                   ' || CHR(10) || -- Previous Max less than or equal to next Min
           ',   SUM(S2) AS MIN_LESS_MIN_AND_MAX_LESS_MAX  ' || CHR(10) || -- Previous Min less than or equal to next Min and Prev Max less than or equal to next Max
           'FROM ' || CHR(10) ||
           '(  SELECT   ' || CHR(10) ||
           '        N.DS' || CHR(10) ||
           '    ,   P.MAX_VAL <= N.MIN_VAL AS S1' || CHR(10) ||
           '    ,   P.MIN_VAL <= N.MIN_VAL AND P.MAX_VAL <= N.MAX_VAL  AS S2' || CHR(10) ||
           '    FROM  D N' || CHR(10) ||
           '    JOIN  D P' || CHR(10) ||
           '    ON (  N.DS     = P.DS ' || CHR(10) ||
           '    AND   N.EXTENT = P.EXTENT + 1 )' || CHR(10) ||
--         '    WHERE N.MIN_VAL <= N.MAX_VAL' || CHR(10) ||
           ') S' || CHR(10) ||
           'GROUP BY DS'        AS STMT
        FROM
            SYSCAT.COLUMNS C
        ,   SYSCAT.TABLES  T
        ,   SYSCAT.TABDEP  D
        WHERE 
              C.TABSCHEMA = T.TABSCHEMA
        AND   C.TABNAME   = T.TABNAME
        AND   T.TABSCHEMA = D.BSCHEMA
        AND   T.TABNAME   = D.BNAME
        AND   D.DTYPE     = '7'
        AND  (T.TABSCHEMA, T.TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM DB_TABLE_SORT_ORDER)
        AND   C.TYPENAME NOT IN ('CLOB','BLOB','DBCLOB') -- these types are not in synopsis tables
        AND   C.LENGTH <= 1000  -- varchars longer than 1000 bytes are not included in synopsis tables
        AND   C.COLNAME NOT IN ('RANDOM_DISTRIBUTION_KEY')  -- no point looking at RANDOM identity columns
        AND   T.TABNAME NOT IN ('DB_TABLE_SORT_ORDER')      -- skip our own table
        AND   T.TABSCHEMA IN ('STAGING')     -- add your own filter here if you wish
        ORDER BY
            C.TABSCHEMA, C.TABNAME, C.COLNO
        WITH UR
    DO
          EXECUTE IMMEDIATE C.STMT;
          COMMIT;
    END FOR;
END
@
