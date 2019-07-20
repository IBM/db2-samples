----------------------------------------------------------------------------
--   (c) Copyright IBM Corp. 2007 All rights reserved.
--   
--   The following sample of source code ("Sample") is owned by International 
--   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
--   copyrighted and licensed, not sold. You may use, copy, modify, and 
--   distribute the Sample in any form without payment to IBM, for the purpose of 
--   assisting you in the development of your applications.
--   
--   The Sample code is provided to you on an "AS IS" basis, without warranty of 
--   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
--   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
--   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
--   not allow for the exclusion or limitation of implied warranties, so the above 
--   limitations or exclusions may not apply to you. IBM shall not be liable for 
--   any damages you suffer as a result of using, copying, modifying or 
--   distributing the Sample, even if IBM has been advised of the possibility of 
--   such damages.
----------------------------------------------------------------------------
--
-- SAMPLE FILE NAME: arrays_sqlpl.db2
--
-- PURPOSE: To demonstrate the new ARRAY type and functions UNNEST and 
--          ARRAY_AGG.
--
-- USAGE SCENARIO: Scenario is based on the employee data in sample database.
-- The management has selected best projects based on the projects performance 
-- in the current year and decided to give the employees of these projects a 
-- performance bonus. The bonus will be a specific percentage of employee 
-- salary.
--
-- An array of varchar is used to store the selected project names.
-- 
-- A stored procedure is implemented to calculate the bonus. The stored 
-- procedure takes this array and percentage value as input.
-- 
-- PREREQUISITE: NONE
--
-- EXECUTION: db2 -td@ -vf arrays_sqlpl.db2
--
-- INPUTS: NONE
-- 
-- OUTPUT: The employee IDs and the corresponding bonus is calculated and
-- stored in a table. An employee can work for multiple projects therefore
-- multiple entries are possible for the same employee ID in this table.
--
-- OUTPUT FILE: arrays_sqlpl.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--               CREATE TABLE
-- 		 INSERT 
--		 SELECT
--               DROP
--               CALL
--               CREATE PROCEDURE
--
-- FUNCTIONS USED:
--  		 UNNEST
--		 ARRAY_AGG
--		 
---------------------------------------------------------------------------
-- For more information about the command line processor (CLP) scripts,     
-- see the README file.                                                     
-- For information on using SQL statements, see the SQL Reference.          
--                                                                          
-- For the latest information on programming, building, and running DB2     
-- applications, visit the DB2 application development website:             
-- http://www.software.ibm.com/data/db2/udb/ad   
--  
--------------------------------------------------------------------------
--
-- SAMPLE DESCRIPTION
--
--------------------------------------------------------------------------
--
-- 1. Create a table "bonus_temp" to store employee ID and corresponding
--    bonus.
-- 2. Create ARRAY types to store the values for employee ID, bonus and 
--    projects.
-- 3. Create a stored procedure to calculate the bonus.
--    3.1 Select the ID and corresponding bonus values into  
--        corresponding ARRAY type "employees" and "bonus" respectively 
--        using aggregate function ARRAY_AGG.
--    3.2 Use UNNEST function to select the ARRAY elements from ARRAY 
--        variables and insert the same in "bonus_temp" table.
--4. Call the stored procedure to calculate the bonus. Input to this
--   stored procedure is the ARRAY of all projects which are 
--   applicable for the bonus.
--5. Select the data from the table "bonus_temp".
-------------------------------------------------------------------------

-- Connect to the database SAMPLE                   
CONNECT TO sample@

----------------------------------------------------------------------------
--
-- 1.  Create a table "bonus_temp" to store employee ID and corresponding
--    bonus.
--
-----------------------------------------------------------------------------

-- Drop the table "bonus_temp" if already exists
drop table bonus_temp@

-- Create the table "bonus_temp" to store employee ID and corresponding
-- bonus information.
CREATE TABLE bonus_temp (empno varchar(6), bonus double)@

----------------------------------------------------------------------------
--
-- 2.  Create ARRAY types to store the values for employee ID, bonus and 
--     projects.
--
-----------------------------------------------------------------------------

-- Create the ARRAY type "projects".
CREATE TYPE projects AS VARCHAR(20) ARRAY[10]@

-- Create the ARRAY type "employee"
CREATE TYPE employees AS VARCHAR(6) ARRAY[20]@

-- Create the ARRAY type "bonus"
CREATE TYPE bonus AS DOUBLE ARRAY[20]@

----------------------------------------------------------------------------
--
-- 3. Create a stored procedure to calculate the bonus.
--
-----------------------------------------------------------------------------

-- Create the procedure to calculate bonus.
CREATE PROCEDURE bonus_calculate (IN projs projects, IN percentage integer)
BEGIN
DECLARE emp_array employees;
DECLARE bonus_array bonus;

-- Select the IDs and corresponding bonus in corresponding ARRAY type
-- "employees" and "bonus" using aggregate function 
-- ARRAY_AGG.
SELECT cast(array_agg(employee.empno) AS employees), 
       cast(array_agg(.10*salary) AS bonus) INTO emp_array,bonus_array  
  FROM vempprojact, unnest(projs) AS P(id), employee 
  WHERE P.id=vempprojact.projno AND employee.empno=vempprojact.empno;

-- Use UNNEST function to select the ARRAY elements from ARRAY 
-- variables and insert the same in "bonus_temp" table.
INSERT INTO bonus_temp 
   SELECT T.empno, T.bonus 
     FROM unnest(emp_array, bonus_array) 
     WITH ORDINALITY AS T(empno,bonus, idx); 
END@

----------------------------------------------------------------------------
--
-- 4. Call the stored procedure to calculate the bonus.Input to this
--   stored procedure is the ARRAY of all projects which are 
--   applicable for bonus.
-----------------------------------------------------------------------------

-- Call the stored procedure
Call bonus_calculate(ARRAY['AD3111', 'IF1000', 'MA2111'], 10)@ 

----------------------------------------------------------------------------
--
-- 5. Select the data from the table "bonus_temp".
--
-----------------------------------------------------------------------------

SELECT empno, bonus FROM bonus_temp@

--Cleanup
DROP PROCEDURE bonus_calculate@
DROP TYPE projects@
DROP TYPE employees@
DROP TYPE bonus@
DROP TABLE bonus_temp@

-- Disconnect from database 
CONNECT RESET@

