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
-- SOURCE FILE NAME: spserver.db2
--
-- SAMPLE: To create a set of SQL procedures
--
-- To create the SQL procedures:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -vf spserver.db2"
--
-- To call these SQL procedures, you can use the
-- C, CLI, or C++ spclient application, or the Spclient
-- application in Java, by compiling and running one of
-- the following source files:
-- C: samples/c/spclient.sqc (UNIX) or samples\c\spclient.sqc (Windows)
-- CLI: samples/cli/spclient.c (UNIX) or samples\c\spclient.c (Windows)
-- C++: samples/cpp/spclient.sqC (UNIX) or samples\cpp\spclient.sqx (Windows)
-- Java JDBC: samples/java/jdbc/Spclient.java (UNIX)
--            or samples\java\jdbc\Spclient.java (Windows)
-- Java SQLJ: samples/java/sqlj/Spclient.sqlj (UNIX)
--            or samples\java\sqlj\Spclient.sqlj (Windows)
-----------------------------------------------------------------------------
--
-- For more information on the sample scripts, see the README file.
--
-- For information on creating SQL procedures, see the Application
-- Development Guide.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-----------------------------------------------------------------------------
-- Stored Procedure: OUT_LANGUAGE
--  
-- Purpose: Returns the code implementation language of
--          routine 'OUT_LANGUAGE' (as it appears in the
--          database catalog) in an output parameter.
--
-- Parameters:
--
-- IN:      (none)
-- OUT:     procedureLanguage - the code language of this routine
-----------------------------------------------------------------------------
CREATE PROCEDURE OUT_LANGUAGE (OUT procedureLanguage CHAR(8))
SPECIFIC SQL_OUT_LANGUAGE
DYNAMIC RESULT SETS 0
LANGUAGE SQL
READS SQL DATA
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE errorLabel CHAR(32) DEFAULT '';
  
  -- in case of no data found  
  DECLARE EXIT HANDLER FOR NOT FOUND
    SIGNAL SQLSTATE value '38200' SET MESSAGE_TEXT= '100: NO DATA FOUND'; 

  -- in case of SQL error
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;

  SET errorLabel = 'SELECT STATEMENT';    
  SELECT language INTO procedureLanguage
    FROM sysibm.sysprocedures
    WHERE procname = 'OUT_LANGUAGE';
END @

-----------------------------------------------------------------------------
-- Stored Procedure: OUT_PARAM
-- 
-- Purpose: Sorts table STAFF by salary, locates and returns
--          the median salary
-- 
-- Parameters:
--
-- IN:      (none)
-- OUT:     medianSalary - median salary in table STAFF
-----------------------------------------------------------------------------
CREATE PROCEDURE OUT_PARAM (OUT medianSalary DOUBLE)
SPECIFIC SQL_OUT_PARAM
DYNAMIC RESULT SETS 0
LANGUAGE SQL
READS SQL DATA
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE errorLabel CHAR(32) DEFAULT '';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE v_numRecords INT DEFAULT 1;
  DECLARE v_counter INT DEFAULT 0;
  DECLARE v_mod INT DEFAULT 0;
  DECLARE v_salary1 DOUBLE DEFAULT 0;
  DECLARE v_salary2 DOUBLE DEFAULT 0;

  DECLARE c1 CURSOR FOR
    SELECT CAST(salary AS DOUBLE) FROM staff
    ORDER BY salary;

  -- in case of no data found
  DECLARE EXIT HANDLER FOR NOT FOUND
    SIGNAL SQLSTATE value '38200' SET MESSAGE_TEXT= '100: NO DATA FOUND'; 

  -- in case of SQL error
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;

  -- initialize OUT parameter
  SET medianSalary = 0;

  SET errorLabel = 'SELECT COUNT';
  SELECT COUNT(*) INTO v_numRecords FROM staff;

  SET errorLabel = 'OPEN CURSOR';
  OPEN c1;

  SET v_mod = MOD(v_numRecords, 2);

  CASE v_mod
   WHEN 0 THEN
     WHILE v_counter < (v_numRecords / 2 + 1) DO
       SET v_salary1 = v_salary2;
       FETCH c1 INTO v_salary2;
       SET v_counter = v_counter + 1;
     END WHILE;
     SET medianSalary = (v_salary1 + v_salary2)/2;
   WHEN 1 THEN
     WHILE v_counter < (v_numRecords / 2 + 1) DO
       FETCH c1 INTO medianSalary;
       SET v_counter = v_counter + 1;
     END WHILE;
  END CASE;

  SET errorLabel = 'CLOSE CURSOR';
  CLOSE c1;
END @

-----------------------------------------------------------------------------
-- Stored Procedure: IN_PARAMS
--  
-- Purpose: Updates salaries of employees in department 'department'
--          using inputs lowsal, medsal, highsal as
--          salary raise/adjustment values.
--  
-- Parameters:
--
-- IN:      lowsal      - new salary for low salary employees
--          medsal      - new salary for mid salary employees
--          highsal     - new salary for high salary employees
--          department  - department to use in SELECT predicate
-- OUT:     (none)
--
-----------------------------------------------------------------------------
CREATE PROCEDURE IN_PARAMS (IN lowsal DOUBLE, IN medsal DOUBLE, IN highsal DOUBLE, IN department CHAR(3))
SPECIFIC SQL_IN_PARAMS
DYNAMIC RESULT SETS 0
DETERMINISTIC
LANGUAGE SQL 
MODIFIES SQL DATA
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE errorLabel CHAR(32) DEFAULT '';
  DECLARE v_firstnme VARCHAR(12);
  DECLARE v_midinit CHAR(1);
  DECLARE v_lastname VARCHAR(15);
  DECLARE v_salary DOUBLE;
  DECLARE at_end SMALLINT DEFAULT 0;
 
  DECLARE c1 CURSOR FOR
    SELECT firstnme, midinit, lastname, CAST(salary AS DOUBLE)
    FROM employee
    WHERE workdept = department 
    FOR UPDATE OF salary;

  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET at_end = 1;

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;

  -- initialize OUT parameter
  SET errorLabel = 'OPEN CURSOR';
  OPEN c1;
  SET errorLabel = 'FIRST FETCH';
  FETCH c1 INTO v_firstnme, v_midinit, v_lastname, v_salary;
  WHILE (at_end = 0) DO
    IF (lowsal > v_salary) THEN
      UPDATE employee
      SET salary = lowsal
      WHERE CURRENT OF c1;
    ELSEIF (medsal > v_salary) THEN
      UPDATE employee
      SET salary = medsal
      WHERE CURRENT OF c1;
    ELSEIF (highsal > v_salary) THEN
      UPDATE employee
      SET salary = highsal
      WHERE CURRENT OF c1;
    ELSE UPDATE employee
      SET salary = salary * 1.10
      WHERE CURRENT OF c1;
    END IF;
    SET errorLabel = 'FETCH IN WHILE LOOP';
    FETCH c1 INTO v_firstnme, v_midinit, v_lastname, v_salary;
  END WHILE;
  SET errorLabel = 'CLOSE CURSOR';
  CLOSE c1;
END @

-----------------------------------------------------------------------------
-- Stored Procedure: INOUT_PARAM
--  
-- Purpose: Calculates the median salary of all salaries in the STAFF
--          above table the input median salary.
--
-- Parameters:
--
-- IN/OUT: medianSalary - median salary
--                        The input value is used in a SELECT predicate. 
--                        Its output value is set to the median salary. 
--
-----------------------------------------------------------------------------
CREATE PROCEDURE INOUT_PARAM (INOUT medianSalary DOUBLE)
SPECIFIC SQL_INOUT_PARAM
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE SQL 
READS SQL DATA
BEGIN 
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE errorLabel CHAR(32) DEFAULT '';
  DECLARE v_mod INT DEFAULT 0;
  DECLARE v_medianSalary DOUBLE DEFAULT 0;
  DECLARE v_numRecords INT DEFAULT 1;
  DECLARE v_counter INT DEFAULT 0;
  DECLARE v_salary1 DOUBLE DEFAULT 0;
  DECLARE v_salary2 DOUBLE DEFAULT 0;

  DECLARE c1 CURSOR FOR 
    SELECT CAST(salary AS DOUBLE) FROM staff 
    WHERE salary > medianSalary
    ORDER BY salary;

  DECLARE EXIT HANDLER FOR NOT FOUND
    SIGNAL SQLSTATE value '38200' SET MESSAGE_TEXT= '100: NO DATA FOUND'; 

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;

  SET errorLabel = 'SELECT COUNT';
  SELECT COUNT(*) INTO v_numRecords FROM staff WHERE salary > medianSalary;

  SET v_mod = MOD(v_numRecords, 2);

  SET errorLabel = 'OPEN CURSOR';
  OPEN c1;

  CASE v_mod
   WHEN 0 THEN
     WHILE v_counter < (v_numRecords / 2 + 1) DO
       SET v_salary1 = v_salary2;
       FETCH c1 INTO v_salary2;
       SET v_counter = v_counter + 1;
     END WHILE;
     SET medianSalary = (v_salary1 + v_salary2)/2;
   WHEN 1 THEN
     WHILE v_counter < (v_numRecords / 2 + 1) DO
       FETCH c1 INTO medianSalary;
       SET v_counter = v_counter + 1;
     END WHILE;
  END CASE;

  SET errorLabel = 'CLOSE CURSOR';
  CLOSE c1;
END @

-----------------------------------------------------------------------------
--  Stored Procedure: DECIMAL_TYPE
--
--  Purpose:  Takes in a decimal number as input, divides it by 2 
--            and returns the resulting decimal rounded off to 2 
--            decimal places.
--
--  Parameters:
--  
--   INOUT:   inOutDecimal - DECIMAL(10,2)
--                            
-----------------------------------------------------------------------------
CREATE PROCEDURE DECIMAL_TYPE (INOUT inOutDecimal DECIMAL(10,2))
SPECIFIC SQL_DEC_TYPE  
DYNAMIC RESULT SETS 0
DETERMINISTIC
LANGUAGE SQL 
READS SQL DATA
BEGIN

  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE errorLabel CHAR(32) DEFAULT '';
  
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;

  SET errorLabel = 'IF DECIMAL';
  IF (inOutDecimal = 0) THEN SET inOutDecimal = 1;
  ELSE SET inOutDecimal = inOutDecimal / 2;
  END IF;

END @

-----------------------------------------------------------------------------
--  Stored Procedure: ALL_DATA_TYPES  
--
--  Purpose: Take each parameter and set it to a new output value.
--           This sample shows only a subset of DB2 supported data types.
--           For a full listing of DB2 data types, please see the SQL 
--           Reference. 
--
--  Parameters:
--  
--   INOUT:   inOutSmallint, inOutInteger, inOutBigint, inOutReal,
--            inoutDouble
--   OUT:     charOut, charsOut, varcharOut, charsOut, timeOut
--
-----------------------------------------------------------------------------
CREATE PROCEDURE ALL_DATA_TYPES (INOUT inOutSmallint SMALLINT, 
  INOUT inOutInteger INTEGER, INOUT inOutBigint BIGINT,
  INOUT inOutReal REAL, INOUT inoutDouble DOUBLE,
  OUT charOut CHAR(1), OUT charsOut CHAR(15),
  OUT varcharOut VARCHAR(12), OUT dateOut DATE,
  OUT timeOut TIME)
SPECIFIC SQL_ALL_DAT_TYPES
DYNAMIC RESULT SETS 0
NOT DETERMINISTIC
LANGUAGE SQL 
READS SQL DATA
BEGIN
  
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE errorLabel CHAR(32) DEFAULT '';
  
  DECLARE EXIT HANDLER FOR NOT FOUND
    SIGNAL SQLSTATE value '38200' SET MESSAGE_TEXT= '100: NO DATA FOUND'; 

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;

  SET errorLabel = 'IF SMALLINT';
  IF (inOutSmallint = 0) THEN SET inOutSmallint = 1;
  ELSE SET inOutSmallint = inOutSmallint / 2;
  END IF;

  SET errorLabel = 'IF INTEGER';
  IF (inOutInteger = 0) THEN SET inOutInteger = 1;
  ELSE SET inOutInteger = inOutInteger / 2;
  END IF;

  SET errorLabel = 'IF BIGINT';
  IF (inOutBigint = 0) THEN SET inOutBigint = 1;
  ELSE SET inOutBigint = inOutBigint / 2;
  END IF;

  SET errorLabel = 'IF REAL';
  IF (inOutReal = 0) THEN SET inOutReal = 1;
  ELSE SET inOutReal = inOutReal / 2;
  END IF;

  SET errorLabel = 'IF DOUBLE';
  IF (inoutDouble = 0) THEN SET inoutDouble = 1;
  ELSE SET inoutDouble = inoutDouble / 2;
  END IF;

  SET errorLabel = 'SELECT midinit';
  SELECT midinit INTO charOut FROM employee WHERE empno = '000180';

  SET errorLabel = 'SELECT lastname';
  SELECT lastname INTO charsOut FROM employee WHERE empno = '000180';

  SET errorLabel = 'SELECT firstnme';
  SELECT firstnme INTO varcharOut FROM employee WHERE empno = '000180';

  SET errorLabel = 'VALUES CURRENT DATE';
  VALUES CURRENT DATE INTO dateOut;

  SET errorLabel = 'VALUES CURRENT TIME';
  VALUES CURRENT TIME INTO timeOut;

END @

-----------------------------------------------------------------------------
-- Stored Procedure: ONE_RESULT_SET
--
-- Purpose: Returns a result set to the caller that identifies employees
--          with salaries greater than the value of input parameter
--          salValue.
--
-- Parameters:
-- 
-- IN:      salValue - salary
--
-----------------------------------------------------------------------------
CREATE PROCEDURE ONE_RESULT_SET (IN salValue DOUBLE)
SPECIFIC SQL_ONE_RES_SET
DYNAMIC RESULT SETS 1
NOT DETERMINISTIC
LANGUAGE SQL 
READS SQL DATA
BEGIN 
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE SQLCODE INTEGER DEFAULT 0;
  DECLARE errorLabel CHAR(32) DEFAULT '';

  -- use WITH RETURN TO CLIENT in DECLARE CURSOR to always 
  -- return a result set to the client application
  DECLARE c1 CURSOR WITH RETURN TO CLIENT FOR 
    SELECT name, job, CAST(salary AS DOUBLE) 
    FROM staff 
    WHERE salary > salValue
    ORDER BY salary;

  DECLARE EXIT HANDLER FOR NOT FOUND
    SIGNAL SQLSTATE value '38200' SET MESSAGE_TEXT= '100: NO DATA FOUND'; 

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;
 
  -- to return result set, do not CLOSE cursor
  SET errorLabel = 'OPEN CURSOR';
  OPEN c1;
 
END @

-----------------------------------------------------------------------------
-- Stored Procedure: RESULT_SET_CALLER
-- 
-- Purpose:  Returns a result set to the caller that identifies employees
--           with salaries greater than the value of input parameter
--           salValue.
-- 
-- Parameters:
--
-- IN:      salValue
-- OUT:     ResultSet
-----------------------------------------------------------------------------
CREATE PROCEDURE RESULT_SET_CALLER (IN salValue DOUBLE)
SPECIFIC SQL_RES_SET_CALLER
DYNAMIC RESULT SETS 1
LANGUAGE SQL
READS SQL DATA
BEGIN
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE errorLabel CHAR(32) DEFAULT '';
  
  -- use WITH RETURN TO CALLER in DECLARE CURSOR to always
  -- return a result set to the calling application
  DECLARE c1 CURSOR WITH RETURN TO CALLER FOR
    SELECT name, job, CAST(salary AS DOUBLE)
    FROM staff
    WHERE salary > salValue
    ORDER BY salary;

  -- in case of no data found
  DECLARE EXIT HANDLER FOR NOT FOUND
    SIGNAL SQLSTATE value '38200' SET MESSAGE_TEXT= '100: NO DATA FOUND'; 

  -- in case of SQL error
  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;

  -- to return result set, do not CLOSE cursor
  OPEN c1;
END @

-----------------------------------------------------------------------------
--  Stored Procedure: TWO_RESULT_SETS
--
--  Purpose:  Return two result sets to the caller. One result set
--            consists of employee data of all employees with
--            salaries greater than medianSalary.  The other
--            result set contains employee data for employees with salaries
--            less than medianSalary.
--
--  Parameters:
-- 
--   IN:      medianSalary - salary
--
-----------------------------------------------------------------------------
CREATE PROCEDURE TWO_RESULT_SETS (IN medianSalary DOUBLE)
SPECIFIC SQL_TWO_RES_SETS
DYNAMIC RESULT SETS 2
NOT DETERMINISTIC
LANGUAGE SQL 
READS SQL DATA
BEGIN
  
  DECLARE nestCode INTEGER;
  DECLARE nestLabel CHAR(32);
  DECLARE SQLSTATE CHAR(5) DEFAULT '00000';
  DECLARE errorLabel CHAR(32) DEFAULT '';
  
  DECLARE r1 CURSOR WITH RETURN FOR
    SELECT name, job, CAST(salary AS DOUBLE)
    FROM staff
    WHERE salary > medianSalary
    ORDER BY salary; 
  
  DECLARE r2 CURSOR WITH RETURN FOR
    SELECT name, job, CAST(salary AS DOUBLE)
    FROM staff
    WHERE salary < medianSalary
    ORDER BY salary DESC; 

  DECLARE EXIT HANDLER FOR NOT FOUND
    SIGNAL SQLSTATE value '38200' SET MESSAGE_TEXT= '100: NO DATA FOUND'; 

  DECLARE EXIT HANDLER FOR SQLEXCEPTION
    SIGNAL SQLSTATE value SQLSTATE SET MESSAGE_TEXT = errorLabel;
    
  SET errorLabel = 'OPEN CURSOR r1';
  OPEN r1;

  SET errorLabel = 'OPEN CURSOR r2';
  OPEN r2;

  -- the EXIT handler ensures that we will not reach this point unless the 
  -- result set has results

END @

