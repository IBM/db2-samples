--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Count the number of rows in each table
 * 
 * Also "published" here https://stackoverflow.com/questions/58725902/db2-select-statement-from-a-table-name-where-the-table-name-is-a-variable */
 * 
 */

CREATE TABLE DB_ROW_COUNTS (
    TABSCHEMA  VARCHAR(128) NOT NULL
,   TABNAME    VARCHAR(128) NOT NULL
,   ROW_COUNT   BIGINT
,   TS      TIMESTAMP NOT NULL
,   PRIMARY KEY (TABSCHEMA, TABNAME) ENFORCED
)
@

TRUNCATE TABLE  DB_ROW_COUNTS IMMEDIATE
@

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'INSERT INTO DB_ROW_COUNTS SELECT ''' || TABSCHEMA || ''',''' || TABNAME || ''', COUNT(*), CURRENT TIMESTAMP FROM '
            || '"' ||  TABSCHEMA || '"."' || TABNAME || '"' AS S
        FROM SYSCAT.TABLES 
        WHERE TYPE = 'T' 
        AND   (TABSCHEMA, TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM DB_ROW_COUNTS)
        AND   TABSCHEMA NOT LIKE 'SYS%'
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S;
          COMMIT;
    END FOR;
END
@
