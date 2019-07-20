-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2007 All rights reserved.
-- 
-- The following sample of source code ("Sample") is owned by International 
-- Business Machines Corporation or one of its subsidiaries ("IBM") and is 
-- copyrighted and licensed, not sold. You may use, copy, modify, and 
-- distribute the Sample in any form without payment to IBM, for the purpose of 
-- assisting you in the development of your applications.
-- 
-- The Sample code is provided to you on an "AS IS" basis, without warranty of 
-- any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
-- IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
-- MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
-- not allow for the exclusion or limitation of implied warranties, so the above 
-- limitations or exclusions may not apply to you. IBM shall not be liable for 
-- any damages you suffer as a result of using, copying, modifying or 
-- distributing the Sample, even if IBM has been advised of the possibility of 
-- such damages.
-----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: healthmon.db2
--    
-- SAMPLE: How to use table functions for Health Monitor Snapshot
--
-- SQL STATEMENTS USED:
--         SELECT 
--         TERMINATE
--         UPDATE
--
-- OUTPUT FILE: healthmon.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts, 
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2 
-- applications, visit the DB2 application development website: 
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- HEALTH_MON parameter allows you to specify whether you want to monitor an 
-- instance, its associated databases, and database objects according to 
-- various health indicators. This parameter has to be set to ON.

UPDATE DBM CFG USING HEALTH_MON ON IMMEDIATE;

-- For each logical group (namely DBM, DB2, Tablespace and Container), there 
-- are three types of UDFs: INFO, HI (Health Indicator) and HI_HIS (Health 
-- Indicator HIStory) 

-- CREATE FUNCTION statement is used to register a UDF or function template
-- with application server. It has been included here to depict the prototype
-- of the UDFs and the table each of them return.

-- Usage of UDFs:
--   select *|<columnname>[,<columnname>] 
--   from table( <udfname>( [<database>,] <partition> )) as <aliasname>
-- where partition has the following values
-- 0..n, with n>0      partition number
-- -1                  means currently connected partition 
-- -2                  means all partitions

-- Snapshot monitor UDF for HMon Snapshot DBM header table

CREATE FUNCTION HEALTH_DBM_INFO ( INTEGER )
RETURNS TABLE (
    SNAPSHOT_TIMESTAMP           TIMESTAMP,
    SERVER_INSTANCE_NAME         VARCHAR(8),
    ROLLED_UP_ALERT_STATE        BIGINT,
    ROLLED_UP_ALERT_STATE_DETAIL VARCHAR(20),
    DB2START_TIME                TIMESTAMP,
    LAST_RESET                   TIMESTAMP,
    NUM_NODES_IN_DB2_INSTANCE    INT
)
SPECIFIC HEALTH_DBM_INFO
EXTERNAL NAME 'db2dbappext!health_dbm_info'
LANGUAGE C
PARAMETER STYLE db2sql
DETERMINISTIC
FENCED
CALLED ON NULL INPUT
NO SQL
EXTERNAL ACTION
SCRATCHPAD
FINAL CALL
DISALLOW PARALLEL;

SELECT SERVER_INSTANCE_NAME, 
       DB2START_TIME
FROM TABLE (HEALTH_DBM_INFO (CAST(NULL AS INTEGER)) ) 
AS HEALTH_DBM_INFO;

-- Snapshot monitor UDF for HMon Snapshot DBM Health Indicator table    

CREATE FUNCTION HEALTH_DBM_HI ( INTEGER )
RETURNS TABLE (
    SNAPSHOT_TIMESTAMP          TIMESTAMP,    
    HI_ID                       BIGINT,
    SERVER_INSTANCE_NAME        VARCHAR(8),
    HI_VALUE                    SMALLINT,
    HI_TIMESTAMP                TIMESTAMP,
    HI_ALERT_STATE              BIGINT,
    HI_ALERT_STATE_DETAIL       VARCHAR(20),
    HI_FORMULA                  VARCHAR(2048),
    HI_ADDITIONAL_INFO          VARCHAR(4096)
)
SPECIFIC HEALTH_DBM_HI
EXTERNAL NAME 'db2dbappext!health_dbm_hi'
LANGUAGE C
PARAMETER STYLE db2sql
DETERMINISTIC
FENCED
CALLED ON NULL INPUT
NO SQL
EXTERNAL ACTION
SCRATCHPAD
FINAL CALL
DISALLOW PARALLEL;

SELECT SNAPSHOT_TIMESTAMP, 
       HI_ID, 
       SERVER_INSTANCE_NAME,
       HI_VALUE, 
       HI_ALERT_STATE 
FROM TABLE (HEALTH_DBM_HI (CAST(NULL AS INTEGER)) )
AS HEALTH_DBM_HI;

-- Snapshot monitor UDF for HMon Snapshot DBM Health Indicator History table

CREATE FUNCTION HEALTH_DBM_HI_HIS ( INTEGER )
RETURNS TABLE (
    SNAPSHOT_TIMESTAMP          TIMESTAMP,    
    HI_ID                       BIGINT,
    SERVER_INSTANCE_NAME        VARCHAR(8),
    HI_VALUE                    SMALLINT,
    HI_TIMESTAMP                TIMESTAMP,
    HI_ALERT_STATE              BIGINT,
    HI_ALERT_STATE_DETAIL       VARCHAR(20),
    HI_FORMULA                  VARCHAR(2048),
    HI_ADDITIONAL_INFO          VARCHAR(4096)
)
SPECIFIC HEALTH_DBM_HI_HIS
EXTERNAL NAME 'db2dbappext!health_dbm_hi_his'
LANGUAGE C
PARAMETER STYLE db2sql
DETERMINISTIC
FENCED
CALLED ON NULL INPUT
NO SQL
EXTERNAL ACTION
SCRATCHPAD
FINAL CALL
DISALLOW PARALLEL;

SELECT SNAPSHOT_TIMESTAMP, 
       HI_ID, 
       SERVER_INSTANCE_NAME,
       HI_VALUE, 
       HI_ALERT_STATE 
FROM TABLE (HEALTH_DBM_HI_HIS (CAST(NULL AS INTEGER)) )
AS HEALTH_DBM_HI_HIS;

-- Snapshot monitor UDF for HMon Snapshot DB header table

CREATE FUNCTION HEALTH_DB_INFO ( VARCHAR(255), INTEGER )
RETURNS TABLE (
    SNAPSHOT_TIMESTAMP           TIMESTAMP,
    DB_NAME                      VARCHAR(8),  
    INPUT_DB_ALIAS               VARCHAR(8),  
    DB_PATH                      VARCHAR(256),  
    DB_LOCATION                  INT,      
    SERVER_PLATFORM              INT,      
    ROLLED_UP_ALERT_STATE        BIGINT,
    ROLLED_UP_ALERT_STATE_DETAIL VARCHAR(20)
)
SPECIFIC HEALTH_DB_INFO
EXTERNAL NAME 'db2dbappext!health_db_info'
LANGUAGE C
PARAMETER STYLE db2sql
DETERMINISTIC
FENCED
CALLED ON NULL INPUT
NO SQL
EXTERNAL ACTION
SCRATCHPAD
FINAL CALL
DISALLOW PARALLEL;

SELECT SNAPSHOT_TIMESTAMP,
       DB_NAME,
       INPUT_DB_ALIAS,
       DB_LOCATION,
       SERVER_PLATFORM
FROM TABLE (HEALTH_DB_INFO('SAMPLE', 0 )) AS HEALTH_DB_INFO;

-- Snapshot monitor UDF for HMon Snapshot Tablespace Health Indicator table

CREATE FUNCTION HEALTH_TBS_HI ( VARCHAR(255), INTEGER )
RETURNS TABLE (
   SNAPSHOT_TIMESTAMP           TIMESTAMP,
   TABLESPACE_NAME              VARCHAR(18),
   HI_ID                        BIGINT,
   HI_VALUE                     SMALLINT,
   HI_TIMESTAMP                 TIMESTAMP,
   HI_ALERT_STATE               BIGINT,
   HI_ALERT_STATE_DETAIL        VARCHAR(20),
   HI_FORMULA                   VARCHAR(2048),
   HI_ADDITIONAL_INFO           VARCHAR(4096)
)
SPECIFIC HEALTH_TBS_HI
EXTERNAL NAME 'db2dbappext!health_tbs_hi'
LANGUAGE C
PARAMETER STYLE db2sql
DETERMINISTIC
FENCED
CALLED ON NULL INPUT
NO SQL
EXTERNAL ACTION
SCRATCHPAD
FINAL CALL
DISALLOW PARALLEL;

SELECT TABLESPACE_NAME,
       HI_ID,
       HI_VALUE,
       HI_ALERT_STATE
FROM TABLE (HEALTH_TBS_HI( 'SAMPLE', 0 )) AS HEALTH_TBS_HI;

-- Snapshot monitor UDF for HMon Snapshot Container Health Indicator History
-- table

CREATE FUNCTION HEALTH_CONT_HI_HIS( VARCHAR(255), INTEGER )
RETURNS TABLE (
   SNAPSHOT_TIMESTAMP           TIMESTAMP,
   CONTAINER_NAME               VARCHAR(256),
   NODE_NUMBER                  INTEGER,
   HI_ID                        BIGINT,
   HI_VALUE                     SMALLINT,
   HI_TIMESTAMP                 TIMESTAMP,
   HI_ALERT_STATE               BIGINT,
   HI_ALERT_STATE_DETAIL        VARCHAR(20),
   HI_FORMULA                   VARCHAR(2048),
   HI_ADDITIONAL_INFO           VARCHAR(4096)
)
SPECIFIC HEALTH_CONT_HI_HIS
EXTERNAL NAME 'db2dbappext!health_cont_hi_his'
LANGUAGE C
PARAMETER STYLE db2sql
DETERMINISTIC
FENCED
CALLED ON NULL INPUT
NO SQL
EXTERNAL ACTION
SCRATCHPAD
FINAL CALL
DISALLOW PARALLEL;

SELECT CONTAINER_NAME,
       HI_VALUE,
       HI_TIMESTAMP,
       HI_VALUE
FROM TABLE (HEALTH_CONT_HI_HIS( 'SAMPLE', 0 )) AS HEALTH_CONT_HI_HIS;

ROLLBACK;

-- TERMINATE;
