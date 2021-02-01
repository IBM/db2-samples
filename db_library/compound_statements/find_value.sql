--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * Search all columns for a given value or condition
 * 
 *  The example below will search all Character columns.
 *  Edit for your purposes as needed
 * 
 * Each column is searched individually. 
 * 
 * For Column organised tables this is efficient
 * For Row organised tables, the searching could be done on all columns in one SELECT
 *      but the current code below is not that clever
 * 
 * https://stackoverflow.com/questions/58756007/db2-looping-through-all-tables-listed-in-the-sysibm-syscolumns-output-for-specif 
 */

CREATE TABLE FIND_VALUE (
    TABSCHEMA  VARCHAR(128) NOT NULL
,   TABNAME    VARCHAR(128) NOT NULL
,   COLNAME    VARCHAR(128) NOT NULL
,   ROW_COUNT   BIGINT
)
@
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'INSERT INTO FIND_VALUE SELECT '
            || '''' || TABSCHEMA || ''',''' || TABNAME || ''',''' || COLNAME || ''', COUNT(*) FROM '
            || '"' ||  TABSCHEMA || '"."' || TABNAME || '"'
            || ' WHERE "' || COLNAME || '" LIKE ''%' || 'Value To Find'  || '%''' AS S
        FROM SYSCAT.COLUMNS C JOIN SYSCAT.TABLES T USING ( TABSCHEMA, TABNAME )
        WHERE C.CODEPAGE > 0 
        AND TABSCHEMA NOT IN ('SYSIBM','SYSTOOLS')
        AND T.TYPE IN ('T','S')
        AND (TABSCHEMA, TABNAME, COLNAME) NOT IN (SELECT TABSCHEMA, TABNAME, COLNAME FROM FIND_VALUE)
        ORDER BY
            TABSCHEMA, TABNAME, COLNAME
    DO       
          EXECUTE IMMEDIATE C.S;
          COMMIT;
    END FOR;
END
@

SELECT * FROM FIND_VALUE
@
