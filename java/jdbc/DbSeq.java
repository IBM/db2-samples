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
// SOURCE FILE NAME: DbSeq.java
//
// SAMPLE: How to create, alter and drop a sequence in a database
//
//         This sample demonstrates how to create, alter and drop a
//         sequence object. It also demonstrates how to use 'next value'
//         and 'previous value' with a sequence object.
//
// SQL STATEMENTS USED:
//         CREATE SEQUENCE
//         ALTER SEQUENCE
//         DROP SEQUENCE
//         INSERT
//         SELECT
//         COMMIT
//         ROLLBACK
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
// OUTPUT FILE: DbSeq.out (available in the online documentation)
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

class DbSeq
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO USE A SEQUENCE IN A DATABASE.");

      // connect to the 'sample' database
      db.connect();

      createSequence(db.con);

      // The following code demonstrates how to GRANT the usage permission
      // on the sequence 'id_seq' to a user, Tom, from Bob. Comment out the
      // following and replace 'Tom' with the user you want to grant usage
      // permission to.

      // Statement grantstmt = con.createStatement();
      // grantstmt.executeUpdate("GRANT USAGE ON SEQUENCE id_seq TO Tom");
      // grantstmt.close();

      // The following code demonstrates how to REVOKE the usage permission
      // on the sequence 'id_seq' from Tom by Bob. Comment out the
      // following, replace 'Bob' with your user name and 'Tom' with the
      // user you want to revoke usage permission from.

      // Statement revostmt = con.createStatement();
      // revostmt.executeUpdate(
      //   "REVOKE USAGE ON SEQUENCE id_seq FROM Tom BY Bob");
      // revostmt.close();

      nextValSeq(db.con);
      prevValSeq(db.con);
      dropSequence(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

  } //main

  // Helping function: This function is used to display the contents of
  // the tables created in this sample program.
  static void tbContentDisplay(Connection con, String tableName)
  {
    try
    {
      int empNo;
      String info = null;

      String column = "Name";
      System.out.println("\n  SELECT * FROM " + tableName);

      if (tableName.equalsIgnoreCase("emp_location"))
      {
        column="Location";
      }
      System.out.println("    EmpNo    " + column);
      System.out.println("    -----    ----------");
      PreparedStatement pstmt = con.prepareStatement(
        "SELECT * FROM " + tableName);

      ResultSet rs = pstmt.executeQuery();

      while (rs.next())
      {
        info = rs.getString(2);
        empNo = rs.getInt(1);
        System.out.println("    "+empNo + "      " + info);
      }
      rs.close();
      pstmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // tbContentDisplay

  // This function shows how to create a table and a sequence in a database.
  static void createSequence(Connection con)
  {
    try
    {
      System.out.println(
        "\n---------------------------------------------------\n"+
        "USE THE SQL STATEMENT:\n" +
        "  CREATE SEQUENCE\n" +
        "TO CREATE A SEQUENCE.");

      // Create a sequence object called 'id_seq' that generates the
      // employee's ID number.
      System.out.println();
      System.out.println(
        "  CREATE SEQUENCE id_seq\n" +
        "    AS INTEGER\n" +
        "    START WITH 400\n" +
        "    INCREMENT BY 10\n" +
        "    NO MINVALUE\n" +
        "    MAXVALUE 430\n" +
        "    NO CYCLE\n" +
        "    NO CACHE");
      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE SEQUENCE id_seq AS INTEGER START WITH 400 " +
        "INCREMENT BY 10 NO MINVALUE MAXVALUE 430 NO CYCLE " +
        "NO CACHE");
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // createTbAndSeq

  // This function shows how to drop a table and a sequence object in a
  // database.
  static void dropSequence(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "------------------------------------------------\n"+
        "USE THE SQL STATEMENT:\n" +
        "  DROP SEQUENCE\n" +
        "TO DROP A SEQUENCE.");

      // drop a sequence object called 'id_seq'
      System.out.println();
      System.out.println("  DROP SEQUENCE id_seq RESTRICT");

      Statement drop = con.createStatement();
      drop.executeUpdate("DROP SEQUENCE id_seq RESTRICT");
      drop.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // dropTbAndSeq

  // This function shows how to alter a sequence object.
  static void alterSeq(Connection con)
  {
    try
    {
      System.out.println(
        "USE THE SQL STATEMENTS:\n" +
        "  ALTER\n" +
        "TO ALTER A SEQUENCE");

      // Alter the sequence to restart from 430 with a range of 400 to 430
      // inclusively while incrementing by -10 (decrementing by 10) with
      // no maximum value.
      System.out.println();
      System.out.println(
        "  ALTER SEQUENCE id_seq\n" +
        "    RESTART WITH 430\n" +
        "    INCREMENT BY -10\n" +
        "    MINVALUE 400\n" +
        "    NO MAXVALUE\n" +
        "    CYCLE\n" +
        "    CACHE 10");

      Statement altstmt = con.createStatement();
      altstmt.executeUpdate(
        "ALTER SEQUENCE id_seq RESTART WITH 430 INCREMENT BY -10" +
        " MINVALUE 400 NO MAXVALUE CYCLE CACHE 10");
      altstmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // alterSeq

  // This function shows how to use a sequence with 'NEXT VALUE' to insert
  // table data and generate a gap.
  static void nextValSeq(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "---------------------------------------------------\n"+
        "USE THE SQL STATEMENTS:\n" +
        "  INSERT\n" +
        "TO INSERT TABLE DATA USING A SEQUENCE WITH 'NEXT VALUE'");

      // create a table called 'contract_emp'
      System.out.println();
      System.out.println(
        "  CREATE TABLE contract_emp(empNo INTEGER, name CHAR(10))");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE contract_emp(empNo INTEGER, name CHAR(10))");
      stmt.close();

      // insert table data using 'NEXT VALUE'
      System.out.println();
      System.out.println(
        "  INSERT INTO contract_emp\n" +
        "    VALUES(NEXT VALUE FOR id_seq, 'shameem')\n");
      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO contract_emp VALUES(NEXT VALUE FOR id_seq, 'shameem')");
      stmt1.close();

      System.out.println("  COMMIT\n");
      con.commit();

      // display the content of the 'contract_emp' table
      tbContentDisplay(con, "contract_emp");

      // insert table data using 'NEXT VALUE'
      System.out.println(
        "  INSERT INTO contract_emp\n" +
        "    VALUES(NEXT VALUE FOR id_seq, 'mohammed')\n");
      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "INSERT INTO contract_emp VALUES(NEXT VALUE FOR id_seq, 'mohammed')");
      stmt2.close();

      // display the content of the 'contract_emp' table
      tbContentDisplay(con, "contract_emp");

      System.out.println("  ROLLBACK\n");
      con.rollback();

      // display the content of the 'contract_emp' table
      tbContentDisplay(con, "contract_emp");

      // insert table data using 'NEXT VALUE'
      System.out.println();
      System.out.println(
        "  INSERT INTO contract_emp\n" +
        "    VALUES(NEXT VALUE FOR id_seq, 'sunny')\n");
      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate(
        "INSERT INTO contract_emp VALUES(NEXT VALUE FOR id_seq,'sunny')");
      stmt3.close();

      // display the content of the 'contract_emp' table
      tbContentDisplay(con, "contract_emp");

      System.out.println();
      System.out.println(
        "  Note:\n"+
        "    The new insertion has EmpNo 420. Note the gap in the\n"+
        "    EmpNo. This shows numbers generated by SEQUENCE are\n"+
        "    independent of the status of the transaction that\n"+
        "    generated the previous value in the sequence.\n");

      System.out.println(
        "  Altering the sequence to show overlap can be generated by\n"+
        "  a sequence object.\n");
      alterSeq(con);

      // insert table data using 'NEXT VALUE' after altering the sequence
      System.out.println();
      System.out.println(
        "  INSERT INTO contract_emp\n" +
        "    VALUES(NEXT VALUE FOR id_seq, 'saba')\n"+
        "          (NEXT VALUE FOR id_seq, 'repeat')");

      Statement stmt4 = con.createStatement();
      stmt4.executeUpdate(
        "INSERT INTO contract_emp VALUES(NEXT VALUE FOR " +
        "id_seq,'saba'), (NEXT VALUE FOR id_seq, 'repeat')");
      stmt4.close();

      // display the content of the 'contract_emp' table after altering the
      // sequence
      tbContentDisplay(con, "contract_emp");

      System.out.println();
      System.out.println(
        "  Note:\n"+
        "    One of the new insertions has EmpNo 420 which\n" +
        "    already exists. This happened because the new altered range\n" +
        "    of sequence overlaps the old one. It is the responsibility\n" +
        "    of the programmer to ensure that these overlaps do not\n" +
        "    occur if they are not wanted.\n");

      // drop the table 'emp_location'
      System.out.println("  DROP TABLE contract_emp");
      Statement drop = con.createStatement();
      drop.executeUpdate("DROP TABLE contract_emp");
      drop.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // nextValSeq

  // This function shows how to use a sequence with 'PREVIOUS VALUE' to insert
  // the last generated sequence value into a table.
  static void prevValSeq(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "---------------------------------------------------\n"+
        "USE THE SQL STATEMENTS:\n" +
        "  INSERT INTO PREVIOUS VALUE\n" +
        "TO INSERT DATA INTO A TABLE USING A SEQUENCE WITH 'PREVIOUS VALUE'");

      // create a table called 'emp_location'
      System.out.println();
      System.out.println(
        "  CREATE TABLE emp_location(empNo INTEGER, city CHAR(10))\n");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE emp_location(empNo INTEGER, city CHAR(10))");
      stmt.close();

      // insert table data using 'PREVIOUS VALUE'
      System.out.println(
        "  INSERT INTO emp_location\n" +
        "    VALUES(PREVIOUS VALUE FOR id_seq, 'repeat')");
      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO emp_location VALUES(PREVIOUS VALUE FOR id_seq, 'repeat')");
      stmt1.close();

      // display the content of the 'emp_location' table
      tbContentDisplay(con, "emp_location");

      System.out.println();
      System.out.println(
        "  Note:\n"+
        "    By using SEQUENCE with 'PREVIOUS VALUE', you can insert\n"+
        "    into a different table with the last generated\n"+
        "    EmpNo.\n");

      // drop the 'emp_location' table
      System.out.println("  DROP TABLE emp_location");
      Statement drop = con.createStatement();
      drop.executeUpdate("DROP TABLE emp_location");
      drop.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // prevValSeq
} // DbSeq

