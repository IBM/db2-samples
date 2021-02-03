--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows any queries in the package cache that have been queue do to WLM concurrency limits 
 * 
*/

CREATE OR REPLACE VIEW DB_WLM_QUEUED_STATEMENTS AS
SELECT
    WLM_QUEUE_TIME_TOTAL
,   WLM_QUEUE_ASSIGNMENTS_TOTAL
,   NUM_EXECUTIONS
,   COORD_STMT_EXEC_TIME
,   QUERY_COST_ESTIMATE
,   STMT_TEXT
FROM
       TABLE(MON_GET_PKG_CACHE_STMT(NULL,NULL,NULL,-2))
WHERE
    WLM_QUEUE_TIME_TOTAL > 0
    