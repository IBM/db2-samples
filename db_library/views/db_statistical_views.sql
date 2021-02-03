--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * List all views that are enabled for query optimization
 */

CREATE OR REPLACE VIEW DB_STATISTICAL_VIEWS AS
SELECT  V.VIEWSCHEMA
,       V.VIEWNAME
,       T.STATS_TIME
,       T.STATISTICS_PROFILE
,       T.CARD
,       V.TEXT        AS DDL
FROM
    SYSCAT.VIEWS  V
INNER JOIN
    SYSCAT.TABLES T
ON
    T.TABSCHEMA = V.VIEWSCHEMA 
AND T.TABNAME   = V.VIEWNAME
AND T.TYPE = 'V'
AND SUBSTR(T.PROPERTY,13,1) = 'Y'