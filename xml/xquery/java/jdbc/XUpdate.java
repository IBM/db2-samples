///*************************************************************************
//   (c) Copyright IBM Corp. 2007 All rights reserved.
//   
//   The following sample of source code ("Sample") is owned by International 
//   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
//   copyrighted and licensed, not sold. You may use, copy, modify, and 
//   distribute the Sample in any form without payment to IBM, for the purpose of 
//   assisting you in the development of your applications.
//   
//   The Sample code is provided to you on an "AS IS" basis, without warranty of 
//   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
//   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
//   not allow for the exclusion or limitation of implied warranties, so the above 
//   limitations or exclusions may not apply to you. IBM shall not be liable for 
//   any damages you suffer as a result of using, copying, modifying or 
//   distributing the Sample, even if IBM has been advised of the possibility of 
//   such damages.
// *************************************************************************
//                                                                          
//  SAMPLE FILE NAME: XUpdate.java                                          
//                                                                          
//  PURPOSE:  To demonstrate how to insert, delete, update, replace, and rename 
//            one or more XML documents or document fragments using transform 
//            expressions. 
//                                                                          
//  USAGE SCENARIO: The orders made by customers are stored in the existing 
//                  PurchaseOrder system. A customer has ordered some items initially, 
//                  and now the customer wants to add some more items and remove some 
//                  items from the list. This sample will show how the order is modified 
//                  using the XQuery transform expression and updating expressions.                 
//                                                                          
//  PREREQUISITE: NONE
//                                                                          
//  EXECUTION:    javac XUpdate.java   (Compile the sample)
//                java XUpdate         (Run the sample)   
//                                                                          
//  INPUTS:       NONE
//                                                                          
//  OUTPUTS:      Successful updation of the purchase orders.
//                                                                          
//  OUTPUT FILE:  XUpdate.out (available in the online documentation)      
//                                     
//  SQL STATEMENTS USED:
//        INSERT
//        UPDATE  
//        DROP   
//
//  SQL/XML FUNCTIONS USED:                                                  
//        XMLQUERY                                                       
//  
// *************************************************************************
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
// *************************************************************************
//
//  SAMPLE DESCRIPTION                                                      
//
// *************************************************************************
//  1. Insert Expression  -- Insert a new element to the existing XML document/fragment. 
//  2. Delete Expression  -- Delete some elements from the exisitng XML document/fragment.
//  3. Replace value of Expression -- i)  Replace the value of an element 
//                                    ii) Replace the value of attribute
//  4. Replace Expression -- Replace an element and attribute
//  5. Rename Expression  -- i)  Rename an element in the existing XML document/fragment.
//                           ii) Rename an attribute in the existing XML document/fragment.
//  6. Insert and Replace Expressions -- Combination of transform expressions.
// *************************************************************************/

import java.lang.*;
import java.sql.*;
import java.io.*;
import java.util.*;
import com.ibm.db2.jcc.DB2Xml;

class XUpdate
{
  public static void main(String argv[])
  {
    int rc=0;
    String url = "jdbc:db2:sample";
    String custName=null;
    String partID=null;
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

    System.out.println("-----------------------------------------------------------------------");
    System.out.println("Insert Expression -- Insert a new element to the existing XML document/fragment.");
    System.out.println("-----------------------------------------------------------------------");
    System.out.println();
    insertExpr(con);

    System.out.println("-----------------------------------------------------------------------");
    System.out.println("Delete Expression  -- Delete some items from the exisitng XML document/fragment.");
    System.out.println("-----------------------------------------------------------------------");
    System.out.println();
    deleteExpr(con);

    System.out.println("-----------------------------------------------------------------------");
    System.out.println("Replace Expression -- Replace/replace value of an element/attribute of an XML document/fragment.");
    System.out.println("-----------------------------------------------------------------------");
    System.out.println();
    replaceExpr(con);

    System.out.println("-----------------------------------------------------------------------");
    System.out.println("Rename Expression -- Rename an element/attribute of an XML document/fragment.");
    System.out.println("-----------------------------------------------------------------------");
    System.out.println();
    renameExpr(con);

    System.out.println("-----------------------------------------------------------------------");
    System.out.println("Insert and Replace Expressions -- Combination of transform expressions.");
    System.out.println("-----------------------------------------------------------------------");
    System.out.println();
    combinationExpr(con);

  } //main

  static void insertExpr(Connection con)
  {
  try
    {
      Statement stmt = con.createStatement();

      // Insert an item into the XML document as last child of the PurchaseOrder
      String query="SELECT  xmlquery('transform copy $po := $order modify do insert document { <item> <partid>100-103-01</partid> <name>Snow Shovel, Super Deluxe 26 inch</name> <quantity>2</quantity> <price>49.99</price> </item> } as last into $po return  $po' passing purchaseorder.porder as \"order\") from purchaseorder where poid=5004";

      System.out.println("Query: \n" + query);

      // Execute the query
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result from the SQL/XML statement
      while (rs.next())
      {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        System.out.println();

        // Print the purchaseorder as DB2 XML String
        System.out.println("Data after inserting Item :\n" + data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt.close();
    }
    catch(SQLException sqle)
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
  } // insertExpr

static void deleteExpr(Connection con)
  {
  try
    {

      // Delete an item from the PurchaseOrder
      String query = "UPDATE purchaseorder SET porder = xmlquery('transform copy $po := $order modify do delete $po/PurchaseOrder/item[partid = ''100-201-01''] return  $po' passing porder as \"order\") WHERE poid=5004";

       System.out.println("Query: \n" + query);	
      // Execute the query
      Statement stmt1 = con.createStatement();    
      stmt1.executeUpdate(query);

      // retrieve and display the result
      stmt1 = con.createStatement(); 
      query = "SELECT porder FROM purchaseorder WHERE poid=5004"; 
      ResultSet rs = stmt1.executeQuery(query);

      while (rs.next())
      {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        System.out.println();

        // Print the purchaseorder as DB2 XML String
        System.out.println("Data after Deleting an Item : \n" + data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt1.close();
    }
    catch(SQLException sqle)
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
  } // deleteExpr

static void replaceExpr(Connection con)
  {
  try
    {
      System.out.println("------------------------------------------------------");
      System.out.println("Replace value of an element...");
      System.out.println("------------------------------------------------------");

      // Replace value of an element
      String query = "UPDATE purchaseorder SET porder = xmlquery('transform copy  $po := $order modify for $i in $po/PurchaseOrder/item[1]//price return do replace value of $i  with $i*0.8 return  $po' passing porder as \"order\") WHERE poid > 5004";
      System.out.println("Query: \n" + query);

      // Execute the query
     Statement stmt1 = con.createStatement(); 
     stmt1.executeUpdate(query);

     stmt1 = con.createStatement(); 
     query = "SELECT porder FROM purchaseorder WHERE poid > 5004"; 
     ResultSet rs = stmt1.executeQuery(query);

     System.out.println("Data after replacing value of an element : ");

     // retrieve and display the result 
     while (rs.next())
     {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        System.out.println();
        // Print the purchaseorder as DB2 XML String
        System.out.println(data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt1.close();

      System.out.println("------------------------------------------------------");
      System.out.println("Replace value of an attribute...");
      System.out.println("------------------------------------------------------");
    
      // Replace value of an attribute
      query = "UPDATE purchaseorder SET porder = xmlquery('transform copy $po := $order modify do replace value of $po/PurchaseOrder/@Status with \"Shipped\" return $po' passing porder as \"order\") WHERE poid < 5002";

      System.out.println("Query: \n" + query);
	
      // Execute the query
      stmt1 = con.createStatement(); 
      stmt1.executeUpdate(query);

      stmt1 = con.createStatement(); 
      query = "SELECT porder FROM purchaseorder WHERE poid < 5002"; 
      rs = stmt1.executeQuery(query);

      System.out.println("Data after replacing value of an attribute : ");
      // retrieve and display the result 
      while (rs.next())
      {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        System.out.println();

        // Print the purchaseorder as DB2 XML String
        System.out.println(data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt1.close();

      System.out.println("------------------------------------------------------");
      System.out.println("Replace an element and attribute...");
      System.out.println("------------------------------------------------------");

      // Replace an element and attribute
      query = "XQUERY for $k in db2-fn:sqlquery(\"select porder from purchaseorder where poid = 5004\") return transform copy $i := $k modify (do replace $i//PurchaseOrder/@OrderDate with ( attribute BilledDate {\"12-12-2007\"}), do replace $i//item[1]/price with $k//item[1]/price) return $i//PurchaseOrder";

      System.out.println("Query: \n" + query);
	
       stmt1 = con.createStatement();  
       rs = stmt1.executeQuery(query);
       System.out.println("Data after replacing an element and attribute : ");

      // retrieve and display the result 
      while (rs.next())
      {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        System.out.println();

        // Print the purchaseorder as DB2 XML String
        System.out.println(data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt1.close();
   
    }
    catch(SQLException sqle)
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
  } // replaceExpr

static void renameExpr(Connection con)
  {
  try
    {

      System.out.println("------------------------------------------------------");
      System.out.println("Rename an element...");
      System.out.println("------------------------------------------------------");

      // Rename an element
      String query = "UPDATE purchaseorder SET porder = xmlquery('transform copy $po := $order modify for $i in $po//item[quantity > 1] return do rename $i as \"items\" return  $po' passing porder as \"order\") WHERE poid=5002";

      System.out.println("Query: \n" + query);

      // Execute the query
      Statement stmt = con.createStatement();  
      stmt.executeUpdate(query);

      stmt = con.createStatement(); 
      query = "SELECT porder FROM purchaseorder WHERE poid=5002"; 
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result 
      while (rs.next())
      {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        System.out.println();

        // Peint the purchaseorder as DB2 XML String
        System.out.println("Data after renaming an element : \n " + data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt.close();

      System.out.println("------------------------------------------------------");
      System.out.println("Rename an attribute, insert a new attribute and rename an element...");         System.out.println("------------------------------------------------------");
 
      // Rename an attribute, Insert a new attribute and rename an element
      query = "XQUERY for $k in db2-fn:sqlquery(\"select porder from purchaseorder where poid=5003\") return transform copy $i := $k modify (do rename $i//*:PurchaseOrder/@OrderDate as \"BilledDate\", do insert attribute Totalcost {\"405.99\"} into $i//*:PurchaseOrder, do rename $i//*:PurchaseOrder//*:partid as \"productid\") return $i//*:PurchaseOrder";

      System.out.println("Query: \n" + query);
	
      stmt = con.createStatement();  
      rs = stmt.executeQuery(query);

      System.out.println("Data after rename element and attribute : ");

      // retrieve and display the result 
      while (rs.next())
      {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        System.out.println();

        // Print the purchaseorder as DB2 XML String
        System.out.println(data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt.close();
   
    }
    catch(SQLException sqle)
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
  } // renameExpr


static void combinationExpr(Connection con)
  {
  try
    {

      // Insert and Replace Expressions
      String query = " UPDATE purchaseorder SET porder = xmlquery ('transform copy   $po := $order modify ( for $i in $po/PurchaseOrder/item[1]//price return do replace value of $i with $i*0.8, do  insert document { <item> <partid>100-103-01</partid> <name>Snow Shovel, Super Deluxe 26 inch</name> <quantity>2</quantity> <price>49.99</price> </item> } as last into $po/PurchaseOrder) return  $po' passing porder as \"order\") WHERE poid = 5004 ";

      System.out.println("Query: \n" + query);
	
      // Execute the query
     Statement stmt = con.createStatement(); 
     stmt.executeUpdate(query);

      stmt = con.createStatement(); 
      query = "SELECT porder FROM purchaseorder WHERE poid=5004"; 
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result 
      while (rs.next())
      {
        // Retrieve the result of purchase order
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        System.out.println();

        // Print the purchaseorder as DB2 XML String
        System.out.println("Data after insert and replace: \n" + data.getDB2XmlString());
      }

      // Close the result set and statement object
      rs.close();
      stmt.close();
   
    }
    catch(SQLException sqle)
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
  } // combinationExpr

} // XUpdate

