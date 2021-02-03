--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * For all tables in LOAD PENDING state, TERMINATE their outstanding LOAD command
 * 
 * Note that this code also skips past any tables that are currently being LOADed to avoid getting a lock wait on the call to ADMIN_GET_TAB_INFO
 */

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        WITH L AS (
            SELECT
                *
            FROM
                TABLE(MON_GET_UTILITY(-2))
            WHERE
                OBJECT_TYPE = 'TABLE'
            AND UTILITY_TYPE = 'LOAD'
            AND UTILITY_DETAIL NOT LIKE '%ONLINE LOAD%' 
        )
        SELECT
            'LOAD FROM (VALUES 1) OF CURSOR TERMINATE INTO "' || T.TABSCHEMA || '"."' || T.TABNAME || '"'   AS CMD
        ,   T.TABSCHEMA
        ,   T.TABNAME
        FROM
            SYSCAT.TABLES  T
        ,   TABLE(ADMIN_GET_TAB_INFO( T.TABSCHEMA, T.TABNAME)) AS I
        WHERE
            T.TABSCHEMA = I.TABSCHEMA
        AND T.TABNAME   = I.TABNAME
        AND ( T.TABSCHEMA, T.TABNAME ) NOT IN (SELECT OBJECT_SCHEMA, OBJECT_NAME FROM L)
        AND T.TABSCHEMA <> 'SYSIBM'     -- exclude synopsis tables
        AND I.LOAD_STATUS = 'PENDING'       
        GROUP BY 
            T.TABSCHEMA
        ,   T.TABNAME
        ORDER BY 
            T.TABSCHEMA
        ,   T.TABNAME
        WITH UR
    DO
        CALL ADMIN_CMD( C.CMD ) ;
        COMMIT;
    END FOR;
END