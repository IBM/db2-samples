--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Provide a (possibly inaccurate) estimate of when a table might have last been updated
 */

CREATE OR REPLACE VIEW DB_TABLE_LAST_UPDATED_ESTIMATE AS
SELECT
    TABSCHEMA
,   TABNAME
,   CASE WHEN STATS_ROWS_MODIFIED = 0 THEN STATS_TIME::DATE     -- Use last stats time if not IUD since that time
         WHEN M.TABNAME IS NULL                                 -- Use last Db2 start time if no monitering data
         OR (STATS_ROWS_MODIFIED = 0 AND ROWS_INSERTED = 0 AND ROWS_UPDATED = 0 AND ROWS_DELETED = 0)  -- or if no IUDs since last restart
         THEN (SELECT MIN(DB2START_TIME)::DATE FROM TABLE(MON_GET_INSTANCE(-2)))
         ELSE NULL
        END             AS LAST_UPDATED_DATE
,   STATS_ROWS_MODIFIED
,   ROWS_INSERTED
,   ROWS_UPDATED
,   ROWS_DELETED 
FROM
    SYSCAT.TABLES
LEFT JOIN (
    SELECT 
        TABSCHEMA
    ,   TABNAME
    ,   SUM(NULLIF(STATS_ROWS_MODIFIED,POWER(2::BIGINT,32)-1)) AS STATS_ROWS_MODIFIED
    ,   SUM(ROWS_INSERTED)       AS ROWS_INSERTED
    ,   SUM(ROWS_UPDATED )       AS ROWS_UPDATED
    ,   SUM(ROWS_DELETED )       AS ROWS_DELETED
   FROM
        TABLE(MON_GET_TABLE(NULL, NULL, -2))
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ) M USING ( TABSCHEMA, TABNAME )
WHERE TYPE = 'T'
