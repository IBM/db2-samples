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
// SOURCE FILE NAME: TbRead.java
//
// SAMPLE: How to read table data
//
// SQL Statements USED:
//         SELECT
//
// JAVA 2 CLASSES USED:
//         Statement
//         PreparedStatement
//         ResultSet
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
// OUTPUT FILE: TbRead.out (available in the online documentation)
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

class TbRead
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO READ TABLE DATA.");

      // connect to the 'sample' database
      db.connect();

      // different ways to read table data
      execQuery(db.con);
      execPreparedQuery(db.con);
      execPreparedQueryWithParam(db.con);
      execPreparedQueryWithUnknownOutputColumn(db.con);

      mostSimpleSubselect(db.con);
      basicSubselect(db.con);
      groupBySubselect(db.con);
      subselect(db.con);
      rowSubselect(db.con);
      fullselect(db.con);
      selectStatement(db.con);

      basicSubselectFromMultipleTables(db.con);
      basicSubselectFromJoinedTable(db.con);
      basicSubselectUsingSubquery(db.con);
      basicSubselectUsingCorrelatedSubquery(db.con);

      subselectUsingGroupingSets(db.con);
      subselectUsingRollup(db.con);
      subselectUsingCube(db.con);
      selectUsingQuerySampling(db.con);

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
  static void OrgTbContentDisplay(Connection con)
  {
    try
    {
      int deptnumb = 0;
      String deptname = "";
      int manager = 0;
      String division = "";
      String location = "";

      System.out.println();
      System.out.println("  SELECT * FROM org");
      System.out.println(
        "    DEPTNUMB DEPTNAME       MANAGER DIVISION   LOCATION\n" +
        "    -------- -------------- ------- ---------- --------------");

      Statement stmt = con.createStatement();
      // perform a SELECT against the "org" table in the sample database.
      ResultSet rs = stmt.executeQuery("SELECT * FROM org");

      // retrieve and display the result from the SELECT statement
      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        deptname = rs.getString(2);
        manager = rs.getInt(3);
        division = rs.getString(4);
        location = rs.getString(5);

        System.out.println(
          "    " +
          Data.format(deptnumb, 8)  + " " +
          Data.format(deptname, 14) + " " +
          Data.format(manager, 7)   + " " +
          Data.format(division, 10) + " " +
          Data.format(location, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // OrgTableContentDisplay

  // helping function
  static void DepartmentTbContentDisplay(Connection con)
  {
    try
    {
      String deptno = "";
      String departmentDeptname = "";
      String mgrno = "";
      String admrdept = "";
      String departmentLocation = "";

      System.out.println();
      System.out.println(
        "  SELECT * FROM department");
      System.out.println(
        "    DEPTNO DEPTNAME                     MGRNO  ADMRDEPT LOCATION");
      System.out.println(
        "    ------ ---------------------------- ------ -------- --------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM department");

      while (rs.next())
      {
        deptno = rs.getString(1);
        departmentDeptname = rs.getString(2);
        mgrno = rs.getString(3);
        admrdept = rs.getString(4);
        departmentLocation = rs.getString(5);

        System.out.print("    " +
                         Data.format(deptno, 6) + " " +
                         Data.format(departmentDeptname, 28));

        if (mgrno != null)
        {
          System.out.print(" " + Data.format(mgrno, 6));
        }
        else
        {
          System.out.print(" -     ");
        }
        System.out.print(" " + Data.format(admrdept,8));
        if (departmentLocation != null)
        {
          System.out.print(" " +
                           Data.format(departmentLocation, 16));
        }
        else
        {
          System.out.print(" -     ");
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
  } // DepartmentTbContentDisplay

  // helping function
  static void EmployeeTbPartialContentDisplay(Connection con)
  {
    try
    {
      String job = "";
      int edlevel = 0;
      double comm = 0.0;

      System.out.println();
      System.out.println("  Perform:\n" +
                         "    SELECT job, edlevel, comm\n" +
                         "      FROM employee\n" +
                         "      WHERE job IN('DESIGNER', 'FIELDREP')\n" +
                         "\n" +
                         "  Results:\n" +
                         "    JOB      EDLEVEL COMM\n" +
                         "    -------- ------- -----------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT job, edlevel, comm " +
        "  FROM employee " +
        "  WHERE job IN('DESIGNER', 'FIELDREP')");

      while (rs.next())
      {
        job = rs.getString(1);
        edlevel = rs.getInt(2);
        comm = rs.getDouble(3);

        System.out.println("    " +
                           Data.format(job, 8) + " " +
                           Data.format(edlevel, 7) + " " +
                           Data.format(comm, 10, 2));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // EmployeeTbPartialContentDisplay

  static void execQuery(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE JAVA 2 CLASS:\n" +
        "  Statement\n" +
        "TO EXECUTE A QUERY.");

      Statement stmt = con.createStatement();

      // execute the query
      System.out.println();
      System.out.println(
        "  Execute Statement:\n" +
        "    SELECT deptnumb, location FROM org WHERE deptnumb < 25");

      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, location FROM org WHERE deptnumb < 25 ");

      System.out.println();
      System.out.println("  Results:\n" +
                         "    DEPTNUMB LOCATION\n" +
                         "    -------- --------------");

      int deptnumb = 0;
      String location = "";
      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        location = rs.getString(2);

        System.out.println("    " +
                           Data.format(deptnumb, 8) + " " +
                           Data.format(location, 14));
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

  static void execPreparedQuery(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE JAVA 2 CLASS:\n" +
        "  PreparedStatement\n" +
        "TO EXECUTE A PREPARED QUERY.");

      Statement stmt = con.createStatement();

      // prepare the query
      System.out.println();
      System.out.println(
        "  Prepare Statement:\n" +
        "    SELECT deptnumb, location FROM org WHERE deptnumb < 25");

      PreparedStatement pstmt = con.prepareStatement(
        "SELECT deptnumb, location FROM org WHERE deptnumb < 25 ");

      System.out.println();
      System.out.println("  Execute prepared statement");
      ResultSet rs = pstmt.executeQuery();

      System.out.println();
      System.out.println("  Results:\n" +
                         "    DEPTNUMB LOCATION\n" +
                         "    -------- --------------");

      int deptnumb = 0;
      String location = "";
      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        location = rs.getString(2);

        System.out.println("    " +
                           Data.format(deptnumb, 8) + " " +
                           Data.format(location, 14));
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

  static void execPreparedQueryWithParam(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE JAVA 2 CLASS:\n" +
        "  PreparedStatement\n" +
        "TO EXECUTE A PREPARED QUERY WITH PARAMETERS.");

      Statement stmt = con.createStatement();

      // prepare the query
      System.out.println();
      System.out.println(
        "  Prepare Statement:\n" +
        "    SELECT deptnumb, location FROM org WHERE deptnumb < ?");

      PreparedStatement pstmt = con.prepareStatement(
        "SELECT deptnumb, location FROM org WHERE deptnumb < ?");

      System.out.println();
      System.out.println("  Set parameter value: parameter 1 = 25");

      pstmt.setInt(1, 25);

      System.out.println();
      System.out.println("  Execute prepared statement");
      ResultSet rs = pstmt.executeQuery();

      System.out.println();
      System.out.println("  Results:\n" +
                         "    DEPTNUMB LOCATION\n" +
                         "    -------- --------------");

      int deptnumb = 0;
      String location = "";
      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        location = rs.getString(2);

        System.out.println(
          "    " +
          Data.format(deptnumb, 8) + " " +
          Data.format(location, 14));
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

  static void execPreparedQueryWithUnknownOutputColumn(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE JAVA 2 CLASS:\n" +
        "  PreparedStatement\n" +
        "TO EXECUTE A PREPARED QUERY WITH UNKNOWN OUTPUT COLUMNS.");

      Statement stmt = con.createStatement();

      // prepare the query
      System.out.println();
      System.out.println("  Prepare Statement:\n" +
                         "    SELECT * FROM org WHERE deptnumb < 25");

      PreparedStatement pstmt = con.prepareStatement(
        "SELECT * FROM org WHERE deptnumb < 25");

      System.out.println();
      System.out.println("  Execute prepared statement");
      ResultSet rs = pstmt.executeQuery();

      ResultSetMetaData rsms = rs.getMetaData();
      int colCount = rsms.getColumnCount();
      int[] colSize = new int[colCount];
      String[] colLabel = new String[colCount];
      String[] colTypeName = new String[colCount];

      for (int i = 0 ; i < colCount ; i++)
      {
        colSize[i] = rsms.getColumnDisplaySize(i+1);
        colLabel[i] = rsms.getColumnLabel(i+1);
        colTypeName[i] = rsms.getColumnTypeName(i+1);
      }

      System.out.println();
      System.out.print("  Results:\n" +
                       "    ");

      // print the columns' name
      for (int i = 0 ; i < colCount ; i++)
      {
        System.out.print(colLabel[i] + " ");
        int spaceCounter = colLabel[i].length();
        while (spaceCounter < colSize[i])
        {
          System.out.print(" ");
          spaceCounter++;
        }
      }
      System.out.println();

      // print the line under each column's name
      int[] actualColSize = new int[colCount];
      System.out.print("    ");
      for (int i = 0 ; i < colCount ; i++)
      {
        int dashCounter = 0;
        while (dashCounter < colSize[i] ||
               dashCounter < colLabel[i].length())
        {
          System.out.print("-");
          dashCounter++;
        }
        actualColSize[i] = dashCounter;
        System.out.print(" ");
      }
      System.out.println();

      // print the result set
      while (rs.next())
      {
        System.out.print("    ");

        for (int i = 0 ; i < colCount ; i++)
        {
          // check the TYPE of the column to retrieve the value of
          // each column
          if (colTypeName[i].equals("SMALLINT"))
          {
            System.out.print(
              Data.format(rs.getInt(i+1), actualColSize[i]));
          }
          else if (colTypeName[i].equals("VARCHAR"))
          {
            System.out.print(Data.format(rs.getString(i+1),
                                         actualColSize[i]));
          }
          else if (colTypeName[i].equals("INTEGER"))
          {
            Integer tempInteger = new Integer(0);
            tempInteger = Integer.valueOf(rs.getString(i+1));
            System.out.print(
              Data.format(tempInteger, actualColSize[i]));
          }
          else if (colTypeName[i].equals("DOUBLE"))
          {
            Double tempDouble = new Double(0.0);
            tempDouble = Double.valueOf(
                           Double.toString(rs.getDouble(i+1)));
            System.out.print(
              Data.format(tempDouble, actualColSize[i], 2));
          }
          else
          {
            System.out.println("Error: " +
                               "Cannot read the column's type");
          }
          System.out.print(" ");
        }
        System.out.println();
      } // end while

      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  }

  static void mostSimpleSubselect(Connection con)
  {
    try
    {
      int deptnumb = 0;
      String deptname = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SIMPLE SUBSELECT.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println("  Perform:\n" +
                         "    SELECT deptnumb, deptname FROM org\n" +
                         "\n" +
                         "  Results:\n" +
                         "    DEPTNUMB DEPTNAME\n" +
                         "    -------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, deptname FROM org");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        deptname = rs.getString(2);

        System.out.println("    " +
                           Data.format(deptnumb, 8) + " " +
                           Data.format(deptname, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // mostSimpleSubselect

  static void basicSubselect(Connection con)
  {
    try
    {
      int deptnumb = 0;
      String deptname = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT USING A WHERE CLAUSE.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT deptnumb, deptname FROM org WHERE deptnumb < 30\n" +
        "\n" +
        "  Results:\n" +
        "    DEPTNUMB DEPTNAME\n" +
        "    -------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, deptname FROM org WHERE deptnumb < 30");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        deptname = rs.getString(2);

        System.out.println("    " +
                           Data.format(deptnumb, 8) + " " +
                           Data.format(deptname, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // basicSubselect

  static void groupBySubselect(Connection con)
  {
    try
    {
      String division = "";
      int maxDeptnumb = 0;

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A 'GROUP BY' SUBSELECT.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT division, MAX(deptnumb) FROM org GROUP BY division\n" +
        "\n" +
        "  Results:\n" +
        "    DIVISION   MAX(DEPTNUMB)\n" +
        "    ---------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT division, MAX(deptnumb) FROM org GROUP BY division");

      while (rs.next())
      {
        division = rs.getString(1);
        maxDeptnumb = rs.getInt(2);

        System.out.println("    " +
                           Data.format(division, 10) + " " +
                           Data.format(maxDeptnumb, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // groupBySubselect

  static void subselect(Connection con)
  {
    try
    {
      int maxDeptnumb = 0;
      String division = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println("  Perform:\n" +
                         "    SELECT division, MAX(deptnumb)\n" +
                         "      FROM org\n" +
                         "      WHERE location NOT IN 'New York'\n" +
                         "      GROUP BY division\n" +
                         "      HAVING division LIKE '%%ern'\n" +
                         "\n" +
                         "  Results:\n" +
                         "    DIVISION   MAX(DEPTNUMB)\n" +
                         "    ---------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT division, MAX(deptnumb) " +
        "  FROM org " +
        "  WHERE location NOT IN 'New York' " +
        "  GROUP BY division " +
        "  HAVING division LIKE '%ern'");

      while (rs.next())
      {
        division = rs.getString(1);
        maxDeptnumb = rs.getInt(2);

        System.out.println("    " + Data.format(division, 10) +
                           " "        + Data.format(maxDeptnumb, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // subselect

  static void rowSubselect(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A 'ROW' SUBSELECT.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println("  Perform:\n" +
                         "    SELECT deptnumb, deptname\n" +
                         "      FROM org\n" +
                         "      WHERE location = 'New York'\n" +
                         "\n" +
                         "  Results:\n" +
                         "    DEPTNUMB DEPTNAME\n" +
                         "    -------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, deptname " +
        "  FROM org " +
        "  WHERE location = 'New York' ");
      rs.next();

      int deptnumb = rs.getInt(1);
      String deptname = rs.getString(2);

      System.out.println("    " + Data.format(deptnumb, 8) +
                         " " + Data.format(deptname, 14));

      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // rowSubselect

  static void fullselect(Connection con)
  {
    try
    {
      int deptnumb = 0;
      String deptname = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A FULLSELECT.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println("  Perform:\n" +
                         "    SELECT deptnumb, deptname\n" +
                         "      FROM org\n" +
                         "      WHERE deptnumb < 20\n" +
                         "      UNION\n" +
                         "      VALUES(7, 'New Deptname')\n" +
                         "\n" +
                         "  Results:\n" +
                         "    DEPTNUMB DEPTNAME\n" +
                         "    -------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT deptnumb, deptname " +
                                       "  FROM org " +
                                       "  WHERE deptnumb < 20 " +
                                       "  UNION " +
                                       "  VALUES(7, 'New Deptname')");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        deptname = rs.getString(2);

        System.out.println("    " + Data.format(deptnumb, 8) +
                           " "        + Data.format(deptname, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // fullselect

  static void selectStatement(Connection con)
  {
    try
    {
      int    deptnumb = 0;
      String deptname = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SELECT STATEMENT.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println("  Perform:\n" +
                         "    SELECT deptnumb, deptname\n" +
                         "      FROM org\n" +
                         "      WHERE deptnumb > 30\n" +
                         "      ORDER BY deptname\n" +
                         "\n" +
                         "  Results:\n" +
                         "    DEPTNUMB DEPTNAME\n" +
                         "    -------- ------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
      "SELECT deptnumb, deptname " +
      "  FROM org " +
      "  WHERE deptnumb > 30 " +
      "  ORDER BY deptname");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        deptname = rs.getString(2);

        System.out.println("    " + Data.format(deptnumb, 8) +
                           " " + Data.format(deptname, 18));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // selectStatement

  static void basicSubselectFromMultipleTables(Connection con)
  {
    try
    {
      int deptnumb = 0;
      String deptno = "";
      String orgDeptname = "";
      String departmentDeptname = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT FROM MULTIPLE TABLES.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      // display DEPARTMENT table content
      DepartmentTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT deptnumb, o.deptname, deptno, d.deptname\n" +
        "      FROM org o, department d\n" +
        "      WHERE deptnumb <= 15 AND deptno LIKE '%%11'\n" +
        "\n" +
        "  Results:\n" +
        "    DEPTNUMB ORG.DEPTNAME   DEPTNO DEPARTMENT.DEPTNAME\n" +
        "    -------- -------------- ------ -------------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, o.deptname, deptno, d.deptname " +
        "  FROM org o, department d " +
        "  WHERE deptnumb <= 15 AND deptno LIKE '%11'");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        orgDeptname = rs.getString(2);
        deptno = rs.getString(3);
        departmentDeptname = rs.getString(4);

        System.out.println("    " + Data.format(deptnumb, 8) +
                           " " + Data.format(orgDeptname, 14) +
                           " " + Data.format(deptno, 6) +
                           " " + Data.format(departmentDeptname, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // TbBasicSelectFromMultipleTables

  static void basicSubselectFromJoinedTable(Connection con)
  {
    try
    {
      int deptnumb = 0;
      int manager = 0;
      String deptno = "";
      String mgrno = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT FROM JOINED TABLES.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      // display DEPARTMENT table content
      DepartmentTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT deptnumb, manager, deptno, mgrno\n" +
        "      FROM org\n" +
        "      INNER JOIN department\n" +
        "      ON manager = INTEGER(mgrno)\n" +
        "      WHERE deptnumb BETWEEN 20 AND 100\n" +
        "\n" +
        "  Results:\n" +
        "    DEPTNUMB MANAGER DEPTNO MGRNO\n" +
        "    -------- ------- ------ ------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, manager, deptno, mgrno " +
        "  FROM org " +
        "  INNER JOIN department " +
        "  ON manager = INTEGER(mgrno) " +
        "  WHERE deptnumb BETWEEN 20 AND 100 ");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        manager = rs.getInt(2);
        deptno = rs.getString(3);
        mgrno = rs.getString(4);

        System.out.println("    " + Data.format(deptnumb, 8) +
                           " " + Data.format(manager, 7) +
                           " " + Data.format(deptno, 5) +
                           " " + Data.format(mgrno, 6));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // basicSubselectFromJoinedTable

  static void basicSubselectUsingSubquery(Connection con)
  {
    try
    {
      int deptnumb = 0;
      String deptname = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT USING SUBQUERY.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT deptnumb, deptname\n" +
        "      FROM org\n" +
        "      WHERE deptnumb < (SELECT AVG(deptnumb) FROM org)\n" +
        "\n" +
        "  Results:\n" +
        "    DEPTNUMB DEPTNAME\n" +
        "    -------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, deptname " +
        "  FROM org " +
        "  WHERE deptnumb < (SELECT AVG(deptnumb) FROM org)");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        deptname = rs.getString(2);

        System.out.println("    " + Data.format(deptnumb, 8) +
                           " " + Data.format(deptname, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // basicSubselectUsingSubquery

  static void basicSubselectUsingCorrelatedSubquery(Connection con)
  {
    try
    {
      int deptnumb = 0;
      String deptname = "";

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT USING CORRELATED SUBQUERY.");

      // display the content of the 'org' table
      OrgTbContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT deptnumb, deptname\n" +
        "      FROM org o1\n" +
        "      WHERE deptnumb > (SELECT AVG(deptnumb)\n" +
        "                          FROM org o2\n" +
        "                          WHERE o2.division = o1.division)\n" +
        "\n" +
        "  Results:\n" +
        "    DEPTNUMB DEPTNAME\n" +
        "    -------- --------------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT deptnumb, deptname " +
        "  FROM org o1 " +
        "  WHERE deptnumb > (SELECT AVG(deptnumb) " +
        "                      FROM org o2 " +
        "                      WHERE o2.division = o1.division) ");

      while (rs.next())
      {
        deptnumb = rs.getInt(1);
        deptname = rs.getString(2);

        System.out.println("    " + Data.format(deptnumb, 8) +
                           " " + Data.format(deptname, 14));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // basicSubselectUsingCorrelatedSubquery

  static void subselectUsingGroupingSets(Connection con)
  {
    try
    {
      String job = null;
      Integer edlevel = new Integer(0);
      Double commSum = new Double(0.0);

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT USING GROUPING SETS.");

      EmployeeTbPartialContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT job, edlevel, SUM(comm)\n" +
        "      FROM employee\n" +
        "      WHERE job IN('DESIGNER', 'FIELDREP')\n" +
        "      GROUP BY GROUPING SETS((job, edlevel), (job))\n" +
        "\n" +
        "  Results:\n" +
        "    JOB      EDLEVEL SUM(COMM)\n" +
        "    -------- ------- -----------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT job, edlevel, SUM(comm) " +
        "  FROM employee " +
        "  WHERE job IN('DESIGNER','FIELDREP') " +
        "  GROUP BY GROUPING SETS ((job, edlevel),(job))");

      while (rs.next())
      {
        if (rs.getString(1) != null)
        {
          job = rs.getString(1);
          System.out.print("    " + Data.format(job, 8));
        }
        else
        {
          System.out.print("           -");
        }

        if (rs.getString(2) != null)
        {
          edlevel = Integer.valueOf(rs.getString(2));
          System.out.print(" " + Data.format(edlevel, 7));
        }
        else
        {
          System.out.print("       -");
        }

        if (rs.getDouble(3) != 0.0)
        {
          commSum = Double.valueOf(
                      Double.toString(rs.getDouble(3)));
          System.out.print(" " + Data.format(commSum, 10, 2));
        }
        else
        {
          System.out.print("          -");
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
  } // subselectUsingGroupingSets

  static void subselectUsingRollup(Connection con)
  {
    try
    {
      String job = null;
      Integer edlevel = new Integer(0);
      Double commSum = new Double(0.0);

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT USING ROLLUP.");

      EmployeeTbPartialContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT job, edlevel, SUM(comm)\n" +
        "      FROM employee\n" +
        "      WHERE job IN('DESIGNER', 'FIELDREP')\n" +
        "      GROUP BY ROLLUP(job, edlevel)\n" +
        "\n" +
        "  Results:\n" +
        "    JOB      EDLEVEL SUM(COMM)\n" +
        "    -------- ------- -----------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT job, edlevel, SUM(comm) " +
        "  FROM employee " +
        "  WHERE job IN('DESIGNER', 'FIELDREP') " +
        "  GROUP BY ROLLUP(job, edlevel)");

      while (rs.next())
      {
        if (rs.getString(1) != null)
        {
          job = rs.getString(1);
          System.out.print("    " + Data.format(job, 8));
        }
        else
        {
          System.out.print("           -");
        }

        if (rs.getString(2) != null)
        {
          edlevel = Integer.valueOf(rs.getString(2));
          System.out.print(" " + Data.format(edlevel, 7));
        }
        else
        {
          System.out.print("       -");
        }

        if (rs.getDouble(3) != 0.0)
        {
          commSum = Double.valueOf(
                      Double.toString(rs.getDouble(3)));
          System.out.print(" " + Data.format(commSum, 10, 2));
        }
        else
        {
          System.out.print("          -");
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
  } // subselectUsingRollup

  static void subselectUsingCube(Connection con)
  {
    try
    {
      String job = null;
      Integer edlevel = new Integer(0);
      Double commSum = new Double(0.0);

      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SUBSELECT USING CUBE.");

      EmployeeTbPartialContentDisplay(con);

      System.out.println();
      System.out.println(
        "  Perform:\n" +
        "    SELECT job, edlevel, SUM(comm)\n" +
        "      FROM employee\n" +
        "      WHERE job IN('DESIGNER', 'FIELDREP')\n" +
        "      GROUP BY CUBE(job, edlevel)\n" +
        "\n" +
        "  Results:\n" +
        "    JOB      EDLEVEL SUM(COMM)\n" +
        "    -------- ------- -----------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT job, edlevel, SUM(comm) " +
        "  FROM employee " +
        "  WHERE job IN('DESIGNER', 'FIELDREP') " +
        "  GROUP BY CUBE(job, edlevel)");

      while (rs.next())
      {
        if (rs.getString(1) != null)
        {
          job = rs.getString(1);
          System.out.print("    " + Data.format(job, 8));
        }
        else
        {
          System.out.print("           -");
        }

        if (rs.getString(2) != null)
        {
          edlevel = Integer.valueOf(rs.getString(2));
          System.out.print(" " + Data.format(edlevel, 7));
        }
        else
        {
          System.out.print("       -");
        }

        if (rs.getDouble(3) != 0.0)
        {
          commSum = Double.valueOf(
                      Double.toString(rs.getDouble(3)));
          System.out.print(" " + Data.format(commSum, 10, 2));
        }
        else
        {
          System.out.print("          -");
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
  } // subselectUsingCube
  
  static void selectUsingQuerySampling(Connection con)
  {
    try
    {
      float avg = 0.0f;
      
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO PERFORM A SELECT USING QUERY SAMPLING ");

      System.out.println(
        "\nCOMPUTING AVG(SALARY) WITHOUT SAMPLING \n" +
        "\n  Perform:\n" +
        "    SELECT AVG(salary) FROM employee \n" +
        "\n  Results:\n" +
        "    AVG SALARY\n" +
        "    ----------");
     
      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
                       "SELECT AVG(salary) FROM employee");
      
      while (rs.next())
      {
        avg = rs.getFloat(1);
        if (rs.wasNull())
        {
          System.out.println("           -");
        }
        else
        {
          System.out.println("    " + avg);
        }
      }  
      rs.close();
           
      System.out.println(
        "\nCOMPUTING AVG(SALARY) WITH QUERY SAMPLING" +
        "\n  - ROW LEVEL SAMPLING " +
        "\n  - BLOCK LEVEL SAMPLING \n" +
        "\n  ROW LEVEL SAMPLING : USE THE KEYWORD 'BERNOULLI'\n" +
        "\nFOR A SAMPLING PERCENTAGE OF P, EACH ROW OF THE TABLE IS\n" +
        "SELECTED FOR THE INCLUSION IN THE RESULT WITH A PROBABILITY\n" +
        "OF P/100, INDEPENDENTLY OF THE OTHER ROWS IN T\n" +
        "\n  Perform:\n" +
        "    SELECT AVG(salary) FROM employee TABLESAMPLE BERNOULLI(25)" +
        " REPEATABLE(5)\n" +
        "\n  Results:\n" +
        "    AVG SALARY\n" +
        "    ----------");
      
      rs = stmt.executeQuery(
             "SELECT AVG(salary) FROM employee " +
             "TABLESAMPLE BERNOULLI(25) REPEATABLE(5)");
      
      while (rs.next())
      {
        avg = rs.getFloat(1);
        if (rs.wasNull())
        {
          System.out.println("           -");
        }
        else
        {
          System.out.println("    " + avg);
        }
      }  
      rs.close();
      
      System.out.println(
        "\n\n  BLOCK LEVEL SAMPLING : USE THE KEYWORD 'SYSTEM'\n" +
        "\nFOR A SAMPLING PERCENTAGE OF P, EACH ROW OF THE TABLE IS\n" +
        "SELECTED FOR INCLUSION IN THE RESULT WITH A PROBABILITY\n" +
        "OF P/100, NOT NECESSARILY INDEPENDENTLY OF THE OTHER ROWS\n" + 
        "IN T, BASED UPON AN IMPLEMENTATION-DEPENDENT ALGORITHM\n" +
        "\n  Perform:\n" +
        "    SELECT AVG(salary) FROM employee TABLESAMPLE SYSTEM(50)" +
        " REPEATABLE(1234)\n" +
        "\n  Results:\n" +
        "    AVG SALARY\n" +
        "    ----------" );
      
      rs = stmt.executeQuery(
             "SELECT AVG(salary)FROM employee "+
             "TABLESAMPLE SYSTEM(50) REPEATABLE(1234)");
      
      while (rs.next())
      {
        avg = rs.getFloat(1);
        if (rs.wasNull())
        {
          System.out.println("           -");
        }
        else
        {
          System.out.println("    " + avg);
        }
      }  
      rs.close();
      
      System.out.println(
        "\nREPEATABLE CLAUSE ENSURES THAT REPEATED EXECUTIONS OF THAT\n" +
        "TABLE REFERENCE WILL RETURN IDENTICAL RESULTS FOR THE SAME \n" +
        "VALUE OF THE REPEAT ARGUMENT (IN PARENTHESIS).");
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // selectUsingQuerySampling
} // TbRead
