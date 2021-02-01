--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows if a table is in a non NORMAL status
 * 
 * See https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0052897.html 
 * for decodes of the status columns:
    LOAD_STATUS 
        IN_PROGRESS
        PENDING
        NULL (if there is no load in progress for the table and the table is not in load pending state)
    INPLACE_REORG_STATUS 
        ABORTED (in a PAUSED state, but unable to RESUME; STOP is required)
        EXECUTING
        PAUSED
        NULL (if no inplace reorg has been performed on the table)

 *
 * The code below uses MON_GET_UTILITY to avoid the call to ADMIN_GET_TAB_INFO from geting lock timeout if there are any in-progress loads
 */

CREATE OR REPLACE VIEW DB_TABLE_STATUS AS
WITH L AS (
    SELECT
        *
    FROM
        TABLE(MON_GET_UTILITY(-2))
    WHERE
        OBJECT_TYPE = 'TABLE'
    AND UTILITY_TYPE = 'LOAD'
    AND UTILITY_DETAIL NOT LIKE '%ONLINE LOAD%' 
)
SELECT
    T.TABSCHEMA
,   T.TABNAME
,   T.STATUS
,   I.AVAILABLE
,   I.REORG_PENDING
,   I.INPLACE_REORG_STATUS
,   I.LOAD_STATUS
,   I.READ_ACCESS_ONLY
,   I.NO_LOAD_RESTART
,   I.NUM_REORG_REC_ALTERS
,   I.INDEXES_REQUIRE_REBUILD
,   MAX(DBPARTITIONNUM)         AS MAX_DBPARTITIONNUM
,   MIN(DBPARTITIONNUM)         AS MIN_DBPARTITIONNUM
,   MAX(DATA_PARTITION_ID)      AS MAX_DATA_PARTITION_ID
,   MIN(DATA_PARTITION_ID)      AS MIN_DATA_PARTITION_ID
FROM
    SYSCAT.TABLES  T
,   TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
WHERE
    T.TABSCHEMA = I.TABSCHEMA
AND T.TABNAME   = I.TABNAME
AND ( T.TABSCHEMA, T.TABNAME ) NOT IN (SELECT OBJECT_SCHEMA, OBJECT_NAME FROM L L)
AND T.TABSCHEMA <> 'SYSIBM'
GROUP BY
    T.TABSCHEMA
,   T.TABNAME
,   T.STATUS
,   I.AVAILABLE
,   I.REORG_PENDING
,   I.INPLACE_REORG_STATUS
,   I.LOAD_STATUS
,   I.READ_ACCESS_ONLY
,   I.NO_LOAD_RESTART
,   I.NUM_REORG_REC_ALTERS
,   I.INDEXES_REQUIRE_REBUILD
UNION ALL
SELECT
    OBJECT_SCHEMA
,   OBJECT_NAME
,   'L'                  AS STATUS
,   'Y'                  AS AVAILABLE
,   ''                   AS REORG_PENDING
,   ''                   AS INPLACE_REORG_STATUS
,   'IN_PROGRESS'        AS LOAD_STATUS
,   CASE WHEN UTILITY_DETAIL LIKE '%ONLINE LOAD%' THEN  'Y' ELSE 'N' END  AS READ_ACCESS_ONLY
,   ''                   AS NO_LOAD_RESTART
,   NULL                 AS NUM_REORG_REC_ALTERS
,   NULL                 AS INDEXES_REQUIRE_REBUILD
,   NULL                 AS MAX_DBPARTITIONNUM
,   NULL                 AS MIN_DBPARTITIONNUM
,   NULL                 AS MAX_DATA_PARTITION_ID
,   NULL                 AS MIN_DATA_PARTITION_ID
FROM L
