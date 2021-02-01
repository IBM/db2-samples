--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all distribution keys that are (probably) ones that Db2 has picked automatically, rather an having been picked by a User
 */

/*
 * Returns what the default distribution key would be for each table based on an approximation of the rules
 *  used by Db2 Warehouse if no distribution key is given by the user
 * 
 * This may, or may not be the acutal distribution key on the table
 * 
 * Use with a query such as

    SELECT * FROM DB_DB2W_DEFAULT_DISTRIBUTION_KEYS 
             JOIN DB_DISTRIBUTION_KEYS USING ( TABSCHEMA, TABNAME )
    WHERE DISTRIBUTION_KEY = DEFAULT_DISTRIBUTION_KEY
    AND   DISTRIBUTION_KEY <> 'RANDOM_DISTRIBUTION_KEY'

 * to see which tables on your system are likley to have a defaulted distribution key
 * 
 * Defaulted distribution keys are rarely the most optimial key that could be picked for a given workload,
 *  and can also suffer from data skew if values in the key columns are not well distributed.
 * 
 * It can be a good idea to review these tables to manully pick better distribution keys
 *
 * Note that the code below does not take into account any Foreign Keys that were part of the CREATE TABLE DDL
 *   Columns in FKs at table creation time are also used in the full rules used by Db2 Warehouse
 */

CREATE OR REPLACE VIEW DB_DB2W_DEFAULT_DISTRIBUTION_KEYS AS 
SELECT
    TABSCHEMA
,   TABNAME
,   LISTAGG('"' || COLNAME || '"',', ') WITHIN GROUP (ORDER BY DIST_KEY_PREFERENCE_ORDER) AS DEFAULT_DISTRIBUTION_KEY
FROM
(
    SELECT ROW_NUMBER() OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY DIST_KEY_PREFERENCE) AS DIST_KEY_PREFERENCE_ORDER
    ,   *
    FROM
    (   SELECT
            TABSCHEMA
        ,   TABNAME
        ,   COLNAME
        ,   COLNO
        ,   CASE
                WHEN IDENTITY = 'Y' THEN 0
                WHEN TYPENAME = 'BIGINT'   OR (TYPENAME = 'DECIMAL' AND SCALE = 0 AND LENGTH > 10) THEN 10000 
                WHEN TYPENAME = 'INTEGER'  OR (TYPENAME = 'DECIMAL' AND SCALE = 0 AND LENGTH > 5 ) THEN 20000
                WHEN TYPENAME = 'SMALLINT' OR (TYPENAME = 'DECIMAL' AND SCALE = 0 AND LENGTH > 3 ) THEN 30000
                WHEN (TYPENAME = 'BINARY' AND LENGTH BETWEEN 4 AND 40 )
                OR   (TYPENAME = 'CHARACTER' AND ( TYPESTRINGUNITS = 'OCTETS' OR CODEPAGE = 0) AND LENGTH BETWEEN 4 AND 40 )
                OR   (TYPENAME = 'CHARACTER' AND   TYPESTRINGUNITS = 'CODEUNITS32'   AND STRINGUNITSLENGTH BETWEEN 0 AND 10 )
                OR   (TYPENAME = 'BINARY' AND LENGTH BETWEEN 4 AND 40 )
                OR   (TYPENAME LIKE '%GRAPHIC' AND  TYPESTRINGUNITS = 'CODEUNITS16'  AND STRINGUNITSLENGTH BETWEEN 2 AND 20 )
                OR   (TYPENAME LIKE '%GRAPHIC' AND  TYPESTRINGUNITS = 'CODEUNITS32'  AND STRINGUNITSLENGTH BETWEEN 0 AND 10 )
                OR   (TYPENAME = 'VARBINARY' AND LENGTH BETWEEN 4 AND 32 )
                OR   (TYPENAME = 'VARCHAR' AND ( TYPESTRINGUNITS = 'OCTETS' OR CODEPAGE = 0) AND LENGTH BETWEEN 4 AND 32 )
                OR   (TYPENAME = 'VARCHAR' AND   TYPESTRINGUNITS = 'CODEUNITS32'         AND STRINGUNITSLENGTH BETWEEN 0 AND 8 )
                                                                                                   THEN 40000
                WHEN TYPENAME IN ('TIMESTAMP','TIME')                                              THEN 50000
                ELSE                                                                                    90000
                END                                                                                    
            + CASE WHEN NULLS = 'Y'            THEN 5000 ELSE 0 END
            + CASE WHEN DEFAULT IS NULL        THEN 2000 ELSE 0 END
            + CASE WHEN GENERATED IN ('A','D') THEN 2000 ELSE 0 END
            + COLNO
                AS DIST_KEY_PREFERENCE
        FROM
            SYSCAT.COLUMNS
        WHERE TYPENAME NOT IN ('LONG VARCHAR','CLOB','DBCLOB','BLOB','XML')
        AND NOT ROWCHANGETIMESTAMP = 'Y'
    )
)
WHERE DIST_KEY_PREFERENCE_ORDER <= 3
GROUP BY
    TABSCHEMA
,   TABNAME