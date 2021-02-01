--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Shows config parameters relevant for BLU in DB2 10.5/11.1/11.5.0.1 and attempts to compare against best practice guidelines
 */

CREATE OR REPLACE VIEW DB_BEST_PRACTICE_BLU_CFG AS
WITH BP_BLU_CFG ( CFG_NAME, BP_VALUE, BP_MIN_VALUE, BP_MAX_VALUE, BP_COMMENT) AS ( values
    ( 'dft_table_org'      ,'COLUMN'    ,   NULL, NULL, 'Should be COLUMN' )
,   ( 'pagesize'           ,'32768'     ,   NULL, NULL, 'Should be 32K')
,   ( 'dft_extent_sz'      ,'4'         ,   NULL, NULL, 'Should be 4 pages' )
,   ( 'dft_degree'         ,'-1'        ,   NULL, NULL, 'Should be set to ANY (-1)' )
,   ( 'catalogcache_sz'    ,''          ,   NULL, NULL, 'Should be set to a value that is higher than the default (maxappls*5)')
,   ( 'maxappls'           ,'AUTOMATIC' ,   NULL, NULL, 'catalogcache_sz should be at least 5 times this value')
,   ( 'self_tuning_mem'    ,'OFF'       ,   NULL, NULL, 'Can be OFF or ON. Typically OFF')
,   ( 'sortheap'           ,NULL        ,      5,   20, 'Should be  5-20% of the value of the SHEAPTHRES_SHR parameter.')
,   ( 'sheapthres_shr'     ,NULL        ,     39,   50, 'Should be 39-50% of DATABASE_MEMORY database configuration parameter.')
--,   ( 'intra_parallel'     ,'YES'       ,   NULL, NULL, 'Should be ON, or enabled at the workload level with MAXIMUM DEGREE DEFAULT')
,   ( 'sheapthres'         ,'0'         ,   NULL, NULL, 'Keep at the default of 0. BLU sort memory is specifed with SHEAPTHRES_SHR).')
,   ( 'database_memory'    ,'AUTOMATIC' ,1000000, NULL, 'Should be AUTOMATIC and typically be 85%-90% of INSTANCE_MEMORY, and be least 1,000,000 4K pages')
,   ( 'instance_memory'    ,''          ,   NULL, NULL, 'Should be 80-90% of physical RAM. If AUTOMATIC Db2 picks at startup time 75-95% of system RAM')
,   ( 'auto_maint'         ,'ON'        ,   NULL, NULL, 'Should be ON')
,   ( 'auto_reorg'         ,'ON'        ,   NULL, NULL, 'Should be ON to enable automatic background REORG RECLAIM EXTENTS for BLU')
,   ( 'DB2_WORKLOAD'       ,'ANALYTICS' ,   NULL, NULL, 'Should be set to ANALYTICS to tell DB2 this datqabase is mostly for BLU workload')
,   ( 'util_heap_sz'       ,'AUTOMATIC' ,   NULL, NULL, '')
,   ( 'DB2_RESOURCE_POLICY','AUTOMATIC' ,   NULL, NULL, '')
,   ( 'IBMDEFAULTBP'       ,NULL        ,     20,   50, 'Should be 40% of db memory for low concurrency and 25% of db mem for high concurrency')
,   ( 'wlm_agent_load_trgt',''          ,     8,    32, 'Should be at least 8')
,   ( 'wlm_admission_ctrl' ,'YES'        ,   NULL, NULL, 'Should be on')
)
SELECT
    CASE 
		WHEN BP_VALUE = 'AUTOMATIC' AND VALUE <> 'AUTOMATIC' AND METHOD <> 'AUTOMATIC' THEN 'Should be Automatic'
		WHEN BP_MIN IS NOT NULL AND "PCT_OF_X" IS NOT NULL AND "PCT_OF_X" < DECFLOAT(BP_MIN) THEN 'Lower than advised relative size'
		WHEN BP_MAX IS NOT NULL AND "PCT_OF_X" IS NOT NULL AND "PCT_OF_X" > DECFLOAT(BP_MAX) THEN 'Higher than advised relative size'
        WHEN BP_MIN IS NOT NULL AND "PCT_OF_X" IS     NULL AND "VALUE" < DECFLOAT(BP_MIN) THEN 'Lower than advised range'
        WHEN BP_MAX IS NOT NULL AND "PCT_OF_X" IS     NULL AND "VALUE" > DECFLOAT(BP_MAX) THEN 'Higher than advised range'
		WHEN BP_MIN IS NULL AND BP_MIN IS NULL AND BP_VALUE <> METHOD AND BP_VALUE <> "VALUE" THEN 'Not Best Practice'  
		ELSE '' END AS ASSESMENT 
,   S.*
FROM
(   
    SELECT 
        CFG_TYPE 
    ,   SUBSTR(UPPER(NAME),1,20) NAME
    ,   BIGINT(SIZE)                       AS SIZE_BYTES
    ,   DECIMAL(SIZE/1024.0/1024/1024,7,2) AS SIZE_GB
    ,   CASE WHEN VALUE_FLAGS = 'NONE' THEN '' ELSE VALUE_FLAGS END AS METHOD
    ,   SUBSTR(VALUE,1,15) VALUE
    ,   CASE WHEN VALUE <> DEFERRED_VALUE THEN SUBSTR(DEFERRED_VALUE,1,15) ELSE '' END AS DEFERRED_VAL 
    ,   BP_VALUE
    ,   BP_MIN_VALUE AS BP_MIN
    ,   BP_MAX_VALUE AS BP_MAX
    ,   PCT_OF_X
    ,   BP_COMMENT 
    ,   MEMBERS
    FROM    
    (
        SELECT
            CFG_TYPE 
        ,   NAME
        ,   SIZE
        ,   VALUE_FLAGS
        ,   VALUE
        ,   DEFERRED_VALUE 
        ,   PCT_OF_X
        ,   LISTAGG(MEMBER,',') WITHIN GROUP (ORDER BY MEMBER)  AS MEMBERS
        FROM
        (      
            SELECT
                CASE WHEN NAME IN ('mon_heap_sz','java_heap_sz','audit_buf_sz','instance_memory','sheapthres','aslheapsz','fcm_num_buffers'
                    , 'app_ctl_heap_sz', 'appgroup_mem_sz', 'appl_memory', 'applheapsz', 'catalogcache_sz'
                     ,'cf_db_mem_sz', 'cf_gbp_sz', 'cf_lock_sz', 'cf_sca_sz', 'database_memory', 'dbheap'
                     , 'hadr_spool_limit', 'groupheap_ratio', 'locklist', 'logbufsz', 'mon_pkglist_sz'
                     , 'pckcachesz', 'sheapthres_shr'
                      , 'sortheap', 'stat_heap_sz', 'stmtheap', 'util_heap_sz'  )
                     OR CFG_TYPE IN ('BP')
                     THEN BIGINT(4096) * VALUE END AS SIZE
             ,       CASE WHEN NAME   = 'sheapthres_shr' 
                          OR CFG_TYPE = 'BP' 
                          THEN DECIMAL(100 * float(value) / MAX(CASE WHEN NAME = 'database_memory' THEN VALUE END) OVER(PARTITION BY MEMBER),5,2) 
                          WHEN NAME = 'sortheap' 
                          THEN DECIMAL(100 * float(value) / MAX(CASE WHEN NAME = 'sheapthres_shr' THEN VALUE  END) OVER(PARTITION BY MEMBER),5,2) 
                      END  AS PCT_OF_X    
             ,   S.*
             FROM 
             (    SELECT 'DB CFG'  AS CFG_TYPE, S.*                                          FROM SYSIBMADM.DBCFG  S UNION ALL
                  SELECT 'DBM CFG' AS CFG_TYPE, S.*, NULL AS DBPARTITIONNUM, NULL AS MEMBER  FROM SYSIBMADM.DBMCFG S UNION ALL
                  select
                      'REGVAR'      AS CFG_TYPE
                  ,   REG_VAR_NAME  AS NAME
                  ,   REG_VAR_VALUE AS VALUE    
                  ,   ''            AS VALUE_FLAGS
                  ,   CASE WHEN REG_VAR_VALUE <> REG_VAR_ON_DISK_VALUE THEN SUBSTR(REG_VAR_ON_DISK_VALUE,1,30) ELSE '' END AS DEFERRED_VALUE
                  ,   ''            AS DEFERRED_VALUE_FLAGS
                  ,   'VARCHAR'     AS DATATYPE
                 ,    NULL AS DBPARTITIONNUM
                 ,    MEMBER
                 FROM
                    TABLE(ENV_GET_REG_VARIABLES(-2, 0))
                 UNION ALL
                   select 'BP' AS CFG_TYPE
                   , b.BPNAME AS name
                   , CHAR((B.PAGESIZE / 4096) * BIGINT(M.BP_CUR_BUFFSZ)) AS VALUE
                   ,       CASE WHEN m.AUTOMATIC = 1 then 'AUTOMATIC' ELSE '' END AS VALUE_FLAGS
                   ,       '' AS DEFERRED_VALUE
                   ,       '' AS DEFERRED_VALUE_FLAGS
                   ,       'VARCHAR' AS DATATYPE
                , null as DBPARTITIONNUM
                , m.MEMBER
                 FROM
                     TABLE(MON_GET_BUFFERPOOL( NULL, -2)) M
                 INNER JOIN SYSCAT.BUFFERPOOLS B 
                 ON
                    M.BP_NAME = B.BPNAME
             ) S
            ) S
            GROUP BY
                CFG_TYPE 
            ,   NAME
            ,   SIZE
            ,   VALUE_FLAGS
            ,   VALUE
            ,   DEFERRED_VALUE 
            ,   PCT_OF_X
     )  S           
        LEFT OUTER JOIN BP_BLU_CFG bp
     ON
        S.NAME = BP.CFG_NAME
     WHERE
         BP.CFG_NAME IS NOT NULL
     OR  S.CFG_TYPE = 'BP'
) S