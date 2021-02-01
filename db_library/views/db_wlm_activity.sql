--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns Work Load Management metrics by current activity
 */

/*
Derived from the query shown here  https://www.ibm.com/support/knowledgecenter/en/SSHRBY/com.ibm.swg.im.dashdb.admin.wlm.doc/doc/adaptive_wlm_why_queued_usage.html

Returns the following information:

    Resource information (effective_query_degree, sort_shrheap_allocated, sort_shrheap_top)
    Whether the query bypassed the adaptive workload manager (adm_bypassed)
    The current state (EXECUTING or IDLE)
    Information that you can use to identify the source of the query, such as the session authorization ID, application name, and statement tex
    
*/
CREATE OR REPLACE VIEW DB_WLM_ACTIVITY AS
WITH
    TOTAL_MEM (CFG_MEM, MEMBER) AS (SELECT VALUE, MEMBER  FROM SYSIBMADM.DBCFG WHERE NAME = 'sheapthres_shr')
,   LOADTRGT  (LOADTRGT)        AS (SELECT MAX(VALUE)     FROM SYSIBMADM.DBCFG WHERE NAME = 'wlm_agent_load_trgt')
,   CPUINFO   (CPUS_PER_HOST)   AS (SELECT MAX(CPU_ONLINE / CPU_HMT_DEGREE) FROM TABLE(ENV_GET_SYSTEM_RESOURCES()))
,   PARTINFO  (PART_PER_HOST)   AS (SELECT COUNT(*) PART_PER_HOST FROM TABLE(DB_MEMBERS()) AS T 
                                    WHERE T.MEMBER_TYPE = 'D' GROUP BY HOST_NAME FETCH FIRST 1 ROWS ONLY )
SELECT 
    A.MEMBER
,   A.COORD_MEMBER
,   A.ACTIVITY_STATE
,   A.APPLICATION_HANDLE
,   A.UOW_ID
,   A.ACTIVITY_ID
,   B.APPLICATION_NAME
,   B.SESSION_AUTH_ID
,   B.CLIENT_IPADDR
,   A.ENTRY_TIME
,   A.LOCAL_START_TIME
,   CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) 
         THEN TIMESTAMPDIFF(2, CHAR(A.LOCAL_START_TIME - A.ENTRY_TIME))
         ELSE A.WLM_QUEUE_TIME_TOTAL/1000 END                                            AS TOTAL_QUEUETIME_SECONDS
,   CASE WHEN (A.LOCAL_START_TIME IS NOT NULL)
         THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME)) ELSE NULL END AS TOTAL_RUNTIME_SECONDS
,   CASE WHEN (A.LOCAL_START_TIME IS NOT NULL) 
         THEN TIMESTAMPDIFF(2, CHAR(CURRENT_TIMESTAMP-A.LOCAL_START_TIME))-A.COORD_STMT_EXEC_TIME/1000
                                                                           ELSE NULL END AS TOTAL_CLIENT_WAIT_SECONDS
,   A.ADM_BYPASSED
/*11.5.0*/,   A.ADM_RESOURCE_ACTUALS
,   A.EFFECTIVE_QUERY_DEGREE
,   DEC((FLOAT(A.EFFECTIVE_QUERY_DEGREE)/(FLOAT(D.LOADTRGT) * FLOAT(E.CPUS_PER_HOST) / FLOAT(F.PART_PER_HOST)))*100,5,2) AS THREADS_USED_PCT
,   A.QUERY_COST_ESTIMATE
,   A.ESTIMATED_RUNTIME
,   A.ESTIMATED_SORT_SHRHEAP_TOP                                            AS ESTIMATED_SORTMEM_USED_PAGES
,   DEC((FLOAT(A.ESTIMATED_SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2) AS ESTIMATED_SORTMEM_USED_PCT
,   A.SORT_SHRHEAP_ALLOCATED                                                AS SORTMEM_USED_PAGES
,   DEC((FLOAT(A.SORT_SHRHEAP_ALLOCATED)/FLOAT(C.CFG_MEM)) * 100, 5, 2)     AS SORTMEM_USED_PCT
,   SORT_SHRHEAP_TOP                                                        AS PEAK_SORTMEM_USED_PAGES
,   DEC((FLOAT(A.SORT_SHRHEAP_TOP)/FLOAT(C.CFG_MEM)) * 100, 5, 2)           AS PEAK_SORTMEM_USED_PCT
,   C.CFG_MEM                                                               AS CONFIGURED_SORTMEM_PAGES
,   STMT_TEXT
FROM
    TABLE(MON_GET_ACTIVITY(NULL,-2))   AS A
,   TABLE(MON_GET_CONNECTION(NULL,-1)) AS B
,   TOTAL_MEM AS C
,   LOADTRGT AS D
,   CPUINFO AS E
,   PARTINFO AS F
WHERE (A.APPLICATION_HANDLE = B.APPLICATION_HANDLE) AND (A.MEMBER = C.MEMBER)
