--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows current database configuration parameter values
 */

CREATE OR REPLACE VIEW DB_DB_CFG AS
SELECT
       SUBSTR(UPPER(NAME),1,20) AS NAME
,      CASE WHEN VALUE_FLAGS = 'NONE' THEN '' ELSE VALUE_FLAGS END AS METHOD
,      VALUE
,      CASE WHEN NAME in ('app_ctl_heap_sz', 'appgroup_mem_sz', 'appl_memory', 'applheapsz', 'catalogcache_sz'
                        ,'cf_db_mem_sz', 'cf_gbp_sz', 'cf_lock_sz', 'cf_sca_sz', 'database_memory', 'dbheap'
                        , 'hadr_spool_limit', 'groupheap_ratio', 'locklist', 'logbufsz', 'mon_pkglist_sz'
                        , 'pckcachesz', 'sheapthres_shr'
                        , 'sortheap', 'stat_heap_sz', 'stmtheap', 'util_heap_sz' )
         THEN DECIMAL(VALUE*4/1024,11,2) END AS SIZE_MB
,      CASE WHEN VALUE <> DEFERRED_VALUE THEN SUBSTR(DEFERRED_VALUE,1,15) ELSE '' END AS DEFERRED_VAL    
,       MEMBERS
,      'call admin_cmd(''UPDATE DB CFG USING ' || UPPER(NAME) || ' ' || COALESCE(VALUE,'') 
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
	,   MIN(MEMBER) AS MIN_MEMBER
	,   MAX(MEMBER) AS MAX_MEMBER
	,   LISTAGG(MEMBER,',') WITHIN GROUP (ORDER BY MEMBER)  AS MEMBERS
	,   COUNT(*)           AS MEMBER_COUNT
	,   COUNT(*) OVER()   AS ALL_MEMBER_COUNT
	FROM
	    SYSIBMADM.DBCFG
	GROUP BY
	    NAME
	,   VALUE
	,   VALUE_FLAGS
	,   DEFERRED_VALUE
	,   DEFERRED_VALUE_FLAGS
	,   DATATYPE
)
