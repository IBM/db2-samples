--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Call DESCRIBE via ADMIN_CMD  and write the dynamic result sets to a persistent table
 * 
 *  Usefull if you want to post process this data in SQL
 *  , or if your SQL GUI tool does not display dynamic results sets from stored procedure calls
 * 
 */

DROP  TABLE DB_DESCRIBE_SELECT                     IF EXISTS @
DROP  TABLE DB_DESCRIBE_TABLE                      IF EXISTS @
DROP  TABLE DB_DESCRIBE_TABLE_PARTITION            IF EXISTS @
DROP  TABLE DB_DESCRIBE_INDEXES                    IF EXISTS @
DROP  TABLE DB_DESCRIBE_DATA_PARTITIONS            IF EXISTS @
DROP  TABLE DB_DESCRIBE_DATA_PARTITION_TABLESPACES IF EXISTS @

--Table 1: DESCRIBE select-statement, DESCRIBE call-statement and DESCRIBE XQUERY XQuery-statement commands
--https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0023570.html#r0023570__d300e1134
CREATE TABLE DB_DESCRIBE_SELECT (
     SQLTYPE_ID          SMALLINT        NOT NULL --  Data type of the column, as it appears in the SQLTYPE field of the SQL descriptor area (SQLDA).
,    SQLTYPE             VARCHAR(257)    NOT NULL --  Data type corresponding to the SQLTYPE_ID value.
,    SQLLEN              INTEGER         NOT NULL --  Length attribute of the column, as it appears in the SQLLEN field of the SQLDA.
,    SQLSCALE            SMALLINT        NOT NULL --  Number of digits in the fractional part of a decimal value; 0 in the case of other data types.
,    SQLNAME_DATA        VARCHAR(128)    NOT NULL --  Name of the column.
,    SQLNAME_LENGTH      SMALLINT        NOT NULL --  Length of the column name.
,    SQLDATA_TYPESCHEMA  VARCHAR(128)             -- Data type schema name.
,    SQLDATA_TYPENAME    VARCHAR(128)             -- Data type name.
)
@

--Table 2: Result set 1 for the DESCRIBE TABLE command
--https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0023570.html#r0023570__d300e1301
CREATE TABLE DB_DESCRIBE_TABLE  (
     COLNAME            VARCHAR(128)    NOT NULL -- Column name.
,    TYPESCHEMA         VARCHAR(128)    NOT NULL -- If the column name is distinct, the schema name is returned, otherwise, 'SYSIBM' is returned.
,    TYPENAME           VARCHAR(128)    NOT NULL -- Name of the column type.
,    FOR_BINARY_DATA    CHAR(1)         NOT NULL --  Returns 'Y' if the column is of type CHAR, VARCHAR or LONG VARCHAR, and is defined as FOR BIT DATA, 'N' otherwise.
,    LENGTH             INTEGER         NOT NULL --  Maximum length of the data. For DECIMAL data, this indicates the precision. For discinct types, 0 is returned.
,    SCALE              SMALLINT        NOT NULL --  For DECIMAL data, this indicates the scale. For all other types, 0 is returned.
,    NULLABLE           CHAR(1)                 --   'Y' if column is nullable.  'N' if column is not nullable
,    COLNO              SMALLINT                -- Ordinal of the column.
,    PARTKEYSEQ         SMALLINT                -- Ordinal of the column within the table's partitioning key. NULL or 0 is returned if the column is not part of the partitioning key, and is NULL for subtables and hierarchy tables.
,    CODEPAGE           SMALLINT                -- Code page of the column
,    DEFAULT            VARCHAR(254)            --  Default value for the column of a table expressed as a constant, special register, or cast-function appropriate for the data type of the column. Might also be NULL.
)
@

--Table 3: Result set 2 for the DESCRIBE TABLE command
-- https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0023570.html#r0023570__d300e1535
CREATE TABLE DB_DESCRIBE_TABLE_PARTITION (
    DATA_PARTITION_KEY_SEQ      INTEGER     NOT NULL -- Data partition key number, for example, 1 for the first data partition expression and 2 for the second data partition expression.
,   DATA_PARTITION_EXPRESSION   CLOB (32K)  --Expression for this data partition key in SQL syntax
)
@

--Table 4: DESCRIBE INDEXES FOR TABLE command
--https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0023570.html?view=kc#r0023570__d300e1593
CREATE TABLE DB_DESCRIBE_INDEXES (
     INDSCHEMA           VARCHAR(128)  -- Index schema name.
,    INDNAME             VARCHAR(128)  -- Index name.
,    UNIQUE_RULE         VARCHAR(30)   -- DUPLICATES_ALLOWED|PRIMARY_INDEX|UNIQUE_ENTRIES_ONLY
,    INDEX_PARTITIONING  CHAR(1)       -- N= Nonpartitioned index. P= Partitioned index.  Blank = Index is not on a partitioned table
,    COLCOUNT            SMALLINT      -- Number of columns in the key, plus the number of include columns, if any.
,    INDEX_TYPE          VARCHAR(30)   -- RELATIONAL_DATA|TEXT_SEARCH|XML_DATA_REGIONS|XML_DATA_PATH|XML_DATA_VALUES_LOGICAL|XML_DATA_VALUES_PHYSICAL
,    INDEX_ID            SMALLINT      -- Index ID for a relational data index, an XML path index, an XML regions index, or an index over XML data
,    DATA_TYPE           VARCHAR(128)  -- SQL data type specified for an index over XML data.  VARCHAR|DOUBLE|DATE|TIMESTAMP
,    HASHED              CHAR(1)       -- Indicates whether or not the value for an index over XML data is hashed. Y|N
,    LENGTH              SMALLINT      -- For an index over XML data, the VARCHAR (integer) length; 0 otherwise.
,    PATTERN             CLOB (2M)     -- XML pattern expression specified for an index over XML data
,    CODEPAGE            INTEGER       -- Document code page specified for the text search index
,    LANGUAGE            VARCHAR(5)    -- Document language specified for the text search index
,    FORMAT              VARCHAR(30)   -- Document format specified for a text search index
,    UPDATEMINIMUM       INTEGER       -- Minimum number of entries in the text search log table before an incremental update is performed
,    UPDATEFREQUENCY     VARCHAR(300)  -- Trigger criterion specified for applying updates to the text index
,    COLLECTIONDIRECTORY VARCHAR(512)  -- Directory specified for the text search index files
,    COLNAMES            VARCHAR(2048) -- List of the column names, each preceded with a + to indicate ascending order or a - to indicate descending order. 
)
@

--Table 5: Result set 1 for the DESCRIBE DATA PARTITIONS FOR TABLE command
--https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0023570.html?view=kc#r0023570__d300e2196
CREATE TABLE DB_DESCRIBE_DATA_PARTITIONS (
     DATA_PARTITION_ID   INTEGER         NOT NULL -- Data partition identifier.
,    LOW_KEY_INCLUSIVE   CHAR(1)         NOT NULL -- 'Y' if the low key value is inclusive, otherwise, 'N'.
,    LOW_KEY_VALUE       VARCHAR(512)    NOT NULL -- Low key value for this data partition.
,    HIGH_KEY_INCLUSIVE  CHAR(1)         NOT NULL -- 'Y' if the high key value is inclusive, otherwise, 'N'.
,    HIGH_KEY_VALUE      VARCHAR(512)    NOT NULL -- High key value for this data partition.
)
@

--Table 6: Result set 2 for the DESCRIBE DATA PARTITIONS FOR TABLE command
--https://www.ibm.com/support/knowledgecenter/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0023570.html?view=kc#r0023570__d300e2320
CREATE TABLE DB_DESCRIBE_DATA_PARTITION_TABLESPACES (
    DATA_PARTITION_ID   INTEGER         -- Data partition identifier.
,   DATA_PARTITION_NAME VARCHAR(128)    -- Data partition name.
,   TBSPID              INTEGER         -- Identifier of the table space where this data partition is stored.
,   PARTITION_OBJECT_ID INTEGER         -- Identifier of the DMS object where this data partition is stored.
,   LONG_TBSPID         INTEGER         -- Identifier of the table space where long data is stored.
,   INDEX_TBSPID        INTEGER         -- Identifier of the table space where index data is stored.
,   ACCESSMODE          VARCHAR(20)     -- Defines accessibility of the data partition and is one of: FULL_ACCESS|NO_ACCESS|NO_DATA_MOVEMENT|READ_ONLY
,   STATUS              VARCHAR(64)     -- Data partition status and can be one of: 
                                        --    NEWLY_ATTACHED
                                        --    NEWLY_DETACHED: MQT maintenance is required.
                                        --    INDEX_CLEANUP_PENDING: detached data partition whose tuple in SYSDATAPARTITIONS is maintained only for index cleanup. 
                                        --                          This tuple is removed when all index records referring to the detached data partition have been deleted.
                                        --    The column is blank otherwise.
)
@

TRUNCATE TABLE DB_DESCRIBE_SELECT IMMEDIATE @

-- DESCRIBE SELECT or CALL or XQUERY
BEGIN
    DECLARE SQLSTATE CHAR(5);
    DECLARE V_SQLTYPE_ID          SMALLINT       ;
    DECLARE V_SQLTYPE             VARCHAR(257)   ;
    DECLARE V_SQLLEN              INTEGER        ;
    DECLARE V_SQLSCALE            SMALLINT       ;
    DECLARE V_SQLNAME_DATA        VARCHAR(128)   ;
    DECLARE V_SQLNAME_LENGTH      SMALLINT       ;
    DECLARE V_SQLDATA_TYPESCHEMA  VARCHAR(128)   ;
    DECLARE V_SQLDATA_TYPENAME    VARCHAR(128)   ;
    --
    DECLARE V1 RESULT_SET_LOCATOR   VARYING;
    --
    CALL SYSPROC.ADMIN_CMD('DESCRIBE SELECT * FROM SYSCAT.TABLES JOIN SYSCAT.COLUMNS USING (TABSCHEMA, TABNAME)'); -- enter your table name here.  Do keep SHOW DETAIL as otherwise not all column below are returend and you will get an error
    ASSOCIATE RESULT SET LOCATOR (V1) WITH PROCEDURE SYSPROC.ADMIN_CMD;
    ALLOCATE C1 CURSOR FOR RESULT SET V1;
    --
    L1: LOOP
        FETCH C1                           INTO V_SQLTYPE_ID, V_SQLTYPE, V_SQLLEN, V_SQLSCALE, V_SQLNAME_DATA, V_SQLNAME_LENGTH, V_SQLDATA_TYPESCHEMA, V_SQLDATA_TYPENAME ;
        IF SQLSTATE<>'00000' THEN LEAVE L1; END IF;        
        INSERT INTO DB_DESCRIBE_SELECT VALUES ( V_SQLTYPE_ID, V_SQLTYPE, V_SQLLEN, V_SQLSCALE, V_SQLNAME_DATA, V_SQLNAME_LENGTH, V_SQLDATA_TYPESCHEMA, V_SQLDATA_TYPENAME );
    END LOOP L1;
    CLOSE C1;
    --
END
@
SELECT * FROM  DB_DESCRIBE_SELECT                     @



-- DESCRIBE TABLE SHOW DETAILS
BEGIN
    DECLARE SQLSTATE CHAR(5);
    DECLARE V_COLNAME            VARCHAR(128)  ;
    DECLARE V_TYPESCHEMA         VARCHAR(128)  ;
    DECLARE V_TYPENAME           VARCHAR(128)  ;
    DECLARE V_FOR_BINARY_DATA    CHAR(1)       ;
    DECLARE V_LENGTH             INTEGER       ;
    DECLARE V_SCALE              SMALLINT      ;
    DECLARE V_NULLABLE           CHAR(1)       ;
    DECLARE V_COLNO              SMALLINT      ;
    DECLARE V_PARTKEYSEQ         SMALLINT      ;
    DECLARE V_CODEPAGE           SMALLINT      ;
    DECLARE V_DEFAULT            VARCHAR(254)  ;
    --
    DECLARE V_DATA_PARTITION_KEY_SEQ      INTEGER   ;
    DECLARE V_DATA_PARTITION_EXPRESSION   CLOB (32K);
    --
    DECLARE V1 RESULT_SET_LOCATOR   VARYING;
    DECLARE V2 RESULT_SET_LOCATOR   VARYING;
    --
    CALL SYSPROC.ADMIN_CMD('DESCRIBE TABLE SYSIBM.TABLES SHOW DETAIL'); -- enter your table name here.  Do keep SHOW DETAIL as otherwise not all column below are returend and you will get an error
    ASSOCIATE RESULT SET LOCATOR (V1, V2) WITH PROCEDURE SYSPROC.ADMIN_CMD;
    ALLOCATE C1 CURSOR FOR RESULT SET V1;
    ALLOCATE C2 CURSOR FOR RESULT SET V2;
    --
    L1: LOOP
        FETCH C1                          INTO V_COLNAME, V_TYPESCHEMA, V_TYPENAME, V_FOR_BINARY_DATA, V_LENGTH, V_SCALE, V_NULLABLE, V_COLNO, V_PARTKEYSEQ, V_CODEPAGE, V_DEFAULT  ;
        IF SQLSTATE<>'00000' THEN LEAVE L1; END IF;        
        INSERT INTO DB_DESCRIBE_TABLE VALUES ( V_COLNAME, V_TYPESCHEMA, V_TYPENAME, V_FOR_BINARY_DATA, V_LENGTH, V_SCALE, V_NULLABLE, V_COLNO, V_PARTKEYSEQ, V_CODEPAGE, V_DEFAULT );
    END LOOP L1;
    CLOSE C1;
    --
    L2: LOOP
        FETCH C2                                    INTO V_DATA_PARTITION_KEY_SEQ, V_DATA_PARTITION_EXPRESSION ;
        IF SQLSTATE<>'00000' THEN LEAVE L2; END IF;        
        INSERT INTO DB_DESCRIBE_TABLE_PARTITION VALUES ( V_DATA_PARTITION_KEY_SEQ, V_DATA_PARTITION_EXPRESSION );
    END LOOP L2;
    CLOSE C2;
END
@

SELECT * FROM  DB_DESCRIBE_TABLE                      @
SELECT * FROM  DB_DESCRIBE_TABLE_PARTITION            @


/* TO-DO describe ffor INDEXES etc..    
 * -- can use this SQL to gen the column lists

SELECT LISTAGG('V_' || COLNAME,', ') WITHIN GROUP ( order by colno) 
, LISTAGG('' || COLNAME,', ') WITHIN GROUP ( order by colno)
FROM SYSCAT.COLUMNS WHERE TABNAME = 'DB_DESCRIBE_SELECT'


SELECT * FROM  DB_DESCRIBE_INDEXES                    @
SELECT * FROM  DB_DESCRIBE_DATA_PARTITIONS            @
SELECT * FROM  DB_DESCRIBE_DATA_PARTITION_TABLESPACES @
  
 */
