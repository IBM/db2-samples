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
// SOURCE FILE NAME: AdmCmdImport.java
//
//
// SAMPLE: How to do export using ADMIN_CMD()
//         This sample should be run using the following steps:
//         1.Compile the program with the following command:
//           javac AdmCmdImport.java
//
//         2.The sample should be run using the following command
//           java AdmCmdImport <path for import>
//           The fenced user id must be able read the file specified
//           for import.This directory must be a full path on the server.
//           The path must include '\' or '/' in the end according to the
//           platform.     
//
// SQL Statements USED:
//         CALL
//         SELECT
//
// Classes used from Util.java are:
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
// OUTPUT FILE: AdmCmdImport.out (available in the online documentation)
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
//*************************************************************************

import java.io.*;     //JDBC classes           
import java.lang.*;
import java.util.*;
import java.sql.*;

class AdmCmdImport 
{

  public static void main(String argv[])
  {
    Connection con = null;
    CallableStatement callStmt1 = null;
    CallableStatement callStmt2 = null;
    ResultSet rs1 = null;
    ResultSet rs2 = null;
    PreparedStatement stmt1 = null;
    Statement stmt2 = null;
  
    int rows_read;
    int rows_skipped;
    int rows_loaded;
    int rows_rejected;
    int rows_deleted;
    int rows_committed;

    String msg_retrieval = null;
    String msg_removal = null;
    String sqlcode = null;
    String msg = null;
  
    if (argv.length < 1)
    {
      System.out.println("\n Usage : java AdmCmdImport <path for import>");
    }
    else
    {             
      try
      {
        // Initialize DB2Driver and establish database connection.
        Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
        con = DriverManager.getConnection("jdbc:db2:SAMPLE");

        System.out.println("HOW TO DO IMPORT USING ADMIN_CMD.\n");
        // prepare the CALL statement for OUT_LANGUAGE
        String sql = "CALL SYSPROC.ADMIN_CMD(?)";
        callStmt1 = con.prepareCall(sql);

        // argv[0] is the path for the file to be imported
        String param = "IMPORT FROM " + argv[0] + "org_ex.ixf OF IXF MESSAGES ";
        param = param + "ON SERVER CREATE INTO ORG_IMPORT" ;

        // setting the imput parameter
        callStmt1.setString(1, param);
        System.out.println("CALL ADMIN_CMD('" + param + "')");
       
        // executing import by calling ADMIN_CMD
        callStmt1.execute();
        rs1 = callStmt1.getResultSet();
      
        // retrieving the resultset  
        if( rs1.next())
        { 
          // retrieve the no of rows read
          rows_read = rs1.getInt(1);
          // retrieve the no of rows skipped
          rows_skipped = rs1.getInt(2);
          // retrieve the no of rows loaded
          rows_loaded = rs1.getInt(3);
          // retrieve the no of rows rejected
          rows_rejected = rs1.getInt(4);
          // retrieve the no of rows deleted
          rows_deleted = rs1.getInt(5);
          // retrieve the no of rows committed
          rows_committed = rs1.getInt(6);

          // retrieve the select stmt for message retrival 
          // containing SYSPROC.ADMIN_GET_MSGS
          msg_retrieval = rs1.getString(7);
  
          // retrive the stmt for message cleanup
          // containing CALL of SYSPROC.ADMIN_REMOVE_MSGS
          msg_removal = rs1.getString(8);
      
          // Displaying the resultset
          System.out.print("\nTotal number of rows read      : ");
          System.out.println(rows_read);
          System.out.print("Total number of rows skipped   : ");
          System.out.println( rows_skipped);
          System.out.print("Total number of rows loaded    : ");
          System.out.println(rows_loaded);
          System.out.print("Total number of rows rejected  : "); 
          System.out.println(rows_rejected);
          System.out.print("Total number of rows deleted   : "); 
          System.out.println(rows_deleted);
          System.out.print("Total number of rows committed : "); 
          System.out.println(rows_read);
          System.out.print("SQL for retrieving the messages: "); 
          System.out.println(msg_retrieval); 
          System.out.print("SQL for removing the messages  : "); 
          System.out.println(msg_removal);
        } 
      
        stmt1 = con.prepareStatement(msg_retrieval);
        System.out.println("\n" + "Executing " + msg_retrieval);  

        // message retrivel 
        rs2 = stmt1.executeQuery();
	
        // retrieving the resultset
        while(rs2.next())
        {
          // retrieving the sqlcode
	    sqlcode = rs2.getString(1);
      
          //retrieving the error message
          msg = rs2.getString(2);

          System.out.println("Sqlcode : " +sqlcode);
          System.out.println("Msg     : " +msg);
        }

        System.out.println("\n Executing " + msg_removal);
        callStmt2 = con.prepareCall(msg_removal);

        // executing the message retrivel
        callStmt2.execute();      
 
        System.out.println("\n Executing DROP TABLE ORG_IMPORT");   
        stmt2 = con.createStatement();
        stmt2.executeUpdate("DROP TABLE ORG_IMPORT");
      }
      catch(Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e);
        jdbcExc.handle();
      }
      finally
      {
        try
        {
          //closing the statements and resultset    
          callStmt1.close();
          callStmt2.close();
          stmt1.close();
          stmt2.close();
          rs1.close();
          rs2.close();
     
          // roll back any changes to the database made by this sample
          con.rollback();

          // closing the connection                                   
          con.close();
        }
        catch (Exception x)
        { 
          System.out.print(x);
          System.out.print("\n Unable to Rollback/Disconnect ");
          System.out.println("from 'sample' database"); 
        }
      }
    } 
  } // main
} // AdmCmdImport 
