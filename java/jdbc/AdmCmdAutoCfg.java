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
// SOURCE FILE NAME: AdmCmdAutoCfg.java
//
// SAMPLE: How to autoconfigure the database
//
// JAVA 2 CLASSES USED:
//         CallableStatement
//         ResultSet
//
// Classes used from Util.java are:
//         Db
//         JdbcException
//
//Compile: the utility file and the source file with:
//         javac Util.java
//javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//     or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: AdmCmdAutoCfg.out (available in the online 
//                                 documentation)
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

import java.io.*;     // JDBC classes           
import java.lang.*;
import java.util.*;
import java.sql.*;

class AdmCmdAutoCfg
{

  public static void main(String argv[])
  {
    Connection con = null;
    ResultSet rs = null;
    Db db = null;  
    CallableStatement callStmt = null;

    try
    {
      db = new Db(argv);

      System.out.print("\nTHIS SAMPLE SHOWS HOW TO AUTOCONFIGURE");
      System.out.print(" A DATABASE USING ADMIN_CMD.\n");  
    
      // connect to the 'sample' database
      db.connect();
      con = db.con;

      // prepare the CALL statement for ADMIN_CMD
      String sql = "CALL SYSPROC.ADMIN_CMD(?)";
      callStmt = con.prepareCall(sql);
        
      // autoconfigure the database 
      String param = "AUTOCONFIGURE USING ISOLATION RS APPLY DB ONLY";
      
      // set the input parameter  
      callStmt.setString(1, param);
      
      // call the stored procedure
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");
      callStmt.execute();
      
      // get first result set       
      rs = callStmt.getResultSet();
      
      // get the values and display them
      while (rs.next())
      { 
         // retireving level
         String level = rs.getString(1);
         // retireving name
         String name = rs.getString(2);
         // retireving value
         String value = rs.getString(3);
         // retireving recommended value
         String recommendedValue = rs.getString(4);
         // retrieving datatype
         String dataType = rs.getString(5);  
         
         // displaying the resultset
         System.out.println("\nLevel             = " + level);
         System.out.println("Name              = " + name);
         System.out.println("Value             = " +  value);
         System.out.println("Recommended_value = " + recommendedValue);
         System.out.println("Datatype          = " + dataType); 
      } 

      System.out.print("\nThe Autoconfiguration is done successfully\n");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }      
    finally
    {
      try
      {
        // close the resultset
        rs.close();

        // close the callStmt
        callStmt.close();

        // roll back any changes to the database made by this sample
        con.rollback();

        // disconnect from the 'sample' database
        db.disconnect();
      }
      catch (Exception x)
      { 
        System.out.print("\n Unable to Rollback/Disconnect ");
        System.out.println("from 'sample' database");    
      }
    }
  } // main
} // AdmCmdAutoCfg
