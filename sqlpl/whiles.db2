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
-- SOURCE FILE NAME: whiles.db2
--    
-- SAMPLE: To create the DEPT_MEDIAN SQL procedure 
--
-- To create the SQL procedure:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -vf whiles.db2"
--
-- To call the SQL procedure from the command line:
-- 1. Connect to the database
-- 2. Enter the following command:
--    db2 "CALL dept_median (51, ?)" 
--
-- You can also call this SQL procedure by compiling and running the
-- C embedded SQL client application, "whiles", using the whiles.sqc
-- source file available in the sqlpl samples directory.
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

CREATE PROCEDURE dept_median
(IN deptNumber SMALLINT, OUT medianSalary DOUBLE)
LANGUAGE SQL
BEGIN 
   DECLARE SQLCODE INTEGER;
   DECLARE SQLSTATE CHAR(5);
   DECLARE v_numRecords INT DEFAULT 1;
   DECLARE v_counter INT DEFAULT 0;
   DECLARE v_mod INT DEFAULT 0;
   DECLARE v_salary1 DOUBLE DEFAULT 0;
   DECLARE v_salary2 DOUBLE DEFAULT 0;

   DECLARE c1 CURSOR FOR 
     SELECT CAST(salary AS DOUBLE) FROM staff 
     WHERE DEPT = deptNumber 
     ORDER BY salary;
   DECLARE EXIT HANDLER FOR NOT FOUND
     SET medianSalary = 6666; 

   -- initialize OUT parameter
   SET medianSalary = 0;

   SELECT COUNT(*) INTO v_numRecords FROM staff
     WHERE DEPT = deptNumber;

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
END @
