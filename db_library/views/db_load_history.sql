--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Show history of LOAD operations from the database history file
 */

CREATE OR REPLACE VIEW DB_LOAD_HISTORY AS
SELECT
    MIN(START_TIMESTAMP) AS START_TIMESTAMP    
,   MAX(END_TIMESTAMP)   AS END_TIMESTAMP
,   TABSCHEMA
,   TABNAME
,   LOAD_MODE
,   COMMAND
,   MIN(SQLCODE)         AS MIN_SQLCODE
,   MAX(SQLCODE)         AS MAX_SQLCODE
,   COUNT(*)             AS MEMBERS
FROM
(
    SELECT 
--    DBPARTITIONNUM
    --,   EID
        TIMESTAMP(START_TIME,0)  AS START_TIMESTAMP
    --,   SEQNUM
    ,   TIMESTAMP(END_TIME,0)    AS END_TIMESTAMP
    --,   NUM_LOG_ELEMS
    --,   FIRSTLOG
    --,   LASTLOG
    --,   BACKUP_ID
    ,   TABSCHEMA
    ,   TABNAME
    --,   COMMENT
    ,   VARCHAR(REGEXP_REPLACE(CMD_TEXT,'NODE[0-9]+','NODExxxx'),4000) AS COMMAND
    --,   NUM_TBSPS
    --,   TBSPNAMES
    --,   OPERATION
    ,   CASE OPERATIONTYPE WHEN 'I' THEN 'INSERT' WHEN 'R' THEN 'REPLACE' END AS LOAD_MODE
    --,   OBJECTTYPE
    --,   LOCATION
    --,   DEVICETYPE
    --,   ENTRY_STATUS
    --,   SQLCAID
    --,   SQLCABC
    ,   SQLCODE
    --,   SQLERRML
    --,   SQLERRMC
    --,   SQLERRP
    --,   SQLERRD1
    --,   SQLERRD2
    --,   SQLERRD3
    --,   SQLERRD4
    --,   SQLERRD5
    --,   SQLERRD6
    --,   SQLWARN
    --,   SQLSTATE
    FROM
        SYSIBMADM.DB_HISTORY
    WHERE
        OPERATION = 'L'
)
GROUP BY
    COMMAND
,   TABSCHEMA
,   TABNAME
,   LOAD_MODE
