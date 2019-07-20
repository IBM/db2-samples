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
// SOURCE FILE NAME: Simple_XmlProc_Client.java
//
// SAMPLE: Call the stored procedure implemented in Simple_XmlProc.java
//
// Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system,
//            do the following:
//            1. Compile the server source file Simple_XmlProc.java (this will 
//               also erase the existing library/class files and copy the newly
//               compiled class files, Simple_XmlProc.class, from the current
//               directory to the $(DB2PATH)\function directory):
//                 nmake/make Simple_XmlProc
//            2. Compile the client source file Simple_XmlProc_Client.java (this 
//               will also call the script 'spcat_xml' to create and catalog the
//               stored procedures):
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
//             4. Catalog the stored procedures in the database with:
//                  spcat_xml
//             5. Compile Simple_XmlProc_Client with:
//                  javac Simple_XmlProc_Client.java
//             6. Run Simple_XmlProc_Client with:
//                  java Simple_XmlProc_Client
//
// Simple_XmlProc_Client calls callSimple_Proc  method that calls the stored procedure:
//         This method will take Customer Information ( of type XML)  as input ,
//         finds whether the customer with Cid in Customer Information exists in the
//         customer table or not, if not this will insert the customer information
//         into the customer table with same Customer id, and returns all the customers
//         from the same city of the input customer information in XML format to the caller
//         along with location as an output parameter in XML format.
//
//         Parameter types used: IN  XML AS CLOB(5000)
//                               OUT XML AS CLOB(5000)
//                               OUT INTEGER 
// SQL Statements USED:
//         CALL
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

import java.lang.*;                   // for String class
import java.io.*;                     // for ...Stream classes
import COM.ibm.db2.app.StoredProc;    // Stored Proc classes
import java.sql.*;                    // for JDBC classes
import com.ibm.db2.jcc.*;             // for XML class  
import COM.ibm.db2.app.Clob;          // for CLOB class
import java.util.*;                   // Utility classes

class Simple_XmlProc_Client
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
     callSimple_Proc(con);
     
     return ;
  } // end main

  // callSimple_Proc  procedure to call the stored procedure
  public static void callSimple_Proc(Connection con)
  {
    try
    {
      // prepare the CALL statement 
      String procName = "Simple_XML_Proc_Java";
      String sql = "CALL " + procName + "( ?, ?, ?)";

      CallableStatement callStmt = con.prepareCall(sql);
      
      // input data
      String inXml = "<customerinfo Cid=\"5002\">"
                   + "<name>Kathy Smith</name><addr country=\"Canada\"><street>25 EastCreek"
                   + "</street><city>Markham</city><prov-state>Ontario</prov-state><pcode-zip>"
                   + "N9C-3T6</pcode-zip></addr><phone type=\"work\">905-566-7258"
                   + "</phone></customerinfo>";
      callStmt.setString (1, inXml ) ;

      // register the output parameter
      callStmt.registerOutParameter(2, com.ibm.db2.jcc.DB2Types.XML);
      callStmt.registerOutParameter(3, Types.INTEGER);
      
      // call the stored procedure
      System.out.println();
      System.out.println("Calling stored procedure " + procName);
      callStmt.execute();
      System.out.println(procName + " called successfully");
      // retrieve output parameters
      com.ibm.db2.jcc.DB2Xml outXML = (DB2Xml) callStmt.getObject(2);
      System.out.println("\n \n Location is :\n "
                                + outXML.getDB2String());
      ResultSet rs = callStmt.getResultSet();
      fetchAll(rs);
      // close ResultSet and callStmt
      rs.close();
      int  retcode = callStmt.getInt(3);
      System.out.println("\n \n  Return code " + " : " + retcode );
  
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
 public static void fetchAll(ResultSet rs)
  {
    try
    {
      System.out.println(
       "=============================================================");

      // retrieve the  number, types and properties of the
      // resultset's columns
      ResultSetMetaData stmtInfo = rs.getMetaData();

      int numOfColumns = stmtInfo.getColumnCount();
      int r = 0;

      System.out.println("\n \n Procedure returned :");

      while (rs.next())
      {
        r++;
        for (int i = 1; i <= numOfColumns; i++)
        {
          if (i == 1)
          {
              com.ibm.db2.jcc.DB2Xml  tempXML = (DB2Xml) rs.getObject(i);
              System.out.println("\n \n " + tempXML.getDB2String());
          }
          else
          {
            System.out.print(rs.getString(i));
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
}

