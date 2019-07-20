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
-- SOURCE FILE NAME: rsultset.db2
--    
-- SAMPLE: To register and create the MEDIAN_RESULT_SET SQL procedure
--
-- To create the SQL procedure:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -vf rsultset.db2"
--
-- To call the SQL procedure from the command line:
-- 1. Connect to the database
-- 2. Enter the following command:
--    db2 "CALL median_result_set (?)" 
--
-- You can also call this SQL procedure by compiling and running the
-- CLI client application, "rsultset", using the rsultset.c
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

CREATE PROCEDURE median_result_set
-- Declare medianSalary as OUT so it can be used to return values
(OUT medianSalary DOUBLE)
RESULT SETS 2
LANGUAGE SQL
BEGIN
   DECLARE v_numRecords INT DEFAULT 1;
   DECLARE v_counter INT DEFAULT 0;

   DECLARE c1 CURSOR FOR
     SELECT salary FROM staff
     ORDER BY CAST(salary AS DOUBLE);

   -- use WITH RETURN in DECLARE CURSOR to return a result set
   DECLARE c2 CURSOR WITH RETURN FOR
     SELECT name, job, salary
     FROM staff 
     WHERE CAST(salary AS DOUBLE) > medianSalary
     ORDER BY salary;

   -- you can return as many result sets as you like, just
   -- ensure that the exact number is declared in the RESULT SETS
   -- clause of the CREATE PROCEDURE statement

   -- use WITH RETURN in DECLARE CURSOR to return another result set
   DECLARE c3 CURSOR WITH RETURN FOR
     SELECT name, job, salary
     FROM staff
     WHERE CAST(salary AS DOUBLE) < medianSalary
     ORDER BY SALARY DESC;

   DECLARE CONTINUE HANDLER FOR NOT FOUND
     SET medianSalary = 6666; 

   -- initialize OUT parameter
   SET medianSalary = 0;

   SELECT COUNT(*) INTO v_numRecords FROM STAFF;

   OPEN c1;
   WHILE v_counter < (v_numRecords / 2 + 1) DO
     FETCH c1 INTO medianSalary;
     SET v_counter = v_counter + 1;
   END WHILE;
   CLOSE c1;

   -- return 1st result set, do not CLOSE cursor
   OPEN c2;
  
   -- return 2nd result set, do not CLOSE cursor
   OPEN c3;
END @
