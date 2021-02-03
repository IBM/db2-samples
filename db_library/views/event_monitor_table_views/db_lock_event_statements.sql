--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Show pairs of participents from the lock event monitor tables
 * 
 * It can be a good idea to query this just for  REQ_ACT = 'CURRENT' AND OWN_ACT = 'CURRENT'
 * as past events (previous, uncommited statements) are cross prducted in this version of the view
 * 
 * See  db_lock_event_statemetns for a version of this view that
 *   just list the pasrt events intermingled in first used order (albeit with the CURRENT statements at the top)
 * 
 */

CREATE OR REPLACE VIEW DB_LOCK_EVENT_STATEMENTS AS     
SELECT
    EVENT_ID
,   L.EVENT_TIMESTAMP::TIMESTAMP(0) AS EVENT_TIMESTAMP
,   MEMBER
,   L.EVENT_TYPE
--,   COUNT(DISTINCT EVENT_ID) AS EVENTS
--,   COUNT(DISTINCT MEMBER) AS MEMBERS
,   P.PARTICIPANT_TYPE     AS PARTICIPANT
,   P.AUTH_ID 
,   P.APPL_NAME
,   P.LOCK_OBJECT_TYPE     AS OBJECT_TYPE
,   CASE P.LOCK_MODE
          WHEN 0  THEN 'NO LOCK'
          WHEN 1  THEN 'IS'
          WHEN 2  THEN 'IX'
          WHEN 3  THEN 'S'
          WHEN 4  THEN 'SIX'
          WHEN 5  THEN 'X'
          WHEN 6  THEN 'IN'
          WHEN 7  THEN 'Z'
          WHEN 8  THEN 'U'
          WHEN 9  THEN 'NS'
          WHEN 10 THEN 'NX'
          WHEN 11 THEN 'WX'
          WHEN 11 THEN 'NWX'
          ELSE CHAR(P.LOCK_MODE)
    END AS HELD
,   CASE P.LOCK_MODE_REQUESTED
        WHEN  0 THEN 'NO LOCK'
        WHEN  1 THEN 'IS'
        WHEN  2 THEN 'IX'
        WHEN  3 THEN 'S'
        WHEN  4 THEN 'SIX'
        WHEN  5 THEN 'X'
        WHEN  6 THEN 'IN'
        WHEN  7 THEN 'Z'
        WHEN  8 THEN 'U'
        WHEN  9 THEN 'NS'
        WHEN  10 THEN 'NX'
        WHEN  11 THEN 'WX'
        WHEN  11 THEN 'NWX'
        ELSE '-1'
    END AS REQ
,   P.TABLE_SCHEMA
,   P.TABLE_NAME
,   A.STMT_FIRST_USE_TIME  AS FIRST_TS
,   CASE WHEN STMT_FIRST_USE_TIME <> STMT_LAST_USE_TIME THEN STMT_LAST_USE_TIME END AS LAST_TS
,   A.EFFECTIVE_ISOLATION  AS ISO
,   A.ACTIVITY_TYPE        AS ACT_TYPE
,   A.ACTIVITIES    AS COUNT
,   STMT_TEXT
FROM
    MON_LOCK L
JOIN
    MON_LOCK_PARTICIPANTS  P
USING
    (EVENT_ID, EVENT_TIMESTAMP, MEMBER, PARTITION_KEY ) 
LEFT JOIN 
    (   SELECT
            EVENT_ID, EVENT_TIMESTAMP, PARTICIPANT_NO,  MEMBER, PARTITION_KEY
        ,   EFFECTIVE_ISOLATION
        ,   ACTIVITY_TYPE
        ,   STMT_TEXT::VARCHAR(32000 OCTETS) AS STMT_TEXT
        ,   MIN(STMT_FIRST_USE_TIME)  AS STMT_FIRST_USE_TIME
        ,   MAX(STMT_LAST_USE_TIME)   AS STMT_LAST_USE_TIME
        ,   COUNT(*) AS ACTIVITIES
        FROM
            MON_LOCK_PARTICIPANT_ACTIVITIES A
        GROUP BY
            EVENT_ID, EVENT_TIMESTAMP, PARTICIPANT_NO,  MEMBER, PARTITION_KEY
        ,   EFFECTIVE_ISOLATION
        ,   ACTIVITY_TYPE
        ,   STMT_TEXT::VARCHAR(32000 OCTETS)
        ) A
    USING (EVENT_ID, EVENT_TIMESTAMP, PARTICIPANT_NO,  MEMBER, PARTITION_KEY )
