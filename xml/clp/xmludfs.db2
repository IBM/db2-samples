-----------------------------------------------------------------------------
-- (c) Copyright IBM Corp. 2008 All rights reserved.
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
-- SAMPLE FILE NAME: xmludfs.db2
--
-- PURPOSE: The purpose of this sample is to show extended support of XML for 
--	    sourced UDF and SQL bodied UDF.
--
-- USAGE SCENARIO: The scenario is for a Book Store that has two types of 
--      customers, retail customers and corporate customers. Corporate 
--      customers do bulk purchases of books for their company libraries. 
--      The Book Store also maintains list of ‘registered customers’ 
--      who are frequent buyers from the store and have registered 
--      themselves with the store. The store has a DBA, sales clerk and a 
--      manager for maintaining the database and to run queries on different 
--      tables to view the book sales.
--
--      The store manager frequently queries various tables to get 
--      information such as contact numbers of different departments,
--      location details, location manager details, employee details 
--      in order to perform various business functions like promoting 
--      employees, analysing sales, giving awards and bonus to employees 
--      based on their sales.
--
--      The manager is frustrated writing the same queries every time to 
--      get the information and observes performance degradation as well.  
--      So he decides to create a user-defined function and a stored  
--      procedure for each of his requirements. 
--
-- PREREQUISITES: None
--
-- EXECUTION: db2 -td@ -vf xmludfs.db2
--
-- INPUTS: NONE
--
-- OUTPUTS: Successfully execution of all UDFs and stored procedures.
--
-- OUTPUT FILE: xmludfs.out (available in the online documentation)
--
-- SQL STATEMENTS USED:
--           CREATE TABLE
--           INSERT
--	       UPDATE
--           DELETE
--           DROP
--
-- SQL/XML FUNCTIONS USED:
--           XMLPARSE
-- 	       XMLTABLE
--           XMLQUERY
--           XMLEXISTS
--
-----------------------------------------------------------------------------
-- For more information about the command line processor (CLP) scripts,
-- see the README file.
--
-- For information on using SQL statements, see the SQL Reference.
--
-----------------------------------------------------------------------------
-- SAMPLE DESCRIPTION
--
-----------------------------------------------------------------------------
-- 1. UDF Scalar function which takes an XML variable as input parameter
--    and returns XML value as output.
--
-- 2. UDF Table function which takes an XML variable as input parameter
--    and returns a table with XML values as output.
--
-- 3. Sourced UDF which takes an XML variable as the input parameter   
--    and returns XML value as output.
--
-- 4. SQL bodied UDF which takes an XML variable as the input parameter
--    and returns a table with XML values as output. This UDF 
--    internally calls a stored procedure which takes an XML variable
--    as the input parameter and returns an XML value as output.
--   
-----------------------------------------------------------------------------
-- SETUP
-----------------------------------------------------------------------------
-- Connect to sample database
CONNECT TO sample@

-----------------------------------------------------------------------------
-- Setting up tables for the sample
-----------------------------------------------------------------------------

-- Create table 'sales_department'
CREATE TABLE sales_department(dept_id CHAR(10), dept_info XML)@

-- Create table 'sales_employee'
CREATE TABLE sales_employee (emp_id INTEGER, total_sales INTEGER, emp_details XML)@

-- Create table 'performance_bonus_employees'
CREATE TABLE performance_bonus_employees(bonus_info XML)@

-- Insert values into 'sales_employee' table
INSERT INTO sales_employee VALUES (5001, 40000, XMLPARSE(document 
'<employee id="5001">
  <name>Lethar Kessy</name>
  <address>
    <street>555 M G Road</street>
    <city>Bangalore</city>
    <state>Karnataka</state>
    <country>India</country>
    <zipcode>411004</zipcode>
  </address>
  <birthdate>27-01-1954 </birthdate>
  <gender>Male</gender>
  <phone>
    <cell>9435344354</cell>
  </phone>
  <email>lethar@company.com</email>
  <dept>DS02</dept>
  <skill_level>7</skill_level>
  <sales>40000</sales>
  <salary currency="INR">25500</salary>
  <designation>Sr. Manager</designation>
  <employee_type>regular</employee_type>
  <manager>Harry</manager>
</employee> '))@

INSERT INTO sales_employee VALUES (5002, 50000, XMLPARSE(document 
'<employee id="5002">
  <name>Mathias Jessy</name>
  <address><street>Indra Nagar Road No. 5</street>
    <city>Bangalore</city>
    <state>Karnataka</state>
    <country>India</country>
    <zipcode>411004</zipcode>
  </address>
  <birthdate>17-01-1974 </birthdate>
  <gender>Female</gender>
  <phone>
    <cell>9438884354</cell>
  </phone>
  <email>jessy@company.com</email>
  <dept>DS02</dept>
  <skill_level>6</skill_level>
  <sales>50000</sales>
  <salary currency="INR">22500</salary>
  <designation>Manager</designation>
  <employee_type>regular</employee_type>
  <manager>Harry</manager>
</employee> '))@

INSERT INTO sales_employee VALUES (5003, 40000, XMLPARSE(document 
'<employee id="5003">
  <name>Mohan Kumar</name>
  <address>
    <street>Vijay Nagar Road No. 5</street>
    <city>Bangalore</city>
    <state>Karnataka</state>
    <country>India</country>
    <zipcode>411004</zipcode>
  </address>
  <birthdate>21-11-1974 </birthdate>
  <gender>Male</gender>
  <phone>
    <cell>9438881234</cell>
  </phone>
  <email>Mohan@company.com</email>
  <dept>DS02</dept>
  <skill_level>5</skill_level>
  <sales>40000</sales>
  <salary currency="INR">15500</salary>
  <designation>Associate Manager</designation>
  <employee_type>regular</employee_type>
  <manager>Harry</manager>
</employee> '))@

-- Insert values into 'sales_department' table
INSERT INTO sales_department VALUES ('DS02', XMLPARSE(document 
'<department id="DS02">
  <name>sales</name>
  <manager id="M2001">
    <name>Harry Thomas</name>
    <phone>
      <cell>9732432423</cell>
    </phone>
  </manager>
  <address>
    <street>Bannerghatta</street>
    <city>Bangalore</city>
    <state>Karnataka</state>
    <country>India</country>
    <zipcode>560012</zipcode>
  </address>
  <phone>
    <office>080-23464879</office>
    <office>080-56890728</office>
    <fax>080-45282976</fax>
  </phone>
</department>'))@

-----------------------------------------------------------------------------
-- 1. UDF Scalar function which takes an XML variable as input parameter
--    and returns an XML value as output.
----------------------------------------------------------------------------

-- Create a scalar function 'getDeptContactNumbers' which returns a list 
-- of department phone numbers
CREATE FUNCTION getDeptContactNumbers(dept_info_p XML)
RETURNS XML
LANGUAGE SQL
SPECIFIC contactNumbers
NO EXTERNAL ACTION
BEGIN ATOMIC

  -- Return a list of department phone numbers
  RETURN XMLQuery('document {<phone_list>{$dep/department/phone}</phone_list>}' 
  PASSING dept_info_p as "dep");

END@

-- Call scalar UDF 'getDeptContactNumbers' to get contact numbers of 
-- the department "DS02"
SELECT getDeptContactNumbers(sales_department.dept_info) 
FROM sales_department
WHERE dept_id = 'DS02'@

----------------------------------------------------------------------------
-- 2. UDF Table function which takes an XML variable as input parameter
--    and returns a table with XML values as output.
----------------------------------------------------------------------------

-- The store opens new branches in different parts of the city. 
-- The book store manager wants to promote senior managers and associate 
-- managers and designate them to manage these new branches. He wants to 
-- update the skill level and salaries of all the promoted managers in the
-- sales_employee table. He asks the DBA to create a table function for 
-- this requirement. The DBA creates the 'updatePromotedEmployeesInfo' 
-- table function. This function updates the skill level and salaries of
-- the promoted managers in sales_employee table and returns details of 
-- all the managers who got promoted.

CREATE FUNCTION updatePromotedEmployeesInfo(emp_id_p INTEGER)
RETURNS TABLE (name VARCHAR(50), emp_id integer, skill_level integer, 
               salary double, address XML)
LANGUAGE SQL
MODIFIES SQL DATA
SPECIFIC func1
BEGIN ATOMIC

    -- Update the skill_level and salary for the Sr. manager promoted to 
    -- Area sales manager.

    UPDATE sales_employee SET emp_details = XMLQuery('transform 
          copy $emp_info := $emp
          modify if ($emp_info/employee[skill_level = 7 and 
	                                designation = "Sr. Manager"]) 
                 then
		 (
		    do replace value of $emp_info/employee/skill_level with 8,
		    do replace value of $emp_info/employee/salary with
		                     $emp_info/employee/salary * 9.5 
                 )	        
                 else if ($emp_info/employee[skill_level = 6  and 
		                             designation = "Manager"]) 
                 then
                 (
		    do replace value of $emp_info/employee/skill_level with 7, 
		    do replace value of $emp_info/employee/salary with
		        $emp_info/employee/salary * 7.5 
                 ) 
		else if ($emp_info/employee[skill_level = 5  and 
		                            designation = "Associate Manager"])
                then 
                ( 
	            do replace value of $emp_info/employee/skill_level with 6, 
	            do replace value of $emp_info/employee/salary with 
		           $emp_info/employee/salary * 5.5 
                ) 
		else ()           
	 return $emp_info' PASSING emp_details as "emp")             
    WHERE emp_id = emp_id_p;

  -- To return the updated details of promoted employees, create a 
  -- relational view of employee_details XML document using XMLTABLE 
  -- function.
  RETURN SELECT X.* 
        FROM sales_employee, XMLTABLE('$e_info/employee' PASSING 
                                       emp_details as "e_info"
        COLUMNS
        name VARCHAR(50) PATH 'name',
        emp_id integer PATH '@id',
        skill_level integer path 'skill_level',
        salary double path 'salary',
        addr XML path 'address') AS X WHERE sales_employee.emp_id = emp_id_p;

END@

-- Call the 'updatePromotedEmployeesInfo' table function to update the details  
-- of promoted employees in 'sales_employee' table
SELECT A.* 
  FROM sales_employee AS E, table(updatePromotedEmployeesInfo(E.emp_id)) AS A@


----------------------------------------------------------------------------
-- 3. Sourced UDF which takes an XML variable as the input parameter
--    and returns an XML value as output.
----------------------------------------------------------------------------
-- The store manager would like to get a particular dept manager name and 
-- his contact numbers. The DBA then creates a 'getManagerDetails' UDF to get 
-- a particular department manager name and manager contact details. 

CREATE FUNCTION getManagerDetails(dept_info_p XML, dept_p VARCHAR(5))
RETURNS XML
LANGUAGE SQL
SPECIFIC getManagerDetails
BEGIN ATOMIC
DECLARE tmp XML;

  -- Return manager name and manager contact details of 'dept_p'
  -- department
  RETURN XMLQuery('$info/department[name=$dept_name]/manager'
             PASSING dept_info_p as "info", dept_p as "dept_name");

END@

-- Create a sourced UDF 'getManagerInfo' based on 'getManagerDetails'
-- user defined function
CREATE FUNCTION getManagerInfo(XML, CHAR(10))
RETURNS XML
SOURCE getManagerDetails(XML, VARCHAR(5))@

-- Call the sourced UDF 'getManagerInfo' to get 'sales' department 
-- manager details
SELECT getManagerInfo(sales_department.dept_info, 'sales') 
FROM sales_department 
WHERE dept_id='DS02'@


-------------------------------------------------------------------------
-- 4. SQL bodied UDF which takes an XML variable as the input parameter
--    and returns a table with XML values as output. This UDF
--    calls a stored procedure which takes an XML variable
--    as the input parameter and returns an XML value as output.
--------------------------------------------------------------------------

-- Create a function which calculates an employee gift cheque amount and 
-- adds this value as a new element into the employee information document

CREATE PROCEDURE calculateGiftChequeAmount(INOUT emp_info_p XML, 
IN emp_name_p VARCHAR(20))
LANGUAGE SQL
MODIFIES SQL DATA
SPECIFIC customer_award
BEGIN
DECLARE emp_bonus_info_v XML;

  IF XMLEXISTS('$e_info/employee[name = $emp1]' PASSING emp_info_p as "e_info",
     emp_name_p as "emp1")
  THEN

    -- Calculate employee gift cheque amount and add a new element
    -- 'customer_gift_cheque' to employee info document
    SET emp_bonus_info_v = XMLQuery('copy $bonus := $info 
       modify 
         do insert <customer_gift_cheque>{$bonus/employee/salary * 0.50 + 25000}
         </customer_gift_cheque> into $bonus/employee  
       return $bonus' PASSING emp_info_p as "info");
  END IF;

  -- Set output parameter value 'emp_info_p' with newly calculated
  -- bonus information
  SET emp_info_p = emp_bonus_info_v;

END@


-- Some employees who got customer appreciation awards and whose 
-- total sales are greater than expected sales were given gift 
-- cheques by the store. The DBA creates 'calculatePerformanceBonus' 
-- function to calculate employee performance bonus along with 
-- customer gift cheque amount and update the employee information 
-- in sales_employee table.

CREATE FUNCTION calculatePerformanceBonus(sales_info_p XML)
RETURNS table(info XML)
LANGUAGE SQL
SPECIFIC awardedemployees
MODIFIES SQL DATA
BEGIN ATOMIC
DECLARE awarded_emp_info_v  XML;
DECLARE emp_name VARCHAR(20);
DECLARE min_sales_v INTEGER;
DECLARE avg_sales_v INTEGER;

  -- Extract minimum and average sales from input XML document
  SET min_sales_v = XMLCAST(XMLQuery('$info/sales_per_annum/min_sales' 
               PASSING sales_info_p as "info")  AS INTEGER);

  SET avg_sales_v = XMLCAST(XMLQuery('$info/sales_per_annum/avg_sales'
               PASSING sales_info_p as "info")  AS INTEGER);

  -- Loop through the employee records and select all the employees
  -- whose total sales value is between target_sales and min_sales.
  FOR_LOOP: FOR EACH_ROW AS 
     SELECT XMLCAST(XMLQuery('$info/employee/name' PASSING awarded_emp_info_v 
               as "info") AS VARCHAR(20)) as name, 
	    XMLQuery('copy $e_info := $inf
	              modify 
                      do insert <performance_bonus>{$e_info/employee/salary 
		                    * 0.25 + 5000}
	                        </performance_bonus> into $e_info/employee
                      return $e_info' PASSING emp_details as "inf")
		      as info
     FROM sales_employee 
     WHERE  total_sales between min_sales_v and avg_sales_v
  DO

    -- For the selected employee, calculate performance bonus and add a new
    -- element 'performance_bonus' to employee info document
    SET awarded_emp_info_v = EACH_ROW.info;

    -- Get the employee name 
    SET emp_name = EACH_ROW.name; 
                  
    -- Call the stored procedure 'calculateGiftChequeAmount' to calculate 
    -- gift cheque amount for the above selected employee
    CALL calculateGiftChequeAmount(awarded_emp_info_v, emp_name);

    -- Insert records of employees who got performance bonus and 
    -- gift cheques into 'performance_bonus_employees' table
    INSERT INTO performance_bonus_employees 
       VALUES (EACH_ROW.info);

  END FOR;

  -- Return updated employees information 
  RETURN SELECT * FROM performance_bonus_employees;

END@

-- Call the table function 'calculatePerformanceBonus' to get the
-- information of all the employees who got gift cheques
-- and performance bonus.
SELECT * FROM table(calculatePerformanceBonus(XMLPARSE(document 
'<sales_per_annum>
  <target_sales>80000</target_sales>
    <avg_sales>70000</avg_sales>
    <min_sales>35000</min_sales>
</sales_per_annum>')))@

-------------------------------------------------------------------------
-- CLEANUP
-------------------------------------------------------------------------
DROP FUNCTION getDeptContactNumbers@
DROP FUNCTION updatePromotedEmployeesInfo@
DROP FUNCTION getManagerInfo@
DROP FUNCTION calculatePerformanceBonus@
DROP PROCEDURE calculateGiftChequeAmount@
DROP TABLE sales_employee@
DROP TABLE sales_department@
DROP TABLE performance_bonus_employees@
DROP FUNCTION getManagerDetails@

