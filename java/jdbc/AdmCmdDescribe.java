//////////////////////////////////////////////////////////////////////////*
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
//////////////////////////////////////////////////////////////////////////*
//
// SOURCE FILE NAME: AdmCmdDescribe.java
//
// SAMPLE: How to do describe table and indexes using ADMIN_CMD
//
// SQL Statements USED:
//         CALL
//         SELECT
//         CREATE INDEX 
//         DROP INDEX
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
// OUTPUT FILE: AdmCmdDescribe.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//////////////////////////////////////////////////////////////////////////*
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
/////////////////////////////////////////////////////////////////////////////

import java.io.*;     // JDBC classes
import java.lang.*;
import java.util.*;
import java.sql.*;

class AdmCmdDescribe 
{

  public static void main(String argv[])
  {
    Connection con = null;
    
    String colname = null;
    String typeschema = null;
    String typename = null; 
    int length;
    int scale;
    String nullable = null;
   
    String indschema = null;
    String indname = null;
    String unique_rule = null;
    int colcount;

    Db db =null;
    CallableStatement callStmt1 = null;
    CallableStatement callStmt2 = null;
    ResultSet rs1 = null;
    ResultSet rs2 = null;
    Statement stmt1 = null;
    Statement stmt2 = null; 
 
    try
    {
      db = new Db(argv);

      // connect to the 'sample' database
      db.connect();
      con = db.con;

      System.out.print("\nHOW TO DESCRIBE TABLE AND INDEXES");
      System.out.println(" USING ADMIN_CMD");

      stmt1 = con.createStatement(); 
      
      System.out.print("\nExecuting CREATE INDEX INDEX1 ON ");
      System.out.println("EMPLOYEE (LASTNAME ASC))");
      stmt1.executeUpdate("CREATE INDEX INDEX1 ON " + 
                           "EMPLOYEE (LASTNAME ASC)");
 
      // prepare the CALL statement for OUT_LANGUAGE
      String sql = "CALL SYSPROC.ADMIN_CMD(?)";
      callStmt1 = con.prepareCall(sql);

      String param = "DESCRIBE TABLE EMPLOYEE";
     
      // setting the imput parameter
      callStmt1.setString(1, param);
      
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");
      // executing export by calling ADMIN_CMD
      callStmt1.execute();
      rs1 = callStmt1.getResultSet();
      
      // retrieving the resultset  
      while (rs1.next())
      { 

        // retrieving column name and displaying it
        colname = rs1.getString(1);
        System.out.println("\nColname     = " + colname);

        // retrieving typeschema and displaying it
        typeschema = rs1.getString(2);
        System.out.println("Typeschema  = " + typeschema);

        // retrieving typename and displaying it
        typename = rs1.getString(3);
        System.out.println("Typename    = " + typename);

        // retrieving length and displaying it
        length = rs1.getInt(4);
        System.out.println("Length      = " + length);

        // retrieving scale and displaying it
        scale = rs1.getInt(5);
        System.out.println("Scale       = " + scale);

        // retrieving nullable and displaying it
        nullable = rs1.getString(6);
        System.out.println("Nullable    = " + nullable);

      } 
     
      callStmt2 = con.prepareCall(sql);
      param = "DESCRIBE INDEXES FOR TABLE EMPLOYEE";
     
      // setting the imput parameter
      callStmt2.setString(1, param);

      System.out.println("\nCALL ADMIN_CMD('" + param + "')");
      // executing describe indexes using ADMIN_CMD
      callStmt2.execute();
      rs2 = callStmt2.getResultSet();
      
      // retrieving the resultset  
      while( rs2.next())
      { 
        // retrieving index schema and displaying it
        indschema = rs2.getString(1);
        System.out.println("\nIndschema   = " + indschema);

        // retrieving index name and displaying it
        indname = rs2.getString(2);
        System.out.println("Indname     = " + indname);

        // retrieving unique rule  and displaying it
        unique_rule = rs2.getString(3);
        System.out.println("Unique_rule = " + unique_rule);

        // retrieving column count  and displaying it
        colcount = rs2.getInt(4);
        System.out.println("Colcount    = " + colcount);

      }   
      stmt2 = con.createStatement(); 
      System.out.println("\nExecuting DROP INDEX INDEX1");
      stmt2.executeUpdate("DROP INDEX INDEX1");
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
        //closing the connections and resultset    
        callStmt1.close();
        callStmt2.close();
        stmt1.close();
        stmt2.close();
        rs1.close();
        rs2.close();
     
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
} // AdmCmdDescribe 
