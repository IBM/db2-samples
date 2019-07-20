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
// SOURCE FILE NAME: Simple_XmlProc.java
//
// SAMPLE: Code implementation of stored procedure Simple_XML_Proc_Java
//         The stored procedures defined in this program are called by the
//         client application Simple_XmlProc_Client.java. Before building and 
//         running Simple_XmlProc_Client.java, build the shared library by 
//         completing the following steps:
//
// Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system,
//            do the following:
//            1. Compile the server source file Simple_XmlProc.java (this will 
//               erase the existing library/class files and copy the newly 
//               compiled class files, Simple_XmlProc.class, from the current
//               directory to the $(DB2PATH)\function directory):
//                 nmake/make Simple_XmlProc
//            2. Compile the client source file Simple_XmlProc_Client.java(this will 
//               also call the script 'spcat_xml' to create and catalog the stored
//               procedures):
//                 nmake/make Simple_XmlProc_Client
//            3. Run the client Simple_XmlProc_Client:
//                 java Simple_XmlProc_Client
//
//         II) If you don't have a compatible make/nmake program on your
//             system do the following:
//             1. Compile the server source file with:
//                  javac Simple_XmlProc.java
//             2. Erase the existing library/class files (if exists),
//                Simple_XmlProc.class from the following path,
//                $(DB2PATH)\function.
//             3. Copy the class files, Simple_XmlProc.class from the current
//                directory to the $(DB2PATH)\function.
//             4. Catalog the stored procedures in the database with the script:
//                  spcat_xml
//             5. Compile Simple_XmlProc_Client with:
//                  javac Simple_XmlProc_Client.java
//             6. Run Simple_XmlProc_Client with:
//                  java Simple_XmlProc_Client
//
// Class Simple_XmlProc contains one method which solves the following scenario:
//         This method will take Customer Information ( of type XML)  as input ,
//         finds whether the customer with Cid in Customer Information exists in the  
//         customer table or not, if not this will insert the customer information
//         into the customer table with same Customer id, and returns all the customers
//         from the same city of the input customer information in XML format to the caller
//         along with location as an output parameter in XML format.
//  
// SQL Statements USED:
//         CREATE
//         SELECT
//         INSERT 
//
// OUTPUT FILE: Simple_XmlProc_Client.out (available in the online documentation)
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
public class Simple_XmlProc extends StoredProc
{
  Connection con;
  ResultSet outRs;
  public void Simple_Proc ( com.ibm.db2.jcc.DB2Xml inXML,
                            com.ibm.db2.jcc.DB2Xml outXML,
                            int retcode )
  throws Exception
  {
         com.ibm.db2.jcc.DB2Xml tempXML = null;
         int custid = 0;
         String city = null;
         int count = 0;
   
         // get caller's connection to the database
         con = DriverManager.getConnection("jdbc:default:connection");
         
         // get the input XML document into an application variable
         String ipdata = inXML.getDB2String() ;
        
         // find whether the customer with that Info exists in the customer table  
         String query1 = "SELECT COUNT(*) FROM customer WHERE "
                       + " XMLEXISTS('$info/customerinfo[@Cid=$id]' PASSING by ref "
                       + "cast(? as XML)  AS \"info\", cid as \"id\")";
         PreparedStatement stmt1 = con.prepareStatement(query1);
         stmt1.setString (1, ipdata);
         ResultSet rs1 = stmt1.executeQuery();
         if(rs1.next()) 
         {
            count = rs1.getInt(1);
         }
         rs1.close();

         // if customer doesn't exist ...... insert into the table
         if ( count < 1 ) 
         {
           // get the custid from the customer information
           String query2 = "SELECT XMLCAST( XMLQUERY('$info/customerinfo/@Cid' "
                         + "passing by ref cast(? as XML) as \"info\") as "
                         + "INTEGER) FROM SYSIBM.SYSDUMMY1 ";
           PreparedStatement stmt2 = con.prepareStatement(query2);
           stmt2.setString (1, ipdata);
           ResultSet rs2 = stmt2.executeQuery();
           if(rs2.next())
           {
              custid = rs2.getInt(1);
           }
           rs2.close();

           // insert into customer table with that custid
           String query3 = "INSERT INTO customer(Cid, Info) VALUES (?,?)";
           PreparedStatement stmt3 = con.prepareStatement(query3);
           stmt3.setInt(1, custid);   
           stmt3.setString(2, ipdata);
           stmt3.executeUpdate();
         }

         // find the city of the customer and assign it to an application variable
         String query4 = "SELECT XMLCAST( XMLQUERY('$info/customerinfo//city' "
                       + "passing by ref cast(? as XML) as \"info\") as "
                       + "VARCHAR(100)) FROM SYSIBM.SYSDUMMY1";
         PreparedStatement stmt4 = con.prepareStatement(query4);
         stmt4.setString (1, ipdata);
         ResultSet rs4 = stmt4.executeQuery();
         if(rs4.next())
         {
              city=rs4.getString(1);
         }
         rs4.close();

         // select location fron the input XML and assign it to output parameter
         String query5 = "SELECT XMLQUERY('let $city := $info/customerinfo//city "
                       + "let $prov := $info/customerinfo//prov-state return <Location> "
                       + "{$city, $prov} </Location>' passing by ref cast(? as XML) as "
                       + "\"info\") FROM SYSIBM.SYSDUMMY1";
         PreparedStatement stmt5 = con.prepareStatement(query5);
         stmt5.setString (1, ipdata);
         ResultSet rs5 = stmt5.executeQuery();
         if(rs5.next())
         {
              tempXML = (DB2Xml) rs5.getObject(1) ;
         }
         // assign the result XML document to output  parameters
         set(2, tempXML);
         rs5.close();

         // findout all the customers from that city and return as an XML to caller
         String query6 = "XQUERY for $cust in db2-fn:xmlcolumn(\"CUSTOMER.INFO\")/customerinfo/ "
                       + "addr[city = \"" + city + "\"] return <Customer>{$cust/../@Cid}"
                       + "{$cust/../name}</Customer>";
         // prepare the SQL statement
         PreparedStatement stmt6 = con.prepareStatement(query6);
         // get the result set that will be returned to the client
         outRs = stmt6.executeQuery();
         con.close(); 

      set(3, 0);
   }
}


