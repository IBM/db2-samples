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
// SOURCE FILE NAME: Xquery_XmlProc_Client.java
//
// SAMPLE: Call the stored procedure implemented in Xquery_XmlProc.java
//
// Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system,
//            do the following:
//            1. Compile the server source file Xquery_XmlProc.java, 
//               erase the existing library/class files and copy the newly 
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
//             4. Catalog the stored procedures in the database with:
//                  spcat_xquery
//             5. Compile Xquery_XmlProc_Client with:
//                  javac Xquery_XmlProc_Client.java
//             6. Run Xquery_XmlProc_Client with:
//                  java Xquery_XmlProc_Client
//
// Xquery_XmlProc_Client calls callSupp_XML_Proc_Java  method that calls the 
//      stored procedure: callSupp_XML_Proc_Java.
//      Calls a stored procedure that accepts an XML document with extended
//      promodate for the products and returns another XML document
//      with Customer Information and excess amount paid by them.
//        Parameter types used: IN  XML AS CLOB(5000)
//                              OUT XML AS CLOB(5000)
//                              OUT INTEGER 
// SQL Statements USED:
//         CALL
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

import java.lang.*;                   // for String class
import java.io.*;                     // for ...Stream classes
import COM.ibm.db2.app.StoredProc;    // Stored Proc classes
import java.sql.*;                    // for JDBC classes
import com.ibm.db2.jcc.*;             // for XML class  
import COM.ibm.db2.app.Clob;          // for CLOB class
import java.util.*;                   // Utility classes

class Xquery_XmlProc_Client
{

  public static void main(String argv[])
  {
   Connection con = null;
   // connect to sample database
   String url = "jdbc:db2:sample";
   try
   {
     Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
   }
   catch (Exception e)
   {
     System.out.println("  Error loading DB2 Driver...\n");
     System.out.println(e);
     System.exit(1);
   }
    try
   {
     con = DriverManager.getConnection(url);
     con.setAutoCommit(false);
   }
   catch (SQLException e)
   {
     System.out.println("Connection to sample db can't be established.");
     System.err.println(e) ;
     System.exit(1);
   }

   // call the procedure to call stored procedure
   callSupp_XML_Proc_Java(con);

   return ;
  } // end main

  // callSupp_XML_Proc_Java  procedure to call the stored procedure
  public static void callSupp_XML_Proc_Java(Connection con)
  {
    try
    {
      // prepare the CALL statement 
      String procName = "Supp_XML_Proc_Java";
      String sql = "CALL " + procName + "( ?, ?, ?)";

      CallableStatement callStmt = con.prepareCall(sql);

      // input data
      String inXml = "<Suppliers> <Supplier id=\"100\">"
                   + "<Products><Product id=\"100-100-01\">"
                   + " <ExtendedDate>2007-01-02</ExtendedDate> </Product> <Product "
                   + "id= \"100-101-01\"> <ExtendedDate>2007-02-02</ExtendedDate>"
                   + " </Product> </Products> </Supplier> <Supplier id=\"101\">"
                   + "<Products> <Product id=\"100-103-01\"> <ExtendedDate>2007-03-22"
                   + "</ExtendedDate> </Product> </Products></Supplier> </Suppliers>";

      callStmt.setString (1, inXml ) ;

      // register the output parameter
      callStmt.registerOutParameter(2, com.ibm.db2.jcc.DB2Types.XML);
      callStmt.registerOutParameter(3, Types.INTEGER);
      
      // call the stored procedure
      System.out.println();
      System.out.println("Calling stored procedure " + procName);
      System.out.println( procName +"(" ) ;
      System.out.println("  "+ inXml + "," ) ;
      System.out.println( "            ?, ?)" ) ;

      callStmt.execute();

      // retrieve output parameters
      com.ibm.db2.jcc.DB2Xml outXML = (DB2Xml) callStmt.getObject(2);

      System.out.println(procName + " completed successfully");
      System.out.println("\n \n  Customers Information " + " : "
                                + outXML.getDB2String());
       int  retcode = callStmt.getInt(3);
       System.out.println("\n \n  Return code " + " : "
                         + retcode );
  
       // Rollback the transactions to keep database consistent      
       System.out.println("\n \n --Rollback the transaction-----");
       con.rollback();
       System.out.println("  Rollback done!");

       // clean up resources
       callStmt.close();

    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
      System.out.println();

      if (con != null)
      {
        try
        {
          System.out.println("--Rollback the transaction-----");
          con.rollback();
          System.out.println("  Rollback done!");
        }
        catch (Exception error )
        {
        }
      }
      System.out.println("--FAILED----");
    }

    return ;
  }
}

