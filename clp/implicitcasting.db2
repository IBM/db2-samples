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
-- SAMPLE FILE NAME: implicitcasting.db2
--
-- PURPOSE: To demonstrate use of Implicit casting. 
--                01. STRING to NUMERIC assignment
--                02. NUMERIC to STRING assignment
--                03. STRING to NUMERIC comparison
--                04. NUMERIC to STRING comparison
--                05. USE of BETWEEN PREDICATE 
--                06. Implicit casting with UNION
--                07. Assignment of a TIMESTAMP
--                08. Implicit casting in scalar functions
--                    a. CONCAT
--                    b. REAL
--                09. Untyped null
-- 
-- PREREQUISITE    : None
--	
-- EXECUTION       : db2 -tvf implicitcasting.db2
--                   
-- INPUTS          : NONE
--
-- OUTPUT          : Result of all the functionalities.
--
-- OUTPUT FILE     : implicitcasting.out (available in the online documentation)
--
-- DEPENDENCIES    : NONE
--
-- SQL STATEMENTS USED:
--                CREATE TABLE
--                DESCRIBE TABLE       	
--                INSERT 
--                SELECT
--                DROP TABLE
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
--
-- SAMPLE DESCRIPTION                                                      
--
-- *************************************************************************
--  1. Implicit casting between string and numeric data on assignments.
--  2. Implicit casting between string and numeric data on comparisons.
--  3. USE of BETWEEN PREDICATE
--  4. Implicit casting between string and numeric data for arithmetic
--     operations.
--  5  Support for assignment of a TIMESTAMP to a DATE or TIME.
--  6. Implicit casting in scalar functions.
--  7. Untyped null
-- *************************************************************************/

-- Connect to sample database
CONNECT TO sample;

-- Drop table temp_employee

DROP TABLE temp_employee;
 
-- Create table temp_employee

CREATE TABLE temp_employee(empno INT NOT NULL, firstname CHAR(12) NOT NULL,
midinit CHAR(1), lastname CHAR(15) NOT NULL ,workdept VARCHAR(3),
phoneno CHAR(4), hiredate DATE, job CHAR(8), edlevel SMALLINT NOT NULL,
sex CHAR(1), birthdate DATE, salary DECIMAL(9,2), bonus INT, comm INT);

--  /*****************************************************************/
--  /* Implicit casting between string and numeric data on           */
--  /* assignments.                                                  */
--  /*****************************************************************/

--  /********************************/
--  /* STRING TO NUMERIC ASSIGNMENT */
--  /********************************/

-- Describe table temp_employee
DESCRIBE TABLE temp_employee;

-- Describe table employee
DESCRIBE TABLE employee;

-- Fetch data from employee table
SELECT * FROM employee 
 WHERE empno < '000100';

-- In employee table empno is of STRING type and in temp_employee table
-- empno is of NUMERIC type.

-- Copy data from one table to another table of different data types without 
-- changing the table structure. 
INSERT INTO temp_employee
 SELECT * FROM employee;

-- Fetch data from temp_employee table
SELECT * FROM temp_employee 
 WHERE empno < 000100;

--  /********************************/
--  /* NUMERIC TO STRING ASSIGNMENT */
--  /********************************/

-- In temp_table, column phoneno is of data type STRING. Update phoneno column
--  by passing NUMERIC phone number.

UPDATE temp_employee
 SET phoneno = 5678
  WHERE empno = '000110';

-- Fetch data from temp_employee table
SELECT * FROM temp_employee
 WHERE phoneno = 5678;

--  /*****************************************************************/
--  /* Implicit casting between string and numeric data on           */
--  /* comparisons.                                                  */
--  /*****************************************************************/

--  /*********************************/
--  /* STRING TO NUMERIC COMPARISON  */
--  /*********************************/

-- Retrieve rows from temp_employee table where empno is 000330.
-- In temp_employee table empno is of NUMERIC type.
-- Pass empno as STRING while fetching the data from table.

SELECT * FROM temp_employee
 WHERE empno = '000330';

--  /*********************************/
--  /* NUMERIC TO STRING COMPARISON  */
--  /*********************************/

-- Retrieve rows from temp_employee table where salary is 37750.00 
-- or bonus is 400 or comm is 1272.
-- 
-- In temp_employee table salary, bonus, comm is of NUMERIC type.
-- Pass salary, bonus, comm as STRING while fetching the data from table.

SELECT * FROM temp_employee
 WHERE salary = '37750.00'
  OR bonus = '400'
   OR comm = '1272';

--  /*********************************/
--  /* USE BETWEEN PREDICATE         */
--  /*********************************/

-- BETWEEN predicate compares a value with a range of values.
-- Pass STRING value of empno as range1 and NUMERIC value of empno as range2.
 
SELECT * FROM temp_employee
 WHERE empno 
  BETWEEN '000120' AND 000160;

--  /*********************************/
--  /* Implicit casting with UNION   */
--  /*********************************/
 
--  Here columns in the query are of different data types.
--  firstname is of CHAR type, phoneno is of CHAR type, projname is of VARCHAR
--  type and prstaff is of DECIMAL type.

SELECT firstname, phoneno AS col1
 FROM temp_employee 
  WHERE workdept = 'D11'
   UNION 
SELECT projname, prstaff AS col2
 FROM proj
  WHERE deptno = 'E21';


--  /*****************************************************************/
--  /* Implicit casting between string and numeric data for          */ 
--  /* arithmetic operations.                                        */
--  /*****************************************************************/

-- STRING and NUMERIC data can be used in arithmetic operations.
-- Update salary of empno 000250 by adding bonus + comm 

UPDATE temp_employee
 SET SALARY = SALARY + comm + bonus + '1000'
  WHERE empno = 000250;

SELECT salary AS updated_salary
 FROM temp_employee
  WHERE empno = '000250';


--  /*****************************************************************/
--  /* Implicit casting in assignment of a TIMESTAMP                 */ 
--  /*                                                               */
--  /*****************************************************************/

--  Drop table date_time
DROP TABLE date_time;

--  Create table date_time 
CREATE TABLE date_time (new_date DATE, new_time TIME);

--  Insert values into date_time
INSERT INTO date_time
 VALUES ('2008-04-11-03.45.30.999', 
         '2008-04-11-03.45.30.999');

INSERT INTO date_time
 VALUES ('2008-05-12-03.45.30.123',
         '2008-05-12-03.45.30.123');

--  Fetch data from data_time table

SELECT TO_CHAR(new_date, 'DAY-YYYY-Month-DD'), new_time
FROM date_time;


--  /*****************************************************************/
--  /* Implicit casting in scalar functions.                         */
--  /*****************************************************************/

--  /*********************************/
--  /* CONCAT scalar function        */
--  /*********************************/

--  CONCAT scalar function can take arguments of different data types.

SELECT CONCAT 
 (CONCAT (CONCAT 
  (CONCAT (empno, ' || ' ),
   firstname),' || '), hiredate) AS employee_information
 FROM temp_employee 
  WHERE empno BETWEEN 
   000100 AND '000340';


--  /*********************************/
--  /* REAL scalar function          */
--  /*********************************/

-- Real scalar function can take string and numeric arguments.

SELECT REAL (salary) as real_salary
 FROM temp_employee;

SELECT REAL (CAST(salary AS CHAR(9)))
  as real_salary FROM temp_employee;


--  /*****************************************************************/
--  /* Untyped null in implicit casting                              */
--  /*****************************************************************/

--  Null can be used anywhere in the expression. 

UPDATE temp_employee
 SET comm = NULL
  WHERE empno = 000330;

-- Select row where empno is 000330

SELECT * FROM
 temp_employee
  WHERE empno = 000330;

--  If either operand is null, the result will be null.

UPDATE temp_employee
 SET salary = salary + NULL + 1000
  WHERE empno = 000330;

-- Select row where empno is 000330

SELECT * FROM temp_employee
 WHERE empno = 000330;

--  /*****************************************************************/
--  /* Clean up                                                      */
--  /*****************************************************************/

DROP TABLE temp_employee;
DROP TABLE date_time;
CONNECT RESET;
