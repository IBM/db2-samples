--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows tops sort consuming statements from the package cache
 */

CREATE OR REPLACE VIEW DB_SORTS_STATEMENT AS
SELECT * FROM (
SELECT
    CAST(STMT_TEXT AS VARCHAR(4000 OCTETS))                          AS STMT_TEXT
,   MAX(SORT_SHRHEAP_TOP)                                            AS SHRHEAP_TOP
,   MAX(ESTIMATED_SORT_SHRHEAP_TOP)                                  AS EST_SHRHEAP_TOP
,   MAX(SORT_CONSUMER_SHRHEAP_TOP)                                   AS MAX_CONSUMER
,   SUM(TOTAL_SORTS + TOTAL_HASH_JOINS + TOTAL_HASH_GRPBYS)          AS CONSUMERS
,   SUM(SORT_OVERFLOWS + HASH_JOIN_OVERFLOWS + HASH_GRPBY_OVERFLOWS) AS OVERFLOWS
FROM
    TABLE(MON_GET_PKG_CACHE_STMT(NULL, NULL, NULL, -2))
GROUP BY
    CAST(STMT_TEXT AS VARCHAR(4000 OCTETS))
ORDER BY
    SHRHEAP_TOP DESC
)