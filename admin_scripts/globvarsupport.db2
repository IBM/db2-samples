-- ****************************************************************************
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
-- ****************************************************************************
--
-- SAMPLE FILE NAME: globvarsupport.db2
--
-- PURPOSE         : To demonstrate how to use global variables with DB2. 
--
-- USAGE SCENARIO  : This sample demonstrates how to exploit session global 
--                   variables in DB2.
--
-- PREREQUISITE    : NONE
--
-- EXECUTION       : db2 -tvf globvarsupport.db2
--
-- INPUTS          : NONE
--
-- OUTPUTS         : 
--
-- OUTPUT FILE     : globvarsupport.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
-- 	             COMMENT ON
--                   CREATE PROCEDURE
--                   CREATE TABLE
--                   CREATE TRIGGER
--                   CREATE VARIABLE
--                   CREATE VIEW
--                   DROP
--                   GRANT
--                   INSERT
--                   REVOKE
--                   SELECT
--                   SET
--                   VALUES
--
-- ****************************************************************************
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
-- http://www.software.ibm.com/data/db2/udb/ad
-- ****************************************************************************
--  SAMPLE DESCRIPTION
-- ****************************************************************************
-- The sample showcases the following:
--  1. Simple operations with global variables, such as:
--        *  creating and dropping of session global variable.
--        *  granting/revoking the permissions to/from users.
--        *  setting value to a global variable using SET statement.
--        *  adding comment to a global variable.
--        *  counting the number of global variables from catalog tables.
--        *  transferring the ownership of a variable.
--
--  2. Use of global variable in a trigger which can be used to control the 
--     operation on the trigger like switching off the trigger for maintenance. 
--
--  3. Use of global variable in a stored procedure.
--
--  4. Use of a global variable in a view to show how global variables can help 
--     to improve security and performance and to reduce complexity.
-- ****************************************************************************
--
-- ****************************************************************************
--    SETUP
-- ****************************************************************************
-- Connect to sample database.
CONNECT TO sample;

-- ****************************************************************************
-- 1.  Simple operations with global variables.
-- ****************************************************************************
-- The code below shows how users can perform different operations on 
-- global variables. 
-- ****************************************************************************
-- Create a session global variable.
CREATE VARIABLE myjob_current varchar (10) DEFAULT ('soft-engg');

-- Obtain information of the global variable created.
SELECT substr (varschema, 1, 10) as varschema, 
       substr (varname, 1, 10) AS varname,
       varid, substr(owner,1,10) AS owner, 
       ownertype, create_time, 
       substr(typeschema,1,10) AS typeschema, 
       substr(typename,1,10) AS typename, length 
  FROM syscat.variables 
  WHERE varname = 'MYJOB_CURRENT';

-- Give read and write permissions to users 'praveen' and 'sanjay'.
GRANT READ, WRITE ON VARIABLE myjob_current TO USER praveen, USER sanjay; 

-- Check the privileges for users 'praveen' and 'sanjay'.
SELECT substr (varschema, 1, 10) AS schema, 
       substr (varname, 1, 10) AS name,
       substr(grantor,1,10) AS grantor, grantortype AS Rtype, 
       substr(grantee,1,10) AS grantee, granteetype AS Etype, 
       readauth, writeauth 
  FROM syscat.variableauth 
  WHERE varname ='MYJOB_CURRENT'; 

-- Revoke write permission from user 'sanjay'
REVOKE WRITE ON VARIABLE myjob_current FROM USER sanjay;

-- Check the privilege for user 'sanjay' to verify write 
-- permission was revoked.
SELECT substr (varschema, 1, 10) AS schema, 
       substr (varname, 1, 10) AS name,
       substr(grantor,1,10) AS grantor, grantortype AS Rtype, 
       substr(grantee,1,10) AS grantee, granteetype AS Etype, 
       readauth, writeauth 
  FROM syscat.variableauth 
  WHERE varname ='MYJOB_CURRENT' AND grantee = 'SANJAY';

-- Assign value 'MGR' to global variable 'myjob_current'.
SET myjob_current = 'MGR';

-- Query the value of global variable 'myjob_current'.
VALUES myjob_current;

-- Add a comment to the  global variable 'myjob_current'.
COMMENT ON VARIABLE myjob_current IS 'Manager';

-- Check comment added to the global variable 'myjob_current'.
SELECT substr (varschema, 1, 10) AS varschema, 
       substr (varname, 1, 10) AS varname,
       substr (remarks, 1, 50) AS comment 
  FROM syscat.variables 
  WHERE varname = 'MYJOB_CURRENT';

-- Count the number of global variables created in the catalog 
-- The count should be one. 
SELECT count (*) FROM syscat.variables;

-- Drop the global variable.
DROP VARIABLE myjob_current;

-- ****************************************************************************
-- The code below shows users how ownership of a global variable 
-- can be transferred to another user.
-- ****************************************************************************

-- Create a session global variable.
CREATE VARIABLE myvar_transfer int;

-- Obtain information of the global variable created.
SELECT substr (varschema, 1, 10) AS varschema, 
       substr (varname, 1, 10) AS varname,
       substr (owner, 1, 10) AS owner, ownertype, create_time 
  FROM syscat.variables
  WHERE varname = 'MYVAR_TRANSFER';

SELECT substr (varschema, 1, 10) AS varschema, 
       substr (varname, 1, 10) AS varname,
       substr (grantor, 1, 10) AS grantor, grantortype, 
       substr (grantee, 1, 10) AS grantee, granteetype, 
       readauth, writeauth 
  FROM syscat.variableauth
  WHERE varname = 'MYVAR_TRANSFER';

-- Transfer ownership of the global variable to another user.
TRANSFER OWNERSHIP OF VARIABLE myvar_transfer 
  TO USER mohan PRESERVE PRIVILEGES;

-- Obtain information of the global variable after TRANSFER.
SELECT substr (varschema, 1, 10) AS varschema, 
       substr (varname, 1, 10) AS varname,
       substr (owner, 1, 10) AS owner, ownertype, create_time 
  FROM syscat.variables
  WHERE varname = 'MYVAR_TRANSFER';

SELECT substr (varschema, 1, 10) AS varschema, 
       substr (varname, 1, 10) AS varname,
       substr (grantor, 1, 10) AS grantor, grantortype, 
       substr (grantee, 1, 10) AS grantee, granteetype, 
       readauth, writeauth 
  FROM syscat.variableauth
  WHERE varname = 'MYVAR_TRANSFER';

-- Drop the  global variable.
DROP VARIABLE myvar_transfer;

-- ****************************************************************************
-- 2. Use of global variable in a trigger which can be used to control the
--    operation on the trigger like switching off the trigger for maintenance.
-- ****************************************************************************
-- The code below shows how users can use global variables within a trigger
-- to control the operation of the trigger.
-- ****************************************************************************

-- Create a global variable whose default value is set to 'N'. We will use 
-- this global variable to enable or disable the firing of the trigger. Its 
-- default will be 'N' since we want the trigger to be active by default.
CREATE VARIABLE disable_trigger char (1) DEFAULT ('N');

-- Grant write privilege only to the DBA User ID. We only want the DBA user to
-- be able to change the value of the global variable. This is because we want
-- to prevent regular users from being able to disable the trigger.
GRANT WRITE ON VARIABLE disable_trigger TO dba_user;

-- Create a trigger that depends on the global variable. The trigger will only fire
-- if the 'disable_trigger' global variable is set to 'N'.
CREATE TRIGGER validate_t BEFORE INSERT ON EMPLOYEE 
  REFERENCING NEW AS n FOR EACH ROW 
  WHEN (disable_trigger = 'N' AND n.empno > '10000') 
  SIGNAL SQLSTATE '38000'
  SET message_text = 'EMPLOYEE NUMBER TOO BIG and INVALID';

-- To diable the trigger the DBA will set the global variable to 'Y'.
SET disable_trigger = 'Y';

-- The DBA can perform table maintenance operations like for example importing older 
-- records since the trigger will not fire. After completing the table operations,
-- the DBA can set the global variable again to 'N'.
SET disable_trigger = 'N';

-- Drop the trigger.
DROP TRIGGER validate_t;

-- Drop the variable. 
DROP VARIABLE disable_trigger;

-- ****************************************************************************
--  3. Use of global variable in a stored procedure.
-- ****************************************************************************
-- The code below shows how to use global variables in a stored procedure. 
-- It returns the authorization level of the user invoking the stored 
-- procedure. The authorization level returned will be different depending on 
-- the user executing the stored procedure.
--
-- The idea of this example is that the users will only have permissions to 
-- execute the stored procedure and not to modify the global variable. Since 
-- the default value of the global variable is "SESSION_USER" it will get the 
-- correct value when called even if it was not set before. Each time the user  
-- logs in and calls this stored procedure he will receive the correct 
-- authorization level.
-- ****************************************************************************

-- Create the table 'security.users'.
CREATE TABLE security.users (userid varchar (10) NOT NULL PRIMARY KEY,
                             firstname varchar(10), lastname varchar(10), 
                             authlevel int);

-- Populate table with the following data.
INSERT INTO security.users VALUES ('praveen', 'sanjay', 'mohan', 1);
INSERT INTO security.users VALUES ('PRAVEEN', 'SANJAY', 'MOHAN', 1);
INSERT INTO security.users VALUES ('padma', 'gaurav', 'PADMA', 3);

-- Create a global variable.
CREATE VARIABLE security.gv_user VARCHAR (10) DEFAULT (SESSION_USER);

-- Create procedure 'get_authorization' that is dependent on the 
-- global variable 'security.gv_user'.
CREATE PROCEDURE get_authorization (OUT authorization INT)
RESULT SETS 1
LANGUAGE SQL
  SELECT authlevel INTO authorization
    FROM security.users
    WHERE userid = security.gv_user;

-- Assign 'praveen' to variable 'security.gv_user'.
SET security.gv_user = 'praveen';

-- Call stored procedure 'get_authorization'. 
-- The authorization level returned will be 1
call get_authorization(?);

-- Assign 'padma' to variable 'security.gv_user'.
SET security.gv_user = 'padma';

-- Call stored procedure 'get_authorization'. 
-- The authorization level returned will be 3
call get_authorization(?);

-- Drop a procedure. 
DROP PROCEDURE get_authorization;

-- Drop a variable. 
DROP VARIABLE security.gv_user;

-- Drop a table.
DROP TABLE security.users;

-- ****************************************************************************
--  4. Use of a global variable in a view to show how global variables can help
--     to improve security and performance and to reduce complexity.
-- ****************************************************************************
-- The code below shows how global variables along with views can be used to 
-- improve security, reduce complexity and improve performance.  
-- ****************************************************************************

-- A variable can be set by invoking a function that supplies the value
-- of the SESSION_USER special register to fetch the department number 
-- for the current user. A view can use the value of this global variable
-- in a predicate to select only those rows that contains the user's 
-- department. Since the value of the variable is set the 
-- first time it is invoked, then we only execute the query once instead of
-- doing it for each row if the query was embedded in the view definition. 
-- This will improve the performance.  

-- Create the global variable using a SELECT statement in the defination. 
CREATE VARIABLE schema1.gv_workdept CHAR 
         DEFAULT ((SELECT workdept FROM employee
  WHERE firstnme = SESSION_USER));

-- Create the view which depends on the global variable
CREATE VIEW schema1.emp_filtered AS 
  SELECT * FROM employee
  WHERE workdept = schema1.gv_workdept;

-- Adjust permissions so that other users can only select from the view. 
-- Any user using this view will only be able to see his department rows. 
GRANT SELECT on schema1.emp_filtered TO PUBLIC;

-- Drop a view.
DROP VIEW schema1.emp_filtered;

-- Drop a variable.
DROP VARIABLE schema1.gv_workdept;

-- Disconnect from the database.
CONNECT RESET;

TERMINATE;
