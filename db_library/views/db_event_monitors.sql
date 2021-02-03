--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists for all event monitors on the database
 */

CREATE OR REPLACE VIEW DB_EVENT_MONITORS AS 
SELECT
    EVMONNAME
,   TARGET_TYPE
,   OWNER
,   AUTOSTART
,   CASE    EVENT_MON_STATE(EVMONNAME)
            WHEN 0 THEN '0 - Inactive'
            WHEN 1 THEN '1 - Active'
    END                                     AS STATE
,   'SET EVENT MONITOR ' || EVMONNAME || ' STATE ' || CHAR(1 - EVENT_MON_STATE(EVMONNAME))
                                              AS SWITCH_STATE_STMT
FROM
     SYSCAT.EVENTMONITORS M