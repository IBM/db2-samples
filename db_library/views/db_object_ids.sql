--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Find object by tbspace-id and object-id for error messages such as SQL1477N that return object id in error
 */

CREATE OR REPLACE VIEW DB_OBJECT_IDS AS
	SELECT
	    TBSPACEID
	,   TABLEID             AS OBJECT_ID
    ,   'TABLE'             AS OBJECT_CLASS
	,   TYPE                AS OBJECT_TYPE
	,   TABSCHEMA           AS OBJECT_SCHEMA
	,   TABNAME             AS OBJECT_NAME
	FROM
	    SYSCAT.TABLES
UNION ALL 
    SELECT
        TBSPACEID
    ,   INDEX_OBJECTID      AS OBJECT_ID    
    ,   'INDEX'             AS OBJECT_CLASS 
    ,   INDEXTYPE           AS OBJECT_TYPE  
    ,   INDSCHEMA           AS OBJECT_SCHEMA
    ,   INDNAME             AS OBJECT_NAME  
    FROM
        SYSCAT.INDEXES
UNION ALL
    SELECT
        TBSPACEID
    ,   PARTITIONOBJECTID   AS OBJECT_ID    
    ,   'DATA PARTITION'    AS OBJECT_CLASS 
    ,   'RANGE'             AS OBJECT_TYPE  
    ,   DATAPARTITIONNAME   AS OBJECT_SCHEMA
    ,   TABNAME             AS OBJECT_NAME  
    FROM
        SYSCAT.DATAPARTITIONS
UNION ALL
SELECT
    TBSP_ID                 AS OBJECT_ID    
,   TAB_FILE_ID             AS OBJECT_CLASS 
,   'TEMP TABLE'            AS OBJECT_TYPE  
,   TEMPTABTYPE             AS OBJECT_SCHEMA
,   TABSCHEMA               AS OBJECT_NAME  
,   TABNAME                 
FROM
    SYSIBMADM.ADMINTEMPTABLES
