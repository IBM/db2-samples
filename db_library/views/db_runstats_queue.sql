--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows runstats queued for processing by Db2 Automatic maintenance or real-time stats
 */

CREATE OR REPLACE VIEW DB_RUNSTATS_QUEUE AS
SELECT * FROM(
    SELECT
        'Auto stats'        AS COLLECT_TYPE
    ,   QUEUE_POSITION
    ,   OBJECT_SCHEMA       AS TABSCHEMA
    ,   OBJECT_NAME         AS TABNAME
    ,   OBJECT_TYPE
    ,   OBJECT_STATUS       AS STATUS
    ,   ''                  AS REQUEST_TYPE
    ,   QUEUE_ENTRY_TIME
    ,   JOB_SUBMIT_TIME     AS SUBMIT_START_TIME
    ,   MEMBER
    FROM TABLE(MON_GET_AUTO_RUNSTATS_QUEUE()) AS T
    UNION ALL
    SELECT 
        'Real-time stats'   AS COLLECT_TYPE
    ,   QUEUE_POSITION
    ,   OBJECT_SCHEMA       AS TABSCHEMA
    ,   OBJECT_NAME         AS TABNAME
    ,   OBJECT_TYPE
    ,   REQUEST_STATUS      AS OBJECT_STATUS
    ,   REQUEST_TYPE
    ,   QUEUE_ENTRY_TIME
    ,   EXECUTION_START_TIME    AS SUBMIT_START_TIME
    ,   MEMBER
    FROM
        TABLE(MON_GET_RTS_RQST()) AS T
    ORDER BY COLLECT_TYPE, QUEUE_POSITION ASC
)
