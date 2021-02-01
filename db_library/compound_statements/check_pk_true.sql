--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Code to check if your NOT ENFORCED Primary Key or Unique Constraints are true or not
 *   
 * If they are not true, and you have duplicate rows, you can get WRONG RESULTS in DB2 queries
 *   because the optimizer will re-write your quired based on the assumetion that your constraints are infact true  
 *
 * Consider DROPing or ENFORCEing all PK and Unique Constraints that are not true.
 *   
 * Note that Db2 does not allow PK or Unique constraints to be set to NOT TRUSTED.
 *     There is a RFE here that you can vote for if you woudl like such a feature https://ibm-data-and-ai.ideas.aha.io/ideas/DB24LUW-I-879
 *   
 * Note that this code relies on the DB2 Optimizer to not re-write the checking queries in such a way 
 *   that the check is optimized away. It might be that a future optimization is added to DB2 query re-write that
 *   would require a more complex statement to check for invalid constraints.  
 *
 */

-- DROP TABLE     DB_PK_DUPLICATES
-- TRUNCATE TABLE DB_PK_DUPLICATES IMMEDIATE

CREATE TABLE DB_PK_DUPLICATES
(   TABSCHEMA             VARCHAR(128)  NOT NULL
,   TABNAME               VARCHAR(128)  NOT NULL
,   CONSTNAME             VARCHAR(128)  NOT NULL
,   CONSTTYPE             CHAR(1)       NOT NULL
,   COLUMNS               VARCHAR(4000) NOT NULL
,   ROW_COUNT             BIGINT        NOT NULL
,   DUPLICATE_ROWS        BIGINT        NOT NULL        -- The number of rows with at least one other row on the table with the same PK value
,   MAX_DUPLICATES        BIGINT        NOT NULL        -- The highest number of rows (including itself) that any row has the same same PK value with
,   MIN_DUPLICATES        BIGINT        NOT NULL        -- The lowest  number of rows (including itself) that any row has the same same PK value with
,   SUM_DUPLICATES        BIGINT        NOT NULL        -- The sum of the number of rows (including itself) that each row has the same same PK value with
,   AVG_DUPLICATES        BIGINT        NOT NULL        -- The average of the number of rows (including itself) that each row has the same same PK value with
,   COUNT_TIMESTAMP     TIMESTAMP       NOT NULL
,   PRIMARY KEY (TABSCHEMA, TABNAME, CONSTNAME ) ENFORCED
)
@

BEGIN 
    FOR C AS cur CURSOR WITH HOLD FOR 
        SELECT VARCHAR('INSERT INTO DB_PK_DUPLICATES SELECT' 
            || ' ''' || RTRIM(TABSCHEMA) || '''' 
            || ',''' || TABNAME          || ''''
            || ',''' || CONSTNAME        || ''''
            || ',''' || C.TYPE           || ''''
            || ',''' || COLUMNS          || ''''
            || ',    COUNT(*) AS ROW_COUNT'
            || ',    COALESCE(SUM(CASE WHEN DUPS > 1 THEN 1 ELSE 0 END),0) AS DUPLICATE_ROWS'
            || ',    COALESCE(MAX(NULLIF(DUPS,1)),0)         AS MAX_DUPLICATES'
            || ',    COALESCE(MIN(NULLIF(DUPS,1)),0)         AS MIN_DUPLICATES'
            || ',    COALESCE(SUM(DUPS -1),0)                AS SUM_DUPLICATES'
            || ',    COALESCE(AVG(NULLIF(DUPS,1)),0)         AS AVG_DUPLICATES'
            || ',    CURRENT TIMESTAMP FROM ' 
            || '( SELECT COUNT(*) OVER(PARTITION BY ' || COLUMNS || ') AS DUPS'
            || ' FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"' 
            || ')',4000)
            AS S  
        FROM
            SYSCAT.TABCONST C 
        JOIN (
            SELECT 
                CONSTNAME, TABSCHEMA, TABNAME
            ,   VARCHAR(LISTAGG('"' || COLNAME || '"', ',') WITHIN GROUP (ORDER BY COLSEQ),4000) AS COLUMNS
            FROM
                SYSCAT.KEYCOLUSE
            GROUP BY
                CONSTNAME, TABSCHEMA, TABNAME
            )              
            USING ( CONSTNAME, TABSCHEMA, TABNAME )
        JOIN
             SYSCAT.TABLES  T USING (            TABSCHEMA, TABNAME )
        WHERE 
            C.ENFORCED = 'N'        -- Only need to consider PKs and UKs that are NOT ENFORCED
        AND (T.TABSCHEMA, T.TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM DB_PK_DUPLICATES R)     -- allow this to be restart able
        AND C.TRUSTED  = 'Y'        -- Note that PK and Unique Keys can't be NOT TRUSTED, but we will filter here in case we get this feature in teh future
        AND C.TYPE IN ('P','U')     -- Primary Keys and Unique Keys
        AND T.TYPE IN ('T')         -- Only check tables, not NICKNAMEs
        AND T.TABSCHEMA = 'STAGING'
        ORDER BY TABSCHEMA, TABNAME, CONSTNAME
        WITH UR
    DO      
        EXECUTE IMMEDIATE C.S;
        COMMIT;
    END FOR;
END
@

-- A view to help you look at the results of the above
CREATE OR REPLACE VIEW DB_PK_DUPLICATES_STMTS AS
SELECT 
       'SELECT * FROM'
    || '( SELECT COUNT(*) OVER(PARTITION BY ' || COLUMNS || ') AS DUPS'
    || ', T.* FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" T' 
    || ') WHERE DUPS > 1'                                                  AS SHOW_DUPLICATES_SQL
,      'DELETE FROM'
    || '( SELECT COUNT(*) OVER(PARTITION BY ' || COLUMNS || ') AS DUPS'
    || ', T.* FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" T' 
    || ') WHERE DUPS > 1'                                                  AS DELETE_DUPLICATES_SQL
--
,   'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME   || '" DROP CONSTRAINT "' || CONSTNAME || '"' AS DROP_CONSTAINT_SQL
--
,   'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME   || '" ADD CONSTRAINT ' 
    || '"' || CONSTNAME || '"' 
    || CASE CONSTTYPE WHEN 'P' THEN 'PRIMARY KEY'
                      WHEN 'U' THEN 'UNIQUE ' END
    || ' (' || COLUMNS   || ')'
    || ' ENFORCED'                                                          AS CREATE_ENFORCED_CONSTRAINT_SQL
--
,      'SELECT' 
                  || '    ''' || RTRIM(TABSCHEMA) || '''' 
       || CHR(10) || ',   ''' || TABNAME          || ''''
       || CHR(10) || ',   ''' || CONSTNAME        || ''''
       || CHR(10) || ',   ''' || COLUMNS          || ''''
       || CHR(10) || ',    COUNT(*) AS ROW_COUNT'                                       
       || CHR(10) || ',    COALESCE(SUM(CASE WHEN DUPS > 1 THEN 1 ELSE 0 END),0) AS DUPLICATE_ROWS' 
       || CHR(10) || ',    COALESCE(MAX(NULLIF(DUPS,1)),0)         AS MAX_DUPLICATES'             
       || CHR(10) || ',    COALESCE(MIN(NULLIF(DUPS,1)),0)         AS MIN_DUPLICATES'             
       || CHR(10) || ',    COALESCE(SUM(DUPS -1),0)                AS SUM_DUPLICATES'              
       || CHR(10) || ',    COALESCE(AVG(NULLIF(DUPS,1)),0)         AS AVG_DUPLICATES'             
       || CHR(10) || '('
       || CHR(10) || '     SELECT COUNT(*) OVER(PARTITION BY ' || COLUMNS || ') AS DUPS'
       || CHR(10) || '     FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"' 
       || CHR(10) || ')'      AS CHECK_FOR_DUPLIACTES_SQL
 ,  *
FROM
    DB_PK_DUPLICATES

@

SELECT * FROM DB_PK_DUPLICATES WHERE DUPLICATE_ROWS > 0

