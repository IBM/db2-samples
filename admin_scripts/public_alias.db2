--/****************************************************************************
-- (c) Copyright IBM Corp. 2008 All rights reserved.
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
-- ******************************************************************************
--
-- SAMPLE FILE NAME: public_alias.db2
--
-- PURPOSE         : The purpose of this sample is to demonstrate the use of 
--                   public aliases for database objects such as tables and modules.
--                   This sample will demonstrate the following features:
--                      
--                     1) Use of public aliases for tables
--                     2) Use of private aliases for modules
--                     3) Use of public aliases for modules
--                     4) Object resolution
--
-- USAGE SCENARIO  : An enterprise database contains number of objects such as 
--                   tables, views, modules and so on. Some objects are created by 
--                   database administrators in a specific schema which can be used by other DBAs 
--                   to perform certain operations. Some objects are created by users 
--                   in their schema. Users use the fully qualified object name
--                   (<schema name>.<object name>) to use any object outside their 
--                   schema. There are some objects which are frequently used
--                   by the DBA or the user. It is preferable to create public aliases
--                   for frequently used objects because those objects can be referenced independently
--                   of the current SQL path or CURRENT SCHEMA by using by its simpler, 
--                   one-part name.
--                   
--
-- PREREQUISITE    : The following users should exist in the operating system.
--                   bob with password "bob12345"
--                   pat with password "pat12345"
--	
-- EXECUTION       : db2 -td@ -vf public_alias.db2
--                   
-- INPUT           : NONE
--
-- OUTPUT          : Successful creation of public alias.
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS  : 
--    USED           
--                   ALTER MODULE PUBLISH PROCEDURE
--                   ALTER MODULE ADD PROCEDURE
--                   ALTER MODULE DROP PROCEDURE
--                   CONNECT
--                   CREATE MODULE
--                   CREATE PUBLIC alias FOR TABLE
--                   CREATE PUBLIC alias FOR MODULE
--                   DROP MODULE
--                   DROP PUBLIC alias FOR TABLE
--                   DROP PUBLIC alias FOR MODULE
--                   SELECT
-- *************************************************************************
--
--  SAMPLE DESCRIPTION
--  
-- A. Schema used in the sample
--
-- 1) dba_object                  : Contains objects frequently used by DBAs. 
-- 
-- B. Tables used in the sample
--
-- 1) SYSIBMADM.APPLICATIONS      : Contains details of connected applications.
-- 2) SYSIBMADM.TBSP_UTILIZATION  : Contains details of tablespaces.
--
-- C. Aliases used in the sample
--
-- 1) app                : Public alias for the table SYSIBMADM.APPLICATIONS
-- 2) tbsp               : Public alias for the table SYSIBMADM.TBSP_UTILIZATION
-- 3) dbms_monit         : Public alias for the module database_monitoring
-- 4) db_monitoring      : Private alias for the module database_monitoring
--
-- D. The application processing is performed by the following routines:
--
-- 1) database_monitoring : Contains various stored procedures. This module is 
--                          used by DBAs to monitor the database.
--
-- a) tbsp_details        : Procedure to monitor table spaces.
--
-- b) app_details         : Procedure to monitor connected applications.
-- 
--
-- SAMPLE DETAILS
--
--  (1) Admin user creates PUBLIC alias "app", "tbsp" for table
--      SYSIBMADM.APPLICATIONS and SYSIBMADM.TBSP_UTILIZATION respectively.
--
--  (2) Admin creates a module database_monitoring in dba_object schema so
--      that DBAs can use it. 
--
--  (3) Admin user creates public alias dbms_monit for module database_monitoring.
-- 
--  (4) Admin user alters the module by adding procedures.
-- 
--  (5) User bob and pat use the module database_monitoring for monitoring the database,
--      but they use dbms_monit alias for monitoring.
--
--  (6) User pat creates one more module of same name dbms_monit in the schema "pat".
--
--  (7) User pat calls the procedure in different ways.
--
--  (8) User bob calls the procedure in different ways.
-- 
-- ***************************************************/
-- SET UP                                            */
-- ***************************************************/

-- Connect to Sample
CONNECT TO sample@

echo@
echo ********************************@
echo USE OF PUBLIC ALIASES FOR TABLE @
echo ********************************@
echo@

-- Create schema to store objects used by DBA
CREATE SCHEMA dba_object@
SET CURRENT SCHEMA = dba_object@
SET CURRENT PATH = CURRENT PATH, dba_object@

-- Create public alias for table SYSIBMADM.APPLICATIONS 
CREATE PUBLIC ALIAS app FOR TABLE SYSIBMADM.APPLICATIONS@

-- Create public alias for table SYSIBMADM.TBSP_UTILIZATION
CREATE PUBLIC ALIAS tbsp FOR TABLE SYSIBMADM.TBSP_UTILIZATION@


-- Create module database_monitoring
CREATE MODULE database_monitoring@

-- Grant execute privilege to user bob 
GRANT EXECUTE ON MODULE database_monitoring TO USER bob@

-- Reset connection
CONNECT RESET@


-- Connect to sample
CONNECT TO sample@

-- Alter module database_monitoring to publish procedure
-- tbsp_detail. Users will use full module name to alter  
-- the module.
ALTER MODULE dba_object.database_monitoring PUBLISH
PROCEDURE tbsp_detail()@

-- Alter module database_monitoring to publish procedure
-- app_detail. Users will use full module name to alter  
-- the module.
ALTER MODULE dba_object.database_monitoring PUBLISH
PROCEDURE app_detail()@


-- Alter module database_monitoring to add procedure
-- tbsp_detail. Users will use full module name to alter  
-- the module.
ALTER MODULE dba_object.database_monitoring ADD 
PROCEDURE tbsp_detail()
   BEGIN
   -- Declare variables
   DECLARE v_tbsp_id INTEGER;
   DECLARE v_tbsp_name CHAR(15);
   DECLARE v_tbsp_type CHAR(5);
   DECLARE v_tbsp_content_type CHAR(10);
   DECLARE v_tbsp_util_prcntg DECIMAL(5,2);
   DECLARE v_dbpgname CHAR(20);
   DECLARE c_tbsp_statistics CURSOR;

   SET c_tbsp_statistics = CURSOR FOR SELECT TBSP_ID, TBSP_NAME, 
   TBSP_TYPE, TBSP_CONTENT_TYPE, TBSP_UTILIZATION_PERCENT, 
   DBPGNAME 
   FROM tbsp;

   -- Open cursor c_tbsp_statistics
   OPEN c_tbsp_statistics;

      CALL DBMS_OUTPUT.NEW_LINE;
      CALL DBMS_OUTPUT.PUT_LINE('---------------------');
      CALL DBMS_OUTPUT.PUT_LINE('TABLESPACE STATISTICS');
      CALL DBMS_OUTPUT.PUT_LINE('---------------------');
      CALL DBMS_OUTPUT.NEW_LINE;

      CALL DBMS_OUTPUT.PUT ('TBSPACE ID'||'   '|| 'TBSPACE NAME'||'      '||
      'TYPE'||'    '||'CONTENT TYPE'||'  '|| '% USED'||'    '||'DBPAGENAME');

      CALL DBMS_OUTPUT.NEW_LINE;
      CALL DBMS_OUTPUT.PUT_LINE('----------'||'   '||'------------'||'      '||
      '----'||'    '||'------------'||'  '||'------'||'    '||'----------');

   fetch_loop:
   LOOP

  -- Fetch values from cursor
     FETCH FROM c_tbsp_statistics INTO 
     v_tbsp_id, v_tbsp_name, v_tbsp_type, v_tbsp_content_type,
     v_tbsp_util_prcntg, v_dbpgname;


      IF c_tbsp_statistics IS NOT FOUND
       THEN LEAVE fetch_loop;
      END IF;

     CALL DBMS_OUTPUT.NEW_LINE;
     CALL DBMS_OUTPUT.PUT(v_tbsp_id);
     CALL DBMS_OUTPUT.PUT('       ');
     CALL DBMS_OUTPUT.PUT('     ');
     CALL DBMS_OUTPUT.PUT(v_tbsp_name);
     CALL DBMS_OUTPUT.PUT('   ');
     CALL DBMS_OUTPUT.PUT(v_tbsp_type);
     CALL DBMS_OUTPUT.PUT('   ');
     CALL DBMS_OUTPUT.PUT(v_tbsp_content_type);
     CALL DBMS_OUTPUT.PUT('    ');
     CALL DBMS_OUTPUT.PUT(v_tbsp_util_prcntg);
     CALL DBMS_OUTPUT.PUT('     ');
     CALL DBMS_OUTPUT.PUT(v_dbpgname);
     CALL DBMS_OUTPUT.NEW_LINE;
   END LOOP fetch_loop;

   -- Close cursor c_tbsp_statistics
   CLOSE c_tbsp_statistics;
END@

echo @
echo ********************************@
echo USE OF PUBLIC ALIAS FOR MODULE @
echo ********************************@
echo @


-- Now admin user creates public alias for object dba_object.database_monitoring
-- which can be accessed by all the users who have privilege to use this 
-- object, without using the full object name.
CREATE PUBLIC ALIAS dbms_monit FOR MODULE dba_object.database_monitoring@

-- Reset connection
CONNECT RESET@


echo @
echo ********************************@
echo USE OF PRIVATE ALIAS FOR MODULE @
echo ********************************@
echo @

-- User bob calls the procedure in different ways
CONNECT TO SAMPLE USER bob USING bob12345@
SET SERVEROUTPUT ON@

-- Call module by using full object name
CALL dba_object.database_monitoring.tbsp_detail()@

-- Create private alias of object dba_object.database_monitoring 
-- to avoid use of full object name
CREATE ALIAS db_monitoring FOR MODULE dba_object.database_monitoring@

-- Call module by using private alias
CALL db_monitoring.tbsp_detail()@

-- Call module by using public alias
CALL dbms_monit.tbsp_detail()@

-- Connect to sample
CONNECT TO sample@

-- Alter module database_monitoring to add procedure
-- app_detail. Users will use full module name to alter  
-- the module.

ALTER MODULE dba_object.database_monitoring ADD 
PROCEDURE app_detail()
   BEGIN
   -- Declare variables
   DECLARE v_agent_id INTEGER ;
   DECLARE v_app_name CHAR(20);
   DECLARE v_auth_id CHAR(15);
   DECLARE v_app_id CHAR(26);
   DECLARE v_app_status CHAR(15);
   DECLARE c_app_detail CURSOR;

   SET c_app_detail = CURSOR FOR SELECT AGENT_ID, APPL_NAME, 
   AUTHID, APPL_ID, APPL_STATUS 
   FROM app
   ORDER BY AGENT_ID ASC;
 
   -- Open cursor c_app_detail
   OPEN c_app_detail;

      CALL DBMS_OUTPUT.NEW_LINE;
      CALL DBMS_OUTPUT.PUT_LINE('------------------');
      CALL DBMS_OUTPUT.PUT_LINE('APPLICATION STATUS');
      CALL DBMS_OUTPUT.PUT_LINE('------------------');
      CALL DBMS_OUTPUT.NEW_LINE;
      CALL DBMS_OUTPUT.PUT
       ('AGENT ID '||' '|| 'APPLICATION NAME '||'        '|| 
        'AUTHORIZATION ID '||'      '|| 'APPLICATION ID '||'                '||
        'STATUS');
	CALL DBMS_OUTPUT.NEW_LINE;
	CALL DBMS_OUTPUT.PUT_LINE('--------'||'  '|| 
	'----------------'||'  '||'      -----------------'||'      '||
	'-------------------------'||'      '|| '-----------');

     fetch_loop:
     LOOP

   -- Fetch values from cursor
      FETCH FROM c_app_detail INTO 
      v_agent_id, v_app_name, v_auth_id, v_app_id, 
      v_app_status;

      IF c_app_detail IS NOT FOUND
       THEN LEAVE fetch_loop;
      END IF;

	CALL DBMS_OUTPUT.NEW_LINE;
	CALL DBMS_OUTPUT.PUT(v_agent_id);
	CALL DBMS_OUTPUT.PUT('       ');
	CALL DBMS_OUTPUT.PUT(v_app_name);
	CALL DBMS_OUTPUT.PUT('     ');
	CALL DBMS_OUTPUT.PUT(v_auth_id);
	CALL DBMS_OUTPUT.PUT('       ');
	CALL DBMS_OUTPUT.PUT(v_app_id);
	CALL DBMS_OUTPUT.PUT('     ');
	CALL DBMS_OUTPUT.PUT(v_app_status);
	CALL DBMS_OUTPUT.NEW_LINE;

     END LOOP fetch_loop;

   -- Close cursor c_app_detail
   CLOSE c_app_detail;
END@

-- Reset connection
CONNECT RESET@

-- User bob calls the procedure in different ways
CONNECT TO SAMPLE USER bob using bob12345@
SET SERVEROUTPUT ON@

-- Call procedure by using full object name
CALL dba_object.database_monitoring.app_detail()@

-- Call procedure by using private alias
CALL db_monitoring.app_detail()@

-- Call procedure by using public alias
CALL dbms_monit.app_detail()@

-- Reset connection
CONNECT RESET@

echo@
echo ******************@
echo OBJECT RESOLUTION @
echo ******************@
echo@

-- Connect to sample 
CONNECT TO sample USER pat USING pat12345@

-- User pat creates one more module of same name in "pat" schema
CREATE MODULE dbms_monit@

-- Alter module dbms_monit to publish same procedure app_detail
ALTER MODULE dbms_monit PUBLISH 
PROCEDURE app_detail()@

ALTER MODULE dbms_monit ADD
PROCEDURE app_detail()
   BEGIN
   -- Declare variables
   DECLARE v_agent_id INTEGER ;
   DECLARE v_app_name CHAR(20);
   DECLARE v_app_status CHAR(15);
   DECLARE c_app_detail CURSOR;

   SET c_app_detail = CURSOR FOR SELECT AGENT_ID, APPL_NAME, 
   APPL_STATUS 
   FROM app 
   ORDER BY AGENT_ID ASC;
 
   -- Open cursor c_app_detail
   OPEN c_app_detail;

      CALL DBMS_OUTPUT.NEW_LINE;
      CALL DBMS_OUTPUT.PUT_LINE('------------------');
      CALL DBMS_OUTPUT.PUT_LINE('APPLICATION STATUS');
      CALL DBMS_OUTPUT.PUT_LINE('------------------');
      CALL DBMS_OUTPUT.NEW_LINE;
      CALL DBMS_OUTPUT.PUT
       ('AGENT ID '||'  '|| 'APPLICATION NAME '||'       '|| 'STATUS');
	CALL DBMS_OUTPUT.NEW_LINE;
	CALL DBMS_OUTPUT.PUT_LINE('--------'||'  '|| 
	'----------------'||'       '|| '-----------');

     fetch_loop:
     LOOP

   -- Fetch values from cursor
      FETCH FROM c_app_detail INTO 
      v_agent_id, v_app_name, v_app_status;

      IF c_app_detail IS NOT FOUND
       THEN LEAVE fetch_loop;
      END IF;

	CALL DBMS_OUTPUT.NEW_LINE;
	CALL DBMS_OUTPUT.PUT(v_agent_id);
	CALL DBMS_OUTPUT.PUT('       ');
	CALL DBMS_OUTPUT.PUT(v_app_name);
	CALL DBMS_OUTPUT.PUT('     ');
	CALL DBMS_OUTPUT.PUT(v_app_status);
	CALL DBMS_OUTPUT.NEW_LINE;

     END LOOP fetch_loop;

   -- Close cursor c_app_detail
   CLOSE c_app_detail;
END@


-- User pat calls the procedure in different ways
SET SERVEROUTPUT ON@

-- Call procedure of schema pat
CALL dbms_monit.app_detail()@

echo "Above output is expected"@
echo@

-- Reset connection
CONNECT RESET@

-- User bob drops procedure from module 
CONNECT TO sample user bob using bob12345@
SET SERVEROUTPUT ON@

-- Alter module by dropping procedure   
ALTER MODULE pat.dbms_monit 
DROP PROCEDURE app_detail@

echo "Above output is expected"@
echo@

-- Call procedure
CALL dbms_monit.app_detail()@

 -- User pat drops procedure from module
CONNECT TO sample USER pat USING pat12345@
SET SERVEROUTPUT ON@

-- Alter module by dropping procedure
ALTER MODULE dbms_monit 
DROP PROCEDURE app_detail@

-- Call procedure
CALL dbms_monit.app_detail()@

echo "Above output is expected"@
echo@

-- Drop module dbms_monit
DROP MODULE dbms_monit@

-- Call procedure after dropping module
CALL dbms_monit.app_detail()@

echo "Above output is expected"@
echo@

-- Reset connection
CONNECT RESET@

-- Drop modules and aliases
CONNECT TO sample@

DROP PUBLIC ALIAS app FOR TABLE@
DROP PUBLIC ALIAS tbsp FOR TABLE @
DROP ALIAS bob.db_monitoring FOR MODULE@
DROP MODULE dba_object.database_monitoring@
DROP PUBLIC ALIAS dbms_monit FOR MODULE@
DROP SCHEMA dba_object RESTRICT@

CONNECT RESET@
