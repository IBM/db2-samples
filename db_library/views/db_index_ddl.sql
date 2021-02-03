--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 *  Generates DDL for all indxes on the database
 */

CREATE OR REPLACE VIEW DB_INDEX_DDL AS
SELECT
    TABSCHEMA
,   TABNAME
,   INDSCHEMA
,   INDNAME
,     'CREATE ' 
    || CASE WHEN UNIQUERULE IN ('P', 'U') THEN 'UNIQUE ' ELSE '' END
    || 'INDEX "' || INDNAME || '" ON "' || TABNAME || '"'
    || ' (' || COLUMN_DDL || ')'
    || COALESCE('INCLUDE (' || INCLUDE_COLUMN_DDL || ')','')
    || CASE INDEXTYPE WHEN 'CLUS' THEN ' CLUSTERED' ELSE '' END 
    || CASE WHEN REVERSE_SCANS = 'Y' THEN ' ALLOW REVERSE SCANS' ELSE ' DISALLOW REVERSE SCANS' END
        AS DDL
FROM
   SYSCAT.INDEXES
JOIN
    (   SELECT
            INDSCHEMA
        ,   INDNAME
        ,   LISTAGG('"' || COLNAME || '"'
                || CASE COLORDER WHEN 'D' THEN ' DESC' ELSE '' END
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS COLUMN_DDL
        FROM
            SYSCAT.INDEXCOLUSE
        WHERE
            COLORDER <> 'I'
        GROUP BY
            INDSCHEMA
        ,   INDNAME
    ) AS C
USING
    ( INDSCHEMA, INDNAME )
LEFT JOIN
    (   SELECT
            INDSCHEMA
        ,   INDNAME
        ,   LISTAGG('"' || COLNAME || '"'
                || CASE COLORDER WHEN 'D' THEN ' DESC' ELSE '' END
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS INCLUDE_COLUMN_DDL
        FROM
            SYSCAT.INDEXCOLUSE
        WHERE
            COLORDER = 'I'
        GROUP BY
            INDSCHEMA
        ,   INDNAME
    ) AS I
USING
    ( INDSCHEMA, INDNAME )
WHERE
    INDEXTYPE IN ('CLUS', 'REG ')
