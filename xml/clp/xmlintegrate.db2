----------------------------------------------------------------------------
--   (c) Copyright IBM Corp. 2007 All rights reserved.
--   
--   The following sample of source code ("Sample") is owned by International 
--   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
--   copyrighted and licensed, not sold. You may use, copy, modify, and 
--   distribute the Sample in any form without payment to IBM, for the purpose of 
--   assisting you in the development of your applications.
--   
--   The Sample code is provided to you on an "AS IS" basis, without warranty of 
--   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
--   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
--   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
--   not allow for the exclusion or limitation of implied warranties, so the above 
--   limitations or exclusions may not apply to you. IBM shall not be liable for 
--   any damages you suffer as a result of using, copying, modifying or 
--   distributing the Sample, even if IBM has been advised of the possibility of 
--   such damages.
----------------------------------------------------------------------------
--
-- SAMPLE FILE NAME: xmlintegrate.db2
--
-- PURPOSE: To show how to use XMLROW and XMLGROUP functions to publish
--          relational information as XML. 
--          To show XMLQuery default passing mechanism. 
--	    To show default column specification for XMLTABLE.
--
-- USAGE SCENARIO: The super marker manager maintains a database to store 
--                 all customer's addresses in a relational table called 
--                 "addr" so that whenever a customer places an order for
--                 any item, he can use this "addr" table to deliver the
--                 item. As the number of customers grew year after 
--                 year,there was a need to change the table structure  
--                 to have one single XML column for address and maintain 
--                 the data in a new table called "customerinfo_new".
--
-- PREREQUISITE: NONE
--
-- EXECUTION: db2 -tvf xmlintegrate.db2
--
-- INPUTS: NONE
-- 
-- OUTPUTS: Shows comparison of XML documents created using different
--          SQLXML functions and using XMLROW, XMLGROUP functions
--
-- OUTPUT FILE: xmlintegrate.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--               CREATE TABLE
-- 		 INSERT 
--		 SELECT
--
-- SQL/XML FUNCTIONS USED:
--  		 XMLROW
--		 XMLGROUP
-- 		 XMLDOCUMENT
--		 XMLELEMENT
--		 XMLCONCAT
--		 XMLATTRIBUTES
--		 
---------------------------------------------------------------------------
-- For more information about the command line processor (CLP) scripts,     
-- see the README file.                                                     
-- For information on using SQL statements, see the SQL Reference.          
--                                                                          
-- For the latest information on programming, building, and running DB2     
-- applications, visit the DB2 application development website:             
-- http://www.software.ibm.com/data/db2/udb/ad                            
--  
--------------------------------------------------------------------------
--
-- SAMPLE DESCRIPTION
--
--------------------------------------------------------------------------
--
-- 1. Shows comparison of publishing XML documents 
--    using different SQL/XML functions and XMLROW function.
--
--  1.1 Element centric mapping comparison.
--
--  1.2 Attribute centric mapping comparison.
--
-- 2. Shows the comparison of publishing XML documents using 
--    different SQL/XML publishing functions and XMLGROUP function
--
-- 3. Shows XMLQuery default parameter passing mechanism.
--
-- 4. Shows default column specification for XMLTABLE.
--
-------------------------------------------------------------------------
--
-------------------------------------------------------------------------
-- SETUP
-------------------------------------------------------------------------
-- Connect to sample database
CONNECT TO SAMPLE;
--

-- Create table "addr"
CREATE TABLE addr (custid int, 
                   name varchar(20), 
		   street varchar(20), 
		   city varchar(10), 
		   province varchar(50), 
		   postalcode BIGINT);

-- Create table "customerinfo_new"
CREATE TABLE customerinfo_new (custid smallint, address xml);

-------------------------------------------------------------------------
--
-- 1. Shows comparison of publishing XML documents using different
--    SQL/XML functions and XMLROW function.
--
-------------------------------------------------------------------------

-------------------------------------------------------------------------
--
--  1.1 Element centric mapping comparison
--
-------------------------------------------------------------------------

-- Insert values into "addr" table
INSERT INTO addr 
VALUES(1000, 'madhavi', 'madivala', 'Bangalore', 'karnataka', 560004);

-- Insert values into "customerinfo_new" table and Create an XML 
-- document address with name, street, city, postal code columns 
-- in the "addr" table and display it along with custid details
INSERT INTO customerinfo_new (Custid, Address)
SELECT Custid, XMLDOCUMENT(
               XMLElement(NAME "row", XMLCONCAT(
	         XMLElement(NAME "NAME", name OPTION NULL ON NULL),
		 XMLElement(NAME "STREET", street OPTION NULL ON NULL),
		 XMLElement(NAME "CITY", city OPTION NULL ON NULL),
		 XMLElement(NAME "PROVINCE", province OPTION NULL ON NULL), 
		 XMLElement(NAME "POSTALCODE", postalcode OPTION NULL ON NULL))
                 OPTION NULL ON NULL )
	         ) FROM addr;

-- Create an XML document using XMLROW function with name, street
-- city, postalcode columns of "addr" table and insert into Address column
-- of "customerinfo_new" table
INSERT INTO customerinfo_new (Custid, Address)
(SELECT Custid, XMLROW(C.name, C.street, C.city, C.province,C.postalcode) 
 FROM addr C);

-- Check whether XML document created using SQL/XML publishing functions
-- and the one created with XMLROW are same.
SELECT * FROM customerinfo_new;

--------------------------------------------------------------------------
--
--  1.2 Attribute centric mapping comparison
--
--------------------------------------------------------------------------

-- Attribute centric mapping using CASE expressions in DB2 9
SELECT Custid, CASE WHEN C.name is NULL and C.street is NULL 
                       and C.City is NULL and C.province is NULL 
                       and C.postalcode is NULL 
                    THEN CAST(NULL as XML)
               ELSE XMLDOCUMENT(XMLElement(name "row", 
                                XMLAttributes(C.name, C.street,C.city, 
					      C.province, C.postalcode))) 
               END 
FROM addr C;

-- Attribute centric mapping using XMLROW function
SELECT Custid, XMLROW(C.name, C.street, C.city, C.province,
                      C.postalcode OPTION AS ATTRIBUTES) 
FROM addr as C;

----------------------------------------------------------------------------
--
-- 2. Shows the comparison of publishing XML documents using different 
--    SQL/XML publishing functions and XMLGROUP function
--
---------------------------------------------------------------------------- 

-- Get all purchase orders made by a particular customer as one single XML
-- document
SELECT XMLDOCUMENT(
       XMLElement(NAME "rowset", 
       XMLAgg(XMLElement(NAME "row", 
              XMLElement(NAME "orderdate", p.orderdate OPTION NULL ON NULL), 
              XMLElement(NAME "porder", p.porder OPTION NULL ON NULL) 
              OPTION NULL ON NULL)ORDER BY p.orderdate) 
       OPTION NULL ON NULL)) 
FROM purchaseorder p, customer c 
WHERE p.custid=c.Cid;

-- Doing the same as above using XMLGROUP function.
SELECT  XMLGroup(p.orderdate, p.porder ORDER BY p.orderdate) 
FROM purchaseorder p, customer c 
WHERE p.custid=c.Cid; 

----------------------------------------------------------------------------
--
-- 3. Shows XMLQuery default parameter passing mechanism
--
----------------------------------------------------------------------------

-- Create employees table
CREATE TABLE employees (empno int,
                       lastname varchar(20), 
                       firstname varchar(20), 
                       workdept varchar(20), 
                       phoneno varchar(20), 
		       hiredate DATE);

-- Insert values into employees table.
INSERT INTO employees 
VALUES (100, 'latha', 'suma', 'Informix', '5114', '03/01/2006');

-- Create an Emp element with 2 attributes lastname and first name, also create
-- elements with employee's department, phone number, hire date and display it.
SELECT empno, XMLQuery('<Emp lastname="{$LASTNAME}" firstname="{$FIRSTNAME}">
                             <department>{$WORKDEPT}</department>
                             <phone_ext>{$PHONENO}</phone_ext>
                             <hire_date>{$HIREDATE}</hire_date>
                        </Emp>') 
FROM employees ORDER BY empno desc;

-----------------------------------------------------------------------------
--
-- 4. Shows the default column specification of XMLTABLE
--
-----------------------------------------------------------------------------

-- Lists all the customer phone numbers
XQuery for $plist in db2-fn:sqlquery("SELECT X.phone FROM customer, 
   XMLTABLE('$INFO/customerinfo/phone') AS X(phone)")
   order by $plist/@type, $plist/text() 
   return $plist;
----------------------------------------------------------------------------
--
-- CLEANUP
--
----------------------------------------------------------------------------
DROP TABLE addr;
DROP TABLE customerinfo_new;
DROP TABLE employees;
