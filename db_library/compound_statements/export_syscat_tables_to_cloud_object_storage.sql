--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Export system catalog views to Cloud Object Storage. 
 * 
 * These can then be loaded to another Db2 instance to allow "off-line" analysis of the database,
 *     including using the "snapshot" version of the db-lib against this data
 * 
 * Note that external tables don't currently support any column data longer than 64K bytes.
 * So the code below truncates any such columns
 * 
 * If on Db2 11.5.2.0 or above, use the BINARY data tarsfer option
*/

CREATE OR REPLACE VARIABLE DB_COS_ENDPOINT          VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_ACCESS_KEY_ID     VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_SECRET_ACCESS_KEY VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_BUCKET            VARCHAR(128) DEFAULT ''@

SET DB_COS_ENDPOINT          = 's3.private.eu.cloud-object-storage.appdomain.cloud' @
SET DB_COS_ACCESS_KEY_ID     = '......'    @
SET DB_COS_SECRET_ACCESS_KEY = '.....' @
SET DB_COS_BUCKET            = 'your_bucket_name' @

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
        'CREATE EXTERNAL TABLE ''' || RTRIM(TABSCHEMA) || '.' || TABNAME 
        || '.dat.lz4'''
--        || '.csv.gz'''
            ||  CHR(10) || 'USING ( s3(''' || DB_COS_ENDPOINT || ''',''' || DB_COS_ACCESS_KEY_ID || ''',''' || DB_COS_SECRET_ACCESS_KEY || ''',''' || DB_COS_BUCKET || ''')'
        ||  CHR(10) ||  ' FORMAT BINARY COMPRESS LZ4' 
--        ||  CHR(10) ||  ' FORMAT TEXT CCSID 1208 ESCAPECHAR ''~'' CTRLCHARS TRUE COMPRESS GZIP'
        || CHR(10) || ') AS SELECT '
        || LISTAGG(
               CASE WHEN TYPENAME IN ('BLOB','CLOB','DCLOB') THEN TYPENAME || '(' || '"' || COLNAME || '"'       
                 || CASE TYPESTRINGUNITS WHEN 'CODEUNITS32' THEN ',16383' 
                                         WHEN 'CODEUNITS16' THEN ',32767'
                                                            ELSE ',65535' END || ')'
             ELSE '"' || COLNAME || '"' END
            ,',') WITHIN GROUP ( ORDER BY COLNO)  
        || CHR(10) || 'FROM'
        || CHR(10) || '    "' || TABSCHEMA || '"."' || TABNAME || '"'
        || '@'  AS STMT
    FROM
        SYSCAT.COLUMNS JOIN SYSCAT.TABLES USING (TABSCHEMA, TABNAME)
    WHERE
        TABSCHEMA = 'SYSCAT'
    AND TABNAME IN 
        ('TABLES', 'COLUMNS', 'VIEWS', 'INDEXES', 'INDEXCOLUSE', 'TABLESPACES', 'TABDEP', 'VIEWDEP', 'KEYCOLUSE', 'TABCONST', 'THRESHOLDS'
        , 'WORKCLASSATTRIBUTES', 'DBPARTITONGROUPDEF', 'COLGROUPS', 'COLGROUPCOLS', 'BUFFERPOOLS')
    GROUP BY
        TABSCHEMA
    ,   TABNAME
    ORDER BY
            TABSCHEMA
        ,   TABNAME
    WITH UR
    DO
          EXECUTE IMMEDIATE C.STMT;
          COMMIT;
    END FOR;
END
