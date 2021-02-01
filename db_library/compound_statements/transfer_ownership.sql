--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Code to TRANSFER OWNERSHIP all objects owned by USERA to USERB
 * 
 * Note that the code below does not transfer wonership of implicitly created schema objects.
 *   I.e. ones that have SYSIBM in the OWNER column and do not have SYSIBM in the DEFINER column.
 * 
 * You could transfer those if you wish with e.g.

SELECT 'TRANSFER OWNERSHIP OF SCHEMA "' || SCHEMANAME || '" TO NEW_USER' FROM SYSCAT.SCHEMATA WHERE OWNER ='SYSIBM' AND DEFINER <> 'SYSIBM'

 * Aslo, as per https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.sql.ref.doc/doc/r0021665.html
 * 
 * Ownership of the following objects cannot be explicitly transferred (SQLSTATE 429BT):
 *
 * - Subtables in a table hierarchy (they are transferred with the root hierarchy table)
 * - Subviews in a view hierarchy (they are transferred with the root hierarchy view)
 * - Indexes that are defined on global temporary tables
 * - Methods or functions that are implicitly generated when a user-defined type is created
 * - Module aliases and modules
 * - Packages that depend on SQL procedures (they are transferred with the SQL procedure)
 * - Event monitors that are active (they can be transferred when they are not active)
 * -
 */

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            OWNER            AS AUTHID
        ,   OWNERTYPE        AS AUTHIDTYPE
        ,   'OWNER'          AS PRIVILEGE
        ,   'N'              AS GRANTABLE
        ,   OBJECTNAME
        ,   OBJECTSCHEMA
        ,   OBJECTTYPE
        ,   'TRANSFER OWNERSHIP OF ' || REPLACE(REPLACE(OBJECTTYPE, 'CREATED TEMPORARY',''),'DB2 PACKAGE','PACKAGE') || ' '
            || ' "' || OBJECTSCHEMA ||  '"."' || OBJECTNAME ||  '"' || ' TO USER '
            || 'USERB'    -- <<-- Set TO user HERE
            || ' PRESERVE PRIVILEGES ' 
             AS TRANSFER_STMT
        FROM 
            SYSIBMADM.OBJECTOWNERS
        WHERE
            OWNER <> 'SYSIBM'
        AND OWNER = 'USERA'       -- <<--Select the users to transfer object from here
        AND OBJECTSCHEMA NOT LIKE 'SYS%' -- Ownership of schemas whose name starts with 'SYS' cannot be transferred (SQLSTATE 42832).
        ORDER BY
            OBJECTNAME
        ,   OBJECTSCHEMA
        ,   OBJECTTYPE
    DO
        EXECUTE IMMEDIATE C.TRANSFER_STMT;
        COMMIT;
    END FOR;
END
 