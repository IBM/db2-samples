--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Create a trigger on a set of tables
 * 
 *      CREATE TABLE ADMIN.AUDIT ( TABSCHEMA VARCHAR(128) NOT NULL, TABNAME VARCHAR(128) NOT NULL, DT TIMESTAMP NOT NULL ) ORGANIZE BY ROW
 */

    BEGIN
        FOR C AS cur CURSOR WITH HOLD FOR
            SELECT 'CREATE TRIGGER "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '_TRIG"'
            || CHR(10) || 'AFTER INSERT ON "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
            || CHR(10) || 'REFERENCING NEW AS NEW FOR EACH ROW'
            || CHR(10) || 'INSERT INTO ADMIN.AUDIT VALUES (''' || TABSCHEMA || ''',''' || TABNAME || ''', CURRENT_TIMESTAMP )'
                AS STMT
            FROM
                SYSCAT.TABLES
            WHERE
                TABSCHEMA = 'PAUL'
            AND TYPE      = 'T'
            AND TABLEORG  = 'R'
            AND (TABSCHEMA, TABNAME || '_TRIG') NOT IN (SELECT TRIGSCHEMA, TRIGNAME FROM SYSCAT.TRIGGERS)
            ORDER BY 
                TABSCHEMA
            ,   TABNAME
        DO
              EXECUTE IMMEDIATE C.STMT;
              COMMIT;
        END FOR;
    END
