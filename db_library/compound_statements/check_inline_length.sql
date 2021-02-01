--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * See if any LOB columns could be in-lined
 */

--DROP TABLE     DB_INLINE_LENGTH
--TRUNCATE TABLE DB_INLINE_LENGTH IMMEDIATE

CREATE TABLE DB_INLINE_LENGTH (
    TABSCHEMA    VARCHAR(128) NOT NULL
,   TABNAME      VARCHAR(128) NOT NULL
,   COLNAME      VARCHAR(128) NOT NULL
,   IS_INLINED          SMALLINT --NOT NULL
,   EST_INLINE_LENGTH   INTEGER --NOT NULL
,   ROW_COUNT    BIGINT NOT NULL
--,   PRIMARY KEY (TABSCHEMA, TABNAME, COLNAME, IS_INLINED) ENFORCED
)
@

/* For EST_INLINE_LENGTH 
     NULL = The column value was  NULL.
    -1    = The data cannot be inlined because there is no valid inline length that would allow the column value to be inlined.
    -2    = The estimated inline length of the document cannot be determined because the document was inserted and stored using an earlier product release. 
*/
    
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'INSERT INTO DB_INLINE_LENGTH' || CHR(10)
        || ' SELECT ''' || TABSCHEMA || ''',''' || TABNAME || ''',''' || COLNAME || ''''
        || ' , IS_INLINED, MAX(EST_INLINE_LENGTH) AS EST_INLINE_LENGTH, COUNT(*) AS ROW_COUNT '
        || ' FROM (' || CHR(10)
        || ' SELECT ADMIN_IS_INLINED("' || COLNAME || '") AS IS_INLINED'
        || ' ,      ADMIN_EST_INLINE_LENGTH("' || COLNAME || '") AS EST_INLINE_LENGTH'       
        || ' FROM "' ||  TABSCHEMA || '"."' || TABNAME || '") AS S' || CHR(10)
        || 'GROUP BY IS_INLINED'
        AS S
        FROM
            SYSCAT.COLUMNS JOIN SYSCAT.TABLES USING (TABSCHEMA, TABNAME)
        WHERE
            TYPE IN ('T','S')
        AND TABSCHEMA NOT LIKE 'SYS%'
        AND TYPENAME IN ('XML','CLOB','BLOB','DBCLOB')
        AND (TABSCHEMA, TABNAME, COLNAME) NOT IN (SELECT TABSCHEMA, TABNAME, COLNAME FROM DB_INLINE_LENGTH)
        ORDER BY
            TABSCHEMA, TABNAME, COLNAME
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S;
          COMMIT;
    END FOR;
END
@

-- Now generate ALTERs for any columns that might benifit from being inlined
--    Not that for a given row, a LOB is either inlined or not. If it 1 byte too long, none of it will be inlined
--     and so none will be compressed

SELECT TABSCHEMA, TABNAME, COLNAME
,   SUM(CASE WHEN IS_INLINED = 1 THEN ROW_COUNT ELSE 0 END) AS INLINED
,   SUM(CASE WHEN IS_INLINED = 0 THEN ROW_COUNT ELSE 0 END) AS OUTLINED
,   SUM(CASE WHEN IS_INLINED IS NULL THEN ROW_COUNT ELSE 0 END) AS NULLS
,   MAX(EST_INLINE_LENGTH) AS EST_INLINE_LENGTH
,   'ALTER TABLE ' || TABNAME || ' ALTER COLUMN ' || COLNAME || ' SET INLINE LENGTH ' || MAX(EST_INLINE_LENGTH)
FROM
    DB_INLINE_LENGTH
WHERE
    TABSCHEMA NOT LIKE 'SYS%' 
GROUP BY
    TABSCHEMA, TABNAME, COLNAME
--HAVING
--    SUM(CASE WHEN IS_INLINED = 0 THEN ROW_COUNT ELSE 0 END)
ORDER BY OUTLINED DESC
