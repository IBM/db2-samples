--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * For every NOT ENFORCED PRIMARY KEY, DROP the PK and recreate it as ENFORCED
 * 
 * I would suggest you use the  check_pk_true.sql  compound statement before this one 
 *    to sure the ALTERs will work...
 * 
 * It is MUCH MUCH faster to check if a PK is true with a SQL query than it is to start building an index
 *   which will have to get rolled back if a dupicate is eventually found.
 *   Especially if you have only duplicates towards "the end" of a big table.
 */

BEGIN
FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
        VARCHAR(
        'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" DROP PRIMARY KEY'                , 4000) AS DROP_PK
    ,   VARCHAR(
        'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" ADD'
        || CASE WHEN CONSTNAME NOT LIKE 'SQL%' THEN ' CONSTRAINT "' || CONSTNAME || '"' ELSE '' END 
        || ' PRIMARY KEY (' || LISTAGG(COLNAME,', ') WITHIN GROUP (ORDER BY COLSEQ) || ') ENFORCED'     , 4000) AS ADD_PK
    FROM
        SYSCAT.TABCONST C
    JOIN
        SYSCAT.KEYCOLUSE U
    USING
        ( TABSCHEMA , TABNAME, CONSTNAME ) 
    WHERE  
        C.TYPE = 'P'
    AND C.ENFORCED = 'N'
    AND SUBSTR(C.TABSCHEMA,1,3) NOT IN ('SYS','IBM','DB2')
    AND TABSCHEMA = 'SSSS'
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ,   CONSTNAME
    WITH UR
DO
      EXECUTE IMMEDIATE C.DROP_PK;
      EXECUTE IMMEDIATE C.ADD_PK;
      COMMIT;
END FOR;
END
