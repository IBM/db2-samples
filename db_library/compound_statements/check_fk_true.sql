--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Code to check if your NOT ENFORCED Foreign Keys are true
 *  
 * If they are not true, you can get WRONG RESULTS in DB2 queries
 *  because the optimizer will re-write your queries based on the assumption that your constraints are infact true  
 *
 * Consider DISABLE QUERY OPTIMIZATION on any FKs that are not true.
 *  
 * This script does the following:
 *  
 *  For each FK that is NOT ENFORCED
 *  
 *  1. Counts the number of rows where the FK is not valid    
 *  
 * This means that this code does rely on the DB2 Optimizer not re-writing the checking queries in such a way 
 *     that the check is optimized away.
 *  
 * After you have run this script, you might want to set all not aactually true FKs to NOT TRUSTed.  
 *     This script does not do that for you...  you might prefer to fix the data, than to switch the FK trust.
 *
*/
--SET STATEMENT TERMINATOR='@'
--RENAME TABLE DB_FK_UNMATCHED TO DB_FK_UNMATCHED_OLD
--DROP TABLE IF EXISTS DB_FK_UNMATCHED
--@

CREATE TABLE DB_FK_UNMATCHED
(   TABSCHEMA             VARCHAR(128)  NOT NULL
,   TABNAME               VARCHAR(128)  NOT NULL
,   REFTABSCHEMA          VARCHAR(128)  NOT NULL
,   REFTABNAME            VARCHAR(128)  NOT NULL
,   CONSTNAME             VARCHAR(128)  NOT NULL
,   ROW_COUNT             BIGINT        NOT NULL        -- The number of child rows
,   NOTNULL_COUNT         BIGINT        NOT NULL        -- The number of child rows with no NULL value in any of the FK columns
,   UNMATCHED_COUNT       BIGINT        NOT NULL        -- The number of rows with at no match in the Parent table
--,   DISTINCT_UNMATCHED_COUNT       BIGINT        NOT NULL        -- The number of values with at no match in the Parent table
,   CHILD_COLUMNS         VARCHAR(4000) NOT NULL
,   JOIN_CLAUSE           VARCHAR(4000) NOT NULL
,   COUNT_TIMESTAMP       TIMESTAMP     NOT NULL
,   PRIMARY KEY (TABSCHEMA, TABNAME, CONSTNAME ) ENFORCED
)
@
DELETE FROM DB_FK_UNMATCHED WHERE 1=1
@
/*
 * So below we generate statements like this
 * 
INSERT INTO DB_FK_UNMATCHED
SELECT
    COUNT(*) AS ROW_COUNT
,   SUM(CASE WHEN FK_COL1 IS NOT NULL
              AND FK_COL2 IS NOT NULL THEN 1 ELSE 0 END) AS NOTNULL_COUNT
,   SUM(CASE WHEN NOT EXISTS (SELECT 1 FROM PARENT P WHERE C.FK_COL1 = P.FK_COL1
                                                       AND C.FK_COL2 = P.FK_COL2 ) THEN 1 ELSE 0 END)
        AS UNMATCHED_COUNT
FROM
    CHILD C
 * 
 */

BEGIN 
    FOR C AS cur CURSOR WITH HOLD FOR     
        SELECT VARCHAR('INSERT INTO DB_FK_UNMATCHED'
        ||CHR(10)|| 'SELECT' 
        ||CHR(10)|| ' ''' || RTRIM(TABSCHEMA)    || '''' 
                 || ',''' || TABNAME             || ''''
                 || ',''' || RTRIM(REFTABSCHEMA) || '''' 
                 || ',''' || REFTABNAME          || ''''
                 || ',''' || CONSTNAME           || ''''
        ||CHR(10)|| ',    COUNT(*) AS ROW_COUNT'
        ||CHR(10)|| ',    SUM(CASE WHEN ' || COALESCE(NULL_CHECK,'1=1') || ' THEN 1 ELSE 0 END) AS NOTNULL_COUNT'
        ||CHR(10)|| ',    SUM(CASE WHEN ' || COALESCE(' (' || NULL_OR_CHECK || ') AND ' ,'') 
                                        || 'NOT EXISTS (SELECT 1 FROM "' || RTRIM(REFTABSCHEMA) || '"."' || REFTABNAME || '" P WHERE '
                                                         || JOIN_CLAUSE || ') THEN 1 ELSE 0 END) AS UNMATCHED_COUNT'
        ||CHR(10)|| ',''' || CHILD_COLUMNS       || ''' AS CHILD_COLUMNS'
        ||CHR(10)|| ',''' || JOIN_CLAUSE         || ''' AS JOIN_CLAUSE'
        ||CHR(10)|| ',    CURRENT_TIMESTAMP ' 
        ||CHR(10)|| ' FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" C'   -- Child Table
                 ,4000) 
            AS S  
        FROM
            SYSCAT.TABCONST C
        JOIN
            SYSCAT.REFERENCES R
        USING ( TABSCHEMA , TABNAME, CONSTNAME )
        JOIN (
            SELECT 
                TABSCHEMA, TABNAME, CONSTNAME
            ,   VARCHAR(LISTAGG('"' || COLNAME || '" IS NOT NULL', ' AND ') WITHIN GROUP (ORDER BY COLSEQ),4000) AS NULL_CHECK
            ,   VARCHAR(LISTAGG('"' || COLNAME || '" IS NOT NULL', ' OR ')  WITHIN GROUP (ORDER BY COLSEQ),4000) AS NULL_OR_CHECK
            ,   VARCHAR(LISTAGG('C."' || COLNAME || '" = P."' || REFCOLNAME || '"', ' AND ') WITHIN GROUP (ORDER BY COLSEQ),4000) AS JOIN_CLAUSE
            ,   VARCHAR(LISTAGG('"' || COLNAME || '"', ', ') WITHIN GROUP (ORDER BY COLSEQ),4000) AS CHILD_COLUMNS
            FROM
                  SYSCAT.REFERENCES R
            JOIN  SYSCAT.KEYCOLUSE  C USING (    TABSCHEMA,    TABNAME, CONSTNAME ) 
            JOIN  (SELECT CONSTNAME REFKEYNAME, TABSCHEMA AS REFTABSCHEMA, TABNAME AS REFTABNAME, COLNAME AS REFCOLNAME, COLSEQ FROM SYSCAT.KEYCOLUSE)
                                    P USING ( REFTABSCHEMA, REFTABNAME, REFKEYNAME, COLSEQ )
            GROUP BY
                TABSCHEMA, TABNAME, CONSTNAME
            )              
            USING ( CONSTNAME, TABSCHEMA, TABNAME )
        JOIN
             SYSCAT.TABLES  T USING (            TABSCHEMA, TABNAME )
        WHERE 
            C.ENFORCED = 'N'        -- Only need to consider PKs and UKs that are NOT ENFORCED
        AND ( TABSCHEMA, TABNAME, CONSTNAME ) NOT IN (SELECT TABSCHEMA, TABNAME, CONSTNAME FROM DB_FK_UNMATCHED R)     -- allow this to be restart able
        AND C.TRUSTED  = 'Y'        -- 
        AND C.TYPE IN ('F')         -- Foreign Keys
        AND T.TYPE IN ('T')         -- Only check tables, not NICKNAMEs
        AND T.TABSCHEMA = 'DW' -- Pick you own schemas to run against
        ORDER BY TABSCHEMA, TABNAME, CONSTNAME
        WITH UR        
    DO      
        EXECUTE IMMEDIATE C.S;
        COMMIT;
    END FOR;
END
@

/*
 * A view to help look at the resutls of the above
 * 
 */
CREATE OR REPLACE VIEW DB_FK_UNMATCHED_STMTS AS
SELECT 
    TABSCHEMA
,   TABNAME
,   REFTABSCHEMA
,   REFTABNAME
,   CONSTNAME
,   UNMATCHED_COUNT
,   NOTNULL_COUNT
,   ROW_COUNT
,    'SELECT ' || CHILD_COLUMNS || ', COUNT(*) AS ROW_COUNT'
    || CHR(10) || ' FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" C' 
    || CHR(10) || ' WHERE NOT EXISTS (SELECT 1 FROM "' ||  RTRIM(REFTABSCHEMA) || '"."' || REFTABNAME || '" P WHERE ' || JOIN_CLAUSE || ' )'
    || CHR(10) || ' GROUP BY ' || CHILD_COLUMNS
                 AS COUNT_BY_VALUE_SQL
--,  *
FROM
    DB_FK_UNMATCHED

@

SELECT * FROM DB_FK_UNMATCHED_STMTS WHERE UNMATCHED_COUNT > 0

@

-- Generate SQL that you can use to look at the individual values are not matching per FK
SELECT REPLACE(COUNT_BY_VALUE_SQL, CHR(10), ' ') || '@' FROM DB_FK_UNMATCHED_STMTS WHERE UNMATCHED_COUNT > 0

