--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Explain statements from the package cache
 * 
 * This example explains the top 20 dynamic statements from the pagake cache that have the worst sort memory estimate vs actual used
 * 
 */

CREATE OR REPLACE VARIABLE DB_EXPLAIN_SCHEMA    VARCHAR(128) DEFAULT 'SYSTOOLS' @  --    An optional input or output argument of type VARCHAR(128) that specifies the schema containing the Explain tables where the explain information should be written. If an empty string or NULL is specified, a search is made for the explain tables under the session authorization ID and, following that, the SYSTOOLS schema. If the Explain tables cannot be found, SQL0219N is returned. If the caller does not have INSERT privilege on the Explain tables, SQL0551N is returned. On output, this parameter is set to the schema containing the Explain tables where the information was written.
CREATE OR REPLACE VARIABLE DB_EXPLAIN_REQUESTER VARCHAR(128) @ --    An output argument of type VARCHAR(128) that contains the session authorization ID of the connection in which this routine was invoked. 
CREATE OR REPLACE VARIABLE DB_EXPLAIN_TIME      TIMESTAMP @    --    An output argument of type TIMESTAMP that contains the time of initiation for the Explain request. 
CREATE OR REPLACE VARIABLE DB_SOURCE_NAME       VARCHAR(128) @ --    An output argument of type VARCHAR(128) that contains the name of the package running when the statement was prepared or compiled.
CREATE OR REPLACE VARIABLE DB_SOURCE_SCHEMA     VARCHAR(128) @ --    An output argument of type VARCHAR(128) that contains the schema, or qualifier, of the source of Explain request.
CREATE OR REPLACE VARIABLE DB_SOURCE_VERSION    VARCHAR(64) @ --    An output argument of type VARCHAR(64) that contains the version of the source of the Explain request.
    
BEGIN
    DECLARE ERROR CONDITION FOR SQLSTATE '4274L'; 
    DECLARE CONTINUE HANDLER FOR ERROR BEGIN END;
    --
    FOR C AS cur CURSOR WITH HOLD FOR   
        SELECT
            EXECUTABLE_ID
        ,   MAX(STMT_TYPE_ID) AS STMT_TYPE_ID
        ,   SUM(ESTIMATED_SORT_SHRHEAP_TOP)    AS EST  --ESTIMATED_SORTMEM_USED_PAGES
        ,   SUM(SORT_SHRHEAP_TOP)              AS ACT  --SORTMEM_USED_PCT
        ,   ABS(SUM(SORT_SHRHEAP_TOP) - SUM(ESTIMATED_SORT_SHRHEAP_TOP)) AS DIFF
        ,   MAX(CAST(STMT_TEXT AS VARCHAR(32000 OCTETS))) AS SQL
        ,   'CALL EXPLAIN_FROM_SECTION ( x''' || hex(EXECUTABLE_ID) || ''', ''M'', NULL, -1, DB_EXPLAIN_SCHEMA, DB_EXPLAIN_REQUESTER, DB_EXPLAIN_TIME, DB_SOURCE_NAME, DB_SOURCE_SCHEMA, DB_SOURCE_VERSION )' 
                AS EXPLAIN_STMT
        FROM
            TABLE(MON_GET_PKG_CACHE_STMT ( 'D', NULL, NULL, -2)) AS T
        WHERE
            PLANID IS NOT NULL
        AND STMT_TYPE_ID IN (
                'DML, Select'
            ,   'DML, Select (blockable)'
            ,   'DML, Insert/Update/Delete '
            )
        GROUP BY
            EXECUTABLE_ID
        ORDER BY
            ABS(SUM(SORT_SHRHEAP_TOP) - SUM(ESTIMATED_SORT_SHRHEAP_TOP)) DESC
        LIMIT 20
        WITH UR
    DO
--          EXECUTE IMMEDIATE C.EXPLAIN_STMT;
        CALL EXPLAIN_FROM_SECTION(EXECUTABLE_ID,'M',NULL,-1, DB_EXPLAIN_SCHEMA, DB_EXPLAIN_REQUESTER, DB_EXPLAIN_TIME, DB_SOURCE_NAME, DB_SOURCE_SCHEMA, DB_SOURCE_VERSION ) ;
--        COMMIT;
    END FOR;
END
@

-- Now look at the tables, and other things from the explain statements..   
SELECT * FROM DB.DB_EXPLAIN_STMT
@

SELECT * FROM DB.DB_EXPLAIN_TABLES 

--or generate some db2exfmt's
SELECT 'db2exfmt -d BLUDB -w ' || EXPLAIN_TIME || ' -o ' || EXPLAIN_TIME || '.exfmt'
FROM
    SYSTOOLS.EXPLAIN_INSTANCE
ORDER BY
    EXPLAIN_TIME DESC
LIMIT 20

