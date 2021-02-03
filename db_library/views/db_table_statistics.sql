--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows table statistics and rows modified since last runstats
 */

CREATE OR REPLACE VIEW DB_TABLE_STATISTICS AS
SELECT
    TABSCHEMA
,   TABNAME
,   STATS_TIME
,   CARD
,   STATS_ROWS_MODIFIED
,   RTS_ROWS_MODIFIED
,   CASE WHEN STATS_ROWS_MODIFIED > 0 AND DECFLOAT(STATS_ROWS_MODIFIED) / CARD > 0.5 THEN 1 ELSE 0 END AS AUTO_STATS_CANDIDATE
    /* the actual algorithm is more complex that this, but this is a reasonalbe approximation */
FROM
    SYSCAT.TABLES
LEFT JOIN
(
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   MAX(NULLIF(STATS_ROWS_MODIFIED,POWER(2::BIGINT,32)-1))    AS STATS_ROWS_MODIFIED  -- the number of rows modified since the last RUNSTATS.
    ,   MAX(NULLIF(RTS_ROWS_MODIFIED,POWER(2::BIGINT,32)-1)  )    AS RTS_ROWS_MODIFIED    -- the number of rows modified since last real-time statistics collection.
    FROM
        TABLE(MON_GET_TABLE(DEFAULT, DEFAULT, -2)) AS T
    WHERE
        TAB_TYPE <> 'EXTERNAL_TABLE'
    GROUP BY
        TABSCHEMA
    ,   TABNAME
)
    USING ( TABSCHEMA, TABNAME )
WHERE
    TYPE NOT IN ('A','N','V','W')
