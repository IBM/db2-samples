--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Scan every character column and record max length, use of multi-byte characters etc
 * 
 * The code currenty records the following for each character column
 * 
 * - Records the max byte length
 * - Records the max character length
 * - Records the min byte length
 * - Counts the number of rows that contain any multi-byte characters
 * - Counts the number of rows that have any trailing spaces
 * 
 *  Works on CHAR/VARCHAR/GRAPHIC/VARGRAPHIC/NCHAR/NVARCHAR and CLOB columns
 * 
 *  I.e. works fine on OCTETS, CODEUNITS16 and CODEUNITS32 columns
 * 
 *  Might not work on a non-Unicode database. I have not tested it on one.
 * 
 *  Best run on COLUMN ORGANIZEd tables as it runs one colum at a time.
 *  I've code somewhere to run efficiently on ROW ORGANIZD tables, but it is not below
*/

CREATE TABLE ANALYZE_COLUMNS
(
    TABSCHEMA         VARCHAR(128 OCTETS) NOT NULL
,   TABNAME           VARCHAR(128 OCTETS) NOT NULL
,   COLNAME           VARCHAR(128 OCTETS) NOT NULL
,   COLNO             SMALLINT            NOT NULL
,   TYPESCHEMA        VARCHAR(128 OCTETS) NOT NULL
,   TYPENAME          VARCHAR(128 OCTETS) NOT NULL
,   LENGTH            INTEGER             NOT NULL
,   SCALE             SMALLINT            NOT NULL
,   TYPESTRINGUNITS   VARCHAR(11 OCTETS)
,   STRINGUNITSLENGTH INTEGER
,   NULLS             CHAR(1)        NOT NULL
,   CODEPAGE          SMALLINT       NOT NULL
,   ROW_COUNT         BIGINT NOT NULL
,   NULL_COUNT        BIGINT NOT NULL
,   MULTI_BYTE_COUNT  BIGINT
,   MAX_LENGTHB       INTEGER
,   MAX_LENGTH4       INTEGER
,   MIN_LENGTHB       INTEGER
,   TRAILING_SPACES_COUNT BIGINT
,   TS                TIMESTAMP NOT NULL
,   PRIMARY KEY (TABSCHEMA, TABNAME, COLNAME) NOT ENFORCED
)
@
--TRUNCATE TABLE ANALYZE_COLUMNS IMMEDIATE


@
BEGIN
    DECLARE NOT_ALLOWED CONDITION FOR SQLSTATE '57016';   -- Skip LOAD pending tables etc. I.e. SQL0668N Operation not allowed 
    DECLARE UNDEFINED_NAME CONDITION FOR SQLSTATE '42704'; -- Skip tables that no longer exist/not commited
    DECLARE CONTINUE HANDLER FOR NOT_ALLOWED, UNDEFINED_NAME BEGIN END;
    ---
    FOR C AS cur CURSOR WITH HOLD FOR   
     SELECT
        'INSERT INTO ANALYZE_COLUMNS'
        || CHR(10) || 'SELECT'
        || CHR(10) || '    ''' || TABSCHEMA || ''' AS TABSCHEMA'
        || CHR(10) || ',   ''' || TABNAME   || ''' AS TABNAME'
        || CHR(10) || ',   ''' || COLNAME   || ''' AS COLNAME'
        || CHR(10) || ',   '   || COLNO     || '   AS COLNAME'
        || CHR(10) || ',   ''' || TYPESCHEMA || ''' AS TYPESCHEMA'
        || CHR(10) || ',   ''' || TYPENAME   || ''' AS TYPENAME'
        || CHR(10) || ',   '   || LENGTH     || ' AS LENGTH'
        || CHR(10) || ',   '   || SCALE      || ' AS SCALE'
        || CHR(10) || ',   ' || COALESCE('''' || TYPESTRINGUNITS   || '''','NULL') || ' AS TYPESTRINGUNITS'
        || CHR(10) || ',   ' || COALESCE(CHAR(STRINGUNITSLENGTH),'NULL') || ' AS STRINGUNITSLENGTH'
        || CHR(10) || ',   ''' || NULLS             || ''' AS NULLS'
        || CHR(10) || ',   ' || COALESCE('' || C.CODEPAGE         || '','NULL') || ' AS CODEPAGE'
        || CHR(10) || ',   COUNT(*) AS ROW_COUNT'
        || CHR(10) || ',   COUNT(*) - COUNT(' || '"' || COLNAME || '"'  || ') AS NULL_COUNT'
        || CHR(10) || ',   SUM(COALESCE(INT(LENGTHB("' || COLNAME || '"'
                                || CASE WHEN C.CODEPAGE = 1200 THEN '::VARCHAR)' ELSE ')' END      -- Cater for UTF-16 types
                           || ' > LENGTH4("' || COLNAME || '")),0))  AS MULTI_BYTE_COUNT'           
        || CHR(10) || ',   MAX(COALESCE(INT(LENGTHB(' 
                   ||           CASE WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'RTRIM("' || COLNAME || '")' ELSE  '"' || COLNAME || '"' END
                                     || CASE WHEN C.CODEPAGE = 1200 THEN '::VARCHAR)' ELSE ')' END || '),0)) AS MAX_LENGTHB'
        || CHR(10) || ',   MAX(COALESCE(INT(LENGTH4(' 
                   ||           CASE WHEN TYPENAME IN ('CHARACTER','GRAPHIC' ) THEN 'RTRIM("' || COLNAME || '")' ELSE  '"' || COLNAME || '"' END
                                     || CASE WHEN C.CODEPAGE = 1200 THEN '::VARCHAR)' ELSE ')' END || '),0)) AS MAX_LENGTH4'
        || CHR(10) || ',   MIN(COALESCE(INT(LENGTHB(' 
                    ||           CASE WHEN TYPENAME IN ('CHARACTER','GRAPHIC') THEN 'RTRIM("' || COLNAME || '")' ELSE  '"' || COLNAME || '"' END
                                     || CASE WHEN C.CODEPAGE = 1200 THEN '::VARCHAR)' ELSE ')' END || '),0)) AS MIN_LENGTHB'
        || CHR(10) || ',   SUM(COALESCE(INT(LENGTH("' || COLNAME || '")'
                           || ' > LENGTH(RTRIM("' || COLNAME || '"))),0))  AS TRAILING_SPACES_COUNT' 
        || ', CURRENT TIMESTAMP'
        || CHR(10) || ' FROM "' || RTRIM(TABSCHEMA) || '"."' || TABNAME || '"'
                AS S
    FROM
        SYSCAT.COLUMNS C JOIN SYSCAT.TABLES T USING ( TABSCHEMA, TABNAME )
    WHERE
        T.TYPE NOT IN ('A','N','V','W')
    AND T.TABLEORG = 'C'
    AND C.CODEPAGE > 0
    AND CARD > 0
    AND T.TABSCHEMA NOT LIKE 'SYS%'
    AND C.TYPESCHEMA NOT IN ('DB2GSE')
    AND  ( TABSCHEMA, TABNAME, COLNAME ) NOT IN (SELECT TABSCHEMA, TABNAME, COLNAME  FROM ANALYZE_COLUMNS)
--   and any schema/table filters here you wish
    --  AND TABSHEMA IN (....)
    --  AND TABNAME = 'AN'
    ORDER BY
        TABSCHEMA
    ,   TABNAME
    ,   COLNO
    WITH UR   
    DO
          EXECUTE IMMEDIATE C.S;
          COMMIT;
    END FOR;
END
@

SELECT * FROM ANALYZE_COLUMNS
