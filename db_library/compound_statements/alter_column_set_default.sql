--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * Add a DEFAULT clause to every column in the tables selected 
 */
BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
        SELECT 'ALTER TABLE "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
        ||     ' ALTER COLUMN "' || COLNAME || '"'
        ||     ' SET DEFAULT'
            AS S1
        FROM SYSCAT.TABLES T JOIN SYSCAT.COLUMNS C USING (TABSCHEMA, TABNAME)
        WHERE T.TYPE = 'T'
        AND   T.TEMPORALTYPE = 'N'          -- exclude temportal tables
        AND   C.DEFAULT IS NULL 
        AND   C.KEYSEQ IS NULL              -- exclude PK columns
        AND   C.IDENTITY = 'N'              -- exclude identity columns
        AND   C.GENERATED = ''              -- exclude generated columns
        AND   T.TABSCHEMA = 'your schema'
        ORDER BY 
            TABSCHEMA
        ,   TABNAME
        WITH UR
    DO
          EXECUTE IMMEDIATE C.S1;
    --      COMMIT;                         -- skip the commit to make it run faster ?
    END FOR;
END
