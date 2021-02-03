--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generates statements to clean up any failed ADMIN_MOVE_TABLE jobs
 */

CREATE OR REPLACE VIEW DB_ADMIN_MOVE_TABLE_CANCEL AS
/* Also see http://www-01.ibm.com/support/docview.wss?uid=swg21672377  if an ADMIN_MOVE_TABLE with CANCEL option fails
*/
SELECT 'CALL ADMIN_MOVE_TABLE (''' || TABSCHEMA || ''',''' || TABNAME || ''','''','''','''','''','''','''','''','''',''CANCEL'')' AS STMT
FROM
    SYSTOOLS.ADMIN_MOVE_TABLE
WHERE 
    KEY = 'STATUS'
AND VALUE <> 'COMPLETE'