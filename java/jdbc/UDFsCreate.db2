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
-- SOURCE FILE NAME: UDFsCreate.db2
--    
-- SAMPLE: How to catalog the UDFs contained in UDFsqlsv.java 
--
-- To run this script from the CLP, perform the following steps:
-- 1. connect to the database
-- 2. issue the command "db2 -td@ -vf <script-name>"
--    where <script-name> represents the name of this script
----------------------------------------------------------------------------

CREATE FUNCTION Convert(CHAR(2), DOUBLE, CHAR(2))
RETURNS DOUBLE
EXTERNAL NAME 'UDFsqlsv!Convert'
FENCED
CALLED ON NULL INPUT
NOT VARIANT
READS SQL DATA 
PARAMETER STYLE DB2GENERAL
LANGUAGE JAVA
NO EXTERNAL ACTION@
  
CREATE FUNCTION sumSalary(CHAR(3))
RETURNS DOUBLE
EXTERNAL NAME 'UDFsqlsv!sumSalary'
FENCED
CALLED ON NULL INPUT
NOT VARIANT
READS SQL DATA 
PARAMETER STYLE DB2GENERAL
LANGUAGE JAVA
NO EXTERNAL ACTION@

CREATE FUNCTION tableUDFWITHSQL ( DOUBLE )
RETURNS TABLE ( name VARCHAR(20), job VARCHAR(20), salary DOUBLE )
EXTERNAL NAME 'UDFsqlsv!tableUDF'
LANGUAGE JAVA
PARAMETER STYLE DB2GENERAL
NOT DETERMINISTIC
FENCED
READS SQL DATA
NO EXTERNAL ACTION
SCRATCHPAD 10
FINAL CALL
DISALLOW PARALLEL
NO DBINFO@
  
CREATE TABLE EXCHANGERATE (sourceCurrency char(2),
	                   exchangeRate double,
	                   resultCurrency char(2))@

INSERT INTO EXCHANGERATE VALUES ('US',1.5,'CA')@

INSERT INTO EXCHANGERATE VALUES ('CA', .67, 'US')@

