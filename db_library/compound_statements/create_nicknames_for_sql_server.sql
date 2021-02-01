--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Create Nicknames for a remote source by reading the remote catalog and creating a nickname for each entry found
 * 
 * This example is for a SQL Server remote database
 * 
 */

-- Requires a SERVER and a NICKNAME to the remote TABLES catalog view.  E.g.
CREATE SERVER "dbo" TYPE MSSQL_ODBC VERSION '7.1'  
OPTIONS ( DBNAME  'somedbname', HOST 'somehostname.eastus.cloudapp.azure.com', PORT '1433' )
@
CREATE NICKNAME "dbo"."TABLES"                  FOR "dbo"."INFORMATION_SCHEMA"."TABLES"
@

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'CREATE NICKNAME ' || TABLE_CATALOG ||                           '."' || TABLE_NAME || '"'
                   ||     ' FOR ' || TABLE_CATALOG || '."' || TABLE_SCHEMA  || '"."' || TABLE_NAME || '"'
            AS STMT
        FROM
            "dbo"."TABLES"          -- Nickname to SQL Server remote catalog  (can't use thre part names in compound SQL
        WHERE ( TABLE_CATALOG, TABLE_NAME ) NOT IN ( SELECT TABSCHEMA, TABNAME FROM SYSCAT.TABLES )
        ORDER BY 
            TABLE_CATALOG
        ,   TABLE_NAME
        WITH UR
    DO
          EXECUTE IMMEDIATE VARCHAR(C.STMT,4000);
          COMMIT;
    END FOR;
END
