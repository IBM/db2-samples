--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Count the number of rows for every character column that contain any multi-byte characters
 * 
 *  Works on CHAR/VARCHAR/GRAPHIC/VARGRAPHIC/NCHAR/NVARCHAR and CLOB columns
 * 
 *  I.e. works fine on OCTETS, CODEUNITS16 and CODEUNITS32 columns
 * 
 *  Might not work on a non-Unicode database. I have not tested it on one.
*/

CREATE TABLE DB_COLUMNS_WITH_MULTI_BYTE_UTF8_CHARACTERS (
    TABSCHEMA                   VARCHAR(128) NOT NULL
,   TABNAME                     VARCHAR(128) NOT NULL
,   COLNAME                     VARCHAR(128) NOT NULL
,   MULTI_BYTE_UTF8_ROW_COUNT   BIGINT
,   TS                          TIMESTAMP NOT NULL
,   PRIMARY KEY (TABSCHEMA, TABNAME, COLNAME) ENFORCED
)
@
TRUNCATE TABLE DB_COLUMNS_WITH_MULTI_BYTE_UTF8_CHARACTERS IMMEDIATE

@
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'INSERT INTO DB_COLUMNS_WITH_MULTI_BYTE_UTF8_CHARACTERS'
        || ' SELECT ''' || TABSCHEMA || ''',''' || TABNAME || ''',''' || COLNAME 
        || ''', SUM(COALESCE(INT(LENGTHB("' || COLNAME || '"'
        || CASE WHEN C.CODEPAGE = 1200 THEN '::VARCHAR)' ELSE ')' END      -- Cater for UTF-16 types
        || ' > LENGTH4("' || COLNAME || '")),0))'
        || ', CURRENT TIMESTAMP FROM '
        || '"' ||  TABSCHEMA || '"."' || TABNAME || '"' AS S
        FROM SYSCAT.COLUMNS C JOIN SYSCAT.TABLES T USING ( TABSCHEMA, TABNAME )
        WHERE TYPE = 'T' 
        AND   TABLEORG = 'C'
        AND   C.CODEPAGE > 0
--      AND   T.CARD > 0
        AND   TABSCHEMA NOT LIKE 'SYS%'
        AND   TABSCHEMA = 'STAGING'
        AND   ( TABSCHEMA, TABNAME, COLNAME ) NOT IN (SELECT TABSCHEMA, TABNAME, COLNAME  FROM DB_COLUMNS_WITH_MULTI_BYTE_UTF8_CHARACTERS)
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S;
          COMMIT;
    END FOR;
END
@

-- SQL to help you look at the output table
-- Include generateing SQL to help you look at the actual data that contains multi-byte chracters
SELECT *
,   'SELECT * FROM (SELECT "' || COLNAME || '", HEX("' || COLNAME || '"), LENGTHB("' || COLNAME || '"::VARCHAR) AS UTF8_LEN, LENGTH4("' || COLNAME || '") AS CHAR_LEN'
    || CHR(10) || 'FROM "' || TABSCHEMA || '"."' || TABNAME || '") WHERE UTF8_LEN > CHAR_LEN'   AS VIEW_SQL
FROM DB_COLUMNS_WITH_MULTI_BYTE_UTF8_CHARACTERS
--WHERE MULTI_BYTE_UTF8_ROW_COUNT > 0 WITH UR
ORDER BY MULTI_BYTE_UTF8_ROW_COUNT DESC NULLS LAST, TS DESC WITH UR
@

