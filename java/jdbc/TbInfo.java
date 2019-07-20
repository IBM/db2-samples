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
// SOURCE FILE NAME: TbInfo.java
//
// SAMPLE: How to get information about a table
//
// SQL Statements USED:
//         SELECT
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
// OUTPUT FILE: TbInfo.out (available in the online documentation)
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

import java.sql.*;

class TbInfo
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);
      String tableName;

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO GET INFORMATION ABOUT A TABLE.");

      // connect to the 'sample' database
      db.connect();

      // call the sample methods
      tableName = "STAFF";
      getSchemaName(db.con, tableName);
      getColumnInfo(db.con, tableName);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // This function demonstrates how to get the schema name for a table
  static void getSchemaName(Connection con, String tableName)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENT:\n" +
      "  SELECT\n" +
      "TO GET THE SCHEMA NAME OF A TABLE.");

    try
    {
      // get the schema name for a table
      System.out.println();
      System.out.println(
        "  Execute the statement:\n" +
        "    SELECT tabschema\n" +
        "      FROM syscat.tables\n" +
        "      WHERE tabname = '" + tableName + "'");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
                       "SELECT tabschema "+
                       "  FROM syscat.tables "+
                       "  WHERE tabname = '"+ tableName + "'");

      boolean result = rs.next();

      System.out.println();
      System.out.println("  Table schema name is: " + rs.getString(1));
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // getSchemaName

  // This function demonstrates how to get the column information for a table
  static void getColumnInfo(Connection con, String tableName)
  {
    String dataColname = "";
    String dataTypename = "";
    int dataLength = 0;
    int dataScale = 0;

    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  SELECT\n" +
      "TO GET THE COLUMN INFORMATION OF A TABLE.");

    try
    {
      // get the column information for a table
      System.out.println();
      System.out.println(
        "  The following SQL statement gets the column information \n"+
        "  of the '" + tableName + "' table: \n");

      System.out.println(
        "  SELECT colname, typename, length, scale \n" +
        "    FROM syscat.columns \n" +
        "    WHERE tabname = '" + tableName + "'\n");

      System.out.println(
        "    column name          data type      data size\n" +
        "    -------------------- -------------- ----------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
                       "SELECT colname, typename, length, scale " +
                       "  FROM syscat.columns " +
                       "  WHERE tabname = '" + tableName + "'\n");

      if (rs.next() == false)
      {
        System.out.println();
        System.out.println("    Data not found.\n");
      }

      do
      {
        dataColname = rs.getString(1);
        dataTypename = rs.getString(2);
        dataLength = rs.getInt(3);
        dataScale = rs.getInt(4);
        System.out.print("    " + Data.format(dataColname, 20) +
                         " " + Data.format(dataTypename, 14) +
                         " " + dataLength);
        if (dataScale != 0)
        {
          System.out.println("," + dataScale);
        }
        else
        {
          System.out.println();
        }
      } while (rs.next());

      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // getColumnInfo
} // TbInfo

