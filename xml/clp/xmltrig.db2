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
-- SAMPLE FILE NAME: xmltrig.db2
--
-- PURPOSE: This sample shows how triggers are used to enforce automatic 
-- 	    validation while inserting/updating xml documents. 
--
-- USAGE SCENARIO: When a customer places a purchase order request an entry
--                 is made in the "customer" table by inserting customer 
--                 information and his history details. If the customer is 
--                 new, and is placing a request for the first time to this 
--                 supplier,then the history column in the "customer" table
--                 wil be NULL. If he's an old customer, data in "customer"
--                 table info and history columns are inserted.
--
-- PREREQUISITE: 
--    On Unix:    copy boots.xsd file from <install_path>/sqllib
--                /samples/xml/data directory to current directory.
--    On Windows: copy boots.xsd from <install_path>\sqllib\
--                samples\xml\data directory to current directory
--
-- EXECUTION: db2 -td@ -vf xmltrig.db2
--
-- INPUTS: NONE
--
-- OUTPUTS: The last trigger statement which uses XMLELEMENT on transition
--          variable will fail. All other trigger statements will succeed. 
--
-- OUTPUT FILE: xmltrig.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--           CREATE TRIGGER
--           INSERT
--           DELETE
--           DROP
--           REGISTER XMLSCHEMA
--           COMPLETE XMLSCHEMA
--
-- SQL/XML FUNCTIONS USED:
--           XMLDOCUMENT
--           XMLPARSE
--           XMLVALIDATE
--           XMLELEMENT
--
--
-----------------------------------------------------------------------------
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
--
-----------------------------------------------------------------------------
-- SAMPLE DESCRIPTION
--
-----------------------------------------------------------------------------
-- 1. Register boots.xsd schema with http://posample1.org namespace.
--
-- 2. This sample consists of four different cases of create trigger 
--    statements to show automatic validation of xml documents with 
--    triggers.
--
--    Case1: This first trigger statement shows how to assign values to 
--    non-xml transition variables, how to validate XML documents and 
--    also to show that NULL values can be assigned to XML transition 
--    variables in triggers. 
--
--    Case2: Create a BEFORE INSERT trigger to validate info column in
--    "customer" table and insert a value for history column without 
--    any validation
--
--    Case3: Create a BEFORE UPDATE trigger with ACCORDING TO clause used
--    with WHEN clause.This trigger statement shows that only when WHEN
--    condition is satisfied, the action part of the trigger will be
--    executed.WHEN conditions are used with BEFORE UPDATE triggers.
--
--    Case4: Create a BEFORE INSERT trigger with XMLELEMENT function being 
--    used on a transition variable. This case results in a failure as only
--    XMLVALIDATE function is allowed on XML transition variables.
--
-- NOTE : In a typical in real-time scenario, DBAs will create triggers 
--  and users will insert records using one or more insert/update statements 
--  not just one insert statement as shown in this sample. 
-----------------------------------------------------------------------------
-- SETUP
-----------------------------------------------------------------------------
-- Connect to sample database
CONNECT TO sample@
--

-- Register boots schema
REGISTER XMLSCHEMA http://posample1.org FROM boots.xsd AS boots@
COMPLETE XMLSCHEMA boots@

-----------------------------------------------------------------------------
--
--    Case1: This first trigger statement shows how to assign values to 
--    non-xml transition variables, how to validate XML documents and 
--    also to show that NULL values can be assigned to XML transition 
--    variables in triggers. 
--
-----------------------------------------------------------------------------

CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON customer 
REFERENCING NEW AS n 
FOR EACH ROW MODE DB2SQL 
BEGIN ATOMIC
  set n.Cid = 5000; 
  set n.info = xmlvalidate (n.info ACCORDING TO XMLSCHEMA ID customer); 
  set n.history = NULL; 
END@

-- Insert values into "customer" table
INSERT INTO customer VALUES (1008, 
    '<customerinfo Cid="1008"><name>
    Larry Menard</name><addr country="Canada"><street>223 Koramangala 
    ring Road</street><city>Toronto</city><prov-state>Ontario
    </prov-state><pcode-zip>M4C 5K8</pcode-zip></addr>
    <phone type="work">905-555-9146</phone><phone type="home">
    416-555-6121</phone><assistant><name>Goose Defender</name>
    <phone type="home">416-555-1943</phone></assistant>
    </customerinfo>', NULL)@ 

-- Display the inserted info from "customer" table     
SELECT Cid, info FROM customer 
WHERE Cid = 5000@

-- DROP trigger TR1
DROP TRIGGER TR1@

-----------------------------------------------------------------------------
--
--    Case2: Create a BEFORE INSERT trigger to validate info column in
--    "customer" table and insert a value for history column without 
--    any validation
--
-----------------------------------------------------------------------------

CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON customer
REFERENCING NEW AS n 
FOR EACH ROW MODE DB2SQL 
BEGIN ATOMIC 
  set n.Cid =5001; 
  set n.info = xmlvalidate(n.info ACCORDING TO XMLSCHEMA ID customer); 
  set n.history = '<customerinfo Cid="1009">
                 <name>madhavi</name></customerinfo>';
END@

-- INSERT row into "customer" table 
INSERT INTO customer VALUES (1009,
    ' <customerinfo Cid="1009"><name>
    Larry Menard</name><addr country="Canada"><street>
    223 Koramangala ring Road</street><city>Toronto</city>
    <prov-state>Ontario</prov-state><pcode-zip>M4C 5K8</pcode-zip>
    </addr><phone type="work">905-555-9146</phone>
    <phone type="home">416-555-6121</phone><assistant><name>
    Madhavi Kaza</name><phone type="home">416-555-1943
    </phone></assistant></customerinfo>', NULL)@ 

-- Display inserted info from "customer" table
SELECT Cid, info, history 
FROM customer 
WHERE Cid = 5001@

-----------------------------------------------------------------------------
--
--    Case3: Create a BEFORE UPDATE trigger with ACCORDING TO clause used
--    with WHEN clause.This trigger statement shows that only when WHEN
--    condition is satisfied, the action part of the trigger will be
--    executed.WHEN conditions are used with BEFORE UPDATE triggers.
--
-----------------------------------------------------------------------------

CREATE TRIGGER TR2 NO CASCADE BEFORE UPDATE ON customer 
REFERENCING NEW AS n 
FOR EACH ROW MODE DB2SQL 
WHEN (n.info is not validated ACCORDING TO XMLSCHEMA ID CUSTOMER) 
BEGIN ATOMIC 
  set n.Cid = 5002; 
  set n.info = xmlvalidate(n.info ACCORDING TO XMLSCHEMA ID customer); 
  set n.history = '<customerinfo Cid="1010">
                <name>sum Lata</name></customerinfo>'; 
END@

-- UPDATE the 'info' column value in the "customer" table whose Cid is 5001
UPDATE CUSTOMER SET customer.info = XMLPARSE(document 
      '<customerinfo Cid="1012">
      <name>Russel</name><addr country="India"><street>
      Koramangala ring Road</street><city>Bangalore</city>
      <prov-state>Karnataka</prov-state><pcode-zip>M4C 5K9
      </pcode-zip></addr><phone type="work">995-545-9142</phone>
      <phone type="home">476-552-6421</phone><assistant><name>
      Madhavi Kaza</name><phone type="home">415-595-1243</phone>
      </assistant></customerinfo>' preserve whitespace) 
WHERE Cid=5001@

-- Display updated data from "customer" table
SELECT Cid, info, history 
FROM customer 
WHERE Cid = 5002@

-- DROP TRIGGERS TR1 and TR2
DROP TRIGGER TR1@
DROP TRIGGER TR2@

-----------------------------------------------------------------------------
--
--    Case4: Create a BEFORE INSERT trigger with XMLELEMENT function being 
--    used on a transition variable. This case results in a failure as only
--    XMLVALIDATE function is allowed on transition variables.
--
-----------------------------------------------------------------------------

-- Create table "boots"
CREATE TABLE boots (Cid int, xmldoc1 XML, xmldoc2 XML)@
 
-- Trigger creation itself fails as XMLELEMENT is not allowed on 
-- transition variable         
CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON boots 
REFERENCING NEW as n
FOR EACH ROW MODE DB2SQL 
BEGIN ATOMIC 
  set n.Cid=5004; 
  set n.xmldoc1 = XMLVALIDATE(xmldoc1 ACCORDING TO XMLSCHEMA URI 
                     'http://posample1.org');  
  set n.xmldoc2 = XMLDOCUMENT(XMLELEMENT(name adidas, n.xmldoc2));
END@

-----------------------------------------------------------------------------
--
-- CLEANUP
--
-----------------------------------------------------------------------------

-- Delete all rows inserted from this sample
DELETE FROM CUSTOMER 
WHERE Cid > 1005@

-- Drop table boots
DROP TABLE boots@

-- Drop schema
DROP XSROBJECT BOOTS@
