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
// SOURCE FILE NAME: RelToXmlDoc.java
//
// SAMPLE USER SCENARIO : Purchase order database uses relational tables to store the
//         orders of different customers. This data can be returned as an XML object 
//         to the application. The XML object can be created using the XML constructor
//         functions on the server side.
//         To achieve this, the user can
//           1. Create a stored procedure to implement the logic to create the XML
//              object using XML constructor functions.
//           2. Register the above stored procedure to the database.
//           3. Call the procedure whenever all the PO data is needed as XML 
//              instead of using complex joins.
//
// SAMPLE : This sample basically demostrates two things
//           1. Using joins on relational data
//           2. Using constructor function to get purchaseorder data as an XML object
// 
//          To run this sample, peform the following steps:
//           1. create and populate the SAMPLE database 
//           2. create stored procedure reltoxmlproc by executing
//              db2 -td@ -f reltoxmlproc.db2
//
// SQL Statements USED:
//         SELECT
//         
// SQL/XML Functions Used :
//         XMLELEMENT
//	   XMLATTRIBUTES
//         XMLCONCAT
//         XMLNAMESPACES
//         XMLCOMMENT
//
// JAVA 2 CLASSES USED:
//         Statement
//         ResultSet
//
// Classes used from Util.java are:
//         Db
//         Data
//         JdbcException
//
// OUTPUT FILE: RelToXmlDoc.out (available in the online documentation)
//***************************************************************************
//
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//     http://www.software.ibm.com/data/db2/udb/ad
//**************************************************************************/

import java.lang.*;
import java.sql.*;

class RelToXmlDoc
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO CONVERT DATA RELATIONAL TABLES\n" + 
        "INTO A XML DOCUMENT USING THE XML CONSTRUCTOR FUNCTIONS");

      // connect to the 'sample' database
      db.connect();

      // select the purchaseorder data using joins
      execQuery(db.con);
      
      // function to call  the stored procedure which will
      // select purchaseorder data using XMLconstructors
      callRelToXmlProc(db.con);
  
      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  static void execQuery(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE JAVA 2 CLASS:\n" +
        "  Statement\n" +
        "TO EXECUTE THE QUERY WITH XML CONSTRUCTORS.");

      Statement stmt = con.createStatement();

      // execute the query
      System.out.println();
      System.out.println(
        "  Execute Statement:\n" +
        "SELECT po.CustID, po.PoNum, po.OrderDate, po.Status,\n" +
        "       count(l.ProdID) as Items, sum(p.Price) as total,\n" +
        "       po.Comment, c.Name, c.Street, c.City, c.Province, c.PostalCode\n" +
        "  FROM PurchaseOrder_relational as po, CustomerInfo_relational as c,\n" +
        "       Lineitem_relational as l, Products_relational as p\n" +
        "  WHERE po.CustID = c.CustID and po.PoNum = l.PoNum and l.ProdID = p.ProdID\n" +
        "  GROUP BY po.PoNum,po.CustID,po.OrderDate,po.Status,c.Name,\n" +
        "           c.Street, c.City,c.Province, c.PostalCode,po.Comment\n" +
        "  ORDER BY po.CustID,po.OrderDate\n");
     
      ResultSet rs = stmt.executeQuery(
	"SELECT po.CustID, po.PoNum, po.OrderDate, po.Status," +
        "       count(l.ProdID) as Items, sum(p.Price) as total," +
        "       po.Comment, c.Name, c.Street, c.City, c.Province, c.PostalCode" +
        "  FROM PurchaseOrder_relational as po, CustomerInfo_relational as c," +
        "       Lineitem_relational as l, Products_relational as p" +
        "  WHERE po.CustID = c.CustID and po.PoNum = l.PoNum and l.ProdID = p.ProdID" +
        "  GROUP BY po.PoNum,po.CustID,po.OrderDate,po.Status,c.Name," +
        "           c.Street, c.City,c.Province, c.PostalCode,po.Comment" +
        "  ORDER BY po.CustID,po.OrderDate");

      System.out.println();
      System.out.println("  Results:\n" +
                         "    CustId   PoNum    OrderDate     Status" +
                         "    \t Items     Total_Price  Comment\n" +
                         "    \t\t Name \t\t Street  \t City  \t Province \t PostalCode\n" +
                         "    -----------------------------------------------------------------------------\n"); 

      int CustId = 0;
      int PoNum = 0;
      String OrderDate = "";
      String Status = "";
      int Items = 0;
      double Price = 0;
      String Comment = "";
      String Name = "";
      String Street= "";
      String City = "";
      String Province = "";
      int PostalCode = 0;

      while (rs.next())
      {
        CustId = rs.getInt(1);
        PoNum = rs.getInt(2);
        OrderDate = rs.getString(3);
        Status = rs.getString(4);
        Items = rs.getInt(5);
        Price = rs.getDouble(6);
        Comment = rs.getString(7);
        Name = rs.getString(8);
        Street = rs.getString(9);
        City = rs.getString(10);
        Province = rs.getString(11);
        PostalCode = rs.getInt(12);     
        System.out.println("    " +
                           Data.format(CustId, 8) + " " +
                           Data.format(PoNum, 8) + " " +
                           Data.format(OrderDate, 11) + " " +
 			   Data.format(Status, 50) + " " +
                           Data.format(Items, 5) + " " +
                           Data.format(Price,6,2) + " " +
                           Data.format(Comment, 200) + " " +
                           Data.format(Name, 20) + " " +
                           Data.format(Street, 20) + " " +
                           Data.format(City, 20) + " " +
                           Data.format(Province, 20) + " "  + 
                           Data.format(PostalCode, 8));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } //execQuery

  public static void callRelToXmlProc(Connection con)
  {
    try
    {
      // prepare the CALL statement for ONE_RESULT_SET
      String procName = "RELTOXMLPROC";
      String sql = "CALL " + procName + "()";
      CallableStatement callStmt = con.prepareCall(sql);

      // call the stored procedure
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();

      System.out.println(procName + " completed successfully");
      ResultSet rs = callStmt.getResultSet();
      fetchAll(rs);

      // close ResultSet and callStmt
      rs.close();
      callStmt.close();
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
  } // callRelToXmlProc

  public static void fetchAll(ResultSet rs)
  {
    try
    {
      System.out.println(
        "=============================================================");

      // retrieve the  number, types and properties of the
      // resultset's columns
      ResultSetMetaData stmtInfo = rs.getMetaData();
     
      String PurchaseOrder = "";
      int numOfColumns = stmtInfo.getColumnCount();
      int r = 0;

      while (rs.next())
      {
        r++;
        System.out.print("Row: " + r + ": ");
        for (int i = 1; i <= numOfColumns; i++)
        {
          if (i == 1 || i == 2)
          {
            System.out.print(Data.format(rs.getInt(i), 8));
          }
          if (i == 3)
          {
            System.out.print(rs.getString(i));
          }
          if (i == 4)
          {
	    PurchaseOrder = rs.getString(i);
            System.out.print(Data.format(PurchaseOrder, 500));
          }
          if (i != numOfColumns)
          {
            System.out.print(", ");
          }
        }
        System.out.println();
      }
    }
    catch (Exception e)
    {
      System.out.println("Error: fetchALL: exception");
      System.out.println(e.getMessage());
    }
  } // fetchAll
} // RelToXmlDoc


