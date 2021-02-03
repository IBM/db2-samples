--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * A Procedure to look for and take any tables out of LOAD PENDING
 * 
 * Call for a given schema, or with no parameter for all schemas 
 */

CREATE OR REPLACE PROCEDURE DB_FIX_LOAD_PENDING(IN I_TABSCHEMA VARCHAR(128) DEFAULT NULL)
LANGUAGE SQL
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT DISTINCT
            'LOAD FROM (VALUES 1) OF CURSOR TERMINATE INTO "' || TABSCHEMA || '"."' || TABNAME || '"'   AS CMD
        FROM
            TABLE(ADMIN_GET_TAB_INFO(I_TABSCHEMA, NULL))
        WHERE
            LOAD_STATUS = 'PENDING'
        AND TABSCHEMA NOT IN ('SYSIBM')
        WITH UR
    DO
        CALL ADMIN_CMD( C.CMD );
        CALL DBMS_OUTPUT.PUT_LINE(C.CMD);
    END FOR;
END
