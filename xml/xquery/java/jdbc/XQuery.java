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
// SOURCE FILE NAME: XQuery.java
//
// SAMPLE: How to run an nested XQuery and shows how to pass parameters to
//         sqlquery function.
//
// XQUERY EXPRESSION USED
//         FLWOR Expression
//
// JAVA 2 CLASSES USED:
//         Statement
//         PreparedStatement
//         ResultSet
//
//
// OUTPUT FILE: XQuery.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//***************************************************************************
//
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using XQUERY statements, see the XQUERY Reference.
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

class XQuery
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
   
   
   System.out.println("-------------------------------------------------------------");
   System.out.println("RESTRUCTURE THE PURCHASEORDERS ACCORDING TO THE CITY....");
   System.out.println();
   PO_OrderByCity(con);

   System.out.println("-------------------------------------------------------------"); 
   System.out.println("RESTRUCTURE THE PURCHASEORDER ACCORDING TO THE PRODUCT.....");
   System.out.println();
   CustomerOrderByProduct(con);
   
   System.out.println("-------------------------------------------------------------"); 
   System.out.println("RESTRUCTURE THE PURCHASEORDER DATA ACCORDING TO PROVIENCE, CITY AND STREET..");
   System.out.println();
   PO_OrderByProvCityStreet(con);
   System.out.println("-------------------------------------------------------------");
   System.out.println("COMBINE THE DATA FROM PRODUCT AND CUSTOMER TABLE TO CREATE A PURCHASEORDER..");
   CustomerPO(con);
  } // main
  
  // The PO_OrderByCity method returns the purchaseorder city wise 
  static void PO_OrderByCity(Connection con)
  {
  try
    {
      Statement stmt = con.createStatement();
      String query="XQUERY for $city in fn:distinct-values(db2-fn:xmlcolumn('CUSTOMER.INFO')"+
            "/customerinfo/addr/city)"+
             " return"+
               " <city name='{$city}'>"+
               "{"+
                 " for  $cust in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[addr/city=$city]"+
                 " let $po:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME \"\"pos\"\","+
                                              " (XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", c.custid),"+
                                                           "XMLELEMENT(NAME \"\"order\"\", c.porder)"+
                                                               "    ) ))"+
                                   " FROM purchaseorder AS c\")"+
         " let $id:=$cust/@Cid,"+
             " $order:=$po/pos[custid=$id]/order" +
         " return"+
         " <customer id='{$id}'>"+
          " {$cust/name}"+
          " {$cust/addr}"+
          " {$order}"+
         " </customer>}"+
        " </city>";
                       
      System.out.println(query);
      
      // Execute the query
     PreparedStatement pstmt = con.prepareStatement(query); 
     ResultSet rs = pstmt.executeQuery();
      
      // Retrieve and display the result from the query
      while (rs.next())
      {
       com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        
       // Print the result as an DB2 XML String
       System.out.println();
       System.out.println(data.getDB2XmlString());
      }
  
      System.out.println("\n\nThe following query shows how to pass parameters to ");
      System.out.print(" sqlquery function which is an enhancement in Viper2");
      System.out.println("\n-------------------------------------------------\n"); 

      // In Viper2 the above query can be written as follows.
      query = "XQUERY "+
              "for $city in fn:distinct-values(db2-fn:xmlcolumn('CUSTOMER.INFO') /customerinfo/addr/city)"+
              "return"+
                "<city name='{$city}'>"+
                "{"+
                   "for  $cust in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo [addr/city=$city]"+
                   "let $po:=db2-fn:sqlquery(\"SELECT porder FROM PURCHASEORDER "+
                                             "WHERE custid=parameter(1)\",$cust/@Cid),"+
                     "  $order:=$po/order"+
                   " return"+
                   " <customer id = '{$cust/@Cid}'>"+
                     " {$cust/name}"+
                     " {$cust/Addr}"+
                     " {$order}"+
                     " </customer>}"+
                " </city>";
        System.out.println("\n----------------------------------");
        System.out.println(query);
        System.out.println("\n----------------------------------");

      // Execute the query
      PreparedStatement pstmt1 = con.prepareStatement(query);
      ResultSet rs1 = pstmt1.executeQuery();

      // Retrieve and display the result from the query
      while (rs1.next())
      {
       com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs1.getObject(1);

       // Print the result as an DB2 XML String
       System.out.println();
       System.out.println(data.getDB2XmlString());
      }
 
      // Close the result set and statement
      rs.close();
      rs1.close();
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
  } // PO_OrderByCity
  
  // This CustomerOrderByProduct function returns the  purchaseorders product wise
  static void CustomerOrderByProduct(Connection con)
  {
  try
    {
      Statement stmt = con.createStatement();
      String query="XQUERY let $po:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME \"\"pos\"\","+
                                                        "( XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", c.custid),"+
                                                                     "XMLELEMENT(NAME \"\"order\"\", c.porder)"+
                                                       " ) ))"+
                                     " FROM purchaseorder AS c\" )"+
                  " for $partid in fn:distinct-values(db2-fn:xmlcolumn('PURCHASEORDER.PORDER')/PurchaseOrder/item/partid)"+
                    " return"+
                    " <Product name='{$partid}'>"+
                     " <Customers>"+
                       " {"+
                         " for  $id in fn:distinct-values($po[order/PurchaseOrder/item/partid=$partid]/custid)"+
                         " let  $order:=<quantity>"+
                         " {fn:sum($po[custid=$id]/order/PurchaseOrder/item[partid=$partid]/quantity)}"+
                         " </quantity>,"+
                       " $cust:=db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo[@Cid=$id]"+
                     " return"+
                     " <customer id='{$id}'>"+
                       " {$order}"+
                       " {$cust}"+
                     " </customer>"+
                     " }"+
                  " </Customers>"+
                 "</Product>";
 
      System.out.println(query);
      System.out.println();
 
      // Execute the query
      ResultSet rs = stmt.executeQuery(query);
      
      // retrieve and display the result from the XQuert statement
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        
        // Print the result as an DB2 XML string
        System.out.println();
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
  } // CustomerOrderByProduct
  
  
  // This PO_OrderByProvCityStreet function returns the purchaseorder province, city and stree wise
  static void PO_OrderByProvCityStreet(Connection con)
  {
	  try
    {
      Statement stmt = con.createStatement();
      String query="XQUERY let $po:=db2-fn:sqlquery(\"SELECT XMLELEMENT( NAME \"\"pos\"\","+
                                          "( XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", c.custid),"+
                                          "XMLELEMENT(NAME \"\"order\"\", c.porder)"+
                                                       ") ))"+
                                           " FROM PURCHASEORDER as c\"),"+
       " $addr:=db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo/addr"+
       " for $prov in distinct-values($addr/prov-state)"+
       " return"+
       " <province name='{$prov}'>"+
       " {"+
         " for $city in fn:distinct-values($addr[prov-state=$prov]/city)"+
         " return"+
         " <city name='{$city}'>"+
         " {"+
           " for $s in fn:distinct-values($addr/street) where $addr/city=$city"+
           " return"+
           " <street name='{$s}'>"+
           " {"+
             " for $info in $addr[prov-state=$prov and city=$city and street=$s]/.."+
             " return"+
             " <customer id='{$info/@Cid}'>"+
             " {$info/name}"+
             " {"+
               " let $id:=$info/@Cid, $order:=$po[custid=$id]/order"+
               " return $order"+
             " }"+
            " </customer>"+
           " }"+
           " </street>"+
         " }"+
          " </city>"+
       " }"+
       " </province>";
              
      System.out.println(query);
      
      // Execute the query
      ResultSet rs = stmt.executeQuery(query);
      
      // retrieve and display the result from the XQuert statement
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        
        // Print the result as an DB2 XML String
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
  }
  
  // The CustomerPO function creates the purchaseorder XML document 
  static void CustomerPO(Connection con)
  {
  try
    {
      Statement stmt = con.createStatement();
      String query="XQUERY <PurchaseOrder>"+
                    "{"+
                        " for $ns1_customerinfo0 in db2-fn:xmlcolumn('CUSTOMER.INFO')/customerinfo"+
                        " where ($ns1_customerinfo0/@Cid=1001)"+
                        " return"+
                        " <customer customerid='{ fn:string( $ns1_customerinfo0/@Cid)}'>"+
                        " {$ns1_customerinfo0/name}"+
                            " <address>"+
                              " {$ns1_customerinfo0/addr/street}"+
                              " {$ns1_customerinfo0/addr/city}"+
                              " {"+
                                 " if($ns1_customerinfo0/addr/@country=\"US\")"+
                                 " then"+
                                  " $ns1_customerinfo0/addr/prov-state"+
                                  " else()"+
                              " }"+
                               " {"+ 
                   " fn:concat ($ns1_customerinfo0/addr/pcode-zip/text(),\",\",fn:upper-case($ns1_customerinfo0/addr/@country))}"+
                           " </address>"+
                          " </customer>"+
                        " }"+
                        " {"+
                         " for $ns2_product0 in db2-fn:xmlcolumn('PRODUCT.DESCRIPTION')/product"+
                         " where ($ns2_product0/@pid=\"100-100-01\")"+
                         " return"+
                         " $ns2_product0"+  
                     " }"+
                   " </PurchaseOrder>";
 
      System.out.println(query);
      System.out.println();

      // Execute the query
      ResultSet rs = stmt.executeQuery(query);

      // retrieve and display the result from the XQuert statement
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data=(com.ibm.db2.jcc.DB2Xml) rs.getObject(1);

        // Print the result as an DB2 XML string
        System.out.println();
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
	  
  } 
} // XQuery 
