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
// SOURCE FILE NAME: TbMod.java
//
// SAMPLE: How to modify table data
//
// SQL Statements USED:
//         SELECT
//         UPDATE
//         DELETE
//         ROLLBACK
//
// Classes used from Util.java are:
//         Db
//         Data
//         JdbcException
//
// OUTPUT FILE: TbMod.out (available in the online documentation)
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

class TbMod
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO MODIFY TABLE DATA.");

      // connect to the 'sample' database
      db.connect();

      // different ways to INSERT table data
      insertUsingValues(db.con);
      insertUsingFullselect(db.con);

      // different ways to UPDATE table data
      updateWithoutSubqueries(db.con);
      updateUsingSubqueryInSetClause(db.con);
      updateUsingSubqueryInWhereClause(db.con);
      updateUsingCorrelatedSubqueryInSetClause(db.con);
      updateUsingCorrelatedSubqueryInWhereClause(db.con);
      positionedUpdateWithoutSubqueries(db.con);

      // Known problem. Bug reported.
      // The following two functions does not work properly due to
      // CLI Driver Error?  Is subquery support?
      //   e.g.1  "UPDATE staff SET col2 = '1000' WHERE CURRENT OF "
      //          + cursName

      positionedUpdateUsingSubqueryInSetClause(db.con);
      positionedUpdateUsingCorrelatedSubqueryInSetClause(db.con);

      // different ways to DELETE table data
      deleteWithoutSubqueries(db.con);
      deleteUsingSubqueryInWhereClause(db.con);
      deleteUsingCorrelatedSubqueryInWhereClause(db.con);
      positionedDelete(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // helping function: Display the content of the 'staff' table
  static void staffTbContentDisplay(Connection con)
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
        "  SELECT * FROM staff WHERE id >= 310\n" +
        "    ID  NAME     DEPT JOB   YEARS SALARY   COMM\n" +
        "    --- -------- ---- ----- ----- -------- --------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT * FROM staff WHERE id >= 310");

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
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // staffTbContentDisplay

  // helping function: Display part of the content of the 'employee' table
  static void employeeTbPartialContentDisplay(Connection con)
  {
    try
    {
      String empno = null;
      Double salary = new Double(0.0);
      String workdept = null;

      System.out.println();
      System.out.println("  SELECT empno, salary, workdept\n" +
                         "    FROM employee\n" +
                         "    WHERE  workdept = 'E11'\n" +
                         "      EMPNO  SALARY     WORKDEPT\n" +
                         "      ------ ---------- --------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT empno, salary, workdept " +
                                       "  FROM employee " +
                                       "  WHERE workdept = 'E11'");

      while (rs.next())
      {
        empno = rs.getString(1);
        salary = Double.valueOf(Double.toString(rs.getDouble(2)));
        workdept = rs.getString(3);

        System.out.println("      "+Data.format(empno, 6) +
                           " " + Data.format(salary, 9, 2) +
                           " " + Data.format(workdept, 8));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // employeeTbPartialContentDisplay

  // This function demonstrates how to insert table data using VALUES
  static void insertUsingValues(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  INSERT\n" +
        "TO INSERT TABLE DATA USING VALUES.");

      // display the initial content of the 'staff' table
      staffTbContentDisplay(con);

      // INSERT data INTO a table using VALUES
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    INSERT INTO staff(id, name, dept, job, salary)\n" +
        "      VALUES(380, 'Pearce', 38, 'Clerk', 13217.50),\n" +
        "            (390, 'Hachey', 38, 'Mgr', 21270.00),\n" +
        "            (400, 'Wagland', 38, 'Clerk', 14575.00)");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "INSERT INTO staff(id, name, dept, job, salary) " +
        "  VALUES(380, 'Pearce', 38, 'Clerk', 13217.50), "+
        "        (390, 'Hachey', 38, 'Mgr', 21270.00), " +
        "        (400, 'Wagland', 38, 'Clerk', 14575.00) ");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // insertUsingValues

  // This function demonstrates how to insert table data using
  // FULLSELECT
  static void insertUsingFullselect(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  INSERT\n" +
        "TO INSERT TABLE DATA USING FULLSELECT.");

      // display the initial content of the 'staff' table
      staffTbContentDisplay(con);

      // INSERT data INTO a table using FULLSELECT
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    INSERT INTO staff(id, name, dept, salary)\n" +
        "      SELECT INTEGER(empno)+100, lastname, 77, salary\n"+
        "        FROM employee\n" +
        "        WHERE INTEGER(empno) >= 310" +
        "        AND INTEGER(empno) <= 340");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "INSERT INTO staff(id, name, dept, salary) " +
        "  SELECT INTEGER(empno) + 100, lastname, 77, salary " +
        "    FROM employee " +
        "    WHERE INTEGER(empno) >= 310" +
        "    AND INTEGER(empno) <= 340");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // insertUsingFullselect

   // This function demonstrates how to update table data
  static void updateWithoutSubqueries(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  UPDATE\n" +
        "TO UPDATE TABLE DATA.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // update table data
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff\n" +
        "      SET salary = salary + 1000\n" +
        "      WHERE id >= 310 AND dept = 84");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("UPDATE staff " +
                         "  SET salary = salary + 1000 " +
                         "  WHERE id >= 310 AND dept = 84");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // updateWithoutSubqueries

  // This function demonstrates how to update table data using
  // subquery in the SET clause
  static void updateUsingSubqueryInSetClause(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  UPDATE\n" +
        "TO UPDATE TABLE DATA\n" +
        "USING SUBQUERY IN 'SET' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // update data of the table 'staff' by using subquery in the SET
      // clause
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff\n" +
        "      SET salary = (SELECT MIN(salary)\n" +
        "                      FROM staff\n" +
        "                      WHERE id >= 310)\n" +
        "      WHERE id = 350");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "UPDATE staff " +
        "  SET salary = (SELECT MIN(salary) " +
        "                  FROM staff " +
        "                  WHERE id >= 310) " +
        "  WHERE id = 350");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // updateUsingSubqueryInSetClause

  // This function demonstrates how to update table data using subquery
  // in the WHERE clause.
  static void updateUsingSubqueryInWhereClause(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  UPDATE\n" +
        "TO UPDATE TABLE DATA\n" +
        "USING SUBQUERY IN 'WHERE' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // update table data using subquery in WHERE clause
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff\n" +
        "      SET comm = 250.00\n" +
        "      WHERE dept = 84 AND\n" +
        "            salary < (SELECT AVG(salary)\n" +
        "                        FROM staff\n" +
        "                        WHERE id >= 310 AND dept = 84)");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "UPDATE staff " +
        "  SET comm = 250.00 " +
        "  WHERE dept = 84 AND " +
        "        salary < (SELECT AVG(salary) " +
        "                    FROM staff " +
        "                    WHERE id >= 310 AND dept = 84)");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // updateUsingSubqueryInWhereClause

  // This function demonstrates how to update table data using
  // correlated subquery in the 'SET' clause.
  static void updateUsingCorrelatedSubqueryInSetClause(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  UPDATE\n" +
        "TO UPDATE TABLE DATA\n" +
        "USING CORRELATED SUBQUERY IN 'SET' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // update data of the 'staff' table using correlated subquery in
      // the 'SET' clause
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff s1\n" +
        "      SET comm = 0.01 * (SELECT MIN(salary)\n" +
        "                           FROM staff s2\n" +
        "                           WHERE id >= 310 AND\n" +
        "                                 s2.dept = s1.dept)\n" +
        "      WHERE id >= 340");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "UPDATE staff s1 " +
        "  SET comm = 0.01 * (SELECT MIN(salary) " +
        "                       FROM staff s2 " +
        "                       WHERE id >= 310 AND " +
        "                             s2.dept = s1.dept) " +
        "  WHERE id >= 340 ");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // updateUsingCorrelatedSubqueryInSetClause

  // This function demonstrates how to update table data using
  // correlated subquery in the 'WHERE' clause.
  static void updateUsingCorrelatedSubqueryInWhereClause(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  UPDATE\n" +
        "TO UPDATE TABLE DATA\n" +
        "USING CORRELATED SUBQUERY IN 'WHERE' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // update data of the 'staff' table using correlated subquery in the
      // 'WHERE' clause
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff s1\n" +
        "      SET comm = 700\n" +
        "      WHERE id >= 340 AND\n" +
        "            salary < (SELECT AVG(salary)\n" +
        "                        FROM staff s2\n" +
        "                        WHERE id >= 310 AND\n" +
        "                              s2.dept = s1.dept)");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "UPDATE staff s1 " +
        "  SET comm = 700 " +
        "    WHERE id >= 340 AND " +
        "          salary < (SELECT AVG(salary) " +
        "                      FROM staff s2 " +
        "                      WHERE id >= 310 AND " +
        "                            s2.dept = s1.dept)");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // updateUsingCorrelatedSubqueryInWhereClause

  // This function demonstrates how to perform positioned update on a table
  static void positionedUpdateWithoutSubqueries(Connection con)
  {
    try
    {
      String name = null;
      int dept = 0;
      String curName = null;

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "  UPDATE\n" +
        "TO PERFORM POSITIONED UPDATE ON A TABLE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Invoke the statements:\n" +
        "    get a ResultSet rs for\n" +
        "      SELECT name, dept\n" +
        "        FROM staff\n" +
        "        WHERE id >= 310\n" +
        "        FOR UPDATE OF comm\n" +
        "\n" +
        "    curName = rs.getCursorName();\n" +
        "    while (rs.next())\n" +
        "    {\n" +
        "      if (dept != 84)\n" +
        "      {\n"+
        "        UPDATE staff\n"+
        "          SET comm = NULL\n"+
        "          WHERE CURRENT OF curName\n" +
        "      }\n" +
        "    }");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT name, dept " +
                                       "  FROM staff " +
                                       "  WHERE id >= 310 " +
                                       "  FOR UPDATE OF comm");

      curName = rs.getCursorName();
      Statement stmt1 = con.createStatement();
      while (rs.next())
      {
        dept = rs.getInt(2);
        if (dept != 84)
        {
          stmt1.executeUpdate("UPDATE staff " +
                              "  SET comm = NULL " +
                              "  WHERE CURRENT OF " + curName);
        }
      }
      stmt1.close();
      rs.close();
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // positionedUpdateWithoutSubqueries

  // This function demonstrates how to perform positioned update on a table
  // using subquery in the 'SET' clause.
  static void positionedUpdateUsingSubqueryInSetClause(Connection con)
  {
    try
    {
      String name = null;
      int dept = 0;
      String curName = null;

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  UPDATE\n" +
        "  SELECT\n" +
        "TO PERFORM POSITIONED UPDATE ON A TABLE\n" +
        "USING SUBQUERY IN 'SET' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Invoke the statements:\n" +
        "    get a ResultSet rs for\n" +
        "      SELECT name, dept\n" +
        "        FROM staff\n" +
        "        WHERE id >= 310\n" +
        "        FOR UPDATE OF comm\n" +
        "\n" +
        "    curName = rs.getCursorName();\n" +
        "    while (rs.next())\n" +
        "    {\n" +
        "      if (dept != 84)\n" +
        "      {\n" +
        "        UPDATE staff\n" +
        "          SET comm = 0.01 * (SELECT AVG(salary)\n" +
        "                               FROM staff\n" +
        "                               WHERE id >= 310)\n" +
        "          WHERE CURRENT OF curName\n" +
        "      }\n" +
        "    }");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT name, dept " +
                                       "  FROM staff " +
                                       "  WHERE id >= 310 " +
                                       "  FOR UPDATE OF comm");

      curName = rs.getCursorName();
      Statement stmt1 = con.createStatement();
      while (rs.next())
      {
        dept = rs.getInt(2);
        if (dept != 84)
        {
          stmt1.executeUpdate(
            "UPDATE staff " +
            "  SET comm = 0.01 * (SELECT AVG(salary) " +
            "                       FROM staff " +
            "                       WHERE id >= 310) " +
            "  WHERE CURRENT OF " + curName);
        }
      }
      stmt1.close();
      rs.close();
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // positionedUpdateUsingSubqueryInSetClause

  // This function demonstrates how to perform positioned update on a table
  // using correlated subquery in the 'SET' clause
  static void
  positionedUpdateUsingCorrelatedSubqueryInSetClause(Connection con)
  {
    try
    {
      String name = null;
      int dept = 0;
      String curName = null;

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  UPDATE\n" +
        "  SELECT\n" +
        "TO PERFORM POSITIONED UPDATE ON A TABLE\n" +
        "USING CORRELATED SUBQUERY IN 'SET' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Invoke the statements:\n" +
        "    get a ResultSet rs for\n" +
        "      SELECT name, dept\n" +
        "        FROM staff\n" +
        "        WHERE id >= 310\n" +
        "        FOR UPDATE OF comm\n" +
        "\n" +
        "    curName = rs.getCursorName();\n" +
        "    while (rs.next())\n" +
        "    {\n" +
        "      if (dept != 84)\n" +
        "      {\n" +
        "        UPDATE staff s1\n" +
        "          SET comm = 0.01 * (SELECT AVG(salary)\n"+
        "                               FROM staff s2\n" +
        "                               WHERE id >= 310 AND\n" +
        "                                     s2.dept = s1.dept)\n" +
        "          WHERE CURRENT OF curName\n" +
        "      }\n" +
        "    }");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT name, dept " +
                                       "  FROM staff " +
                                       "  WHERE id >= 310 " +
                                       "  FOR UPDATE OF comm");

      curName = rs.getCursorName();
      Statement stmt1 = con.createStatement();
      while (rs.next())
      {
        dept = rs.getInt(2);
        if (dept != 84)
        {
          stmt1.executeUpdate(
            "UPDATE staff s1 " +
            "  SET comm = 0.01 * (SELECT AVG(salary) " +
            "                       FROM staff s2 " +
            "                       WHERE id >= 310 AND " +
            "                             s2.dept = s1.dept) " +
            "  WHERE CURRENT OF " + curName);
        }
      }
      stmt1.close();
      rs.close();
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // updateUsingCorrelatedSubqueryInSetClause

  // This function demonstrates how to delete table data
  static void deleteWithoutSubqueries(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  DELETE\n" +
        "TO DELETE TABLE DATA.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // delete data from the 'staff' table without subqueries
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    DELETE FROM staff WHERE id >= 310 AND salary > 20000 AND job != 'Sales'\n");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "DELETE FROM staff WHERE id >= 310 AND salary > 20000 AND job != 'Sales'");
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // deleteWithoutSubqueries

  // This function demonstrates how to delete table data using
  // subquery in the 'WHERE' clause.
  static void deleteUsingSubqueryInWhereClause(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  DELETE\n" +
        "TO DELETE TABLE DATA\n" +
        "USING SUBQUERY IN 'WHERE' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // display a partial content of the 'employee' table
      employeeTbPartialContentDisplay(con);

      // delete data from the 'staff' table using subquery in the 'WHERE'
      // clause
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    DELETE FROM staff\n" +
        "      WHERE id >= 310 AND\n" +
        "       job != 'Sales' AND\n" +
        "            salary > (SELECT AVG(salary)\n" +
        "                        FROM employee\n" +
        "                        WHERE workdept = 'E11')");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "DELETE FROM staff " +
        "  WHERE id >= 310 AND " +
        "       job != 'Sales' AND " +
        "        salary > (SELECT AVG(salary) " +
        "                    FROM employee " +
        "                    WHERE workdept = 'E11')");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // deleteUsingSubqueryInWhereClause

  // This function demonstrates how to delete table data using
  // correlated subquery in the 'WHERE' clause.
  static void deleteUsingCorrelatedSubqueryInWhereClause(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  DELETE\n" +
        "TO DELETE TABLE DATA\n" +
        "USING A CORRELATED SUBQUERY IN 'WHERE' CLAUSE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // delete data from the 'staff' table using correlated subquery in the
      // 'WHERE' clause
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    DELETE FROM staff s1\n" +
        "      WHERE id >= 310 AND\n" +
        "        job != 'Sales' AND\n" +
        "            salary < (SELECT AVG(salary)\n" +
        "                        FROM staff s2\n" +
        "                        WHERE s2.dept = s1.dept)");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "DELETE FROM staff s1 " +
        "  WHERE id >= 310 AND " +
        "     job != 'Sales' AND " +
        "        salary < (SELECT AVG(salary) " +
        "                    FROM staff s2 " +
        "                    WHERE s2.dept = s1.dept)");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // TbDeleteUsingCorrelatedSubqueryInWhereClause

  // This function demonstrates how to perform positioned delete on a table
  static void positionedDelete(Connection con)
  {
    try
    {
      String name = null;
      int dept = 0;
      String curName = null;

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  DELETE\n" +
        "TO PERFORM POSITIONED DELETE ON A TABLE.");

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Invoke the statements:\n" +
        "    get a ResultSet rs for\n" +
        "      SELECT name, dept FROM staff WHERE id >= 310 AND job != 'Sales' FOR UPDATE\n" +
        "\n" +
        "    curName = rs.getCursorName();\n" +
        "    while (rs.next())\n" +
        "    {\n" +
        "      if (dept != 84)\n" +
        "      {\n" +
        "        DELETE FROM staff WHERE CURRENT OF curName\n" +
        "      }\n" +
        "    }");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT name, dept FROM staff WHERE id >= 310 AND job != 'Sales' FOR UPDATE");

      curName = rs.getCursorName();
      Statement stmt1 = con.createStatement();
      while (rs.next())
      {
        dept = rs.getInt(2);
        if (dept != 84)
        {
          stmt1.executeUpdate(
            "DELETE FROM staff WHERE CURRENT OF " + curName);
        }
      }
      stmt1.close();
      rs.close();
      stmt.close();

      // display the final content of the 'staff' table
      staffTbContentDisplay(con);

      // rollback the transaction
      System.out.println();
      System.out.println("  Rollback the transaction...");
      con.rollback();
      System.out.println("  Rollback Done.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // positionedDelete */
} // TbMod

