//***************************************************************************
//   (c) Copyright IBM Corp. 2007 All rights reserved.
//   
//   The following sample of source code ("Sample") is owned by International 
//   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
//   copyrighted and licensed, not sold. You may use, copy, modify, and 
//   distribute the Sample in any form without payment to IBM, for the purpose of 
//   assisting you in the development of your applications.
//   
//   The Sample code is provided to you on an "AS IS" basis, without warranty of 
//   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
//   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
//   not allow for the exclusion or limitation of implied warranties, so the above 
//   limitations or exclusions may not apply to you. IBM shall not be liable for 
//   any damages you suffer as a result of using, copying, modifying or 
//   distributing the Sample, even if IBM has been advised of the possibility of 
//   such damages.
//***************************************************************************
//                                                            
//  SAMPLE FILE NAME: TbRowcompress.java
//
//  PURPOSE: To demonstrate row compression and automatic dictionary creation.
//           
//    Row Compression:
//         1. How to enable the row compression after a table is created.
//         2. How to enable the row compression during table creation.
//         3. Usage of the options to REORG to use the exiting dictionary 
//            or creating a new dictionary.   
//         4. How to estimate the effectiveness of the compression.
//
//    Automatic Dictionary Creation:
//         1. When the compression dictionary will automatically be created.
//         2. Automatic dictionary creation with DML commands like INSERT, IMPORT and LOAD.
//         3. How to determine whether a new dictionary should be built or not. 
//         4. Automatic dictionary creation for a data partitioned table. 
// 
//  PREREQUISITE: NONE
//
//  EXECUTION:    i)  javac TbRowcompress.java   (compile the sample)
//                ii) java TbRowcompress.class <path for the dummy file>  (run the sample)
//                                                                          
//  INPUTS:       NONE
//
//  OUTPUTS:   successful creation of compression dictionary. 
//
//  OUTPUT FILE:  TbRowcompress.out (available in the online documentation) 
//                        
//  SQL STATEMENTS USED:
//         CREATE TABLE ... COMPRESS YES
//         CREATE PROCEDURE
//         CALL
//         ALTER TABLE 
//         DELETE
//         DROP TABLE
//         EXPORT
//         IMPORT
//         INSERT
//         INSPECT
//         LOAD
//         REORG
//         RUNSTATS
//         TERMINATE
//         UPDATE
//
//  SQL ROUTINES USED:  
//         SYSPROC.ADMIN_GET_TAB_COMPRESS_INFO
//
//  JAVA 2 CLASSES USED:
//         Statement
//         CallableStatement
//         ResultSet
//
//  Classes used from Util.java are:
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
// *************************************************************************
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//      http://www.software.ibm.com/data/db2/udb/ad
// *************************************************************************/                       //
//  SAMPLE DESCRIPTION                                                      
//
// /*************************************************************************
//
// *************************************************************************
//  1. ROW COMPRESSION 
//  2. AUTOMATIC DICTIONARY CREATION
// *************************************************************************/

import java.lang.*;
import java.sql.*;

class TbRowcompress
{
  public static void main(String argv[])
  {
    if (argv.length < 1)
    {
      System.out.println("\n Usage : java TbRowcompress" +
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
          "This sample demonstrates row compression and automatic dictionary creation.");

        // *************************************************************************
        //  1. ROW COMPRESSION 
        // *************************************************************************

        // to Load table data into a file.
        getLoadData(con, path);

        // to Enable Row compression on table.
        enableRowCompressionForTables(con, path); 

        // to disable row compression on tables.
        disableRowCompressionForTables(con, path); 

        // to inspect the compression.
        inspectCompression(con, path); 

        // *************************************************************************
        //  2. AUTOMATIC DICTIONARY CREATION
        // *************************************************************************

        // to demonstrate automatic dictionary creation
        AutomaticDictionaryCreation(con, path);

        // close the connection                                   
        con.close();

      }
      catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e);
        jdbcExc.handle();
      }
    }
  } // main

  static void getLoadData(Connection con, String path) throws SQLException
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
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENTS:\n" +
       "  CREATE TABLE \n" +
       "TO CREATE A TABLE \n" +
       "\n    Perform:\n" +
       "    CREATE TABLE temp(empno INT, sal INT)");

     // create a temporary table
     stmt.executeUpdate("CREATE TABLE temp(empno INT, sal INT)");

     // insert data into the table and export the data in order to obtain
     // dummy.del file in the required format for load.

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  INSERT \n" +
       "TO INSERT DATA INTO THE TABLE \n" +
       "\n    Perform:\n" +
       "    INSERT INTO temp");

     // insert data into the table
     stmt = con.createStatement();
     for(int count=1; count< 1000; count++)
     {
     stmt.executeUpdate("INSERT INTO temp VALUES(100, 20000)");
     stmt.executeUpdate("INSERT INTO temp VALUES(200, 30000)");
     stmt.executeUpdate("INSERT INTO temp VALUES(100, 30500)");
     stmt.executeUpdate("INSERT INTO temp VALUES(300, 20000)");
     stmt.executeUpdate("INSERT INTO temp VALUES(400, 30000)");
     }
     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  EXPORT \n" +
       "TO EXPORT TABLE DATA INTO A FILE \n" +
       "\n    Perform:\n" +
       "    EXPORT TO dummy.del OF DEL SELECT * FROM temp");

     // export data into a dummy file
     sql = "CALL SYSPROC.ADMIN_CMD(?)";
     callStmt1 = con.prepareCall(sql);

     // 'path' is the path for the file to which the data is to be exported
     param = "EXPORT TO " + path + "dummy.del OF DEL SELECT * FROM temp" ;

     // set the input parameter
     callStmt1.setString(1, param);
     System.out.println();

     // execute import by calling ADMIN_CMD
     callStmt1.execute();

     rs = callStmt1.getResultSet();
      
     // retrieve the resultset  
     if( rs.next())
     { 
       // the numbers of rows exported
       rows_exported = rs.getInt(1);

       // display the output
       System.out.println
         ("Total number of rows exported  : " + rows_exported);
     } 

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  DROP \n" +
       "TO DROP THE TABLE \n" +
       "\n    Perform:\n" +
       "    DROP TABLE temp");

     // drop the temporary table
     stmt = con.createStatement();
     stmt.executeUpdate("DROP TABLE temp");

     con.commit();
     stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // getLoadData

  static void enableRowCompressionForTables
                (Connection con, String path) throws SQLException
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
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENTS:\n" +
       "  CREATE TABLE \n" +
       "TO CREATE A TABLE \n" +
       "\n    Perform:\n" +
       "    CREATE TABLE empl(emp_no INT, salary INT)");

     // create a table without enabling row compression at the time of
     // table creation
     stmt = con.createStatement();
     stmt.executeUpdate("CREATE TABLE empl(emp_no INT, salary INT)");

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  IMPORT \n" +
       "TO IMPORT THE DATA INTO THE TABLE \n" +
       "\n    Perform:\n" +
       "    IMPORT FROM dummy.del OF DEL INSERT INTO empl");

     // import data from file
     sql = "CALL SYSPROC.ADMIN_CMD(?)";
     callStmt1 = con.prepareCall(sql);

     // 'path' is the path for the file to be loaded
     param = "IMPORT FROM " + path + "dummy.del OF DEL INSERT INTO empl" ;

     // set the input parameter
     callStmt1.setString(1, param);
       
     // execute import by calling ADMIN_CMD
     callStmt1.execute();
     rs = callStmt1.getResultSet();
      
     // retrieve the resultset  
     if( rs.next())
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

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  ALTER TABLE \n" +
        "TO ENABLE ROW COMPRESSION \n" +
        "\n    Perform:\n" +
        "    ALTER TABLE empl COMPRESS YES");

      // enable row compression
      stmt = con.createStatement();
      stmt.executeUpdate("ALTER TABLE empl COMPRESS YES");

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  REORG \n" +
        "TO COMPRESS ROWS \n" +
        "\n    Perform:\n" +
        "    REORG TABLE empl");

      // perform non-inplace reorg to compress rows and to retain
      // existing dictionary
      sql = "CALL SYSPROC.ADMIN_CMD(?)";
      callStmt1 = con.prepareCall(sql);

      param = "REORG TABLE empl" ;
 
      // set the input parameter
      callStmt1.setString(1, param);
        
      // execute import by calling ADMIN_CMD
      callStmt1.execute();

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  DROP \n" +
        "TO DROP THE TABLE \n" +
        "\n    Perform:\n" +
        "    DROP TABLE empl");
 
      // drop the temporary table
      stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE empl");
 
      con.commit();
      stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // enableRowCompressionForTables

  static void disableRowCompressionForTables
                (Connection con, String path) throws SQLException
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
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENTS:\n" +
       "  CREATE \n" +
       "TO CREATE A TABLE \n" +
       "\n    Perform:\n" +
       "    CREATE TABLE empl(emp_no INT, salary INT) COMPRESS YES");

     // create a table enabling compression initially
     stmt = con.createStatement();
     stmt.executeUpdate
            ("CREATE TABLE empl(emp_no INT, salary INT) COMPRESS YES");

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  IMPORT \n" +
       "TO IMPORT THE DATA INTO THE TABLE \n" +
       "\n    Perform:\n" +
       "    IMPORT FROM dummy.del OF DEL INSERT INTO empl");

     // load data into table
     sql = "CALL SYSPROC.ADMIN_CMD(?)";
     callStmt1 = con.prepareCall(sql);

     // 'path' is the path for the file to be loaded
     param = "IMPORT FROM " + path + "dummy.del OF DEL INSERT INTO empl" ;

     // set the input parameter
     callStmt1.setString(1, param);
       
     // execute import by calling ADMIN_CMD
     callStmt1.execute();
     rs = callStmt1.getResultSet();
      
     // retrieve the resultset  
     if( rs.next())
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

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  REORG \n" +
       "TO COMPRESS ROWS \n" +
       "\n    Perform:\n" +
       "    REORG TABLE empl");

     // perform reorg to compress rows
     param = "REORG TABLE empl" ;

     // set the input parameter
     callStmt1.setString(1, param);
       
     // execute import by calling ADMIN_CMD
     callStmt1.execute();

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  INSERT \n" +
       "  UPDATE \n" +
       "  DELETE \n" +
       "TO INSERT, UPDATE OR DELETE DATA IN TABLE \n" +
       "\n    Perform:\n" +
       "    INSERT INTO empl VALUES(400, 30000)\n" +
       "    UPDATE empl SET salary = salary + 1000\n" +
       "    DELETE FROM empl WHERE emp_no = 200");

     // perform modifications on table
     stmt = con.createStatement();
     stmt.executeUpdate("INSERT INTO empl VALUES(400, 30000)");
     stmt.executeUpdate("UPDATE empl SET salary = salary + 1000");
     stmt.executeUpdate("DELETE FROM empl WHERE emp_no = 200");

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  ALTER TABLE \n" +
       "TO DISABLE ROW COMPRESSION FOR THE TABLE \n" +
       "\n    Perform:\n" +
       "    ALTER TABLE empl COMPRESS NO");

     // disable row compression for the table
     stmt = con.createStatement();
     stmt.executeUpdate("ALTER TABLE empl COMPRESS NO");

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  REORG TABLE \n" +
       "TO REORG THE TABLE AND REMOVE EXISTING DICTIONARY \n" +
       "\n    Perform:\n" +
       "    REORG TABLE empl RESETDICTIONARY");

     // Perform reorg to remove existing dictionary.
     // New dictionary will be created and all the rows processed
     // by the reorg are decompressed.
     param = "REORG TABLE empl RESETDICTIONARY" ;

     // set the input parameter
     callStmt1.setString(1, param);
       
     // execute import by calling ADMIN_CMD
     callStmt1.execute();

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  DROP \n" +
       "TO DROP THE TABLE \n" +
       "\n    Perform:\n" +
       "    DROP TABLE empl");

     // drop the table
     stmt = con.createStatement();
     stmt.executeUpdate("DROP TABLE empl");
     
     con.commit();
     stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // disableRowCompressionForTables

  static void inspectCompression
                (Connection con, String path) throws SQLException
  {
    try
    {
     String sql = null;
     String param = null;
     String str = null;
     ResultSet rs = null;
     Statement stmt = con.createStatement();

     CallableStatement callStmt1 = null;

     int emp_no = 0;
     int sal = 0;

     int rows_read = 0;
     int rows_skipped = 0;
     int rows_loaded = 0;
     int rows_rejected = 0;
     int rows_deleted = 0;
     int rows_committed = 0;

     int avgrowsize = 0;
     int avgcompressedrowsize = 0;
     int pctpagessaved = 0;
     int avgrowcompressionratio = 0;
     int pctrowscompressed = 0;

     System.out.println(
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENTS:\n" +
       "  CREATE TABLE \n" +
       "TO CREATE A TABLE \n" +
       "\n    Perform:\n" +
       "    CREATE TABLE empl(emp_no INT, salary INT)");

     // create a table
     stmt = con.createStatement();
     stmt.executeUpdate("CREATE TABLE empl(emp_no INT, salary INT)");

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  IMPORT \n" +
       "TO IMPORT DATA INTO TABLE \n" +
       "\n    Perform:\n" +
       "    IMPORT FROM dummy.del OF DEL INSERT INTO empl");

     // import data into the table
     sql = "CALL SYSPROC.ADMIN_CMD(?)";
     callStmt1 = con.prepareCall(sql);

     // 'path' is the path for the file to be loaded
     param = "IMPORT FROM " + path + "dummy.del OF DEL INSERT INTO empl" ;

     // set the input parameter
     callStmt1.setString(1, param);
            
     // execute import by calling ADMIN_CMD
     callStmt1.execute();
     rs = callStmt1.getResultSet();
      
     // retrieve the resultset  
     if( rs.next())
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

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  ALTER TABLE \n" +
        "TO ENABLE COMPRESSION \n" +
        "\n    Perform:\n" +
        "    ALTER TABLE empl COMPRESS YES");

      // enable row compression for the table
      stmt = con.createStatement();
      stmt.executeUpdate("ALTER TABLE empl COMPRESS YES");

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  INSERT \n" +
        "TO INSERT DATA INTO THE TABLE \n" +
        "\n    Perform:\n" +
        "    INSERT INTO empl VALUES(400, 30000)");
 
      // insert some data into the table
      stmt = con.createStatement();
      stmt.executeUpdate("INSERT INTO empl VALUES(400, 30000)");
 
      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  INSPECT \n" +
        "TO ESTIMATE THE EFFECTIVENESS OF COMPRESSION \n" +
        "\n    Perform:\n" +
        "    INSPECT ROWCOMPESTIMATE TABLE NAME empl RESULTS KEEP result");
 
      // Perform inspect to estimate the effectiveness of compression.
      // Inspect has to be run before the REORG utility.
      // Inspect allows you to look over tablespaces and tables for their
      // architectural integrity.
      // 'result' file contains percentage of bytes saved from compression,
      // Percentage of rows ineligible for compression due to small row size,
      // Compression dictionary size, Expansion dictionary size etc.
      // To view the contents of 'result' file perform
      //    db2inspf result result.out; This formats the 'result' file to
      // readable form.
 
      String execCmd = "db2 INSPECT ROWCOMPESTIMATE TABLE NAME empl" +
                       " RESULTS KEEP result";

      // execute the command
      Process p1 = Runtime.getRuntime().exec(execCmd);

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  REORG \n" +
        "TO REORG THE TABLE \n" +
        "\n    Perform:\n" +
        "    REORG TABLE empl");
 
      // perform reorg on the table
 
      param = "REORG TABLE empl" ;

      // set the input parameter
      callStmt1.setString(1, param);
       
      // execute import by calling ADMIN_CMD
      callStmt1.execute();

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  INSERT \n" +
        "TO INSERT DATA INTO THE TABLE \n" +
        "\n    Perform:\n" +
        "    INSERT INTO empl VALUES(500, 40000)");
 
      // all the rows will be compressed including the one inserted
      // after reorg
      stmt = con.createStatement();
      stmt.executeUpdate("INSERT INTO empl VALUES(500, 40000)");
 
      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  ALTER TABLE \n" +
        "TO DISABLE THE COMPRESSION \n" +
        "\n    Perform:\n" +
        "    ALTER TABLE empl COMPRESS NO");

      // disable row compression for the table.
      // rows inserted after this will be non-compressed.
      stmt = con.createStatement();
      stmt.executeUpdate("ALTER TABLE empl COMPRESS NO");

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  INSERT \n" +
        "TO INSERT DATA INTO THE TABLE \n" +
        "\n    Perform:\n" +
        "    INSERT INTO empl VALUES(600, 40500)");

      // add one row of data to the table
      stmt = con.createStatement();
      stmt.executeUpdate("INSERT INTO empl VALUES(600, 40500)");
 
      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  ALTER TABLE \n" +
        "TO ENABLE THE COMPRESSION \n" +
        "\n    Perform:\n" +
        "    ALTER TABLE empl COMPRESS YES");

     // enable the row compression for the table
     stmt = con.createStatement();
     stmt.executeUpdate("ALTER TABLE empl COMPRESS YES");

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  INSERT \n" +
       "TO INSERT DATA INTO THE TABLE \n" +
       "\n    Perform:\n" +
       "    INSERT INTO empl VALUES(700, 40600)");

     // add one row of data to the table
     stmt = con.createStatement();
     stmt.executeUpdate("INSERT INTO empl VALUES(700, 40600)");

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  RUNSTATS \n" +
       "TO MEASURE THE EFFECTIVENESS OF COMPRESSION \n" +
       "\n    Perform:\n" +
       "    RUNSTATS ON TABLE EMPL");

     // Perform runstats to measure the effectiveness of compression using
     // compression related catalog fields. New columns will be updated to
     // catalog table after runstats if performed on a compressed table.

     // get fully qualified name of the table
     String tableName = "EMPL";
     String schemaName = getSchemaName(con, tableName);
     String fullTableName = schemaName + "." + tableName;

     param = "RUNSTATS ON TABLE " + fullTableName;

     // set the input parameter
     callStmt1.setString(1, param);
            
     // execute import by calling ADMIN_CMD
     callStmt1.execute();

     System.out.println();
     System.out.println(
       "SELECT avgrowsize, avgcompressedrowsize, pctpagessaved,\n" +
       "       avgrowcompressionratio, pctrowscompressed\n" +
       "  FROM SYSCAT.TABLES WHERE tabname = 'EMPL'");
     System.out.println(
       "\n    AvRowSize AvCmprsdRowSize PerPgSaved AvgRowCmprRatio" +
       " PerRowsCmprsd\n" +
       "    --------- --------------- ---------- ---------------" +
       " -------------");

      stmt = con.createStatement();
      // perform a SELECT against the "SYSCAT.TABLES" table.
      str = "SELECT avgrowsize, avgcompressedrowsize, pctpagessaved, " + 
            "avgrowcompressionratio, pctrowscompressed from " +
            "SYSCAT.TABLES WHERE tabname = 'EMPL'";
      rs = stmt.executeQuery(str);

      // retrieve and display the result from the SELECT statement
      while (rs.next())
      {
        avgrowsize = rs.getInt(1);
        avgcompressedrowsize = rs.getInt(2);
        pctpagessaved = rs.getInt(3);
        avgrowcompressionratio = rs.getInt(4);
        pctrowscompressed = rs.getInt(5);

        System.out.println(
          "    " + Data.format(avgrowsize, 4) +
          "    " + Data.format(avgcompressedrowsize, 11) +
          "    " + Data.format(pctpagessaved, 9) +
          "    " + Data.format(avgrowcompressionratio, 9) +
          "    " + Data.format(pctrowscompressed, 13));

      }
      rs.close();

      System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  DROP \n" +
        "TO DROP THE TABLE \n" +
        "\n    Perform:\n" +
        "    DROP TABLE empl");

      // drop the temporary table
      stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE empl");

      con.commit();
      stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // inspectCompression

 
 static void AutomaticDictionaryCreation
                (Connection con, String path) throws SQLException
  {
    try
    {
     String sql = "";
     String param = "";
     String tabschema = "";
     CallableStatement callStmt1 = null;
     ResultSet rs = null;
     Statement stmt = con.createStatement();

     int rows_read = 0;
     int rows_skipped = 0;
     int rows_loaded = 0;
     int rows_rejected = 0;
     int rows_deleted = 0;
     int rows_committed = 0;

     String dictbuilder = "";
     long compressdictsize = 0;
     long expanddictsize = 0;
     int pagessavedpercent = 0;
     int bytessavedpercent = 0;

     System.out.println(
       "\n ---------------------------------------------------------------------------" +
       "\n USE THE SQL STATEMENTS:\n" +
       "  CREATE \n" +
       "TO CREATE A TABLE \n" +
       "\n    Perform:\n" +
       "    CREATE TABLE emptable(emp_no INT, name VARCHAR(120),joindate DATE) COMPRESS YES");

     // create the table enabling compression initially
     stmt = con.createStatement();
     stmt.executeUpdate
           ("CREATE TABLE emptable(emp_no INT, name VARCHAR(120),joindate DATE) COMPRESS YES");
 
     tabschema = getSchemaName(con, "EMPTABLE"); 
     // insert data into the table and export the data in order to obtain
     // dummy.del file in the required format for load.

     System.out.println("\n Insert data into the table until the table size threshold is breached");

     // insert data into the table
     stmt = con.createStatement();

     for(int count=1; count< 8000; count++)
     { 
     stmt.executeUpdate("INSERT INTO emptable VALUES(10, 'Padma Kota', '2001-12-02')");
     stmt.executeUpdate("INSERT INTO emptable VALUES(30, 'Doug Foulds', '1898-08-08')");
     stmt.executeUpdate("INSERT INTO emptable VALUES(50, 'Kathy Smith', '2006-12-02')");
     stmt.executeUpdate("INSERT INTO emptable VALUES(75, 'Brad Cassels', '1984-04-06')");
     stmt.executeUpdate("INSERT INTO emptable VALUES(90, 'Kelly Booch', '2003-12-02')");
     }

     stmt = con.createStatement();
     // perform a SELECT against the table function SYSPROC.ADMIN_GET_TAB_COMPRESS_INFO.
     String str = "SELECT dict_builder, compress_dict_size, expand_dict_size, pages_saved_percent, bytes_saved_percent FROM table(sysproc.admin_get_tab_compress_info('" + tabschema +"','EMPTABLE','REPORT')) as temp";
      rs = stmt.executeQuery(str);

      // retrieve and display the result from the SELECT statement
      if (rs.next())
      {

      dictbuilder = rs.getString(1);
      compressdictsize = rs.getLong(2);
      expanddictsize = rs.getLong(3);
      pagessavedpercent = rs.getInt(4);
      bytessavedpercent = rs.getInt(5);

      System.out.println(
          "    " + "dict_builder" +
          "    " + "compress_dict_size" +
          "    " + "expand_dict_size" +
          "    " + "pages_saved_percent" +
          "    " + "bytes_saved_percent");

      System.out.println(
          "    " + dictbuilder +
          "    " + compressdictsize +
          "    " + expanddictsize +
          "    " + pagessavedpercent +
          "    " + bytessavedpercent);

      }
      rs.close();

      System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  EXPORT \n" +
       "TO EXPORT TABLE DATA INTO A FILE \n" +
       "\n    Perform:\n" +
       "    EXPORT TO data.del OF DEL SELECT * FROM emptable");

     // export data into a dummy file
     sql = "CALL SYSPROC.ADMIN_CMD(?)";
     callStmt1 = con.prepareCall(sql);

     // 'path' is the path for the file to which the data is to be exported
     param = "EXPORT TO " + path + "data1.del OF DEL SELECT * FROM emptable" ;

     // set the input parameter
     callStmt1.setString(1, param);
     System.out.println();

     // execute import by calling ADMIN_CMD
     callStmt1.execute();

     rs = callStmt1.getResultSet();
      
     // retrieve the resultset  
     if( rs.next())
     { 
       // the numbers of rows exported
       int rows_exported = rs.getInt(1);

       // display the output
       System.out.println
         ("Total number of rows exported  : " + rows_exported);
     } 

     System.out.println(
        "\nUSE THE SQL STATEMENTS:\n" +
        "  DROP \n" +
        "TO DROP THE TABLE \n" +
        "\n    Perform:\n" +
        "    DROP TABLE emptable");

      // drop the temporary table
      stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE emptable");

      con.commit();
      
      System.out.println(
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENTS:\n" +
       "  CREATE \n" +
       "TO CREATE A TABLE \n" +
       "\n    Perform:\n" +
       "    CREATE TABLE emptable(emp_no INT, name VARCHAR(120),joindate DATE) COMPRESS YES");

     // create a table enabling compression initially
     stmt = con.createStatement();
     stmt.executeUpdate
            ("CREATE TABLE emptable(emp_no INT, name VARCHAR(120),joindate DATE) COMPRESS YES");


     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  IMPORT \n" +
       "TO IMPORT THE DATA INTO THE TABLE \n" +
       "\n    Perform:\n" +
       "    IMPORT FROM data1.del OF DEL INSERT INTO emptable");

     // load data into table
     sql = "CALL SYSPROC.ADMIN_CMD(?)";
     callStmt1 = con.prepareCall(sql);

     // 'path' is the path for the file to be loaded
     param = "IMPORT FROM " + path + "data1.del OF DEL INSERT INTO emptable" ;

     // set the input parameter
     callStmt1.setString(1, param);

     // execute import by calling ADMIN_CMD
     callStmt1.execute();
     rs = callStmt1.getResultSet();

     // retrieve the resultset
     if( rs.next())
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
    
      // perform a SELECT against the table function SYSPROC.ADMIN_GET_TAB_COMPRESS_INFO.
      str = "SELECT dict_builder, compress_dict_size, expand_dict_size, pages_saved_percent, bytes_saved_percent FROM table(sysproc.admin_get_tab_compress_info('" + tabschema +"','EMPTABLE','REPORT')) as temp";
      rs = stmt.executeQuery(str);

      // retrieve and display the result from the SELECT statement
      if (rs.next())
      {

      dictbuilder = rs.getString(1);
      compressdictsize = rs.getLong(2);
      expanddictsize = rs.getLong(3);
      pagessavedpercent = rs.getInt(4);
      bytessavedpercent = rs.getInt(5);

      System.out.println(
          "    " + "dict_builder" +
          "    " + "compress_dict_size" +
          "    " + "expand_dict_size" +
          "    " + "pages_saved_percent" +
          "    " + "bytes_saved_percent");

      System.out.println(
          "    " + dictbuilder +
          "    " + compressdictsize +
          "    " + expanddictsize +
          "    " + pagessavedpercent +
          "    " + bytessavedpercent);

      }
      rs.close();

     System.out.println(
       "\nUSE THE SQL STATEMENTS:\n" +
       "  DROP \n" +
       "TO DROP THE TABLE \n" +
       "\n    Perform:\n" +
       "    DROP TABLE emptable");

     // drop the table
     stmt = con.createStatement();
     stmt.executeUpdate("DROP TABLE emptable");

     con.commit();
     stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }

  // function to get the schema name for a particular table
  static String getSchemaName
                  (Connection conn, String tableName) throws Exception
  {
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery(
                     "SELECT tabschema "+
                     "  FROM syscat.tables "+
                     "  WHERE tabname = '"+ tableName + "'");
    boolean result = rs.next();
    String schemaName = rs.getString(1);

    rs.close();
    stmt.close();

    // remove the trailing white space characters from schemaName before
    // returning it to the calling function
    return schemaName.trim();
  } // getSchemaName
} // TbRowcompress
