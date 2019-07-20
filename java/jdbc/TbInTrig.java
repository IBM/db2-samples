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
//**************************************************************************
//
// SOURCE FILE NAME: TbInTrig.java 
//    
// SAMPLE: How to use an 'INSTEAD OF' trigger on a view 
//           
// SQL STATEMENTS USED:
//         SELECT
//         CREATE TABLE
//         DROP
//         CREATE TRIGGER
//         INSERT
//         DELETE
//         UPDATE
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: TbInTrig.out (available in the online documentation)
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
// For the latest information on programming, building, and running DB2 
// applications, visit the DB2 application development website: 
//     http://www.software.ibm.com/data/db2/udb/ad
//*************************************************************************/

import java.lang.*;
import java.sql.*;

class TbInTrig
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "  THIS SAMPLE SHOWS HOW TO USE 'INSTEAD OF' TRIGGERS.\n");

      // connect to the 'sample' database
      db.connect();

      // Create a view 'staffv' of the table 'staff'
      CreateViewStaffV(db.con);

      // Demonstrate an UPDATE operation before an INSTEAD OF UPDATE trigger
      // is created
      NormalUpdate(db.con);

      // Demonstrate the same UPDATE operation after an INSTEAD OF UPDATE
      // trigger is created
      UpdateWithInsteadOfTrigger(db.con);

      // Demonstrate how to update a number of tables through a common view
      // and the use of a set of 'INSTEAD OF' triggers
      MutliTableUpdate(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // This method creates a view 'staffv' of the table 'staff' 
  public static void CreateViewStaffV(Connection conn)
  {
    try
    {
      System.out.println(
        "\n  CREATE A VIEW 'staffv' OF THE TABLE 'staff'\n" +
        "\n  INVOKE THE STATEMENT:\n" +
        "\n    CREATE VIEW staffv(ID, NAME, DEPT, JOB, YEARS, SALARY, COMM)"+
        "\n      AS SELECT * FROM staff WHERE ID >= 310");

      Statement stmt = conn.createStatement();
      stmt.executeUpdate(
        "CREATE VIEW staffv(ID, NAME, DEPT, JOB, YEARS, SALARY, COMM)" +
        "  AS SELECT * FROM staff WHERE ID >= 310");

      stmt.close();
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  }

  // Helper method: This method displays the results of a query specified by
  // 'selectstmt' on the 'staffv' view 
  private static void StaffvContentDisplay(Connection conn,
                                           String selectStmt)
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
      System.out.println("  " + selectStmt + "\n");

      System.out.println(
        "    ID  NAME    DEPT JOB   YEARS SALARY   COMM\n" +
        "    --- ------- ---- ----- ----- -------- --------");

      Statement stmt = conn.createStatement();
      ResultSet rs = stmt.executeQuery(selectStmt);

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
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  } // StaffvContentDisplay

  // This method demonstrates an UPDATE operation before an 
  // 'INSTEAD OF UPDATE' trigger is created 
  public static void InsteadOfUpdateTriggerCreate(Connection conn)
  {
    try
    {
      System.out.println(
        "\n  CREATE AN 'INSTEAD OF UPDATE' TRIGGER CALLED 'staff_raise'");

      // Create a trigger which apart from the original update, raises the
      // salary further based on the number of years the employee has served
      System.out.println(
        "\n    CREATE TRIGGER staff_raise INSTEAD OF UPDATE ON staffv" +
        "\n      REFERENCING NEW AS n OLD AS o " +
        "\n      FOR EACH ROW " +
        "\n      BEGIN ATOMIC " +
        "\n        VALUES(CASE " +
        "\n                 WHEN n.ID = o.ID THEN 0 " +
        "\n                 ELSE RAISE_ERROR('70002', 'Must not change ID')"+
        "\n               END); " +
        "\n        UPDATE STAFF AS S " +
        "\n          SET (ID, NAME, DEPT, JOB, YEARS, COMM, SALARY) " +
        "\n            = (n.ID, n.NAME, n.DEPT, n.JOB, n.YEARS, n.COMM, " +
        "\n               CASE " +
        "\n                 WHEN n.YEARS IS NULL THEN o.salary " +
        "\n                 WHEN n.YEARS <= 2 THEN n.salary + 500 " +
        "\n                 WHEN n.YEARS <= 4 THEN n.salary + 1000 " +
        "\n                 WHEN n.YEARS <= 6 THEN n.salary + 2000 " +
        "\n                 WHEN n.YEARS <= 8 THEN n.salary + 3500 " +
        "\n                 WHEN n.YEARS <= 10 THEN n.salary + 5500 " +
        "\n                 ELSE n.salary + 6000 " +
        "\n               END) " +
        "\n          WHERE n.ID = S.ID; " +
        "\n      END");

      Statement stmt = conn.createStatement();
      stmt.execute(
        "CREATE TRIGGER staff_raise INSTEAD OF UPDATE ON staffv" +
        "  REFERENCING NEW AS n OLD AS o " +
        "  FOR EACH ROW " +
        "  BEGIN ATOMIC " +
        "    VALUES(CASE " +
        "             WHEN n.ID = o.ID THEN 0 " +
        "             ELSE RAISE_ERROR('70002', 'Must not change ID') " +
        "           END); " +
        "    UPDATE STAFF AS S " +
        "      SET (ID, NAME, DEPT, JOB, YEARS, COMM, SALARY) " +
        "        = (n.ID, n.NAME, n.DEPT, n.JOB, n.YEARS, n.COMM, " +
        "           CASE " +
        "             WHEN n.YEARS IS NULL THEN o.salary " +
        "             WHEN n.YEARS <= 2 THEN n.salary + 500 " +
        "             WHEN n.YEARS <= 4 THEN n.salary + 1000 " +
        "             WHEN n.YEARS <= 6 THEN n.salary + 2000 " +
        "             WHEN n.YEARS <= 8 THEN n.salary + 3500 " +
        "             WHEN n.YEARS <= 10 THEN n.salary + 5500 " +
        "             ELSE n.salary + 6000 " +
        "           END) " +
        "      WHERE n.ID = S.ID; " +
        "  END ");

      stmt.close();
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  } // InsteadOfUpdateTriggerCreate

  // This method demonstrates an UPDATE operation before an
  // 'INSTEAD OF UPDATE' trigger has been created 
  public static void NormalUpdate(Connection conn)
  {
    try
    {
      String selectString = "SELECT * FROM staffv WHERE ID = 340";

      System.out.println(
        "\n  -----------------------------------------------------------" +
        "\n  USE THE SQL STATEMENTS:\n" +
        "\n    ROLLBACK" +
        "\n    UPDATE\n" +
        "\n  TO DISPLAY THE RESULTS OF AN UPDATE STATEMENT ON THE VIEW" +
        " 'staffv'" +
        "\n  BEFORE AN 'INSTEAD OF UPDATE' TRIGGER IS CREATED.");

      // Display the contents of the row in 'staffv' that is going to be
      // updated 
      System.out.println(
        "\n  CONTENT OF A ROW IN 'staffv' VIEW BEFORE IT IS UPDATED");
      StaffvContentDisplay(conn, selectString);

      // Update the 'staffv' view 
      System.out.println(
        "\n  INVOKE THE STATEMENT:\n" +
        "\n    UPDATE staffv SET years=4,COMM=50 WHERE ID = 340");

      Statement stmt = conn.createStatement();
      stmt.executeUpdate("UPDATE staffv SET years=4,COMM=50 WHERE ID = 340");

      // Display the contents of the row in 'staffv' after updating it 
      System.out.println(
        "\n  CONTENTS OF THE ROW IN 'staffv' AFTER UPDATING IT");
      StaffvContentDisplay(conn, selectString);

      stmt.close();
      conn.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  } // NormalUpdate

  // This method demonstrates an UPDATE operation after an
  // 'INSTEAD OF UPDATE' trigger has been created 
  public static void UpdateWithInsteadOfTrigger(Connection conn)
  {
    try
    {
      String selectString = "SELECT * FROM staffv WHERE ID = 340";

      System.out.println(
        "\n  -----------------------------------------------------------" +
        "\n  USE THE SQL STATEMENTS:\n" +
        "\n    CREATE TRIGGER" +
        "\n    UPDATE" +
        "\n    ROLLBACK" +
        "\n    COMMIT\n" +
        "\n  TO DISPLAY THE RESULTS OF THE SAME UPDATE STATEMENT ON THE" +
        " VIEW" +
        "\n  'staffv' AFTER CREATING AN 'INSTEAD OF UPDATE' TRIGGER.");

      // Create an 'INSTEAD OF UPDATE' trigger
      InsteadOfUpdateTriggerCreate(conn);

      // Display the row to be updated in 'staffv' before an UPDATE statement
      // is issued 
      System.out.println(
        "\n  CONTENTS OF THE ROW IN 'staffv' BEFORE IT IS UPDATED");
      StaffvContentDisplay(conn, selectString);

      // Issue an UPDATE statement to update the 'staffv' view 
      System.out.println(
        "\n  INVOKE THE SAME STATEMENT:\n" +
        "\n    UPDATE staffv SET years=4,COMM=50 WHERE ID = 340");

      Statement stmt = conn.createStatement();
      stmt.executeUpdate("UPDATE staffv SET years=4,COMM=50 WHERE ID = 340");

      // Display the contents of the row in 'staffv' after updating it with
      // the UPDATE statement
      System.out.println(
        "\n  CONTENTS OF THE ROW IN 'staffv' AFTER INVOKING THE UPDATE" +
        " STATEMENT," +
        "\n  WHICH NOW CAUSES THE 'INSTEAD OF UPDATE' TRIGGER TO FIRE");
      StaffvContentDisplay(conn, selectString);

      // Rollback changes made to the view 
      conn.rollback();

      // Drop the trigger 
      stmt.execute("DROP TRIGGER staff_raise");

      // Drop the view 
      stmt.execute("DROP VIEW staffv");

      stmt.close();
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  }

  // This method creates tables: PERSONS, STUDENTS and EMPLOYEES and
  // creates a view called PERSONS_V 
  private static void CreateTablesAndView(Connection conn)
  {
    try
    {
      // Create the table PERSONS 
      System.out.println(
        "\n  INVOKE THE STATEMENTS:\n" +
        "\n    CREATE TABLE PERSONS(ssn INT NOT NULL, name VARCHAR(20)" +
        " NOT NULL)");

      Statement stmt = conn.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE PERSONS(ssn INT NOT NULL, name VARCHAR(20) NOT NULL)");

      // Create the table EMPLOYEES 
      System.out.println(
        "\n    CREATE TABLE EMPLOYEES(ssn INT NOT NULL," +
        "\n                           company VARCHAR(20) NOT NULL," +
        "\n                           salary DECIMAL(9,2))");

      stmt.executeUpdate(
        "CREATE TABLE EMPLOYEES(ssn INT NOT NULL," +
        "                       company VARCHAR(20) NOT NULL," +
        "                       salary DECIMAL(9,2))");

      // Create the table STUDENTS
      System.out.println(
        "\n    CREATE TABLE STUDENTS(ssn INT NOT NULL," +
        "\n                          university VARCHAR(20) NOT NULL," +
        "\n                          major VARCHAR(10))");

      stmt.executeUpdate(
        "CREATE TABLE STUDENTS(ssn INT NOT NULL," +
        "                      university VARCHAR(20) NOT NULL," +
        "                      major VARCHAR(10))");

      // Create the view PERSONS_V 
      System.out.println(
        "\n    CREATE VIEW PERSONS_V(ssn, name, company, " +
        "\n                          salary, university, major) " +
        "\n      AS SELECT P.ssn, name, company, " +
        "\n                salary, university, major " +
        "\n           FROM PERSONS P LEFT OUTER JOIN EMPLOYEES E " +
        "\n                               ON P.ssn = E.ssn " +
        "\n                          LEFT OUTER JOIN STUDENTS S " +
        "\n                               ON P.ssn = S.ssn");

      stmt.executeUpdate(
        "CREATE VIEW PERSONS_V(ssn, name, company," +
        "                      salary, university, major)" +
        "  AS SELECT P.ssn, name, company,salary, university, major" +
        "       FROM PERSONS P LEFT OUTER JOIN EMPLOYEES E" +
        "            ON P.ssn = E.ssn" +
        "       LEFT OUTER JOIN STUDENTS S" +
        "            ON P.ssn = S.ssn");
      stmt.close();
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  } // CreateTablesAndView 

  // This method creates INSTEAD OF triggers: INSERT_PERSONS_V,
  // UPDATE_PERSONS_V and DELETE_PERSONS_V on the view PERSONS_V
  private static void CreatePersonsVTriggers(Connection conn)
  {
    try
    {
      // Create the INSTEAD OF INSERT trigger 'INSERT_PERSONS_V' 
      System.out.println(
        "\n  CREATE AN 'INSTEAD OF INSERT' TRIGGER CALLED" +
        " 'INSERT_PERSONS_V':\n" +
        "\n  INVOKE THE STATEMENT:");

      System.out.println(
        "\n    CREATE TRIGGER INSERT_PERSONS_V " +
        "\n      INSTEAD OF INSERT ON PERSONS_V " +
        "\n      REFERENCING NEW AS n FOR EACH ROW " +
        "\n      BEGIN ATOMIC " +
        "\n        INSERT INTO PERSONS VALUES (n.ssn, n.name); " +
        "\n        IF n.university IS NOT NULL THEN " +
        "\n          INSERT INTO STUDENTS " +
        "\n            VALUES(n.ssn, n.university, n.major); " +
        "\n        END IF; " +
        "\n        IF n.company IS NOT NULL THEN " +
        "\n          INSERT INTO EMPLOYEES " +
        "\n            VALUES(n.ssn, n.company, n.salary); " +
        "\n        END IF; " +
        "\n      END");

      Statement stmt = conn.createStatement();
      stmt.execute(
        "CREATE TRIGGER INSERT_PERSONS_V " +
        "  INSTEAD OF INSERT ON PERSONS_V " +
        "  REFERENCING NEW AS n FOR EACH ROW " +
        "  BEGIN ATOMIC " +
        "    INSERT INTO PERSONS VALUES (n.ssn, n.name); " +
        "    IF n.university IS NOT NULL THEN " +
        "      INSERT INTO STUDENTS " +
        "        VALUES(n.ssn, n.university, n.major); " +
        "    END IF; " +
        "    IF n.company IS NOT NULL THEN " +
        "      INSERT INTO EMPLOYEES " +
        "        VALUES(n.ssn, n.company, n.salary); " +
        "    END IF; " +
        "  END ");

      conn.commit();

      // Create the INSTEAD OF DELETE trigger 'DELETE_PERSONS_V' 
      System.out.println(
        "\n  CREATE AN 'INSTEAD OF DELETE' TRIGGER CALLED" +
        " 'DELETE_PERSONS_V':\n" +
        "\n  INVOKE THE STATEMENT:");

      System.out.println(
        "\n    CREATE TRIGGER DELETE_PERSONS_V " +
        "\n      INSTEAD OF DELETE ON PERSONS_V " +
        "\n      REFERENCING OLD AS o FOR EACH ROW " +
        "\n      BEGIN ATOMIC " +
        "\n        DELETE FROM STUDENTS WHERE ssn = o.ssn; " +
        "\n        DELETE FROM EMPLOYEES WHERE ssn = o.ssn; " +
        "\n        DELETE FROM PERSONS WHERE ssn = o.ssn; " +
        "\n      END");

      stmt.execute(
        "CREATE TRIGGER DELETE_PERSONS_V " +
        "  INSTEAD OF DELETE ON PERSONS_V " +
        "  REFERENCING OLD AS o FOR EACH ROW " +
        "  BEGIN ATOMIC " +
        "    DELETE FROM STUDENTS WHERE ssn = o.ssn; " +
        "    DELETE FROM EMPLOYEES WHERE ssn = o.ssn; " +
        "    DELETE FROM PERSONS WHERE ssn = o.ssn; " +
        "  END ");

      conn.commit();

      // Create the INSTEAD OF UPDATE trigger 'UPDATE_PERSONS_V'
      System.out.println(
        "\n  CREATE AN 'INSTEAD OF UPDATE' TRIGGER CALLED " +
        "'UPDATE_PERSONS_V':\n" +
        "\n  INVOKE THE STATEMENT:");

      System.out.println(
        "\n    CREATE TRIGGER UPDATE_PERSONS_V " +
        "\n      INSTEAD OF UPDATE ON PERSONS_V " +
        "\n      REFERENCING OLD AS o NEW AS n " +
        "\n      FOR EACH ROW " +
        "\n      BEGIN ATOMIC " +
        "\n        UPDATE PERSONS " +
        "\n          SET (ssn, name) = (n.ssn, n.name) " +
        "\n          WHERE ssn = o.ssn; " +
        "\n        IF n.university IS NOT NULL " +
        "\n           AND o.university IS NOT NULL THEN " +
        "\n          UPDATE STUDENTS " +
        "\n            SET (ssn, university, major) " +
        "\n              = (n.ssn, n.university, n.major) " +
        "\n            WHERE ssn = o.ssn; " +
        "\n        ELSEIF n.university IS NULL THEN " +
        "\n          DELETE FROM STUDENTS WHERE ssn = o.ssn; " +
        "\n        ELSE " +
        "\n          INSERT INTO STUDENTS " +
        "\n            VALUES(n.ssn, n.university, n.major); " +
        "\n        END IF; " +
        "\n        IF n.company IS NOT NULL " +
        "\n           AND o.company IS NOT NULL THEN " +
        "\n          UPDATE EMPLOYEES " +
        "\n            SET (ssn, company, salary) " +
        "\n              = (n.ssn, n.company, n.salary) " +
        "\n            WHERE ssn = o.ssn; " +
        "\n        ELSEIF n.company IS NULL THEN " +
        "\n          DELETE FROM EMPLOYEES WHERE ssn = o.ssn; " +
        "\n        ELSE " +
        "\n          INSERT INTO EMPLOYEES " +
        "\n            VALUES(n.ssn, n.company, n.salary); " +
        "\n        END IF; " +
        "\n      END");

      stmt.execute(
        "CREATE TRIGGER UPDATE_PERSONS_V " +
        "  INSTEAD OF UPDATE ON PERSONS_V " +
        "  REFERENCING OLD AS o NEW AS n " +
        "  FOR EACH ROW " +
        "  BEGIN ATOMIC " +
        "    UPDATE PERSONS " +
        "      SET (ssn, name) = (n.ssn, n.name) " +
        "      WHERE ssn = o.ssn; " +
        "    IF n.university IS NOT NULL " +
        "       AND o.university IS NOT NULL THEN " +
        "      UPDATE STUDENTS " +
        "        SET (ssn, university, major) " +
        "          = (n.ssn, n.university, n.major) " +
        "        WHERE ssn = o.ssn; " +
        "    ELSEIF n.university IS NULL THEN " +
        "      DELETE FROM STUDENTS WHERE ssn = o.ssn; " +
        "    ELSE " +
        "      INSERT INTO STUDENTS " +
        "        VALUES(n.ssn, n.university, n.major); " +
        "    END IF; " +
        "    IF n.company IS NOT NULL " +
        "       AND o.company IS NOT NULL THEN " +
        "      UPDATE EMPLOYEES " +
        "        SET (ssn, company, salary) " +
        "          = (n.ssn, n.company, n.salary) " +
        "        WHERE ssn = o.ssn; " +
        "    ELSEIF n.company IS NULL THEN " +
        "      DELETE FROM EMPLOYEES WHERE ssn = o.ssn; " +
        "    ELSE " +
        "      INSERT INTO EMPLOYEES " +
        "        VALUES(n.ssn, n.company, n.salary); " +
        "    END IF; " +
        "  END");

      stmt.close();
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  } // CreatePersonsVTriggers 

  // This method demonstrates how to update a number of tables through a
  // common view and the use of a set of 'INSTEAD OF' triggers 
  public static void MutliTableUpdate(Connection conn)
  {
    try
    {
      System.out.println(
        "\n  -----------------------------------------------------------" +
        "\n  USE THE SQL STATEMENTS:\n" +
        "\n    CREATE TABLE" +
        "\n    CREATE VIEW" +
        "\n    CREATE TRIGGER" +
        "\n    INSERT" +
        "\n    UPDATE" +
        "\n    DELETE" +
        "\n    COMMIT" +
        "\n    ROLLBACK\n");

      System.out.println(
        "  TO UPDATE DATA IN TABLES 'PERSONS' 'STUDENTS' AND 'EMPLOYEES'\n" +
        "  THROUGH A VIEW 'PERSONS_V' USING 'INSTEAD OF' TRIGGERS.\n\n" +
        "  NOTE: THE VIEW IS NEITHER INSERTABLE, UPDATABLE NOR DELETABLE," +
        " SO\n" +
        "  IN ORDER TO PERFORM THESE TABLE OPERATIONS, A FULL SET OF\n" +
        "  'INSTEAD OF' TRIGGERS NEEDS TO BE GENERATED. THE TRIGGERS" +
        " MODIFY\n" +
        "  THE CONTENTS OF EACH TABLE INDIVIDUALLY WHEN AN OPERATION IS\n" +
        "  ATTEMPTED ON THE VIEW");

      System.out.println(
        "\n  CREATE TABLES: 'PERSONS', 'EMPLOYEES' AND 'STUDENTS' AND " +
        "CREATE A\n  VIEW 'PERSONS_V'");

      //  Create the tables PERSONS, STUDENTS, EMPLOYEES, and the view
      //  PERSONS_V 
      CreateTablesAndView(conn);

      // Create the set of INSTEAD OF triggers 
      CreatePersonsVTriggers(conn);

      // Insert values in tables PERSONS, STUDENTS, and EMPLOYEES by
      // inserting the values in the view PERSONS_V. This action will trigger
      // the INSTEAD OF INSERT trigger which will then insert the values in
      // the individual tables
      System.out.println(
        "\n  INSERT VALUES IN THE TABLES 'PERSONS', 'STUDENTS' AND " +
        "'EMPLOYEES'" +
        "\n  THROUGH THE VIEW 'PERSONS_V'\n" +
        "\n  INVOKE THE STATEMENT:");

      System.out.println(
        "\n    INSERT INTO PERSONS_V" +
        "\n      VALUES(123456, 'Smith', NULL, NULL, NULL, NULL), " +
        "\n            (234567, 'Jones', 'Wmart', 20000, NULL, NULL), " +
        "\n            (345678, 'Miller', NULL, NULL, 'Harvard', 'Math'), " +
        "\n            (456789, 'McNuts', 'SelfEmp', 60000, 'UCLA', 'CS')");

      Statement stmt = conn.createStatement();
      stmt.executeUpdate(
        "INSERT INTO PERSONS_V VALUES " +
        "  (123456, 'Smith', NULL, NULL, NULL, NULL), " +
        "  (234567, 'Jones', 'Wmart', 20000, NULL, NULL), " +
        "  (345678, 'Miller', NULL, NULL, 'Harvard', 'Math'), " +
        "  (456789, 'McNuts', 'SelfEmp', 60000, 'UCLA', 'CS') ");

      // Display view content after the insertion of rows
      System.out.println(
        "\n  CONTENTS OF 'PERSONS_V' AFTER THE 'INSERT' STATEMENT");
      PersonsVContentDisplay(conn);

      // Update values in tables PERSONS, STUDENTS, and EMPLOYEES by updating
      // the values in the view PERSONS_V. This action will trigger the
      // INSTEAD OF UPDATE trigger which will then update the values in the
      // individual tables 
      System.out.println(
        "\n  UPDATE THE TABLES 'PERSONS', 'STUDENTS' AND 'EMPLOYEES'" +
        "\n  THROUGH THE VIEW 'PERSONS_V'\n" +
        "\n  INVOKE THE STATEMENTS:");

      System.out.println(
        "\n    UPDATE PERSONS_V" +
        "\n      SET (name, company, salary) =" +
        " ('Johnson', 'Mickburgs', 15000)" +
        "\n      WHERE SSN = 123456\n" +
        "\n    UPDATE PERSONS_V" +
        "\n      SET (company, salary, university) = ('IBM', 70000, NULL)" +
        "\n      WHERE SSN = 345678");

      stmt.executeUpdate(
        "UPDATE PERSONS_V " +
        "  SET (name, company, salary) = ('Johnson', 'Mickburgs', 15000) " +
        "  WHERE SSN = 123456");

      stmt.executeUpdate(
        "UPDATE PERSONS_V SET (company, salary, university) " +
        "                   = ('IBM', 70000, NULL) " +
        "  WHERE SSN = 345678");

      // Display view content after updating 
      System.out.println(
        "\n  CONTENTS OF 'PERSONS_V' AFTER THE 'UPDATE' STATEMENTS");
      PersonsVContentDisplay(conn);

      // Delete rows from tables PERSONS, STUDENTS, and EMPLOYEES by deleting
      // the rows in the view PERSONS_V. This action will trigger the INSTEAD
      // OF DELETE trigger which will then delete rows from the individual
      // tables 
      System.out.println(
        "\n  DELETE ROWS FROM THE TABLES 'PERSONS', 'STUDENTS' AND" +
        " 'EMPLOYEES'" +
        "\n  THROUGH THE VIEW 'PERSONS_V'\n" +
        "\n  INVOKE THE STATEMENT:");
      System.out.println("\n    DELETE FROM PERSONS_V WHERE NAME = 'Jones'");

      stmt.executeUpdate("DELETE FROM PERSONS_V WHERE NAME = 'Jones'");

      // Display view content after deleting rows 
      System.out.println(
        "\n  CONTENTS OF 'PERSONS_V' AFTER THE 'DELETE' STATEMENT");
      PersonsVContentDisplay(conn);

      conn.rollback();

      // Drop the INSTEAD OF triggers 
      System.out.println(
        "\n  DROP TRIGGERS: INSERT_PERSONS_V, DELETE_PERSONS_V, AND " +
        "UPDATE_PERSONS_V");

      stmt.execute("DROP TRIGGER INSERT_PERSONS_V");
      stmt.execute("DROP TRIGGER DELETE_PERSONS_V");
      stmt.execute("DROP TRIGGER UPDATE_PERSONS_V");

      // Drop the tables PERSONS, STUDENTS, EMPLOYEES and the view PERSONS_V 
      System.out.println(
        "  DROP TABLES: PERSONS, STUDENTS, AND EMPLOYEES\n" +
        "  DROP VIEW: PERSONS_V");

      stmt.execute("DROP TABLE PERSONS");
      stmt.execute("DROP VIEW PERSONS_V");
      stmt.execute("DROP TABLE STUDENTS");
      stmt.execute("DROP TABLE EMPLOYEES");

      stmt.close();
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  }

  // This method displays the contents of the 'STAFFV' view 
  private static void PersonsVContentDisplay(Connection conn)
  {
    try
    {
      int ssn = 0;
      String name = null;
      String company = null;
      double salary = 0.0;
      String university = null;
      String major = null;

      System.out.println(
        "\n  SELECT * FROM persons_v ORDER BY ssn\n" +
        "\n    SSN      NAME    COMPANY    SALARY   UNIVERSITY MAJOR" +
        "\n    ------ -------- --------- ---------- ---------- -----");

      // Declare a CURSOR to store the results of the query 
      Statement stmt = conn.createStatement();
      ResultSet rs;
      rs = stmt.executeQuery(
             "SELECT SSN, NAME, COMPANY, SALARY, UNIVERSITY, MAJOR" +
             "  FROM persons_v ORDER BY ssn");
      while (rs.next())
      {
        ssn = rs.getInt(1);
        name = rs.getString(2);
        if (rs.getString(3) != null)
        {
          company = rs.getString(3);
        }
        else
        {
          company = null;
        }
        if (rs.getObject(4) != null)
        {
          salary = rs.getDouble(4);
        }
        else
        {
          salary = 0.0;
        }
        if (rs.getString(5) != null)
        {
          university = rs.getString(5);
        }
        else
        {
          university = null;
        }
        if (rs.getString(6) != null)
        {
          major = rs.getString(6);
        }
        else
        {
          major = null;
        }

        System.out.print("    " + Data.format(ssn,6) +
                         " " + Data.format(name,8));
        if (company != null)
        {
          System.out.print(" " + Data.format(company,9));
        }
        else
        {
          System.out.print("    -     ");
        }
        if (salary != 0.0)
        {
          System.out.print(" " + Data.format(salary,9,2));
        }
        else
        {
          System.out.print("      -    ");
        }
        if (university != null)
        {
          System.out.print(" " + Data.format(university,10));
        }
        else
        {
          System.out.print("      -     ");
        }
        if (major != null)
        {
          System.out.print(" " + Data.format(major,5));
        }
        else
        {
          System.out.print("  -   ");
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
  } // PersonsVContentDisplay 
}
