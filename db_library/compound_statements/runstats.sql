--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Runstats all selected tables
 * 
 */

BEGIN
    DECLARE LOAD_PENDING CONDITION FOR SQLSTATE '57016';    -- Skip LOAD pending tables 
    DECLARE NOT_ALLOWED  CONDITION FOR SQLSTATE '57007';    -- Skip Set Integrity Pending  tables  I.e. SQL0668N Operation not allowed
    DECLARE UNDEFINED_NAME CONDITION FOR SQLSTATE '42704';  -- Skip tables that no longer exist/not commited
    DECLARE CONTINUE HANDLER FOR LOAD_PENDING, NOT_ALLOWED, UNDEFINED_NAME BEGIN END;
--
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            TABSCHEMA
        ,   TABNAME
        ,   'CALL ADMIN_CMD(''RUNSTATS ON TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" '
            || CASE WHEN STATISTICS_PROFILE IS NOT NULL THEN 'USE PROFILE' 
                ELSE 'WITH DISTRIBUTION' || CASE WHEN TYPE IN ('S','T') THEN ' AND SAMPLED DETAILED INDEXES ALL'  ELSE '' END
        --          || CASE WHEN CARD * COLCOUNT > 10000000000 THEN ' TABLESAMPLE SYSTEM (1) ' END
                 END 
            || ''')' AS RUNSTATS
        ,   T.STATS_TIME
        ,   T.STATISTICS_PROFILE
        ,   T.CARD
        FROM
            SYSCAT.TABLES T
        WHERE
            ( TYPE IN ('S','T')  OR  ( T.TYPE = 'V' AND SUBSTR(T.PROPERTY,13,1) = 'Y' ) )
        AND TABSCHEMA LIKE 'DB%'
        ORDER BY 
            TABSCHEMA
        ,   TABNAME
        WITH UR
    DO
          EXECUTE IMMEDIATE C.RUNSTATS;
          COMMIT;
    END FOR;
END
@
