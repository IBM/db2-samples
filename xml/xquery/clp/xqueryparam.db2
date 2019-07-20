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
-- SAMPLE FILE NAME: xqueryparam.db2
--
-- PURPOSE: This sample shows how to pass parameters to the 
--          db2-fn:sqlquery function.
--
-- USAGE SCENARIO: The super market manager maintains database with 
--                 "employee" and "dept_location" tables. "Employee" table 
--                 contains employee ID and employee address. 
--                 "dept_location" table contains the department and 
--                 and it's location details.He will query
--                 these tables to get information about employees, their 
--                 department details.
--                 The last XQuery exprepression in this sample shows
--                 purchaseorder details from the sample database
--                 purchaseorder table.
--
-- PREREQUISITE: Sample database should exist before running this sample.
--
-- EXECUTION: db2 -td@ -vf xqueryparam.db2
--
-- INPUTS: NONE
--
-- OUTPUTS: Queries will display the results.
--
-- OUTPUT FILE: xqueryparam.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--           CREATE TABLE
--           INSERT
--           DROP
--
-- SQL/XML FUNCTIONS USED:
--	     SQLQUERY
--           XMLCOLUMN
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
-- 1. Passing single parameter to SQL fullselect db2-fn:sqlquery function.
--
-- 2. Passing multiple parameters to SQL fullselect in db2-fn:sqlquery function.
--
-----------------------------------------------------------------------------
-- SETUP
-----------------------------------------------------------------------------
-- Connect to sample database
CONNECT TO sample@
--

-- Create table "employee"
CREATE TABLE employees(empid int, addr XML)@

-- Create table "dept_location"
CREATE TABLE dept_location(dept_name varchar(20), 
                             branch_name varchar(50), 
                             block_no varchar(20), street 
                             varchar(20), city varchar(20), 
                             zip_code varchar(20),
                             dept_details XML)@
 
-- Insert row into table "dept_location"
INSERT INTO dept_location
VALUES ('DB2', 'EGL', 'B', 'Koramangala', 'Bangalore', '500042',
XMLPARSE(document
 '<dept_details xmlns="http://posample.org" dept_code="E32">
   <manager>Peter suzanski</manager>
   <teams>
     <team1>Samples</team1>
     <team2>testing</team2>
     <team3>Development</team3>
   </teams>
   <no_of_people>140</no_of_people>
 </dept_details>' ))@

-- Insert row into table "dept_location"
INSERT INTO dept_location
VALUES ('Informix','MANYATA', 'D2', 'Hebbal', 'Bangalore', '500067',
XMLPARSE(document
'<dept_details xmlns="http://posample.org" dept_code="E34">
   <manager>Jeff </manager>
   <teams>
     <team1>bird</team1>
     <team2>QA</team2>
   </teams>
   <no_of_people>60</no_of_people>
 </dept_details>' ))@

-- Insert row into table "employee"
INSERT INTO employees 
VALUES (1005, XMLPARSE(document 
'<employeeinfo xmlns="http://posample.org" empid="1005">
  <name>Ravi varma</name>
    <addr country="India">
      <street>Hebbal</street>
      <city>Bangalore</city>
      <prov-state>Karnataka</prov-state>
      <pcode-zip>500067</pcode-zip>
    </addr>
</employeeinfo>'))@  

-- Insert row into table "employee"
INSERT INTO employees
VALUES (1006, XMLPARSE(document 
'<employeeinfo xmlns="http://posample.org" empid="1006">
  <name>Oswal Menard</name>
    <addr country="India">
      <street>Koramangala</street>
      <city>Bangalore</city>
       <prov-state>Karnataka</prov-state>
      <pcode-zip>500042</pcode-zip>
    </addr>
</employeeinfo>'))@ 

-----------------------------------------------------------------------------
-- 1. Passing single parameter to SQL fullselect in db2-fn:sqlquery function.
-----------------------------------------------------------------------------
-- The following XQuery expression returns an employee's postal code
-- and department details when the employee and the  department are in
-- the same location (defined by zip code).
XQUERY declare default element namespace "http://posample.org";
  for $pcode in db2-fn:xmlcolumn("EMPLOYEES.ADDR")/employeeinfo/addr/pcode-zip
    for $deptinfo in db2-fn:sqlquery( "SELECT dept_details FROM dept_location 
                              WHERE zip_code = parameter(1)", $pcode)
  order by $pcode  
  return <out>{$pcode, $deptinfo }</out>@

------------------------------------------------------------------------------
-- 2. Passing multiple parameters to SQL fullselect in db2-fn:sqlquery function.
------------------------------------------------------------------------------
-- The following XQuery expression returns an employee's postal code,department 
-- name and department details, when an employee and a department are in same 
-- location, and the employee belongs to one of the following departments:
-- DB2, Informix or CM.
XQUERY declare default element namespace "http://posample.org";
for $pcode in db2-fn:xmlcolumn("EMPLOYEES.ADDR")/employeeinfo/addr/pcode-zip,
      $dept in ('DB2', 'Informix', 'CM')
  for $deptinfo in db2-fn:sqlquery(
    "SELECT dept_details FROM dept_location
     WHERE zip_code = parameter(1) and dept_name = parameter(2)", $pcode, $dept)
order by $pcode   
return <out>
            {$pcode} 
            <dept_name>{$dept}</dept_name>
            {$deptinfo} 
       </out>@

-- The following XQuery expression uses the purchaseorder table from the sample
-- database. 
-- The XQuery expression returns all purchase orders made by 
-- customers after the date "2005-11-18".
XQUERY for $ponum in db2-fn:xmlcolumn("PURCHASEORDER.PORDER")/PurchaseOrder/@PoNum 
       for $x in db2-fn:sqlquery("SELECT porder FROM purchaseorder 
       WHERE OrderDate > parameter(1) and poid = parameter(2)", '2005-11-18', $ponum) 
order by $ponum
return <out> {$x} </out>@

------------------------------------------------------------------------
-- CLEANUP
------------------------------------------------------------------------

DROP TABLE employees@
DROP TABLE dept_location@
