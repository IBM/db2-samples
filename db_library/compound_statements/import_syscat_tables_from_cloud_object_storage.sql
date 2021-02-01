--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Import syscat data exported to Cloud Object Storage from an Db2 database into user tables this database
 *  
 * Note that external tables don't currently support any column data longer than 64K bytes.
 * So the code below truncates any such columns when creating them
 */

CREATE OR REPLACE VARIABLE DB_COS_ENDPOINT          VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_ACCESS_KEY_ID     VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_SECRET_ACCESS_KEY VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_BUCKET            VARCHAR(128) DEFAULT ''@

SET DB_COS_ENDPOINT          = 's3.private.eu.cloud-object-storage.appdomain.cloud' @
SET DB_COS_ACCESS_KEY_ID     = '...'    @
SET DB_COS_SECRET_ACCESS_KEY = '...' @
SET DB_COS_BUCKET            = '...' @

SET SCHEMA your_snapshot_schema @

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
        'CREATE TABLE "' || TABNAME || '"'
        || CHR(32) || ' AS (SELECT '
        || LISTAGG(
               CASE WHEN TYPENAME IN ('BLOB','CLOB','DCLOB') THEN TYPENAME || '(' || '"' || COLNAME || '"'       
                 || CASE TYPESTRINGUNITS WHEN 'CODEUNITS32' THEN ',16383' 
                                         WHEN 'CODEUNITS16' THEN ',32767'
                                                            ELSE ',65535' END || ') AS ' || '"' || COLNAME || '"'  
             ELSE '"' || COLNAME || '"' END
            ,',') WITHIN GROUP ( ORDER BY COLNO)  
        || CHR(32) || 'FROM'
        || CHR(32) || '    "' || TABSCHEMA || '"."' || TABNAME || '"'       
        || ') WITH NO DATA' 
         AS CREATE_TABLE
     --
    ,   'INSERT INTO ' --|| RTRIM(TABSCHEMA) || '.' 
        || TABNAME 
        || CHR(10) || 'SELECT * FROM EXTERNAL ''' || RTRIM(TABSCHEMA) || '.' || TABNAME 
--        || '.dat.lz4'''
        || '.csv.gz'''
            ||  CHR(10) || 'USING ( s3(''' || DB_COS_ENDPOINT || ''',''' || DB_COS_ACCESS_KEY_ID || ''',''' || DB_COS_SECRET_ACCESS_KEY || ''',''' || DB_COS_BUCKET || ''')'
--        ||  CHR(10) ||  ' FORMAT BINARY COMPRESS LZ4' 
        ||  CHR(10) ||  ' FORMAT TEXT CCSID 1208 ESCAPECHAR ''~'' CTRLCHARS TRUE IGNOREZERO TRUE COMPRESS GZIP'
--        ||  CASE WHEN MAX(CARD) > 500000 THEN 'PARTITION ALL' ELSE '' END 
        || CHR(10) || ')'
         AS LOAD_TABLE
    FROM
        SYSCAT.COLUMNS JOIN SYSCAT.TABLES USING (TABSCHEMA, TABNAME)
    WHERE
        TABSCHEMA = 'SYSCAT'
    AND TABNAME IN 
        ('TABLES'
        , 'COLUMNS'
        , 'VIEWS', 'INDEXES'
--        'INDEXCOLUSE',
        ,  'TABLESPACES', 'TABDEP', 'VIEWDEP', 'KEYCOLUSE', 'TABCONST', 'THRESHOLDS'
        , 'WORKCLASSATTRIBUTES', 'DBPARTITONGROUPDEF')
        --, 'BUFFERPOOLS')
        --'COLGROUPS', 'COLGROUPCOLS', 
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ORDER BY
            TABSCHEMA
        ,   TABNAME
    WITH UR
    DO
        EXECUTE IMMEDIATE C.CREATE_TABLE;    
        EXECUTE IMMEDIATE C.LOAD_TABLE;
        COMMIT;
    END FOR;
END

