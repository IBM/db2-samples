--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generate runstats commands
 * 
 * TO-DO - add a sensible sampleing default based on #rows * # columns
 */

CREATE OR REPLACE VIEW DB_RUNSTATS AS
SELECT  T.TABSCHEMA
,       T.TABNAME
,       'CALL ADMIN_CMD(''RUNSTATS ON TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" '
        || CASE WHEN STATISTICS_PROFILE IS NOT NULL THEN 'USE PROFILE' 
             ELSE 'WITH DISTRIBUTION AND SAMPLED DETAILED INDEXES ALL' 
--             || CASE WHEN CARD * COLCOUNT > 10000000000 THEN ' TABLESAMPLE SYSTEM (1) ' END
             END 
        || '''' AS RUNSTATS
,       T.STATS_TIME
,       T.STATISTICS_PROFILE
,       T.CARD
FROM
    SYSCAT.TABLES T
WHERE
        TYPE IN ('S','T')
OR  (   T.TYPE = 'V' AND SUBSTR(T.PROPERTY,13,1) = 'Y' )