--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Returns data from the package cache. Shows recently executed SQL statements
 */
    
CREATE OR REPLACE VIEW DB_STMT_CACHE AS
SELECT  
    MAX(STMT_TEXT::VARCHAR(32672 OCTETS)) AS STMT_TEXT
--,   COUNT(DISTINCT MEMBER)    AS SLICES
--,   TIMESTAMP(MAX(MAX_COORD_STMT_EXEC_TIMESTAMP),0) AS MAX_EXEC_TIMESTAMP
,   MAX(NUM_EXECUTIONS)              AS NUM_EXECS
,   MAX(QUERY_COST_ESTIMATE)         AS COST
,                    MAX(TOTAL_ACT_TIME)       / 1000.0                                              AS     ACTIVITY_SECS
,   DECIMAL(DECFLOAT(SUM(TOTAL_ACT_TIME))      / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_ACTIVITY_SECS
,                    MAX(TOTAL_ACT_WAIT_TIME)  / 1000.0                                              AS     WAIT_SECS
,   DECIMAL(DECFLOAT(SUM(TOTAL_ACT_WAIT_TIME)) / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_WAIT_SECS
,                    MAX(STMT_EXEC_TIME)       / 1000.0                                              AS     EXEC_SECS
,   DECIMAL(DECFLOAT(SUM(STMT_EXEC_TIME))      / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_EXEC_SECS
,                    MAX(TOTAL_CPU_TIME)       /1000.0                                               AS     CPU_SECS
,   DECIMAL(DECFLOAT(SUM(TOTAL_CPU_TIME))      / NULLIF(SUM(NUM_EXEC_WITH_METRICS), 0) /1000.0,31,3) AS AVG_CPU_SECS
,   SUM(ROWS_READ    )              AS ROWS_READ    
,   SUM(ROWS_RETURNED)              AS ROWS_RETURNED
,   SUM(ROWS_MODIFIED)              AS ROWS_MODIFIED
,   SUM(ROWS_INSERTED)              AS ROWS_INSERTED
,   SUM(ROWS_UPDATED )              AS ROWS_UPDATED
,   SUM(ROWS_DELETED )              AS ROWS_DELETED
--,   (DIRECT_READS)         AS DIRECT_READS
--    , (DIRECT_WRITES)        AS DIRECT_WRITES
,   SUM(TOTAL_HASH_GRPBYS)                 AS HASH_GRPBYS
,   SUM(TOTAL_SORTS)                       AS SORTS
,   SUM(TOTAL_HASH_JOINS)                  AS HASH_JOINS
,                   MAX(TOTAL_SECTION_SORT_TIME) /1000.0                                               AS    SORT_SECS
--,    INT(total_col_vector_consumers)        AS VECTORS
--, SORT_CONSUMER_SHRHEAP_TOP 
--,SORT_HEAP_TOP SORT_SHRHEAP_TOP
--, EXT_TABLE_RECV_WAIT_TIME        --BIGINT  ext_table_recv_wait_time - Total agent wait time for external table readers monitor element
--, EXT_TABLE_RECVS_TOTAL           --BIGINT  ext_table_recvs_total - Total row batches received from external table readers monitor element
--, EXT_TABLE_RECV_VOLUME           --BIGINT  ext_table_recv_volume - Total data received from external table readers monitor element
--, EXT_TABLE_READ_VOLUME           --BIGINT  ext_table_read_volume - Total data read by external table readers monitor element
--, EXT_TABLE_SEND_WAIT_TIME        --BIGINT  ext_table_send_wait_time - Total agent wait time for external table writers monitor element
--, EXT_TABLE_SENDS_TOTAL           --BIGINT  ext_table_sends_total - Total row batches sent to external table writers monitor element
--, EXT_TABLE_SEND_VOLUME           --BIGINT  ext_table_send_volume - Total data sent to external table writers monitor element
--, EXT_TABLE_WRITE_VOLUME          
,   DECIMAL(ROUND(1.0 - DECIMAL(SUM(POOL_DATA_P_READS))/NULLIF(SUM(POOL_DATA_L_READS),0),4)*100,5,2)   AS DATA_HIT_PCT
,   DECIMAL(ROUND(1.0 - DECIMAL(SUM(POOL_INDEX_P_READS))/NULLIF(SUM(POOL_INDEX_L_READS),0),4)*100,5,2) AS INDEX_HIT_PCT
,   DECIMAL(ROUND(1.0 - (DECIMAL(SUM(POOL_TEMP_DATA_P_READS) +  SUM(POOL_TEMP_INDEX_P_READS))/NULLIF((SUM(POOL_TEMP_DATA_L_READS) + SUM(POOL_TEMP_INDEX_L_READS)),0)),4)*100,5,2) AS TEMP_HIT_PCT
,   MIN(INSERT_TIMESTAMP)::DATE      AS  STMT_CACHE_DATE
,   MIN(INSERT_TIMESTAMP)::TIME      AS  TIME
FROM
    TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) AS T
GROUP BY
    EXECUTABLE_ID
