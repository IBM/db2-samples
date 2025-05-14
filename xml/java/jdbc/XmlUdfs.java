//***************************************************************************
// (c) Copyright IBM Corp. 2008 All rights reserved.
//
// The following sample of source code ("Sample") is owned by International
// Business Machines Corporation or one of its subsidiaries ("IBM") and is
// copyrighted and licensed, not sold. You may use, copy, modify, and
// distribute the Sample in any form without payment to IBM, for the purpose of
// assisting you in the development of your applications.
//
// The Sample code is provided to you on an "AS IS" basis, without warranty of
// any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
// IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
// not allow for the exclusion or limitation of implied warranties, so the above
// limitations or exclusions may not apply to you. IBM shall not be liable for
// any damages you suffer as a result of using, copying, modifying or
// distributing the Sample, even if IBM has been advised of the possibility of
// such damages.
//***************************************************************************
//
// SAMPLE FILE NAME: XmlUdfs.java
//
// PURPOSE: The purpose of this sample is to show extended support of XML for 
//          sourced UDF and SQL bodied UDF in serial and DPF environment 
//          for DB2 Cobra. 
//
// USAGE SCENARIO: The scenario is for a Book Store that has two types of 
//      customers, retail customers and corporate customers. Corporate 
//      customers do bulk purchases of books for their company libraries. 
//      The Book Store also maintains list of registered customers 
//      who are frequent buyers from the store and have registered 
//      themselves with the store. The store has a DBA, sales clerk and a 
//      manager for maintaining the database and to run queries on different 
//      tables to view the book sales.
//
//      The store manager frequently queries various tables to get 
//      information such as contact numbers of different departments,
//      location details, location manager details, employee details 
//      in order to perform various business functions like promoting 
//      employees, analysing sales, giving awards and bonus to employees 
//      based on their sales.
//
//      The manager is frustrated writing the same queries every time to 
//      get the information and observes performance degradation as well.  
//      So he decides to create a user-defined function and a stored  
//      procedure for each of his requirements. 
//
// PREREQUISITE: None
//
// EXECUTION: javac XmlUdfs.java
//            java XmlUdfs <SERVER_NAME> <PORT_NO> <USERID> <PASSWORD>
//
// INPUTS: NONE
//
// OUTPUTS: Successfull execution of all UDFs and stored procedures.
//
// OUTPUT FILE: XmlUdfs.out (available in the online documentation)
//
// SQL STATEMENTS USED:
//           CREATE TABLE
//           INSERT
//           DELETE
//           DROP
// SQL/XML FUNCTIONS USED:
//           XMLEXISTS
//           XMLPARSE
//           XMLQUERY
//
//***************************************************************************
// For more information about the command line processor (CLP) scripts,
// see the README file.
//
// For information on using SQL statements, see the SQL Reference.
//
//***************************************************************************
// SAMPLE DESCRIPTION
//
//***************************************************************************
// 1. UDF Scalar function which takes an XML variable as input the parameter
//    and returns XML value as output.
//
// 2. UDF Table function which takes an XML variable as input the parameter
//    and returns table with XML values as output.
//
// 3. Sourced UDF which takes an XML variable as the input parameter   
//    and returns XML value as output.
//
// 4. SQL bodied UDF which takes an XML variable as the input parameter
//    and returns a table with XML values as output. This UDF 
//    internally calls a stored procedure which takes an XML variable
//    as the input parameter and returns an XML value as output.
//   
//***************************************************************************
//
//   IMPORT ALL PACKAGES AND CLASSES
//
//**************************************************************************/

import java.lang.*;
import java.sql.*;
import java.util.*;
import java.io.*;

class XmlUdfs
{
  static Db db;
  public static void main(String argv[])
  {
    String url="jdbc:db2:sample";
    Connection con = null;
    ResultSet rs = null;
    javax.sql.DataSource ds = null;

    try
    {
       db=new Db(argv);
    }
    catch (Exception e)
    {
       System.out.println("  Error loading DB2 Driver...\n");
       System.out.println(e);
       System.exit(1);
    }
    try
    {
       con = db.connect();
    }
    catch (Exception e)
    {
       System.out.println("Connection to sample db can't be established.");
       System.err.println(e) ;
       System.exit(1);
    }

    System.out.println("This sample shows how to pass "+
       " XML type variables as input parameters, return type "+
       " or local variables in SQL bodied UDFs ");

    try
    {
       setUpTables(con);
       scalarUDF(con);
       tableUDF(con);
       sourcedUDF(con);
       invokeSpFromUDF(con);
       cleanUpTables(con);
    }
    catch(Exception e)
    {
      System.out.println("Error..."+e);
    }

    try
    {
       db.disconnect();
    }
    catch (Exception e)
    {
       System.out.println("Connection to sample db can't be terminated.");
       System.err.println(e) ;
       System.exit(1);
    }

  } // main

  static void setUpTables(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();

      System.out.println("Setting up tables for the sample");
      System.out.println("---------------------------------");
      System.out.println();
      String str = "CREATE TABLE sales_department(dept_id CHAR(10), "+
                   "dept_info XML)";
      stmt.executeUpdate(str);
      System.out.println(str);
      System.out.println();

      str = "CREATE TABLE sales_employee (emp_id INTEGER, "+
            " total_sales INTEGER, emp_details XML)";
      stmt.executeUpdate(str);
      System.out.println(str);
      System.out.println();

      str = "CREATE TABLE performance_bonus_employees(bonus_info XML)";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println();
      str = "INSERT INTO sales_employee VALUES (5001, 40000, "+
            "XMLPARSE(document "+
            "'<employee id=\"5001\">"+
	    "<name>Lethar Kessy</name>"+
	    "<address>"+
	    "<street>555 M G Road</street>"+
	    "<city>Bangalore</city>"+
	    "<state>Karnataka</state>"+
	    "<country>India</country>"+
	    "<zipcode>411004</zipcode>"+
	    "</address>"+
            "<phone>"+
            "<cell>9435344354</cell>"+
	    "</phone>"+
            "<dept>DS02</dept>"+
	    "<skill_level>7</skill_level>"+
	    "<sales>40000</sales>"+
	    "<salary currency=\"INR\">25500</salary>"+
	    "<designation>Sr. Manager</designation>"+
	    "<manager>Harry</manager>"+
	    "</employee> '))";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println();
      str = "INSERT INTO sales_employee VALUES (5002, 50000, "+
            "XMLPARSE(document "+
            "'<employee id=\"5002\">"+
            "<name>Mathias Jessy</name>"+
            "<address>"+
            "<street>Indra Nagar Road No. 5</street>"+
            "<city>Bangalore</city>"+
            "<state>Karnataka</state>"+
            "<country>India</country>"+
            "<zipcode>411004</zipcode>"+
            "</address>"+
            "<phone>"+
            "<cell>9438884354</cell>"+
            "</phone>"+
            "<dept>DS02</dept>"+
            "<skill_level>6</skill_level>"+
            "<sales>50000</sales>"+
            "<salary currency=\"INR\">22500</salary>"+
            "<designation>Manager</designation>"+
            "<manager>Harry</manager>"+
            "</employee> '))";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println();
      str = "INSERT INTO sales_employee VALUES (5003, 40000, "+
            "XMLPARSE(document "+
            "'<employee id=\"5003\">"+
            "<name>Mohan Kumar</name>"+
            "<address>"+
            "<street>Vijay Nagar Road No. 5</street>"+
            "<city>Bangalore</city>"+
            "<state>Karnataka</state>"+
            "<country>India</country>"+
            "<zipcode>411004</zipcode>"+
            "</address>"+
            "<phone>"+
            "<cell>9438881234</cell>"+
            "</phone>"+
            "<dept>DS02</dept>"+
            "<skill_level>5</skill_level>"+
            "<sales>40000</sales>"+
            "<salary currency=\"INR\">15500</salary>"+
            "<designation>Associate Manager</designation>"+
            "<manager>Harry</manager>"+
            "</employee> '))";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println();
      str = "INSERT INTO sales_department VALUES ('DS02', XMLPARSE(document "+
	    "'<department id=\"DS02\">"+
	    "<name>sales</name>"+
	    "<manager id=\"M2001\">"+
	    "<name>Harry Thomas</name>"+
	    "<phone>"+
	    "<cell>9732432423</cell>"+
	    "</phone>"+
	    "</manager>"+
	    "<phone>"+
	    "<office>080-23464879</office>"+
	    "<office>080-56890728</office>"+
	    "<fax>080-45282976</fax>"+
	    "</phone>"+
	    "</department>'))";
      stmt.executeUpdate(str);
      System.out.println(str);

    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // setUpTables

  //--------------------------------------------------------------------------
  // 1. UDF Scalar function which takes an XML variable as input parameter
  //    and returns an XML value as output.
  //--------------------------------------------------------------------------

  static void scalarUDF(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
      System.out.println("------------------------------------------");
      System.out.print("Create a scalar function 'getDeptContactNumbers' ");
      System.out.println(" which returns a list of department phone numbers ");
      System.out.println("------------------------------------------");

      System.out.println();
      String str = "CREATE FUNCTION getDeptContactNumbers(dept_info_p XML)"+
		   "RETURNS XML "+
	           "LANGUAGE SQL "+
		   "SPECIFIC contactNumbers "+
		   "NO EXTERNAL ACTION "+
		   "BEGIN ATOMIC "+
		   "RETURN XMLQuery('document "+
                   "{<phone_list>{$dep/department/phone}</phone_list>}' "+
		   "PASSING dept_info_p as \"dep\");"+
 		   "END";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println("Call scalar UDF 'getDeptContactNumbers' to get ");
      System.out.println(" contact numbers of the department \"DS02\" ");

      str = "SELECT getDeptContactNumbers(sales_department.dept_info) "+
            "FROM sales_department where dept_id = 'DS02'";
      ResultSet rs = stmt.executeQuery(str);
      System.out.println();
      System.out.println(str);

      String result = null; 
      while(rs.next())
      {
        result = rs.getString(1);
        System.out.println("    " +
                            Data.format(result, 1024) + " " );
      }

      rs.close();
      stmt.close(); 
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }

  } // scalarUDF

  //------------------------------------------------------------------------
  // 2. UDF Table function which takes an XML variable as input parameter
  //    and returns a table with XML values as output.
  //-------------------------------------------------------------------------

  static void tableUDF(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
    
      System.out.println("-------------------------------");
      System.out.println("The store opens new branches in different ");
      System.out.print(" parts of the city. The book store manager ");
      System.out.print("wants to promote senior managers and associate ");
      System.out.print("managers and designate them to manage these new ");
      System.out.print("branches. He wants to update the skill level and ");
      System.out.print("salaries of all the promoted managers in the ");
      System.out.print("sales_employee table. He asks the DBA to create ");
      System.out.print("a table function for this requirement. The DBA ");
      System.out.print("creates the 'updatePromotedEmployeesInfo' ");
      System.out.print("table function. This function updates the skill ");
      System.out.print("level and salaries of the promoted managers in ");
      System.out.print("sales_employee table and returns details of ");
      System.out.println("all the managers who got promoted.");
      System.out.println("-------------------------------");

      System.out.println();
      String str = "CREATE FUNCTION updatePromotedEmployeesInfo(emp_id_p INTEGER) "+
               "RETURNS TABLE (name VARCHAR(50), emp_id integer, skill_level integer, "+
               "salary double, address XML) "+
               "LANGUAGE SQL "+
               "MODIFIES SQL DATA "+
               "SPECIFIC func1 "+
               "BEGIN ATOMIC "+
               "UPDATE sales_employee SET emp_details = XMLQuery('transform  "+
               "copy $emp_info := $emp "+
               " modify if ($emp_info/employee[skill_level = 7 and "+
	         "                       designation = \"Sr. Manager\"]) "+
               "then "+
		   "( "+
		   "do replace value of $emp_info/employee/skill_level with 8, "+
		   "do replace value of $emp_info/employee/salary with "+
		   "                  $emp_info/employee/salary * 9.5 "+
               ")	"+        
               "else if ($emp_info/employee[skill_level = 6  and "+
		   "                          designation = \"Manager\"])"+
               "then "+
               "( "+
		   "do replace value of $emp_info/employee/skill_level with 7, "+
		   " do replace value of $emp_info/employee/salary with "+
		   "     $emp_info/employee/salary * 7.5 "+
               ") "+
		   "else if ($emp_info/employee[skill_level = 5  and "+
		   "                         designation = \"Associate Manager\"]) "+
               "then "+
               "( "+
	         " do replace value of $emp_info/employee/skill_level with 6, "+
	         "   do replace value of $emp_info/employee/salary with "+
		   "        $emp_info/employee/salary * 5.5 "+
               ")"+ 
		   "else ()"+           
	         "return $emp_info' PASSING emp_details as \"emp\") "+             
               " WHERE emp_id = emp_id_p; "+
               " RETURN SELECT X.* "+
               "FROM sales_employee, XMLTABLE('$e_info/employee' PASSING "+
               "                        emp_details as \"e_info\" "+
               "COLUMNS "+
               "name VARCHAR(50) PATH 'name', "+
               "emp_id integer PATH '@id', "+
               "skill_level integer path 'skill_level', "+
               "salary double path 'salary', "+
               "addr XML path 'address') AS X WHERE sales_employee.emp_id = emp_id_p; "+
               "END";

      stmt.executeUpdate(str);
      System.out.println(str);
      System.out.println();

      System.out.println("Call the 'updatePromotedEmployeesInfo' table ");
      System.out.println("function to update the details of promoted employees");
      System.out.println(" in 'sales_employee' table ");

      str = "SELECT A.* FROM sales_employee AS E,  "+
            "table(updatePromotedEmployeesInfo(E.emp_id)) AS A";
      System.out.println(str);

      ResultSet rs = stmt.executeQuery(str); 
      String name = null;
      int emp_id = 0;
      int skill_level = 0;
      int salary = 0;
      String addr = null;

      System.out.println();
      System.out.println("name, emp_id, skill_level, salary, address");
      System.out.println("-----------------------------------------");
      while(rs.next())
      {
        name = rs.getString(1);
        emp_id = rs.getInt(2);
        skill_level = rs.getInt(3);
        salary = rs.getInt(4);
        addr = rs.getString(5);

        System.out.println("  "+Data.format(name, 20)+"   "+
          Data.format(emp_id, 10)+"    "+Data.format(skill_level, 5)+"    "+
          Data.format(salary, 20)+"   "+Data.format(addr, 1024)+"      ");
      }

      rs.close();
      stmt.close();

    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // tableUDF

  //------------------------------------------------------------------------
  // 3. Sourced UDF which takes an XML variable as the input parameter
  //  and returns an XML value as output.
  //------------------------------------------------------------------------


  static void sourcedUDF(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
   
      System.out.println("------------------------------------");
      System.out.println("The store manager would like to get a ");
      System.out.println("particular dept manager name and his ");
      System.out.println("contact numbers. The DBA then creates a ");
      System.out.println("'getManagerDetails' UDF to get a particular ");
      System.out.println("department manager name and manager contact details.");
      System.out.println("------------------------------------");

      System.out.println(); 
      String str = "CREATE FUNCTION getManagerDetails(dept_info_p XML, "+
                   " dept_p VARCHAR(5)) "+
                   "RETURNS XML "+
                   "LANGUAGE SQL "+
                   "SPECIFIC getManagerDetails "+
                   "BEGIN ATOMIC "+
                   "RETURN XMLQuery('for $dt in "+
                   "$info/department[name=$dept_name] "+
                   "return (<manager_info>{$dt/manager}</manager_info>)' "+
                   "PASSING dept_info_p as \"info\", dept_p as \"dept_name\");"+
                   "END";

      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println("---------------------------------------------"); 
      System.out.println("Create a sourced UDF 'getManagerInfo' ");
      System.out.println("based on 'getManagerDetails'user defined function ");


      str = "CREATE FUNCTION getManagerInfo(XML, CHAR(10))"+
            "RETURNS XML "+
            "SOURCE getManagerDetails(XML, VARCHAR(5)) ";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println(); 
      System.out.println("Call the sourced UDF 'getManagerInfo' to get ");
      System.out.println(" 'sales' department manager details ");
      System.out.println("---------------------------------------------");   

      str = "SELECT getManagerInfo(sales_department.dept_info, 'sales') "+
            "FROM sales_department WHERE dept_id='DS02'";
      ResultSet rs = stmt.executeQuery(str);
      System.out.println(str);

      String manager_details = null;
      while(rs.next())
      {
        manager_details = rs.getString(1);
        System.out.println("  "+Data.format(manager_details, 1024)+"   ");
      }

      rs.close();
      stmt.close();

    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // sourcedUDF

  // -------------------------------------------------------------------------
  // 4. SQL bodied UDF which takes an XML variable as the input parameter
  //    and returns a table with XML values as output. This UDF
  //    calls a stored procedure which takes an XML variable
  //    as the input parameter and returns an XML value as output.
  //--------------------------------------------------------------------------


  static void invokeSpFromUDF(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
      System.out.println("---------------------------------------");
      System.out.println("Create a function which calculates an employee ");
      System.out.println("gift cheque amount and adds this value as a new ");
      System.out.println("element into the employee information document");
      System.out.println("---------------------------------------");

      System.out.println();
      String str = "CREATE PROCEDURE calculateGiftChequeAmount( "+
                   "INOUT emp_info_p XML, "+
                   "IN emp_name_p VARCHAR(20)) "+
                   "LANGUAGE SQL "+
                   "MODIFIES SQL DATA "+
                   "SPECIFIC giftcheque "+
                   "BEGIN  "+
                   "DECLARE emp_bonus_info_v XML; "+
                   "IF XMLEXISTS('$e_info/employee[name = $emp1]' PASSING "+
                   "emp_info_p as \"e_info\","+
                   "emp_name_p as \"emp1\")"+
                   "THEN "+
                   "SET emp_bonus_info_v = XMLQuery('copy $bonus := $info "+
                   "modify "+
                   "do insert <customer_gift_cheque>{"+
                   " $bonus/employee/salary * 0.50 + 25000} "+
                   "</customer_gift_cheque> into $bonus/employee "+
                   "return $bonus' PASSING emp_info_p as \"info\"); "+
                   "END IF; "+
                   "SET emp_info_p = emp_bonus_info_v; "+
                   "END ";
      stmt.executeUpdate(str);
      System.out.println(str);


      System.out.println("----------------------------------------");
      System.out.print("Some employees who got customer appreciation ");
      System.out.println("awards and whose total sales are greater ");
      System.out.println("than expected sales were given gift cheques ");
      System.out.println("by the store. The DBA creates ");
      System.out.println("'calculatePerformanceBonus' function to ");
      System.out.println("calculate employee performance bonus along with ");
      System.out.println("customer gift cheque amount and update the ");
      System.out.println("employee information in sales_employee table.");
      System.out.println("----------------------------------------");   

      str = "CREATE FUNCTION calculatePerformanceBonus(sales_info_p XML) "+
            "RETURNS table(info XML) "+
            "LANGUAGE SQL "+
            "SPECIFIC awardedemployees "+
            "MODIFIES SQL DATA "+
            "BEGIN ATOMIC "+
            "DECLARE awarded_emp_info_v  XML; "+
            "DECLARE emp_name VARCHAR(20); "+
            "DECLARE min_sales_v INTEGER; "+
            "DECLARE avg_sales_v INTEGER; "+
            "SET min_sales_v = XMLCAST(XMLQuery('$info/sales_per_annum/min_sales' "+
            "PASSING sales_info_p as \"info\")  AS INTEGER); "+
            "SET avg_sales_v = XMLCAST(XMLQuery('$info/sales_per_annum/avg_sales' "+
            "PASSING sales_info_p as \"info\")  AS INTEGER); "+
            "FOR_LOOP: FOR EACH_ROW AS "+
            "SELECT XMLCAST(XMLQuery('$info/employee/name' PASSING awarded_emp_info_v "+
            "as \"info\") AS VARCHAR(20)) as name, "+
            "XMLQuery('copy $e_info := $inf "+
            "modify "+
            "do insert <performance_bonus>{$e_info/employee/salary "+
            "* 0.25 + 5000} "+
            "</performance_bonus> into $e_info/employee "+
            "return $e_info' PASSING emp_details as \"inf\") "+
            "as info "+
            "FROM sales_employee "+
            "WHERE  total_sales between min_sales_v and avg_sales_v "+
            "DO "+
            "SET awarded_emp_info_v = EACH_ROW.info; "+
            "SET emp_name = EACH_ROW.name; "+
            "CALL calculateGiftChequeAmount(awarded_emp_info_v, emp_name); "+
            "INSERT INTO performance_bonus_employees "+
            "VALUES (EACH_ROW.info); "+
            "END FOR; "+
            "RETURN SELECT * FROM performance_bonus_employees; "+
            "END ";



      stmt.executeUpdate(str);
      System.out.println(str);
      System.out.println("---------------------------------------------");
      System.out.println("Call the table function ");
      System.out.println("'calculatePerformanceBonus' to get the ");
      System.out.println("information of all the employees who got gift ");
      System.out.println("cheques and performance bonus.");
      System.out.println("---------------------------------------------");

      str = "SELECT * FROM table(calculatePerformanceBonus(XMLPARSE(document "+
            "'<sales_per_annum> "+
            "<target_sales>80000</target_sales> "+
            "<avg_sales>70000</avg_sales> "+
            "<min_sales>35000</min_sales> "+
            "</sales_per_annum>')))";
      ResultSet rs = stmt.executeQuery(str);
      System.out.println(str);
      System.out.println();

      String bonus_info = null;
      while(rs.next())
      {
        bonus_info = rs.getString(1);
        System.out.println("   "+Data.format(bonus_info, 1024)+"    ");
      }

      rs.close();
      stmt.close();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // invokeSpFromUdf


  static void cleanUpTables(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();

      String str = "DROP FUNCTION getDeptContactNumbers";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP FUNCTION updatePromotedEmployeesInfo";
      stmt.executeUpdate(str);  

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP FUNCTION getManagerInfo";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP FUNCTION calculatePerformanceBonus";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP PROCEDURE calculateGiftChequeAmount";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP TABLE sales_employee";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP TABLE sales_department";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP TABLE performance_bonus_employees";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

      str = "DROP FUNCTION getManagerDetails";
      stmt.executeUpdate(str);

      str = "COMMIT";
      stmt.executeUpdate(str);

    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // cleanUpTables
} // XmlUdfs

