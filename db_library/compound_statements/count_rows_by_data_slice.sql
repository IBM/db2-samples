--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Count the number of rows in each table by data slice.
 * 
 * Usefull for a fully accurate check on table Skew
 * 
 */

CREATE TABLE DB_ROW_COUNTS_BY_SLICE (
    TABSCHEMA  VARCHAR(128) NOT NULL
,   TABNAME    VARCHAR(128) NOT NULL
,   DATA_SLICE  SMALLINT NOT NULL
,   ROW_COUNT   BIGINT
,   TS      TIMESTAMP NOT NULL
--,   PRIMARY KEY (TABSCHEMA, TABNAME, DATA_SLICE) ENFORCED
)

@

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'INSERT INTO DB_ROW_COUNTS_BY_SLICE SELECT ''' || TABSCHEMA || ''',''' || TABNAME || ''', DS, COUNT(*), CURRENT TIMESTAMP FROM '
            || '( SELECT DATASLICEID AS DS FROM "' ||  TABSCHEMA || '"."' || TABNAME || '") GROUP BY DS' AS S
        FROM SYSCAT.TABLES 
        WHERE TYPE = 'T'
        AND   TABLEORG = 'C'
        AND   CARD > 0
        AND   TABSCHEMA NOT IN ('SYSIBM','SYSTOOLS') 
        AND   TABSCHEMA NOT LIKE 'IBM%'
        AND   TABNAME <> 'DB_ROW_COUNTS_BY_SLICE'
        AND     (TABSCHEMA, TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM DB_ROW_COUNTS_BY_SLICE)
        ORDER BY TABSCHEMA, TABNAME
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S;
          COMMIT;
    END FOR;
END

@