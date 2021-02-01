--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/*
 * Write DESIGN_ADVISOR output to a table
 * 
 * Db2 provides a DESIGN_ADVISOR procedure that returns a dynamic result set.
 * https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.sql.rtn.doc/doc/r0059509.html
 * 
 * This code writes that data to a persistent table which is much easier to work with
 */

DROP  TABLE  DB_DESIGN_ADVISOR     @
DROP  TABLE  DB_DESIGN_ADVISOR_OUT @
CREATE TABLE DB_DESIGN_ADVISOR (
    SCHEMA              VARCHAR(128 OCTETS) NOT NULL
,   NAME                VARCHAR(128 OCTETS) NOT NULL
,   EXISTS              CHAR(1 OCTETS)      NOT NULL
,   RECOMMENDATION      VARCHAR(8 OCTETS)   NOT NULL
,   BENEFIT             DOUBLE              NOT NULL
,   OVERHEAD            DOUBLE              NOT NULL
,   STATEMENT_NO        INTEGER             NOT NULL
,   DISKUSE             DOUBLE              NOT NULL
,   PRIMARY KEY (SCHEMA, NAME) NOT ENFORCED
) ORGANIZE BY ROW
@
CREATE TABLE DB_DESIGN_ADVISOR_OUT (
    TS                    TIMESTAMP(0)
,   OUT_XML_OUTPUT        BLOB(12K)
,   OUT_XML_MESSAGE       BLOB(64K)
) ORGANIZE BY ROW
@
-- Seed some workload into the ADVISE tables.
-- Can also get workload from other places, see db2advis options and change input XML in compound statement below
---   https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.admin.cmd.doc/doc/r0002452.html )
INSERT INTO SYSTOOLS.ADVISE_WORKLOAD VALUES('MY_WORKLOAD', 0, 'SELECT COUNT(*)     FROM DB.DB_DESIGN_ADVISOR','',100,0,0,0,0,'')@
INSERT INTO SYSTOOLS.ADVISE_WORKLOAD VALUES('MY_WORKLOAD', 1, 'SELECT AVG(DISKUSE) FROM DB.DB_DESIGN_ADVISOR WHERE NAME=''TEST'' ','',100,0,0,0,0,'')@

BEGIN
    DECLARE SQLSTATE CHAR(5 OCTETS);
    DECLARE V_SCHEMA              VARCHAR(128 OCTETS);
    DECLARE V_NAME                VARCHAR(128 OCTETS);
    DECLARE V_EXISTS              CHAR(1 OCTETS)     ;
    DECLARE V_RECOMMENDATION      VARCHAR(8 OCTETS)  ;
    DECLARE V_BENEFIT             DOUBLE             ;
    DECLARE V_OVERHEAD            DOUBLE             ;
    DECLARE V_STATEMENT_NO        INTEGER            ;
    DECLARE V_DISKUSE             DOUBLE             ;
    DECLARE INOUT_MAJOR_VERSION   INTEGER            ;
    DECLARE INOUT_MINOR_VERSION   INTEGER            ;
    DECLARE OUT_XML_OUTPUT        BLOB(12K)          ;
    DECLARE OUT_XML_MESSAGE       BLOB(64K)          ;
    DECLARE V1 RESULT_SET_LOCATOR VARYING;
    --
    SET INOUT_MAJOR_VERSION = 1;
    SET INOUT_MINOR_VERSION = 0;
    --
    /* -type options:
         I - for index selection, 
         M - for MQT selection,                             -- using this one gets a SQL670N from the SP on my test Db2 11.1.4.4 system
         C - for Multi-dimensional Clustering selection,
         P - for partitioning selection,
        Default is I

     */
    CALL SYSPROC.DESIGN_ADVISOR
        ( 
            INOUT_MAJOR_VERSION
        ,   INOUT_MINOR_VERSION
        ,   'en_US'
        ,   BLOB('
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
<key>MAJOR_VERSION</key><integer>1</integer>
<key>MINOR_VERSION</key><integer>0</integer>
<key>REQUESTED_LOCALE</key><string>en_US</string>
<key>CMD_OPTIONS</key><string>-workload MY_WORKLOAD -type ICP -timelimit 5</string>
</dict>
</plist>')
        ,   NULL
        ,   OUT_XML_OUTPUT
        ,   OUT_XML_MESSAGE
        );
    ASSOCIATE RESULT SET LOCATOR (V1) WITH PROCEDURE SYSPROC.DESIGN_ADVISOR;
    ALLOCATE C1 CURSOR FOR RESULT SET V1;
    --
    L1: LOOP
        FETCH C1                         INTO V_SCHEMA, V_NAME, V_EXISTS, V_RECOMMENDATION, V_BENEFIT, V_OVERHEAD, V_STATEMENT_NO, V_DISKUSE;
        IF SQLSTATE<>'00000' THEN LEAVE L1; END IF;        
        INSERT INTO DB_DESIGN_ADVISOR VALUES ( V_SCHEMA, V_NAME, V_EXISTS, V_RECOMMENDATION, V_BENEFIT, V_OVERHEAD, V_STATEMENT_NO, V_DISKUSE);
    END LOOP L1;
  CLOSE C1;
  INSERT INTO DB_DESIGN_ADVISOR_OUT VALUES ( CURRENT_TIMESTAMP, OUT_XML_OUTPUT, OUT_XML_MESSAGE );
END
@

SELECT * FROM DB_DESIGN_ADVISOR
@
SELECT * FROM DB_DESIGN_ADVISOR_OUT
@
SELECT * FROM SYSTOOLS.ADVISE_INDEX     @
SELECT * FROM SYSTOOLS.ADVISE_MQT       @
SELECT * FROM SYSTOOLS.ADVISE_PARTITION @
SELECT * FROM SYSTOOLS.ADVISE_TABLE     @
SELECT * FROM SYSTOOLS.ADVISE_INSTANCE  @
SELECT * FROM SYSTOOLS.ADVISE_WORKLOAD  @
