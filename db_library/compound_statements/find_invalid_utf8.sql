--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Search for and record all column values that contain invalid UTF-8 bytes
 * 
 */

CREATE TABLE DBT_INVALID_UTF8_VALUES (
    TABSCHEMA  VARCHAR(128)  NOT NULL
,   TABNAME    VARCHAR(128)  NOT NULL
,   COLNAME    VARCHAR(128)  NOT NULL
,   VALUE      VARCHAR(4096) NOT NULL
,   PRIMARY KEY (TABSCHEMA, TABNAME, COLNAME, VALUE) --ENFORCED
)
@

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'INSERT INTO DBT_INVALID_UTF8_VALUES'
        || CHR(10) || 'SELECT DISTINCT ''' || TABSCHEMA || ''',''' || TABNAME || ''',''' || COLNAME || ''''
        || ', VARCHAR("'  || COLNAME || '",4096)'
        || CHR(10) || 'FROM '
        || '"' ||  TABSCHEMA || '"."' || TABNAME || '" AS S'
        || CHR(10) || 'WHERE NOT DB_IS_VALID_UTF8("' || COLNAME || '") AND "' || COLNAME || '" IS NOT NULL' AS S
        FROM SYSCAT.COLUMNS C JOIN SYSCAT.TABLES T USING ( TABSCHEMA, TABNAME )
        WHERE T.TYPE = 'T' 
        AND   C.TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
        AND   C.CODEPAGE > 0 
        AND   TABSCHEMA NOT LIKE 'SYS%'
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S;
          COMMIT;
    END FOR;
END
@