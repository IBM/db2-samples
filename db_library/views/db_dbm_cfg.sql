--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows current database manager configuration parameter values
 */

CREATE OR REPLACE VIEW DB_DBM_CFG AS
SELECT
       UPPER(NAME)      AS NAME
,      CASE WHEN VALUE_FLAGS = 'NONE' THEN '' ELSE VALUE_FLAGS END AS METHOD
,      VALUE
,      CASE WHEN NAME in ('cf_mem_sz','instance_memory','java_heap_sz' )
         THEN DECIMAL(VALUE*4/1024,11,2) END AS SIZE_MB
,      CASE WHEN VALUE <> DEFERRED_VALUE THEN SUBSTR(DEFERRED_VALUE,1,15) ELSE '' END AS DEFERRED_VAL    
,      'call admin_cmd(''UPDATE DBM CFG USING ' || UPPER(NAME) || ' ' || COALESCE(VALUE,'') 
       || CASE WHEN VALUE_FLAGS = 'AUTOMATIC' THEN ' AUTOMATIC ' ELSE '' END || ' IMMEDIATE'');' AS UPDATE_STMT
FROM
(
	SELECT 
	    NAME
	,   VALUE
	,   VALUE_FLAGS
	,   DEFERRED_VALUE
	,   DEFERRED_VALUE_FLAGS
	,   DATATYPE
	FROM
	    SYSIBMADM.DBMCFG
	GROUP BY
	    NAME
	,   VALUE
	,   VALUE_FLAGS
	,   DEFERRED_VALUE
	,   DEFERRED_VALUE_FLAGS
	,   DATATYPE
)
