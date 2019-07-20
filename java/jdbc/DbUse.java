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
// SOURCE FILE NAME: DbUse.java
//
// SAMPLE: How to use a database
//
// SQL Statements USED:
//         CREATE TABLE
//         DROP TABLE
//         DELETE
//         COMMIT
//         ROLLBACK
//
// JAVA 2 CLASSES USED:
//         Statement
//         PreparedStatement
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
// OUTPUT FILE: DbUse.out (available in the online documentation)
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

class DbUse
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO USE A DATABASE.");

      // connect to the 'sample' database
      db.connect();

      execStatement(db.con);
      execPreparedStatement(db.con);
      execPreparedStatementWithParam(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  static void execStatement(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE JAVA 2 CLASS:\n" +
      "  Statement\n" +
      "TO EXECUTE A STATEMENT.");

    try
    {
      Statement stmt = con.createStatement();

      // execute the statement
      System.out.println();
      System.out.println("  CREATE TABLE t1(col1 INTEGER)");
      stmt.execute("CREATE TABLE t1(col1 INTEGER)");

      // commit the transaction
      System.out.println("  COMMIT");
      con.commit();

      // execute the statement
      System.out.println("  DROP TABLE t1");
      stmt.execute("DROP TABLE t1");

      // commit the transaction
      System.out.println("  COMMIT");
      con.commit();

      // close the statement
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // execStatement

  static void execPreparedStatement(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE JAVA 2 CLASS:\n" +
      "  PreparedStatement\n" +
      "TO EXECUTE A PREPARED STATEMENT.");

    try
    {
      // prepare the statement
      System.out.println();
      System.out.println("  Prepared the statement:\n" +
                         "    DELETE FROM org WHERE deptnumb <= 70");

      PreparedStatement prepStmt = con.prepareStatement(
        "  DELETE FROM org WHERE deptnumb <= 70");

      // execute the statement
      System.out.println();
      System.out.println("  Executed the statement");
      prepStmt.execute();

      // rollback the transaction
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();

      // close the statement
      prepStmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // execPreparedStatement

  static void execPreparedStatementWithParam(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE JAVA 2 CLASS:\n" +
      "  PreparedStatement\n" +
      "TO EXECUTE A PREPARED STATEMENT WITH PARAMETERS.");

    try
    {
      // prepare the statement
      System.out.println();
      System.out.println(
        "  Prepared the statement:\n" +
        "    DELETE FROM org WHERE deptnumb <= ? AND division = ?");

      PreparedStatement prepStmt = con.prepareStatement(
        "  DELETE FROM org WHERE deptnumb <= ? AND division = ? ");

      // execute the statement
      System.out.println();
      System.out.println("  Executed the statement for:\n" +
                         "    parameter 1 = 70\n" +
                         "    parameter 2 = 'Eastern'");

      prepStmt.setInt(1, 70);
      prepStmt.setString(2, "Eastern");
      prepStmt.execute();

      // rollback the transaction
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();

      // close the statement
      prepStmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // execPreparedStatementWithParam
} // DbUse

