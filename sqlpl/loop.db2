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
-- SOURCE FILE NAME: loop.db2
--    
-- SAMPLE: To create the LOOP_UNTIL_SPACE SQL procedure 
--
-- To create the SQL procedure:
-- 1. Connect to the database
-- 2. Enter the command "db2 -td@ -vf loop.db2"
--
-- To call the SQL procedure from the command line:
-- 1. Connect to the database
-- 2. Enter the following command:
--    db2 "CALL loop_until_space (?)" 
--
-- You can also call this SQL procedure by compiling and running the
-- C embedded SQL client application, "loop", using the loop.sqc
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

CREATE PROCEDURE loop_until_space(OUT counter INT)
LANGUAGE SQL
BEGIN
  DECLARE v_firstnme VARCHAR(12);
  DECLARE v_midinit CHAR(1);
  DECLARE v_lastname VARCHAR(15);
  DECLARE v_counter SMALLINT DEFAULT 0;

  DECLARE c1 CURSOR FOR 
    SELECT firstnme, midinit, lastname 
    FROM employee
    ORDER BY midinit DESC;
  DECLARE CONTINUE HANDLER FOR NOT FOUND
    SET counter = -1;

  -- initialize OUT parameter
  SET counter = 0;
  OPEN c1;
  fetch_loop:
  LOOP
    FETCH c1 INTO 
      v_firstnme, v_midinit, v_lastname;
    -- Use a local variable for the iterator variable
    -- because SQL procedures only allow you to assign 
    -- values to an OUT parameter
    SET v_counter = v_counter + 1;
    IF v_midinit = ' ' THEN
      LEAVE fetch_loop;
    END IF;
  END LOOP fetch_loop;
  CLOSE c1;

  -- Now assign the value of the local
  -- variable to the OUT parameter
  SET counter = v_counter;
END @
