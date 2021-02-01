--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows STMM and manual memory area changes from the db2diag.log. Set the DB_DIAG_FROM_TIMESTAMP variable to see data before today
 */

CREATE OR REPLACE VIEW DB_MEMORY_CHANGE_HISTORY AS
SELECT
    TIMESTAMP
,   MEMBER
,   MESSAGE
,   REGEXP_SUBSTR(MESSAGE,'[^"]*"([^"]*)"',1,1,'',1)::VARCHAR(128) AS NAME
,   REGEXP_SUBSTR(MESSAGE,'From:\s+"([0-9]+)"',1,1,'',1)::VARCHAR(128) AS FROM_VALUE
,   REGEXP_SUBSTR(MESSAGE,'To:\s+"([0-9]+)"',1,1,'',1)::VARCHAR(128)   AS TO_VALUE
,   AUTH_ID
,   EDUNAME
,   FUNCTION
FROM
(
    SELECT 
        REGEXP_REPLACE(
            COALESCE(
                MSG
            ,   REGEXP_SUBSTR(FULLREC,'CHANGE  : (.*)',1,1,'',1)
            ),'[\s]+',' ')::VARCHAR(256)   AS MESSAGE
    ,   T.*
    FROM
        TABLE(PD_GET_DIAG_HIST('MAIN', 'ALL','',DB_DIAG_FROM_TIMESTAMP,DB_DIAG_TO_TIMESTAMP,DB_DIAG_MEMBER)) T
    )
WHERE
    FUNCTION IN ('sqlbAlterBufferPoolAct','sqlfLogUpdateCfgParam')
