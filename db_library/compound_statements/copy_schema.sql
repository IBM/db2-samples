--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Copy all data from one schema to an new schema
 * 
 */

--## First copy the DDL with ADMIN_COPY_SCHEMA

---- Create variables as the last two parameters are IN/OUT params
CREATE OR REPLACE VARIABLE DB_ERROR_TABSCHEMA VARCHAR(128) DEFAULT 'BLUADMIN'                @
CREATE OR REPLACE VARIABLE DB_ERROR_TABNAME   VARCHAR(128) DEFAULT 'ADMIN_COPY_SCHEMA_ERROR' @

-- Drop error table is already eixsts (othewise ADMIN_COPY_SCHEMA will fail with a error)
SELECT * FROM BLUADMIN.ADMIN_COPY_SCHEMA_ERROR

----                            Edit your Schema Names here
CALL SYSPROC.ADMIN_COPY_SCHEMA('STAGING', 'STAGING_COPY', 'DDL', NULL, NULL, NULL, DB_ERROR_TABNAME, DB_ERROR_TABNAME)
@
-- Table only gets created if there were any errors
SELECT * FROM BLUADMIN.ADMIN_COPY_SCHEMA_ERROR
@

--## Now Copy the data in a loop, logging each copy to avoid re-copying the same table twice, and allowing the loop below to be re-runable
CREATE TABLE SCHEMA_COPY_LOG (
    TABSCHEMA  VARCHAR(128) NOT NULL
,   TABNAME    VARCHAR(128) NOT NULL
,   TO_SCHEMA  VARCHAR(128) NOT NULL
,   TS         TIMESTAMP    NOT NULL
--,   PRIMARY KEY (TABSCHEMA, TABNAME) ENFORCED
)
@
TRUNCATE TABLE  SCHEMA_COPY_LOG IMMEDIATE
@
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            RTRIM(TABSCHEMA)            AS TABSCHEMA 
        ,   RTRIM(TABSCHEMA) || '_COPY' AS TO_SCHEMA            --  Edit your TO schema name here
        ,   TABNAME
        FROM 
            SYSCAT.TABLES 
        WHERE TYPE = 'T' 
        AND   TABSCHEMA = 'STAGING'                             --  Edit your FROM schema name here
        AND   (TABSCHEMA, TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM SCHEMA_COPY_LOG)
        
    DO
          EXECUTE IMMEDIATE ('INSERT INTO "' || TO_SCHEMA || '"."' || TABNAME || '" SELECT * FROM "' || TABSCHEMA || '"."' || TABNAME || '"');
          INSERT INTO SCHEMA_COPY_LOG VALUES ( TABSCHEMA, TABNAME, TO_SCHEMA, CURRENT_TIMESTAMP);
          COMMIT;
    END FOR;
END
@
