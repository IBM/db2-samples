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
-------------------------------------------------------------------------------
-- SOURCE FILE NAME: bonus_calculate.db2
--
-- DESCRIPTION: This is the set up script for the sample Arrays_Sqlpl.java
--
-- SQL STATEMENTS USED:
--               CREATE TABLE
-- 		 INSERT 
--		 SELECT
--               DROP
--               CREATE PROCEDURE
--
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

-- Connect to the database
CONNECT TO sample@

-- Drop the ARRAY types
DROP TYPE projects@
DROP TYPE employees@
DROP TYPE bonus@

-- Create the ARRAY types
-- Create the ARRAY type "projects".
CREATE TYPE projects AS VARCHAR(20) ARRAY[10]@

-- Create the ARRAY type "employee"
CREATE TYPE employees AS VARCHAR(6) ARRAY[20]@

-- Create the ARRAY type "bonus"
CREATE TYPE bonus AS DOUBLE ARRAY[20]@

-- Drop the table "bonus_temp" if already exists
drop table bonus_temp@

-- Create the table "bonus_temp" to store employee ID and corresponding
-- bonus information.
CREATE TABLE bonus_temp (empno varchar(6), bonus double)@

-- Drop the procedure if already exists
DROP PROCEDURE bonus_calculate@
-- Create the procedure
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
