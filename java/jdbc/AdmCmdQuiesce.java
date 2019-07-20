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
// SOURCE FILE NAME: AdmCmdQuiesce.java
//
// SAMPLE: How to quiesce tablespace and database using ADMIN_CMD
//
// JAVA 2 CLASSES USED:
//         CallableStatement
//
// Classes used from Util.java are:
//         Db
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
//Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: AdmCmdQuiesce.out (available in the online documentation)
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

class AdmCmdQuiesce 
{

  public static void main(String argv[])
  {
    Connection con = null;

    try
    {
      Db db = new Db(argv);

      System.out.print("\nTHIS SAMPLE SHOW TO QUIESCE TABLESPACES");
      System.out.print("AND DATABASE USING ADMIN_CMD.\n");  
    
      // connect to the 'sample' database
      db.connect();
      con = db.con;

      // prepare the CALL statement for ADMIN_CMD
      String sql = "CALL SYSPROC.ADMIN_CMD(?)";
      CallableStatement callStmt = con.prepareCall(sql);
        
      // quiesce tablespaces for empoyee table 
      String param = "QUIESCE TABLESPACES FOR TABLE EMPLOYEE EXCLUSIVE";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");
     
      // call the stored procedure
      callStmt.execute();
      
      System.out.print("The quiesce tablespaces for employee ");
      System.out.print("table done successfully\n");

      // quiesce reset of tablespaces of employee table
      param = "QUIESCE TABLESPACES FOR TABLE EMPLOYEE RESET";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();

      System.out.print("The quiesce reset of tablespaces ");
      System.out.print("done successfully\n");
 
      // quiesce database
      param = "QUIESCE DATABASE IMMEDIATE";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.println("The quiesce database done successfully.");

      // unquiesce database 
      param = "UNQUIESCE DB";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.println("The unquiesce database done successfully.");

      // close the callStmt
      callStmt.close();
     
      // rollback changes 
      con.rollback();   
                                
      // disconnect from the 'sample' database
      db.disconnect();  
    }
    catch (Exception e)
    {
      try
      {
        con.rollback();
        con.close();
      }
      catch (Exception x)
      { }

      e.printStackTrace();
    }
  } // main
} // AdmCmdQuiesce 
