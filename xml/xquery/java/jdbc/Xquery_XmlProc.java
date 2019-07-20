//*************************************************************************
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
//*************************************************************************
//
// SOURCE FILE NAME: Xquery_XmlProc.java
//
// SAMPLE: Code implementation of stored procedure Supp_XML_Proc_Java
//         The stored procedures defined in this program are called by the
//         client application Xquery_XmlProc_Client.java. Before building and 
//         running Xquery_XmlProc_Client.java, build the shared library by 
//         completing the following steps:
//
// Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system,
//            do the following:
//            1. Compile the server source file Xquery_XmlProc.java (this will 
//               also erase the existing library/class files and copy the newly
//               compiled class files, Xquery_XmlProc.class, from the current 
//               directory to the $(DB2PATH)\function directory):
//                 nmake/make Xquery_XmlProc
//            2. Compile the client source file Xquery_XmlProc_Client.java (this
//               will also call the script 'spcat_xquery' to create and catalog
//               the stored procedures):
//                 nmake/make Xquery_XmlProc_Client
//            3. Run the client Xquery_XmlProc_Client:
//                 java Xquery_XmlProc_Client
//
//         II) If you don't have a compatible make/nmake program on your
//             system do the following:
//             1. Compile the server source file with:
//                  javac Xquery_XmlProc.java
//             2. Erase the existing library/class files (if exists),
//                Xquery_XmlProc.class from the following path,
//                $(DB2PATH)\function.
//             3. Copy the class files, Xquery_XmlProc.class from the current
//                directory to the $(DB2PATH)\function.
//             4. Catalog the stored procedures in the database with the script:
//                  spcat_xquery
//             5. Compile Xquery_XmlProc_Client with:
//                  javac Xquery_XmlProc_Client.java
//             6. Run Xquery_XmlProc_Client with:
//                  java Xquery_XmlProc_Client
//
// Class Xquery_XmlProc contains one method which solves the following scenario:
//         Some of the suppliers have extended the promotional price date for
//         their products. Getting all the customer's Information who purchased
//         these products in the extended period will help the financial department
//         to return the excess amount paid by those customers. The supplier 
//         information along with extended date's for the products is provided 
//         in an XML document and the client wants to have the information
//         of all the customers who has paid the excess amount by purchasing those 
//         products in the extended period.
//
//         This procedure will return an XML document containing customer info
//         along with the the excess amount paid by them.
//
// SQL Statements USED:
//         CREATE
//         SELECT
//         INSERT 
//
// OUTPUT FILE: Xquery_XmlProc_Client.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//*************************************************************************
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

import java.sql.*;                 // JDBC classes
import java.io.*;                  // Input/Output classes
import java.lang.*;                // for String class
import COM.ibm.db2.app.StoredProc; // Stored Proc classes
import com.ibm.db2.jcc.DB2Xml;     // XML classes
import COM.ibm.db2.app.Clob;       // CLOB classes   
import java.math.BigDecimal;       // Basic Arithmetic  

// Java stored procedure in this class
public class Xquery_XmlProc extends StoredProc
{

  Connection con;
  public void  Xquery_Proc ( com.ibm.db2.jcc.DB2Xml inXML,
                             com.ibm.db2.jcc.DB2Xml outXML,
                             int retcode )
  throws Exception
  {
   String prodid = null ;
   java.sql.Date oldPromoDate = null;
   com.ibm.db2.jcc.DB2Xml orders = null;
   com.ibm.db2.jcc.DB2Xml tempXML = null;
   java.sql.Date newPromoDate = null;
   float originalPrice =0;
   float promoPrice =0;
   long custid=0;
   String partid = null;
   int quantity=0;
   float excessamount =0;
   String sql =null;
 
         // get caller's connection to the database
         con = DriverManager.getConnection("jdbc:default:connection");
         
         // get the input XML document into an application variable
         String ipdata = inXML.getDB2String() ;

         // an XQUERY statement to restructure all the PurchaseOrders
         // into the following form
         // <items>
         //    <item OrderDate="YYYY-MM-DD">
         //       <custid>XXXX</custid>
         //       <partid>XXX-XXX-XX</partid>
         //       <quantity>XX</quantity>
         //    </item>................<item>...............</item>
         //    <item>.................</itemm
         // </items>
         // store the above XML document in an application varible "orders"
  
         String query1 = "XQUERY let $po:=db2-fn:sqlquery( \"SELECT XMLELEMENT( NAME \"\"porders\"\", "
                  + "( XMLCONCAT( XMLELEMENT(NAME \"\"custid\"\", p.custid), p.porder) )) "
                  + " FROM PURCHASEORDER as p\") return <items> {for $i in $po, $j in "
                  + " $po[custid=$i/custid]/PurchaseOrder[@PoNum=$i/PurchaseOrder/@PoNum]/item "
                  + " return <item>{$i/PurchaseOrder/@OrderDate}{$i/custid}{$j/partid}"
                  + " {$j/quantity}</item>}</items>";

         PreparedStatement stmt1 = con.prepareStatement(query1);
         ResultSet rs1 = stmt1.executeQuery();
  
         if(rs1.next()) 
         {
	   orders = (DB2Xml) rs1.getObject(1) ;
         }
         String temporders=orders.getDB2XmlString();
         rs1.close() ;
         stmt1.close();
 
         // select the oldpromodate, newpromodate, price and promoprice
         // for the products for which the promodate is extended
         // using input XML document

         String query2 = "SELECT Pid,PromoEnd,Price,PromoPrice,XMLCAST(XMLQUERY("
                  + "'$info/Suppliers/Supplier/Products/Product[@id=$pid]/ExtendedDate' "
                  + "passing cast(? as XML) as \"info\",  pid as \"pid\") as DATE) FROM "
                  + "product WHERE XMLEXISTS('for $prod in $info//Product[@id=$pid] "
                  + "return $prod' passing by ref cast(? as XML) as \"info\", pid as \"pid\")";

         PreparedStatement stmt2 = con.prepareStatement(query2);
         stmt2.setString (1, ipdata);
         stmt2.setString (2, ipdata);
         ResultSet rs2 = stmt2.executeQuery();

         // create two temporary tables to store intermediate results
         Statement create1 = con.createStatement();
         create1.executeUpdate( "CREATE TABLE temp_table1(custid INT,partid VARCHAR(12),"
                                + "excessamount DECIMAL(30,2))");
         create1.close();
         Statement create2 = con.createStatement();
         create2.executeUpdate( "CREATE TABLE temp_table2(cid INT,total DECIMAL(30,2))");
         create2.close();          
 
         // repeat the above for all products 
         while(rs2.next())
         {
            prodid = rs2.getString(1);
            oldPromoDate = rs2.getDate(2);
            originalPrice = rs2.getFloat(3);
            promoPrice = rs2.getFloat(4);
            newPromoDate = rs2.getDate(5);
            
            // finding out the toatal quantity of the product purchased by a customer
            // if that order is made in between oldpromodate and extended promodate.
            // this query will return the custid, product id and total quantity of
            // that product purchased in all his orders.
            String query3 = "WITH temp1 AS (SELECT cid,partid,quantity,orderdate "
                     + "FROM XMLTABLE('$od//item' passing cast(? as XML)"
                     + " as \"od\" COLUMNS cid BIGINT path './custid', partid VARCHAR(20)"
                     + "path './partid', orderdate DATE path './@OrderDate',quantity BIGINT"
                     + " path './quantity') as temp2) SELECT  temp1.cid, temp1.partid, "
                     + "sum(temp1.quantity) as quantity FROM temp1 WHERE partid=? and "
                     + "orderdate>cast(? as DATE) and orderdate<cast(? as DATE) "
                     + "group by temp1.cid,temp1.partid";
            PreparedStatement stmt3 = con.prepareStatement(query3);
            stmt3.setString(1,temporders);
            stmt3.setString(2,prodid);
            stmt3.setDate(3,oldPromoDate);
            stmt3.setDate(4,newPromoDate);
            ResultSet rs3 = stmt3.executeQuery();

            // repeat the above  to findout all the customers
            while(rs3.next())
            {
               custid = rs3.getLong(1);
               partid =  rs3.getString(2);
               quantity = rs3.getInt(3);
  
               // excess amount to be paid to customer for that product              
               excessamount = (originalPrice - promoPrice)*quantity;

               // store these results in a temporary table
               sql = "INSERT INTO temp_table1(custid,partid,excessamount) values(?,?,?)";
               PreparedStatement stmt4 = con.prepareStatement(sql);
               stmt4.setLong(1,custid);
               stmt4.setString(2,partid);
               stmt4.setFloat(3,excessamount);
               stmt4.executeUpdate();
               stmt4.close();
            }
            rs3.close();
            stmt3.close();
        }
        rs2.close() ;
        stmt2.close();

        // findout total excess amount to be paid to a customer for all the products
        // store those results in another temporary table
        Statement stmt5 = con.createStatement();
        stmt5.executeUpdate("INSERT INTO temp_table2( SELECT custid, sum(excessamount) "
                            + "FROM temp_table1 GROUP BY custid)");
        stmt5.close();

        // format the results into an XML document of the following form
        // <Customers>
        //    <Customer>
        //      <Custid>XXXX</Custid>
        //      <Total>XXXX.XXXX</Total>
        //      <customerinfo Cid="xxxx">
        //              <name>xxxx xxx</name>
        //              <addr country="xxx>........
        //              </addr>
        //              <phone type="xxxx">.........
        //              </phone>
        //      </customerinfo>
        //   </Customer>............
        // </Customers>

        String query4 = "XQUERY let $res:=db2-fn:sqlquery(\"SELECT XMLELEMENT( "
                 + "NAME \"\"Customer\"\",( XMLCONCAT(XMLELEMENT(NAME \"\"Custid\"\", "
                 + "t.cid),XMLELEMENT( NAME \"\"Total\"\", t.total),c.info))) FROM "
                 + "temp_table2 AS t,customer AS c WHERE t.cid = c.cid\") "
                 + "return <Customers>{$res}</Customers>";

        PreparedStatement stmt6 = con.prepareStatement(query4);
        ResultSet rs4 = stmt6.executeQuery();
        if(rs4.next())
        {
           tempXML = (DB2Xml) rs4.getObject(1) ;
        }
        // assign the result XML document to parameters
        set( 2, tempXML);

        rs4.close() ;
        stmt6.close();

        //drop the temporary tables
        Statement drop1 = con.createStatement();
        drop1.executeUpdate( "DROP TABLE temp_table1");
        drop1.close();
        Statement drop2 = con.createStatement();
        drop2.executeUpdate( "DROP TABLE temp_table2");
        drop2.close();

        set( 3, 0);     
        con.close();

        return ;
  }
}

