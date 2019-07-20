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
-- SOURCE FILE NAME: tbfnuse.db2
--    
-- SAMPLE: Demonstrate use of table functions created in tbfnuse sample
--         At the end of this script, statements are rolled back and the
--         tables and functions created in tbfn.db2 are dropped.
--
-- To create/register the tables, and invoke the SQL function using this file:
--  1. Connect to the database
--  2. Enter the commands:
--
--     db2 -td@ -vf tbfn.db2
--     db2 -td@ -vf tbfnuse.db2
--
-- Note: creating and registering the tables in tbfn.db2 is a prerequisite 
--       for running this script.
-- ----------------------------------------------------------------------------- --
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

echo -- EXAMPLES OF INVOKING SQL TABLE FUNCTIONS@
echo -- ========================================@
echo@ 
echo -- BASIC INVOCATION OF AN SQL TABLE FUNCTION THAT MODIFIES SQL DATA@
echo -- ------------------------------------------------------@
echo -- The SQL table function "updateInv" can be invoked from within the@
echo -- FROM clause of a SELECT statement. Table function "updateInv"@
echo -- updates the quantity of an item identified by item number@
echo -- 'ISBN-0-8021-3424-6' by an amount of five. The product name and the@
echo -- updated quantity of the item are returned in a result set.@
echo@

echo -- Display the initial contents of table "INVENTORY":@
echo@
SELECT * FROM INVENTORY@

echo -- Invoke the table function from the FROM clause of a SELECT@
echo -- statement:@
echo@
SELECT productName, quantity
  FROM TABLE(updateInv('ISBN-0-8021-3424-6', 5)) AS T@

echo -- Display the updated contents of table "INVENTORY":@
echo@
SELECT * FROM INVENTORY@

echo -- INVOKING AN SQL TABLE FUNCTION THAT MODIFIES SQL DATA WHICH IS@
echo -- CORRELATED TO ANOTHER TABLE-REFERENCE.@
echo -- --------------------------------------------------------------@
echo -- In this example, the quantities of multiple items in the inventory@
echo -- table, "INVENTORY", are updated. The VALUES clause is used to@
echo -- generate table "newItem" which contains rows of items to be updated.@
echo -- The table function "updateInv" is correlated to table reference@
echo -- "newItem", because at least one column in "newItem" appears as an@
echo -- argument to the table function "updateInv".@
echo@
echo -- Note: It is required that a table function that MODIFIES SQL DATA@
echo -- (only) be the last table reference in the FROM clause of an@
echo -- outermost SELECT.@
echo@

echo -- Invoke the correlated table function from the FROM clause of a@
echo -- SELECT statement:@
echo@
SELECT newItem.id, TF.productName, TF.Quantity
  FROM (VALUES ('ISBN-0-8021-3424-6', 5),
               ('ISBN-0-8021-4612-1', 10)) AS newItem(id, quantity),
        TABLE(updateInv(newItem.id, newItem.quantity)) AS TF@

echo -- Display the updated contents of table INVENTORY:@
echo@
SELECT * FROM INVENTORY@

echo -- INVOKING AN SQL TABLE FUNCTION THAT MODIFIES SQL DATA WHICH IS@
echo -- CORRELATED TO ANOTHER TABLE-REFERENCE AND IN A@
echo -- COMMON-TABLE-EXPRESSION@
echo -- -----------------------------------------------------------------------@
echo -- This example extends the previous example by returning the unit price@
echo -- and total inventory value of the updated stock items. The total@
echo -- inventory value is calculated by multiplying the new quantities of@
echo -- these items by the price from a price list table, "PRICELIST".@
echo@
echo -- Note: A common table expression is identified by the use of the@
echo --       WITH clause which instantiates a temporary table newInv that@
echo --       can be queried in the SELECT portion of an SQL statement.@
echo@

echo -- Invoke the correlated table function from within a@
echo -- common-table-expression@
echo@
WITH newInv(itemNo, quantity) AS
  (SELECT id, TF.quantity
    FROM (VALUES ('ISBN-0-8021-3424-6', 5),
                 ('ISBN-0-8021-4612-1', 10)) AS newItem(id, q),
          TABLE(updateInv(newItem.id, newItem.q)) AS TF)
SELECT itemNo, quantity, unitPrice, (quantity * unitPrice) as TotalInvValue
  FROM newInv, priceList
    WHERE itemNo = priceList.itemID@

echo -- Display the updated contents of table INVENTORY:@
echo@
SELECT * FROM INVENTORY@

echo -- AUDITING READ ACCESSES OF A TABLE USING AN SQL@ 
echo -- TABLE FUNCTION THAT MODIFIES SQL DATA@
echo -- ----------------------------------------------@
echo -- The table function "sal_by_dept" is referenced as a table-reference@
echo -- in the FROM clause of a SELECT statement.  Upon execution of the@
echo -- statement, the table function is invoked.   The table function@
echo -- "sal_by_dept" reads data from a table EMPLOYEES and returns@
echo -- salary information for employees of a specified department@
echo -- in a result set.  It also inserts a record into an audit table,@
echo -- "AUDIT_TABLE recording details of the read access on table@
echo -- "EMPLOYEES".@
echo@

echo -- Display initial contents of table "AUDIT_TABLE":@
echo@

SELECT * FROM AUDIT_TABLE@

echo -- The following SELECT statement shows how a user might@
echo -- invoke the routine to read the salaries of employees in@
echo -- department '111'. A result set is returned with the last name,@
echo -- first name, and salary for the employee.@
echo@ 
SELECT * from table(sal_by_dept(char('111'))) as T@

echo -- The invoker of the "sal_by_dept" table function need not know@
echo -- that an audit record was also inserted into an audit table.@
echo@

SELECT * FROM AUDIT_TABLE@

echo -- AUDITING UPDATES TO A TABLE USING AN SQL A TABLE FUNCTION THAT@
echo -- MODIFIES SQL DATA@
echo -- -----------------------------------------------------------------@
echo -- The table function "update_salary" is referenced as a table-reference@
echo -- in the FROM clause of a SELECT statement.  Upon execution of the@
echo -- statement, the table function is invoked.  The table function updates@
echo -- the salary of a specified employee and inserts a record into an@
echo -- AUDIT TABLE recording details of the read access on table@
echo -- "EMPLOYEES".@
echo@
echo -- The following SELECT statement shows how a user might invoke the@
echo -- routine to update the salary of an employee with employee ID '1136,@
echo -- by an amount of $500:@
echo@

SELECT emp_lastname, emp_firstname, newsalary
  FROM TABLE(update_salary(CHAR('1136'), 500)) AS T@
  
echo -- The invoker of the "update_salary" table function need not know@
echo -- that an audit record was also inserted into an audit table.@
echo@

SELECT * FROM AUDIT_TABLE@

echo -- Rolling back changes and dropping the@
echo -- tables and functions created by this sample.@
echo@

echo@
-- If you don't want the changes made by this sample to be rolled back,
-- comment out all lines below this line.

ROLLBACK@

DROP FUNCTION updateInv@
DROP FUNCTION sal_by_dept@
DROP FUNCTION update_salary@

DROP TABLE INVENTORY@
DROP TABLE PRICELIST@
DROP TABLE EMPLOYEES@
DROP TABLE AUDIT_TABLE@

