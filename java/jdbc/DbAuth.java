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
// SOURCE FILE NAME: DbAuth.java
//
// SAMPLE: Grant, display or revoke privileges on database
//
// SQL Statements USED:
//         GRANT (Database Authorities)
//         SELECT
//         REVOKE (Database Authorities)
//         COMMIT
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
// OUTPUT FILE: DbAuth.out (available in the online documentation)
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

class DbAuth
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.print("THIS SAMPLE SHOWS HOW TO GRANT/DISPLAY/REVOKE ");
      System.out.println("AUTHORITIES ON DATABASE.");

      // connect to the 'sample' database
      db.connect();

      grant(db.con);
      display(db.con);
      revoke(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // This function shows how to grant user authorities on database
  static void grant(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  GRANT (Database Authorities)\n" +
      "  COMMIT\n" +
      "TO GRANT AUTHORITIES AT DATABASE LEVEL.\n");

    try
    {
      System.out.println(
        "  GRANT CONNECT, CREATETAB, BINDADD\n" +
        "    ON DATABASE\n" +
        "    TO USER user1");
      Statement stmt = con.createStatement();

      stmt.execute("GRANT CONNECT, CREATETAB, BINDADD " +
                   " ON DATABASE" +
                   " TO USER user1");
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
  } // grant

  // helping function: This function displays the authorities for a
  // user on a database
  static void display(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENT:\n" +
      "  SELECT\n" +
      "TO DISPLAY AUTHORITIES FOR ANY USER AT DATABASE LEVEL.\n");

    System.out.println(
      "  SELECT granteetype, dbadmauth, createtabauth,\n" +
      "         bindaddauth, connectauth, nofenceauth,\n" +
      "         implschemaauth, loadauth\n" +
      "    FROM syscat.dbauth\n" +
      "    WHERE grantee = 'USER1'\n");


    // retrieve and display the result from the SELECT statement
    try
    {
      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
                       "SELECT granteetype, dbadmauth, createtabauth, "+
                       "       bindaddauth, connectauth, nofenceauth, "+
                       "       implschemaauth, loadauth "+
                       "  FROM syscat.dbauth " +
                       "  WHERE grantee = 'USER1'");

      boolean result = rs.next();

      String granteetype = rs.getString(1);
      String dbadmauth = rs.getString(2);
      String createtabauth = rs.getString(3);
      String bindaddauth = rs.getString(4);
      String connectauth = rs.getString(5);
      String nofenceauth = rs.getString(6);
      String implschemaauth = rs.getString(7);
      String loadauth = rs.getString(8);

      rs.close();
      stmt.close();

      System.out.println(
        "      Grantee Type      = " + granteetype + "\n" +
        "      DBADM auth.       = " + dbadmauth + "\n" +
        "      CREATETAB auth.   = " + createtabauth + "\n" +
        "      BINDADD auth.     = " + bindaddauth + "\n" +
        "      CONNECT auth.     = " + connectauth + "\n" +
        "      NO_FENCE auth.    = " + nofenceauth + "\n" +
        "      IMPL_SCHEMA auth. = " + implschemaauth + "\n" +
        "      LOAD auth.        = " + loadauth);
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // display

  // This function shows how to revoke user authorities on a database
  static void revoke(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  REVOKE (Database Authorities)\n" +
      "  COMMIT\n" +
      "TO REVOKE AUTHORITIES AT DATABASE LEVEL.");

    try
    {
      System.out.println();
      System.out.println(
        "  REVOKE CONNECT, CREATETAB, BINDADD\n" +
        "    ON DATABASE\n" +
        "    FROM USER user1");
      Statement stmt = con.createStatement();

      stmt.execute("REVOKE CONNECT, CREATETAB, BINDADD " +
                   " ON DATABASE " +
                   " FROM USER user1");
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
  } // revoke
} // DbAuth

