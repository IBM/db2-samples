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
// SOURCE FILE NAME: XmlToTable.java
//
// SAMPLE USAGE SCENARIO:Purchase order XML document contains detailed
// information about all the orders. It will also have the detail of the
// customer with each order.
//
// PROBLEM: The document has some redundant information as customer info
// and product info is repeated in each order for example
// Customer info is repeated for each order from same customer.
// Product info will be repeated for each order of same product from different customers.
//
// SOLUTION: The sample database has tables with both relational and XML data to remove
// this redundant information. These relational tables will be used to store
// the customer info and product info in the relational table having XML data
// and id value. Purchase order will be stored in another table and it will
// reference the customerId and productId to refer the customer and product
// info respectively.
//
// To achieve the above goal this sample will shred the data for purchase order XML
// document and insert it into the tables.
//
// The sample will follow the following steps
//
// 1. Get the relevant data in XML format from the purchase order XML document (use XMLQuery)
// 2. Shred the XML doc into the relational table. (Use XMLTable)
// 3. Select the relevant data from the table and insert into the target relational table.
//
// EXTERNAL DEPENDENCIES:
//     For successful precompilation, the sample database must exist
//     (see DB2's db2sampl command).
//     XML Document purchaseorder.xml must exist in the same directory as of this sample 
//  
// SQL Statements USED:
//         SELECT
//         INSERT
//
// XML Functions USED:
//         XMLCOLUMN
//         XMLELEMENT
//         XMLTABLE
//         XMLDOCUMENT
//         XMLATTRIBTES
//         XMLCONCAT
//         XQUERY
//
// Classes used from Util.java are:
//         Db
//         SqljException
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
import java.io.*;
import java.util.*;

class XmlToTable
{
 static int num_record_customer=0;
 static int num_record_po=0;
 public static void main(String argv[])
  {
     String url = "jdbc:db2:sample";
     Connection con=null;
    try
    {
     Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
     con = DriverManager.getConnection( url ); 
     System.out.println();
      // connect to the 'sample' database
      PO_shred(con);
      displayContent(con); 
      cleanUp(con);
  
    } catch (SQLException sqle)
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
 }// main

 static void displayContent(Connection con)
 {
   try
   {
     String stmt="SELECT cid, info FROM customer ORDER BY cid";
     Statement stmt1 = con.createStatement();
     Statement stmt2 = con.createStatement();

     // Execute the select statement
     ResultSet rs = stmt1.executeQuery(stmt);
     
     while (rs.next())
      {
        int cid=rs.getInt(1); 
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(2);

        // Print the result
        System.out.println();
        System.out.println("CID :"+ cid +" INFO :" + data.getDB2XmlString());
      }

      // Close the result set
      rs.close();

      // Close the statement
      stmt1.close();
 
     stmt= "SELECT poid, porder FROM purchaseorder ORDER BY poid";
     rs=stmt2.executeQuery(stmt);

     while (rs.next())
      {
        int poid=rs.getInt(1);
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(2);

        // Print the result
        System.out.println();
        System.out.println("POID :"+ poid +" PORDER :" + data.getDB2XmlString());
      }

      // Close the result set
      rs.close();

      // Close the statement
      stmt2.close();
      
   }
   catch (SQLException sqle)
   {
     System.out.println("Error Msg: "+ sqle.getMessage());
     System.out.println("SQLState: "+sqle.getSQLState());
     System.out.println("SQLError: "+sqle.getErrorCode());
     System.out.println("Rollback the transaction and quit the program");
     System.out.println();
     try { con.rollback(); }
     catch (Exception e) {}
     System.exit(1);
   }
 } // displayContent
 
 static void cleanUp(Connection con)
 {
   try
   {
     String stmt="DELETE FROM CUSTOMER WHERE CID IN (10,11)";
     Statement stmt1 = con.createStatement();     
     
     // delete from customer
     System.out.println(stmt);
     stmt1.executeUpdate(stmt);
     
     stmt="DELETE FROM PURCHASEORDER WHERE POID IN (110,111)";
     // delete from purchaseorder
     System.out.println(stmt);
     stmt1.executeUpdate(stmt);
   }
   catch (SQLException sqle)
   {
     System.out.println("Error Msg: "+ sqle.getMessage());
     System.out.println("SQLState: "+sqle.getSQLState());
     System.out.println("SQLError: "+sqle.getErrorCode());
     System.out.println("Rollback the transaction and quit the program");
     System.out.println();
     try { con.rollback(); }
     catch (Exception e) {}
     System.exit(1);
   }
 } // cleanUp
 
 static void PO_shred(Connection con)
 {
   String data=new String();
   String custInsert = new String();
   String POInsert = new String(); 
 
   try 
   {
     Statement stmt1 = con.createStatement();
     Statement stmt2 = con.createStatement();
  
     // create PO table 
     stmt1.executeUpdate("CREATE TABLE PO (id INT GENERATED ALWAYS AS IDENTITY,purchaseorder XML)");
     PreparedStatement pstmt2;
     PreparedStatement pstmt1=con.prepareStatement("insert into PO(purchaseorder) values(?)");
     pstmt1.setString(1,returnFileValues("purchaseorder.xml"));
     pstmt1.executeUpdate();
  
     // run the XQuery to find out the purchaseorder with status shipped
     ResultSet rs=stmt1.executeQuery("XQUERY db2-fn:xmlcolumn('PO.PURCHASEORDER')/PurchaseOrders/PurchaseOrder[@Status='shipped']"); 
  
     custInsert="INSERT INTO customer(CID,info,history)"+
                       " SELECT T.CustID,xmldocument" +
                       "(XMLELEMENT(NAME \"customerinfo\",XMLATTRIBUTES (T.CustID as \"Cid\"),"+
                       " XMLCONCAT(" +
                       " XMLELEMENT(NAME \"name\", T.Name ), T.Addr,"+
                       " XMLELEMENT(NAME \"phone\", XMLATTRIBUTES(T.type as \"type\"), T.Phone)"+
                       " ))), xmldocument(T.History)"+
                       " FROM XMLTABLE( '$d/PurchaseOrder' PASSING cast(? as XML)  AS \"d\""+
                       " COLUMNS CustID BIGINT PATH  '@CustId',"+
                       " Addr      XML                 PATH './Address',"+
                       " Name     VARCHAR(20)       PATH './name',"+
                       " Country  VARCHAR(20)  PATH './Address/@country',"+
                       " Phone    VARCHAR(20)  PATH './phone',"+
                       " Type     VARCHAR(20) PATH './phone/@type',"+
                       " History XML PATH './History') as T"+
                       " WHERE T.CustID NOT IN (SELECT CID FROM customer)";

     System.out.println("INSERT INTO CUSTOMER TABLE USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED\n");
     System.out.println(custInsert);

     POInsert = "INSERT INTO purchaseOrder(poid, orderdate, custid,status, porder, comments)"+
                        " SELECT poid, orderdate, custid, status,xmldocument(XMLELEMENT(NAME \"PurchaseOrder\","+
                                                         " XMLATTRIBUTES(T.Poid as \"PoNum\", T.OrderDate as \"OrderDate\","+
                                                          "  T.Status as \"Status\"),"+
                                                  "T.itemlist)), comment"+
                        " FROM XMLTable ('$d/PurchaseOrder' PASSING cast(? as XML)  as \"d\""+
                        " COLUMNS poid BIGINT PATH '@PoNum',"+
                        " orderdate date PATH '@OrderDate',"+
                        " CustID BIGINT PATH '@CustId',"+
                        " status varchar(10) PATH '@Status',"+
                        " itemlist XML PATH './itemlist',"+
                        " comment varchar(1024) PATH './comments') as T";

     System.out.println("\n INSERT INTO PURCHASE ORDER USING FOLLOWING QUERY FOR EACH PURCHASEORDER SELECTED\n");
     System.out.println(POInsert);

     // iterate for all the rows, insert the data into the relational table 
     while(rs.next())
     {
       data=rs.getString(1);
       // insert into customer table
       System.out.println("Inserting into customer table ....");
       pstmt2=con.prepareStatement(custInsert);
       
       // bind the parameter value 
       pstmt2.setString(1,data);
       pstmt2.executeUpdate();
       num_record_customer++;

       // insert into purchaseorder table 
       System.out.println("Inserting into purchaseorder table .....\n");
       pstmt2=con.prepareStatement(POInsert);
       pstmt2.setString(1,data);
       pstmt2.executeUpdate();
       num_record_po++;
     
     }// while loop
    
    // drop table po
    stmt2.executeUpdate("DROP TABLE PO");
   }
   catch (SQLException sqle)
   {
     System.out.println("Error Msg: "+ sqle.getMessage());
     System.out.println("SQLState: "+sqle.getSQLState());
     System.out.println("SQLError: "+sqle.getErrorCode());
     System.out.println("Rollback the transaction and quit the program");
     System.out.println();
     try { con.rollback(); }
     catch (Exception e) {}
     System.exit(1);
   }
 System.out.println("\nNumber of record inserted to customer table = " +num_record_customer);
 System.out.println("Number of record inserted to purchaseorder table = " +num_record_po); 
 
 }// PO_shred

 public static String returnFileValues(String fileName)
 {
   String record = null;
   try
   {
      FileReader fr     = new FileReader(fileName);
      BufferedReader br = new BufferedReader(fr);

      record = new String();
           
      record = br.readLine();
      String descReturn=record;
      while ((record = br.readLine()) != null)
          descReturn=descReturn+record;
          return descReturn;
   }
    catch (IOException e)
    {
    // catch possible io errors from readLine()
       System.out.println("     file " + fileName + "doesn't exist");
       System.out.println("     Can not continue with insert, please verify "+fileName+" and try again.");
       System.out.println("     Quitting program!");
       System.out.println();
       System.exit(-1);
    }
    return null;
 }// returnFileValues   
}// XmlToTable
