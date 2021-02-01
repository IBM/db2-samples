--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Reinsert data into an existing table
 * 
 * This code is intended to help shrink the synopsis and table size for small tables.
 * 
 * THIS CODE IS QUITE DANGEROUS. YOU CAN LOOSE YOUR DATA IF SOMETHING BAD HAPPENS DURING THE RUNNING OF THE CODE
 *    Maybe I could/should use a transactional TRUNCATE... but I don't
 *    Probably I should have a ROW COUNT check
 *    Probably I want an option to use LOAD REPLACE RESET DICTONARY to optimise dictonary build
 *    Probably I want an option to insert data in a given sort order
 *    Probably I want an option to insert data in a chunks
 *    Probably I want an option to re-create the table and do a rename..., ...
 * 
 * There are also two way to run the code.
 * Below uses perisisten tables
 * , but there is commented out code that uses TEMP tables, so is even more DANGEROUS,
 * 
 * Even with persistent tables, if there is a bug in my code, you moight loose data 
 *   
 * 
 * This code will copy data to a "temp" table, TRUNCATE the table, then re-insert the data 
 *
 *  We generate and execute code like this for each table
 *

BEGIN
    LOCK TABLE "MY_SCHEMA "."MY_TABLE" IN SHARE MODE;
    EXECUTE IMMEDIATE('CREATE TABLE WRK AS (SELECT * FROM "MY_SCHEMA "."MY_TABLE") WITH DATA');
    COMMIT;
    EXECUTE IMMEDIATE('TRUNCATE TABLE  "MY_SCHEMA "."MY_TABLE" IMMEDIATE');      -- implicitly commits
    LOCK TABLE "MY_SCHEMA "."MY_TABLE" IN SHARE MODE;
    SET CURRENT DEGREE = '1';
    EXECUTE IMMEDIATE('INSERT INTO "STAGING "."MY_TABLE" SELECT * FROM WRK');
    EXECUTE IMMEDIATE('DROP TABLE WRK');
END

 */
--DROP TABLE     DB_LOG_REINSERT
--TRUNCATE TABLE DB_LOG_REINSERT IMMEDIATE

CREATE TABLE DB_LOG_REINSERT (
    TABSCHEMA    VARCHAR(128) NOT NULL
,   TABNAME      VARCHAR(128) NOT NULL
--,   PRIMARY KEY (TABSCHEMA, TABNAME ) ENFORCED
) DISTRIBUTE ON ( TABSCHEMA, TABNAME )
@
    
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            TABSCHEMA
        ,   TABNAME 
        ,   PCTPAGESSAVED
        ,   CARD
        ,   NPAGES
        ,   FPAGES
        ,   (1/PCTPAGESSAVED::DECFLOAT) * ROWS_READ     AS RANK_A
        ,   ROWS_READ   AS RANK_B
        ,   VARCHAR(
            'CREATE TABLE   "' || T.TABSCHEMA || '"."' || T.TABNAME   || '_TMP" AS (SELECT * FROM "'
                               || T.TABSCHEMA || '"."' || T.TABNAME   || '") WITH DATA DISTRIBUTE ON ' 
                               || CASE WHEN DISTRIBUTION_KEY = '"RANDOM_DISTRIBUTION_KEY"' THEN 'RANDOM' ELSE ' (' || DISTRIBUTION_KEY || ')' END
                                                                                         ,4000)   AS CREATE_COPY_TABLE
        ,   VARCHAR('DECLARE GLOBAL TEMPORARY TABLE '
                        || '"' || 'SESSION' || '"."' || T.TABNAME   || '_TMP" AS (SELECT * FROM "'
                               || T.TABSCHEMA || '"."' || T.TABNAME   || '") WITH DATA ORGANIZE BY COLUMN ON COMMIT PRESERVE ROWS NOT LOGGED DISTRIBUTE BY (' 
                               ||  DISTRIBUTION_KEY || ')'
                                                                                         ,4000)   AS CREATE_TMP_TABLE
        ,   'LOCK   TABLE   "' || T.TABSCHEMA || '"."' || T.TABNAME   || '" IN SHARE MODE'  AS LOCK_TABLE
        ,   'TRUNCATE TABLE "' || T.TABSCHEMA || '"."' || T.TABNAME   || '" IMMEDIATE'      AS TRUNCATE_TABLE
        ,   'INSERT INTO    "' || T.TABSCHEMA || '"."' || T.TABNAME   || '" SELECT * FROM "'
                               || T.TABSCHEMA || '"."' || T.TABNAME   || '_TMP"'            AS INSERT_FROM_COPY_TABLE
        ,   'INSERT INTO    "' || T.TABSCHEMA || '"."' || T.TABNAME   || '" SELECT * FROM "'
                               || 'SESSION'   || '"."' || T.TABNAME   || '_TMP"'            AS INSERT_FROM_TMP_TABLE
        ,   'DROP TABLE     "' || T.TABSCHEMA || '"."' || T.TABNAME   || '_TMP"'            AS DROP_COPY_TABLE
        ,   'DROP TABLE     "' || 'SESSION'   || '"."' || T.TABNAME   || '_TMP"'            AS DROP_TMP_TABLE
        FROM
            SYSCAT.TABLES T JOIN DB.DB_DISTRIBUTION_KEYS USING (TABSCHEMA, TABNAME)
        LEFT JOIN (SELECT DISTINCT I.TABSCHEMA, I.TABNAME FROM SYSCAT.INDEXES I WHERE INDEXTYPE = 'REG') I USING (TABSCHEMA, TABNAME)   -- skip tables with indexes
        INNER JOIN
        (   -- lets tacket tables based on how used they are
            SELECT
                TABSCHEMA
            ,   TABNAME    
            ,   SUM(ROWS_READ)        AS ROWS_READ
            FROM
                TABLE(MON_GET_TABLE(DEFAULT, DEFAULT, -2)) AS T
            WHERE
                TABSCHEMA NOT LIKE 'SYS%'
            AND TAB_TYPE <> 'EXTERNAL_TABLE'
            GROUP BY
                TABSCHEMA
            ,   TABNAME
        ) USING ( TABSCHEMA, TABNAME )
        WHERE
             (T.TABSCHEMA, T.TABNAME) NOT IN (SELECT R.TABSCHEMA, R.TABNAME FROM DB_LOG_REINSERT R)     -- ignore tables alread processed
        AND TABSCHEMA NOT LIKE 'SYS%'
        AND TABLEORG = 'C'
--        AND   T.TABSCHEMA IN ('Your Schema')      -- add your own filters here if you wish
--        AND   T.TABNAME   IN ('your table')      -- add your own filters here if you wish
--  Try to fitler tables that look like they are sparse, but that do actualy have a reasonble dictorany
        AND T.NPAGES > (11 * 4 )      -- ignore tables that have less than one extent per data slice
        AND T.PCTPAGESSAVED < 20     -- only pick tables with poor pages saved (as this gets worse as sparsity increases)
        AND ( I.TABSCHEMA IS NULL OR CARD BETWEEN 1 AND 1000000)      -- Skip tables with enforced indexes if cardanality is more than 1 million
        -- now only include tables with a reasonable dictonary
        AND (TABSCHEMA, TABNAME) IN (SELECT TABSCHEMA, TABNAME FROM SYSCAT.COLUMNS GROUP BY  TABSCHEMA, TABNAME HAVING AVG(PCTENCODED) > 80)
        AND CARD < 50000000   -- Skip really big tables
        ORDER BY
            (1/PCTPAGESSAVED::DECFLOAT) * ROWS_READ     DESC   
        ,   ROWS_READ DESC
--            T.TABSCHEMA, T.TABNAME
        WITH UR       
    DO
        EXECUTE IMMEDIATE C.LOCK_TABLE;
        EXECUTE IMMEDIATE C.CREATE_COPY_TABLE;
--        EXECUTE IMMEDIATE C.CREATE_TMP_TABLE; 
        COMMIT;
        EXECUTE IMMEDIATE C.TRUNCATE_TABLE;
        SET CURRENT DEGREE = '1';                   -- use this to avoid having multiple insert ranges on the reinserted data.
        EXECUTE IMMEDIATE C.INSERT_FROM_COPY_TABLE;
--        EXECUTE IMMEDIATE C.INSERT_FROM_TMP_TABLE;
        EXECUTE IMMEDIATE C.DROP_COPY_TABLE;
--        EXECUTE IMMEDIATE C.DROP_TMP_TABLE;
        INSERT INTO DB_LOG_REINSERT VALUES ( C.TABSCHEMA, C.TABNAME );
     END FOR;
END
@

