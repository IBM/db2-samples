--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * Create UNION ALL views of DB view by schema
 * 
 * Usefull for when you have multiple copiles of the DB library (such as multiple off-line or snapshots)
 *   and you want to report on the data together
 */
SET SCHEMA ALL
@

BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
    END;
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            VARCHAR(   'CREATE OR REPLACE VIEW ' || TABNAME || ' AS ' || CHR(10)
        || LISTAGG(    'SELECT ''' || RTRIM(TABSCHEMA) || '''' || REPEAT(' ',(MAX(0,16-LENGTH(RTRIM(TABSCHEMA)))) || ' AS DB'
                    || ', * FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
               , ' UNION ALL' || CHR(10))
              WITHIN GROUP (ORDER BY TABSCHEMA)
                , 4000) AS DDL
        FROM
            SYSCAT.TABLES 
        WHERE
            TABNAME LIKE 'DB\_%' ESCAPE '\'
        AND TYPE = 'V'
        AND TABSCHEMA LIKE 'DB%'
        AND (CURRENT_SCHEMA, TABNAME) NOT IN (SELECT TABSCHEMA, TABNAME FROM SYSCAT.TABLES)
        GROUP BY
            TABNAME
        ORDER BY
            TABNAME
        WITH UR 
    DO
        EXECUTE IMMEDIATE C.DDL;
        COMMIT;
    END FOR;
END
