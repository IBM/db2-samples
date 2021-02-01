--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * For every ENFORCED PRIMARY KEY, DROP the PK and recreate it NOT ENFORCED
 */

BEGIN
FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
        VARCHAR(
        'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" DROP PRIMARY KEY'                , 4000) AS DROP_PK
    ,   VARCHAR(
        'ALTER TABLE "' || TABSCHEMA || '"."' || TABNAME || '" ADD'
        || CASE WHEN CONSTNAME NOT LIKE 'SQL%' THEN ' CONSTRAINT "' || CONSTNAME || '"' ELSE '' END 
        || ' PRIMARY KEY (' || LISTAGG(COLNAME,', ') WITHIN GROUP (ORDER BY COLSEQ) || ') NOT ENFORCED'     , 4000) AS ADD_PK
    FROM
        SYSCAT.TABCONST C
    JOIN
        SYSCAT.KEYCOLUSE U
    USING
        ( TABSCHEMA , TABNAME, CONSTNAME ) 
    WHERE  
        C.TYPE = 'P'
    AND C.ENFORCED = 'Y'
    AND SUBSTR(C.TABSCHEMA,1,3) NOT IN ('SYS','IBM','DB2')
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