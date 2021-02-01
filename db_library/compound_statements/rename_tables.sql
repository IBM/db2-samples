--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Code to rename all tables that match some pattern
 *  
 * This example removes any "non-word" characters from table names.
 * 
 * I.e. any characters that are not an underscore or in the \w regular expresion set:
 * 
    [\p{Alphabetic}\p{Mark}\p{Decimal_Number}\p{Connector_Punctuation}\u200c\u200d]
    
 *
*/
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT
            'RENAME TABLE "' || TABSCHEMA || '"."' || TABNAME || '" TO "' || NEW_TABNAME || '"' AS RENAME
        FROM
        (   SELECT *
            ,   REGEXP_REPLACE(TABNAME,'[^\w_]','') AS NEW_TABNAME
            FROM
                SYSCAT.TABLES 
            WHERE TYPE = 'T'
            )
        WHERE  TABAME <> NEW_TABNAME
        ORDER BY
            TABSCHEMA
        ,   TABNAME
        WITH UR
    DO
        EXECUTE IMMEDIATE C.RENAME;
        COMMIT;
    END FOR;
END
@
