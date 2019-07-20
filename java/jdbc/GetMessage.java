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
// SOURCE FILE NAME: GetMessage.java
//
// SAMPLE : How to get error message in the required locale with token
//          replacement. The tokens can be programatically obtained by
//          invoking Sqlaintp using JNI.
//
// JAVA CLASSES USED:
//         Statement
//         ResultSet
//
// Classes used from Util.java are:
//         Db
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: GetMessage.out (available in the online documentation)
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

import java.io.*;     //JDBC classes           
import java.lang.*;
import java.util.*;
import java.sql.*;

class GetMessage
{
  public static void main(String argv[])
  {
    Connection con = null;
    Statement stmt = null;
    ResultSet rs = null;
    Db db = null;

    try
    {
      db = new Db(argv);
      
      // connect to the 'sample' database
      db.connect();
      con = db.con;
     
      System.out.println
        ("How to get error message in the required locale with token\n" +
        "  replacement. The tokens can be programatically obtained\n" +
        "  by onvoking Sqlaintp API.\n\n");

      stmt = con.createStatement();

      System.out.print("Executing\n"); 
      System.out.print("     SELECT SYSPROC.SQLERRM ('sql551',\n" );
      System.out.print("                             'USERA;UPDATE;");
      System.out.print("SYSCAT.TABLES',\n");
      System.out.print("                             ';',\n"); 
      System.out.print("                             'en_US',\n"); 
      System.out.print("                             1)\n"); 
      System.out.print("       FROM SYSIBM.SYSDUMMY1;\n");

      // Suppose:
      //   'sql551' is sqlcode 
      //   'USERA', 'UPDATE', 'SYSCAT.TABLES' are tokens 
      //   ';' is the delimiter for tokens. 
      //   'en_US' is the locale 
      // If the above information is passed to the scalar function SQLERRM,
      // a message is returned in the specified LOCALE.

      // perform a SELECT against the "org" table in the sample database.
      rs = stmt.executeQuery("SELECT SYSPROC.SQLERRM ('sql551'," +
                                                     "'USERA;" +
                                                     "UPDATE;SYSCAT.TABLES'," +
                                                     "';','en_us'," +
                                                     "1)" +
                               "FROM SYSIBM.SYSDUMMY1");   

      // retrieve and display the result from the SELECT statement
      while (rs.next())
      {
        String message = rs.getString(1);      
        System.out.println("\nThe message is \n" + message); 
      }
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
    finally
    {
      try
      {
        //close the resultset
        rs.close(); 

        // close the Statement
        stmt.close();

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
} // GetMessage
