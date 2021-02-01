--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Current coordinator activity by status and whether the query bypassed the adaptive workload manager
 * 
 * EXECUTING - queries are currently processing a request in the database engine. 
 * IDLE - query is blocked on the client (i.e. waiting for the next client request). 
 * QUEUED – query is waiting for resources so that they can be admitted. 
 * 
 * Two counts are reported per state for this query; the total number of activities and the number that bypassed admission control. 
 * 
 * Bypassed activities do not directly cause queuing. 
 * 
*/

CREATE OR REPLACE VIEW DB_WLM_ACTIVITY_STATE AS
SELECT
    ACTIVITY_STATE
,   COUNT(*)                 AS ACTIVITIES
,   SUM(INT(ADM_BYPASSED))   AS BYPASSED
FROM
    TABLE(MON_GET_ACTIVITY(NULL,-2)) AS T
WHERE
    MEMBER = COORD_PARTITION_NUM
GROUP BY
    ACTIVITY_STATE
