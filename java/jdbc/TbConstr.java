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
// SOURCE FILE NAME: TbConstr.java
//
// SAMPLE: How to create, use and drop constraints
//
// SQL Statements USED:
//         CREATE TABLE
//         DROP TABLE
//         DELETE
//         COMMIT
//         ROLLBACK
//         INSERT
//         ALTER
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
// OUTPUT FILE: TbConstr.out (available in the online documentation)
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

class TbConstr
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO CREATE, USE AND DROP CONSTRAINTS.\n");

      // connect to the 'sample' database
      db.connect();

      demo_NOT_NULL(db.con);
      demo_UNIQUE(db.con);
      demo_PRIMARY_KEY(db.con);
      demo_CHECK(db.con);
      demo_CHECK_INFO(db.con);
      demo_WITH_DEFAULT(db.con);

      System.out.println();
      System.out.println(
      "----------------------------------------------------------\n" +
        "#####################################################\n" +
        "#    Create tables for FOREIGN KEY sample functions #\n" +
        "#####################################################");

      FK_TwoTablesCreate(db.con);

      demo_FK_OnInsertShow(db.con);
      demo_FK_ON_UPDATE_NO_ACTION(db.con);
      demo_FK_ON_UPDATE_RESTRICT(db.con);
      demo_FK_ON_DELETE_CASCADE(db.con);
      demo_FK_ON_DELETE_SET_NULL(db.con);
      demo_FK_ON_DELETE_NO_ACTION(db.con);

      System.out.println();
      System.out.println(
      "----------------------------------------------------------\n" +
        "########################################################\n" +
        "# Drop tables created for FOREIGN KEY sample functions #\n" +
        "########################################################");
      FK_TwoTablesDrop(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // helping function: This function creates two foreign keys
  static void FK_TwoTablesCreate(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE deptmt(deptno CHAR(3) NOT NULL,\n" +
        "                    deptname VARCHAR(20),\n" +
        "                    CONSTRAINT pk_dept\n" +
        "                    PRIMARY KEY(deptno))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE deptmt(deptno CHAR(3) NOT NULL, " +
        "                  deptname VARCHAR(20), " +
        "                  CONSTRAINT pk_dept " +
        "                  PRIMARY KEY(deptno))");
      stmt.close();

      System.out.println();
      System.out.println(
        "  INSERT INTO deptmt VALUES('A00', 'ADMINISTRATION'),\n" +
        "                         ('B00', 'DEVELOPMENT'),\n" +
        "                         ('C00', 'SUPPORT')");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO deptmt VALUES('A00', 'ADMINISTRATION'), " +
        "                       ('B00', 'DEVELOPMENT'), " +
        "                       ('C00', 'SUPPORT') ");
      stmt1.close();

      System.out.println();
      System.out.println(
        "  CREATE TABLE empl(empno CHAR(4),\n" +
        "                   empname VARCHAR(10),\n" +
        "                   dept_no CHAR(3))");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("CREATE TABLE empl(empno CHAR(4), " +
                          "                 empname VARCHAR(10), " +
                          "                 dept_no CHAR(3))");
      stmt2.close();

      System.out.println();
      System.out.println(
        "  INSERT INTO empl VALUES('0010', 'Smith', 'A00'),\n" +
        "                        ('0020', 'Ngan', 'B00'),\n" +
        "                        ('0030', 'Lu', 'B00'),\n" +
        "                        ('0040', 'Wheeler', 'B00'),\n" +
        "                        ('0050', 'Burke', 'C00'),\n" +
        "                        ('0060', 'Edwards', 'C00'),\n" +
        "                        ('0070', 'Lea', 'C00')");

      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate(
        "INSERT INTO empl VALUES('0010', 'Smith', 'A00'), " +
        "                      ('0020', 'Ngan', 'B00'), " +
        "                      ('0030', 'Lu', 'B00'), " +
        "                      ('0040', 'Wheeler', 'B00'), " +
        "                      ('0050', 'Burke', 'C00'), " +
        "                      ('0060', 'Edwards', 'C00'), " +
        "                      ('0070', 'Lea', 'C00')  ");
      stmt3.close();

      System.out.println("\n  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // FK_TwoTablesCreate

  // helping function
  static void FK_TwoTablesDisplay(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  SELECT * FROM deptmt");
      System.out.println("    DEPTNO  DEPTNAME\n" +
                         "    ------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM deptmt");

      while (rs.next())
      {
        System.out.println("    " +
                           Data.format(rs.getString("deptno"),7) + " " +
                           Data.format(rs.getString("deptname"),20));
      }
      rs.close();
      stmt.close();

      System.out.println();
      System.out.println("  SELECT * FROM empl");
      System.out.println("    EMPNO EMPNAME    DEPT_NO\n" +
                         "    ----- ---------- -------");

      Statement stmt1 = con.createStatement();
      ResultSet rs1 = stmt1.executeQuery("SELECT * FROM empl");

      while (rs1.next())
      {
        System.out.print("    " +
                          Data.format(rs1.getString("empno"),5) + " " +
                          Data.format(rs1.getString("empname"),10));
        String deptNo = rs1.getString("dept_no");
        if (deptNo !=null)
        {
          System.out.print(" " + Data.format(deptNo,3));
        }
        else
        {
          System.out.print(" -");
        }
        System.out.println();
      }
      rs1.close();
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // FK_TwoTablesDisplay

  // helping function
  static void FK_TwoTablesDrop(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE deptmt");
      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE deptmt");
      stmt.close();

      System.out.println();
      System.out.println("  DROP TABLE empl");
      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("DROP TABLE empl");
      stmt1.close();

      System.out.println("\n  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // FK_TwoTablesDrop


  // helping function
  static void FK_Create(String ruleClause, Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  ALTER TABLE empl\n" +
                         "    ADD CONSTRAINT fk_dept\n" +
                         "    FOREIGN KEY(dept_no)\n" +
                         "    REFERENCES deptmt(deptno)\n" +
                         "    " + ruleClause);

      Statement stmt = con.createStatement();
      stmt.executeUpdate("ALTER TABLE empl " +
                         "  ADD CONSTRAINT fk_dept " +
                         "  FOREIGN KEY(dept_no) " +
                         "  REFERENCES deptmt(deptno) " +
                         ruleClause);
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
  } // FK_Create


  // helping function
  static void FK_Drop(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("  ALTER TABLE empl DROP CONSTRAINT fk_dept");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("ALTER TABLE empl DROP CONSTRAINT fk_dept");
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
  } // FK_Drop

  // This function demonstrates how to use a 'NOT NULL' constraint.
  static void demo_NOT_NULL(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TABLE\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  DROP TABLE\n" +
      "TO SHOW A 'NOT NULL' CONSTRAINT.");

    // Create a table called empl_sal with a 'NOT NULL' constraint
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL,\n" +
        "                       firstname VARCHAR(10),\n" +
        "                       salary DECIMAL(7, 2))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL, " +
        "                     firstname VARCHAR(10), " +
        "                     salary DECIMAL(7, 2))");
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

    // Insert a row in the table empl_sal with NULL as the lastname.
    // This insert will fail with an expected error.
    try
    {
      String strStmt;
      System.out.println();
      System.out.println(
        "  INSERT INTO empl_sal VALUES(NULL, 'PHILIP', 17000.00)");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO empl_sal VALUES(NULL, 'PHILIP', 17000.00) ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // drop the table empl_sal
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE empl_sal");
      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP TABLE empl_sal");
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demo_NOT_NULL

  // This function demonstrates how to use a 'UNIQUE' constraint.
  static void demo_UNIQUE(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TABLE\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  ALTER TABLE\n" +
      "  DROP TABLE\n" +
      "TO SHOW A 'UNIQUE' CONSTRAINT.");

    // Create a table called empl_sal with a 'UNIQUE' constraint
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL,\n" +
        "                       firstname VARCHAR(10) NOT NULL,\n" +
        "                       salary DECIMAL(7, 2),\n" +
        "                       CONSTRAINT unique_cn\n" +
        "                       UNIQUE(lastname, firstname))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL, " +
        "                     firstname VARCHAR(10) NOT NULL, " +
        "                     salary DECIMAL(7, 2), " +
        "                     CONSTRAINT unique_cn " +
        "                     UNIQUE(lastname, firstname))");
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

    // Insert two rows into the table empl_sal that have the same lastname
    // and firstname values. The insert will fail with an expected error
    // because the rows violate the PRIMARY KEY constraint.
    try
    {
      System.out.println();
      System.out.println(
        "  INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00),\n" +
        "                            ('SMITH', 'PHILIP', 21000.00)");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00), " +
        "                          ('SMITH', 'PHILIP', 21000.00)  ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // drop the 'UNIQUE' constraint on the table empl_sal
    try
    {
      System.out.println();
      System.out.println(
        "  ALTER TABLE empl_sal DROP CONSTRAINT unique_cn");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "ALTER TABLE empl_sal DROP CONSTRAINT unique_cn ");
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the table empl_sal
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE empl_sal");
      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate("DROP TABLE empl_sal");
      stmt3.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demo_UNIQUE

  // This function demonstrates how to use a 'PRIMARY KEY' constraint.
  static void demo_PRIMARY_KEY(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TABLE\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  ALTER TABLE\n" +
      "  DROP TABLE\n" +
      "TO SHOW A 'PRIMARY KEY' CONSTRAINT.");

    // Create a table called empl_sal with a 'PRIMARY KEY' constraint
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL,\n" +
        "                       firstname VARCHAR(10) NOT NULL,\n" +
        "                       salary DECIMAL(7, 2),\n" +
        "                       CONSTRAINT pk_cn\n" +
        "                       PRIMARY KEY(lastname, firstname))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE empl_sal(lastname VARCHAR(10) NOT NULL, " +
        "                     firstname VARCHAR(10) NOT NULL, " +
        "                     salary DECIMAL(7, 2), " +
        "                     CONSTRAINT pk_cn " +
        "                     PRIMARY KEY(lastname, firstname))");
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

    // Insert two rows into the table empl_sal that have the same lastname
    // and firstname values. The insert will fail with an expected error
    // because the rows violate the PRIMARY KEY constraint.
    try
    {
      System.out.println();
      System.out.println(
        "  INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00),\n" +
        "                            ('SMITH', 'PHILIP', 21000.00)");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 17000.00)," +
        "                          ('SMITH', 'PHILIP', 21000.00) ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // drop the 'PRIMARY KEY' constraint on the table empl_sal
    try
    {
      System.out.println();
      System.out.println("  ALTER TABLE empl_sal DROP CONSTRAINT pk_cn");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("ALTER TABLE empl_sal DROP CONSTRAINT pk_cn");
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the table empl_sal
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE empl_sal");

      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate("DROP TABLE empl_sal");
      stmt3.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demo_PRIMARY_KEY

  // This function demonstrates how to use a 'CHECK' constraint.
  static void demo_CHECK(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TABLE\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  ALTER TABLE\n" +
      "  DROP TABLE\n" +
      "TO SHOW A 'CHECK' CONSTRAINT.");

    // Create a table called empl_sal with a 'CHECK' constraint
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE empl_sal(lastname VARCHAR(10),\n" +
        "                       firstname VARCHAR(10),\n" +
        "                       salary DECIMAL(7, 2),\n" +
        "                       CONSTRAINT check_cn\n" +
        "                       CHECK(salary < 25000.00))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE empl_sal(lastname VARCHAR(10), " +
        "                     firstname VARCHAR(10), " +
        "                     salary DECIMAL(7, 2), " +
        "                     CONSTRAINT check_cn " +
        "                     CHECK(salary < 25000.00))");
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

    // Insert a row in the table empl_sal that violates the rule defined
    // in the 'CHECK' constraint. This insert will fail with an expected
    // error.
    try
    {
      System.out.println();
      System.out.println(
        "  INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 27000.00)");

      Statement stmt1 = con.createStatement();
      stmt1.execute(
        "INSERT INTO empl_sal VALUES('SMITH', 'PHILIP', 27000.00)");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // drop the 'CHECK' constraint on the table empl_sal
    try
    {
      System.out.println();
      System.out.println("  ALTER TABLE empl_sal DROP CONSTRAINT check_cn");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "ALTER TABLE empl_sal DROP CONSTRAINT check_cn");
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the table empl_sal
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE empl_sal");
      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate("DROP TABLE empl_sal");
      stmt3.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demo_CHECK

  // This function demonstrates how to use an 'INFORMATIONAL' constraint.
  static void demo_CHECK_INFO(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
      
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  CREATE TABLE\n" +
        "  COMMIT\n" +
        "  INSERT\n" +
        "  ALTER TABLE\n" +
        "  DROP TABLE\n" +
        "TO SHOW AN 'INFORMATIONAL' CONSTRAINT.");

      // create a table called empl with a 'CHECK' constraint
      System.out.println(
        "\n  CREATE TABLE empl(empno INTEGER NOT NULL PRIMARY KEY,\n" +
        "                   name VARCHAR(10),\n" +
        "                   firstname VARCHAR(20),\n" +
        "                   salary INTEGER CONSTRAINT minsalary\n" +
        "                          CHECK (salary >= 25000)\n" +
        "                          NOT ENFORCED\n" +
        "                          ENABLE QUERY OPTIMIZATION)\n");
      stmt.executeUpdate(
        "CREATE TABLE empl(empno INTEGER NOT NULL PRIMARY KEY," +
        "                   name VARCHAR(10)," +
        "                   firstname VARCHAR(20)," +
        "                   salary INTEGER CONSTRAINT minsalary" +
        "                          CHECK (salary >= 25000)" +
        "                          NOT ENFORCED" +
        "                          ENABLE QUERY OPTIMIZATION)");

      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
    
    try
    {
      // insert data that doesn't satisfy the constraint 'minsalary'. 
      // database manager does not enforce the constraint for IUD operations 
      System.out.println(
        "\n\nTO SHOW NOT ENFORCED OPTION\n" +
        "\n  INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)\n");
            
      stmt.executeUpdate(
        "INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
    
    try
    {
      // alter the constraint to make it ENFORCED by database manager
      System.out.println(
        "Alter the constraint to make it ENFORCED by database manager\n" +
        "\n  ALTER TABLE empl ALTER CHECK minsalary ENFORCED");
      
      stmt.executeUpdate(
        "ALTER TABLE empl ALTER CHECK minsalary ENFORCED");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }
    
    try
    {
      // delete entries from EMP Table
      System.out.println("\n  DELETE FROM empl");
      
      stmt.executeUpdate("DELETE FROM empl");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
    
    try
    {
      // alter the constraint to make it ENFORCED by database manager
      System.out.println(
        "\n\nTO SHOW ENFORCED OPTION\n" +
        "\n  ALTER TABLE empl ALTER CHECK minsalary ENFORCED\n ");
      
      stmt.executeUpdate("ALTER TABLE empl ALTER CHECK minsalary ENFORCED");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);                    
      jdbcExc.handle();
    }
    
    try
    {
      // insert table with data not conforming to the constraint 'minsalary'
      // database manager enforces the constraint for IUD operations
      System.out.println(
        "  INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)");
      
      stmt.executeUpdate(
        "INSERT INTO empl VALUES(1, 'SMITH', 'PHILIP', 1000)");
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }
    
    try
    {
      // drop table
      System.out.println("\n  DROP TABLE empl");
      
      stmt.executeUpdate("DROP TABLE empl");
      con.commit();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demo_CHECK_INFO

  // This function demonstrates how to use a 'WITH DEFAULT' constraint.
  static void demo_WITH_DEFAULT(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  CREATE TABLE\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  DROP TABLE\n" +
      "TO SHOW A 'WITH DEFAULT' CONSTRAINT.");

    // Create a table called empl_sal with a 'WITH DEFAULT' constraint
    try
    {
      System.out.println();
      System.out.println(
        "  CREATE TABLE empl_sal(lastname VARCHAR(10),\n" +
        "                       firstname VARCHAR(10),\n" +
        "                       salary DECIMAL(7, 2) " +
        "WITH DEFAULT 17000.00)");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE empl_sal(lastname VARCHAR(10), " +
        "                     firstname VARCHAR(10), " +
        "                     salary DECIMAL(7, 2) WITH DEFAULT 17000.00)");
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

    // Insert three rows into the table empl_sal, without any value for the
    // the third column. Since the third column is defined with a default
    // value of 17000.00, the third column for each of these three rows
    // will be set to 17000.00.
    try
    {
      String strStmt;
      System.out.println();
      System.out.println("  INSERT INTO empl_sal(lastname, firstname)\n" +
                         "    VALUES('SMITH', 'PHILIP'),\n" +
                         "          ('PARKER', 'JOHN'),\n" +
                         "          ('PEREZ', 'MARIA')");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("INSERT INTO empl_sal(lastname, firstname) " +
                          "  VALUES('SMITH' , 'PHILIP'), " +
                          "        ('PARKER', 'JOHN'), " +
                          "        ('PEREZ' , 'MARIA') ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // retrieve and display the data in the table empl_sal
    try
    {
      String strStmt;
      System.out.println();
      System.out.println("  SELECT * FROM empl_sal");
      System.out.println("    FIRSTNAME  LASTNAME   SALARY\n" +
                         "    ---------- ---------- --------");

      Statement stmt2 = con.createStatement();
      ResultSet rs = stmt2.executeQuery("SELECT * FROM empl_sal");

      while (rs.next())
      {
        System.out.println("    " +
          Data.format(rs.getString("firstname"),10) + " " +
          Data.format(rs.getString("lastname"),10) + " " +
          Data.format(rs.getDouble("salary"),7,2));
      }
      rs.close();
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // drop the table empl_sal
    try
    {
      System.out.println();
      System.out.println("  DROP TABLE empl_sal");
      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate("DROP TABLE empl_sal");
      stmt3.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demo_WITH_DEFAULT

  // This function demonstrates how to insert into a foreign key
  static void demo_FK_OnInsertShow(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  ALTER TABLE\n" +
      "  COMMIT\n" +
      "  INSERT\n" +
      "  ROLLBACK\n" +
      "TO SHOW HOW A FOREIGN KEY WORKS ON INSERT.");

    // display the initial content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // create a foreign key on the 'empl' table that reference the 'deptmt'
    // table
    FK_Create("", con);

    // insert an entry into the parent table, 'deptmt'
    try
    {
      System.out.println();
      System.out.println("  INSERT INTO deptmt VALUES('D00', 'SALES')");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("INSERT INTO deptmt VALUES('D00', 'SALES')");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // insert an entry into the child table, 'empl'
    try
    {
      System.out.println();
      System.out.println(
        "  INSERT INTO empl VALUES('0080', 'Pearce', 'E03')");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO empl VALUES('0080', 'Pearce', 'E03')");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // display the final content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // roll back the transaction
    try
    {
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

    // drop the foreign key
    FK_Drop(con);
  } // demo_FK_OnInsertShow

  // This function demonstrates how to use an 'ON UPDATE NO ACTION'
  // foreign key
  static void demo_FK_ON_UPDATE_NO_ACTION(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  ALTER TABLE\n" +
      "  COMMIT\n" +
      "  UPDATE\n" +
      "  ROLLBACK\n" +
      "TO SHOW AN 'ON UPDATE NO ACTION' FOREIGN KEY.");

    // display the initial content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // create an 'ON UPDATE NO ACTION' foreign key
    FK_Create("ON UPDATE NO ACTION", con);

    // update parent table
    try
    {
      System.out.println();
      System.out.println(
        "  UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00'");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00' ");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // update the parent table, 'deptmt'
    try
    {
      System.out.println();
      System.out.println(
        "  UPDATE deptmt\n" +
        "    SET deptno = CASE\n" +
        "                   WHEN deptno = 'A00' THEN 'B00'\n" +
        "                   WHEN deptno = 'B00' THEN 'A00'\n" +
        "                 END\n" +
        "    WHERE deptno = 'A00' OR deptno = 'B00'");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "UPDATE deptmt " +
        "  SET deptno = CASE " +
        "                 WHEN deptno = 'A00' THEN 'B00' " +
        "                 WHEN deptno = 'B00' THEN 'A00' " +
        "               END " +
        "  WHERE deptno = 'A00' OR deptno = 'B00' ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // update the child table, 'empl'
    try
    {
      System.out.println();
      System.out.println(
        "  UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler'");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler' ");
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // display the final content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // roll back the transaction
    try
    {
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

    // drop the foreign key
    FK_Drop(con);
  } // demo_FK_ON_UPDATE_NO_ACTION

  // This function demonstrates how to use an 'ON UPDATE RESTRICT'
  // foreign key
  static void demo_FK_ON_UPDATE_RESTRICT(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  ALTER TABLE\n" +
      "  COMMIT\n" +
      "  UPDATE\n" +
      "  ROLLBACK\n" +
      "TO SHOW AN 'ON UPDATE RESTRICT' FOREIGN KEY.");

    // display the initial content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // create an 'ON UPDATE RESTRICT' foreign key
    FK_Create("ON UPDATE RESTRICT", con);

    // update the parent table, 'deptmt', with data that violates the 'ON
    // UPDATE RESTRICT' foreign key. An error is expected to be returned.
    try
    {
      System.out.println();
      System.out.println(
        "  UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00'");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "UPDATE deptmt SET deptno = 'E01' WHERE deptno = 'A00' ");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // update the parent table, 'deptmt', with data that violates the 'ON
    // UPDATE RESTRICT' foreign key. An error is expected to be returned.
    try
    {
      System.out.println();
      System.out.println(
        "  UPDATE deptmt\n" +
        "    SET deptno = CASE\n" +
        "                   WHEN deptno = 'A00' THEN 'B00'\n" +
        "                   WHEN deptno = 'B00' THEN 'A00'\n" +
        "                 END\n" +
        "    WHERE deptno = 'A00' OR deptno = 'B00'");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "UPDATE deptmt " +
        "  SET deptno = CASE " +
        "                 WHEN deptno = 'A00' THEN 'B00' " +
        "                 WHEN deptno = 'B00' THEN 'A00' " +
        "               END " +
        "  WHERE deptno = 'A00' OR deptno = 'B00' ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // update the child table, 'empl', with data that violates the 'ON
    // UPDATE RESTRICT' foreign key. An error is expected to be returned.
    try
    {
      System.out.println();
      System.out.println(
        "  UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler'");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "UPDATE empl SET dept_no = 'G11' WHERE empname = 'Wheeler' ");
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // display the final content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // roll back the transaction
    try
    {
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

    // drop the foreign key
    FK_Drop(con);

  } // demo_FK_ON_UPDATE_RESTRICT

  // This function demonstrates how to use an 'ON DELETE CASCADE' foreign key
  static void demo_FK_ON_DELETE_CASCADE(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  ALTER TABLE\n" +
      "  COMMIT\n" +
      "  DELETE\n" +
      "  ROLLBACK\n" +
      "TO SHOW AN 'ON DELETE CASCADE' FOREIGN KEY.");

    // display the initial content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // create an 'ON DELETE CASCADE' foreign key
    FK_Create("ON DELETE CASCADE", con);

    // delete from the parent table, 'deptmt'
    try
    {
      System.out.println();
      System.out.println("  DELETE FROM deptmt WHERE deptno = 'C00'");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DELETE FROM deptmt WHERE deptno = 'C00' ");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // delete from the child table, 'empl'
    try
    {
      System.out.println();
      System.out.println("  DELETE FROM empl WHERE empname = 'Wheeler'");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DELETE FROM empl WHERE empname = 'Wheeler' ");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the final content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // roll back the transaction
    try
    {
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

    // drop the foreign key
    FK_Drop(con);

  } // demo_FK_ON_DELETE_CASCADE

  // This function demonstrates how to use an 'ON DELETE SET NULL'
  // foreign key
  static void demo_FK_ON_DELETE_SET_NULL(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  ALTER TABLE\n" +
      "  COMMIT\n" +
      "  DELETE\n" +
      "  ROLLBACK\n" +
      "TO SHOW AN 'ON DELETE SET NULL' FOREIGN KEY.");

    // display the initial content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // create an 'ON DELETE SET NULL' foreign key
    FK_Create("ON DELETE SET NULL", con);

    // delete from the parent table, 'deptmt'
    try
    {
      System.out.println();
      System.out.println("  DELETE FROM deptmt WHERE deptno = 'C00'");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DELETE FROM deptmt WHERE deptno = 'C00' ");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // delete from the child table, 'empl'
    try
    {
      System.out.println();
      System.out.println("  DELETE FROM empl WHERE empname = 'Wheeler'");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("DELETE FROM empl WHERE empname = 'Wheeler' ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the final content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // roll back the transaction
    try
    {
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

    // drop the foreign key
    FK_Drop(con);

  } // demo_FK_ON_DELETE_SET_NULL

  // This function demonstrates how to use an 'ON DELETE NO ACTION'
  // foreign key
  static void demo_FK_ON_DELETE_NO_ACTION(Connection con)
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  ALTER TABLE\n" +
      "  COMMIT\n" +
      "  DELETE\n" +
      "  ROLLBACK\n" +
      "TO SHOW AN 'ON DELETE NO ACTION' FOREIGN KEY.");

    // display the initial content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // create an 'ON DELETE NO ACTION' foreign key
    FK_Create("ON DELETE NO ACTION", con);

    // delete from the parent table, 'deptmt'
    try
    {
      System.out.println();
      System.out.println("  DELETE FROM deptmt WHERE deptno = 'C00'");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("DELETE FROM deptmt WHERE deptno = 'C00' ");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }

    // delete from the child table, 'empl'
    try
    {
      System.out.println();
      System.out.println("  DELETE FROM empl WHERE empname = 'Wheeler'");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("DELETE FROM empl WHERE empname = 'Wheeler' ");
      stmt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the final content of the 'deptmt' and 'empl' table
    FK_TwoTablesDisplay(con);

    // roll back the transaction
    try
    {
      System.out.println();
      System.out.println("  ROLLBACK");
      con.rollback();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

    // drop the foreign key
    FK_Drop(con);
  } // demo_FK_ON_DELETE_NO_ACTION
} // TbConstr

