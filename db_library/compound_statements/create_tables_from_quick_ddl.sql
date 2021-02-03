--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Example of using the DB_TABLE_QUICK_DDL view to copy table DDL into a new schema
 */

BEGIN
--    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;  -- Uncomment to ignore errors.
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
--          REPLACE(DDL,'IN "USERSPACE1"','') AS DDL
            VARCHAR(REPLACE(DDL,'"' || TABSCHEMA || '".','"NEW_SCHEMA".'),32000) AS DDL
        FROM
            DB.DB_TABLE_QUICK_DDL 
        WHERE
            ('NEW_SCHEMA', TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM SYSCAT.TABLES)
        AND TABSCHEMA = 'THE_SCHEMA'
        ORDER BY
            TABSCHEMA
        ,   TABNAME
        WITH UR
    DO
        EXECUTE IMMEDIATE C.DDL;
        COMMIT;
    END FOR;
END
