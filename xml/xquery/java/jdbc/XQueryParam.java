//***************************************************************************
// (c) Copyright IBM Corp. 2007 All rights reserved.
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
// SAMPLE FILE NAME: XQueryParam.java
//
// PURPOSE: This sample shows how to pass parameters to db2-fn:sqlquery 
//          function.
//
// USAGE SCENARIO: The super market manager maintains database with
//                 "employee" and "dept_location" tables. "Employee" table
//                 contains employee ID and employee address.
//                 "dept_location" table contains the department and
//                 and it's location details.He will query
//                 these tables to get information about employees and
//                 their department details.
//                 The last XQuery exprepression in this sample shows
//                 purchaseorder details from the sample database
//                 purchaseorder table.
//
// PREREQUISITE: NONE
//
// EXECUTION: javac XQuerypParam.java
//            java XQueryParam
//
// INPUTS: NONE
//
// OUTPUTS: Queries will display the results.
//
// OUTPUT FILE: XQueryParam.out (available in the online documentation)
//
//
// SQL STATEMENTS USED:
//           CREATE TABLE
//           INSERT
//           DROP
//
// SQL/XML FUNCTIONS USED:
//           SQLQUERY
//           XMLCOLUMN
//
//
//***************************************************************************
// For more information about the command line processor (CLP) scripts,
// see the README file.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, building, and running DB2
// applications, visit the DB2 application development website:
//     http://www.software.ibm.com/data/db2/udb/ad
//
//***************************************************************************
// SAMPLE DESCRIPTION
//
//***************************************************************************
// 1. Passing single parameter to SQL fullselect in db2-fn:sqlquery function.
//
// 2. Passing multiple parameters to SQL fullselect in db2-fn:sqlquery 
//    function.
//
//***************************************************************************


import java.lang.*;
import java.sql.*;
import java.io.*;
import java.util.*;
import com.ibm.db2.jcc.DB2Xml;

class XQueryParam
{
  public static void main(String argv[])
  {
    int rc=0;
    String url = "jdbc:db2:sample";
    Connection con=null;
    try
    {
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();

      // connect to the 'sample' database
      con = DriverManager.getConnection( url );
      System.out.println();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try { con.rollback(); }
      catch (Exception e)
      {
      }
      System.exit(1);
    }
    catch(Exception e)
    {}
  
    System.out.println("This sample shows how to pass parameters to ");
    System.out.println(" sqlquery function");
    System.out.println("--------------------------------------------");
    System.out.println();

    createTables(con);
    passSingleParam(con);
    passTwoParams(con);
    cleanup(con);

  } //main

  static void createTables(Connection con)
  {
    Statement stmt = null;

    try
    {
      stmt = con.createStatement();
      String str = "CREATE TABLE employee(empid int, addr XML)";
      System.out.println(str);
      System.out.println();

      stmt.executeUpdate(str);

      str = "CREATE TABLE dept_location(dept_name varchar(20),"+
                " branch_name varchar(50),"+
                " block_no varchar(20), street "+
                " varchar(20), city varchar(20), "+
                " zip_code varchar(20), "+
                " dept_details XML)";

      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);

      str = "INSERT INTO dept_location "+
        "VALUES ('DB2', 'EGL', 'B', 'Koramangala', 'Bangalore', '500042',"+
        "XMLPARSE(document "+
        "'<dept_details xmlns=\"http://posample.org\" dept_code=\"E32\">"+
          "<manager>Peter suzanski</manager>"+
            "<teams>"+
              "<team1>Samples</team1>"+
              "<team2>testing</team2>"+
              "<team3>Development</team3>"+
            "</teams>"+
           "<no_of_people>140</no_of_people>"+
         "</dept_details>' ))";

      System.out.println(str);
      System.out.println();

      stmt.executeUpdate(str);
  
      str ="INSERT INTO dept_location "+
        "VALUES ('Informix','MANYATA', 'D2', 'Hebbal', 'Bangalore', '500067',"+
        "XMLPARSE(document"+
        "'<dept_details xmlns=\"http://posample.org\" dept_code=\"E34\">"+
          "<manager>Jeff </manager>"+
          "<teams>"+
            "<team1>bird</team1>"+
            "<team2>QA</team2>"+
          "</teams>"+
          "<no_of_people>60</no_of_people>"+
        "</dept_details>' ))";

      System.out.println(str);
      System.out.println();

      stmt.executeUpdate(str);

      str = "INSERT INTO employee "+
            "VALUES (1005, XMLPARSE(document "+
            "'<employeeinfo xmlns=\"http://posample.org\" empid=\"1005\">"+
               "<name>Ravi varma</name> "+
               "<addr country=\"India\"> "+
                 "<street>Koramangala</street> "+
                 "<city>Bangalore</city>"+
                 "<prov-state>Karnataka</prov-state>"+
                 "<pcode-zip>500042</pcode-zip>"+
               "</addr>"+
            "</employeeinfo>'))";
      System.out.println(str);
      System.out.println();

      stmt.executeUpdate(str);

      str = "INSERT INTO employee "+
            "VALUES (1006, XMLPARSE(document "+
            "'<employeeinfo xmlns=\"http://posample.org\" empid=\"1006\">"+
                "<name>Oswal Menard</name>"+
                "<addr country=\"India\">"+
                  "<street>Hebbal</street>"+
                  "<city>Bangalore</city>"+
                  "<prov-state>Karnataka</prov-state>"+
                  "<pcode-zip>500067</pcode-zip>"+
                "</addr>"+
            "</employeeinfo>'))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);
 
      stmt.close(); 
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try { con.rollback(); }
      catch (Exception e)
      {
      }
      System.exit(1);
    }
    catch(Exception e)
    {}
  } //createTables
 
  //--------------------------------------------------------------------------
  // 1. Passing single parameter to SQL fullselect in db2-fn:sqlquery function.
  //--------------------------------------------------------------------------
 
  static void passSingleParam(Connection con)
  {
    try
    {
      System.out.println("The following XQuery expression returns an ");
      System.out.println("employee's postal code and department details ");
      System.out.println("when the employee and the department are in same ");
      System.out.println("location (defined by zip code)");
      System.out.println();

      String str = "XQUERY "+
                   "declare default element namespace \"http://posample.org\";"+
                   "for $pcode in db2-fn:xmlcolumn(\"EMPLOYEE.ADDR\")"+
                         "/employeeinfo/addr/pcode-zip "+
                   "for $deptinfo in db2-fn:sqlquery( "+
                         "\"SELECT dept_details FROM dept_location "+
                         "WHERE zip_code = parameter(1)\", $pcode)"+
                   "return "+
                      "<out>{$pcode, $deptinfo }</out>";
      System.out.println(str);
      System.out.println();

      PreparedStatement pstmt = con.prepareStatement(str);
      ResultSet rs = pstmt.executeQuery();

      System.out.println("-------------------------------------------------");
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
      } 
      System.out.println("-------------------------------------------------");
 
      rs.close();
      pstmt.close();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try { con.rollback(); }
      catch (Exception e)
      {
      }
      System.exit(1);
    }
    catch(Exception e)
    {}
  } //passSingleParam
  
  //------------------------------------------------------------------------------
  // 2. Passing multiple parameters to SQL fullselect in db2-fn:sqlquery 
  //    function.
  //-------------------------------------------------------------------------

  static void passTwoParams(Connection con)
  {
    try
    {
      System.out.println("The following XQuery expression returns an employee's");
      System.out.println(" postal code,department name and department details,");
      System.out.println(" when an employee and a department are in same ");
      System.out.println(" location, and the employee belongs to one of the ");
      System.out.println(" following departments: DB2, Informix or CM.");
      System.out.println();

      String str = "XQUERY "+
                   "declare default element namespace \"http://posample.org\";"+
                   "for $pcode in db2-fn:xmlcolumn(\"EMPLOYEE.ADDR\")"+
                                 "/employeeinfo/addr/pcode-zip,"+
                        "$dept in ('DB2', 'Informix', 'CM')"+
                   "for $deptinfo in db2-fn:sqlquery("+
                      "\"SELECT dept_details FROM dept_location "+
                      "WHERE zip_code = parameter(1) and dept_name = parameter(2)\","+
                      " $pcode, $dept) "+
                     "return "+
                         "<out>"+
                               "{$pcode}"+
                               "<dept_name>{$dept}</dept_name>"+
                               "{$deptinfo}"+
                         "</out>";
      System.out.println(str);
      System.out.println();

      PreparedStatement pstmt = con.prepareStatement(str);
      ResultSet rs = pstmt.executeQuery();

      System.out.println("-------------------------------------------------");
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
      }
      System.out.println("-------------------------------------------------");

      System.out.println("The following XQuery expression uses the purchase");
      System.out.println("order table from the sample database.");

      System.out.println("The XQuery expression returns all purchase orders ");
      System.out.println(" made by customers after date \"2005-11-18\".");
      System.out.println();

      str = "XQUERY "+
            "for $ponum in db2-fn:xmlcolumn(\"PURCHASEORDER.PORDER\")"+
                    "/PurchaseOrder/@PoNum "+
            "for $x in db2-fn:sqlquery(\"SELECT porder FROM purchaseorder "+
                    "WHERE OrderDate > parameter(1) and poid = parameter(2)\","+
                    " '2005-11-18', $ponum) "+
              "return "+
                 " <out> {$x} </out>";
      System.out.println(str);
      System.out.println();
     
      PreparedStatement pstmt1 = con.prepareStatement(str); 
      rs = pstmt1.executeQuery();
      System.out.println("-------------------------------------------------");
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
      }
      System.out.println("-------------------------------------------------");

      rs.close();
      pstmt.close();
      pstmt1.close();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try { con.rollback(); }
      catch (Exception e)
      {
      }
      System.exit(1);
    }
    catch(Exception e)
    {}
  } //passTwoParams
  
  static void cleanup(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
      String str = "DROP TABLE employee";
      System.out.println(str);
      System.out.println();

      stmt.executeUpdate(str);
     
      str = "DROP TABLE dept_location";
      System.out.println(str);
      System.out.println();

      stmt.executeUpdate(str);

      stmt.close();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try { con.rollback(); }
      catch (Exception e)
      {
      }
      System.exit(1);
    }
    catch(Exception e)
    {}
  } //cleanup
} //XQueryParam
