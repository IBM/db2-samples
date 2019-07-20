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
// SOURCE FILE NAME: AdmCmdExport.java
//
// SAMPLE: How to perform export using ADMIN_CMD.
//
//         This sample should be run using the following steps:
//         1.Compile the program with the following command:
//           javac AdmCmdExport.java
//
//         2.The sample should be run using the following command
//           java AdmCmdExport <path for export>
//           The fenced user id must be able to create or overwrite files in
//           the target export directory specified.This directory must 
//           be a full path on the server. The path must include '\' or '/'
//           in the end according to the platform. The file for export must
//           exist before the sample is run. 
//
// SQL Statements USED:
//         CALL
//         SELECT
//
// Class used from Util.java are:
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
// OUTPUT FILE: AdmCmdExport.out (available in the online documentation)
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
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//     http://www.software.ibm.com/data/db2/udb/ad
//***************************************************************************

import java.io.*;     
import java.lang.*;
import java.util.*;
import java.sql.*;

class AdmCmdExport 
{

  public static void main(String argv[])
  {
    Connection con = null;
    
    int rows_exported;
    String msg_retrieval = null;
    String msg_removal = null;
    String sqlcode = null;
    String msg = null;
    
    CallableStatement callStmt1 = null;
    ResultSet rs1 = null;
    PreparedStatement stmt1 = null;
    ResultSet rs2 = null;
    CallableStatement callStmt2 = null;

    if (argv.length < 1)
    {
      System.out.println("\n Usage : java AdmCmdExport <path for export>");
    }
    else
    {             
      try
      {
        // initialize DB2Driver and establish database connection.
        Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
        con = DriverManager.getConnection("jdbc:db2:SAMPLE");

        System.out.println("HOW TO PERFORM EXPORT USING ADMIN_CMD.\n");
        // prepare the CALL statement for OUT_LANGUAGE
        String sql = "CALL SYSPROC.ADMIN_CMD(?)";
        callStmt1 = con.prepareCall(sql);

        String param = "export to "+ argv[0] + "org_ex.ixf ";
        param = param + "of ixf messages on server select * from org" ;

        // set the imput parameter
        callStmt1.setString(1, param);
        System.out.println("CALL ADMIN_CMD('" + param + "')");
       
        // execute export by calling ADMIN_CMD
        callStmt1.execute();
        rs1 = callStmt1.getResultSet();
        // retrieve the resultset  
        if( rs1.next())
        { 
          // the numbers of rows exported
          rows_exported = rs1.getInt(1);

          // retrieve the select stmt for message retrival 
          // containing SYSPROC.ADMIN_GET_MSGS
          msg_retrieval = rs1.getString(2);
  
          // retrive the stmt for message cleanup
          // containing CALL of SYSPROC.ADMIN_REMOVE_MSGS
          msg_removal = rs1.getString(3);
      
          // display the output
          System.out.println("Total number of rows exported  : " + rows_exported);
          System.out.println("SQL for retrieving the messages: " + msg_retrieval); 
          System.out.println("SQL for removing the messages  : " + msg_removal);
        } 
      
        stmt1 = con.prepareStatement(msg_retrieval);
        System.out.println("\n" + "Executing " + msg_retrieval);  

        // message retrivel 
        rs2 = stmt1.executeQuery();
	
        // retrieve the resultset
        while(rs2.next())
        {
          // retrieve the sqlcode
	    sqlcode = rs2.getString(1);
      
          // retrieve the error message
          msg = rs2.getString(2);
          System.out.println("Sqlcode : " +sqlcode);
          System.out.println("Msg     : " +msg);
        }

        System.out.println("\nExecuting " + msg_removal);
        callStmt2 = con.prepareCall(msg_removal);

        // executing the message retrivel
        callStmt2.execute();      
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
          // close the statements 
          callStmt1.close();
          callStmt2.close();
          stmt1.close();

          // close the resultsets
          rs1.close();
          rs2.close();
     
          // roll back any changes to the database made by this sample
          con.rollback();

          // close the connection                                   
          con.close();
        }
        catch (Exception x)
        { 
          System.out.print("\n Unable to Rollback/Disconnect ");
          System.out.println("from 'sample' database"); 
        }
      }
    } 
  } // main
} // AdmCmdExport 
