--# Copyright IBM Corp. All Rights Reserved.
--# SPDX-License-Identifier: Apache-2.0

/* 
 * A sample Connect Procedure to set special registers etc when users connect
 * 
 * Db2 allows a stored procedure to be called for all users at session connect time.
 * 
 * This can be used to global variables such as SQL_COMPAT 
 *   and special registers such as CURRENT PATH, CURRENT SCHEMA etc
 * 
 * For more details on connect procedures see the manual page here
 *   https://www.ibm.com/support/knowledgecenter/en/SSEPGG_11.5.0/com.ibm.db2.luw.admin.dbobj.doc/doc/c0057372.html
 * 
 * Please do **TEST** your procedure before run enabling it. 
 * 
 * If it returns an error, you will **LOCK YOURSELF** out of DB2 and you will need server access
 * to run the db cfg update without connectint to Db2.
 * 
 * If on Db2WoC you would need to raise a Support Case to fix a lock out
 * 
 */

--Unset any current connect proc
CALL ADMIN_CMD('UPDATE DB CFG USING CONNECT_PROC ""') 
@

CREATE OR REPLACE PROCEDURE DB_CONNECT_PROCEDURE ()
MODIFIES SQL DATA
LANGUAGE SQL
BEGIN
    --## NPS mode ##
    -- Set NPS mode for some users
    IF  VERIFY_ROLE_FOR_USER(SESSION_USER,'NETEZZA') = 1 
    THEN  
        SET SQL_COMPAT='NPS';
    END IF;
    --## NPS mode ##
    -- Set default isolation to Uncommited Read for some users
    IF  VERIFY_ROLE_FOR_USER(SESSION_USER,'WITH_UR') = 1 
    THEN  
        SET CURRENT ISOLATION = UR;
    END IF;
    --## PATH ##
    -- Set default path to include current schema, current user and schema "DB"  
    IF SYSTEM_USER NOT LIKE 'DB2INST%'                      -- exclude instance owner
     AND SYSTEM_USER NOT LIKE 'IBM%' AND SYSTEM_USER NOT LIKE 'SYS%' AND SYSTEM_USER NOT LIKE 'DB2%' -- exclude internal users
    THEN 
        EXECUTE IMMEDIATE(
             'SET CURRENT FUNCTION PATH SYSIBM,SYSFUN,SYSPROC,SYSIBMADM' 
             || ',' || CASE WHEN CURRENT SCHEMA <> CURRENT USER THEN CURRENT SCHEMA || ',' || CURRENT USER ELSE CURRENT USER END 
             || ',' || 'DB' );
    END IF;
END
@

-- The procedure needs to be callable by eveyone
GRANT EXECUTE ON PROCEDURE DB_CONNECT_PROCEDURE TO PUBLIC         
@

-- Now TEST your procedure, any run-time errors, and NO ONE, not even db2inst1 can connect.
CALL DB_CONNECT_PROCEDURE ()        
@

--Set new connect proc
CALL ADMIN_CMD('UPDATE DB CFG USING CONNECT_PROC "DB_CONNECT_PROCEDURE"') 
@
