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
// SOURCE FILE NAME: AdmCmdUpdateCfg.java
//
// SAMPLE: How to update and reset the Database configuration and Database 
//         Manager Configuration Parameters 
//
// JAVA 2 CLASS USED:
//         CallableStatement
//
// Class used from Util.java are:
//         Db
//         JdbcException
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
//Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: AdmCmdUpdateCfg.out (available in the online 
//                                   documentation)
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

import java.io.*;
import java.lang.*;
import java.util.*;
import java.sql.*;

class AdmCmdUpdateCfg 
{

  public static void main(String argv[])
  {
    Connection con = null;
    Db db = null;  
    CallableStatement callStmt = null;
    try
    {
      db = new Db(argv);

      System.out.print("\nTHIS SAMPLE SHOWS HOW TO UPDATE AND RESET THE"); 
      System.out.print(" DB CFGAND DBM CFG PARAMETERS USING ADMIN_CMD.\n");
    
      // connect to the 'sample' database
      db.connect();
      con = db.con;

      // prepare the CALL statement for ADMIN_CMD
      String sql = "CALL SYSPROC.ADMIN_CMD(?)";
      callStmt = con.prepareCall(sql);
        
      // update the Database configuration Parameter dbheap to 1500 
      String param = "UPDATE DATABASE CONFIGURATION USING DBHEAP 1500";

      // set the input parameter  
      callStmt.setString(1, param);

      System.out.println("\nCALL ADMIN_CMD('" + param + "')");
      // call the stored procedure
      callStmt.execute();
      
      System.out.print("The DB CFG parameter is updated successfully.\n");
    
      // update the Database Manager Configuration 
      // Parameter aslheapsz to 1000 
      param = "UPDATE DATABASE MANAGER CONFIGURATION using ASLHEAPSZ 1000";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();

      System.out.print("The DBM CFG parameter is updated successfully.\n");
 
      // reset the DB CFG parameters for SAMPLE 
      param = "RESET DB CFG FOR SAMPLE";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The DB CFG parameters for SAMPLE DB are"); 
      System.out.print(" resetted successfully.\n");

      // reset the DBM CFG parameters 
      param = "RESET DBM CFG";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      
      System.out.print("The DBM CFG parameters are resetted successfully\n");
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
} // AdmCmdUpdateCfg 
