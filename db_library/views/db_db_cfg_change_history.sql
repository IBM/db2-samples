--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows database configuration changes from the db2diag.log. 
 */

CREATE OR REPLACE VIEW DB_DB_CFG_CHANGE_HISTORY AS
SELECT
    TIMESTAMP
,   MEMBER
,   REGEXP_SUBSTR(MESSAGE,'[^"]*"([^"]*)"',1,1,'',1)::VARCHAR(128)        AS NAME
,   REGEXP_SUBSTR(MESSAGE,'From:\s+"\-?([0-9]+)"',1,1,'',1)::VARCHAR(128) AS FROM_VALUE
,   REGEXP_SUBSTR(MESSAGE,'To:\s+"\-?([0-9]+)"',1,1,'',1)::VARCHAR(128)   AS TO_VALUE
,   AUTH_ID
,   EDUNAME
--,   MESSAGE
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
        TABLE(PD_GET_DIAG_HIST('MAIN', 'EI','',NULL,NULL,-2)) T
    )
WHERE
    FUNCTION IN ('sqlfLogUpdateCfgParam')
--AND     EDUNAME NOT LIKE 'db2stmm%'     -- filter out Self Tuning entries
--ORDER BY 
--    TIMESTAMP, MEMBER   DESC
