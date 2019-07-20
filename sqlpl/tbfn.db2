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
-- SOURCE FILE NAME: tbfn.db2
--    
-- SAMPLE: Create the tables and table functions used in tbfnuse sample
--         After the tbfnuse script is run, all changes are rolled back and
--         the tables and functions created in this file are dropped.
--
-- To create/register the tables and SQL functions defined in this file:
--  1. Connect to the database
--  2. Enter the command "db2 -td@ -vf tbfn.db2"
--
-- To invoke an SQL table function from the command line:   
--  1. Connect to the database (if not already connected)
--  2. Enter the command:
--
--     db2 "SELECT * FROM sal_by_dept(char('111'))"
--    
--     This issues a SELECT statement that references the table function as 
--     a table-reference in the FROM clause.  A result set is returned.
-- 
-- To invoke the SQL table functions defined in this file within a sample:
--  1. Connect to the database (if not already connected)                      
--  2. Enter the command "db2 -td@ -vf tbfnuse.db2"
--
--    This issues a series of SQL statements that invoke table functions
--    that read or modify data in the tables, and that show the state of the
--    tables after the table-function invocations.
--
-----------------------------------------------------------------------------
--
-- For more information on the sample scripts, see the README file.
--
-- For information on creating SQL functions, see the Application
-- Development Guide.
--
-- For information on using SQL statements, see the SQL Reference.
--
-- For the latest information on programming, building, and running DB2 
-- applications, visit the DB2 application development website: 
--     http://www.software.ibm.com/data/db2/udb/ad
-----------------------------------------------------------------------------

DROP FUNCTION updateInv@
DROP FUNCTION sal_by_dept@
DROP FUNCTION update_salary@

DROP TABLE INVENTORY@
DROP TABLE PRICELIST@
DROP TABLE EMPLOYEES@
DROP TABLE AUDIT_TABLE@

echo -- This table contains the inventory for a book store.@
echo@
 
CREATE TABLE INVENTORY(itemID varchar(20),
                       itemName varchar(20), 
                       quantity integer)@
INSERT INTO INVENTORY VALUES('ISBN-0-8021-3424-6', 
                             'Feng Shui at Home',
                             10)@
INSERT INTO INVENTORY VALUES('ISBN-0-8021-4612-1', 
                             'Baseball Heroes', 
                             10)@
INSERT INTO INVENTORY VALUES('ISBN-0-8021-5551-0', 
                             'Shakespeare in Love', 
                             10)@

echo -- This table contains the inventory pricelist for a book store.@
echo@
 
CREATE TABLE PRICELIST(itemID varchar(20), unitprice decimal(4,2))@
INSERT INTO PRICELIST VALUES('ISBN-0-8021-3424-6', 12.40)@
INSERT INTO PRICELIST VALUES('ISBN-0-8021-4612-1', 16.00)@
INSERT INTO PRICELIST VALUES('ISBN-0-8021-5551-0', 4.99)@

echo -- The table function that follows updates the quantity of@
echo -- a product item in the "INVENTORY" table by a specified amount@
echo -- and returns a result set indicating the new product inventory.@
echo@
echo -- Note that because the table function modifies table data@
echo -- the clause "MODIFIES SQL DATA" is used in the CREATE@
echo -- FUNCTION statement.@
echo@
 
CREATE FUNCTION updateInv(itemNo VARCHAR(20), amount INTEGER)
RETURNS TABLE (productName varchar(20), quantity INTEGER)
LANGUAGE SQL
MODIFIES SQL DATA
BEGIN ATOMIC
  UPDATE Inventory as I
    SET quantity = quantity + amount
      WHERE I.itemID = itemNo;
   RETURN
    SELECT I.itemName, I.quantity
      FROM Inventory as I
        WHERE I.itemID = itemNo;
END@

echo -- This table contains the employees of a company.@
echo@

CREATE TABLE EMPLOYEES(EMPNUM CHAR(4), 
                      FIRSTNAME varchar(128), 
                      LASTNAME varchar(128), 
                      DEPT CHAR(4), SALARY integer)@
                       
INSERT INTO EMPLOYEES VALUES('1124', 'NADIM', 'RATANI', '111', 75000), 
                           ('1136', 'GWYNETH', 'EVANS', '112', 90000)@

echo -- This table contains audit records of transactions performed on@
echo -- table "EMPLOYEES". Each record in this table contains information@
echo -- about a user, what table they accessed, what was the access, and@
echo -- what was the time of that access.  Records are added to this@
echo -- table whenever the table functions "sal_by_dept" and "update_salary"@
echo -- are invoked.@
echo@
  
CREATE TABLE AUDIT_TABLE(USER varchar(10),
                         TABLE varchar(10), 
                         ACTION varchar(50), 
                         TIME TIMESTAMP)@

echo -- This table function returns the salary of an employee in table@
echo -- "EMPLOYEES" and inserts an audit record into "AUDIT_TABLE" containing@
echo -- information about the user that invoked the table function and what@
echo -- table access that user performed. A result set is returned containing@
echo -- the lastname, firstname, and salary of the employee.@
echo@

CREATE FUNCTION sal_by_dept(deptno CHAR(3))
  RETURNS TABLE(lastname VARCHAR(10),
                firstname VARCHAR(10),
                salary INTEGER)
  LANGUAGE SQL
  MODIFIES SQL DATA
  NO EXTERNAL ACTION
  NOT DETERMINISTIC
  BEGIN ATOMIC
    INSERT INTO audit_table(USER, TABLE, ACTION, TIME)
      VALUES(USER,
             'EMPLOYEES',
             'Read employee salaries in department ' || DEPTNO,
             CURRENT_TIMESTAMP);
    RETURN
      SELECT lastname, firstname, salary
        FROM employees as E
          WHERE E.DEPT = DEPTNO;
  END@

echo -- This table function updates the salary of an employee identified by@
echo -- his employee number, by a specified amount. It also inserts an audit@
echo -- record into "AUDIT_TABLE" containing information about the user that@
echo -- invoked the table function and what table access the user performed. A@
echo -- result set is returned containing the lastname, firstname and the@
echo -- new salary of the employee.@
echo@

CREATE FUNCTION update_salary(updEmpNum CHAR(4), amount INTEGER)
RETURNS TABLE(emp_lastname VARCHAR(10),
              emp_firstname VARCHAR(10),
              newSalary INTEGER)
  LANGUAGE SQL
  MODIFIES SQL DATA
  NO EXTERNAL ACTION
  NOT DETERMINISTIC
  BEGIN ATOMIC
    INSERT INTO audit_table(USER, TABLE, ACTION, TIME)
    VALUES(USER,
           'EMPLOYEES',
           'Update of employee salary. ID: '
           || updEmpNum || ', BY: $' || char(amount),
           CURRENT_TIMESTAMP);
    RETURN
      SELECT lastname, firstname, salary
        FROM FINAL TABLE(UPDATE employees
                         SET salary = salary + amount
                         WHERE employees.empnum = updEmpNum);
  END@

