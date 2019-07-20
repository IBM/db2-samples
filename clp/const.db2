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
-- SOURCE FILE NAME: const.db2
--    
-- SAMPLE: How to create a table with a check constraint
--
-- SQL STATEMENTS USED:
--         CREATE TABLE
--         INSERT
--         DROP
--
-- OUTPUT FILE: const.out (available in the online documentation)
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

CREATE TABLE EMPL                                                     
 (ID           SMALLINT NOT NULL,                                         
  NAME         VARCHAR(9),                                                
  DEPT         SMALLINT CHECK (DEPT BETWEEN 10 AND 100),
  JOB          CHAR(5)  CHECK (JOB IN ('Sales', 'Mgr', 'Clerk')),
  HIREDATE     DATE,                                                      
  SALARY       DECIMAL(7,2),                                              
  COMM         DECIMAL(7,2),                                              
  PRIMARY KEY (ID),                                                       
  CONSTRAINT YEARSAL CHECK (YEAR(HIREDATE) > 1986 OR SALARY > 40500) 
 );

-- Attempt to insert a row into table EMPL
-- The attempt will fail, as it would violate check constraint YEARSAL
INSERT INTO EMPL VALUES (1,'Lee', 15, 'Mgr', '1985-01-01' , 40000.00, 1000.00);

DROP TABLE EMPL;
