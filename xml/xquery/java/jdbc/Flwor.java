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
// SOURCE FILE NAME: Flwor.java
//
// SAMPLE: How to use XQuery FLWOR expressions
//
// SQL Statements USED:
//         SELECT
//
// JAVA 2 CLASSES USED:
//         Statement
//         PreparedStatement
//         ResultSet
//
// SQL/XML FUNCTIONS USED:
//                xmlcolumn
//                xmlquery
//
// XQuery function used:
//                data
//                string 
//
// OUTPUT FILE: Flwor.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//***************************************************************************
//
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// For information on using XQuery statements, see the XQuery Reference.
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

class Flwor
{
  private static int cid=1002;
  private static String country="US";
  private static float price=10;
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
      {}
      System.exit(1);
    }
    catch(Exception e)
    {}
    System.out.println("----------------------------------------------------------------");
    System.out.println("Return customer information in alphabetical order by customer name .....");
    orderCustDetails(con);
    
    System.out.println("----------------------------------------------------------------");
    System.out.println("Return information for customers whose customer ID is greater than "+ cid +".....");
    conditionalCustDetails1(con, cid);

    System.out.println("----------------------------------------------------------------");
    cid=1000;
    System.out.println("Return information for customers whose customer ID is greater than  "+ cid +" and"); 
    System.out.println(" who do not live in country "+ country +".....");
    conditionalCustDetails2(con, cid, country);

    System.out.println("----------------------------------------------------------------");
    System.out.println("Select the product with maximun price......");
    maxpriceproduct(con);

    System.out.println("----------------------------------------------------------------");
    System.out.println("Select the product with basic price "+ price +"........");
    basicproduct(con, price);    
  } //main

  // The orderCustDetails method returns customer information in alphabetical order by customer name 
  static void orderCustDetails(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();
      String query="XQUERY "+
                   "for $custinfo in db2-fn:xmlcolumn('CUSTOMER.INFO')"+
                             "/customerinfo[addr/@country=\"Canada\"]"+
                             " order by $custinfo/name,fn:number($custinfo/@Cid)"+
                             " return $custinfo";
      System.out.println(); 
      System.out.println(query);          
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result from the XQUERY statement
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        
        // Print the result as DB2 XML String
      
        System.out.println();
        System.out.println(data.getDB2XmlString());  
      }
      
      // Close the result set
      rs.close();
      
      // Close the statement object
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
  } // orderCustDetails
  
  // The conditionalCustDetails1 returns information for customers whose customer ID is greater than
  // the cid value passed as an argument  
  static void conditionalCustDetails1(Connection con, int cid)
  {
    try
    {
      Statement stmt = con.createStatement();
      String query="select xmlquery('"+
                              " for $customer in $cust/customerinfo"+
                              " where ($customer/@Cid > $id)"+
                              " order by $customer/@Cid "+
                              " return <customer id=\"{$customer/@Cid}\">"+
                              " {$customer/name} {$customer/addr} </customer>'"+
                              " passing by ref customer.info as \"cust\", cast(? as integer) as \"id\")"+
                              " from customer ORDER BY cid";      
      System.out.println();
      System.out.println(query);
 
      // Prepare the statement
      PreparedStatement pstmt = con.prepareStatement(query);
      
      // Set the value for the parameter marker
      System.out.println("Set the paramter value: "+ cid);
      pstmt.setInt(1,cid);
      ResultSet rs = pstmt.executeQuery();

      // retrieve and display the result from the XQUERY statement
      while (rs.next())
      {
         // Retrive the data a binary stream  
         InputStream data=rs.getBinaryStream(1);
        
         System.out.println();
       
         // print the result
         dispValue(data);
      }
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
  } // conditionalCustDetails1
  
  // The conditionalCustDetails2 method returns information for customers whose customer ID is greater than
  //  the cid value passed to the function and who dont live in the country 
  static void conditionalCustDetails2(Connection con, int cid, String country)
  {
    try
    {
      Statement stmt = con.createStatement();
      String query="select xmlquery('"+
                               " for $customer in db2-fn:xmlcolumn(\"CUSTOMER.INFO\")/customerinfo"+
                               " where (xs:integer($customer/@Cid) > $id) and ($customer/addr/@country !=$c)"+
                               " order by $customer/@Cid "+
                               " return <customer id=\"{fn:string($customer/@Cid)}\">"+
                               " {$customer/name}"+
                               " <address>{$customer/addr/street}"+
                               " {$customer/addr/city} </address></customer>'"+
                               " passing by ref cast(? as integer) as \"id\","+
                               " cast(? as varchar(10)) as \"c\")"+
                               " from  SYSIBM.SYSDUMMY1";
      System.out.println();
      System.out.println(query);
      
      // Prepare the statement    
      PreparedStatement pstmt = con.prepareStatement(query);
      
      // Set the first parameter marker
      System.out.println();
      System.out.println("Set the first parameter value : "+ cid);
      pstmt.setInt(1,cid);
      
      // Set the second parameter marker
      System.out.println(); 
      System.out.println("Set the second parameter value: "+ country);
      pstmt.setString(2,country);     
      ResultSet rs = pstmt.executeQuery();

      // retrieve and display the result from the query 
      while (rs.next())
      {
        // retrieve the data as a string object 
        String data= rs.getString(1);
        System.out.println();
        System.out.println(data);
      }
      
      // Close the result set
      rs.close();
      
      // Close the statement object
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
  } // conditionalCustDetails2
  
  // The maxpriceproduct function returns the product details with maximun price 
  static void maxpriceproduct(Connection con)
  {
   try
    {
      Statement stmt = con.createStatement();
      String query="XQUERY "+
                   " let $prod := for $product in db2-fn:xmlcolumn('PRODUCT.DESCRIPTION')/product/description"+
                   " order by fn:number($product/price) descending return $product"+
                   " return <product> {$prod[1]/name} </product>";
      System.out.println();
      System.out.println(query);          
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result from the XQUERY statement
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        System.out.println();
        System.out.println(data.getDB2String());
      }
      
      // Close the result set
      rs.close();
      
      // Close the statement object
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
  } // maxpriceproduct
  
  // The basicproduct function returns the product with basic attribute value true
  // if the price is less then price parameter otherwiese false
  static void basicproduct(Connection con, double price)
  {
    try
    {
      Statement stmt = con.createStatement();
      String query="select xmlquery('"+
                   "for $prod in db2-fn:xmlcolumn(\"PRODUCT.DESCRIPTION\")/product/description"+
                   " order by $prod/name "+
                   " return ( if ($prod/price < $price)"+
                   " then <product basic = \"true\">{fn:data($prod/name)}</product>"+
                   " else <product basic = \"false\">{fn:data($prod/name)}</product>)'"+
                   " passing by ref cast(? as float) as \"price\")"+ 
                   " from SYSIBM.SYSDUMMY1";
      System.out.println();
      System.out.println(query);
      
      // Prepare the statement          
      PreparedStatement pstmt = con.prepareStatement(query);
      
      // Set the parameter value
      System.out.println("Set the parameter value: "+ price);
      pstmt.setDouble(1,price);
      ResultSet rs = pstmt.executeQuery();

      // retrieve and display the result from the XQUERY statement
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        
        // print the result as DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        
      }
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
  } // basicproduct

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

} // Flwor
