--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Generates quick DDL for tables. Provided AS-IS. It is accurate for most simple tables. Does not include FKs, generated column expression or support range partitioned and MDC tables or other complex DDL structure
 */

CREATE OR REPLACE VIEW DB_TABLE_QUICK_DDL AS
/*
Simple DDL generator for DB2

Many things are not supported. Use db2look, IBM Data Studio or some other method for more complete DDL support.

Notable exclusions include
   Foreign Keys
   Unique Keys
   (full support of) Identity columns
   MDC
   Range Partitioning
   etc

If your table DDL will end up being more than 32 thousand bytes, the DDL will be split over more than 1 row. 
  This is to avoid the length of the generate DDL breaking the max length of a VARCHAR used by LISTAGG 

*/
WITH T AS (
          SELECT CASE WHEN TRANSLATE(TABSCHEMA,'','ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_') = '' 
                           THEN RTRIM(TABSCHEMA)
               ELSE '"' || RTRIM(TABSCHEMA) || '"' END AS SCHEMA
  ,       CASE WHEN TRANSLATE(TABNAME,'','ABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890_') = '' 
               THEN TABNAME
               ELSE '"' || RTRIM(TABNAME) || '"' END AS TABLE 
  ,       T.*
  ,       CASE TYPE WHEN 'G' THEN VARCHAR('CREATE GLOBAL TEMPORARY TABLE ')
                    WHEN 'A' THEN 'CREATE OR REPLACE ALAIS '
                    WHEN 'N' THEN 'CREATE OR REPLACE NICKNAME '
                             ELSE 'CREATE TABLE '
                    END AS CREATE
  FROM
        SYSCAT.TABLES  T
  WHERE   TYPE NOT IN ('V')
  )
  , C AS (
  SELECT
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000    AS DDL_SPLIT_SEQ
      ,   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS))
                  || CASE WHEN COL_SEQ > 0 THEN VARCHAR(CHR(10) || ',   ') ELSE '    ' END 
                  || '"' || COLNAME || '"'
                  || CASE WHEN LENGTH(COLNAME) < 40 THEN REPEAT(' ',40-LENGTH(COLNAME)) ELSE ' ' END
                  || DATATYPE_DDL
                  || GENERATED_DDL
                  || CASE WHEN DEFAULT_VALUE_DDL <> '' THEN ' ' || DEFAULT_VALUE_DDL ELSE '' END 
                  || CASE WHEN OTHER_DDL         <> '' THEN ' ' || OTHER_DDL         ELSE '' END 
                  ) WITHIN GROUP (ORDER BY COLNO) AS COLUMNS
      FROM
          (SELECT C.*
           ,    SUM(50 + LENGTH(DATATYPE_DDL) + LENGTH(DEFAULT_VALUE_DDL) + LENGTH(OTHER_DDL))
                     OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) AS CUMULATIVE_LENGTH
           FROM
           (
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
                ,   ROW_NUMBER() OVER(PARTITION BY TABSCHEMA, TABNAME ORDER BY COLNO) - 1        AS COL_SEQ
                ,   CASE WHEN GENERATED <> '' THEN  ' GENERATED' 
                    || CASE GENERATED WHEN 'A' THEN ' ALWAYS' WHEN 'D' THEN ' BY DEFUALT' ELSE '' END
                    || ' AS ' || CASE WHEN IDENTITY = 'Y' THEN 'IDENTITY' WHEN ROWBEGIN = 'Y' THEN 'ROW BEGIN' WHEN ROWEND = 'Y' THEN 'ROW END'
                              WHEN TRANSACTIONSTARTID = 'Y' THEN 'TRANSACTION START ID' ELSE VARCHAR(TEXT,1000) END 
                    ELSE '' END   AS GENERATED_DDL
                FROM
                    SYSCAT.COLUMNS
                WHERE
                    NOT (RANDDISTKEY = 'Y' AND HIDDEN = 'I') -- Don't generate DDL for hidden RANDOM_DISTRIBUTION_KEY columns
           ) C
          )
      GROUP BY
          TABSCHEMA
      ,   TABNAME
      ,   CUMULATIVE_LENGTH/32000
  ) 
  SELECT
      T.TABSCHEMA
  ,   T.TABNAME
  ,   C.DDL_SPLIT_SEQ + 1                   AS DDL_LINE_NO
  ,   CASE WHEN DDL_SPLIT_SEQ = 0 THEN      -- Top 
           CREATE ||  SCHEMA || '.' || TABLE || CHR(10) || '(' || CHR(10) ELSE '' 
      END
      || COLUMNS || CHR(10)                 -- Middle
      || CASE WHEN DDL_SPLIT_SEQ = MAX(DDL_SPLIT_SEQ) OVER( PARTITION BY T.TABSCHEMA, T.TABNAME)
         THEN
                CASE WHEN T.TEMPORALTYPE IN ('A','B') OR SUBSTR(T.PROPERTY,29,1) = 'Y' THEN COALESCE(',   PERIOD BUSINESS_TIME ("' || BT.BEGINCOLNAME || '", "' || BT.ENDCOLNAME || '")' || CHR(10),'') END
             || CASE WHEN T.TEMPORALTYPE IN ('S','B') OR SUBSTR(T.PROPERTY,29,1) = 'Y' THEN COALESCE(',   PERIOD SYSTEM_TIME ("'   || ST.BEGINCOLNAME || '", "' || ST.ENDCOLNAME || '")' || CHR(10),'') END
             || CASE WHEN                                SUBSTR(T.PROPERTY,29,1) = 'Y' THEN 'MAINTAINED BY USER' || CHR(10) ELSE '' END
             || CASE WHEN PK.TYPE = 'P' 
             THEN ',   '
                  || CASE WHEN PK.CONSTNAME NOT LIKE 'SQL%' THEN 'CONSTRAINT ' || PK.CONSTNAME ELSE '' END
                  || ' PRIMARY KEY ( ' || PK_COLS 
                  || COALESCE(', ' || PK.PERIODNAME || CASE PK.PERIODPOLICY WHEN 'O' THEN ' WITHOUT OVERLAPS' ELSE '' END,'') || ' )'
                  || CASE WHEN PK.ENFORCED = 'N' THEN ' NOT ENFORCED' ELSE ' ENFORCED' END
                  || CASE PK.ENABLEQUERYOPT WHEN 'N' THEN ' DISABLE QUERY OPTIMIZATION' ELSE '' END                  
                  || CHR(10)  
             ELSE ''
             END
             || ')' || CHR(10)
             || CASE WHEN T.TABLEORG = 'C' THEN 'ORGANIZE BY COLUMN ' || CHR(10)  
                     WHEN T.TABLEORG = 'R' THEN 'ORGANIZE BY ROW '    || CHR(10)  ELSE '' END
             || CASE WHEN D.RANDDISTKEY = 'Y'      THEN 'DISTRIBUTE BY RANDOM' || CHR(10)
                     WHEN D.DISTRIBUTION_KEY <> '' THEN 'DISTRIBUTE BY (' || DISTRIBUTION_KEY || ')' || CHR(10) 
                ELSE ''  END
             || CASE WHEN T.TBSPACE IS NOT NULL THEN 'IN "' || T.TBSPACE || '"' || CHR(10)  ELSE '' END
         ELSE '' END
        AS DDL
  FROM
      T
  JOIN 
      C
  ON
      T.TABSCHEMA = C.TABSCHEMA AND T.TABNAME = C.TABNAME
  LEFT OUTER JOIN
      SYSCAT.TABCONST PK
  ON
     PK.TABSCHEMA = T.TABSCHEMA AND PK.TABNAME = T.TABNAME AND PK.TYPE = 'P'
  LEFT OUTER JOIN
(   SELECT
        K.TABSCHEMA
    ,   K.TABNAME
    ,   K.CONSTNAME
    ,   LISTAGG('"' || K.COLNAME || '"',', ') WITHIN GROUP (ORDER BY K.COLSEQ)   AS PK_COLS
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
) K
  ON
     PK.TABSCHEMA = K.TABSCHEMA AND PK.TABNAME = K.TABNAME AND PK.CONSTNAME = K.CONSTNAME
LEFT OUTER JOIN
(	
	SELECT
	    TABSCHEMA
	,   TABNAME
	,   SUBSTR(LISTAGG(CASE WHEN PARTKEYSEQ > 0 THEN ', "' || COLNAME || '"' ELSE '' END) WITHIN GROUP (ORDER BY PARTKEYSEQ ),3) AS DISTRIBUTION_KEY
	,   MAX(RANDDISTKEY)    AS RANDDISTKEY
	FROM
	    SYSCAT.COLUMNS
	GROUP BY
	    TABSCHEMA 
	,   TABNAME
) D
ON
    T.TABSCHEMA = D.TABSCHEMA AND T.TABNAME = D.TABNAME
LEFT JOIN
    SYSCAT.PERIODS  BT 
ON
    T.TABSCHEMA = BT.TABSCHEMA AND T.TABNAME = BT.TABNAME AND BT.PERIODNAME = 'BUSINESS_TIME'
LEFT JOIN
    SYSCAT.PERIODS  ST 
ON
    T.TABSCHEMA = ST.TABSCHEMA AND T.TABNAME = ST.TABNAME AND ST.PERIODNAME = 'SYSTEM_TIME'
