--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows auto and manual runstats history from the db2optstats log. Defaults to entries for the current day
 */

CREATE OR REPLACE VIEW DB_RUNSTATS_LOG AS
SELECT * FROM(
    SELECT TIMESTAMP
    ,      TIMEZONE                             AS TZ
    ,      OBJNAME_QUALIFIER                    AS TABSCHEMA
    ,      OBJNAME                              AS TABNAME
    ,      SUBSTR(SECOND_EVENTQUALIFIER, 1, 20) AS COLLECT_TYPE 
    ,      AUTH_ID
    ,      SUBSTR(OBJTYPE, 1, 30)               AS OBJTYPE
    ,      SUBSTR(EVENTSTATE, 1, 8)             AS RESULT
    ,      SUBSTR(COALESCE(THIRD_EVENTQUALIFIER,''), 1, 15) AS REASON
    FROM
           TABLE(SYSPROC.PD_GET_DIAG_HIST('OPTSTATS', '', '',DB_DIAG_FROM_TIMESTAMP,DB_DIAG_TO_TIMESTAMP,DB_DIAG_MEMBER)) AS SL
    WHERE
        OBJNAME_QUALIFIER IS NOT NULL
    AND EVENTSTATE <> 'start'
    ORDER BY
        TIMESTAMP
)SS
