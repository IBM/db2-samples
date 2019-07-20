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
-- SOURCE FILE NAME: lobstoxml.db2
--
-- SAMPLE: How to move LOB data into an XML column using IMPORT and EXPORT commands
--
-- PREREQUSITES: 
--         Create a directory "lobdatadir" in the present working dirctory
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
-- OUTPUT FILE: lobstoxml.out (available in the online documentation)
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

-- create the table CUSTOMER_LOB with one LOB column "Info"
CREATE TABLE customer_lob(Cid INT, Info CLOB(50K));

-- populate the table CUSTOMER_LOB with multiple rows of data
INSERT INTO customer_lob VALUES(1001,'<customerinfo Cid="1001"><name>Manoj Sardana</name><addr country="Canada"><street>1596 Baseline</street><city>Aurora</city><prov-state>Ontario</prov-state><pcode-zip>N8X-7F8</pcode-zip></addr><phone type="work">905-555-7258</phone><phone type="home">416-555-2937</phone><phone type="cell">905-555-8743</phone><phone type="cottage">613-555-3278</phone></customerinfo>');

INSERT INTO customer_lob VALUES(1002,'<customerinfo Cid="1002"><name>Padma Kota</name><addr country="Canada"><street>1596 Baseline</street><city>Aurora</city><prov-state>Ontario</prov-state><pcode-zip>N8X-7F8</pcode-zip></addr><phone type="work">905-555-7258</phone><phone type="home">416-555-2937</phone><phone type="cell">905-555-8743</phone><phone type="cottage">613-555-3278</phone></customerinfo>');

INSERT INTO customer_lob VALUES(1003,'<customerinfo Cid="1003"><name>Sanjay Kumar</name><addr country="Canada"><street>1596 Baseline</street><city>Aurora</city><prov-state>Ontario</prov-state><pcode-zip>N8X-7F8</pcode-zip></addr><phone type="work">905-555-7258</phone><phone type="home">416-555-2937</phone><phone type="cell">905-555-8743</phone><phone type="cottage">613-555-3278</phone></customerinfo>');

-- export the data from table CUSTOMER_LOB into lobdata.del with LOB data in seperate files 
EXPORT TO lobdata.del OF DEL LOBS TO lobdatadir LOBFILE lobfiles 
  MODIFIED BY LOBSINSEPFILES SELECT * FROM customer_lob;

-- create the table CUSTOMER with an XML column "Info" instead of LOB type
CREATE TABLE customer_xml(Cid INT, Info XML);

-- import data from the lobdata.del and insert into the XML column of table CUSTOMER_XML
IMPORT FROM lobdata.del OF DEL LOBS FROM lobdatadir 
  MODIFIED BY XMLCHAR 
  XMLVALIDATE USING SCHEMA customer
  INSERT INTO customer_xml;

-- Select the data from the table CUSTOMER_XML to show that data is inserted successfully
SELECT * FROM customer_xml ORDER BY cid;

-- drop the tables
DROP TABLE customer_xml;
DROP TABLE customer_lob;

CONNECT RESET;


