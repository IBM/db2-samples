----------------------------------------------------------------------------
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
----------------------------------------------------------------------------
--
-- SOURCE FILE NAME: nestedsp.db2
--    
-- SAMPLE: To create the OUT_AVERAGE, OUT_MEDIAN and MAX_SALARY SQL procedures
--         which are used to calculate the average salary, median salary and 
--         maximum salary of the EMPLOYEE table respectively.
--
-- To create the SQL procedures:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -vf nestedsp.db2"
--
-- To call the SQL procedure from the command line:
-- 1. Connect to the database
-- 2. Enter the following command:
--    db2 "CALL out_average (?,?,?)" 
--
-- To drop the SQL stored procedures created with nestedsp.db2 script:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -vf nestedspdrop.db2"
--
-- You can also call this SQL procedure by compiling and running the
-- Java client application using the NestedSP.java
-- source file available in the sqlpl samples directory.
----------------------------------------------------------------------------

CREATE PROCEDURE MAX_SALARY (OUT maxSalary DOUBLE)
LANGUAGE SQL 
READS SQL DATA

BEGIN
  
  SELECT MAX(salary) INTO maxSalary FROM staff;

END @


CREATE PROCEDURE OUT_MEDIAN (OUT medianSalary DOUBLE, OUT maxSalary DOUBLE)
DYNAMIC RESULT SETS 0
LANGUAGE SQL 
MODIFIES SQL DATA
BEGIN 

  DECLARE v_numRecords INT DEFAULT 1;
  DECLARE v_counter INT DEFAULT 0;
  DECLARE v_mod INT DEFAULT 0;
  DECLARE v_salary1 DOUBLE DEFAULT 0;
  DECLARE v_salary2 DOUBLE DEFAULT 0;
 
  DECLARE c1 CURSOR FOR 
    SELECT CAST(salary AS DOUBLE) FROM staff 
    ORDER BY salary;

  SELECT COUNT(*) INTO v_numRecords FROM staff;

  SET v_mod = MOD(v_numRecords, 2);
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
  
  CLOSE c1;

  CALL MAX_SALARY(maxSalary);

END @


CREATE PROCEDURE OUT_AVERAGE (OUT averageSalary DOUBLE, OUT medianSalary DOUBLE, OUT maxSalary DOUBLE)
DYNAMIC RESULT SETS 2
LANGUAGE SQL 
MODIFIES SQL DATA
BEGIN 

  DECLARE r1 CURSOR WITH RETURN TO CLIENT FOR
    SELECT name, job, CAST(salary AS DOUBLE)
    FROM staff
    WHERE salary > averageSalary
    ORDER BY name ASC;
    
  DECLARE r2 CURSOR WITH RETURN TO CLIENT FOR
    SELECT name, job, CAST(salary AS DOUBLE)
    FROM staff
    WHERE salary < averageSalary
    ORDER BY name ASC; 

  SELECT AVG(salary) INTO averageSalary FROM staff;
  CALL OUT_MEDIAN(medianSalary, maxSalary); 

  -- open the cursors to return result sets
  OPEN r1;

  OPEN r2;

END @

