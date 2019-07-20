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
// SOURCE FILE NAME: RelToXmlType.java
//
// SAMPLE : Purchase order database uses relational tables to store the orders of
//          different customers. This data can be returned as an XML object to the
//          application. The XML object can be created using the XML constructor
//          functions on the server side.
//          To achieve this, the user can
//             1. Create new tables having XML columns. (Done in set up script)
//             2. Change the relational data to XML type using constructor functions.
//             3. Insert the data in new tables
//             4. Use the query to select all PO data.
//
// PREREQUISITE:
//         The relational tables that store the purchase order data will have to
//         be created before this sample is executed. For this the file
//         setupscript.db2 will have to be run using the command
//            db2 -tvf setupscript.db2
//         After successfull execution of the script, this sample can be compiled using
//            javac RelToXmlType.java
//         and executed using
//            java RelToXmlType
//
//          Please make sure that you run the cleanup script after running the
//          sample using following command
//             db2 -tvf cleanupscript.db2
// 
// SQL Statements USED:
//         SELECT
//         INSERT
//
// SQL/XML FUNCTION USED:
//         XMLDOCUMENT
//         XMLELEMENT
//         XMLATTRIBUTES
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
// OUTPUT FILE: RelToXmlType.out (available in the online documentation)
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

class RelToXmlType
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

      // execute the Query to Select data from relation tables
      // and insert into tables as XML data type.
      execQuery(db.con);
      
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
        "INSERT INTO Customerinfo_New (Custid, Address)\n" +
        "(SELECT Custid, \n" +
        "XMLDOCUMENT( \n" +
        "XMLELEMENT(NAME \"Address\", \n" +
        "XMLELEMENT(NAME \"Name\", c.Name), \n" +
        "XMLELEMENT(NAME \"Street\", c.Street), \n" +
        "XMLELEMENT(NAME \"City\", c.City), \n" +
        "XMLELEMENT(NAME \"Province\", c.Province), \n" +
        "XMLELEMENT(NAME \"PostalCode\", c.PostalCode))) \n" +
        "FROM CustomerInfo_relational AS C)\n");

      stmt.executeUpdate(
        "INSERT INTO Customerinfo_New (Custid, Address)" +
        "(SELECT Custid, " +
        "XMLDOCUMENT( " +
        "XMLELEMENT(NAME \"Address\", " +
        "XMLELEMENT(NAME \"Name\", c.Name), " +
        "XMLELEMENT(NAME \"Street\", c.Street), " +
        "XMLELEMENT(NAME \"City\", c.City), " +
        "XMLELEMENT(NAME \"Province\", c.Province), " +
        "XMLELEMENT(NAME \"PostalCode\", c.PostalCode))) " +
        "FROM CustomerInfo_relational AS C)");

      System.out.println(
        "Execute Statement:\n" +
        "INSERT INTO purchaseorder_new(PoNum, OrderDate, CustID, Status, LineItems)\n" +
        "(SELECT Po.PoNum, OrderDate, CustID, Status,\n" +
        "XMLDOCUMENT(\n" +
        "XMLELEMENT(NAME \"itemlist\", \n" +
        "XMLELEMENT(NAME \"PartID\", l.ProdID),\n" +
        "XMLELEMENT(NAME \"Description\", p.Description ),\n" +
        "XMLELEMENT(NAME \"Quantity\", l.Quantity),\n" +
        "XMLELEMENT(NAME \"Price\", p.Price)))\n" +
        "FROM purchaseorder_relational AS po, lineitem_relational AS l,\n" +
              "products_relational AS P\n" +
        "WHERE l.PoNum=po.PoNum AND l.ProdID=P.ProdID)\n");
       
      stmt.executeUpdate(
        "INSERT INTO purchaseorder_new(PoNum, OrderDate, CustID, Status, LineItems) " +
        "(SELECT Po.PoNum, OrderDate, CustID, Status, " +
        "XMLDOCUMENT( " +
        "XMLELEMENT(NAME \"itemlist\", " +
        "XMLELEMENT(NAME \"PartID\", l.ProdID), " +
        "XMLELEMENT(NAME \"Description\", p.Description ), " +
        "XMLELEMENT(NAME \"Quantity\", l.Quantity), " +
        "XMLELEMENT(NAME \"Price\", p.Price))) " +
        "FROM purchaseorder_relational AS po, lineitem_relational AS l, " +
        "     products_relational AS P " +
        "WHERE l.PoNum=po.PoNum AND l.ProdID=P.ProdID)");

      System.out.println();
      
      ResultSet rs = stmt.executeQuery(
	"SELECT po.PoNum, po.CustId, po.OrderDate, " +
        "XMLELEMENT(NAME \"PurchaseOrder\", " +
        "XMLATTRIBUTES(po.CustID AS \"CustID\", po.PoNum AS \"PoNum\", " +
        "              po.OrderDate AS \"OrderDate\", po.Status AS \"Status\")), " +
        "XMLELEMENT(NAME \"Address\", c.Address), " +
        "XMLELEMENT(NAME \"lineitems\", po.LineItems) " +
        "FROM PurchaseOrder_new AS po, CustomerInfo_new AS c " +
        "WHERE  po.custid = c.custid " +
        "ORDER BY po.custID");
 
      int CustId = 0;
      int PoNum = 0;
      String OrderDate = "";
      String PurchaseOrder = "";
      String Address = "";
      String LineItem = "";
      String Name = "";
      String Street= "";
      String City = "";
      String Province = "";
      int PostalCode = 0;

      while (rs.next())
      {
        PoNum = rs.getInt(1);
        CustId = rs.getInt(2);
        OrderDate = rs.getString(3);
        PurchaseOrder = rs.getString(4);
        Address = rs.getString(5);
        LineItem = rs.getString(6);
        
        System.out.println("    " +
                           "\n Customer ID             : " +
                           Data.format(CustId, 8) + " " +
                           "\n Purchase Order Number   : " +
                           Data.format(PoNum, 8) + " " +
                           "\n Purchase Order Date     : " +
                           Data.format(OrderDate, 11) + " " +
                           "\n Purchase Order Document : \n" +
 			   Data.format(PurchaseOrder, 1000) + " " +
                           "\n Address in XML Format: \n" +
                           Data.format(Address, 500) + " " +
                           "\n Line Item in XML Format\n" +
                           Data.format(LineItem, 500));
      }
      rs.close();
      
      // Rollback the changes
      con.rollback();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } //execQuery
} // RelToXmlType


