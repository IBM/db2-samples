//**************************************************************************
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
// *************************************************************************
//
// SOURCE FILE NAME: TbAST.java
//
// SAMPLE: How to use staging table for updating deferred AST 
//          
//         This sample:
//         1. Creates a refresh-deferred summary table 
//         2. Creates a staging table for this summary table 
//         3. Applies contents of staging table to AST
//         4. Restores the data in a summary table 
//
// SQL STATEMENTS USED:
//         CREATE SUMMARY TABLE
//         DROP
//         INSERT
//         REFRESH
//         SET INTEGRITY
//
// JAVA 2 CLASSES USED:
//         Statement
//         ResultSet
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
// OUTPUT FILE: TbAST.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//**************************************************************************
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
//**************************************************************************

import java.lang.*;
import java.sql.*;

class TbAST
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS THE USAGE OF STAGING TABLE TO UPDATE \n" + 
        "REFRESH DEFERRED AST AND RESTORE DATA IN A SUMMARY TABLE \n" +
        "\n-----------------------------------------------------------\n");

      // connect to database
      db.connect();

      // create a base table, summary table, staging table 
      createStagingTable(db.con);

      // to show the propagation of changes of base table to
      // summary tables through the staging table 
      System.out.println(
        "\n-----------------------------------------------------------\n" +
        "To show the propagation of changes from base table to \n" +
        "summary tables through the staging table: \n" );
      propagateStagingToAst(db.con);
    
      // to show restoring of data in a summary table 
      System.out.println(
        "\n------------------------------------------------------------ \n" +
        "To show restoring of data in a summary table");
      restoreSummaryTable(db.con);
  
      // drop the created tables
      System.out.println(
        "\n------------------------------------------------------------ \n" +
        "Drop the created tables");
      dropTables(db.con);
 
      // disconnect from 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // main

  // Creates base table, summary table and staging table 
  static void createStagingTable(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();
            
      //create base table
      System.out.println(
        "\nUSE THE SQL STATEMENT: \n" +
        "  CREATE TABLE \n" +
        "To create base table, summary table, staging table\n" +
        "\nCreating the base table t\n" +
        "  CREATE TABLE t \n" +
        "    (c1 SMALLINT NOT NULL,\n" +
        "     c2 SMALLINT NOT NULL, \n" +
        "     c3 SMALLINT, \n" +
        "     c4 SMALLINT)\n");       
      stmt.executeUpdate(
        "  CREATE TABLE t " +
        "    (c1 SMALLINT NOT NULL, " +
        "     c2 SMALLINT NOT NULL, " +
        "     c3 SMALLINT, " +
        "     c4 SMALLINT)");      
      System.out.println("  COMMIT");
      con.commit();
      
      // create summary table
      System.out.println(
        "\nCreating summary table d_ast \n" +
        "  CREATE SUMMARY TABLE d_ast AS\n" + 
        "    (SELECT c1, c2, COUNT(*) AS count\n" + 
        "      FROM t\n" +
        "      GROUP BY c1, c2)\n" +
        "    DATA INITIALLY DEFERRED\n" + 
        "    REFRESH DEFERRED \n");
      stmt.executeUpdate(
        "CREATE SUMMARY TABLE d_ast AS " +
        "  (SELECT c1, c2, COUNT(*) AS count " +
        "    FROM t " +
        "    GROUP BY c1, c2) " +
        "  DATA INITIALLY DEFERRED " +
        "  REFRESH DEFERRED ");
      System.out.println("  COMMIT");
      con.commit();
     
      // create staging table
      System.out.println(
        "\nCreating the staging table g \n" + 
        "  CREATE TABLE g FOR d_ast PROPAGATE IMMEDIATE");
      stmt.executeUpdate("CREATE TABLE g FOR d_ast PROPAGATE IMMEDIATE");
      System.out.println("\n  COMMIT");
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // createStagingTable
  
  // Show how to propagate the changes from base table to
  // summary tables through the staging table
  static void propagateStagingToAst(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();
     
      System.out.println(
        "Bring staging table out of pending state \n" + 
        "  SET INTEGRITY FOR g IMMEDIATE CHECKED");
      stmt.executeUpdate("SET INTEGRITY FOR g IMMEDIATE CHECKED");      
      con.commit();
      
      System.out.println(
        "\nRefresh summary table, get it out of pending state. \n" + 
        "  REFRESH TABLE d_ast NOT INCREMENTAL");
      stmt.executeUpdate("REFRESH TABLE d_ast NOT INCREMENTAL");     
      con.commit();
     
      System.out.println(
        "\nInsert data into base table T\n" +
        "  INSERT INTO t VALUES(1,1,1,1), \n" +
        "                      (2,2,2,2), \n" +
        "                      (1,1,1,1), \n" +
        "                      (3,3,3,3)");
      stmt.executeUpdate(
        "INSERT INTO t VALUES(1,1,1,1)," +
        "                    (2,2,2,2)," +
        "                    (1,1,1,1)," +
        "                    (3,3,3,3)");      
      con.commit();
      
      System.out.println(
        "\nDisplay the contents of staging table g.\n" + 
        "The Staging table contains incremental changes to base table.\n"); 
      displayTable(con, "g");
 
      System.out.println(
        "\n\nRefresh the summary table \n" +
        "  REFRESH TABLE d_ast INCREMENTAL");
      stmt.executeUpdate("REFRESH TABLE d_ast INCREMENTAL");
      con.commit();
      
      System.out.println(
        "\nDisplay the contents of staging table g \n" +
        "   NOTE: The staging table is pruned after AST is \n" +
        "         refreshed. The contents are propagated to AST \n" +
        "         from the staging table\n");
      displayTable(con, "g");

      System.out.println(
        "\nDisplay the contents of AST\n"  +
        "Summary table has the changes propagated from staging table\n");
      displayTable(con, "d_ast");
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // propagateStagingToAst
  
  // Shows how to restore the data in a summary table 
  static void restoreSummaryTable(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();
            
      System.out.println(
        "\nBlock all modifications to the summary table \n" +
        "by setting the integrity to off \n" +
        "  (g is placed in pending and g.CC=N) \n" +
        "  SET INTEGRITY FOR g OFF");
      stmt.executeUpdate("SET INTEGRITY FOR g OFF");
      con.commit();
      
      System.out.println(
        "\nExport the query definition in summary table and load \n" +
        "directly back to the summary table.\n" +
        "  (d_ast and g both in pending \n" + 
        "  SET INTEGRITY FOR d_ast OFF CASCADE IMMEDIATE\n");
      stmt.executeUpdate("SET INTEGRITY FOR d_ast OFF CASCADE IMMEDIATE");
      con.commit();
                                           
      System.out.println(
        "Prune staging table and place it in normal state\n" +
        "  (g.CC=F)\n" + 
        "  SET INTEGRITY FOR g IMMEDIATE CHECKED PRUNE\n");
      stmt.executeUpdate("SET INTEGRITY FOR g IMMEDIATE CHECKED PRUNE");
      con.commit();
               
      System.out.println(
        "Changing staging table state to U \n"  +
        "  (g.CC to U)\n" + 
        "  SET INTEGRITY FOR g STAGING IMMEDIATE UNCHECKED");
      stmt.executeUpdate("SET INTEGRITY FOR g STAGING IMMEDIATE UNCHECKED");
      con.commit();
      
      System.out.println(
        "\nPlace d_ast in normal and d_ast.CC to U \n" + 
        "  SET INTEGRITY FOR d_ast MATERIALIZED QUERY IMMEDIATE UNCHECKED");
      stmt.executeUpdate(
        "SET INTEGRITY FOR d_ast MATERIALIZED QUERY IMMEDIATE UNCHECKED");
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // restoreSummaryTable
  
  // Displays the contents of the table being passed as the argument
  static void displayTable(Connection con, String tableName)
  {
    try
    {
      Statement stmt = con.createStatement();
      String sqlString = null;
      ResultSet rs;
      int c1 = 0;
      int c2 = 0;
      int count = 0;
      
      if (tableName.equals("g"))
      {
        sqlString = "  SELECT c1, c2, count FROM g" ;
      }
      else if (tableName.equals("d_ast"))
      {
        sqlString = "  SELECT c1, c2, count FROM d_ast" ;
      }
      
      rs = stmt.executeQuery(sqlString);
      System.out.println(
        sqlString +
        "\n\n  C1    C2    COUNT " +
        "\n  ------------------");
      
      while (rs.next())
      {
        c1 = rs.getInt("c1");
        c2 = rs.getInt("c2");
        count = rs.getInt("count");
         
        System.out.println("   " + c1 + "    " + c2 + "    " + count );
      }
      
      rs.close();
      stmt.close();
    }  
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // displayTable
  
  // Drops the staging table, summary table and base table
  static void dropTables(Connection con)
  { 
    try
    {
      Statement stmt = con.createStatement();
     
      System.out.println(
        "\nDropping a base table implicitly drops summary table defined \n" +
        "on it which in turn cascades to dropping its staging table. \n" +
        "\nUSE THE SQL STATEMENT:\n" +
        "  DROP TABLE \n" + 
        "To drop a table \n\n" + 
        "  DROP TABLE t \n");
      stmt.executeUpdate("DROP TABLE t");
      System.out.println("  COMMIT");
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // dropTables
} // TbAST
