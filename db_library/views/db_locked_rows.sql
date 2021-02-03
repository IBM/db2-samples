--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all rows locks on the system, and generates SQL to SELECT the locked row(s).
 */

CREATE OR REPLACE VIEW DB_LOCKED_ROWS AS
SELECT 
    F.TABSCHEMA
,   F.TABNAME
,   F.TBSP_NAME
,   COALESCE(F.RID,F.TSNID) AS RID
,   'SELECT * FROM "' || F.TABSCHEMA  || '"."' || F.TABNAME || '" AS T'
    || ' WHERE RID(T) = ' || COALESCE(F.RID,F.TSNID)
    || ' AND DATASLICEID = '  || F.DATA_PARTITION_ID
    ||' WITH UR' AS SELECT_LOCKED_ROW
,   L.LOCK_MODE            AS MODE
,   L.LOCK_STATUS          AS STATUS
,   L.LOCK_COUNT           AS LOCKS
,   L.LOCK_HOLD_COUNT      AS WITH_HOLD     --The number of holds placed on the lock. Holds are placed on locks by cursors registered with the WITH HOLD clause and some utilities. Locks with holds are not released when transactions are committed. 
,   A.APPLICATION_NAME   
,   A.SYSTEM_AUTH_ID     AS AUTH_ID
,   A.CONNECTION_START_TIME
,   A.APPLICATION_HANDLE
,   'SELECT ''CALL WLM_CANCEL_ACTIVITY( ' || A.APPLICATION_HANDLE || ','' || UOW_ID || '','' || ACTIVITY_ID || '')'' FROM TABLE(MON_GET_ACTIVITY(' || A.APPLICATION_HANDLE || ',-2))' 
                                                                                    AS GEN_CANCEL_ACTIVITY_STMT
,   'CALL ADMIN_CMD(''FORCE APPLICATION ( ' || A.APPLICATION_HANDLE || ' )'')'      AS FORCE_STATMET
,   L.LOCK_NAME
FROM
    TABLE(MON_GET_LOCKS(NULL,-2 )) L
LEFT JOIN 
    TABLE(MON_GET_CONNECTION(NULL,-2)) A USING (APPLICATION_HANDLE, MEMBER )
JOIN
    LATERAL(SELECT
             MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),48)
           + MAX(CASE WHEN NAME = 'PAGEID'            THEN BIGINT(VALUE) ELSE 0 END) * power(bigint(2),16) 
           + MAX(CASE WHEN NAME = 'ROWID'             THEN BIGINT(VALUE) END)   AS RID
    ,   MAX(CASE WHEN NAME = 'DATA_PARTITION_ID' THEN INT(VALUE) ELSE 0 END)    AS DATA_PARTITION_ID
    ,   MAX(CASE WHEN NAME = 'TABSCHEMA' THEN RTRIM(VALUE) ELSE '' END)         AS TABSCHEMA
    ,   MAX(CASE WHEN NAME = 'TABNAME'   THEN       VALUE  ELSE '' END)         AS TABNAME
    ,   MAX(CASE WHEN NAME = 'TBSP_NAME' THEN       VALUE  ELSE '' END)         AS TBSP_NAME
    ,   MAX(CASE WHEN NAME = 'TSNID'     THEN BIGINT(VALUE)  ELSE -1 END)       AS TSNID
    FROM
        TABLE(MON_FORMAT_LOCK_NAME(L.LOCK_NAME)) F
    ) F
ON 1=1
WHERE 
    L.LOCK_OBJECT_TYPE = 'ROW'
