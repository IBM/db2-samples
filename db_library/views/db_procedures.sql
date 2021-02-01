--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all stored procedures on the database. Includes the parameter signature and an example CALL statement for each procedure
 */

CREATE OR REPLACE VIEW DB_PROCEDURES AS
SELECT
    ROUTINESCHEMA   AS PROCSCHEMA
,   ROUTINENAME     AS PROCNAME
,   COALESCE(PARMS,'')       AS PARMS
,   SPECIFICNAME
,   COALESCE(CALL_STMT,'')   AS CALL_STMT
,   LANGUAGE
,   TIMESTAMP(CREATE_TIME,0) AS CREATE_DATETIME
,   REMARKS         AS COMMENTS
FROM
    SYSCAT.ROUTINES 
LEFT JOIN
(    SELECT 
         ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME
     ,   LISTAGG(
             VARCHAR(PARMNAME,32000) || ' '
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
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
LEFT JOIN
( SELECT ROUTINESCHEMA
     ,   ROUTINENAME
     ,   SPECIFICNAME      
     ,   'call "' || ROUTINESCHEMA || '"."' || ROUTINENAME || '" (' ||
         LISTAGG(
             VARCHAR(PARMNAME,32000) || ' => ' 
             || CASE WHEN ROWTYPE = 'O' THEN '?' 
                    WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'VARGAPHIC', 'LONG VARCHAR','CLOB','BLOB','NCLOB')    THEN  ''''''
                    WHEN TYPENAME IN ('TIMESTAMP')           THEN 'CURRENT_TIMESTAMP'
                    WHEN TYPENAME IN ('DATE')                THEN 'CURRENT_DATE'
                    WHEN TYPENAME IN ('TIME')                THEN 'CURRENT_TIME'
                    WHEN TYPENAME IN ('DECIMAL','DECFLOAT')  THEN '0.0' 
                                                             ELSE '0'
                END
             ,   ', ') 
             WITHIN GROUP (ORDER BY ORDINAL) || ');' AS CALL_STMT 
     FROM
         SYSCAT.ROUTINEPARMS
     GROUP BY
            ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME
)
USING ( ROUTINESCHEMA, ROUTINENAME, SPECIFICNAME )
WHERE
    ROUTINETYPE = 'P'
