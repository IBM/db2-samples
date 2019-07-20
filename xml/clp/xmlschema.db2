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
-- SOURCE FILE NAME:xmlschema.db2
--
-- SAMPLE USAGE SCENARIO: Consider a user who needs to insert an XML type value 
-- into the table. The user would like to ensure that the XML value conforms to a 
-- deterministic XML schema.  
--
-- PROBLEM: User has schema's for all the XML values and like to validate the values 
-- as per schema while inserting it to the tables.
--
-- SOLUTION: 
-- To achieve the goal, the sample will follow the following steps:
-- a) Register the primary XML schema
-- b) Add the XML schema documents to the primary XML schema to ensure that the 
--    schema is deterministic
-- c) Insert an XML value into an existing XML column and perform validation
--
-- SAMPLE EXECUTION : Run this sample using following command
--
--             db2 -td! -vf xmlschema.db2
--
-- PREREQUISITE :copy product.xsd, order.xsd, 
--              customer.xsd, header.xsd Schema files, order.xml XML 
--              document from xml/data directory to working 
--              directory
--
-- SQL STATEMENTS USED:
--        REGISTER XMLSCHEMA
--        ADD XMLSCHEMA DOCUMENT
--        COMPLETE XMLSCHEMA
--        INSERT
--
-- SQL/XML FUNCTIONS USED:
--        XMLVALIDATE
--        XMLPARSE
--
-- OUTPUT FILE: xmlschema.out (available in the online documentation)
-----------------------------------------------------------------------------
--
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2
-- applications, visit the DB2 application development website:
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

-- CONNECT TO THE DATABASE
CONNECT TO SAMPLE!

-- REGISTER THE MAIN XML SCHEMA
REGISTER XMLSCHEMA http://www.test.com/order FROM order.xsd AS order! 

-- ADD XML SCHEMA DOCUMENT TO MAIN SCHEMA
ADD XMLSCHEMA DOCUMENT TO order ADD http://www.test.com/header FROM header.xsd!

-- ADD XML SCHEMA DOCUMENT TO MAIN SCHEMA
ADD XMLSCHEMA DOCUMENT TO order ADD http://www.test.com/product FROM product.xsd!

-- ADD XML SCHEMA DOCUMENT TO MAIN SCHEMA
ADD XMLSCHEMA DOCUMENT TO order ADD http://www.test.com/customer FROM customer.xsd!

-- COMPLETE THE SCHEMA REGISTRATION 
COMPLETE XMLSCHEMA order!

-- SELECT INFORMATION ABOUT THE REGISTERED SCHEMA FROM CATALOG TABLE 
SELECT CAST(OBJECTSCHEMA AS VARCHAR(15)), CAST(OBJECTNAME AS VARCHAR(15))  FROM syscat.xsrobjects WHERE OBJECTNAME='ORDER'!

-- INSERT THE XML DOCUMENT
CREATE TABLE t1 (id INT GENERATED ALWAYS AS IDENTITY,po XML)!

INSERT INTO t1(po) VALUES(xmlvalidate(xmlparse(document('<?xml version="1.0" encoding="UTF-8"?>
                    <po:PurchaseOrder xmlns:po="http://www.test.com/po">
                       <Header>
                            <Id>1</Id>
                            <date>2004-01-29</date>
                            <description>purchase order</description>
                            <value>20</value>
                            <status>shipped</status>
                       </Header>
                       <Items>
                            <Item>
                                 <ItemDescription color="red" weight="5">
                                          <Name>Widget C</Name>
                                          <SKU>1</SKU>
                                          <Price>30</Price>
                                          <Comment>no comment</Comment>
                                 </ItemDescription>
                                 <NumberOrdered>1</NumberOrdered>
                            </Item>
                       </Items>
                       <Customer type="regualar">
                             <Name>Manoj K Sardana</Name>
                             <Address>ring road, bangalore</Address>
                             <Phone>918051055109</Phone>
                             <email>msardana@in.ibm.com</email>
                       </Customer>
                    </po:PurchaseOrder>')) ACCORDING TO XMLSCHEMA ID order))!

-- DROP THE TABLE
DROP TABLE t1!

-- DISCONNECT FROM DATABASE
CONNECT RESET!

