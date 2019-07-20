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
// SOURCE FILE NAME: UDFsqlcl.java
//
// SAMPLE: Call the UDFs in UDFsqlsv.java
//
//         Steps to run the sample with the command line window:
// 
//         I) If you have a compatible make/nmake program on your system, 
//            all you have to do is:
//            1. Compile the server source file UDFsqlsv (this will also compile
//               the Utility file, erase the existing library/class files and
//               copy the newly compiled class files, UDFsqlsv.class and 
//               Person.class from the current directory to the 
//               $(DB2PATH)\function directory):
//                 nmake/make UDFsqlsv
//            2. Connect to the sample database, type:
//                 db2 connect to sample
//            3. Catalog the UDFs defined in UDFsqlsv.java:
//                 db2 -td@ -vf UDFsCreate.db2
//            4. Compile the client source file UDFsqlcl.java:
//                 nmake/make UDFsqlcl
//            5. Run the client UDFsqlcl
//                 java UDFsqlcl
//            6. Uncatalog the UDFs using the following command:
//                 db2 -td@ -vf@ UDFsDrop.db2
//
//         II) If you don't have a compatible make/nmake program on your system,
//             all you have to do is:
//             1. Compile the utility file and the server source file with:
//                  javac Util.java
//                  javac UDFsqlsv.java
//             2. Erase the existing library/class files (if exists), 
//                UDFsqlsv.class and Person.class from the following path,
//                $(DB2PATH)\function. 
//             3. copy the class files, UDFsqlsv.class and Person.class from 
//                the current directory to the $(DB2PATH)\function.
//             4. Connect to the sample database, type:
//                  db2 connect to sample
//             5. Catalog the UDFs defined in UDFsqlsv.java:
//                  db2 -td@ -vf UDFsCreate.db2
//             6. Compile UDFsqlcl with:
//                  javac UDFsqlcl.java
//             7. Run UDFsqlcl with:
//                  java UDFsqlcl
//             8. Uncatalog the UDFs using the following command:
//                  db2 -td@ -vf@ UDFsDrop.db2
//
// SQL Statements USED:
//         SELECT
//
// OUTPUT FILE: UDFsqlcl.out (available in the online documentation)
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

import java.sql.*; // JDBC classes
import java.lang.*;
import java.math.BigDecimal;

class UDFsqlcl
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO WORK WITH UDFs.");

      // connect database
      db.connect();

      demoExternalScalarUDFWithSQL(db.con);
      demoExternalScalarUDFWithNesting(db.con);
      demoExternalTableUDFWithSQL(db.con);
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  static void demoExternalScalarUDFWithSQL(Connection con)
    throws Exception
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  SELECT\n" +
      "TO WORK WITH SCALAR UDF WITH SQL.");

    try
    {
      Statement stmt = con.createStatement();

      // use SCRATCHPAD scalar UDF
      System.out.println();
      System.out.println(
        "  Use the scalar UDF with SQL:\n" +
        "    SELECT name, job, salary, convert(CHAR('CA'), salary, CHAR('US'))\n" +
        "      FROM staff\n" +
        "      WHERE name LIKE 'S%'");

      ResultSet rs = stmt.executeQuery(
        "SELECT name, job, salary, convert(CHAR('CA'), salary, CHAR('US')) " +
        "  FROM staff " +
        "  WHERE name LIKE 'S%' ");

      System.out.println("    NAME       JOB     SALARY   SALARY IN US\n" +
                         "    ---------- ------- -------- ------------");

      String name;
      String job;
      BigDecimal salary;
      double salaryInUS;
      while (rs.next())
      {
        name = rs.getString(1);
        job = rs.getString(2);
        salary = rs.getBigDecimal(3);
        salaryInUS = rs.getDouble(4);

        System.out.println("    " + Data.format(name, 10) +
                           " " + Data.format(job, 7) +
                           " " + Data.format(salary, 7, 2) +
                           " " + Data.format(salaryInUS, 7, 2));
      }
      rs.close();

      // close statement
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demoExternalScratchpadScalarUDF

  static void demoExternalScalarUDFWithNesting(Connection con)
    throws Exception
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  SELECT\n" +
      "TO WORK WITH SCALAR UDF WITH NESTING.");

    try
    {
      Statement stmt = con.createStatement();

      // use scalar UDF
      System.out.println();
      System.out.println(
        "  Use the scalar UDF that returns error:\n" +
        "    SELECT deptno, deptname, sumSalary(deptno)\n"+
        "      FROM department\n");

      ResultSet rs = stmt.executeQuery(
        "SELECT deptno, deptname, sumSalary(deptno)\n" +
        "  FROM department ");

      System.out.println("    DEPTNO Department name               SUM SALARY\n" +
                         "    ------ ----------------------------- ----------");

      String deptno;
      String deptname;
      double sumSalary;

      while (rs.next())
      {
        deptno = rs.getString(1);
        deptname = rs.getString(2);
        sumSalary = rs.getDouble(3);

        System.out.println("    " + Data.format(deptno, 6) +
                           " " + Data.format(deptname, 29) +
                           " " + Data.format(sumSalary, 7, 2));
      }
      rs.close();

      // close statement
      stmt.close();
    }
    catch (SQLException e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demoExternalscalarUDFReturningErr

  static void demoExternalTableUDFWithSQL(Connection con)
    throws Exception
  {
    System.out.println();
    System.out.println(
      "----------------------------------------------------------\n" +
      "USE THE SQL STATEMENTS:\n" +
      "  SELECT\n" +
      "TO WORK WITH TABLE UDF WITH SQL.");

    try
    {
      Statement stmt = con.createStatement();

      // use table UDF
      System.out.println();
      System.out.println(
        "  Use the table UDF:\n" +
        "    SELECT udfTb.name, udfTb.job, udfTb.salary\n" +
        "      FROM TABLE(TableUDF(1.5)) AS udfTb");

      ResultSet rs = stmt.executeQuery(
        "SELECT udfTb.name, udfTb.job, udfTb.salary " +
        "  FROM TABLE(TableUDFWITHSQL(1.5)) AS udfTb ");

      System.out.println("    NAME    JOB        SALARY\n" +
                         "    ------- ---------- --------");

      String name;
      String job;
      double newSalary;
      while (rs.next())
      {
        name = rs.getString(1);
        job = rs.getString(2);
        newSalary = rs.getDouble(3);

        System.out.println("    " + Data.format(name, 7) +
                           " " + Data.format(job, 10) +
                           " " + Data.format(newSalary, 7, 2));
      }
      rs.close();

      // close statement
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // demoExternalTableUDF
} // UDFcli








