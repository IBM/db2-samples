--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows all current locks and lock requests on the system along with the SQL Statement holding or requesting the lock
 */

CREATE OR REPLACE VIEW DB_LOCK_STATEMENTS AS
SELECT 
    A.STMT_TEXT
,   L.*
FROM
(
    SELECT 
        T.TABSCHEMA
    ,   T.TABNAME
    ,   L.LOCK_OBJECT_TYPE     AS TYPE
    ,   L.LOCK_MODE            AS MODE
    ,   L.LOCK_STATUS          AS STATUS
    ,   SUM(L.LOCK_COUNT)      AS LOCKS
    ,   SUM(L.LOCK_HOLD_COUNT) AS WITH_HOLD     --The number of holds placed on the lock. Holds are placed on locks by cursors registered with the WITH HOLD clause and some utilities. Locks with holds are not released when transactions are committed. 
    ,   C.APPLICATION_NAME   
    ,   C.SYSTEM_AUTH_ID     AS AUTH_ID
    ,   C.CONNECTION_START_TIME
    ,   C.APPLICATION_HANDLE
    ,   'SELECT ''CALL WLM_CANCEL_ACTIVITY( '  || C.APPLICATION_HANDLE || ','' || UOW_ID || '','' || ACTIVITY_ID || '')'' FROM TABLE(MON_GET_ACTIVITY(' || C.APPLICATION_HANDLE || ',-2))' 
                                                                                        AS GEN_CANCEL_ACTIVITY_STMT
    ,   'CALL ADMIN_CMD(''FORCE APPLICATION ( ' || C.APPLICATION_HANDLE || ' )'')'      AS FORCE_STATMET
    FROM
        TABLE(MON_GET_LOCKS(NULL,-2 )) L
    LEFT JOIN 
        TABLE(MON_GET_CONNECTION(NULL,-2)) C USING (APPLICATION_HANDLE, MEMBER )
    LEFT JOIN 
        SYSCAT.TABLES T 
    ON 
        L.TBSP_ID = T.TBSPACEID AND L.TAB_FILE_ID = T.TABLEID 
    GROUP BY
        T.TABSCHEMA
    ,   T.TABNAME
    ,   C.APPLICATION_NAME
    ,   C.SYSTEM_AUTH_ID
    ,   C.CONNECTION_START_TIME
    ,   L.TBSP_ID
    ,   L.TAB_FILE_ID
    ,   L.LOCK_OBJECT_TYPE
    ,   L.LOCK_MODE
    ,   L.LOCK_STATUS
    ,   C.APPLICATION_HANDLE
) L
LEFT JOIN
    ( SELECT * FROM TABLE(MON_GET_ACTIVITY(NULL,-2)) WHERE MEMBER = COORD_PARTITION_NUM ) AS A
USING
    ( APPLICATION_HANDLE )

