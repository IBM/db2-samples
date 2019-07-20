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
-- SAMPLE FILE NAME: defaultparam.db2
--
-- PURPOSE: To demonstrate how to use DEFAULT values for procedure parameters. 
--
-- PREREQUISITE    : NONE
--	
-- EXECUTION       : db2 -td@ -vf defaultparam.db2 
--                   
-- INPUTS          : NONE
--
-- OUTPUT          : Result of all the procedure calls
--
-- OUTPUT FILE     : defaultparam.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--                CREATE TABLE
--                CREATE PROCEDURE
--                INSERT 
--                SELECT
--                DROP TABLE
--                DROP PROCEDURE
--                UPDATE TABLE
--
-- *************************************************************************
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--
-- http://www.ibm.com/software/data/db2/ad/
--
-- *************************************************************************

-- SAMPLE DESCRIPTION 
-- 
-- Create a procedure bonus_calculation which will take workdept and empjob
-- as a parameter for calculating the bonus for that department. If there 
-- is no parameter is specified while calling the procedure DEFAULT value is 
-- set. Here default value is ALL.
-- 
-- *************************************************************************                                                   

--  /*****************************************************************/
--  /* DEFAULT values for procedure parameters                       */
--  /*****************************************************************/

-- Connect to sample database

CONNECT TO sample@

-- Drop table temp_employee

DROP TABLE temp_employee@
 
-- Create table temp_employee
CREATE TABLE temp_employee LIKE employee@

-- Insert data into temp_employee@
INSERT INTO temp_employee SELECT * FROM employee@ 

-- Drop procedure bonus_calculation
DROP PROCEDURE bonus_calculation @

CREATE PROCEDURE bonus_calculation
(IN emp_job VARCHAR(8),
IN dept_no CHAR(3) DEFAULT 'ALL')
 RESULT SETS 1
 LANGUAGE SQL
 BEGIN
  
  DECLARE c1 CURSOR WITH RETURN FOR
  SELECT CONCAT(CONCAT(CONCAT
  (CONCAT(cast(empno as CHAR(4)), ' || '), workdept),
  ' || '), bonus) AS bonus_calculation 
  FROM temp_employee
  ORDER BY workdept;

  DECLARE c2 CURSOR WITH RETURN FOR
  SELECT CONCAT(CONCAT(CONCAT
  (CONCAT(cast(empno AS CHAR(4)), ' || '), workdept),
  ' || '), bonus) AS bonus_calculation 
  FROM temp_employee
  WHERE workdept = dept_no AND job = emp_job;



  IF dept_no = 'ALL ' THEN
  UPDATE temp_employee
  SET bonus = 
  CASE WHEN year (current date) - year (hiredate)
  between 20 and 15 THEN salary * '.30'
  WHEN year (current date) - year (hiredate)
  between 15 and 10 THEN salary * '.20'
  WHEN year (current date) - year (hiredate)
  between 10 and 05 THEN salary * '.15'
  ELSE salary * '.10'
   END
   WHERE job = emp_job;
  ELSE
   UPDATE temp_employee 
   SET bonus =
   CASE WHEN year (current date) - year (hiredate)
   between 20 and 15 THEN salary * '.30'
   WHEN year (current date) - year (hiredate)
   between 15 and 10 THEN salary * '.20'
   WHEN year (current date) - year (hiredate)
   between 10 and 05 THEN salary * '.15'
   ELSE salary * '.10'
   END
   WHERE workdept = dept_no AND job = emp_job;
  END IF;


  IF dept_no = 'ALL' THEN 
   OPEN c1;
  ELSE
   OPEN c2;
  END IF;
END @


--  Call Procedure bonus_calculation

--  Calling procedure with one argument 
CALL bonus_calculation(emp_job=>'MANAGER')@

--  Calling procedure with more than one argument.
CALL bonus_calculation(dept_no=>'D11', emp_job=>'MANAGER')@

--  Calling procedure with one DEFAULT argument.
CALL bonus_calculation(emp_job=>'MANAGER', dept_no=>DEFAULT)@

--  Calling procedure with DEFAULT value as arguments
CALL bonus_calculation(emp_job=>DEFAULT, dept_no=>DEFAULT)@

-- Calling procedure with DEFAULT arguments
CALL bonus_calculation(DEFAULT,DEFAULT)@


--  /*****************************************************************/
--  /* Clean up                                                      */
--  /*****************************************************************/

DROP TABLE temp_employee@
DROP PROCEDURE bonus_calculation@
CONNECT RESET@

