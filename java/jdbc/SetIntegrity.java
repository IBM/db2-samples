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
// SOURCE FILE NAME: SetIntegrity.java
//
// SAMPLE: How to perform online SET INTEGRITY on a table.
//
//         This sample:
//         1. Availability of table during SET INTEGRITY after LOAD utility.
//         2. Availability of table during set INTEGRITY after adding a new
//            partition is added to the table via the ALTER ATTACH.
//         3. Shows how SET INTEGRITY statement will generate the proper
//            values for both generated columns and identity values whenever
//            a partition which violates the constraint is attached a data
//            partitioned table.
//
//         This sample should be run using the following steps:
//         1.Compile the program with the following command:
//           javac SetIntegrity.java Util.java
//
//         2.The sample should be run using the following command
//           java SetIntegrity <path for dummy file>
//           The fenced user id must be able to create or overwrite files in
//           the directory specified.This directory must
//           be a full path on the server. The dummy file 'dummy.del' must
//           exist before the sample is run.
//
// SQL Statements USED:
//           ALTER TABLE
//           CREATE TABLE
//           DROP TABLE
//           EXPORT
//           IMPORT
//           INSERT
//           LOAD
//           SELECT
//           SET INTEGRITY
//
// JAVA 2 CLASSES USED:
//           Statement
//           ResultSet
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// Classes used from Util.java are:
//           Db
//           Data
//           JdbcException
//
// OUTPUT FILE: SetIntegrity.out (available in the online documentation)
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
//**************************************************************************

import java.lang.*;
import java.sql.*;

class SetIntegrity
{
  public static void main(String argv[])
  {
    if (argv.length < 1)
    {
      System.out.println("\n Usage : java SetIntegrity" +
                        " <path for dummy file>");
    }
    else
    {
      try
      {
        Connection con = null;
        String path = argv[0];
 
        // initialize DB2Driver and establish database connection.
        Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
        con = DriverManager.getConnection("jdbc:db2:SAMPLE");

        System.out.println(
          "\nTHIS SAMPLE SHOWS HOW TO PERFORM SET INTEGRITY ON A TABLE.");

        // creates regular  DMS tablespaces       
        dmstspaceCreate(con);
 
        System.out.println(
          "****************************************************"+
          "\nTHE FOLLOWING SCENARIO SHOWS THE AVAILABILITY OF\n " +
          "    TABLE DURING SET INTEGRITY AFTER LOAD UTILITY\n" +
          "*****************************************************");

        // creates a partitioned table 
        partitionedTbCreate(con, path); 

        System.out.println(
          "*****************************************************"+
          "\nTHE FOLLOWING SCENARIO SHOWS THE AVAILABILITY OF " +
          "\n  TABLE DURING SET INTEGRITY ALONG WITH GENERATE"  +
          "\n    IDENTITY CLAUSE AFTER LAOD\n" +
          "*****************************************************\n");

        // create a temporary table
        createtb_Temp(con, path);
        createptb_Temp(con, path);

        System.out.println(
          "\n*******************************************************"+
          "\nTHE FOLLOWING SCENARIO SHOWS THE AVAILABILITY OF " +
          "\n  TABLE DURING SET INTEGRITY AFTER ATTACH via ALTER" +
          "\n*****************************************************");

        //  alter a table
        alterTable(con, path);

        // drop tablespaces
        tablespacesDrop(con); 
       
        // disconnect from the 'sample' database
        con.close();
      }
      catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e);
        jdbcExc.handle();
      }
    } 
  } // main
 
  // creates regular DMS tablespaces
  static void dmstspaceCreate(Connection con) throws SQLException
  {
    try
    {
     System.out.println(
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENT:\n" +
       "  CREATE REGULAR TABLESPACE \n" +
       "TO CREATE A REGULAR TABLESPACE \n" +
       "\nExecute the statement:\n" +
       "  CREATE REGULAR TABLESPACE dms_tspace");

     // create regular DMS table space dms_tspace
     Statement stmt = con.createStatement();
     String str = "";
     str = "CREATE REGULAR TABLESPACE dms_tspace";
     stmt.executeUpdate(str);

     System.out.println(
       "Execute the statement:\n" +
       "CREATE REGULAR TABLESPACE dms_tspace1");

     // create regular DMS table space dms_tspace1
     str = "CREATE REGULAR TABLESPACE dms_tspace1";
     stmt.executeUpdate(str);

     System.out.println(
       "Execute the statement:\n" +
       "CREATE REGULAR TABLESPACE dms_tspace2");

     // create regular DMS table space dms_tspace2
     str = "CREATE REGULAR TABLESPACE dms_tspace2";
     stmt.executeUpdate(str);

     System.out.println(
       "Execute the statement:\n" +
       "CREATE REGULAR TABLESPACE dms_tspace3");

     // create regular DMS table space dms_tspace3
     str = "CREATE REGULAR TABLESPACE dms_tspace3";
     stmt.executeUpdate(str);

     con.commit();
     stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // dmstspaceCreate

  // creates a partitioned table with 'part1' in 'dms_tspace1', 'part2' in
  // 'dms_tspace2', and 'part3' in 'dms_tspace3' and inserts data into the 
  // table. The  function also shows how SET INTEGRITY can be performed on 
  // a partitioned table.  
  static void partitionedTbCreate(Connection con, String path) 
  {
    try
    {
     System.out.println(
       "\nUSE THE SQL STATEMENT:\n" +
       "  CREATE TABLE \n" +
       "TO CREATE A PARTITIONED TABLE \n" +
       "\nExecute the statement:\n" +
       "  CREATE TABLE fact_table (max INTEGER NOT NULL,\n" +
       "                           CONSTRAINT CC CHECK (max>0))\n" +  
       "    PARTITION BY RANGE (max)\n "+
       "     (PART  part1 STARTING FROM (-1) ENDING (3) IN dms_tspace1,\n" +
       "      PART part2 STARTING FROM (4) ENDING (6) IN dms_tspace2,\n" +
       "      PART part3 STARTING FROM (7) ENDING (9) IN dms_tspace3)");

     Statement stmt = con.createStatement();
     String str = "";

     str = str + "CREATE TABLE fact_table ";
     str = str + "(max INTEGER NOT NULL, CONSTRAINT CC CHECK (max>0))";
     str = str + " PARTITION BY RANGE (max) ";
     str = str + "(PART  part1 STARTING FROM (-1) ENDING (3) ";
     str = str + "IN dms_tspace1, PART part2 STARTING FROM (4) ENDING (6) ";
     str = str + "IN dms_tspace2, PART part3 STARTING FROM (7) ENDING (9) ";
     str = str + "IN dms_tspace3)";
    
     stmt.executeUpdate(str);                  
     con.commit();
     stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
 
   try
    {
      System.out.println(
        "\n-----------------------------------------------------------" +
        "\nUSE THE SQL STATEMENT:\n" +
        "  INSERT INTO \n" +
        "TO INSERT DATA IN A TABLE \n" +
        "\nExecute the statement:\n" +
        "  INSERT INTO fact_table VALUES (1), (2), (3)");

      // insert data into the table
      Statement stmt = con.createStatement();
      String str = "";

      str = str + "INSERT INTO fact_table VALUES (1), (2), (3)";
      stmt.executeUpdate(str);

      con.commit();
      stmt.close();
     
      System.out.println(
        "\n-----------------------------------------------------------" +
        "\nUSE THE SQL STATEMENT:\n" +
        "  CREATE TABLE \n" +
        "TO CREATE A TABLE \n"); 
 
      // create a temporary table
      System.out.println(
        "Execute the statements:\n" +
        "CREATE TABLE temp_table (max INT)\n ");
     
      stmt = con.createStatement();
      str = "";
  
      str = "CREATE TABLE temp_table (max INT)";
      stmt.executeUpdate(str);
      con.commit();
      stmt.close();

      System.out.println(
        "INSERT INTO temp_table VALUES(4), (5), (6), (7), (0), (-1)");
   
      stmt = con.createStatement();
      str = "";
  
      str = "INSERT INTO temp_table VALUES(4), (5), (6), (7), (0), (-1)";
      stmt.executeUpdate(str);
      con.commit();
      stmt.close(); 
   
      // export data to temporary table 
      exportData(con, path);
      
      // load data from temporary table into base table
      loadData(con, path);
     
      // create temporary table to hold exceptions thrown by SET INTEGRITY 
      // statement.
 
      System.out.println(
        "\nExecute the statement:\n" +
        "CREATE TABLE fact_exception (max INTEGER NOT NULL)");
     
      stmt = con.createStatement();
      str = "";
  
      str = str + "CREATE TABLE fact_exception (max INTEGER NOT NULL)";
      stmt.executeUpdate(str);
      con.commit();
      stmt.close();
   
      System.out.println(
        "\nUSE THE SQL STATEMENT\n" +
        "  SET INTEGRITY\n" +
        "TO TABLE OUT OF CHECK PENDING STATE:\n");
   
      System.out.println(
        "Execute the statement:" +
        "SET INTEGRITY FOR fact_table ALLOW READ ACCESS\n" +
        "  IMMEDIATE CHECKED FOR EXCEPTION IN fact_table\n" +
        "    USE fact_exception");

      stmt = con.createStatement();
      str = "";
  
      str =str + "SET INTEGRITY FOR fact_table ALLOW READ ACCESS";
      str =str + " IMMEDIATE CHECKED FOR EXCEPTION IN fact_table";
      str =str + " USE fact_exception";
 
      stmt.executeUpdate(str);
      con.commit();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
   
   // display the contents of 'fact_table'.
   try
   {
     int max = 0;

     System.out.println(
       "---------------------------------------------------------\n");
     System.out.println("  SELECT * FROM fact_table");
     System.out.println(
       "    MAX\n" +
       "   ------");

     Statement stmt = con.createStatement();
     // perform a SELECT against the "fact_table" table.
     ResultSet rs = stmt.executeQuery("SELECT * FROM fact_table");

     // retrieve and display the result from the SELECT statement
     while (rs.next())
     {
       max = rs.getInt(1);

       System.out.println(
         "    " +
         Data.format(max, 3));
     }
    rs.close();
    stmt.close();
    }  
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the contents of exception table.

    try
    {
     int max = 0;

     System.out.println();
     System.out.println("  SELECT * FROM fact_exception");
     System.out.println(
       "    MAX\n" +
       "   ------");

     Statement stmt = con.createStatement();
     // perform a SELECT against the "fact_exception" table.
     ResultSet rs1 = stmt.executeQuery("SELECT * FROM fact_exception");

     // retrieve and display the result from the SELECT statement
     while (rs1.next())
     {
       max = rs1.getInt(1);

       System.out.println(
         "    " +
         Data.format(max, 3));
     }
     rs1.close();
     stmt.close();
     System.out.println(
       "-----------------------------------------------------------"); 
     }  
     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }

     // drop the tables
     try
     {
   
       System.out.println(
         "\nUSE THE SQL STATEMENT:\n" +
         "  DROP \n" +
         "TO DROP THE TABLES  \n" );

       System.out.println(
         "Execute the statement:\n" +
         "DROP TABLE temp_table\n");

       Statement stmt = con.createStatement();
       String str = "";

       str = str + "DROP TABLE temp_table";
       stmt.executeUpdate(str);
       con.commit();
       stmt.close();
  
       System.out.println(
         "DROP TABLE fact_exception\n");
 
       stmt = con.createStatement();
       str = "";

       str = str + "DROP TABLE fact_exception";
       stmt.executeUpdate(str);
       con.commit();
       stmt.close();

       System.out.println(
         "DROP TABLE fact_table\n");

       stmt = con.createStatement();
       str = "";

       str = str + "DROP TABLE fact_table";
       stmt.executeUpdate(str);
       con.commit();
       stmt.close();
     }

     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }

  } // partitionedTbCreate

  // export data to a temporary table
  static void exportData(Connection con, String path) throws SQLException
  {
    try
    {
      String sql = "";
      String param = "";
      CallableStatement callStmt1 = null;
      ResultSet rs = null;
      Statement stmt = con.createStatement();

      int rows_exported = 0;
        
      System.out.println(
        "\nUSE THE SQL STATEMENT:\n" +
        "  EXPORT \n" +
        "TO EXPORT TABLE DATA INTO A FILE \n" +
        "\nExecute the statement:\n" +
        "  EXPORT TO dummy.del OF DEL SELECT * FROM temp_table");

      // export data into a dummy file
      sql = "CALL SYSPROC.ADMIN_CMD(?)";
      callStmt1 = con.prepareCall(sql);

      // 'path' is the path for the file to which the data is to be exported
      param = "EXPORT TO " + path + "/dummy.del OF DEL SELECT * FROM temp_table";

      // set the input parameter
      callStmt1.setString(1, param);
      System.out.println();
 
      // execute export by calling ADMIN_CMD
      callStmt1.execute();

      rs = callStmt1.getResultSet();
     
      // retrieve the resultset  
      if (rs.next())
      { 
        // the numbers of rows exported
        rows_exported = rs.getInt(1);

        // display the output
        System.out.println
          ("Total number of rows exported  : " + rows_exported);
      } 
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // exportData

  // load data from temporary table into base table
  static void loadData(Connection con, String path) throws SQLException
  {
    try
    {
      String sql = "";
      String param = "";
      CallableStatement callStmt1 = null;
      ResultSet rs = null;
      Statement stmt = con.createStatement();
 
      int rows_read = 0;
      int rows_skipped = 0;
      int rows_loaded = 0;
      int rows_rejected = 0;
      int rows_deleted = 0;
      int rows_committed = 0;
   
      System.out.println(
        "\nUSE THE SQL STATEMENT:\n" +
        "  LOAD \n" +
        "TO LOAD THE DATA INTO THE TABLE \n" +
        "\nExecute the statement:\n" +
        "  LOAD FROM dummy.del OF DEL INSERT INTO fact_table");

        // Load data from file
        sql = "CALL SYSPROC.ADMIN_CMD(?)";
        callStmt1 = con.prepareCall(sql);
 
        // 'path' is the path of the file from which the data is to be loaded
        param = "LOAD FROM " + path + "/dummy.del OF DEL INSERT INTO fact_table";

        // set the input parameter
        callStmt1.setString(1, param);
       
        // execute import by calling ADMIN_CMD
        callStmt1.execute();
        rs = callStmt1.getResultSet();
      
        // retrieve the resultset  
        if (rs.next())
        { 
          // retrieve the no of rows read
          rows_read = rs.getInt(1);

          // retrieve the no of rows skipped
          rows_skipped = rs.getInt(2);

          // retrieve the no of rows loaded
          rows_loaded = rs.getInt(3);

          // retrieve the no of rows rejected
          rows_rejected = rs.getInt(4);

          // retrieve the no of rows deleted
          rows_deleted = rs.getInt(5);

          // retrieve the no of rows committed
          rows_committed = rs.getInt(6);

          // display the resultset
          System.out.print("\nTotal number of rows read      : ");
          System.out.println(rows_read);
          System.out.print("Total number of rows skipped   : ");
          System.out.println( rows_skipped);
          System.out.print("Total number of rows loaded    : ");
          System.out.println(rows_loaded);
          System.out.print("Total number of rows rejected  : "); 
          System.out.println(rows_rejected);
          System.out.print("Total number of rows deleted   : "); 
          System.out.println(rows_deleted);
          System.out.print("Total number of rows committed : "); 
          System.out.println(rows_read);
        } 
     }
     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }
   } // loadData
   
   // display the contents of table
   static void DisplaytbData(Connection con) throws SQLException
   {
     try
     {
       int max = 0;

       System.out.println();
       System.out.println("  SELECT * FROM fact_table");
       System.out.println(
         "    MAX\n" +
         "    ------");
 
       Statement stmt = con.createStatement();
       // perform a SELECT against the "fact_table" table.
       ResultSet rs1 = stmt.executeQuery("SELECT * FROM fact_table");
 
       // retrieve and display the result from the SELECT statement
       while (rs1.next())
       {
         max = rs1.getInt(1);
 
         System.out.println(
           "    " +
           Data.format(max, 6));
       }
       rs1.close();
       stmt.close();
     }
     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }
   } // DisplaytbData

   // shows the contents of table
   static void showData(Connection con) throws SQLException
   {
     try
     {
       int max = 0;
       int min = 0;

       System.out.println(
         "\n-----------------------------------------------------------\n" +
         "USE THE SQL STATEMENT:\n" +
         "  SELECT\n" +
         "ON fact_table TABLE.\n");
     } 

     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }

     try
     {
       Statement stmt = con.createStatement();
       ResultSet rs;
       int min = 0;
       int max = 0;

       System.out.println(
         "Execute the statement:\n" +
         "SELECT *  FROM fact_table\n");
       
       System.out.println(
         "   MIN     MAX     \n" +
         "  -----  ------");
 
       // perform a SELECT against the "fact_table" table 
       rs = stmt.executeQuery(
              "SELECT * FROM fact_table");

       // retrieve and display the result from the SELECT statement
       while (rs.next())
       {
         min = rs.getInt(1);
         max = rs.getInt(2);
 
         System.out.println(
          "    " +
           Data.format(min, 2) + " " +
           Data.format(max, 7));
       }
       rs.close();
     } 
     catch (Exception e)
     {
        JdbcException jdbcExc = new JdbcException(e, con);
        jdbcExc.handle();
     }
     
     try
     {
       System.out.println(
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENT:\n" +
       "  DROP \n" +
       "TO DROP THE TABLES  \n" +
       "  DROP TABLE fact_table");

       // drop the tables
       Statement stmt = con.createStatement();
       stmt.executeUpdate("DROP TABLE fact_table");
      
       con.commit();
       stmt.close();
     }
     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }
   } // showData

  // creates a partitioned table with 'part1' in 'dms_tspace1', 'part2' in
  // 'dms_tspace2' and 'part3' in 'dms_tspace3' with GENERATE IDENTITY clause
  static void createptb_with_GenerateIdentity(Connection con) 
  {
    try
      {
        System.out.println(
          "USE THE SQL STATEMENT:\n" +
          "  CREATE\n" + 
          "TO CREATE A PARTITIONED TABLE WITH GENERATE IDENTITY CLAUSE");

        System.out.println(
          "\nExecute the statement:" +
          "\nCREATE TABLE fact_table (min SMALLINT NOT NULL," +
          "\n               max SMALLINT GENERATED ALWAYS AS IDENTITY," +
          "\n               CONSTRAINT CC CHECK (min>0)) " +
          "\n  PARTITION BY RANGE (min)" +
          "\n    (PART  part1 STARTING FROM (1) ENDING (3) IN dms_tspace1," +
          "\n    PART part2 STARTING FROM (4) ENDING (6) IN dms_tspace2," +
          "\n    PART part3 STARTING FROM (7) ENDING (9) IN dms_tspace3)\n");
 
        Statement stmt = con.createStatement();
        String str = "";
 
        str = str + "CREATE TABLE fact_table (min SMALLINT NOT NULL, ";
        str = str + "          max SMALLINT GENERATED ALWAYS AS IDENTITY,";
        str = str + "          CONSTRAINT CC CHECK (min>0)) ";
        str = str + "  PARTITION BY RANGE (min)";
        str = str + "  (PART  part1 STARTING FROM (1) ENDING (3) IN dms_tspace1,";
        str = str + "  PART part2 STARTING FROM (4) ENDING (6) IN dms_tspace2,";
        str = str + "  PART part3 STARTING FROM (7) ENDING (9) IN dms_tspace3)";

        stmt.executeUpdate(str);
        con.commit();
        stmt.close();
 
      }
      catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e, con);
        jdbcExc.handle();
      }
  } // createptb_with_GenerateIdentity

  // creates a temporary table and inserts data into it. This also shows 
  // SET INTEGRITY operation on 'fact_table' with FORCE GENERATED clause 
  // to it.
  static void createptb_Temp(Connection con, String path) throws SQLException
   {
     // creates a partitioned table with GENERATE IDENTITY clause	   
     createptb_with_GenerateIdentity(con);

     try
     {
       // create a temporary table
        System.out.println(
          "Execute the statements:\n" +
          "CREATE TABLE temp_table (max INTEGER)\n ");
     
        Statement stmt = con.createStatement();
        String str = "";
  
        str = "CREATE TABLE temp_table (max INTEGER)";
        stmt.executeUpdate(str);
        con.commit();
        stmt.close();

        System.out.println(
          "INSERT INTO temp_table VALUES (1), (2), (3), (4), (5), (6)," +
	  " (7), (8), (9)");
   
        stmt = con.createStatement();
        str = "";
  
        str = "INSERT INTO temp_table VALUES(1), (2), (3), (4), (5), (6),";
	str = str + " (7), (8), (9)";
        stmt.executeUpdate(str);
        con.commit();
        stmt.close(); 
   
	// export data to a temporary table
        exportData(con, path);
        
	// load data from temporary table into base table
	loadData(con, path);
   
        System.out.println(
          "\nUSE THE SQL STATEMENT:\n" +
          "  SET INTEGRITY \n" +
          "To bring the table out of check pending state\n");
    
        System.out.println(
          "SET INTEGRITY FOR fact_table IMMEDIATE CHECKED FORCE GENERATED");

        stmt = con.createStatement();
        stmt.executeUpdate(
          "SET INTEGRITY FOR fact_table IMMEDIATE CHECKED FORCE GENERATED");

       // commit the transaction
        con.commit();
        stmt.close();
      }
      catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e, con);
        jdbcExc.handle();
      } 
  
      // shows the contents of table
      showData(con);
   } // createptb_Temp

   // creates temporary tables 'attach_part' and 'attach'. Insert data into
   // 'attach'. Exports data from 'attach' into 'dummy.del'. Perform LOAD
   // to load data from 'dummy.del' into 'attach_part'. Partition is added 
   // to 'fact_table' and SET INTEGRITY is performed on 'fact_table' to bring 
   // table out of check pending state.
   static void alterTable(Connection con, String path) throws SQLException
   {
     // creates a partitioned table with GENERATE IDENTITY clause 
     createptb_with_GenerateIdentity(con);

     // export data to a temporary table
     exportData(con, path);
     
     // load data from temporary table into base table
     loadData(con, path);
      
     Statement stmt = con.createStatement();
     String str = "";

     str = str + "CREATE TABLE attach_part (min SMALLINT NOT NULL, "; 
     str = str + "               max SMALLINT GENERATED ALWAYS AS IDENTITY,";
     str = str + "               CONSTRAINT CC CHECK (min>0))IN dms_tspace1";
     stmt.executeUpdate(str); 
     con.commit();
     stmt.close();

     stmt = con.createStatement();
     str = "";
     str = str + "CREATE TABLE attach(min SMALLINT NOT NULL)";
     stmt.executeUpdate(str);
     con.commit();
      
     str = ""; 
     str = str + "INSERT INTO attach VALUES (10), (11), (12)";
     stmt.executeUpdate(str);
     con.commit();
 
     try
     {
       String sql = "";
       String param = "";
       CallableStatement callStmt1 = null;
       ResultSet rs = null;
       stmt = con.createStatement();

       int rows_exported = 0;

       System.out.println(
         "\nUSE THE SQL STATEMENT:\n" +
         "  EXPORT \n" +
         "TO EXPORT TABLE DATA INTO A FILE \n" +
         "\nExecute the statement:\n" +
         "  EXPORT TO dummy.del OF DEL SELECT * FROM attach");

       // export data into a dummy file
       sql = "CALL SYSPROC.ADMIN_CMD(?)";
       callStmt1 = con.prepareCall(sql);

       // 'path' is the path for the file to which the data is to be exported
       param = "EXPORT TO " + path + "/dummy.del OF DEL SELECT * FROM attach";

       // set the input parameter
       callStmt1.setString(1, param);
       System.out.println();

       // execute export by calling ADMIN_CMD
       callStmt1.execute();
       rs = callStmt1.getResultSet();
       // retrieve the resultset
       if (rs.next())
       {
        // the numbers of rows exported
        rows_exported = rs.getInt(1);

       // display the output
       System.out.println
         ("Total number of rows exported  : " + rows_exported);
       }
      }
      catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e, con);
        jdbcExc.handle();
      }

      try
      {

        String sql = "";
        String param = "";
        CallableStatement callStmt1 = null;
        ResultSet rs = null;
        stmt = con.createStatement();

        int rows_read = 0;
        int rows_skipped = 0;
        int rows_loaded = 0;
        int rows_rejected = 0;
        int rows_deleted = 0;
        int rows_committed = 0;

        System.out.println(
          "\nUSE THE SQL STATEMENT:\n" +
          "  LOAD \n" +
          "TO LOAD THE DATA INTO THE TABLE \n" +
          "\nExecute the statement:\n" +
          "  LOAD FROM dummy.del OF DEL INSERT INTO attach_part");
 
        // Load data from file
        sql = "CALL SYSPROC.ADMIN_CMD(?)";
        callStmt1 = con.prepareCall(sql);

        // 'path' is the path of the file from which the data is to be loaded
        param = "LOAD FROM " + path + "/dummy.del OF DEL INSERT INTO attach_part";
 
        // set the input parameter
        callStmt1.setString(1, param);

        // execute import by calling ADMIN_CMD
        callStmt1.execute();
        rs = callStmt1.getResultSet();

        // retrieve the resultset
        if (rs.next())
        {
          // retrieve the no of rows read
          rows_read = rs.getInt(1);

          // retrieve the no of rows skipped
          rows_skipped = rs.getInt(2);

          // retrieve the no of rows loaded
          rows_loaded = rs.getInt(3);

          // retrieve the no of rows rejected
          rows_rejected = rs.getInt(4);

          // retrieve the no of rows deleted
          rows_deleted = rs.getInt(5);

          // retrieve the no of rows committed
          rows_committed = rs.getInt(6);

          // display the resultset
          System.out.print("\nTotal number of rows read      : ");
          System.out.println(rows_read);
          System.out.print("Total number of rows skipped   : ");
          System.out.println( rows_skipped);
          System.out.print("Total number of rows loaded    : ");
          System.out.println(rows_loaded);
          System.out.print("Total number of rows rejected  : ");
          System.out.println(rows_rejected);
          System.out.print("Total number of rows deleted   : ");
          System.out.println(rows_deleted);
          System.out.print("Total number of rows committed : ");
          System.out.println(rows_read);
       }
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
   
    System.out.println(
      "\nUSE THE SQL STATEMENT\n" +
      "  ALTER TABLE\n" +
      "TO ATTACH PARTITION TO A TABLE\n" +
      "\nExecute the statement:\n" +
      "  ALTER TABLE fact_table ATTACH PARTITION part4\n" +
      "    STARTING FROM (10) ENDING AT (12)\n" +
      "      FROM TABLE attach_part\n");

    stmt = con.createStatement();
    str = "";
    str = str + "ALTER TABLE fact_table ATTACH PARTITION part4";
    str = str + "  STARTING FROM (10) ENDING AT (12) FROM TABLE attach_part";
    stmt.executeUpdate(str);

    con.commit();
    stmt.close();

    // The following SET INTEGRITY statement will check the table fact_table
    // for constraint violations and at the same time the GENERATE IDENTITY
    // along with INCREMENTAL options will generate new identity values
    // for attached rows only.

    System.out.println(
      "\nUSE THE SQL STATEMENT\n" +
      "  SET INTEGRITY \n" +
      "TO BRING TABLE OUT OF CHECK PENDING STATE\n\n" +
      "Execute the statement:\n" +
      "  SET INTEGRITY FOR fact_table GENERATE IDENTITY\n" +
      "    IMMEDIATE CHECKED INCREMENTAL;");
  
    stmt = con.createStatement();
    str = ""; 
    str = str + "SET INTEGRITY FOR fact_table GENERATE IDENTITY";
    str = str + "  IMMEDIATE CHECKED INCREMENTAL";
    stmt.executeUpdate(str);

    con.commit();
    stmt.close();

    // shows the contents of table
    showData(con);

    System.out.println(
      "\nExecute the statements:\n" +
      "DROP TABLE temp_table\n" +
      "DROP TABLE attach");
  
    stmt = con.createStatement();
    stmt.executeUpdate("DROP TABLE temp_table");
    stmt.executeUpdate("DROP TABLE attach");
    con.commit();
    stmt.close();
 
  } // alterTable 

  // creates temporary table 'temp_table' and inserts data into it. Data is
  // exported from 'temp_table' to 'dummy.del' and later loaded into 
  // 'fact_table'. SET INTEGRITY with GENERATE IDENTITY clause is performed
  // on 'fact_table' to generate new identity values for all rows currently
  // in the table and all loaded rows.
  static void createtb_Temp(Connection con, String path) throws SQLException
  {
    // creates a partitioned table with GENERATE IDENTITY clause	  
    createptb_with_GenerateIdentity(con);

    try
    {
      System.out.println(
        "\nExecute the statement:" +
        "\n  CREATE TABLE temp_table (min SMALLINT NOT NULL)");

      Statement stmt = con.createStatement();
      String str = "";
 
      stmt.executeUpdate("CREATE TABLE temp_table (min SMALLINT NOT NULL)");
       
      System.out.println(
        "\nExecute the statements:\n" +
        "  INSERT INTO temp_table VALUES (1), (2), (3), (4), (5)\n" +
        "  INSERT INTO temp_table VALUES (6), (7), (8), (9)");
  
      str = str + "INSERT INTO temp_table VALUES (1), (2), (3), (4), (5),";
      str = str + " (6), (7), (8), (9)";
 
      stmt.executeUpdate(str);
      con.commit();
      stmt.close();
      
      // export data to a temporary table
      exportData(con, path);

      // load data from temporary table into base table
      loadData(con, path);
     
      // The following SET INTEGRITY statement will check the table 
      // fact_table for constraint violations and at the same time thei 
      // GENERATE IDENTITY along with NOT INCREMENTAL options will generate 
      // new identity values for all rows currently in the table and all 
      // loaded rows. 

      System.out.println(
        "\nUSE THE SQL STATEMENT\n" +
        "  SET INTEGRITY\n" +
        "TO TABLE OUT OF CHECK PENDING STATE:\n" +
        "\nExecute the statement:" +
        "\n  SET INTEGRITY FOR fact_table GENERATE IDENTITY \n" +
        "    IMMEDIATE CHECKED  NOT INCREMENTAL \n");

      stmt = con.createStatement();
      str = "";

      str = str + "SET INTEGRITY FOR fact_table GENERATE IDENTITY";
      str = str + "  IMMEDIATE CHECKED  NOT INCREMENTAL";
      stmt.executeUpdate(str);
      con.commit();
      stmt.close();

      // shows the contents of table
      showData(con);  
     
      System.out.println(
        "\nExecute the statement:\n" +
        "  DROP TABLE temp_table\n");
 
      stmt = con.createStatement();

      stmt.executeUpdate("DROP TABLE temp_table"); 
    
      con.commit();
      stmt.close();
    }
    catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }
  } // createtb_Temp

  // drops a tablespaces
  static void tablespacesDrop(Connection con) throws SQLException
  {
    try
    {
      System.out.println(
        "\n-----------------------------------------------------------" +
        "\nUSE THE SQL STATEMENT:\n" +
        "  DROP \n" +
        "TO DROP THE TABLESPACES  \n" +
        "\nExecute the statements:\n" +
        "  DROP TABLESPACE dms_tspace\n" +
        "  DROP TABLESPACE dms_tspace1\n" +
        "  DROP TABLESPACE dms_tspace2\n" +
        "  DROP TABLESPACE dms_tspace3");

      // drop the tablespaces
      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLESPACE dms_tspace");
      stmt.executeUpdate("DROP TABLESPACE dms_tspace1");
      stmt.executeUpdate("DROP TABLESPACE dms_tspace2");
      stmt.executeUpdate("DROP TABLESPACE dms_tspace3");

      con.commit();
      stmt.close();

     }
     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }
   } // tablespacesDrop
} // SetIntegrity  
