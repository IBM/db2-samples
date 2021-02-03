--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all indexes, including the columns and data types of that make up the index.
 */

CREATE OR REPLACE VIEW DB_INDEXES AS
SELECT
    TABSCHEMA
,   TABNAME
,   INDSCHEMA
,   INDNAME
,   INDEX_COLUMN_DDL
FROM
   SYSCAT.INDEXES
JOIN
    (   SELECT
            INDSCHEMA
        ,   INDNAME
        ,   LISTAGG('"' || COLNAME || '" ' 
            || CASE
                WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
                THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                     || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                     || CASE WHEN CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END
                WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
                THEN TYPENAME || '(' || LENGTH || ')'  
                WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                THEN TYPENAME
                WHEN TYPENAME IN ('TIMESTAMP')
                THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
                THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                ELSE TYPENAME END 
            || CASE WHEN INLINE_LENGTH <> 0 THEN ' INLINE LENGTH ' || INLINE_LENGTH ELSE '' END
            || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        
                , ', '
                ) WITHIN GROUP (ORDER BY COLSEQ)    AS INDEX_COLUMN_DDL
        FROM
            SYSCAT.INDEXES
        JOIN
            SYSCAT.INDEXCOLUSE
        USING
            ( INDSCHEMA, INDNAME )
        JOIN
            SYSCAT.COLUMNS
        USING
            ( TABSCHEMA, TABNAME, COLNAME )
        GROUP BY
            INDSCHEMA
        ,   INDNAME
    ) AS C
USING
    ( INDSCHEMA, INDNAME )
