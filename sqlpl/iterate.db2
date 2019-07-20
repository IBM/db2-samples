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
-- SOURCE FILE NAME: iterate.db2
--    
-- SAMPLE: To create the ITERATOR SQL procedure 
--
-- To create the SQL procedure:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -vf iterate.db2"
--
-- To call the SQL procedure from the command line:
-- 1. Connect to the database
-- 2. Enter the following command:
--    db2 "CALL iterator ()" 
--
-- You can also call this SQL procedure by compiling and running the
-- C embedded SQL client application, "iterate", using the iterate.sqc
-- source file available in the sqlpl samples directory.
----------------------------------------------------------------------------
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

CREATE PROCEDURE iterator()
LANGUAGE SQL 
BEGIN 
   DECLARE SQLSTATE CHAR(5);
   DECLARE v_dept CHAR(3);
   DECLARE v_deptname VARCHAR(29);
   DECLARE v_admdept CHAR(3);
   DECLARE at_end INT DEFAULT 0;
   DECLARE new_v_dept VARCHAR(3);
   DECLARE dept_no  INT DEFAULT 11;

   DECLARE not_found CONDITION FOR SQLSTATE '02000';
   DECLARE c1 CURSOR FOR 
     SELECT deptno, deptname, admrdept 
     FROM department
     ORDER BY deptno;
   DECLARE CONTINUE HANDLER FOR not_found
     SET at_end = 1;

   OPEN c1;
   ins_loop:
   LOOP
     FETCH c1 INTO v_dept, v_deptname, v_admdept;
     IF at_end = 1 THEN
       LEAVE ins_loop;
     ELSEIF v_dept = 'D11' THEN
       ITERATE ins_loop;
     END IF;
     SET new_v_dept= VARCHAR('K'||CHAR(dept_no)||'',3);
     SET dept_no=dept_no+1;
     INSERT INTO department (deptno, deptname, admrdept)
       VALUES (new_v_dept, v_deptname, v_admdept);
   END LOOP;
   CLOSE c1;
END @
