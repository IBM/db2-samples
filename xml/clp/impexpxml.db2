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
-- SOURCE FILE NAME: impexpxml.db2
--
-- SAMPLE: How to use IMPORT and EXPORT with new options for XML data
--
-- PREREQUISITES:
--         1. Copy xmldata.del to the Present Working Directory (PWD) 
--         2. Create a directory "xmldatadir" in PWD and copy "xmlfiles.001.xml" 
--            to the "xmldatadir" directory
--
-- SQL STATEMENT USED:
--         CREATE TABLE
--         INSERT INTO
--         SELECT
--         DROP TABLE
--         IMPORT
--         EXPORT
--         TERMINATE
--
-- OUTPUT FILE: impexpxml.out (available in the online documentation)
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

-- connect to the SAMPLE database
CONNECT TO sample;

-- create a table CUSTOMER_XML with XML an column to import the data
CREATE TABLE customer_xml(Cid INT, Info XML);

-- import the data to the table using XMLVALIDATE USING XDS clause
IMPORT FROM xmldata.del OF DEL XML FROM xmldatadir 
  MODIFIED BY XMLCHAR
  XMLVALIDATE using XDS DEFAULT customer
  IGNORE (supplier) MAP((product,customer))
  INSERT INTO customer_xml;

-- select the data from the table to show that data is inserted successfully
SELECT * FROM customer_xml ORDER BY cid;

-- delete the inserted data from CUSTOMER_XML
DELETE FROM customer_xml;

-- import the data to the table using XMLVALIDATE USING SCHEMA clause
IMPORT FROM xmldata.del OF DEL XML FROM xmldatadir
  MODIFIED BY XMLCHAR 
  XMLVALIDATE using SCHEMA customer 
  INSERT INTO customer_xml;

-- Select the data from the table to show that data is inserted successfully
SELECT * FROM customer_xml ORDER BY cid;

-- Export the data back using XMLSAVESCHEMA option
EXPORT TO xmldata_exp.del OF DEL XML TO xmldatadir XMLFILE xmlfiles_exp 
  MODIFIED BY XMLCHAR XMLINSEPFILES XMLSAVESCHEMA 
  SELECT * FROM customer_xml;

-- drop the table CUSTOMER_XML
DROP TABLE customer_xml;

CONNECT RESET;

