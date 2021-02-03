--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Drop all tables/views/nickname/aliases for your selection
 * 
 * Use with caution !
 */

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'DROP '
        ||      CASE WHEN TYPE IN ('T','S','G') THEN 'TABLE '
                     WHEN TYPE = 'V'            THEN 'VIEW '
                     WHEN TYPE = 'N'            THEN 'NICKNAME '
                     WHEN TYPE = 'A'            THEN 'ALIAS '
                END
        || '"' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
            AS S1
        FROM SYSCAT.TABLES
        WHERE
            TABSCHEMA = ''
        AND TABNAME   = ''
        ORDER BY 
            TABSCHEMA
        ,   TABNAME
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S1;
--          COMMIT;
    END FOR;
END