--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * List all views that are enabled for query optimization
 */

CREATE OR REPLACE VIEW DB_STATS_PROFILES AS
SELECT  T.TABSCHEMA
,       T.TABNAME
,       T.STATS_TIME
,       T.STATISTICS_PROFILE
,       T.CARD
FROM
    SYSCAT.TABLES T
WHERE
    STATISTICS_PROFILE IS NOT NULL
    