--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns any lock escalation messages from the diag.log. Set the DB_DIAG_FROM_TIMESTAMP variable to see data before today
 */

CREATE OR REPLACE VIEW DB_LOCK_ESCALATIONS AS
SELECT
    TIMESTAMP
,   TIMEZONE
,   MEMBER
,   DBNAME
,   PID
,   SUBSTR(MSG,1,1024) MSG
FROM 
    TABLE(PD_GET_DIAG_HIST( 'MAIN', 'DX','', DB_DIAG_FROM_TIMESTAMP, DB_DIAG_TO_TIMESTAMP, DB_DIAG_MEMBER ))
WHERE FUNCTION = 'sqldEscalateLocks'