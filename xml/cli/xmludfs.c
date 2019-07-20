/***************************************************************************
** (c) Copyright IBM Corp. 2008 All rights reserved.
** 
** The following sample of source code ("Sample") is owned by International 
** Business Machines Corporation or one of its subsidiaries ("IBM") and is 
** copyrighted and licensed, not sold. You may use, copy, modify, and 
** distribute the Sample in any form without payment to IBM, for the purpose of 
** assisting you in the development of your applications.
** 
** The Sample code is provided to you on an "AS IS" basis, without warranty of 
** any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
** IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
** not allow for the exclusion or limitation of implied warranties, so the above 
** limitations or exclusions may not apply to you. IBM shall not be liable for 
** any damages you suffer as a result of using, copying, modifying or 
** distributing the Sample, even if IBM has been advised of the possibility of 
** such damages.
*****************************************************************************
**
** SAMPLE FILE NAME: xmludfs.c
**
** PURPOSE: The purpose of this sample is to show extended support of XML for 
**	    sourced UDF and SQL bodied UDF in serial and DPF environment 
** 	    for DB2 Cobra. 
**
** USAGE SCENARIO: The scenario is for a Book Store that has two types of 
**     customers, retail customers and corporate customers. Corporate 
**      customers do bulk purchases of books for their company libraries. 
**      The Book Store also maintains list of ‘registered customers’ 
**      who are frequent buyers from the store and have registered 
**      themselves with the store. The store has a DBA, sales clerk and a 
**      manager for maintaining the database and to run queries on different 
**      tables to view the book sales.
**
**      The store manager frequently queries various tables to get 
**      information such as contact numbers of different departments,
**      location details, location manager details, employee details 
**      in order to perform various business functions like promoting 
**      employees, analysing sales, giving awards and bonus to employees 
**      based on their sales.
**
**      The manager is frustrated writing the same queries every time to 
**      get the information and observes performance degradation as well.  
**      So he decides to create a user-defined function and a stored  
**      procedure for each of his requirements. 

**
** PREREQUISITE: NONE
**
** EXECUTION: bldapp xmludfs
**            xmludfs
**
** INPUTS: NONE
**
** OUTPUTS: Successfull execution of all UDFs and stored procedures.
**
** OUTPUT FILE: xmludfs.out (available in the online documentation)
**
** SQL STATEMENTS USED:
**           CREATE TABLE
**           INSERT
**           DROP
**
** SQL/XML FUNCTIONS USED:
**          XMLPARSE
**          XMLQUERY
**          XMLEXISTS
**
*****************************************************************************
**
** For more information about the command line processor (CLP) scripts,
** see the README file.
**
** For information on using SQL statements, see the SQL Reference.
**
*****************************************************************************
**
**  SAMPLE DESCRIPTION
**
*****************************************************************************
** 1. UDF Scalar function which takes an XML variable as input the parameter
**    and returns XML value as output.
**
** 2. UDF Table function which takes an XML variable as input the parameter
**    and returns table with XML values as output.
**
** 3. Sourced UDF which takes an XML variable as the input parameter   
**    and returns XML value as output.
**
** 4. SQL bodied UDF which takes an XML variable as the input parameter
**    and returns a table with XML values as output. This UDF 
**    internally calls a stored procedure which takes an XML variable
**    as the input parameter and returns an XML value as output.
************************************************************************
**
**  INCLUDE ALL HEADER FILES
**
****************************************************************************/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>
#include "utilcli.h" /* Header file for CLI sample code */

int main(int argc, char *argv[])
{
  SQLRETURN cliRC = SQL_SUCCESS;
  int rc = 0;

  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handles */

  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }

  printf("\n This sample shows how to pass XML type variables");
  printf(" as input parameters, return type or local ");
  printf(" variables in SQL bodied UDFs\n\n");

  /* initialize the application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_ON);
  if (rc != 0)
  {
    return rc;
  }

  rc = SetUpTables(hdbc);
  rc = ScalarUDF(hdbc);
  rc = TableUDF(hdbc);
  rc = SourcedUDF(hdbc);
  rc = InvokeSpFromUDF(hdbc);
  rc = CleanUpTables(hdbc);
 
    
  /* terminate the application by calling a helper
    utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);

  return rc;
}

int SetUpTables(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLCHAR *stmt = 0;
  
   printf("---------------------------------\n");
   printf("Setting up tables for the sample\n");
   printf("---------------------------------\n");

   printf("\n-----------------------------------------------------------");
   printf("\nUSE THE CLI FUNCTIONS\n");
   printf("  SQLSetConnectAttr\n");
   printf("  SQLAllocHandle\n");
   printf("  SQLExecDirect\n");
   printf("  SQLEndTran\n");
   printf("  SQLFreeHandle\n");
   printf("TO USE XML TYPE IN UDFs :\n");

   /* set AUTOCOMMIT OFF */
   cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
   DBC_HANDLE_CHECK(hdbc, cliRC);


   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);
 
   stmt = (SQLCHAR *)"CREATE TABLE sales_department(dept_id CHAR(10), "
                    " dept_info XML)";
   printf("\n%s\n\n", stmt);
  
   /* execute create table statement directly */
   printf("create the table called dept\n");
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   stmt = (SQLCHAR *)"CREATE TABLE sales_employee (emp_id INTEGER, "
          "total_sales INTEGER, emp_details XML)";
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   printf("\n%s\n\n", stmt);

   stmt = (SQLCHAR *)"CREATE TABLE performance_bonus_employees(bonus_info XML)";
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   printf("\n%s\n\n", stmt);
   
   stmt = (SQLCHAR *)"INSERT INTO sales_employee VALUES (5001, 40000, XMLPARSE(document "
			  "'<employee id=\"5001\">"
			  "<name>Lethar Kessy</name>"
			  "<address>"
			    "<street>555 M G Road</street>"
			    "<city>Bangalore</city>"
			    "<state>Karnataka</state>"
			    "<country>India</country>"
			    "<zipcode>411004</zipcode>"
			  "</address>"
			  "<phone>"
			    "<cell>9435344354</cell>"
			  "</phone>"
			  "<dept>DS02</dept>"
			  "<skill_level>7</skill_level>"
			  "<sales>40000</sales>"
			  "<salary currency=\"INR\">25500</salary>"
			  "<designation>Sr. Manager</designation>"
			  "<employee_type>regular</employee_type>"
			  "<manager>Harry</manager> "
			  "</employee> '))";
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   stmt = (SQLCHAR *) "INSERT INTO sales_employee VALUES (5002, 50000, XMLPARSE(document "
	"'<employee id=\"5002\">"
	  "<name>Mathias Jessy</name>"
	  "<address>"
		"<street>Indra Nagar Road No. 5</street>"
		"<city>Bangalore</city>"
	      "<state>Karnataka</state>"
            "<country>India</country>"
            "<zipcode>411004</zipcode>"
	  "</address>"
	  "<phone>"
	    "<cell>9438884354</cell>"
	  "</phone>"
	  "<dept>DS02</dept>"
	  "<skill_level>6</skill_level>"
	  "<sales>50000</sales>"
	  "<salary currency=\"INR\">22500</salary>"
	  "<designation>Manager</designation>"
	  "<employee_type>regular</employee_type>"
	  "<manager>Harry</manager>"
	  "</employee> '))";

   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   stmt = (SQLCHAR *)"INSERT INTO sales_employee VALUES (5003, 40000, XMLPARSE(document "
		"'<employee id=\"5003\">"
  		"<name>Mohan Kumar</name>"
		"  <address>"
		    "<street>Vijay Nagar Road No. 5</street>"
    		    "<city>Bangalore</city>"
                "<state>Karnataka</state>"
                "<country>India</country>"
                "<zipcode>411004</zipcode>"
  	      "</address>"
		"<phone>"
    			"<cell>9438881234</cell>"
  		"</phone>"
  		"<dept>DS02</dept>"
  		"<skill_level>5</skill_level>"
  		"<sales>40000</sales>"
  		"<salary currency=\"INR\">15500</salary>"
  		"<designation>Associate Manager</designation>"
  		"<employee_type>regular</employee_type>"
  		"<manager>Harry</manager>"
		"</employee> '))";

   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
 
   stmt = (SQLCHAR *) "INSERT INTO sales_department VALUES ('DS02', XMLPARSE(document "
			"'<department id=\"DS02\">"
			  "<name>sales</name>"
  			  "<manager id=\"M2001\">"
    			  "<name>Harry Thomas</name>"
    			  "<phone>"
      			"<cell>9732432423</cell>"
    			  "</phone>"
  			  "</manager>"
  			  "<address>"
    			  "<street>Bannerghatta</street>"
    			  "<city>Bangalore</city>"
    			  "<state>Karnataka</state>"
    			  "<country>India</country>"
    			  "<zipcode>560012</zipcode>"
  			  "</address>"
  			  "<phone>"
    			  "<office>080-23464879</office>"
    			  "<office>080-56890728</office>"
    			  "<fax>080-45282976</fax>"
  			  "</phone>"
			  "</department>'))";

   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   stmt = (SQLCHAR *) "COMMIT";
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   printf("\n  Rolling back the transaction...\n");

   cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   printf("  Transaction rolled back.\n");

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   return rc;
 
}

/*-----------------------------------------------------------------------
-- 1. UDF Scalar function which takes an XML variable as input parameter
--    and returns an XML value as output.
-------------------------------------------------------------------------*/

int ScalarUDF(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLCHAR *stmt = 0;
   struct 
   {
     SQLINTEGER ind;
     SQLVARCHAR data[1000];
   }xmldata;

   printf("---------------------------------\n");
   printf("Create a scalar function 'getDeptContactNumbers' which ");
   printf("returns a list of department phone numbers\n");
   printf("---------------------------------\n");

   stmt = "CREATE FUNCTION getDeptContactNumbers(dept_info_p XML) "
              "RETURNS XML "
              "LANGUAGE SQL "
              "SPECIFIC contactNumbers "
              "NO EXTERNAL ACTION "
              "BEGIN ATOMIC "
  	        "RETURN XMLQuery('document {<phone_list>{"
              "$dep/department/phone}</phone_list>}'  "
              "PASSING dept_info_p as \"dep\"); "
		  "END";
   printf("\n%s\n\n", stmt);

     /* set AUTOCOMMIT OFF */
   cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
   DBC_HANDLE_CHECK(hdbc, cliRC);


   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);
 
   /* execute create table statement directly */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   printf("--------------------------------------------------\n");
   printf("Call scalar UDF 'getDeptContactNumbers' to get contact");
   printf(" numbers of the department \"DS02\"\n\n");
   printf("--------------------------------------------------\n");

   stmt = (SQLCHAR *) "SELECT getDeptContactNumbers(sales_department.dept_info) "
          "FROM sales_department WHERE dept_id = 'DS02'";
   printf("\n%s\n\n", stmt);
   
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column POID to variable PID*/
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata.data, 3000, &xmldata.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch result returned from Select statement*/
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    if(xmldata.ind > 0)
    {
      printf("\n%s\n\n", xmldata.data);
    }
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
    printf("\n  Rolling back the transaction...\n");

   /* end the transactions on the connection */
   cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   printf("  Transaction rolled back.\n");

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   return rc;
 
}

/*------------------------------------------------------------------------
-- 2. UDF Table function which takes an XML variable as input parameter
--    and returns a table with XML values as output.
--------------------------------------------------------------------------*/

int TableUDF(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLCHAR *stmt = 0;
   SQLINTEGER emp_id;
   SQLINTEGER skill_level;
   SQLINTEGER salary;
   SQLVARCHAR name[50];
   struct 
   {
     SQLINTEGER ind;
     SQLVARCHAR data[1000];
   }xmldata;

   printf("---------------------------------\n");
   printf("The store opens new branches in different parts of the city. ");
   printf("The book store manager wants to promote senior managers and associate ");
   printf("managers and designate them to manage these new branches. He wants to ");
   printf("update the skill level and salaries of all the promoted managers in the");
   printf("sales_employee table. He asks the DBA to create a table function for ");
   printf("this requirement. The DBA creates the 'updatePromotedEmployeesInfo' ");
   printf("table function. This function updates the skill level and salaries of");
   printf("the promoted managers in sales_employee table and returns details of ");
   printf("all the managers who got promoted. \n");
   printf("---------------------------------\n");

   stmt = "CREATE FUNCTION updatePromotedEmployeesInfo(emp_id_p INTEGER) "
          "RETURNS TABLE (name VARCHAR(50), emp_id integer, skill_level integer, "
	  "               salary double, address XML) "
	  "LANGUAGE SQL "
	  "MODIFIES SQL DATA "
	  "SPECIFIC func1 "
	  "BEGIN ATOMIC "
	  "UPDATE sales_employee SET emp_details = XMLQuery('transform "
	  "       copy $emp_info := $emp "
          "       modify if ($emp_info/employee[skill_level = 7 and "
	  "               designation = \"Sr. Manager\"]) "
	  "then "
	  "( "
	  " do replace value of $emp_info/employee/skill_level with 8, "
	  " do replace value of $emp_info/employee/salary with "
	  "        $emp_info/employee/salary * 9.5 "
	  ") "
	  "else if ($emp_info/employee[skill_level = 6  and  "
	  "        designation = \"Manager\"]) "
	  "then "
	  "( "
	  "do replace value of $emp_info/employee/skill_level with 7, "
	  "do replace value of $emp_info/employee/salary with "
	  "        $emp_info/employee/salary * 7.5 "
	  ") "
	  "else if ($emp_info/employee[skill_level = 5  and "
	  "designation = \"Associate Manager\"]) "
	  "then "
	  "( "
	  "do replace value of $emp_info/employee/skill_level with 6, "
	  "do replace value of $emp_info/employee/salary with "
	  "$emp_info/employee/salary * 5.5 "
	  ") "
	  "else () "
	  "return $emp_info' PASSING emp_details as \"emp\")"
	  "WHERE emp_id = emp_id_p;"
	  "RETURN SELECT X.* "
	  "FROM sales_employee, XMLTABLE('$e_info/employee' PASSING "
	  "emp_details as \"e_info\" "
	  " COLUMNS "
	  "name VARCHAR(50) PATH 'name', "
	  "emp_id integer PATH '@id', "
	  "skill_level integer path 'skill_level', "
	  "salary double path 'salary', "
	  "addr XML path 'address') AS X WHERE sales_employee.emp_id = emp_id_p; "
          "END";

	  
   printf("%s\n\n", stmt);

     /* set AUTOCOMMIT OFF */
   cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);
 
   /* execute create table statement directly */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   printf("---------------------------------------------------------\n");
   printf("Call the 'updatePromotedEmployeesInfo' table function to ");
   printf("update the details of promoted employees in 'sales_employee' table ");
   printf("---------------------------------------------------------\n");


   stmt = "SELECT A.* FROM sales_employee AS E, "
         "table(updatePromotedEmployeesInfo(E.emp_id)) AS A";
  printf("%s\n\n", stmt);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column info to variable xmldata*/
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &name, 50, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column info to variable xmldata*/
  cliRC = SQLBindCol(hstmt, 2, SQL_C_LONG, &emp_id, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column info to variable xmldata*/
  cliRC = SQLBindCol(hstmt, 3, SQL_C_LONG, &skill_level, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column info to variable xmldata*/
  cliRC = SQLBindCol(hstmt, 4, SQL_C_LONG, &salary, 0, NULL);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column info to variable xmldata*/
  cliRC = SQLBindCol(hstmt, 5, SQL_C_CHAR, &xmldata.data, 2000, &xmldata.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  

  /* fetch result returned from Select statement*/
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    printf("\n\n%s   %d  %d  %d", name, emp_id, skill_level, salary);
    if(xmldata.ind > 0)
    {
      printf("\n%s\n\n", xmldata.data);
    }
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
   printf("\n  Rolling back the transaction...\n");

   /* end the transactions on the connection */
   cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   printf("  Transaction rolled back.\n");

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   return rc;
    	
}

/*--------------------------------------------------------------------------
-- 3. Sourced UDF which takes an XML variable as the input parameter
--    and returns an XML value as output.
--------------------------------------------------------------------------*/

int SourcedUDF(SQLHANDLE hdbc)
{
   SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLCHAR *stmt = 0;
   struct 
   {
     SQLINTEGER ind;
     SQLVARCHAR data[1000];
   }xmldata;

   printf("---------------------------------\n");
   printf("The store manager would like to get a particular dept manager ");
   printf("name and his contact numbers. The DBA then creates a ");
   printf("'getManagerDetails' UDF to get a particular department manager ");
   printf("name and manager contact details. ");
   printf("---------------------------------\n");

   stmt = (SQLCHAR *)"CREATE FUNCTION getManagerDetails(dept_info_p XML, dept_p VARCHAR(5)) "
    	 	   "RETURNS XML "
		   "LANGUAGE SQL "
		   "SPECIFIC getManagerDetails "
		   "BEGIN ATOMIC "
		   "RETURN XMLQuery('$info/department[name=$dept_name]/manager' "
		   "PASSING dept_info_p as \"info\", dept_p as \"dept_name\"); "
		   "END";
   printf("%s\n\n", stmt);

     /* set AUTOCOMMIT OFF */
   cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);
 
   /* execute create table statement directly */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   printf("Create a sourced UDF 'getManagerInfo' based on ");
   printf("'getManagerDetails' user defined function \n\n");
 
   stmt = "CREATE FUNCTION getManagerInfo(XML, CHAR(10))"
            "RETURNS XML "
	    "SOURCE getManagerDetails(XML, VARCHAR(5)) ";
   /* execute create table statement directly */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
   printf("%s\n\n", stmt);

   printf("Call the sourced UDF 'getManagerInfo' to get ");
   printf("'sales' department manager details");

   stmt = "SELECT getManagerInfo(sales_department.dept_info, 'sales') "
          " FROM sales_department WHERE dept_id='DS02'";
   printf("%s\n\n", stmt);

   
  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column POID to variable PID*/
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata.data, 3000, &xmldata.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch result returned from Select statement*/
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    if(xmldata.ind > 0)
    {
      printf("\n%s\n\n", xmldata.data);
    }
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
   printf("\n  Rolling back the transaction...\n");

   /* end the transactions on the connection */
   cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   printf("  Transaction rolled back.\n");

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   return rc;
   
}

/*-----------------------------------------------------------------------
-- 4. SQL bodied UDF which takes an XML variable as the input parameter
--    and returns a table with XML values as output. This UDF
--    calls a stored procedure which takes an XML variable
--    as the input parameter and returns an XML value as output.
------------------------------------------------------------------------*/
int InvokeSpFromUDF(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLCHAR *stmt = 0;
   struct 
   {
     SQLINTEGER ind;
     SQLVARCHAR data[1000];
   }xmldata;

   printf("---------------------------------\n");
   printf("Create a function which calculates an employee gift cheque ");
   printf("amount and adds this value as a new element into the ");
   printf("employee information document");
   printf("---------------------------------\n");

   stmt = "CREATE PROCEDURE calculateGiftChequeAmount("
               " INOUT emp_info_p XML, "
               "IN emp_name_p VARCHAR(20)) "
	       "LANGUAGE SQL "
	       "MODIFIES SQL DATA "
	       "SPECIFIC customer_award "
	       "BEGIN  "
	       "DECLARE emp_bonus_info_v XML; "
	       "IF XMLEXISTS('$e_info/employee[name = $emp1]' "
               "PASSING emp_info_p as \"e_info\","
	       "emp_name_p as \"emp1\")"
	       "THEN "
	       "SET emp_bonus_info_v = XMLQuery('copy $bonus := $info "
	       "modify "
	       "do insert <customer_gift_cheque>{"
               " $bonus/employee/salary * 0.50 + 25000} "
	       "</customer_gift_cheque> into $bonus/employee "
	       "return $bonus' PASSING emp_info_p as \"info\"); "
	       "END IF; "
	       "SET emp_info_p = emp_bonus_info_v; "
	       "END ";
   printf("%s\n\n", stmt);
   
     /* set AUTOCOMMIT OFF */
   cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);
 
   /* execute create table statement directly */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   printf("-----------------------------------------------------\n");
   printf("Some employees who got customer appreciation awards ");
   printf("and whose total sales are greater than expected sales ");
   printf("were given gift cheques by the store. The DBA creates ");
   printf("'calculatePerformanceBonus' function to calculate ");
   printf("employee performance bonus along with customer gift ");
   printf("cheque amount and update the employee information ");
   printf("in sales_employee table. ");
   printf("-----------------------------------------------------\n");

   stmt = "CREATE FUNCTION calculatePerformanceBonus(sales_info_p XML) "
	    "RETURNS table(info XML) "
	    "LANGUAGE SQL "
	    "SPECIFIC awardedemployees "
	    "MODIFIES SQL DATA "
   	    "BEGIN ATOMIC "
	    "DECLARE awarded_emp_info_v  XML; "
            "DECLARE emp_name VARCHAR(20); "
	    "DECLARE min_sales_v INTEGER; "
            "DECLARE avg_sales_v INTEGER; "
	    "SET min_sales_v = XMLCAST(XMLQuery('$info/sales_per_annum/min_sales' "
            "PASSING sales_info_p as \"info\")  AS INTEGER); "
	    "SET avg_sales_v = XMLCAST(XMLQuery('$info/sales_per_annum/avg_sales' "
            "PASSING sales_info_p as \"info\")  AS INTEGER); "
	    "FOR_LOOP: FOR EACH_ROW AS "
            "SELECT XMLCAST(XMLQuery('$info/employee/name' PASSING awarded_emp_info_v "    
	    "as \"info\") AS VARCHAR(20)) as name, "
	    "XMLQuery('copy $e_info := $inf "
	    "modify "
	    "do insert <performance_bonus>{$e_info/employee/salary "
	    "* 0.25 + 5000} "
	    "</performance_bonus> into $e_info/employee "
	    "return $e_info' PASSING emp_details as \"inf\") "
	    "as info "
	    "FROM sales_employee "
	    "WHERE  total_sales between min_sales_v and avg_sales_v "
	    "DO "
	    "SET awarded_emp_info_v = EACH_ROW.info; "
	    "SET emp_name = EACH_ROW.name; "
	    "CALL calculateGiftChequeAmount(awarded_emp_info_v, emp_name); "
	    "INSERT INTO performance_bonus_employees "
	    "VALUES (EACH_ROW.info); "
	    "END FOR; "
	    "RETURN SELECT * FROM performance_bonus_employees; "
	    "END " ;
		    
   printf("%s\n\n", stmt);

   /* execute create table statement directly */
   cliRC = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   printf("Call the table function 'calculatePerformanceBonus' ");
   printf("to get the information of all the employees who got gift ");
   printf("cheques and performance bonus.");

   stmt = "SELECT * FROM table(calculatePerformanceBonus(XMLPARSE(document "
	    "'<sales_per_annum> "
	    "<target_sales>80000</target_sales> "
	    "<avg_sales>70000</avg_sales> "
	    "<min_sales>35000</min_sales> "
	    "</sales_per_annum>')))";
  printf("%s\n\n", stmt);

  /* allocate a statement handle */
  cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
  DBC_HANDLE_CHECK(hdbc, cliRC);

  /* prepare the statement */
  cliRC = SQLPrepare(hstmt, stmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* execute the statement */
  cliRC = SQLExecute(hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* bind column POID to variable PID*/
  cliRC = SQLBindCol(hstmt, 1, SQL_C_CHAR, &xmldata.data, 3000, &xmldata.ind);
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  /* fetch result returned from Select statement*/
  cliRC = SQLFetch(hstmt); 
  STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

  while (cliRC != SQL_NO_DATA_FOUND) 
  {
    if(xmldata.ind > 0)
    {
      printf("\n%s\n\n", xmldata.data);
    }
    /* fetch next row */
    cliRC = SQLFetch(hstmt);
    STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);
  }
  
   printf("\n  Rolling back the transaction...\n");

   /* end the transactions on the connection */
   cliRC = SQLEndTran(SQL_HANDLE_DBC, hdbc, SQL_ROLLBACK);
   DBC_HANDLE_CHECK(hdbc, cliRC);
   printf("  Transaction rolled back.\n");

   /* free the statement handle */
   cliRC = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, cliRC);

   return rc;
  
}

int CleanUpTables(SQLHANDLE hdbc)
{
  SQLRETURN cliRC = SQL_SUCCESS;
   int rc = 0;
   SQLHANDLE hstmt; /* statement handle */
   SQLCHAR *stmt = 0;
   char clean[200];


     /* set AUTOCOMMIT OFF */
   cliRC = SQLSetConnectAttr(hdbc,
                            SQL_ATTR_AUTOCOMMIT,
                            (SQLPOINTER)SQL_AUTOCOMMIT_OFF,
                            SQL_NTS);
   DBC_HANDLE_CHECK(hdbc, cliRC);

   /* allocate a statement handle */
   cliRC = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   DBC_HANDLE_CHECK(hdbc, cliRC);

  printf("cleaning up.... \n");
 
  strcpy(clean,"DROP TABLE sales_department");
  printf("%s \n",clean);
  rc = SQLExecDirect(hstmt, (SQLCHAR *)clean, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  strcpy(clean,"DROP TABLE sales_employee");
  printf("%s \n",clean);
  rc = SQLExecDirect(hstmt, (SQLCHAR *)clean, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  strcpy(clean,"DROP TABLE performance_bonus_employees");
  printf("%s \n",clean);
  rc = SQLExecDirect(hstmt, (SQLCHAR *)clean, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  strcpy(clean, "COMMIT");
  printf("%s \n",clean);
  rc = SQLExecDirect(hstmt, (SQLCHAR *)clean, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);
  
  /* Free the allocated handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  return 1;

}
