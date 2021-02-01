--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows all current locks on the system (run WITH UR)
 */

CREATE OR REPLACE VIEW DB_LOCKS AS
SELECT 
    T.TABSCHEMA
,   T.TABNAME
,   LOCK_OBJECT_TYPE     AS TYPE
,   LOCK_MODE            AS MODE
,   LOCK_STATUS          AS STATUS
,   SUM(LOCK_COUNT)      AS LOCKS
,   SUM(LOCK_HOLD_COUNT) AS WITH_HOLD     --The number of holds placed on the lock. Holds are placed on locks by cursors registered with the WITH HOLD clause and some utilities. Locks with holds are not released when transactions are committed. 
,   A.APPLICATION_NAME   
,   A.SYSTEM_AUTH_ID     AS AUTH_ID
,   A.CONNECTION_START_TIME
,   A.APPLICATION_HANDLE
,   'SELECT ''CALL WLM_CANCEL_ACTIVITY( ' || A.APPLICATION_HANDLE || ','' || UOW_ID || '','' || ACTIVITY_ID || '')'' FROM TABLE(MON_GET_ACTIVITY(' || A.APPLICATION_HANDLE || ',-2))' 
                                                                                    AS GEN_CANCEL_ACTIVITY_STMT
,   'CALL ADMIN_CMD(''FORCE APPLICATION ( ' || A.APPLICATION_HANDLE || ' )'')'      AS FORCE_STATMET
FROM
    TABLE(MON_GET_LOCKS(NULL,-2 )) L
LEFT JOIN 
    TABLE(MON_GET_CONNECTION(NULL,-2)) A USING (APPLICATION_HANDLE, MEMBER )
LEFT JOIN 
    SYSCAT.TABLES T 
ON 
    L.TBSP_ID = T.TBSPACEID AND L.TAB_FILE_ID = T.TABLEID 
GROUP BY
    T.TABSCHEMA
,   T.TABNAME
,   A.APPLICATION_NAME
,   A.SYSTEM_AUTH_ID
,   A.CONNECTION_START_TIME
,   SYSTEM_AUTH_ID
,   CONNECTION_START_TIME
,   TBSP_ID
,   TAB_FILE_ID
,   LOCK_OBJECT_TYPE
,   LOCK_MODE
,   LOCK_STATUS
,   A.APPLICATION_HANDLE
