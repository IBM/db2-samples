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
// SOURCE FILE NAME: DbInfo.java
//
// SAMPLE: How to get/set info in a database
//
// JAVA 2 CLASSES USED:
//         DatabaseMetaData
//         ResultSet
//
// Classes used from Util.java are:
//         Db
//         Data
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
// OUTPUT FILE: DbInfo.out (available in the online documentation)
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

class DbInfo
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO GET/SET INFO ABOUT DATABASES.");

      // connect database
      db.connect();

      // Get information in a database
      infoGet(db.con);
      db.con.commit();

      // disconnect database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // main

  static void infoGet(Connection con)
  {
    System.out.println();
    System.out.println(
      "--------------------------------------------------------\n" +
      "USE THE JAVA APIs:\n" +
      "  DatabaseMetaData.getSchemas()\n" +
      "  ResultSet.getMetaData()\n" +
      "  DatabaseMetaData.getURL()\n" +
      "  DatabaseMetaData.isReadOnly()\n" +
      "  DatabaseMetaData.supportsPositionedDelete()\n" +
      "TO GET INFORMATION AT THE DATABASE LEVEL.");

    try
    {
      DatabaseMetaData dbMetaData = con.getMetaData();

      System.out.println();
      System.out.println("  Information of The current database:\n");

      // Get the schema names available in this database
      ResultSet rs = dbMetaData.getSchemas();
      System.out.println("    Schema names: ");
      String schemaName;

      while (rs.next())
      {
        schemaName = rs.getString(1);
        System.out.println("                                 " + schemaName);
      }
      rs.close();
      System.out.println();

      // Get the URL for this database
      String url = dbMetaData.getURL();
      System.out.println("    Database URL:                " + url);

      // Is the database in read-only mode?
      boolean isReadOnly = dbMetaData.isReadOnly();
      System.out.println();
      System.out.println("    Database is Read-only:       " + isReadOnly);

      // Is positional DELETE supported?
      boolean isPosDelete = dbMetaData.supportsPositionedDelete();
      System.out.println();
      System.out.println("    Positioned DELETE supported: " + isPosDelete);
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // infoGet
} // DbInfo

