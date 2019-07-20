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
// SOURCE FILE NAME: TbCreate.java
//
// SAMPLE: How to create and drop tables
//
// SQL Statements USED:
//         CREATE TABLE
//         DROP TABLE
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
// OUTPUT FILE: TbCreate.out (available in the online documentation)
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

class TbCreate
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);
      String tableName;

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO CREATE AND DROP TABLES.");

      // connect to the 'sample' database
      db.connect();

      create(db.con);
      drop(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // This function demonstrates how to create a table with different
  // data types for each column.
  static void create(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENT\n" +
      "  CREATE TABLE\n" +
      "TO CREATE A TABLE.");

    // create a table called 'tbname' under the schema 'schname'
    try
    {
      System.out.println();
      System.out.println(
        "  Execute the statement:\n" +
        "    CREATE TABLE schname.tbname(Col1 SMALLINT,\n" +
        "                                Col2 CHAR(7),\n" +
        "                                Col3 VARCHAR(7),\n" +
        "                                Col4 DEC(9,2),\n" +
        "                                Col5 DATE,\n" +
        "                                Col6 BLOB(5000),\n" +
        "                                Col7 CLOB(5000))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE schname.tbname(col1 SMALLINT, " +
        "                            col2 CHAR(7), " +
        "                            col3 VARCHAR(7) , " +
        "                            col4 DEC(9,2), " +
        "                            col5 DATE, " +
        "                            col6 BLOB(5000), " +
        "                            col7 CLOB(5000)) ");
      stmt.close();

      // commit the transaction
      System.out.println();
      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // create

  // This function demonstrates how to drop a table in a specific schema
  static void drop(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENT\n" +
      "  DROP TABLE\n" +
      "TO DROP A TABLE.");

    // drop the table 'tbname' that is under the schema 'schname'
    try
    {
      System.out.println();
      System.out.println("  Execute the statement:\n" +
                         "    DROP TABLE schname.tbname");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE schname.tbname");
      stmt.close();

      System.out.println();
      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // drop
} // TbCreate

