--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * A simple procedure to run SQL statements stored in a table and record the return code in the same table
 *  
 * The proc executes SQL in the table DB.RUN_SQL for rows where RUN_TIMESTAMP is NULL
 *  Updates the columns SQLCODE, EXEC_TIMESTAMP with the result of the exec
 * 
 *  It COMMITs each statement in turn, and does not stop until the end of the input table
 * 
 * Reset the run_timestamp if you want the proc to re-run a statement
 *   update db_run_sql set run_timestamp = null where sql_CODE < 0
 * 
 * Look at the reult with, e.g.
 *  SELECT SEQ, ROW_COUNT, DB2_TOKEN_STRING, MESSAGE_TEXT, SQL_CODE, SQL_STATE, RUN_TIMESTAMP FROM DB_RUN_SQL
 */

--DROP   TABLE DB_RUN_SQL
@
CREATE TABLE DB_RUN_SQL (
     SEQ INTEGER    NOT NULL
,    SQL_STMT       CLOB(2M)   NOT NULL
,    SQL_SCHEMA     VARCHAR(128)       NOT NULL WITH DEFAULT    --use this current schema
--,    AUTHID         VARCHAR(128)  NOT NULL WITH DEFAULT      --use this session authorization.  If used, would force a COMMIT
--,    CURRENT_PATH  VARCHAR(1024)  NOT NULL WITH DEFAULT      --use this current function path
--,  COMMIT_IND    BOOLEAN          NOT NULL WITH DEFAULT 0
,    START_TIMESTAMP    TIMESTAMP
,    END_TIMESTAMP      TIMESTAMP
,    ROW_COUNT          BIGINT
,    SQL_CODE           INTEGER
,    SQL_STATE          CHAR(5)
,    DB2_TOKEN_STRING   VARCHAR(1000)
,    MESSAGE_TEXT       VARCHAR(4000)
,    PRIMARY KEY (SEQ)
)
ORGANIZE BY ROW
IN USERSPACE1
@


CREATE OR REPLACE PROCEDURE DB_RUN_SQL()
LANGUAGE SQL
MODIFIES SQL DATA
BEGIN
    DECLARE SQLSTATE,V_SQL_STATE,E_SQL_STATE     CHAR(5); 
    DECLARE SQLCODE, V_SQL_CODE ,E_SQL_CODE      INT;
    DECLARE V_CONTINUE                           INT    DEFAULT 1;
--    DECLARE I                                   INT             DEFAULT 0;
    DECLARE V_SQL                                CLOB(2M);
    DECLARE V_SCHEMA                             VARCHAR(128);
    DECLARE V_ROW_COUNT, E_ROW_COUNT             BIGINT;
    DECLARE E_DB2_TOKEN_STRING                   VARCHAR(1000);
    DECLARE E_MESSAGE_TEXT                       VARCHAR(32672);
    DECLARE LOOP_C                               CURSOR WITH HOLD
        FOR SELECT
                SQL_STMT
            ,   SQL_SCHEMA
            FROM  DB_RUN_SQL
            WHERE START_TIMESTAMP IS NULL
            ORDER BY SEQ
            FOR UPDATE;
    --
    DECLARE CONTINUE HANDLER FOR NOT FOUND, SQLWARNING, SQLEXCEPTION BEGIN
        GET DIAGNOSTICS             E_ROW_COUNT        = ROW_COUNT;
        GET DIAGNOSTICS EXCEPTION 1 E_DB2_TOKEN_STRING = DB2_TOKEN_STRING
                                  , E_MESSAGE_TEXT     = MESSAGE_TEXT;
        SET ( V_CONTINUE, E_SQL_STATE, E_SQL_CODE ) = ( 1, SQLSTATE, SQLCODE ) ;     END;
     -- note that SQLWARNING triggers when eg. using an UPDATE or DELETE without a WHERE clause
     --    the NOT FOUND will also trigger when the FETCH goes past end of the cursor
    --
    OPEN    LOOP_C;
    FETCH   LOOP_C INTO V_SQL, V_SCHEMA;
    --
    WHILE(V_SQL IS NOT NULL AND V_CONTINUE = 1)
    DO   
        IF V_SCHEMA <> '' AND CURRENT SCHEMA <> V_SCHEMA THEN SET SCHEMA V_SCHEMA; END IF;
        --
        UPDATE DB_RUN_SQL 
            SET START_TIMESTAMP    = CURRENT_TIMESTAMP
        WHERE CURRENT OF LOOP_C;
        --
        EXECUTE IMMEDIATE V_SQL;
        GET DIAGNOSTICS             V_ROW_COUNT = ROW_COUNT;
        SET ( V_SQL_STATE, V_SQL_CODE ) = ( SQLSTATE, SQLCODE );
        --
        UPDATE DB_RUN_SQL 
            SET END_TIMESTAMP    = CURRENT_TIMESTAMP
            ,   ROW_COUNT        = COALESCE( E_ROW_COUNT, V_ROW_COUNT)
            ,   SQL_CODE         = COALESCE( E_SQL_CODE , V_SQL_CODE)
            ,   SQL_STATE        = COALESCE( E_SQL_STATE, V_SQL_STATE)
            ,   DB2_TOKEN_STRING =           E_DB2_TOKEN_STRING
            ,   MESSAGE_TEXT     =           E_MESSAGE_TEXT 
        WHERE CURRENT OF LOOP_C;
        --
        COMMIT;
        --
--        SET i = i + 1;
        SET (V_SQL, V_SCHEMA, V_ROW_COUNT, V_SQL_CODE, V_SQL_STATE                                     ) = (NULL,NULL,NULL,NULL,NULL          );
        SET (                 E_ROW_COUNT, E_SQL_CODE, E_SQL_STATE, E_DB2_TOKEN_STRING, E_MESSAGE_TEXT ) = (          NULL,NULL,NULL,NULL,NULL);
        --
        FETCH   LOOP_C INTO V_SQL, V_SCHEMA;
    END WHILE;
    CLOSE     LOOP_C;
    COMMIT; 
--    RETURN i;
END
@


--/* Testing..
INSERT INTO T VALUES (1),(3)
@
DELETE FROM DB_RUN_SQL WHERE 1=1
@
INSERT INTO DB_RUN_SQL (SEQ, SQL_STMT, SQL_SCHEMA)
VALUES 
       (1, 'INSERT INTO T VALUES (1)','PAUL')
,      (2, 'UPDATE T SET I = I + 1 WHERE 1=1','PAUL')
,      (3, 'UPDATE T SET I = I + 1','PAUL')
,      (6, 'DELETE FROM T','PAUL')
,      (7, 'INSERT INTO T VALUES (1)','PAUL')
@
SELECT * FROM T
@
CALL DB_RUN_SQL()
@
UPDATE T SET I = I + 1
@
SELECT SEQ, START_TIMESTAMP, END_TIMESTAMP, END_TIMESTAMP - START_TIMESTAMP AS DURATION, SQL_CODE, ROW_COUNT, SQL_STMT --, DB2_TOKEN_STRING, HEX(DB2_TOKEN_STRING)
, MESSAGE_TEXT, SQL_STATE FROM DB_RUN_SQL ORDER BY START_TIMESTAMP DESC NULLS LAST
@
UPDATE DB_RUN_SQL SET RUN_TIMESTAMP = NULL WHERE RUN_TIMESTAMP IS NULL
@
--*/