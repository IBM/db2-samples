--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Export tables to Cloud Object Storage.
 * 
 * In the code below, tables with more than half a million estimated rows are exported using PARTITION ALL
 * This means to need to know which tables these are to be able to re-import the data with the correct option.
 * If this is a pain, just use PARTITION ALL on an explit set of your large tables, or just on all tables.
 * 
 * If on Db2 11.5.2.0 or above, use the BINARY data tarsfer option
 * 
 * Note that is you have any LOB data, that will be truncated to 64K as (currently) external tables do not support long data
*/

-- Get Access Keys from a Service Credential you create with the "Include HMAC Credential" option selected
--- The keys you need will be in the "cos_hmac_keys" section of the JSON document for the Service Credential
CREATE OR REPLACE VARIABLE DB_COS_ENDPOINT          VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_ACCESS_KEY_ID     VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_SECRET_ACCESS_KEY VARCHAR(128) DEFAULT ''@
CREATE OR REPLACE VARIABLE DB_COS_BUCKET            VARCHAR(128) DEFAULT ''@

CREATE TABLE EXTRACT_LOG (
    TABCHEMA VARCHAR(128) NOT NULL
,   TABNAME  VARCHAR(128) NOT NULL
,   CARD     BIGINT NOT NULL
,   TS       TIMESTAMP NOT NULL
)
@

SET DB_COS_ENDPOINT          = 's3.private.eu.cloud-object-storage.appdomain.cloud' @
SET DB_COS_ACCESS_KEY_ID     = 'xxxx'    @
SET DB_COS_SECRET_ACCESS_KEY = 'xxxx' @
SET DB_COS_BUCKET            = 'xxxx' @

BEGIN
    FOR C AS cur CURSOR WITH HOLD FOR
    SELECT
        TABSCHEMA
    ,   TABNAME
    ,   MAX(CARD) CARD
    ,   VARCHAR('CREATE EXTERNAL TABLE ''' || RTRIM(TABSCHEMA) || '.' || TABNAME 
--        || '.dat.lz4'''
        || '.csv.gz'''
            ||  CHR(10) || 'USING ( s3(''' || DB_COS_ENDPOINT || ''',''' || DB_COS_ACCESS_KEY_ID || ''',''' || DB_COS_SECRET_ACCESS_KEY || ''',''' || DB_COS_BUCKET || ''')'
--        ||  CHR(10) ||  ' FORMAT BINARY COMPRESS LZ4' 
        ||  CHR(10) ||  ' FORMAT TEXT CCSID 1208 ESCAPECHAR ''~'' CTRLCHARS TRUE COMPRESS GZIP'
        || ' NOLOG true'  -- skip writing log files back to COS
--        ||  CASE WHEN MAX(CARD) > 500000 THEN ' PARTITION ALL' ELSE '' END 
        ||  ' PARTITION ALL'
        || CHR(10) || ') AS SELECT '
        || LISTAGG( VARCHAR('',32000) || 
--            COLNAME 
--          External tables doe not currently support LOB data, so truncate any such columns
        CASE WHEN TYPENAME IN ('BLOB','CLOB','DCLOB') THEN TYPENAME || '(' || '"' || COLNAME || '"'       
             || CASE TYPESTRINGUNITS WHEN 'CODEUNITS32' THEN ',16383' 
                                     WHEN 'CODEUNITS16' THEN ',32767'
                                                        ELSE ',65535' END || ')'
            ELSE '"' || COLNAME || '"' END
        ,',') WITHIN GROUP ( ORDER BY COLNO ) 
        || CHR(10) || 'FROM'
        || CHR(10) || '    "' || TABSCHEMA || '"."' || TABNAME || '"'
        ,32000) AS STMT
    FROM
        SYSCAT.TABLES JOIN SYSCAT.COLUMNS C USING ( TABSCHEMA, TABNAME )
    WHERE
        TYPE = 'T'
    AND C.HIDDEN <> 'I'
    AND TABSCHEMA = 'pick a schema'
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
          INSERT INTO EXTRACT_LOG VALUES ( TABSCHEMA, TABNAME, CARD, CURRENT_TIMESTAMP );
          COMMIT;
    END FOR;
END
