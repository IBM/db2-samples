--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Example of using the DB_PRIVILEGES view to revoke all access a user has in a schema
 * 
 * TO-DO more elgantly cater for revoking CONTROL PRIVILEGE
 */

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            REPLACE(REVOKE_STMT,'SOME_OTHER_USER','USER_TO_OWN_OBJECTS') AS REVOKE_STMT
        FROM
            DB.DB_PRIVILEGES 
        WHERE
            OBJECTSCHEMA = 'pick a schema'
        --  AND OBJECTNAME = 'A'
        AND AUTHID = 'pick a user'
        AND AUTHIDTYPE = 'U'
        ORDER BY
            OBJECTSCHEMA
        ,   OBJECTNAME
        ,   CASE WHEN PRIVILEGE = 'CONTROL' THEN ' first' ELSE PRIVILEGE END
        WITH UR
    DO
        EXECUTE IMMEDIATE C.REVOKE_STMT;
        COMMIT;
    END FOR;
END
 
