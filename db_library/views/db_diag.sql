--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows records from Db2's diag.log file(s)
 * 
 * Note that Global Variables are used to set the time range of records returned, and from which database member
 *   These defualt to showing entires for the current date
 * If you need a different time range, set the variables like this
 *
 *   SET DB.DB_DIAG_FROM_TIMESTAMP = CURRENT_DATE - 7 DAYS      -- defaults to today
 *   SET DB.DB_DIAG_TO_TIMESTAMP   = CURRENT_TEIMSTAMP
 *   SET DB.DB_DIAG_MEMBER INTEGER = 0                          -- defaults to all members (-2)
 * 
 * Note that some diag.log entries don't populate the MSG column.
 *   For those, this view attempts to pull relevent message from the FULLREC
 * 
 */

CREATE OR REPLACE VIEW DB_DIAG AS
SELECT 
    TIMESTAMP
,   TIMEZONE
,   DBPARTITIONNUM      AS MEMBER
,   COALESCE(LEVEL,'')  AS LEVEL
,   COALESCE(IMPACT,'') AS IMPACT
,   COALESCE(MSG,REGEXP_SUBSTR(FULLREC,'((MESSAGE :)|( sqlerrmc: )|(Received sqlcode -)|(sqlcode: )|(sqluMCReadFromDevice)|(Skipping database))|(sqlsGet955DiagMessage).*')) 
        AS MSG
,   AUTH_ID 
,   FULLREC
,   RECTYPE
,   PID
,   TID
FROM TABLE(PD_GET_DIAG_HIST('MAIN', 'ALL','',DB_DIAG_FROM_TIMESTAMP,DB_DIAG_TO_TIMESTAMP,DB_DIAG_MEMBER))
