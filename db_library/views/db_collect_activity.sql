--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows where Db2 is configured to COLLECT ACTIVITY DATA for any activity event monitors
 *
 * Db2 can collect information about an activity by specifying COLLECT ACTIVITY DATA for any of the following
 * - service class
 * - workload
 * - work action
 * - threshold
 * 
 */

CREATE OR REPLACE VIEW DB_COLLECT_ACTIVITY AS
SELECT
    'THRESHOLD'         AS COLECTION_OBJECT_TYPE
,   THRESHOLDNAME       AS COLLECTION_OBJECT_NAME
,   COLLECTACTDATA
,   COLLECTACTPARTITION
,   'ALTER THRESHOLD "' || THRESHOLDNAME || '" COLLECT ACTIVITY DATA NONE'    AS DISABLE_DDL
FROM
    SYSCAT.THRESHOLDS
WHERE
    COLLECTACTDATA <> 'N'
UNION ALL
SELECT
    'WORKLOAD'          AS COLECTION_OBJECT_TYPE
,   WORKLOADNAME        AS COLLECTION_OBJECT_NAME
,   COLLECTACTDATA
,   COLLECTACTPARTITION
,   'ALTER WORKLOAD "' || WORKLOADNAME || '" COLLECT ACTIVITY DATA NONE' AS DISABLE_DDL
FROM
    SYSCAT.WORKLOADS
WHERE
    COLLECTACTDATA <> 'N'
UNION ALL
SELECT
    'SERVICE CLASS'     AS COLECTION_OBJECT_TYPE
,   COALESCE(PARENTSERVICECLASSNAME || '.','') || SERVICECLASSNAME  
                        AS COLLECTION_OBJECT_NAME
,   COLLECTACTDATA
,   COLLECTACTPARTITION
,   'ALTER SERVICE CLASS "' || SERVICECLASSNAME || COALESCE(' UNDER "' || PARENTSERVICECLASSNAME || '"','') || '" COLLECT ACTIVITY DATA NONE' AS DISABLE_DDL
FROM
    SYSCAT.SERVICECLASSES
WHERE
    COLLECTACTDATA <> 'N'
UNION ALL
SELECT
    'WORK ACTION'       AS COLECTION_OBJECT_TYPE
,   ACTIONSETNAME || '.'  || WORKCLASSNAME || '.'  || ACTIONNAME
                        AS COLLECTION_OBJECT_NAME
,   ACTIONTYPE AS COLLECTACTDATA            -- TO-DO, decode to be consistent with COLLECTACTDATA values
,   ACTIONTYPE AS COLLECTACTPARTITION       -- TO-DO, decode to be consistent with COLLECTACTPARTITION values
,   'ALTER WORK ACTION SET "' || WORKCLASSNAME || '" COLLECT ACTIVITY DATA NONE'    AS DISABLE_DDL
FROM SYSCAT.WORKACTIONS
WHERE 
    ACTIONTYPE IN (
        'D' -- Collect activity data with details at the coordinating member of the activity.
    ,   'F' -- Collect activity data with details, section, and values at the coordinating member of the activity.
    ,   'G' -- Collect activity details and section at the coordinating member of the activity and collect activity data at all members.
    ,   'H' -- Collect activity details, section, and values at the coordinating member of the activity and collect activity data at all members.
    ,   'S' -- Collect activity data with details and section at the coordinating member of the activity.
    ,   'V' -- Collect activity data with details and values at the coordinating member.                                          
    ,   'W' -- Collect activity data without details at the coordinating member.                                                  
    ,   'X' -- Collect activity data with details at the coordinating member and collect activity data at all members.            
    ,   'Y' -- Collect activity data with details and values at the coordinating member and collect activity data at all members. 
    ,   'Z' -- Collect activity data without details at all members.                                                              
)

