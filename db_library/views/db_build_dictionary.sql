--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generates LOAD RESETDICTONARY commands with appropriate table sampling clause for BLU tables. Use to "prime" a dictonary when rebuilding a column organised table
 */

CREATE OR REPLACE VIEW DB_BUILD_DICTIONARY AS
SELECT 
    TABSCHEMA
,   TABNAME
,   TBSPACE
,   PCTPAGESSAVED
,   AVG_PCTENCODED
,   CARD
,   NPAGES
,   FPAGES
,   CEIL( UNCOMPRESSED_DATA_GB / 64)  AS MODOLUS
,   DECIMAL(UNCOMPRESSED_DATA_GB,17,2) UNCOMPRESSED_DATA_GB
,   DECIMAL(UNCOMPRESSED_DATA_GB_PER_SLICE,17,2)  UNCOMPRESSED_DATA_GB_PER_SLICE
,   'CALL ADMIN_CMD(''LOAD FROM (SELECT * FROM "' || TABSCHEMA  || '"."' || TABNAME || '"' 
/* we want to sample so that no more than 128 GB of uncompressed data is sent to LOAD in on a given data slice 
 *    https://www.ibm.com/support/pages/db2-how-it-works-load-cdeanalyzefrequency-and-maxanalyzesize
 * 
 * So if a table is 5000 GBs, and we have 23 data slices, we have  values 5000 / 23 = 217 GB per slice
 *  so if we target say hitting 64 GB per partition, we want a MOD number of  VALUES CEIL(217.0 / 64)
 * 
 * However as LOAD from CURSOR is single threaded, I don't think I need the divide by # data slices, so 
*/
        || CASE WHEN UNCOMPRESSED_DATA_GB > 64  THEN ' WHERE MOD(ABS(HASH4(ROWID)),' || CEIL( UNCOMPRESSED_DATA_GB / 64) || ')=0' ELSE '' END
        || ' WITH UR) OF CURSOR MODIFIED BY CDEANALYZEFREQUENCY=100 REPLACE RESETDICTIONARYONLY INTO '
        || '"' || TABSCHEMA || '"."' || TABNAME || '_NEW" NONRECOVERABLE'')'
        AS STMT
FROM
    (SELECT *
    ,    (( NPAGES  * 32768 ) / DECFLOAT(POWER(1024,3))) * (100.0 / (100 - PCTPAGESSAVED))       AS UNCOMPRESSED_DATA_GB
    ,   ((( NPAGES  * 32768 ) / DECFLOAT(POWER(1024,3))) * (100.0 / (100 - PCTPAGESSAVED))) / 23 AS UNCOMPRESSED_DATA_GB_PER_SLICE
    FROM SYSCAT.TABLES
    ) T
JOIN
    (SELECT TABNAME, TABSCHEMA, DECIMAL(AVG(PCTENCODED),5,2) AVG_PCTENCODED FROM SYSCAT.COLUMNS GROUP BY TABNAME, TABSCHEMA ) USING (TABNAME, TABSCHEMA)
WHERE TYPE NOT IN ('A','N','V','W')
AND TABSCHEMA NOT LIKE 'SYS%'
AND T.TABLEORG = 'C'
