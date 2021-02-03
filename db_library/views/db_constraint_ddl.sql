--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generates DDL for Primary and Unique Constraints
 * 
 * See db_foreign_key_ddl.sql for FK DDL
 */

CREATE OR REPLACE VIEW DB_CONSTRAINT_DDL AS
-- PKs and UKs
SELECT
    TABSCHEMA
,   TABNAME
,   CONSTNAME
,     'ALTER TABLE "' || TABNAME || '" ADD CONSTRAINT "'
    || CONSTNAME || '"'
    || CASE TYPE WHEN 'U' THEN ' UNIQUE ' WHEN 'P' THEN ' PRIMARY KEY ' END
    || ' (' || COLUMN_DDL || ')'
    || CASE WHEN ENFORCED = 'Y' THEN ' ENFORCED' WHEN ENFORCED = 'N' THEN ' NOT ENFORCED' END
    || CASE WHEN ENABLEQUERYOPT = 'Y' THEN ' ENABLE' WHEN 'N' THEN ' DISABLE' END || ' QUERY OPTIMIZATION'
        AS DDL
FROM
   SYSCAT.TABCONST
JOIN
    (   SELECT
            TABSCHEMA
        ,   TABNAME
        ,   CONSTNAME
        ,   LISTAGG('"' || COLNAME || '"'
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS COLUMN_DDL
        FROM
            SYSCAT.KEYCOLUSE
        GROUP BY
            TABSCHEMA
        ,   TABNAME
        ,   CONSTNAME
    ) AS C
USING
    ( TABSCHEMA, TABNAME, CONSTNAME )
