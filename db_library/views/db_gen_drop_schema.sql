--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generate ADMIN_DROP_SCHEMA statements that you can then run to drop all objects in a schema and the schema
 */

 --Generate SQL command to drop all objects in the schema and drop the schema

CREATE OR REPLACE VIEW DB_GEN_DROP_SCHEMA AS
SELECT 
    SCHEMANAME
,   'CALL SYSPROC.ADMIN_DROP_SCHEMA(' || RTRIM(SCHEMANAME) || ', NULL, ''SYSTOOLS'', ''ADMIN_DROP_SCHEMA_ERROR_TABLE'')'  AS STMT
,   'SET DB_SYSTOOLS = ''SYSTOOLS'' ' || CHR(10) || CHR(10) || 'SET DB_ADMIN_DROP_SCHEMA = ''ADMIN_DROP_SCHEMA'''         AS SETUP_STMT
,   'DROP TABLE SYSTOOLS.ADMIN_DROP_SCHEMA'  AS CLEANUP_STMT
FROM
    SYSCAT.SCHEMATA