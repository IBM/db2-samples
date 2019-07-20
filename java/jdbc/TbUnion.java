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
// SOURCE FILE NAME: TbUnion.java
//
// SAMPLE: How to insert through a UNION ALL view
//
// SQL Statements USED:
//         SELECT
//         CREATE TABLE
//         ALTER TABLE
//         DROP TABLE
//         CREATE VIEW
//         DROP VIEW
//         INSERT
//         DELETE
//         UPDATE
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
// OUTPUT FILE: TbUnion.out (available in the online documentation)
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

class TbUnion
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "  THIS SAMPLE SHOWS HOW TO INSERT THROUGH A 'UNION ALL' VIEW.\n");

      // Connect to the 'sample' database
      db.connect();

      // Create tables Q1, Q2, Q3 and Q4 and add constraints to them.
      // Also create a view FY which is a view over the full year.
      CreateTablesAndView(db.con);

      // Insert some values directly into tables Q1, Q2, Q3 and Q4
      InsertInitialValuesInTables(db.con);

      // Demonstrate how to insert through a UNION ALL view
      InsertUsingUnionAll(db.con);

      // Modify the constraints of table Q1
      NewConstraints(db.con);

      // Attempt to insert data through a UNION ALL view where no table
      // accepts the row
      InsertWhenNoTableAcceptsIt(db.con);

      // Attempt to insert data through a UNION ALL view where more than
      // one table accepts the row
      InsertWhenMoreThanOneTableAcceptsIt(db.con);

      // Drop, recreate and reinitialize the tables and view
      DropTablesAndView(db.con);
      CreateTablesAndView(db.con);
      InsertInitialValuesInTables(db.con);
  
      // Create a new view and perform some updates through it.  This shows how
      // updates through a view with row migration affect the underlying
      // tables
      UpdateWithRowMovement(db.con);

      // Show two special cases of row migration involving tables with 
      // overlapping constraints
      UpdateWithRowMovementSpecialCase(db.con);

      // Drop tables Q1, Q2, Q3 and Q4 and the view FY
      DropTablesAndView(db.con);

      // Disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // This method create tables Q1, Q2, Q3 and Q4 and adds constraints
  // to them. It also creates a view FY which is a view over the full year.
  public static void CreateTablesAndView(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLES Q1,Q2,Q3 AND Q4 BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    CREATE TABLE Q1(product_no INT, sales INT, date DATE)\n" +
        "    CREATE TABLE Q2 LIKE Q1\n" +
        "    CREATE TABLE Q3 LIKE Q1\n" +
        "    CREATE TABLE Q4 LIKE Q1\n");

      // Create tables Q1, Q2, Q3 and Q4
      Statement stmt = con.createStatement();
      stmt.execute(
        "CREATE TABLE Q1(product_no INT, sales INT, date DATE)");
      stmt.execute("CREATE TABLE Q2 LIKE Q1");
      stmt.execute("CREATE TABLE Q3 LIKE Q1");
      stmt.execute("CREATE TABLE Q4 LIKE Q1");

      System.out.println(
        "  ADD CONSTRAINTS TO TABLES Q1, Q2, Q3 AND Q4 BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    ALTER TABLE Q1 ADD CONSTRAINT Q1_CHK_DATE" + 
        " CHECK (MONTH(date) IN (1, 2, 3))\n" +
        "    ALTER TABLE Q2 ADD CONSTRAINT Q2_CHK_DATE" + 
        " CHECK (MONTH(date) IN (4, 5, 6))\n" +
        "    ALTER TABLE Q3 ADD CONSTRAINT Q3_CHK_DATE" + 
        " CHECK (MONTH(date) IN (7, 8, 9))\n" +
        "    ALTER TABLE Q4 ADD CONSTRAINT Q4_CHK_DATE" + 
        " CHECK (MONTH(date) IN (10,11,12))\n");

      // Adds constraints to tables Q1, Q2, Q3 and Q4
      stmt.execute("ALTER TABLE Q1 ADD CONSTRAINT Q1_CHK_DATE " +
                   "CHECK (MONTH(date) IN (1, 2, 3))");
      stmt.execute("ALTER TABLE Q2 ADD CONSTRAINT Q2_CHK_DATE " +
                   "CHECK (MONTH(date) IN (4, 5, 6))");
      stmt.execute("ALTER TABLE Q3 ADD CONSTRAINT Q3_CHK_DATE " +
                   "CHECK (MONTH(date) IN (7, 8, 9))");
      stmt.execute("ALTER TABLE Q4 ADD CONSTRAINT Q4_CHK_DATE " +
                   "CHECK (MONTH(date) IN (10, 11, 12))");

      System.out.println(
        "  CREATE A VIEW 'FY' BY INVOKING THE STATEMENT:\n\n" +
        "    CREATE VIEW FY AS\n" + 
        "      SELECT product_no, sales, date FROM Q1\n" +
        "      UNION ALL\n" +
        "      SELECT product_no, sales, date FROM Q2\n" +
        "      UNION ALL\n" +
        "      SELECT product_no, sales, date FROM Q3\n" +
        "      UNION ALL\n" +
        "      SELECT product_no, sales, date FROM Q4\n");

      // Create the view FY, a view over the full year.
      stmt.execute("CREATE VIEW FY AS" + 
                   "  SELECT product_no, sales, date FROM Q1" +
                   "  UNION ALL" +
                   "  SELECT product_no, sales, date FROM Q2" +
                   "  UNION ALL" +
                   "  SELECT product_no, sales, date FROM Q3" +
                   "  UNION ALL" +
                   "  SELECT product_no, sales, date FROM Q4");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }

  // This method inserts some values directly into tables Q1, Q2, Q3 and Q4
  public static void InsertInitialValuesInTables(Connection con)
  {
    try
    {
      System.out.println(
        "  INSERT INITIAL VALUES INTO TABLES Q1, Q2, Q3, Q4 BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    INSERT INTO Q1 VALUES (5, 6, '2001-01-02'),\n" +
        "                          (8, 100, '2001-02-28')\n" +
        "    INSERT INTO Q2 VALUES (3,  10, '2001-04-11'),\n" +
        "                          (5,  15, '2001-05-19')\n" +
        "    INSERT INTO Q3 VALUES (1,  12, '2001-08-27')\n" +
        "    INSERT INTO Q4 VALUES (3,  14, '2001-12-29'),\n" +
        "                          (2,  21, '2001-12-12')");

      // Insert initial values into tables Q1, Q2, Q3 and Q4
      Statement stmt = con.createStatement();
      stmt.execute("INSERT INTO Q1 VALUES (5, 6, '2001-01-02')," +
                   "   	                  (8, 100, '2001-02-28')");
      stmt.execute("INSERT INTO Q2 VALUES (3,  10, '2001-04-11')," +
                   "                      (5,  15, '2001-05-19')");
      stmt.execute("INSERT INTO Q3 VALUES (1,  12, '2001-08-27')");
      stmt.execute("INSERT INTO Q4 VALUES (3,  14, '2001-12-29')," +
                   "                      (2,  21, '2001-12-12')");

      stmt.close();

      // Display the view FY after inserting values into the tables
      DisplayData(con, "SELECT * FROM FY ORDER BY date, product_no");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }

  // This method drops tables Q1, Q2, Q3 and Q4 and the view FY
  public static void DropTablesAndView(Connection con)
  {
    try
    {
      System.out.println(
        "\n  DROP TABLES Q1,Q2,Q3,Q4 AND VIEW FY BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    DROP VIEW FY\n" +
        "    DROP TABLE Q1\n" +
        "    DROP TABLE Q2\n" +
        "    DROP TABLE Q3\n" +
	"    DROP TABLE Q4");

      Statement stmt = con.createStatement();
      stmt.execute("DROP VIEW FY");
      stmt.execute("DROP TABLE Q1");
      stmt.execute("DROP TABLE Q2");
      stmt.execute("DROP TABLE Q3");
      stmt.execute("DROP TABLE Q4");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }

  // Helper method: This method displays the results of the query
  // specified by 'querystr'
  public static void DisplayData(Connection con, String querystr)
  {
    try
    {
      Integer prod_num = new Integer(0);
      Integer sales_amt = new Integer(0);
      String sales_date = new String();

      System.out.println();
      System.out.println(
        "    " + querystr + "\n\n" +
        "    PRODUCT_NO  SALES       DATE\n" +
        "    ----------- ----------- ----------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(querystr);

      while (rs.next())
      {
        prod_num = Integer.valueOf(rs.getString(1));
        sales_amt = Integer.valueOf(rs.getString(2));
        sales_date = rs.getString(3);
        
        System.out.print("    "+Data.format(prod_num, 11) +
                         " " + Data.format(sales_amt, 11) +
                         " " + Data.format(sales_date, 10));
        System.out.println();
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }

  // This method demonstrates how to insert through a UNION ALL view
  public static void InsertUsingUnionAll(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "  ----------------------------------------------------------\n" +
        "  USE THE SQL STATEMENT:\n\n" +
        "    INSERT\n\n" +
        "  TO INSERT DATA THROUGH THE 'UNION ALL' VIEW.\n");

      System.out.println(
        "  CONTENTS OF THE VIEW 'FY' BEFORE INSERTING DATA:");

      // Display the initial content of the view FY before inserting new
      // rows
      DisplayData(con, "SELECT * FROM FY ORDER BY date, product_no");

      // INSERT data into tables Q1, Q2, Q3 and Q4 through the
      // UNION ALL view FY
      System.out.println();
      System.out.println(
        "  INSERT DATA THROUGH THE 'UNION ALL' VIEW" +
        " BY INVOKING THE STATEMENT:\n\n" +
        "    INSERT INTO FY VALUES (1, 20, '2001-06-03'),\n" +
        "                          (2, 30, '2001-03-21'),\n" +
        "                          (2, 25, '2001-08-30')\n");
 
      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "INSERT INTO FY VALUES (1, 20, '2001-06-03')," +
        "                      (2, 30, '2001-03-21')," +
        "                      (2, 25, '2001-08-30')");
      stmt.close();

      // Display the final content of all tables
      System.out.println(
        "  CONTENTS OF THE TABLES Q1, Q2, Q3, AND Q4 AFTER INSERTING DATA:");
      DisplayData(con, "SELECT * FROM Q1 ORDER BY date, product_no");
      DisplayData(con, "SELECT * FROM Q2 ORDER BY date, product_no");
      DisplayData(con, "SELECT * FROM Q3 ORDER BY date, product_no");
      DisplayData(con, "SELECT * FROM Q4 ORDER BY date, product_no");

      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }

  // This method modifies the constraints of table Q1
  public static void NewConstraints(Connection con)
  {
    try
    {
      System.out.println();
      Statement stmt = con.createStatement();

      System.out.println(
        "  CHANGE THE CONSTRAINTS OF TABLE 'Q1' BY" +
        " INVOKING THE STATEMENTS:\n\n" +
        "    DELETE FROM FY\n" +
        "    ALTER TABLE Q1 DROP CONSTRAINT Q1_CHK_DATE\n" +
        "    ALTER TABLE Q1 ADD CONSTRAINT Q1_CHK_DATE" +
        " CHECK (MONTH(date) IN (4, 2, 3))");
 
      // Drop the constraint Q1_CHK_DATE and add a new one
      stmt.execute("DELETE FROM FY");
      stmt.execute("ALTER TABLE Q1 DROP CONSTRAINT Q1_CHK_DATE");
      stmt.execute("ALTER TABLE Q1 ADD CONSTRAINT Q1_CHK_DATE" + 
                   "  CHECK (MONTH(date) IN (4, 2, 3))");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }    

  // This method attempts to insert data through a UNION ALL view where no
  // table accepts the row
  public static void InsertWhenNoTableAcceptsIt(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "  ----------------------------------------------------------\n" +
        "  USE THE SQL STATEMENT:\n\n" +
        "    INSERT\n\n" +
        "  TO ATTEMPT TO INSERT DATA THROUGH A 'UNION ALL' VIEW WHERE\n" +
        "  NO TABLE ACCEPTS THE ROW\n");

      System.out.println(
        "  NO TABLE ACCEPTS A ROW WITH 'MONTH' = 1." + 
        " AN ATTEMPT TO INSERT A ROW WITH\n" +
        "  'MONTH' = 1, WOULD CAUSE A 'NO TARGET' ERROR TO BE RAISED");

      Statement stmt = con.createStatement();

      System.out.println();
      System.out.println(
        "  ATTEMPT TO INSERT A ROW WITH 'MONTH' = 1" +
        " BY INVOKING THE STATEMENT:\n\n" +
        "    INSERT INTO FY VALUES (5, 35, '2001-01-14')\n");
 
      // Attempt to insert a row with 'MONTH' = 1 which no table will accept
      stmt.executeUpdate(
        "INSERT INTO FY VALUES (5, 35, '2001-01-14')");
      stmt.close();

      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }
  }

  // This method attempts to insert data through a UNION ALL view where more
  // than one table accepts the row
  public static void InsertWhenMoreThanOneTableAcceptsIt(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "  ----------------------------------------------------------\n" +
        "  USE THE SQL STATEMENT:\n\n" +
        "    INSERT\n\n" +
        "  TO ATTEMPT TO INSERT DATA THROUGH A 'UNION ALL' VIEW WHERE\n" +
        "  MORE THAN ONE TABLE ACCEPTS THE ROW\n");

      System.out.println(
        "  BOTH TABLES Q1 AND Q2 ACCEPT A ROW WITH 'MONTH' = 4." +
        " AN ATTEMPT TO\n" +
        "  INSERT A ROW WITH 'MONTH' = 4, WOULD CAUSE AN 'AMBIGUOUS" +
        " TARGET' ERROR\n" +
        "  TO BE RAISED");

      Statement stmt = con.createStatement();

      System.out.println();
      System.out.println(
        "  ATTEMPT TO INSERT A ROW WITH 'MONTH' = 4" +
        " BY INVOKING THE STATEMENT:\n\n" +
        "    INSERT INTO FY VALUES (3, 30, '2001-04-21')\n");

      // Attempt to insert a row with 'MONTH' = 4 which is accepted
      // by both tables Q1 and Q2 
      stmt.executeUpdate(
        "INSERT INTO FY VALUES (3, 30, '2001-04-21')");
      stmt.close();

      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }
  }

  // This function creates a new view.  The new view has the WITH ROW 
  // MIGRATION clause in it, which enables row migration.  It performs some 
  // updates through this view to show how row migration affects the 
  // underlying tables. 
  public static void UpdateWithRowMovement(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();

      System.out.println(
        "\n  CREATE A VIEW 'vfullyear' BY INVOKING THE STATEMENT:\n\n" +
        "    CREATE VIEW vfullyear AS\n" +
        "      SELECT product_no, sales, date FROM Q1\n" +
        "      UNION ALL\n" +
        "      SELECT product_no, sales, date FROM Q2\n" +
        "      UNION ALL\n" +
        "      SELECT product_no, sales, date FROM Q3\n" +
        "      UNION ALL\n" +
        "      SELECT product_no, sales, date FROM Q4\n" +
        "      WITH ROW MOVEMENT\n");
  
      // Create the view vfullyear, this is the same as view FY with the
      // exception that it has the WITH ROW MOVEMENT clause.  This additional
      // clause allows updates through the view to move rows across the underlying
      // tables (row migration) as necessary.
      stmt.execute( 
        "CREATE VIEW vfullyear AS" +
        "  SELECT product_no, sales, date FROM Q1" +
        "  UNION ALL" +
        "  SELECT product_no, sales, date FROM Q2" +
        "  UNION ALL" +
        "  SELECT product_no, sales, date FROM Q3" +
        "  UNION ALL" +
        "  SELECT product_no, sales, date FROM Q4" +
        "  WITH ROW MOVEMENT");

      System.out.println(
        "  CONTENTS OF THE TABLES Q1 AND Q2 BEFORE ROW MOVEMENT OCCURS");
      DisplayData(con, "SELECT * FROM Q1");
      DisplayData(con, "SELECT * FROM Q2");
  
      System.out.println(
        "\n  UPDATE VALUES IN VIEW vfullyear BY INVOKING\n" +
        "  THE STATEMENT:\n\n" +
        "    UPDATE vfullyear SET date = date + 2 MONTHS\n" +
        "                     WHERE date='2001-02-28'");
		  
      // Demonstrate row movement by executing the following UPDATE statement.
      // This statement causes a row to move from table Q1 to table Q2.
      stmt.execute( 
        "UPDATE vfullyear SET date = date + 2 MONTHS" +
        "                 WHERE date='2001-02-28'");

      System.out.println(
        "\n  CONTENTS OF THE TABLES Q1 AND Q2 AFTER ROW MOVEMENT OCCURS");
      DisplayData(con, "SELECT * FROM Q1");
      DisplayData(con, "SELECT * FROM Q2");

      System.out.println(
        "\n  DROP THE VIEW vfullyear BY INVOKING\n" +
        "  THE STATEMENT:\n\n" +
        "    DROP VIEW vfullyear");
           
      stmt.execute("DROP VIEW vfullyear");
      
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // UpdateWithRowMovement

  // This function creates three new tables and one new view.  It performs some
  // updates through the view to show two special cases of row migration.
  public static void UpdateWithRowMovementSpecialCase(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();

      System.out.println(
        "\n  CREATE TABLES T1,T2 AND T3 BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    CREATE TABLE T1(name CHAR, grade INT)\n" +
        "    CREATE TABLE T2 LIKE T1\n" +
        "    CREATE TABLE T3 LIKE T1\n");
 
      stmt.execute("CREATE TABLE T1(name CHAR, grade INT)");
      stmt.execute("CREATE TABLE T2 LIKE T1");
      stmt.execute("CREATE TABLE T3 LIKE T1");

      System.out.println(
        "  INSERT INITIAL VALUES INTO TABLES T1, T2, T3 BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    INSERT INTO T1 VALUES ('a', 40), ('b', 55)\n" +
        "    INSERT INTO T2 VALUES ('c', 50), ('d', 75)\n" +
        "    INSERT INTO T3 VALUES ('d', 90), ('e', 95)");
   
      stmt.execute("INSERT INTO T1 VALUES ('a', 40), ('b', 55)");
      stmt.execute("INSERT INTO T2 VALUES ('c', 50), ('d', 75)");
      stmt.execute("INSERT INTO T3 VALUES ('d', 90), ('e', 95)");
 
      System.out.println(
        "\n  ADD CONSTRAINTS TO TABLES T1, T2 AND T3 BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    ALTER TABLE T1 ADD CONSTRAINT T1_CHK_GRADE\n" +
        "      CHECK (grade >= 0 AND grade <= 55)\n" +
        "    ALTER TABLE T2 ADD CONSTRAINT T2_CHK_GRADE\n" +
        "      CHECK (grade >= 50 AND grade <= 100)\n" +
        "    ALTER TABLE T3 ADD CONSTRAINT T3_CHK_GRADE\n" +
        "      CHECK (grade >= 90 AND grade <= 100)\n");
  
      stmt.execute(
        "ALTER TABLE T1 ADD CONSTRAINT T1_CHK_GRADE" +
        " CHECK (grade >= 0 AND grade <= 55)");

      stmt.execute(
        "ALTER TABLE T2 ADD CONSTRAINT T2_CHK_GRADE" +
        " CHECK (grade >= 50 AND grade <= 100)");

      stmt.execute(
        "ALTER TABLE T3 ADD CONSTRAINT T3_CHK_GRADE" +
        " CHECK (grade >= 90 AND grade <= 100)");

    }
    catch(Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
    try
    {
      Statement stmt = con.createStatement();

      System.out.println(
        "  CREATE A VIEW 'vmarks' BY INVOKING THE STATEMENT:\n\n" +
        "    CREATE VIEW vmarks AS\n" +
        "      SELECT name, grade FROM T1\n" +
        "      UNION ALL\n" +
        "      SELECT name, grade FROM T2\n" +
        "      UNION ALL\n" +
        "      SELECT name, grade FROM T3\n" +
        "      WITH ROW MOVEMENT\n");
 
      stmt.execute(
        "CREATE VIEW vmarks AS" +
        "  SELECT name, grade FROM T1" +
        "  UNION ALL" +
        "  SELECT name, grade FROM T2" +
        "  UNION ALL" +
        "  SELECT name, grade FROM T3" +
        "  WITH ROW MOVEMENT");
   
      System.out.println(
        "  ATTEMPT TO UPDATE THE ROW WITH grade = 50" +
        " BY INVOKING THE STATEMENT:\n\n" +
        "    UPDATE vmarks SET GRADE = 60 WHERE GRADE = 50");
  
      // Attempt to update the row where grade = 50, which satisfies constraints
      // for both tables T2 and T3.  In this case no error is raised as row 
      // migration doesn't apply.  The row does not need to be moved because it 
      // satisfies all constraints of the table it is already in.
      stmt.execute(
        "UPDATE vmarks SET grade = 60" +
        "              WHERE grade = 50");
   
      System.out.println(
        "\n  ATTEMPT TO UPDATE THE ROW WITH grade = 90" +
        " BY INVOKING THE STATEMENT:\n\n" +
        "    UPDATE vmarks SET GRADE = 50 WHERE GRADE = 90");
  
      // Attempt to update the row where grade = 90, which satisfies constraints
      // for both tables T1 and T2.  An error is raised since this update is 
      // ambiguous.  A similar error is raised on an ambiguous insert statement.
      stmt.execute( 
        "UPDATE vmarks SET grade = 50" +
        "              WHERE grade = 90");
    }
    catch(Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }
    try
    {
      Statement stmt = con.createStatement();

      System.out.println(
        "\n  DROP TABLES T1,T2,T3 AND VIEW vmarks BY INVOKING\n" +
        "  THE STATEMENTS:\n\n" +
        "    DROP VIEW vmarks\n" +
        "    DROP TABLE T1\n" +
        "    DROP TABLE T2\n" +
        "    DROP TABLE T3");
  
      stmt.execute("DROP VIEW vmarks");
      stmt.execute("DROP TABLE T1");
      stmt.execute("DROP TABLE T2");
      stmt.execute("DROP TABLE T3");

      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // UpdateWithRowMovementSpecialCase
} // TbUnion

