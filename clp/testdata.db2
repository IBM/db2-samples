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
-- SOURCE FILE NAME: testdata.db2
--    
-- SAMPLE: How to populate a table with randomly generated test data
--
-- DB2 BUILT-IN FUNCTIONS USED:
--         RAND()
--         TRANSLATE()
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         INSERT
--         SELECT
--         DROP TABLE
--
-- OUTPUT FILE: testdata.out (available in the online documentation)
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

 CREATE TABLE EMPL (ENO INTEGER, LASTNAME VARCHAR(30),
                 HIREDATE DATE, SALARY INTEGER);
 
 
 INSERT INTO EMPL 
 -- generate 100 records
 WITH DT(ENO) AS (VALUES(1) UNION ALL SELECT ENO+1 FROM DT WHERE ENO < 100 )
 
 -- Now, use the generated records in DT to create other columns
 -- of the employee record.
   SELECT ENO,
     TRANSLATE(CHAR(INTEGER(RAND()*1000000)),
               CASE MOD(ENO,4) WHEN 0 THEN 'aeiou' || 'bcdfg'
                               WHEN 1 THEN 'aeiou' || 'hjklm'
                               WHEN 2 THEN 'aeiou' || 'npqrs'
                                      ELSE 'aeiou' || 'twxyz' END,
                                           '1234567890') AS LASTNAME,
     CURRENT DATE - (RAND()*10957) DAYS AS HIREDATE,
     INTEGER(10000+RAND()*200000) AS SALARY
   FROM DT;
                                                      
 SELECT * FROM EMPL;

 DROP TABLE EMPL;

