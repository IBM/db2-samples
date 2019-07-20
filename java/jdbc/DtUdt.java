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
// SOURCE FILE NAME: DtUdt.java
//
// SAMPLE: How to create, use and drop user defined distinct types
//
// SQL statements USED:
//         CREATE DISTINCT TYPE
//         CREATE TABLE
//         DROP DISTINCT TYPE
//         DROP TABLE
//         INSERT
//         COMMIT
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
// OUTPUT FILE: DtUdt.out (available in the online documentation)
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

class DtUdt
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO CREATE, USE AND DROP\n" +
        "USER DEFINED DISTINCT TYPES.");

      // connect to the 'sample' database
      db.connect();

      create(db.con);
      use(db.con);
      drop(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // main

  // This function creates a few user defined distinct types
  static void create(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  CREATE DISTINCT TYPE\n" +
        "  COMMIT\n" +
        "TO CREATE UDTs.");

      System.out.println();
      System.out.println(
        "  CREATE DISTINCT TYPE udt1 AS INTEGER WITH COMPARISONS");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE DISTINCT TYPE udt1 AS INTEGER WITH COMPARISONS");
      stmt.close();

      System.out.println(
        "  CREATE DISTINCT TYPE udt2 AS CHAR(2) WITH COMPARISONS");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "CREATE DISTINCT TYPE udt2 AS CHAR(2) WITH COMPARISONS");
      stmt1.close();

      System.out.println(
        "  CREATE DISTINCT TYPE udt3 AS DECIMAL(7, 2) WITH COMPARISONS");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "CREATE DISTINCT TYPE udt3 AS DECIMAL(7, 2) WITH COMPARISONS ");
      stmt2.close();

      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // create

  // This function uses the user defined distinct types that we created
  // at the beginning of this program.
  static void use(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  EXECUTE IMMEDIATE\n" +
      "  COMMIT\n" +
      "TO USE UTDs.");

    // Create a table that uses the user defined distinct types
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE udt_table(col1 udt1, col2 udt2, col3 udt3)");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE udt_table(col1 udt1, col2 udt2, col3 udt3)");
      stmt.close();

      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // Insert data into the table with the user defined distinct types
    try
    {
      String strStmt;
      System.out.println();
      System.out.println(
        "  INSERT INTO udt_table \n" +
        "    VALUES(CAST(77 AS udt1),\n" +
        "           CAST('ab' AS udt2),\n" +
        "           CAST(111.77 AS udt3))");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO udt_table VALUES(CAST(77 AS udt1), " +
        "                             CAST('ab' AS udt2), " +
        "                             CAST(111.77 AS udt3))");
      stmt1.close();

      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // Drop the table with the user defined distinct types
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE udt_table");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP TABLE udt_table");
      stmt2.close();

      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con) ;
      jdbcExc.handle();
    }
  } // use

  // This function drops all of the user defined distinct types that
  // we created at the beginning of this program
  static void drop(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  DROP\n" +
      "  COMMIT\n" +
      "TO DROP UDTs.");

    try
    {
      System.out.println();
      System.out.println("  DROP USER DISTINCT TYPE udt1");
      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP DISTINCT TYPE udt1");
      stmt.close();

      System.out.println("  DROP USER DISTINCT TYPE udt2");
      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("DROP DISTINCT TYPE udt2");
      stmt1.close();

      System.out.println("  DROP USER DISTINCT TYPE udt3");
      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP DISTINCT TYPE udt3");
      stmt2.close();

      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con) ;
      jdbcExc.handle();
    }
  } // drop
} // DtUdt

