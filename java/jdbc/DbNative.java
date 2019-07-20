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
// SOURCE FILE NAME: DbNative.java
//
// SAMPLE: Converts an SQL statement into the system's native SQL grammar
//
// SQL Statements USED:
//         SELECT
//
// JAVA 2 CLASSES USED:
//         Connection
//
// Classes used from Util.java are:
//         Db
//         JdbcException
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: DbNative.out (available in the online documentation)
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
//**************************************************************************/

import java.lang.*;
import java.sql.*;

class DbNative
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO CONVERT A GIVEN SQL STATEMENT INTO \n" +
        "THE SYSTEM'S NATIVE SQL GRAMMAR. ");

      // connect to the 'sample' database
      db.connect();

      String stmt = "SELECT * FROM employee WHERE hiredate={d '1994-03-29'}";
      String odbcEscapeClause = "{d '1994-03-29'}";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE API Function:\n" +
        "  Connection.nativeSQL()\n" +
        "TO CONVERT AN SQL STATEMENT INTO THE SYSTEM'S NATIVE SQL GRAMMAR");

      System.out.println();
      System.out.println(
        "  Translate the statement\n\n" +
        "    " + stmt + "\n\n" +
        "  that contains the ODBC escape clause" + odbcEscapeClause + "\n" +
        "  into the system's native SQL grammar:\n");

      // The Java 2 method Connection.nativeSQL() converts the given SQL
      // statement into the system's native SQL grammar.
      String nativeSql = db.con.nativeSQL(stmt);
      if (nativeSql == null)
      {
        System.out.println("Invalid ODBC statement\n");
      }
      else
      {
        System.out.println("    " + nativeSql);
      }

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // main
} // DbNative

