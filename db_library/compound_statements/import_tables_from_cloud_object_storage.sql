--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Import tables from Cloud Object Storage or S3 that were exported using the export compound statement
 * 
 * The code assumes that you have already copied the DDL and that all tables were exported with PARTITION ALL
 * If tables are small, you will need to not use PARTITION ALL as you won't get a file if there are no rows on a data slice.
 */

CREATE TABLE IMPORT_LOG (
    TABCHEMA    VARCHAR(128) NOT NULL
,   TABNAME     VARCHAR(128) NOT NULL
,   FILE_FOUND  SMALLINT NOT NULL
,   TS          TIMESTAMP NOT NULL
)

CREATE OR REPLACE VARIABLE DB_COS_ENDPOINT          VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_ACCESS_KEY_ID     VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_SECRET_ACCESS_KEY VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_BUCKET            VARCHAR(128) DEFAULT ''@

-- Get Access Keys from a Service Credential you create with the "Include HMAC Credential" option selected
--- The keys you need will be in the "cos_hmac_keys" section of the JSON document for the Service Credential
SET DB_COS_ENDPOINT          = 's3.private.eu.cloud-object-storage.appdomain.cloud' @
SET DB_COS_ACCESS_KEY_ID     = 'xxxx'  @
SET DB_COS_SECRET_ACCESS_KEY = 'xxxx' @
SET DB_COS_BUCKET            = 'xxxx' @

BEGIN 
   DECLARE NO_FILE CONDITION FOR SQLSTATE '428IB';      -- Cater for tables with 0 rows that don't have an input file to load
   DECLARE file_found INTEGER DEFAULT 1;
   DECLARE CONTINUE HANDLER FOR NO_FILE SET file_found = 0;
--  
    FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   'INSERT INTO ' || RTRIM(TABSCHEMA) || '."' || TABNAME  || '"'
        || CHR(10) || 'SELECT * FROM EXTERNAL ''' || RTRIM(TABSCHEMA) || '.' || TABNAME 
        || '.dat.lz4'''
--        || '.csv.gz'''
            ||  CHR(10) || 'USING ( s3(''' || DB_COS_ENDPOINT || ''',''' || DB_COS_ACCESS_KEY_ID || ''',''' || DB_COS_SECRET_ACCESS_KEY || ''',''' || DB_COS_BUCKET || ''')'
        ||  CHR(10) ||  ' FORMAT BINARY COMPRESS LZ4' 
--        ||  CHR(10) ||  ' FORMAT TEXT CCSID 1208 ESCAPECHAR ''~'' CTRLCHARS TRUE IGNOREZERO TRUE CRINSTRING true COMPRESS GZIP'
--        || ' NOLOG true'  -- skip writing log files back to COS
--        ||  CASE WHEN CARD > 500000 THEN ' PARTITION ALL' ELSE '' END 
        || ' PARTITION ALL'
        || CHR(10) || ')'
         AS STMT
    FROM
        REMOTE_SERVER.SYSCAT.TABLES -- if not using CARD to detrimine if to use PARTITION ALL, could just use the local SYSCAT.TABLES
    WHERE
        TYPE = 'T'
    AND TABSCHEMA = 'Your Schema'
    ORDER BY
            TABSCHEMA
        ,   TABNAME
    WITH UR
    DO
        EXECUTE IMMEDIATE C.STMT;
        COMMIT;
        INSERT INTO IMPORT_LOG VALUES ( TABSCHEMA, TABNAME, file_found, CURRENT_TIMESTAMP );
        COMMIT;
        SET file_found = 1;
    END FOR;
END
