--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all scalar functions in the database
 */

/*
 * Note that SYSCAT.FUNCTIONS has been deprecated sincde DB2 7.1, so we use SYSCAT.ROUTINES
 */
CREATE OR REPLACE VIEW DB_SCALAR_FUNCTIONS AS
SELECT
    ROUTINESCHEMA     AS FUNCSCHEMA
,   ROUTINENAME       AS FUNCNAME
,   ROUTINEMODULENAME AS MODULENAME
,   COALESCE(PARMS,'')       AS PARMS
,   SPECIFICNAME
,   LANGUAGE
,   DIALECT
,      CASE WHEN LANGUAGE <> '' THEN 'LANGUAGE ' || RTRIM(LANGUAGE) ELSE '' END
    || CASE DETERMINISTIC WHEN 'Y' THEN ' DETERMINISTIC'
                      WHEN 'N' THEN ' NOT DETERMINISTIC'
    ELSE '' END
    || CASE EXTERNAL_ACTION WHEN 'Y' THEN ' EXTERNAL ACTION'
                         WHEN 'N' THEN ' NO EXTERNAL ACTION'
    ELSE '' END 
    || CASE FENCED WHEN 'Y' THEN ' FENCED'
               WHEN 'N' THEN ' NOT FENCED'
    ELSE '' END 
    || CASE THREADSAFE WHEN 'Y' THEN ' THREADSAFE'
                   WHEN 'N' THEN ' NOT THREADSAFE'
    ELSE '' END 
    || CASE PARALLEL WHEN 'Y' THEN ' ALLOW PARALLEL'
                  WHEN 'N' THEN ' DISALLOW PARALLEL'
    ELSE '' END  
    || CASE SQL_DATA_ACCESS 
                            WHEN 'R' THEN ' READS SQL DATA'
                            WHEN 'C' THEN ' CONTAINS SQL'
                            WHEN 'M' THEN ' MODIFIES SQL DATA'
                            WHEN 'N' THEN ' NO SQL'
    ELSE '' END 
    || CASE SECURE WHEN 'Y' THEN ' SECURED'
    --               WHEN 'N' THEN ' NOT SECURED'       this is the default
    ELSE '' END 
        AS OPTIONS
,   CASE WHEN TEXT_BODY_OFFSET > 0 THEN SUBSTR(TEXT,TEXT_BODY_OFFSET) ELSE '' END   AS TEXT_BODY
,   COALESCE(CALL_STMT,'')   AS USAGE_STMT
,   REMARKS         AS COMMENTS
FROM  
    SYSCAT.ROUTINES 
LEFT JOIN
(    SELECT 
         ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME
     ,   LISTAGG(
             COALESCE(VARCHAR(PARMNAME,32000) || ' ','')
             || CASE
                    WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','BLOB','NCLOB') 
                    THEN     CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END
                          || '(' || LENGTH || ')'
                    WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
                    THEN TYPENAME
                    WHEN TYPENAME IN ('TIMESTAMP') OR (TYPENAME IN ('DECIMAL') AND SCALE = 0)
                    THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
                    WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
                    THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
                    WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
                    ELSE TYPENAME END 
             ,   ', ') 
             WITHIN GROUP (ORDER BY ORDINAL) AS PARMS 
     FROM
         SYSCAT.ROUTINEPARMS
     WHERE
        ROWTYPE IN ('P','B')
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
LEFT JOIN
(    SELECT 
         ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME      
     ,   'values "' || ROUTINESCHEMA || '"."' || ROUTINENAME || '" (' ||
         LISTAGG(
                CASE 
                    WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'VARGAPHIC', 'LONG VARCHAR','CLOB','BLOB','NCLOB')    THEN  ''''''
                    WHEN TYPENAME IN ('TIMESTAMP')           THEN 'CURRENT_TIMESTAMP'
                    WHEN TYPENAME IN ('DATE')                THEN 'CURRENT_DATE'
                    WHEN TYPENAME IN ('TIME')                THEN 'CURRENT_TIME'
                    WHEN TYPENAME IN ('DECIMAL','DECFLOAT')  THEN '0.0' 
                                                             ELSE '0'
                END
             ,   ', ') 
             WITHIN GROUP (ORDER BY ORDINAL) || ')' AS CALL_STMT 
     FROM
         SYSCAT.ROUTINEPARMS
     WHERE
        ROWTYPE IN ('P','B')
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
WHERE
    FUNCTIONTYPE = 'S'
