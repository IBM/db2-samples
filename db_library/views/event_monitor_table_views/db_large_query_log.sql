--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows SQL activity captured by an WLM Event Activity Monitor
 */

--CREATE OR REPLACE VIEW DB.DB_LARGE_QUERY_LOG AS
SELECT  
        A.QUERY_COST_ESTIMATE
,       A.QUERY_CARD_ESTIMATE
,       A.SESSION_AUTH_ID
,       A.TPMON_CLIENT_WKSTN        AS CLIENT_WORKSTATION
,       A.USER_CPU_TIME
,       V.THRESHOLD_PREDICATE       AS THRESHOLD_NAME
,       V.THRESHOLD_MAXVALUE        AS THRESHOLD_VALUE
,       V.THRESHOLD_ACTION          AS THRESHOLD_ACTION
,       A.SQLCODE                   AS SQL_ERROR_CODE
,       CASE A.SQLCODE WHEN      0 THEN 'Successful'
                       WHEN    100 THEN 'No rows'
                       WHEN   -952 THEN 'User Cancelled'
                       WHEN  -1224 THEN 'App forced off'
                       WHEN   -954 THEN 'Application heap full'
                       WHEN   -802 THEN 'Arithmetic overflow'
                       ELSE '' END  AS SQL_ERROR_MESSAGE
,       A.ROWS_RETURNED
,       A.ROWS_FETCHED
,       A.ROWS_MODIFIED
,       A.TIME_CREATED              AS QUERY_DATETIME
,       V.TIME_OF_VIOLATION         AS VIOLATION_DATETIME
,       CASE WHEN A.TIME_STARTED > '2001-01-01-00.00.00' THEN
         (BIGINT(DAYS(A.TIME_COMPLETED)) * 86400 + MIDNIGHT_SECONDS(A.TIME_COMPLETED))
        - (BIGINT(DAYS(A.TIME_STARTED  )) * 86400 + MIDNIGHT_SECONDS(A.TIME_STARTED  ))  END AS ELAPSED_TIME_SECONDS 
,       A.TOTAL_SORT_TIME
,       A.ACTIVITY_TYPE
,       ST.STMT_TEXT
FROM    
        MON_ACTIVITIES          A
,       MON_ACTIVITIES_STMT     ST
,       (   SELECT  V.*     -- Get the first violation
            ,       ROW_NUMBER() OVER(PARTITION BY APPL_ID, ACTIVITY_ID, UOW_ID, TIME_OF_VIOLATION) AS VIOLATION_DEDUP
            FROM    DB.MON_THRESHOLD_VIOLATIONS V
            WHERE   ACTIVITY_COLLECTED = 'Y'
            AND     THRESHOLD_PREDICATE <> 'ConnectionIdleTime'
         ) V
WHERE 
        A.APPL_ID                 = ST.APPL_ID
AND     A.ACTIVITY_ID             = ST.ACTIVITY_ID
AND     A.UOW_ID                  = ST.UOW_ID
AND     A.TIME_CREATED            = ST.STMT_FIRST_USE_TIME
AND     A.PARTITION_KEY           = ST.PARTITION_KEY
AND     A.ACTIVITY_SECONDARY_ID   = ST.ACTIVITY_SECONDARY_ID 
AND     V.APPL_ID                 = A.APPL_ID
AND     V.ACTIVITY_ID             = A.ACTIVITY_ID
AND     V.UOW_ID                  = A.UOW_ID
--AND     ( V.TIME_OF_VIOLATION >= A.TIME_CREATED  AND V.TIME_OF_VIOLATION <= A.TIME_COMPLETED )
AND     V.VIOLATION_DEDUP = 1

