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
// SOURCE FILE NAME: TbTemp.java
//
// SAMPLE: How to use Declared Temporary Table
//
//         This sample:
//         1. Creates a user temporary table space required for declared 
//            temporary tables
//         2. Creates and populates a declared temporary table 
//         3. Shows that the declared temporary table exists after a commit 
//            and shows the declared temporary table's use in a procedure
//         4. Shows that the temporary table can be recreated with the same 
//            name using the "with replace" option and without "not logged"
//            clause, to enable logging.
//         5. Shows the creation of an index on the temporary table.
//         6. Show the usage of "describe" command to obtain information
//            regarding the tempraroy table.
//         7. Shows that the temporary table is implicitly dropped with a  
//            disconnect from the database
//         8. Drops the user temporary table space
//
//         To Run on the Command line:
//         javac TbTemp.java
//         java TbTemp [dbUserName][password]
//
//         This sample assumes that the database specified by databaseAlias
//         contains a table named "department" and that the table's structure
//         is the same as the one for the department table in the SAMPLE
//         database.
//
//         The following objects are made and later removed:
//         (If objects with these names already exist, an error message will
//         be printed out.)
//         1. a user temporary tablespace named usertemp1
//         2. a declared global temporary table named temptb1
//
//
// SQL STATEMENTS USED:
//         CREATE USER TEMPORARY TABLESPACE
//         DECLARE GLOBAL TEMPORARY TABLE
//         INSERT
//         DROP TABLESPACE
//
// JAVA 2 CLASSES USED:
//         Statement
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
// OUTPUT FILE: TbTemp.out (available in the online documentation)
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
import java.lang.*;
import java.io.*;

public class TbTemp
{
  public static void main (String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("HOW TO USE DECLARED TEMPORARY TABLES.\n");

      // connect to the 'sample' database
      db.connect();

      // make sure a user temporary table space exists before creating
      // the table
      createTablespace(db.con);

      // show how to make a declared temporary table
      declareTempTable(db.con);

      // show that the temporary table exists in ShowAfterCommit() even
      // though it was declared in declareTempTable(). The temporary table
      // is accessible to the whole session as the connection still exists
      // at this point. Show that the temporary table exists after a commit.
      showAfterCommit(db.con);

      // declare the temporary table again. The old one will be dropped and
      // a new one will be made.
      recreateTempTableWithLogging(db.con);
      db.con.commit();

      // create an index for the global temporary table 
      createIndex(db.con);
      
      // use the ResultSetMetaData to describe the temp table 
      describeTemporaryTable(db.con);
      
      // disconnect from the 'sample' database. This implicitly drops the
      // temporary table. Alternatively, an explicit drop statement could
      // have been used.
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

    try
    {
      Db db = new Db(argv);

      // connect to the 'sample' database
      db.connect();
      dropTablespace(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // Create a user temporary tablespace for the temp table.  A user
  // temporary tablespace is required for temp tables and none are created
  // at database creation time.
  static void createTablespace(Connection conn) throws SQLException
  {
    System.out.println(
      "\n-----------------------------------------------------------" +
      "\nUSE THE SQL STATEMENTS:\n" +
      "  CREATE USER TEMPORARY TABLESPACE \n" +
      "TO MAKE A USER TEMPORARY TABLESPACE FOR THE TEMP TABLE \n" +
      "IN A DIRECTORY CALLED usertemp, RELATIVE TO THE DATABASE" +
      "\n  Perform:\n" +
      "    CREATE USER TEMPORARY TABLESPACE usertemp1");

    Statement stmt = conn.createStatement();
    stmt.executeUpdate("CREATE USER TEMPORARY TABLESPACE usertemp1");
    conn.commit();
    stmt.close();
  } // createTableSpace()

  // Declare a temporary table with the same columns as the one for the
  // database's department table.  Populate the temporary table and
  // show the contents.
  static void declareTempTable(Connection conn) throws Exception
  {
    // Declare the declared temporary table.  It is created empty.
    System.out.println(
      "\n-----------------------------------------------------------" +
      "\nUSE THE SQL STATEMENTS:\n" +
      "  DECLARE GLOBAL TEMPORARY TABLE\n" +
      "TO MAKE A GLOBAL DECLARED TEMPORARY TABLE WITH THE SAME \n" +
      "COLUMNS AS THE DEPARTMENT TABLE." +
      "\n  Perform:\n" +
      "    DECLARE GLOBAL TEMPORARY TABLE temptb1 \n" +
      "      LIKE department \n" +
      "      NOT LOGGED\n");

    Statement stmt = conn.createStatement();
    stmt.executeUpdate("DECLARE GLOBAL TEMPORARY TABLE temptb1 " +
                       "  LIKE department " +
                       "  NOT LOGGED " +
                       "  IN usertemp1");
    conn.commit();
    stmt.close();

    populateTempTable(conn);
    showTableContents(conn);

  } // declareTempTable()

  // Drop the user temp tablespace.  This function assumes that the tablespace
  // can be dropped. If the declared temporary table still exists in the
  // tablespace, then the tablespace cannot be dropped.
  static void dropTablespace(Connection conn) throws SQLException
  {
    System.out.println(
      "\n-----------------------------------------------------------" +
      "\nUSE THE SQL STATEMENTS:\n" +
      "  DROP TABLESPACE \n" +
      "TO REMOVE THE TABLESPACE THAT THIS PROGRAM CREATED\n" +
      "\n  Perform:\n" +
      "    DROP TABLESPACE usertemp1\n");

    Statement stmt = conn.createStatement();
    stmt.executeUpdate("DROP TABLESPACE usertemp1");
    conn.commit();
    stmt.close();

  } // dropTablespace()

  // Populate the temp table with the department table's contents
  static void populateTempTable(Connection conn) throws Exception
  {
    // Populating the temp table is done the same way as a normal table
    // except the qualifier "session" is required whenever the table name
    // is referenced.
    System.out.println(
      "\nUSE THE SQL STATEMENTS:\n" +
      "  INSERT\n" +
      "TO POPULATE THE DECLARED TEMPORARY TABLE WITH DATA FROM\n" +
      "THE DEPARTMENT TABLE\n" +
      "\n  Perform:\n" +
      "    INSERT INTO session.temptb1\n" +
      "      (SELECT deptno, deptname, mgrno, admrdept, location\n" +
      "         FROM department)\n");

    Statement stmt = conn.createStatement();
      
    stmt.executeUpdate(
      "INSERT INTO session.temptb1 " +
      "(SELECT deptno, deptname, mgrno, admrdept, location FROM department)");

    stmt.close();

  } // populateTempTable()

  // Declare the temp table temptb1 again, this time with logging option,
  // thereby replacing the existing one. If the "with replace" option is not
  // used, then an error will result if the table name is already associated
  // with an existing temp table. Populate and show contents again.
  static void recreateTempTableWithLogging(Connection conn) throws Exception
  {
    // Declare the declared temporary table again, this time without the
    // NOT LOGGED clause. It is created empty.
    System.out.println(
      "\n-----------------------------------------------------------" +
      "\nUSE THE SQL STATEMENTS:\n" +
      "\nDECLARE GLOBAL TEMPORARY TABLE\n" +
      "TO REPLACE A GLOBAL DECLARED TEMPORARY TABLE WITH A NEW\n" +
      "TEMPORARY TABLE OF THE SAME NAME WITH LOGGING ENABLED.\n" +
      "\n  Perform:\n" +
      "    DECLARE GLOBAL TEMPORARY TABLE temptb1 \n" +
      "      LIKE department \n" +
      "      WITH REPLACE\n" +
      "      ON COMMIT PRESERVE ROWS\n" +
      "      IN usertemp1");

    Statement stmt = conn.createStatement();
    stmt.executeUpdate("DECLARE GLOBAL TEMPORARY TABLE temptb1 " +
                       "  LIKE department " +
                       "  WITH REPLACE " +
                       "  ON COMMIT PRESERVE ROWS " +
                       "  IN usertemp1");
    stmt.close();

    populateTempTable(conn);
    showTableContents(conn);

  } // recreateTempTableWithLogging()

  // Show that the temp table still exists after the commit. All the
  // rows will be deleted because the temp table was declared, by default,
  // with "on commit delete rows".  If "on commit preserve rows" was used,
  // then the rows would have remained.
  static void showAfterCommit(Connection conn) throws Exception
  {
    System.out.println(
      "\n-----------------------------------------------------------" +
      "\nUSE THE SQL STATEMENTS:\n" +
      "  COMMIT\n" +
      "TO SHOW THAT THE TEMP TABLE EXISTS AFTER A COMMIT BUT WITH\n" +
      "ALL ROWS DELETED\n" +
      "\n  Perform:\n" +
      "    COMMIT\n");


    conn.commit();

    showTableContents(conn);

  } // showAftercommit()

  // Use cursors to access each row of the declared temp table and then print
  // each row.  This function assumes that the declared temp table exists.
  // This access is the same as accessing a normal table except the qualifier,
  // "session", is required in the table name.
  static void showTableContents(Connection conn) throws Exception
  {

    // Variables to store data from the department table

    String deptno = "";
    String deptname = "";
    String mgrno = "";
    String admrdept = "";
    String location = "";

    System.out.println("\n  SELECT * FROM session.temptb1\n");
    System.out.println(
      "    DEPT#   DEPTNAME                     MGRNO   ADMRDEPT  LOCATION\n"+
      "    -----  ----------------------------  ------  --------  --------");

    Statement stmt = conn.createStatement();
    
    ResultSet rs = stmt.executeQuery("SELECT * FROM session.temptb1");

    while (rs.next())//Fetch a row of data
    {
      try
      {
        deptno = rs.getObject("deptno").toString();
      }
      catch (Exception e)
      {
        deptno = "    -";
      }

      try
      {
        deptname = rs.getObject("deptname").toString();

        if (deptname.length() < 28) // For GUI purposes
        {
          int l = 28 - deptname.length();
          while (l != 0)
          {
            deptname = deptname + " ";
            l--;
          }
        }
      }
      catch (Exception e)
      {
        deptname = "                           -";
      }

      try
      {
        mgrno = rs.getObject("mgrno").toString();
      }
      catch (Exception e)
      {
        mgrno = "     -";
      }

      try
      {
        admrdept = rs.getObject("admrdept").toString();
      }
      catch (Exception e)
      {
        admrdept = "       -";
      }

      try
      {
        location = rs.getObject("location").toString();
      }
      catch (Exception e)
      {
        location = "       -";
      }

      System.out.println("    " + deptno + "    " + deptname + "  " +
                         mgrno + "  " + admrdept + "  " + location);

    } // while

    rs.close();
    stmt.close();
    conn.commit();

  } // showTableContents()

  // create Index command can be used on temporary tables to improve 
  // the performance of queries 
  static void createIndex(Connection conn) throws Exception
  {
    System.out.print(
      "\n-----------------------------------------------------------");
    System.out.print(
      "\n Indexes can be created for temporary tables. Indexing a table\n" +
      " optimizes query performance \n");
 
    System.out.print(
      "\n  CREATE INDEX session.tb1ind \n" +
      "    ON session.temptb1 (deptno DESC) \n" +
      "    DISALLOW REVERSE SCANS \n");
  
    Statement stmt = conn.createStatement();
    stmt.executeUpdate(
      "CREATE INDEX session.tb1ind " +
      "ON session.temptb1(deptno DESC) " +
      "DISALLOW REVERSE SCANS");
                        
    System.out.print(
      "\n Following clauses in create index are not supported \n" +
      " for temporary tables:\n" +
      "   SPECIFICATION ONLY\n" +
      "   CLUSTER\n" +
      "   EXTEND USING\n" +
      "   Option SHRLEVEL will have no effect when creating indexes \n" +
      "   on DGTTs and will be ignored \n");
 
    System.out.print(
      "\n Indexes can be dropped by issuing DROP INDEX statement, \n" +
      " or they will be implicitly dropped when the underlying temp \n" +
      " table is dropped.\n");
    
    stmt.close();
  } // createIndex 
    
  // Issue a SELECT * command on the temporary table created and use
  // ResultSetMetaData to obtain description of the temporary table             
  static void describeTemporaryTable(Connection conn) throws Exception
  {
    System.out.print(
      "\n-----------------------------------------------------------");
    System.out.print(
      "\n Use ResultSetMetaData to get temporary table description\n" +
      "\n  Perform:" +
      "\n    SELECT * FROM session.temptb1\n" +
      "\n Use ResultSetMetaData to get information about structure of" +
      "\n the temporary table\n");    
    
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery("SELECT * FROM session.temptb1");
    ResultSetMetaData rsmd = rs.getMetaData();
    int numberOfColumns = rsmd.getColumnCount();
    
    String colName = "";
    String schemaName = "";
    String colType = "";
    int colLength, colScale, colNull;
    
    System.out.print(
        "\n  Column               Type     Type \n" +
        "  name                 schema   name           Length Scale Nulls\n"+
        "  -------------------- -------- -------------- ------ ----- -----");
    
    for (int i = 1; i <= numberOfColumns; i++)
    {
      colName = rsmd.getColumnName(i);
      schemaName = rsmd.getSchemaName(i);
      colType = rsmd.getColumnTypeName(i);
      colLength = rsmd.getColumnDisplaySize(i);
      colScale = rsmd.getScale(i);
      colNull = rsmd.isNullable(i);
      
      System.out.print(
         "\n  " + Data.format(colName, 20) + " " +
        Data.format(schemaName, 8) + " " +
        Data.format(colType, 14) + " " +
        Data.format(colLength, 6) + " " +
        Data.format(colScale, 5) + " "); 
      
      if (colNull == rsmd.columnNullable)
        System.out.print("Yes");
      else if (colNull == rsmd.columnNoNulls)
        System.out.print("No");
      else 
        System.out.print("Unknown");  
    }
    System.out.println();
 
    rs.close();
    stmt.close();
  } // describeTemporaryTable    
} // TbTemp
