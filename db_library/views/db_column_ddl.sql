--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generates the data type DDL text for columns. Note the DDL is UNOFFICIAL and INCOMPLETE, is provided AS-IS and Db2look might well produce something different
 */

CREATE OR REPLACE VIEW DB_COLUMN_DDL AS
SELECT
    TABSCHEMA
,   TABNAME
,   COLNAME
,   COLNO
,   CASE
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
    || CASE WHEN NULLS = 'N' THEN ' NOT NULL' ELSE '' END                        AS DATATYPE_DDL
,   CASE WHEN DEFAULT IS NOT NULL THEN ' DEFAULT ' || DEFAULT ELSE '' END        AS DEFAULT_VALUE_DDL 
,   CASE WHEN HIDDEN = 'I' THEN 'IMPLICITLY HIDDEN ' ELSE '' END                 AS OTHER_DDL
,   SUM(CASE WHEN COLNAME = 'RANDOM_DISTRIBUTION_KEY' AND HIDDEN = 'I' THEN 0 ELSE 1 END) 
        OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO)                     AS COL_SEQ
FROM
    SYSCAT.COLUMNS