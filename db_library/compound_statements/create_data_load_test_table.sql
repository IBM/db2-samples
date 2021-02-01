--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Create an empty table LIKE another table, but with all columns changed to VARCHAR
 * 
 * If you are stuggling to load external data into Db2, a good technique can be
 * 
 * 1. Create a table that matches your target table, but with all columns set to VARCHAR
 * 2. Load your data to the VARCHAR table
 * 3. Select the table, and see if any column values have got into the wrong column
 * 
 * If you have some existing data loaded in your target table you can also
 *   create a view that converts all your target table columns to VARCHAR 
 *   which you can then UNION ALL with the VARCHAR table to compare data
 * 
 * Use the compound statement below to create _VARCHAR_TABLE 
 * and _VARCHAR_VIEW versions of your target table(s)
 * 
 * Remember to use FILLRECORD YES on your External Table load into the _VARCHAR_TABLE
 * to allow for the possability that you have fewer columns in your input file than you thought
 * 
 *  Example 
 * 
 *  INSERT INTO T_VARCHAR_TABLE SELECT * FROM EXTERNAL '/tmp/csv' using (REMOTESOURCE YES  DELIMITER ';' fillRecord yes)
 * 
 * DROP TABLE T_VARCHAR_TABLE
 * SELECT * FROM T_VARCHAR_TABLE UNION ALL
 * SELECT * FROM T_VARCHAR_VIEW 
 */

BEGIN
    FOR C AS
        SELECT
            'CREATE TABLE "' || TABSCHEMA || '"."' || TABNAME || '_VARCHAR_TABLE" ('
            ||   LISTAGG(CAST('' AS VARCHAR(32000 OCTETS)) || '"' || COLNAME || '" VARCHAR(1024)',', ') 
                    WITHIN GROUP (ORDER BY COLNO) || ')'AS VARCHAR_TABLE
        --        
        ,   'CREATE OR REPLACE VIEW "' || TABSCHEMA || '"."' || TABNAME || '_VARCHAR_VIEW" AS (SELECT '
            ||   LISTAGG(COLNAME || '::VARCHAR(1024) "' || COLNAME || '"',', ')
                WITHIN GROUP (ORDER BY COLNO) 
            || ' FROM "' || TABSCHEMA || '"."' || TABNAME || '" WHERE 1=0)'  AS VARCHAR_VIEW
        FROM 
            SYSCAT.COLUMNS
        WHERE TABNAME = 'Your Table'
        AND   TABSCHEMA = CURRENT SCHEMA
        AND HIDDEN <> 'I'
        GROUP BY
            TABSCHEMA
        ,   TABNAME
    DO
        EXECUTE IMMEDIATE C.VARCHAR_TABLE;
        EXECUTE IMMEDIATE C.VARCHAR_VIEW;
    END FOR;
END
