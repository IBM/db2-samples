--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * For every FORIEGN KEY and PRIMARY KEY, recreate them with a standard constraint name
 * 
 * This is useful if comparing schemas (e.g. in a tool such as InforSphere Data Architect)
 * and you want to ignore differences due to system generated constrant names (that begine with SQL...)
 * 
 * Db2 does not allow constraints to be RENAMED, so this script will drop all FKs and PKs
 *  that don't follow the naming standard, and recreate them with a standard, generated constraint name
 * 
 * All FKs are dropped, then PKs recreated, then the FKs re-added
 * 
 * Really, this script is best run against an empty database. E.g. when doing data modelling work. 
 * But it is up to you
 * 
 * Ideally the script would only drop the FKs needed for the PKs that need recreating. But it is not that clever
 * 
 */

--TRUNCATE TABLE DB_STANDARDIZE_CONSTRAINTS IMMEDIATE

-- Populate table to hold new FK and PKs
CREATE TABLE DB_STANDARDIZE_CONSTRAINTS
(   TABSCHEMA         VARCHAR(128 OCTETS) NOT NULL
,   TABNAME           VARCHAR(128 OCTETS) NOT NULL
,   CONSTNAME         VARCHAR(128 OCTETS) NOT NULL
--,   NEW_CONSTNAME     VARCHAR(128 OCTETS) NOT NULL
,   TYPE              CHAR(1 OCTETS) NOT NULL -- 'P' = PK, 'F' = FK
,   NEW_DDL           VARCHAR(512 OCTETS) NOT NULL
)

@

-- Generate new Foriegn Keys names and DDL
INSERT INTO DB_STANDARDIZE_CONSTRAINTS
-- Code borrowed from --CREATE OR REPLACE VIEW DB_FOREIGN_KEY_DDL AS       
WITH COLS AS (
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   CONSTNAME
    ,   LISTAGG('"' || COLNAME || '"',', ') WITHIN GROUP (ORDER BY COLSEQ) AS COL_LIST
    FROM
        SYSCAT.KEYCOLUSE
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ,   CONSTNAME
)
SELECT
    TABSCHEMA
,   TABNAME
,   CONSTNAME
,   'F' AS TYPE
--,   REFTABSCHEMA    AS PARENT_SCHEMA
--,   REFTABNAME      AS PARENT_TABNAME
,   'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" ADD'              
--    || CASE WHEN CONSTNAME NOT LIKE 'SQL%' THEN ' CONSTRAINT "' || CONSTNAME || '"' ELSE '' END
    || ' CONSTRAINT ' || '"FK_' /*|| REFTABNAME || ':' */|| REPLACE(REPLACE(COL_LIST,', ',':'),'"','') || '"'                         -- Add your FK naming standard here
    || ' FOREIGN KEY (' || COL_LIST || ') REFERENCES "' || REFTABSCHEMA || '"."' || REFTABNAME || '"'
    || CASE WHEN PARENT_COLS = COL_LIST THEN '' ELSE '(' || PARENT_COLS || ')' END
    || CASE ENFORCED WHEN 'Y' THEN ' ENFORCED' WHEN 'N' THEN ' NOT ENFORCED' END
    || CASE ENABLEQUERYOPT WHEN 'N' THEN ' DISABLE QUERY OPTIMIZATION' ELSE '' END
    || CASE DELETERULE WHEN 'A' THEN '' ELSE ' ON DELETE ' || CASE DELETERULE WHEN 'C' THEN 'CASCADE' WHEN 'N' THEN 'SET NULL' WHEN 'R' THEN 'RESTRICT' END END
    || CASE UPDATERULE WHEN 'A' THEN '' ELSE ' ON UPDATE RESTRICT ' END 
        AS DDL
--,   REFKEYNAME
FROM
    SYSCAT.TABCONST C
JOIN
    SYSCAT.REFERENCES
USING
    ( TABSCHEMA , TABNAME, CONSTNAME )
JOIN
    COLS
USING
    ( TABSCHEMA , TABNAME, CONSTNAME ) 
JOIN
(
    SELECT TABSCHEMA AS REFTABSCHEMA, TABNAME AS REFTABNAME, CONSTNAME AS REFKEYNAME, COL_LIST AS PARENT_COLS 
    FROM COLS
)
USING
    ( REFTABSCHEMA, REFTABNAME, REFKEYNAME )
JOIN (
    SELECT 
        TABSCHEMA, TABNAME, CONSTNAME
    ,   VARCHAR(LISTAGG('C."' || COLNAME || '" = P."' || REFCOLNAME || '"', ' AND ') WITHIN GROUP (ORDER BY COLSEQ),4000) AS JOIN_CLAUSE
    FROM
          SYSCAT.REFERENCES R
    JOIN  SYSCAT.KEYCOLUSE  C USING (    TABSCHEMA,    TABNAME, CONSTNAME ) 
    JOIN  (SELECT CONSTNAME REFKEYNAME, TABSCHEMA AS REFTABSCHEMA, TABNAME AS REFTABNAME, COLNAME AS REFCOLNAME, COLSEQ FROM SYSCAT.KEYCOLUSE)
                            P USING ( REFTABSCHEMA, REFTABNAME, REFKEYNAME, COLSEQ )
    GROUP BY
        TABSCHEMA, TABNAME, CONSTNAME
    )              
    USING ( CONSTNAME, TABSCHEMA, TABNAME )
 WHERE SUBSTR(TABSCHEMA,1,3) NOT IN ('SYS','IBM')
@

-- Generate new Primary Keys names and DDL
INSERT INTO DB_STANDARDIZE_CONSTRAINTS
-- Code borrowed from --CREATE OR REPLACE VIEW DB_PRIMARY_KEY_DDL AS       
SELECT
    TABSCHEMA
,   TABNAME
,   CONSTNAME
,   C.TYPE    
,   'ALTER TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" ADD' 
    || ' CONSTRAINT "' || CASE C.TYPE WHEN 'P' THEN 'PK_' || TABNAME WHEN 'U' THEN 'UK_' || TRIM(REPLACE(REPLACE(COL_LIST,', ',':'),'"','')) END || '"' -- Add your PK naming standard here
    || CASE C.TYPE WHEN 'P' THEN ' PRIMARY KEY ' WHEN 'U' THEN ' UNIQUE ' END
    || '(' || COL_LIST
    || COALESCE(', ' || PERIODNAME || CASE PERIODPOLICY WHEN 'O' THEN ' WITHOUT OVERLAPS ' ELSE '' END,'')
    || ')'
    || CASE ENFORCED WHEN 'Y' THEN ' ENFORCED' WHEN 'N' THEN ' NOT ENFORCED' END
    || CASE ENABLEQUERYOPT WHEN 'N' THEN ' DISABLE QUERY OPTIMIZATION' ELSE '' END
        AS DDL
FROM
    SYSCAT.TABCONST C
JOIN
(   SELECT
        K.TABSCHEMA
    ,   K.TABNAME
    ,   K.CONSTNAME
    ,   LISTAGG('"' || K.COLNAME || '"',', ') WITHIN GROUP (ORDER BY K.COLSEQ)   AS COL_LIST
    FROM
        SYSCAT.KEYCOLUSE K
    LEFT JOIN -- exclude period columns from the column list
        SYSCAT.PERIODS  B1 ON K.TABSCHEMA = B1.TABSCHEMA AND K.TABNAME = B1.TABNAME AND K.COLNAME = B1.BEGINCOLNAME AND B1.PERIODNAME = 'BUSINESS_TIME'
    LEFT JOIN
        SYSCAT.PERIODS  B2 ON K.TABSCHEMA = B2.TABSCHEMA AND K.TABNAME = B2.TABNAME AND K.COLNAME = B2.ENDCOLNAME   AND B2.PERIODNAME = 'BUSINESS_TIME'
    WHERE
        B1.TABNAME IS NULL
    AND B2.TABNAME IS NULL
    GROUP BY
        K.TABSCHEMA
    ,   K.TABNAME
    ,   K.CONSTNAME
)    
USING
    ( TABSCHEMA , TABNAME, CONSTNAME ) 
WHERE  
    C.TYPE IN ( 'P', 'U' )
AND SUBSTR(TABSCHEMA,1,3) NOT IN ('SYS','IBM')
@

SELECT * FROM DB_STANDARDIZE_CONSTRAINTS
@

-- Now apply the above new constraint names

-- Include your required filters on e.g. schema below
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION BEGIN ROLLBACK; END;
--        
FOR A AS cur CURSOR WITH HOLD FOR
    SELECT
           'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" DROP FOREIGN KEY "' || CONSTNAME || '"'  AS DROP_FK
    FROM
        DB_STANDARDIZE_CONSTRAINTS
    WHERE  
        TYPE = 'F'
    AND TABSCHEMA = 'DW'
    WITH UR
DO
      EXECUTE IMMEDIATE DROP_FK;
--      COMMIT;
END FOR;
--
FOR B AS cur CURSOR WITH HOLD FOR
    SELECT
           'ALTER TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '" DROP'
        || CASE TYPE WHEN 'P' THEN ' PRIMARY KEY ' WHEN 'U' THEN ' UNIQUE ' || '"' || CONSTNAME || '"' END AS DROP_PK
    ,       NEW_DDL AS ADD_PK
    FROM
        DB_STANDARDIZE_CONSTRAINTS
    WHERE  
        TYPE IN ( 'P', 'U')
    AND TABSCHEMA = 'DW'
    WITH UR
DO
      EXECUTE IMMEDIATE DROP_PK;
      EXECUTE IMMEDIATE ADD_PK;
--      COMMIT;
END FOR;
--
FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
           NEW_DDL AS ADD_FK
    FROM
        DB_STANDARDIZE_CONSTRAINTS
    WHERE  
        TYPE = 'F'
    AND TABSCHEMA = 'DW'
    WITH UR
DO
      EXECUTE IMMEDIATE ADD_FK;
--      COMMIT;
END FOR;
    COMMIT;
END
@

-- Now check the results
SELECT * FROM DB_PRIMARY_KEYS WHERE TABSCHEMA = 'PAUL' @
SELECT * FROM DB_FOREIGN_KEYS WHERE TABSCHEMA = 'PAUL' @
