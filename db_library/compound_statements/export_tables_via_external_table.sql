--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Gnerate export and import sql to save/load table data to your client via external table
 * 
 * Supports CLOBs and XML upto 64K bytes long.
 * Generate SQL such as
 * 
 
CREATE EXTERNAL TABLE '/home/paul/git/db-lib/data/db2sampl/CUSTOMER.dat.lz4'
    USING ( REMOTESOURCE YES FORMAT BINARY COMPRESS LZ4) 
AS SELECT "CID",XMLSERIALIZE("INFO" AS CLOB(65535 OCTETS)),XMLSERIALIZE("HISTORY" AS CLOB(65535 OCTETS))
FROM "DB2INST1"."CUSTOMER"
 
 * and
 
INSERT INTO "CUSTOMER"
SELECT  * FROM EXTERNAL '/home/paul/git/db-lib/data/db2sampl/CUSTOMER.dat.lz4'
    ( "CID" BIGINT,"INFO" CLOB(65535 OCTETS),"HISTORY" CLOB(65535 OCTETS) )
    USING ( REMOTESOURCE YES FORMAT BINARY COMPRESS LZ4)

***/

-- Code Generator for the above
WITH C AS (
    SELECT * 
    ,   CASE WHEN TYPENAME IN ('BLOB','CLOB','DCLOB','XML') THEN 1 END 
                AS SPECIAL_HANDELLING
    ,   CASE WHEN TYPENAME IN ('BLOB','CLOB','DCLOB') THEN TYPENAME || '(' || '"' || COLNAME || '"'       
                 || CASE TYPESTRINGUNITS WHEN 'CODEUNITS32' THEN ',16383' 
                                         WHEN 'CODEUNITS16' THEN ',32767'
                                                            ELSE ',65535' END || ')'
                    WHEN TYPENAME = 'XML' THEN 'XMLSERIALIZE("' || COLNAME || '" AS CLOB(65535 OCTETS))'
                                                            ELSE '"' || COLNAME || '"' END 
                AS COL_SELECT
    ,   CASE
            WHEN TYPENAME IN ('BLOB','CLOB','DCLOB') THEN TYPENAME || '('    
                     || CASE TYPESTRINGUNITS WHEN 'CODEUNITS32' THEN '16383' 
                                             WHEN 'CODEUNITS16' THEN '32767'
                                                                ELSE '65535' END || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
            WHEN TYPENAME = 'XML' THEN 'CLOB(65535 OCTETS)'
            WHEN TYPENAME IN ('CHARACTER', 'VARCHAR', 'GRAPHIC', 'VARGRAPHIC', 'LONG VARCHAR','CLOB','DBCLOB') 
            THEN CASE WHEN TYPENAME = 'CHARACTER' THEN 'CHAR' ELSE TYPENAME END  
                 || '(' || COALESCE(STRINGUNITSLENGTH,LENGTH) || COALESCE(' ' || TYPESTRINGUNITS,'') || ')'
                 || CASE WHEN CODEPAGE = 0 THEN ' FOR BIT DATA' ELSE '' END
            WHEN TYPENAME IN ('BLOB', 'BINARY', 'VARBINARY') 
            THEN TYPENAME || '(' || LENGTH || ')'  
            WHEN TYPENAME IN ('TIMESTAMP') AND SCALE = 6
            THEN TYPENAME
            WHEN TYPENAME IN ('TIMESTAMP')
            THEN TYPENAME || '(' || RTRIM(CHAR(SCALE))  || ')'
            WHEN TYPENAME IN ('DECIMAL') AND SCALE = 0
            THEN TYPENAME || '(' || RTRIM(CHAR(LENGTH))  || ')'
            WHEN TYPENAME IN ('DECIMAL') AND SCALE > 0
            THEN TYPENAME || '(' || LENGTH || ',' || SCALE || ')'
            WHEN TYPENAME = 'DECFLOAT' AND LENGTH = 8  THEN 'DECFLOAT(16)' 
            ELSE TYPENAME END
                AS DATA_TYPE
    FROM SYSCAT.COLUMNS
)    
SELECT
    'CREATE EXTERNAL TABLE ''/home/paul/git/db-lib/data/db2sampl/' /* || RTRIM(TABSCHEMA) || '.' */ || TABNAME 
    || '.dat.lz4'''
--        || '.csv.gz'''
    || REPEAT(' ',(MAX(0,30 - LENGTH(RTRIM(TABSCHEMA) || '.' || TABNAME))))
    || ' USING ( REMOTESOURCE YES'
    ||  ' FORMAT BINARY COMPRESS LZ4' 
--        ||  CHR(10) ||  ' FORMAT TEXT CCSID 1208 ESCAPECHAR ''~'' CTRLCHARS TRUE COMPRESS GZIP'
    || ') AS SELECT '
    ||  CASE WHEN MAX(SPECIAL_HANDELLING) =  1 THEN
            LISTAGG(
               COL_SELECT
            ,',') WITHIN GROUP ( ORDER BY COLNO)  
        ELSE ' *' END
    || ' FROM'
    || ' "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
    || '@' AS EXPORT_STMT
--
,     'INSERT INTO ' || /* || RTRIM(TABSCHEMA) || '.' */ '"' || TABNAME || '"'
    || REPEAT(' ',(MAX(0,30 - LENGTH(RTRIM(TABSCHEMA) || '.' || TABNAME))))
    || ' SELECT '
    || ' * FROM'
    || ' EXTERNAL ''/home/paul/git/db-lib/data/db2sampl/' /* || RTRIM(TABSCHEMA) || '.' */|| TABNAME
    || '.dat.lz4'''
    || CASE WHEN MAX(SPECIAL_HANDELLING) IS NULL THEN ' LIKE "' /*|| RTRIM(TABSCHEMA) || '".' ||  */ || TABNAME || '"' 
        ELSE ' ( ' || LISTAGG(
               '"' || COLNAME || '" ' ||DATA_TYPE
            ,',') WITHIN GROUP ( ORDER BY COLNO) || ' )'
        END 
        || ' USING ( REMOTESOURCE YES'
    ||  ' FORMAT BINARY COMPRESS LZ4' 
--        ||  CHR(10) ||  ' FORMAT TEXT CCSID 1208 ESCAPECHAR ''~'' CTRLCHARS TRUE COMPRESS GZIP'
    || ') @' AS IMPORT_STMT
FROM
    C JOIN SYSCAT.TABLES USING (TABSCHEMA, TABNAME)
WHERE
    TABSCHEMA = (VALUES AUTH_GET_INSTANCE_AUTHID())
AND TYPE = 'T'    
GROUP BY
    TABSCHEMA
,   TABNAME
ORDER BY
        TABSCHEMA
    ,   TABNAME
WITH UR
