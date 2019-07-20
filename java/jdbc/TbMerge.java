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
// SOURCE FILE NAME: TbMerge.java
//
// SAMPLE: How to use the MERGE statement
//
// SQL Statements USED:
//         SELECT
//         UPDATE
//         DELETE
//         INSERT
//         MERGE
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
// OUTPUT FILE: TbMerge.out (available in the online documentation)
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

public class TbMerge
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "  THIS SAMPLE SHOWS HOW TO USE THE 'MERGE' STATEMENT\n");

      // connect to the 'sample' database
      db.connect();

      // create the 'empsamp' table
      CreateTable(db.con);

      // make changes to the 'empsamp' table
      ChangeTable(db.con);

      // apply the changes from table 'empsamp' table to the
      // 'staff' table
      MergeTables(db.con);

      // drop the 'empsamp' table
      Statement stmt = db.con.createStatement();
      stmt.executeUpdate("DROP TABLE empsamp");
      stmt.close();

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    } 
  } // main

  // This method creates the 'empsamp' table and inserts some values into it
  public static void CreateTable(Connection conn)
  {
    try
    {
      System.out.println(
        "\n  -----------------------------------------------------------" +
        "\n  USE THE SQL STATEMENT:\n" +
        "    CREATE TABLE\n" +
        "  TO CREATE A TABLE IN THE SAMPLE DATABASE.\n");

      // create the table
      System.out.println(
        "\n  Create a table 'EMPSAMP' with attributes:" +
        "\n    ID SMALLINT NOT NULL," +
        "\n    NAME VARCHAR(9)," +
        "\n    DEPT SMALLINT," +
        "\n    JOB CHAR(5)," +
        "\n    YEARS SMALLINT," +
        "\n    SALARY DEC(7,2)," +
        "\n    COMM DEC(7,2)," +
        "\n    PRIMARY KEY(ID)");  
      Statement stmt = conn.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE empsamp(" + 
        "  ID SMALLINT NOT NULL," +
        "  NAME VARCHAR(9)," +
        "  DEPT SMALLINT," +
        "  JOB CHAR(5)," +
        "  YEARS SMALLINT," +
        "  SALARY DEC(7,2)," +
        "  COMM DEC(7,2)," +
        "  PRIMARY KEY(ID))");  

      // insert some values into the table
      System.out.println("\n  Insert values into EMPSAMP");
      System.out.println("\n  Invoke the statement:\n" +
                         "\n    INSERT INTO empsamp " +
                         "SELECT * FROM staff WHERE ID >= 310");
      stmt.executeUpdate("INSERT INTO empsamp" +
                         "  SELECT * FROM staff" + 
                         "    WHERE ID >= 310");
      stmt.close();

      // display the final content of the 'empsamp' table
      TbContentDisplay(conn, "empsamp");

      // commit the transaction
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    } 
  } // CreateTable

  // This method makes changes to the 'empsamp' table
  public static void ChangeTable(Connection conn)
  {
    try
    {
      System.out.println(
        "\n  -----------------------------------------------------------" +
        "\n  USE THE SQL STATEMENTS:\n" +
        "    UPDATE\n" +
        "    INSERT\n" +
        "  TO MAKE CHANGES TO THE 'empsamp' TABLE.\n");
  
      // display the initial contents of the 'empsamp' table
      TbContentDisplay(conn, "empsamp");

      // make changes and insert values into the 'empsamp' table
      System.out.println(
        "\n  Invoke the statement\n\n" +
        "    INSERT INTO empsamp(id, name, dept, job, salary)\n" +
        "      VALUES(380, 'Pearce', 38, 'Clerk', 13217.50),\n" +
        "            (390, 'Hachey', 38, 'Mgr', 21270.00),\n" +
        "            (400, 'Wagland', 38, 'Clerk', 14575.00)\n");

      System.out.println(
        "\n  Invoke the statements:\n" +
        "\n    UPDATE empsamp SET job = 'Mgr' WHERE id = 310" +
        "\n    UPDATE empsamp SET job = 'Sales', salary = 15000.00" + 
        " WHERE id = 350" +
        "\n    UPDATE empsamp SET name = '-' WHERE id = 320");

      Statement stmt = conn.createStatement();
      stmt.executeUpdate(
        "INSERT INTO empsamp(id, name, dept, job, salary)" +
        "  VALUES(380, 'Pearce', 38, 'Clerk', 13217.50)," +
        "        (390, 'Hachey', 38, 'Mgr', 21270.00)," +
        "        (400, 'Wagland', 38, 'Clerk', 14575.00)");

      stmt.executeUpdate("UPDATE empsamp SET job = 'Mgr' WHERE id = 310");
      stmt.executeUpdate("UPDATE empsamp " + 
                         "  SET job = 'Sales', salary = 15000.00" + 
                         "  WHERE id = 350");
      stmt.executeUpdate("UPDATE empsamp SET name = '-' WHERE id = 320");
      stmt.close();

      // display the content of the final 'empsamp' table
      TbContentDisplay(conn, "empsamp");

      // commit the transaction
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    } 
  } // ChangeTable

  // This method applies the changes from the 'empsamp' table
  // to the 'staff' table using the MERGE statement
  public static void MergeTables(Connection conn)
  {
    try
    {
      System.out.println(
        "\n  -----------------------------------------------------------" +
        "\n  USE THE SQL STATEMENT:\n" +
        "    MERGE\n" +
        "  TO APPLY CHANGES FROM TABLE 'empsamp' TO TABLE 'staff'\n");

      // display the initial contents of the 'staff' table
      TbContentDisplay(conn, "staff");

      // apply changes from the 'empsamp' table to the 'staff' table 
      // with the MERGE statement
      System.out.println(
        "\n  Merge tables" +
        "\n  Invoke the statement:\n" +
        "\n    MERGE INTO staff S" +
        "\n      USING (SELECT * FROM empsamp) E" +
        "\n        ON (S.id = E.id)" +
        "\n          WHEN MATCHED AND E.name != '-' THEN" +
        "\n            UPDATE SET (name, dept, job, years, salary, comm) =" +
        "\n                       (E.name, E.dept, E.job, E.years," +
        " E.salary, E.comm)" +
        "\n          WHEN NOT MATCHED THEN" +
        "\n            INSERT (id, name, dept, job, years, salary, comm)" +
        "\n              VALUES (E.id, E.name, E.dept, E.job, E.years," +
        " E.salary, E.comm)" +
        "\n          ELSE" +
        "\n            IGNORE\n");

      Statement stmt = conn.createStatement();
      stmt.executeUpdate(  
        "MERGE INTO staff S" +
        "  USING (SELECT * FROM empsamp) E" +
        "    ON (S.id = E.id)" +
        "      WHEN MATCHED AND E.name != '-' THEN" +
        "        UPDATE SET (name, dept, job, years, salary, comm) =" +
        "        (E.name, E.dept, E.job, E.years, E.salary, E.comm)" +
        "      WHEN NOT MATCHED THEN" +
        "        INSERT (id, name, dept, job, years, salary, comm)" +
        "          VALUES (E.id, E.name, E.dept, E.job, E.years," + 
        "                  E.salary, E.comm)" +
        "      ELSE" +
        "        IGNORE");

      stmt.close();

      // display the contents of the final 'staff' table
      TbContentDisplay(conn, "staff");

      // rollback the transaction
      conn.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    } 
  } // MergeTables

  // helping function: Display the contents of the 'staff' or 'empsamp' table
  public static void TbContentDisplay(Connection conn, String tablename) 
  {
    try
    {
      Integer id = new Integer(0);
      String name = null;
      Integer dept = new Integer(0);
      String job = null;
      Integer years = new Integer(0);
      Double salary = new Double(0.0);
      Double comm = new Double(0.0);

      System.out.println();
      System.out.println(
        "  SELECT * FROM " + tablename + " WHERE id >= 310\n" +
        "    ID  NAME     DEPT JOB   YEARS SALARY   COMM\n" +
        "    --- -------- ---- ----- ----- -------- --------");

      Statement stmt = conn.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT * FROM " + tablename + " WHERE id >= 310");

      while (rs.next())
      {
        id = Integer.valueOf(rs.getString(1));
        name = rs.getString(2);
        dept = Integer.valueOf(rs.getString(3));
        job = rs.getString(4);
        if (rs.getString(5) == null)
        {
          years = null;
        }
        else
        {
          years = Integer.valueOf(rs.getString(5));
        }
        salary = Double.valueOf(Double.toString(rs.getDouble(6)));
        if (rs.getDouble(7) == 0.0)
        {
          comm = null;
        }
        else
        {
          comm = Double.valueOf(Double.toString(rs.getDouble(7)));
        }

        System.out.print("    "+Data.format(id, 3) +
                         " " + Data.format(name, 8) +
                         " " + Data.format(dept, 4));
        if (job != null)
        {
          System.out.print(" " + Data.format(job, 5));
        }
        else
        {
          System.out.print("     -");
        }
        if (years != null)
        {
          System.out.print(" " + Data.format(years, 5));
        }
        else
        {
          System.out.print("     -");
        }

        System.out.print(" " + Data.format(salary, 7, 2));
        if (comm != null)
        {
          System.out.print(" " + Data.format(comm, 7, 2));
        }
        else
        {
          System.out.print("       -");
        }
        System.out.println();
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  } // TbContentDisplay

}  // TbMerge
