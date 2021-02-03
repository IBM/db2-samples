--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Create Nicknames for the catalog views of all remote SQL servers registered in Db2
 *
 */

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'CREATE NICKNAME ' || SERVERNAME ||                           '."' || TABLE_NAME || '"'
                   ||     ' FOR ' || SERVERNAME || '."' || TABLE_SCHEMA  || '"."' || TABLE_NAME || '"'
            AS STMT
        FROM
            SYSCAT.SERVERS
        ,   TABLE(VALUES
                  ('INFORMATION_SCHEMA','CHECK_CONSTRAINTS' )
                , ('INFORMATION_SCHEMA','COLUMNS' )
                , ('INFORMATION_SCHEMA','COLUMN_DOMAIN_USAGE' )
                , ('INFORMATION_SCHEMA','CONSTRAINT_COLUMN_USAGE' )
                , ('INFORMATION_SCHEMA','CONSTRAINT_TABLE_USAGE' )
                , ('INFORMATION_SCHEMA','DOMAINS' )
                , ('INFORMATION_SCHEMA','DOMAIN_CONSTRAINTS' )
                , ('INFORMATION_SCHEMA','KEY_COLUMN_USAGE' )
                , ('INFORMATION_SCHEMA','COLUMN_PRIVILEGES' )
                , ('INFORMATION_SCHEMA','PARAMETERS' )
                , ('INFORMATION_SCHEMA','ROUTINES' )
                , ('INFORMATION_SCHEMA','ROUTINE_COLUMNS' )
--                , ('INFORMATION_SCHEMA','SEQUENCES' )               -- fails due to sql_variant column
                , ('INFORMATION_SCHEMA','TABLE_PRIVILEGES' )
                , ('INFORMATION_SCHEMA','VIEW_COLUMN_USAGE' )
                , ('INFORMATION_SCHEMA','VIEW_TABLE_USAGE' )
                , ('INFORMATION_SCHEMA','REFERENTIAL_CONSTRAINTS' )
                , ('INFORMATION_SCHEMA','SCHEMATA' )
                , ('INFORMATION_SCHEMA','TABLES' )
                , ('INFORMATION_SCHEMA','TABLE_CONSTRAINTS' )
                , ('INFORMATION_SCHEMA','VIEWS')
            ) AS (TABLE_SCHEMA, TABLE_NAME )
        WHERE 
            SERVERTYPE LIKE 'MSSQL%'
        AND ( SERVERNAME, TABLE_NAME ) NOT IN ( SELECT TABSCHEMA, TABNAME FROM SYSCAT.TABLES )
        ORDER BY 
            SERVERNAME
        ,   TABLE_NAME
        WITH UR
    DO
          EXECUTE IMMEDIATE VARCHAR(C.STMT,4000);
          COMMIT;
    END FOR;
END
