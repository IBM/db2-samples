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
-- SAMPLE FILE NAME: databaseroles.db2
--
-- PURPOSE         : To demonstrate how database roles can be used in DB2 LUW.
--
-- USAGE SCENARIO  : In an enterprise, each employee has certain privileges
--                   based on his/her role in each department. When an
--                   employee joins, leaves or moves to or from a different
--                   department, permissions need to be
--                   granted, revoked, or transferred on department specific
--                   database objects individually. This sample demonstrates
--                   how all these can easily be done in single statement using
--                   roles.
--
--                   The sample uses a scenario of an enterprise with three
--                   departments DEVELOPMENT, TESTING, and SALES and three new
--                   employees JOE, BOB, and PAT, joining the three departments
--                   respectively. Employees for each department should have
--                   access to only department specific information (tables)
--                   and in case an employee gets transferred to another
--                   department or leaves the enterprise, the permissions need
--                   to be modified accordingly. The sample demonstrates how
--                   the enterprise DBA's task of modifying permission on
--                   different database objects for different users can be
--                   simplified by the creation of database roles.
--
-- PREREQUISITE    : The following users should exist in the operating system.
--
--                   newton with password "Way2discoveR" in SYSADM group.
--                   john with password "john123456"
--                   joe  with password "joe123456"
--                   bob  with password "bob123456"
--                   pat  with password "pat123456"
--
--
-- EXECUTION       : db2 -tvf databaseroles.db2
--
-- INPUTS          : NONE
--
-- OUTPUTS         : Roles will be created and dropped in the database.
--
-- OUTPUT FILE     : databaseroles.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--                   CREATE ROLE
--                   CREATE TABLE
--                   CRETE VIEW
--                   CONNECT
--                   DROP
--                   GRANT
--                   INSERT
--                   REVOKE
--                   SELECT
--                   TRANSFER
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
--  1: How to GRANT select privilege to users through ROLES.
--  2. How to replace GROUPS with ROLES.
--  3: How to transfer ownership of database objects.
--  4: How to REVOKE privileges from roles.
--  5: How to build a role hierarchy.
--  6: GRANT-ing and REVOKE-ing WITH ADMIN OPTIONS to and from an
--     authorization ID.
-- ****************************************************************************

-- ****************************************************************************
--    SETUP
-- ****************************************************************************

CONNECT TO sample; 

-- Create tables TEMP_EMPLOYEE and TEMP_DEPARTMENT under 'newton' schema.
CREATE TABLE newton.TEMP_EMPLOYEE LIKE EMPLOYEE;
CREATE TABLE newton.TEMP_DEPARTMENT LIKE DEPARTMENT;

-- Populate the above created tables with the data from EMPLOYEE & DEPARTMENT tables.

-- export the table data to file 'load_employee.ixf'.
EXPORT TO load_employee.ixf OF IXF SELECT * FROM EMPLOYEE;

-- loading data from data file inserting data into the table TEMP_EMPLOYEE.
LOAD FROM load_employee.ixf of IXF INSERT INTO newton.TEMP_EMPLOYEE;

-- export the table data to file 'load_department.ixf'.
EXPORT TO load_department.ixf OF IXF SELECT * FROM DEPARTMENT;

-- loading data from data file inserting data into the table TEMP_DEPARTMENT.
LOAD FROM load_department.ixf of IXF INSERT INTO newton.TEMP_DEPARTMENT;

-- ----------------------------------------------------------------------------
-- 1: How to GRANT select privilege to users through ROLES.
-- ----------------------------------------------------------------------------
-- Usage scenario :
-- The code below shows how to GRANT/REVOKE select privilege to users JOE and
-- BOB through role DEVELOPMENT_ROLE. User JOHN, who is a
-- security administrator(SECADM), creates a role DEVELOPMENT_ROLE and grants
-- employees JOE and BOB, working in department DEVELOPMENT, SELECT privilege
-- on tables DEV_TABLE1 and DEV_TABLE2 via DEVELOPMENT_ROLE.
-- The sample also shows how REVOKING of the DEVELOPMENT_ROLE from employees
-- JOE and BOB causes employees JOE and BOB to lose SELECT privilege on
-- tables DEV_TABLE1 and DEV_TABLE2. At this point, if employees JOE and
-- BOB try to perform a select operation on tables DEV_TABLE1 and DEV_TABLE2,
-- the select statement will fail.  The sample also shows when a new
-- employee PAT joins department DEVELOPMENT, she is granted SELECT privilege
-- on the two development tables via DEVELOPMENT_ROLE.
-- ----------------------------------------------------------------------------

-- Connect to sample database using user NEWTON.
CONNECT TO sample user newton using Way2discoveR;

-- Grant SECADM authority to a user JOHN.
GRANT SECADM ON DATABASE TO USER john;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO sample USER john USING john123456;

-- Create role DEVELOPMENT_ROLE. Only a user with SECADM authority can create
-- the role. In this sample user JOHN is assigned SECADM authority and has
-- the privilege to create the roles.
CREATE ROLE development_role;

-- Create tables DEV_TABLE1 and DEV_TABLE2. Any user can create these tables.
-- In the sample these tables are created by user JOHN.
CREATE TABLE dev_table1 (project VARCHAR(25), dept_no INT);
INSERT INTO dev_table1 VALUES ('DB0', 1);

CREATE TABLE dev_table2 (defect_no INT, scheme_repository VARCHAR(25));
INSERT INTO dev_table2 VALUES (100, 'wsdbu');

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user NEWTON(SYSADM).
-- User NEWTON is system administrator(SYSADM).
CONNECT TO sample user newton using Way2discoveR;

-- Grant SELECT privilege on tables DEV_TABLE1 and DEV_TABLE2 to role
-- DEVELOPMENT_ROLE.
GRANT SELECT ON TABLE john.dev_table1
  TO ROLE development_role;
GRANT SELECT ON TABLE john.dev_table2
  TO ROLE development_role;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO sample user john using john123456;

-- Grant role DEVELOPMENT_ROLE to users JOE and BOB.
GRANT ROLE development_role TO USER joe, USER bob;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOE.
CONNECT TO sample USER joe USING joe123456;

-- User JOE is granted DEVELOPMENT_ROLE role and hence gains select privilege
-- on the tables DEV_TABLE1 and DEV_TABLE2 through membership of this role.
-- SELECT from tables DEV_TABLE1 and DEV_TABLE2 to verify user JOHN has
-- select privileges.
SELECT * FROM john.dev_table1;
SELECT * FROM john.dev_table2;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user BOB
CONNECT TO sample USER bob USING bob123456;

-- User BOB is granted DEVELOPMENT_ROLE role and hence gains select privilege
-- on the tables DEV_TABLE1 and DEV_TABLE2 through membership of this role.
-- SELECT from tables DEV_TABLE1 and DEV_TABLE2 to verify user BOB has select
-- privileges.

SELECT * FROM john.dev_table1;
SELECT * FROM john.dev_table2;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO sample user john using john123456;

-- REVOKE the role DEVELOPMENT_ROLE from users JOE and BOB.
REVOKE ROLE development_role FROM USER joe, USER bob;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOE.
CONNECT TO sample USER joe USING joe123456;

-- The following two SELECT statements will fail. Users JOE cannot perform
-- SELECT on the tables DEV_TABLE1 and DEV_TABLE2 now. JOE has lost SELECT
-- privilege on these tables as role DEVELOPMENT_ROLE was revoked from him.

-- Error displayed for the following SELECT statement will be :
-- SQL0551N  "JOE" does not have the privilege to perform operation "SELECT"
-- on object "JOHN.DEV_TABLE1".  SQLSTATE=42501
SELECT * FROM john.dev_table1;
!echo "Above error is expected !";

-- Error displayed for the following SELECT statement will be :
-- SQL0551N  "JOE" does not have the privilege to perform operation "SELECT"
-- on object "JOHN.DEV_TABLE2".  SQLSTATE=42501
SELECT * FROM john.dev_table2;
!echo "Above error is expected !";

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user BOB
CONNECT TO sample USER bob USING bob123456;

-- The following two SELECT statements will fail as user BOB has lost SELECT
-- privilege on these tables as the role DEVELOPMENT_ROLE was revoked
-- from him.

-- Error displayed for the following SELECT statement will be :
-- SQL0551N  "BOB" does not have the privilege to perform operation "SELECT"
-- on object "JOHN.DEV_TABLE1".  SQLSTATE=42501
SELECT * FROM john.dev_table1;
!echo "Above error is expected !";

-- Error displayed for the following SELECT statement will be :
-- SQL0551N  "BOB" does not have the privilege to perform operation "SELECT"
-- on object "JOHN.DEV_TABLE2".  SQLSTATE=42501
SELECT * FROM john.dev_table2;
!echo "Above error is expected !";

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN.
CONNECT TO sample USER john USING john123456;

-- Grant role DEVELOPMENT_ROLE to new employee PAT.
-- Once this is done, PAT can SELECT from tables DEV_TABLE1
-- and DEV_TABLE2.
GRANT ROLE development_role TO USER pat;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user PAT.
CONNECT TO sample USER pat USING pat123456;

-- The following two SELECT statements will be successful.
SELECT * FROM john.dev_table1;
SELECT * FROM john.dev_table2;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO sample USER john USING john123456;

-- Drop the tables.
DROP TABLE dev_table1;
DROP TABLE dev_table2;

-- Drop the role. Only a user having SECADM authority can drop the role.
DROP ROLE development_role;

-- Disconnect from sample database.
CONNECT RESET;

-- ----------------------------------------------------------------------------
--  2. How to replace GROUPS with ROLES.
-- ----------------------------------------------------------------------------
-- Usage scenario:
-- Assume there are three groups DEVELOPER_G, TESTER_G, and SALES_G and three
-- users (BOB, JOE and PAT) defined in the operating system.
-- BOB belongs to group DEVELOPER_G and SALES_G, JOE
-- belongs to group TESTER_G and SALES_G and PAT belongs to group TESTER_G.
-- Roles DEVELOPER, TESTER and SALES will be created and used instead of groups
-- DEVELOPER_G, TESTER_G, and SALES_G respectively . In this scenario, all the
-- privileges held by GROUPS will be granted to appropriate ROLES and revoked
-- from the GROUPS. This leaves the users with the same privileges but now
-- held through ROLES instead of GROUPS.
-- ----------------------------------------------------------------------------

-- Connect to sample database using user JOHN.
CONNECT TO sample USER john USING john123456;

-- Create roles DEVELOPER, TESTER and SALES.
CREATE ROLE developer;
CREATE ROLE tester;
CREATE ROLE sales;

-- Grant role DEVELOPER to user BOB.
GRANT ROLE developer TO USER bob;

-- Grant role TESTER to users JOE and PAT.
GRANT ROLE tester TO USER joe, USER pat;

-- Grant role SALES to users JOE and BOB.
GRANT ROLE sales TO USER joe, USER bob;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user BOB.
CONNECT TO SAMPLE USER bob USING bob123456;

-- Create table TEMP1.
CREATE TABLE temp1 (a int);

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user Newton(SYSADM)so that he can grant
-- ALTER privilege to role DEVELOPER. (DBADM can also grant ALTER privilege).
CONNECT TO SAMPLE USER newton USING Way2discoveR;

-- Grant ALTER privilege on table TEMP1 to role DEVELOPER. NEWTON(SYSADM)
-- (also DBADM) can grant the ALTER privilege on tables.
-- Once ALTER privilege is granted to role DEVELOPER, any user who
-- is part of role DEVELOPER can ALTER this table. So in this sample,
-- user BOB can perform an alter operation on table TEMP1. Users belonging to
-- other roles cannot perform alter operation on TEMP1 unless they have
-- privilege granted.
GRANT ALTER ON bob.temp1 TO ROLE developer;
CONNECT RESET;

-- The following statements show that a trigger TRG1 will be created
-- when user BOB holds the privilege through role DEVELOPER. But this is
-- not possible if user BOB is part of group DEVELOPER_G.

-- Connect to sample database using user BOB.
CONNECT TO SAMPLE USER bob using bob123456;

-- Create trigger TRG1. The following statements show that trigger TRG1 can
-- only be created by user BOB, as he holds the privilege through role
-- DEVELOPER. But this is not possible if user BOB holds the necessary
-- privileges through a group.
CREATE TRIGGER trg1 AFTER DELETE ON bob.temp1
  FOR EACH STATEMENT MODE DB2SQL INSERT INTO bob.temp1 VALUES (1);

-- Drop the table TEMP1.
DROP TABLE bob.temp1;

-- Drop the trigger TRG1.
DROP trigger trg1;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john using john123456;

-- Drop the roles. Only a user with SECADM authority can drop the roles.
-- In this sample, user JOHN(SECADM) can only drop the roles.
DROP ROLE developer;
DROP ROLE tester;
DROP ROLE sales;

-- Disconnect from sample database.
CONNECT RESET;

-- ----------------------------------------------------------------------------
--  3: How to transfer ownership of database objects.
-- ----------------------------------------------------------------------------
-- Usage scenario:
-- Consider the tables TEMP_EMPLOYEE and TEMP_DEPARTMENT in the sample database. User BOB
-- creates a view EMP_DEPT on tables TEMP_EMPLOYEE and TEMP_DEPARTMENT.
-- The user JOHN(SECADM) creates a role EMP_DEPT_ROLE which is granted SELECT
-- privilege on table TEMP_EMPLOYEE and TEMP_DEPARTMENT. The sample shows how to transfer
-- ownership of view BOB.EMP_DEPT, which depends on tables TEMP_EMPLOYEE and
-- TEMP_DEPARTMENT, to new user JOE. For the TRANSFER to work, new user JOE must
-- hold SELECT privilege on the above two table.
-- ----------------------------------------------------------------------------

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john USING john123456;

-- Create role EMP_DEPT_ROLE.
CREATE ROLE emp_dept_role;

-- Disconnect from sample database.
CONNECT RESET;

-- User NEWTON(SYSADM) grants SELECT privilege on tables TEMP_EMPLOYEE and TEMP_DEPARTMENT
-- to role EMP_DEPT_ROLE.

-- Connect to sample database using user NEWTON.
CONNECT TO sample user newton using Way2discoveR;

GRANT SELECT ON TABLE newton.temp_employee
           TO ROLE emp_dept_role;
GRANT SELECT ON TABLE newton.temp_department
           TO ROLE emp_dept_role;

-- Disconnect from sample database.
CONNECT RESET;


-- To transfer ownership of view EMP_DEPT(created below), BOB must hold SELECT
-- privilege on table TEMP_EMPLOYEE and table TEMP_DEPARTMENT.
-- Since role EMP_DEPT_ROLE has these privileges, role EMP_DEPT_ROLE
-- is granted to user BOB using the statement, below.
-- For the TRANSFER to work, new user JOE must also hold SELECT privilege on
-- the above two tables. Hence user JOHN(SECADM) grants SELECT privilege
-- to user JOE also.
-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john USING john123456;

GRANT ROLE emp_dept_role TO USER bob, USER joe;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user BOB.
CONNECT TO SAMPLE USER bob USING bob123456;

-- User BOB creates a view EMP_DEPT which depends upon tables
-- TEMP_EMPLOYEE and TEMP_DEPARTMENT.
-- Create view EMP_DEPT using tables TEMP_EMPLOYEE and TEMP_DEPARTMENT.
CREATE VIEW emp_dept AS SELECT * FROM newton.temp_employee, newton.temp_department;

-- Transfer view EMP_DEPT to user JOE from user BOB.
TRANSFER OWNERSHIP OF VIEW bob.emp_dept TO USER joe PRESERVE PRIVILEGES;

-- Connect to sample database using user JOE.
CONNECT TO SAMPLE USER joe using joe123456;

-- After the TANSFER is done,user BOB cannot drop the view. Only new user JOE,
-- who is current owner of the view, can drop it.
DROP VIEW bob.emp_dept;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john using john123456;

-- User JOHN(SECADM) drops the role.
DROP ROLE emp_dept_role;

-- Disconnect from sample database.
CONNECT RESET;

-- ----------------------------------------------------------------------------
--  4: How to REVOKE privileges from roles.
-- ----------------------------------------------------------------------------
-- Usage scenario:
-- To show the effect on a user~Rs access privilege to a database object, if
-- some privileges are revoked from an authorization ID and privileges are
-- held only through a role. User JOE creates a table TEMP_TABLE.
-- User JOHN(SECADM) creates a role DEVELOPER and is grants it to user BOB.
-- User NEWTON(SYSADM) grants SELECT and INSERT privileges on table JOE.TEMP_TABLE to
-- PUBLIC and to role DEVELOPER. User BOB creates a view VIEW_TEMP which is
-- dependent on table JOE.TEMP_TABLE. The sample shows what happens to
-- user BOB's access privilege when SELECT privilege is revoked from PUBLIC
-- and from role developer.
-- ----------------------------------------------------------------------------

-- Connect to sample database using user JOE.
CONNECT TO SAMPLE USER joe USING joe123456;

-- Create table TEMP_TABLE.
CREATE TABLE temp_table (x int);

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john USING john123456;

-- Create role DEVELOPER.
CREATE ROLE developer;

-- Grant role DEVELOPER to user BOB
GRANT ROLE developer TO USER bob;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user NEWTON(SYSADM).
CONNECT TO SAMPLE USER newton using Way2discoveR;

-- Grant SELECT and INSERT privileges on table TEMP_TABLE to PUBLIC and
-- to role DEVELOPER. Only a user with SYSADM or DBADM authority can grant
-- the privileges on the table.
-- In this sample, the user NEWTON(SYSADM)can grant the SELECT and the INSERT
-- privileges on the table TEMP_TABLE to PUBLIC and to role DEVELOPER.
GRANT SELECT ON TABLE joe. temp_table TO PUBLIC;
GRANT INSERT ON TABLE joe. temp_table TO PUBLIC;
GRANT SELECT ON TABLE joe. temp_table
  TO ROLE developer;
GRANT INSERT ON TABLE joe. temp_table
  TO developer;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database uing user BOB.
CONNECT TO SAMPLE USER bob USING bob123456;

-- Create a view VIEW_TEMP on the table TEMP_TABLE.
CREATE VIEW view_temp
  AS SELECT * FROM joe.temp_table;

-- Disconnect form sample database.
CONNECT RESET;

-- Connect to sample database using user NEWTON(SYSADM).
CONNECT TO SAMPLE USER newton using Way2discoveR;

-- If SELECT privilege on table JOE.TEMP_TABLE is revoked from PUBLIC,
-- the view, BOB.VIEW_TEMP will still be accessible by users who are
-- part of the role DEVELOPER.
REVOKE SELECT ON joe. temp_table FROM PUBLIC;

-- Disconnect from sample database.
CONNECT RESET;


-- Connect to sample database using user NEWTON(SYSADM).
CONNECT TO sample USER newton USING Way2discoveR;

-- If SELECT privilege on table JOE.TEMP_TABLE is revoked from the role
-- DEVELOPER, user BOB will lose SELECT privilege on the table JOE.TEMP_TABLE
-- because required privileges are not held through either role DEVELOPER
-- or any other means.
REVOKE SELECT ON TABLE joe. temp_table FROM ROLE developer;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user BOB.
CONNECT TO sample USER bob USING bob123456;

-- Drop a view VIEW_TEMP.
DROP VIEW bob.view_temp;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOE.
CONNECT TO SAMPLE USER joe USING joe123456;

-- Drop a table TEMP_TABLE.
DROP TABLE joe.temp_table;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john USING john123456;

-- Drop a role DEVELOPER.
DROP ROLE developer;

-- Disconnect from sample database.
CONNECT RESET;

-- ----------------------------------------------------------------------------
--  5: How to build a role hierarchy.
-- ----------------------------------------------------------------------------
-- Usage scenario:
-- The following sample demonstrates how to represent hierarchy levels
-- in an enterprise by building a role hierarchy.
-- Consider an enterprise having the following roles: MANAGER, TECH_LEAD and
-- DEVELOPER. A role hierarchy is built by granting a role to another role, but
-- without creating cycles. Role DEVELOPER will be granted to role TECH_LEAD,
-- and role TECH_LEAD will be granted to role MANAGER. Granting role MANAGER to
-- role DEVELOPER will create a cycle and it is not allowed.
-- By building a hierarchy, role MANAGER will have all the privileges of roles
-- DEVELOPER and TECH_LEAD along with the privileges granted to it directly.
-- Role TECH_LEAD will have privileges of role DEVELOPER and the privileges
-- granted to it directly. Role DEVELOPER will just have the privileges granted
-- to it. Later, depending upon the enterprise needs, each role can be granted
-- to specific employees to form the hierarchy.
-- ----------------------------------------------------------------------------


-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john USING john123456;

-- Create roles MANAGER, TECH_LEAD and DEVELOPER.
CREATE ROLE manager;
CREATE ROLE tech_lead;
CREATE ROLE developer;

-- These two statements create a role hierarchy.
GRANT ROLE developer TO ROLE tech_lead;
GRANT ROLE tech_lead TO ROLE manager;

-- Drop roles MANAGER, TECH_LEAD and DEVELOPER.
DROP ROLE manager;
DROP ROLE tech_lead;
DROP ROLE developer;

-- Disconnect from sample database.
CONNECT RESET;

-- ----------------------------------------------------------------------------
--  6: GRANT-ing and REVOKE-ing WITH ADMIN OPTIONS to and from an
--     authorization ID.
-- ----------------------------------------------------------------------------
-- Usage scenario:
-- A security administrator will create role DEVELOPER and grant it to user JOE
-- using WITH ADMIN OPTION. Once the ADMIN OPTION is granted to user JOE, he can
-- GRANT or REVOKE role DEVELOPER to or from another user BOB who is a member of
-- this role. But JOE will not get the authority to drop role DEVELOPER or to
-- grant ADMIN OPTION to another user. User JOE is not allowed to REVOKE the
-- ADMIN OPTION from role DEVELOPER because he does not have SECADM authority.
-- A  security administrator can revoke the ADMIN OPTION from role DEVELOPER,
-- and user JOE will still have role DEVELOPER granted.
-- If a SECADM revokes the role DEVELOPER from the user JOE, the user JOE will
-- lose all the privileges he has received by being a member of role DEVELOPER
-- and the ADMIN OPTION on role DEVELOPER if this was held.
-- ----------------------------------------------------------------------------

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john USING john123456;

-- Create role DEVELOPER.
CREATE ROLE developer;

-- Grant role DEVELOPER to user JOE and give the WITH ADMIN privilege.
GRANT ROLE developer TO USER joe WITH ADMIN OPTION;

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOE.
CONNECT TO SAMPLE USER joe USING joe123456;

-- The following statements will be successful because user JOE has the
-- WITH ADMIN privileges on role DEVELOPER.
-- User JOE can GRANT and REVOKE ROLE to/from the other users.
GRANT ROLE developer TO USER bob;

REVOKE ROLE developer FROM USER bob;

-- The following statement will fail since user JOE doesn't have the privilege
-- to drop the role DEVELOPER. Only user JOHN(SECADM) is allowed to drop the
-- role.
-- Error displayed will be:
-- SQL0552N "JOE" does not have the privilege to perform operation
-- "DROP ROLE".  SQLSTATE=42502
DROP ROLE developer;
!echo "Above error is expected!";

-- The following statement will fail because user JOE cannot GRANT/REVOKE
-- the role DEVELOPER to another user by using the WITH ADMIN OPTION clause.
-- Only a SECADM can grant/revoke the WITH ADMIN OPTION.
-- Error displayed will be:
-- SQL0551N .JOE" does not have the privilege to perform operation
-- "GRANT/REVOKE" on object "DEVELOPER".  SQLSTATE=42501
GRANT ROLE DEVELOPER TO USER bob WITH ADMIN OPTION;
!echo "Above error is expected!";

REVOKE ADMIN OPTION FOR ROLE developer FROM USER bob;
!echo "Above error is expected!";

-- Disconnect from sample database.
CONNECT RESET;

-- Connect to sample database using user JOHN(SECADM).
CONNECT TO SAMPLE USER john USING john123456;

-- The following statement will be successful because user JOHN(SECADM)
-- is executing it.
-- With the command below, only ADMIN OPTION is revoked, role DEVELOPER is
-- still granted to user JOE.
REVOKE ADMIN OPTION FOR ROLE developer FROM USER joe;

-- Revoke role DEVELOPER from user JOE.
REVOKE ROLE developer FROM USER joe;

-- Drop a role.
DROP ROLE developer;

-- Disconnect from sample database.
CONNECT RESET;

-- ****************************************************************************
--    CLEAN UP
-- ****************************************************************************

-- Drop the temporary tables created.
CONNECT TO SAMPLE;

DROP TABLE newton.TEMP_EMPLOYEE;
DROP TABLE newton.TEMP_DEPARTMENT;

TERMINATE;

