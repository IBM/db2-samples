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
// SOURCE FILE NAME: TbTrig.java
//
// SAMPLE: How to use triggers
//
// SQL Statements USED:
//         CREATE TABLE
//         CREATE TRIGGER
//         DROP TABLE
//         DROP TRIGGER
//         SELECT
//         INSERT
//         UPDATE
//         DELETE
//         COMMIT
//         ROLLBACK
//
// JAVA 2 CLASSES USED:
//         Statement
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
// OUTPUT FILE: TbTrig.out (available in the online documentation)
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

class TbTrig
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO USE TRIGGERS.");

      // connect to the 'sample' database
      db.connect();

      TbBeforeInsertTriggerUse(db.con);
      TbAfterInsertTriggerUse(db.con);
      TbBeforeDeleteTriggerUse(db.con);
      TbBeforeUpdateTriggerUse(db.con);
      TbAfterUpdateTriggerUse(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // helping function
  static void StaffTbContentDisplay(Connection con)
  {
    try
    {
      int id = 0;
      int dept = 0;
      double salary = 0.0;
      String name = null;
      String job = null;
      Integer years = new Integer(0);
      Double comm = new Double(0.0);

      System.out.println();
      System.out.println("  SELECT * FROM staff WHERE id <= 50");

      System.out.println(
        "    ID  NAME    DEPT JOB   YEARS SALARY   COMM\n" +
        "    --- ------- ---- ----- ----- -------- --------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
                       "SELECT * FROM staff WHERE id <= 50");

      while (rs.next())
      {
        id = rs.getInt(1);
        name = rs.getString(2);
        dept = rs.getInt(3);
        job = rs.getString(4);

        if (rs.getString(5) == null)
        {
          years = null;
        }
        else
        {
          years = Integer.valueOf(rs.getString(5));
        }
        salary = rs.getDouble(6);
        if (rs.getDouble(7) == 0.0)
        {
          comm = null;
        }
        else
        {
          comm = Double.valueOf(Double.toString(rs.getDouble(7)));
        }

        System.out.print("    " + Data.format(id,3) +
                         " " + Data.format(name,7) +
                         " " + Data.format(dept,4));
        if (job != null)
        {
          System.out.print(" " + Data.format(job,5));
        }
        else
        {
          System.out.print("     -");
        }
        if (years != null)
        {
          System.out.print(" " + Data.format(years,5));
        }
        else
        {
          System.out.print("     -");
        }
        System.out.print(" " + Data.format(salary,7,2));
        if (comm != null)
        {
          System.out.print(" " + Data.format(comm,7,2));
        }
        else
        {
          System.out.print("     -");
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
  } // StaffTbContentDisplay

  // helping function
  static void StaffStatsTbCreate(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  CREATE TABLE staff_stats(nbemp SMALLINT)");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("CREATE TABLE staff_stats(nbemp SMALLINT)");
      stmt.close();

      System.out.println();
      System.out.println(
        "  INSERT INTO staff_stats VALUES(SELECT COUNT(*) FROM staff)");

      Statement stmt1 = con.createStatement();
      stmt1.execute(
        "INSERT INTO staff_stats VALUES(SELECT COUNT(*) FROM staff)");
      stmt1.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // StaffStatsTbCreate

  // helping function
  static void StaffStatsTbContentDisplay(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  SELECT nbemp FROM staff_stats");
      System.out.println("    NBEMP\n" +
                         "    -----");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM staff_stats");
      rs.next();

      System.out.println("    " + Data.format(rs.getShort("nbemp"),5));
      stmt.close();
      rs.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // StaffStatsTbContentDisplay

  // helping function
  static void StaffStatsTbDrop(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE staff_stats");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE staff_stats");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // StaffStatsTbDrop

  // helping function
  static void SalaryStatusTbCreate(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE salary_status(emp_name VARCHAR(9),\n" +
        "                             sal DECIMAL(7, 2),\n" +
        "                             status CHAR(15))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE salary_status(emp_name VARCHAR(9), " +
        "                           sal DECIMAL(7, 2), " +
        "                           status CHAR(15))");
      stmt.close();

      System.out.println();
      System.out.println(
        "  INSERT INTO salary_status\n" +
        "    SELECT name, salary, 'Not Defined'\n" +
        "      FROM staff\n" +
        "      WHERE id <= 50");

      Statement stmt1 = con.createStatement();
      stmt1.execute("INSERT INTO salary_status " +
                    "  SELECT name, salary, 'Not Defined' " +
                    "    FROM staff " +
                    "    WHERE id <= 50");
      stmt1.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // SalaryStatusTbCreate

  // helping function
  static void SalaryStatusTbContentDisplay(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  SELECT * FROM salary_status");
      System.out.println("    EMP_NAME   SALARY   STATUS\n" +
                         "    ---------- -------- ----------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM salary_status");

      while (rs.next())
      {
        System.out.println("    " +
          Data.format(rs.getString("emp_name"),10) + " " +
          Data.format(rs.getDouble("sal"),7,2) + " " +
          Data.format(rs.getString("status"),15));
      }
      stmt.close();
      rs.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // SalaryStatusTbContentDisplay

  // helping function
  static void SalaryStatusTbDrop(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE salary_status");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE salary_status");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // SalaryStatusTbDrop

  // helping function
  static void SalaryHistoryTbCreate(Connection con)
  {
    System.out.println();
    System.out.println(
      "  CREATE TABLE salary_history(employee_name VARCHAR(9),\n" +
      "                              salary_record DECIMAL(7, 2),\n" +
      "                              change_date DATE)");

    try
    {
      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE salary_history(employee_name VARCHAR(9), " +
        "                            salary_record DECIMAL(7, 2), " +
        "                            change_date DATE)");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // SalaryHistoryTbCreate

  // helping function
  static void SalaryHistoryTbContentDisplay(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  SELECT * FROM salary_history");
      System.out.println("    EMPLOYEE_NAME  SALARY_RECORD  CHANGE_DATE\n" +
                         "    -------------- -------------- -----------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM salary_history");

      while (rs.next())
      {
        System.out.println("    " +
          Data.format(rs.getString("employee_name"),14) + " " +
          Data.format(rs.getDouble("salary_record"),13,2) + " " +
          rs.getDate("change_date"));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // SalaryHistoryTbContentDisplay

  // helping function
  static void SalaryHistoryTbDrop(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE salary_history");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE salary_history");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // SalaryHistoryTbDrop


  static void TbBeforeInsertTriggerUse(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TRIGGER\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  ROLLBACK\n" +
      "  DROP TRIGGER\n" +
      "TO SHOW A 'BEFORE INSERT' TRIGGER.");

    // display the initial content of the 'staff' table
    StaffTbContentDisplay(con);

    // create a 'BEFORE INSERT' trigger
    try
    {
      System.out.println();
      System.out.println("  CREATE TRIGGER min_sal\n" +
                         "    NO CASCADE BEFORE INSERT\n" +
                         "    ON staff\n" +
                         "    REFERENCING NEW AS newstaff\n" +
                         "    FOR EACH ROW \n" +
                         "    BEGIN ATOMIC\n" +
                         "      SET newstaff.salary =\n" +
                         "      CASE\n" +
                         "        WHEN newstaff.job = 'Mgr' AND\n" +
                         "             newstaff.salary < 17000.00\n" +
                         "        THEN 17000.00\n" +
                         "        WHEN newstaff.job = 'Sales' AND\n" +
                         "             newstaff.salary < 14000.00\n" +
                         "        THEN 14000.00\n" +
                         "        WHEN newstaff.job = 'Clerk' AND\n" +
                         "             newstaff.salary < 10000.00\n" +
                         "        THEN 10000.00\n" +
                         "        ELSE newstaff.salary\n" +
                         "      END;\n" +
                         "    END");

      Statement stmt = con.createStatement();
      stmt.execute("CREATE TRIGGER min_sal " +
                   "  NO CASCADE BEFORE INSERT " +
                   "  ON staff " +
                   "  REFERENCING NEW AS newstaff " +
                   "  FOR EACH ROW " +
                   "  BEGIN ATOMIC " +
                   "    SET newstaff.salary = " +
                   "    CASE " +
                   "      WHEN newstaff.job = 'Mgr'      AND " +
                   "           newstaff.salary < 17000.00 " +
                   "      THEN 17000.00 " +
                   "      WHEN newstaff.job = 'Sales'    AND " +
                   "           newstaff.salary < 14000.00 " +
                   "      THEN 14000.00 " +
                   "      WHEN newstaff.job = 'Clerk'    AND " +
                   "           newstaff.salary < 10000.00 " +
                   "      THEN 10000.00 " +
                   "      ELSE newstaff.salary " +
                   "    END; " +
                   "  END");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // insert table data using values
    try
    {
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    INSERT INTO staff(id, name, dept, job, salary)\n" +
        "      VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),\n" +
        "            (35, 'Hachey', 38, 'Mgr', 21270.00),\n" +
        "            (45, 'Wagland', 38, 'Sales', 11575.00)");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO staff(id, name, dept, job, salary) " +
        "  VALUES(25, 'Pearce', 38, 'Clerk', 7217.50), " +
        "        (35, 'Hachey', 38, 'Mgr', 21270.00), "  +
        "        (45, 'Wagland', 38, 'Sales', 11575.00)");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the final content of the 'staff' table
    StaffTbContentDisplay(con);

    // drop the trigger
    try
    {
      System.out.println();
      System.out.println("  Rollback the transaction.");
      con.rollback();

      System.out.println();
      System.out.println("  DROP TRIGGER min_sal");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP TRIGGER min_sal");
      stmt2.close();

      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // TbBeforeInsertTriggerUse

  static void TbAfterInsertTriggerUse(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TRIGGER\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  ROLLBACK\n" +
      "  DROP TRIGGER\n" +
      "TO SHOW AN 'AFTER INSERT' TRIGGER.");

    // create a table called 'staff_stats'
    StaffStatsTbCreate(con);

    // display the content of the 'staff_stats' table
    StaffStatsTbContentDisplay(con);

    // create an 'AFTER INSERT' trigger
    try
    {
      System.out.println();
      System.out.println("  CREATE TRIGGER new_hire\n" +
                         "    AFTER INSERT\n" +
                         "    ON staff\n" +
                         "    FOR EACH ROW \n" +
                         "    BEGIN ATOMIC\n" +
                         "      UPDATE staff_stats\n" +
                         "      SET nbemp = nbemp + 1;\n" +
                         "    END");

      Statement stmt = con.createStatement();
      stmt.execute("CREATE TRIGGER new_hire " +
                   "  AFTER INSERT " +
                   "  ON staff " +
                   "  FOR EACH ROW " +
                   "  BEGIN ATOMIC " +
                   "    UPDATE staff_stats " +
                   "    SET nbemp = nbemp + 1; " +
                   "  END");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // insert table data using values
    try
    {
      String strStmt;
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    INSERT INTO staff(id, name, dept, job, salary)\n" +
        "      VALUES(25, 'Pearce', 38, 'Clerk', 7217.50),\n" +
        "            (35, 'Hachey', 38, 'Mgr', 21270.00),\n" +
        "            (45, 'Wagland', 38, 'Sales', 11575.00)");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO staff(id, name, dept, job, salary) " +
        "  VALUES(25, 'Pearce' , 38, 'Clerk', 7217.50), " +
        "        (35, 'Hachey' , 38, 'Mgr'  , 21270.00), " +
        "        (45, 'Wagland', 38, 'Sales', 11575.00)");
      stmt1.close();

      // display the content of the 'staff_stats' table
      StaffStatsTbContentDisplay(con);

      System.out.println();
      System.out.println("  Rollback the transaction.");
      con.rollback();

      System.out.println();
      System.out.println("  DROP TRIGGER new_hire");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP TRIGGER new_hire");

      stmt2.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the 'staff_stats' table
    StaffStatsTbDrop(con);

  } // TbAfterInsertTriggerUse

  static void TbBeforeDeleteTriggerUse(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TRIGGER\n" +
      "  COMMIT\n" +
      "  DELETE\n" +
      "  ROLLBACK\n" +
      "  DROP TRIGGER\n" +
      "TO SHOW A 'BEFORE DELETE' TRIGGER.");

    // display the initial content of the 'staff' table
    StaffTbContentDisplay(con);

    // create a 'BEFORE DELETE' trigger
    try
    {
      System.out.println();
      System.out.println("  CREATE TRIGGER do_not_delete_sales\n" +
                         "    NO CASCADE BEFORE DELETE\n" +
                         "    ON staff\n" +
                         "    REFERENCING OLD AS oldstaff\n" +
                         "    FOR EACH ROW \n" +
                         "    WHEN (oldstaff.job = 'Sales')\n" +
                         "    BEGIN ATOMIC\n" +
                         "      SIGNAL SQLSTATE '75000' " +
                         "('Sales can not be deleted now.');\n" +
                         "    END");

      Statement stmt = con.createStatement();
      stmt.execute("CREATE TRIGGER do_not_delete_sales " +
                   "  NO CASCADE BEFORE DELETE " +
                   "  ON staff " +
                   "  REFERENCING OLD AS oldstaff " +
                   "  FOR EACH ROW " +
                   "  WHEN (oldstaff.job = 'Sales') " +
                   "  BEGIN ATOMIC " +
                   "    SIGNAL SQLSTATE '75000' " +
                   "    ('Sales can not be deleted now.'); " +
                   "  END");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // delete data from the 'staff' table
    try
    {
      System.out.println();
      System.out.println("  Invoke the statement:\n" +
                         "    DELETE FROM staff WHERE id <= 50");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("DELETE FROM staff WHERE id <= 50");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }
    // display the final content of the 'staff' table
    StaffTbContentDisplay(con);

    // drop the trigger
    try
    {
      System.out.println();
      System.out.println("  Rollback the transaction.");
      con.rollback();

      System.out.println();
      System.out.println("  DROP TRIGGER do_not_delete_sales");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP TRIGGER do_not_delete_sales");
      stmt2.close();

      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // TbBeforeDeleteTriggerUse

  static void TbBeforeUpdateTriggerUse(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TRIGGER\n" +
      "  COMMIT\n" +
      "  UPDATE\n" +
      "  ROLLBACK\n" +
      "  DROP TRIGGER\n" +
      "TO SHOW A 'BEFORE UPDATE' TRIGGER.");

    // create a table called salary_status
    SalaryStatusTbCreate(con);

    // display the content of the 'salary_status' table
    SalaryStatusTbContentDisplay(con);

    // create a 'BEFORE UPDATE' trigger
    try
    {
      System.out.println();
      System.out.println("  CREATE TRIGGER salary_status\n" +
                         "    NO CASCADE BEFORE UPDATE OF sal\n" +
                         "    ON salary_status\n" +
                         "    REFERENCING NEW AS new OLD AS old\n" +
                         "    FOR EACH ROW \n" +
                         "    BEGIN ATOMIC\n" +
                         "      SET new.status =\n" +
                         "      CASE\n" +
                         "        WHEN new.sal < old.sal\n" +
                         "        THEN 'Decreasing'\n" +
                         "        WHEN new.sal > old.sal\n" +
                         "        THEN 'Increasing'\n" +
                         "      END;\n" +
                         "    END");

      Statement stmt = con.createStatement();
      stmt.execute("CREATE TRIGGER sal_status " +
                   "  NO CASCADE BEFORE UPDATE OF sal " +
                   "  ON salary_status " +
                   "  REFERENCING NEW AS new OLD AS old " +
                   "  FOR EACH ROW " +
                   "  BEGIN ATOMIC " +
                   "    SET new.status = " +
                   "    CASE " +
                   "      WHEN new.sal < old.sal " +
                   "      THEN 'Decreasing' " +
                   "      WHEN new.sal > old.sal " +
                   "      THEN 'Increasing' " +
                   "    END; " +
                   "  END ");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // update data in table 'salary_status'
    try
    {
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE salary_status SET sal = 18000.00");

      Statement stmt1 = con.createStatement();
      stmt1.execute("UPDATE salary_status SET sal = 18000.00");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the content of the 'salary_status' table
    SalaryStatusTbContentDisplay(con);

    // rollback the transaction
    try
    {
      System.out.println();
      System.out.println("  Rollback the transaction.");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the trigger
    try
    {
      System.out.println();
      System.out.println("  DROP TRIGGER sal_status");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP TRIGGER sal_status");
      stmt2.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop salary_status table
    SalaryStatusTbDrop(con);

  } // TbBeforeUpdateTriggerUse

  static void TbAfterUpdateTriggerUse(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TRIGGER\n" +
      "  COMMIT\n" +
      "  UPDATE\n" +
      "  DROP TRIGGER\n" +
      "TO SHOW AN 'AFTER UPDATE' TRIGGER.");

    // create a table called 'salary_history'
    SalaryHistoryTbCreate(con);

    // display the content of the 'salary_history' table
    SalaryHistoryTbContentDisplay(con);

    try
    {
      System.out.println();
      System.out.println("  CREATE TRIGGER sal_history\n" +
                         "    AFTER UPDATE OF salary\n" +
                         "    ON staff\n" +
                         "    REFERENCING NEW AS newstaff\n" +
                         "    FOR EACH ROW \n" +
                         "    BEGIN ATOMIC\n" +
                         "      INSERT INTO salary_history\n" +
                         "        VALUES(newstaff.name,\n" +
                         "               newstaff.salary,\n" +
                         "               CURRENT DATE);\n" +
                         "    END");

      Statement stmt = con.createStatement();
      stmt.execute("CREATE TRIGGER sal_history " +
                   "  AFTER UPDATE OF salary " +
                   "  ON staff " +
                   "  REFERENCING NEW AS newstaff " +
                   "  FOR EACH ROW " +
                   "  BEGIN ATOMIC " +
                   "    INSERT INTO salary_history " +
                   "      VALUES(newstaff.name, " +
                   "             newstaff.salary, " +
                   "             CURRENT DATE); " +
                   "  END");
      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // update table data
    try
    {
      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff SET salary = 20000.00 WHERE name = 'Sanders'");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "UPDATE staff SET salary = 20000.00 WHERE name = 'Sanders'");
      stmt1.close();

      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff SET salary = 21000.00 WHERE name = 'Sanders'");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "UPDATE staff SET salary = 21000.00 WHERE name = 'Sanders'");
      stmt2.close();

      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff SET salary = 23000.00 WHERE name = 'Sanders'");

      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate(
        "UPDATE staff SET salary = 23000.00 WHERE name = 'Sanders'");
      stmt3.close();

      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff SET salary = 20000.00 WHERE name = 'Hanes'");

      Statement stmt4 = con.createStatement();
      stmt4.executeUpdate(
        "UPDATE staff SET salary = 20000.00 WHERE name = 'Hanes'");
      stmt4.close();

      System.out.println();
      System.out.println(
        "  Invoke the statement:\n" +
        "    UPDATE staff SET salary = 21000.00 WHERE name = 'Hanes'");

      Statement stmt5 = con.createStatement();
      stmt5.executeUpdate(
        "UPDATE staff SET salary = 21000.00 WHERE name = 'Hanes'");
      stmt5.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the content of the 'salary_history' table
    SalaryHistoryTbContentDisplay(con);

    // rollback the transaction
    try
    {
      System.out.println();
      System.out.println("  Rollback the transaction.");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the trigger
    try
    {
      System.out.println();
      System.out.println("  DROP TRIGGER sal_history");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TRIGGER sal_history");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the 'salary_history' table
    SalaryHistoryTbDrop(con);

  } // TbAfterUpdateTriggerUse
} // TbTrig

