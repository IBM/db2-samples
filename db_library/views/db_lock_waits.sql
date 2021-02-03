--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows applications that are waiting on locks
 */

CREATE OR REPLACE VIEW DB_LOCK_WAITS AS
SELECT
    L.*
,   'call admin_cmd(''force application (' || HLD_APPLICATION_HANDLE || ')'')' AS FORCE_BLOCKER_APPLICATION_STMT 
FROM
    SYSIBMADM.MON_LOCKWAITS L