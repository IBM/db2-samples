/***************************************************************************
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
// SOURCE FILE NAME: SqlXQuery.java
//
// SAMPLE: How to run SQL/XML Queries
//
// SQL Statements USED:
//         SELECT
//
// JAVA 2 CLASSES USED:
//         Statement
//         PreparedStatement
//         ResultSet
//
// SQL/XML STATEMENTS USED:
//                XMLQUERY              
//                XMLEXISTS
//
//
// OUTPUT FILE: SqlXQuery.out (available in the online documentation)
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
import com.ibm.db2.jcc.DB2Xml;

class SqlXQuery
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
    
    System.out.println("---------------------------------------------------------------------------");
    custName="Robert Shoemaker";
    System.out.println("RETURN THE FIRST ITEM IN THE PURCHASEORDER FOR THE CUSTOMER "+custName+"......");
    System.out.println();
    firstPO1(con,custName); 
    
    System.out.println("---------------------------------------------------------------------------");
    System.out.println("RETURN THE FIRST ITEM IN THE PURCHASEORDER WHEN THE CUSTOMER IS IN SEQUENCE (X,Y,Z)");
    System.out.println("  AND CUSTOMER ID IN THE SEQUENCE (1001,1002,1003)   ........");
    System.out.println(); 
    firstPO2(con);
    
    System.out.println("--------------------------------------------------------------------------");
    System.out.println("SORT THE CUSTOMERS ACCORDING TO THE NUMBER OF PURCHASEORDERS...........");
    System.out.println();
    sortCust_PO(con);   
    
    System.out.println("---------------------------------------------------------------------------");
    partID="100-101-01";
    System.out.println("RETURN THE NUMBER OF PURCHASEORDER FOR THE CUSTOMER "+custName+" HAVING THE");
    System.out.println(" PARTID " + partID +"......"); 
    System.out.println();
    numPO(con, custName, partID);

  } //main
  
  // The firstPO1 function returns the first item in the purchase order for customer custName passed as an argument
  static void firstPO1(Connection con, String custName)
  {
  try
    {
      Statement stmt = con.createStatement();
      String query="SELECT XMLQUERY('$p/PurchaseOrder/item[1]' PASSING p.porder AS \"p\")"+
           " FROM purchaseorder AS p, customer AS c"+
           " WHERE XMLEXISTS('$custinfo/customerinfo[name=$c and @Cid = $cid]'"+
           " PASSING c.info AS \"custinfo\", p.custid AS \"cid\", cast(? as varchar(20)) as \"c\")";
      
      System.out.println(query);
      
      // Prepare the SQL/XML query
      PreparedStatement pstmt = con.prepareStatement(query);
      
      // Set the value of parameter marker
      System.out.println();
      System.out.println("Set the value of the parameter : " + custName);
      pstmt.setString(1,custName);
      
      ResultSet rs = pstmt.executeQuery();

      // retrieve and display the result from the SQL/XML statement
      while (rs.next())
      {
        // retrieve the data as character stream 
        java.io.Reader data= rs.getCharacterStream(1);
        
        // Print the result 
        System.out.println();
        char[] readerData=new char[500];
        data.read(readerData);
        System.out.println(readerData);
        
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
    catch (IOException e) {System.out.println("Error Msg: "+ e.getMessage());
                                   e.printStackTrace();} 
  } // firstPO1	
  
  // The firstPO2 function returns the first item in the purchaseorder when
  //  Name is from the sequence (X,Y,Z)
  // or the customer id is from the sequence (1000,1002,1003) 
  static void firstPO2(Connection con)
  {
  try
    {
      Statement stmt = con.createStatement();
      String query="SELECT cid, XMLQUERY('$custinfo/customerinfo/name' passing c.info as \"custinfo\"),"+
                  "XMLQUERY('$p/PurchaseOrder/item[1]' passing p.porder as \"p\"),"+
                  "XMLQUERY('$x/history' passing c.history as \"x\")"+
                  " FROM purchaseorder as p,customer as c"+
                  " WHERE XMLEXISTS('$custinfo/customerinfo[name=(X,Y,Z)"+
                  " or @Cid=(1000,1002,1003) and @Cid=$cid ]'"+
                  " PASSING c.info AS \"custinfo\", p.custid AS \"cid\") ORDER BY cid";
      
      System.out.println(query);
      
      // Execute the query
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result from the SQL/XML statement
      while (rs.next())
      {
        // Retrieve the customer id
        int cid=rs.getInt(1);
          
        // Retrieve the name of the customer as a string object
        String name=rs.getString(2);
	      
        // Retrieve the first item in the purchaseorder for the customer 
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(3);
	      
        // Retrieve the history for the customer
        com.ibm.db2.jcc.DB2Xml history=(com.ibm.db2.jcc.DB2Xml) rs.getObject(4);
        
        System.out.println();
        System.out.println(); 
        // Print the customer id 
        System.out.println("Cid:"+ cid);
        
        // Print the name as DB2 String
        System.out.println("Name:"+ name);
        
        // Print the first item in the purchaseorder as DB2 XML String
        System.out.println("First Item in purchaseorder : " + data.getDB2XmlString());
        
        // Print the history of the customer as DB2 XML String
        System.out.println("History:" + history.getDB2XmlString());  
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
  } // firstPO2
  
  // The sortCust_PO function sort the customers according to the number of purchaseorders
  static void sortCust_PO(Connection con)
  {
  try
    {
      int count=0;
	  Statement stmt = con.createStatement();
      String query="WITH count_table AS ( SELECT count(poid) as c,custid"+
                   " FROM purchaseorder,customer"+
                   " WHERE cid=custid group by custid )"+
            " SELECT c, xmlquery('$s/customerinfo[@Cid=$id]/name'"+
                                 " passing customer.info as \"s\", count_table.custid as \"id\")"+
            " FROM customer,count_table"+
            " WHERE custid=cid ORDER BY custid";

      System.out.println(query);
      
      // Execute the query
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result from the SQL/XML statement
      while (rs.next())
      {
        // Retrieve the count 
        count = rs.getInt(1);
        
        // Retrieve the Customer name as a binary stream
       InputStream name= rs.getBinaryStream(2);
        
        System.out.println(); 
        // Print the customer names in order of number of purchase orders
        System.out.println("COUNT : " + count + "  CUSTOMER : " );
        dispValue(name);
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
  } // sortCust_PO
  
  // The numPO function returns the number of purchaseorder having specific partid
  // for the specific customer passed as an argument to the function
  static void numPO(Connection con, String name, String partId)
  {
   try
    {
      Statement stmt = con.createStatement();
      String query="WITH cid_table AS (SELECT Cid FROM customer"+
                " WHERE XMLEXISTS('$custinfo/customerinfo[name=$name]'"+
                                  " PASSING customer.info AS \"custinfo\", cast(? as varchar(20)) as \"name\"))"+
                " SELECT count(poid) FROM purchaseorder,cid_table"+
                " WHERE XMLEXISTS('$po/PurchaseOrder/item[partid=$id]'"+
                                  " PASSING purchaseorder.porder AS \"po\", cast(? as varchar(20)) as \"id\")"+
                " AND purchaseorder.custid=cid_table.cid";
      
      System.out.println(query);  
      
      // Prepare the statement
      PreparedStatement pstmt = con.prepareStatement(query);
      
      // Set the first parameter value value
      System.out.println(); 
      System.out.println("set the first parameter value : " + name);
      pstmt.setString(1,name);
      
      // Set the second parameter value
      System.out.println(); 
      System.out.println("set the second paramter value : " +partId);
      pstmt.setString(2,partId);
      
      ResultSet rs = pstmt.executeQuery();

      // retrieve and display the result from the SQL/XML statement
      while (rs.next())
      {
        int count=rs.getInt(1);
        
        // Print the number of purchase order
        System.out.println("Number of purchase order with partid " + partId + " for customer " + name +" : " + count);  
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
  }     // numPO

  public static void dispValue(InputStream in)
  {
        int size;
        byte buf;
        int count = 0;
        try
        {
             size = in.available();
             byte ary[] = new byte[size];
             buf = (byte) in.read();
             while(buf!=-1)
            {
                  ary[count] = buf;
                  count++;
                  buf = (byte) in.read();
            }
            System.out.println(new String(ary));
        }
        catch (Exception e)
        {
             System.out.println("Error occured while reading stream ... \n");
        }

  } // dispValue
} // SqlXQuery
