--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Lists all table function, nickname, table and view columns in the database
 */

CREATE OR REPLACE VIEW DB_COLUMNS_ALL AS
SELECT
    ROUTINESCHEMA       AS TABSCHEMA
,   ROUTINEMODULENAME   AS MODULENAME
,   ROUTINENAME         AS TABNAME
,   'F'                 AS TYPE
,   PARMNAME            AS COLNAME
,   CAST(NULL AS INTEGER)   AS COLCARD
,   ORDINAL             AS COLNO
,   LENGTH
,   STRINGUNITSLENGTH
,   SCALE 
,   CAST(NULL AS INTEGER)   AS INLINE_LENGTH
,   'Y'                     AS NULLS
,   ''                      AS DEFAULT
,   'N'                     AS HIDDEN 
,   SPECIFICNAME
,   REMARKS
FROM
    SYSCAT.ROUTINEPARMS P
WHERE
    P.ROWTYPE IN ('R','C','S')
AND P.PARMNAME IS NOT NULL
UNION ALL    
SELECT  
    C.TABSCHEMA
,   ''                  AS MODULENAME
,   C.TABNAME
,   T.TYPE
,   C.COLNAME
,   C.COLNO
,   C.COLCARD
,   C.LENGTH
,   C.STRINGUNITSLENGTH
,   SCALE 
,   INLINE_LENGTH
,   NULLS
,   DEFAULT
,   HIDDEN 
,   ''                  AS SPECIFICNAME
,   C.REMARKS
FROM
    SYSCAT.COLUMNS C
INNER JOIN
    SYSCAT.TABLES T
USING
   ( TABSCHEMA, TABNAME )