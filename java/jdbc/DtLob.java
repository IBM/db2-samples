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
// SOURCE FILE NAME: DtLob.java
//
// SAMPLE: How to use LOB data type
//
//         This program ONLY works with jdk 1.2.2 or later version.
//
//         Before running this sample, ensure that you set the database
//         manager configuration parameter UDF Shared Memory Set Size
//         (udf_mem_sz) to at least two pages more than the larger
//         of the input arguments or the resulting CLOB being retrieved.
//
//         For example, issue: db2 UPDATE DBM CFG USING udf_mem_sz 1024
//         to run this sample program against the SAMPLE database.
//
//         Stop and restart the server for the change to take effect.
//
// SQL Statements USED:
//         SELECT
//         INSERT
//         DELETE
//
// JAVA 2 CLASSES USED:
//         Connection
//         PreparedStatement
//         Statement
//         ResultSet
//         Clob
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
// OUTPUT FILE: DtLob.out (available in the online documentation)
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

import java.io.*;
import java.lang.*;
import java.util.*;
import java.sql.*;

class DtLob
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO USE LOB DATA TYPE.");

      // connect to the 'sample' database
      db.connect();

      blobFileUse(db.con);
      clobUse(db.con);
      clobFileUse(db.con);
      clobSearchStringUse(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  static void blobFileUse(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "  INSERT\n" +
        "  DELETE\n" +
        "TO SHOW HOW TO USE BINARY LARGE OBJECT (BLOB) FILES.");

      String osName = System.getProperty("os.name");
      String photoFormat;
      String fileName;
      String empno;

      if (osName.equals("Windows NT"))
      {
        photoFormat = "bitmap";
        fileName = "photo.BMP";
      }
      else
      {
        // UNIX
        photoFormat = "gif";
        fileName = "photo.GIF";
      }

      // ---------- Read BLOB data from file -------------------
      System.out.println();
      System.out.println(
        "  ---------------------------------------------------\n" +
        "  READ BLOB DATA FROM THE FILE '" + fileName + "':");

      System.out.println();
      System.out.println(
        "    Prepare the statement:\n" +
        "      SELECT picture\n" +
        "        FROM emp_photo\n" +
        "        WHERE photo_format = ? AND empno = ?");

      PreparedStatement pstmt = con.prepareStatement(
        "SELECT picture " +
        "  FROM emp_photo " +
        "  WHERE photo_format = ? AND empno = ?");

      System.out.println();
      System.out.println(
        "    Execute the prepared statement using:\n" +
        "      photo_format = 'bitmap'\n" +
        "      empno = '000130'");

      empno = "000130";
      pstmt.setString(1, photoFormat);
      pstmt.setString(2, empno);
      ResultSet rs = pstmt.executeQuery();
      rs.next();
      Blob blob = rs.getBlob(1);

      System.out.println();
      System.out.println("  READ FROM BLOB FILE SUCCESSFULLY!");

      // -------------- Write BLOB data into file -----------------
      System.out.println();
      System.out.println(
        "  ---------------------------------------------------\n" +
        "  INSERT BLOB FILE " + fileName + " INTO THE DB:");

      System.out.println();
      System.out.println(
        "    Prepare the statement:\n" +
        "      INSERT INTO emp_photo(photo_format, empno, picture)\n" +
        "        VALUES (?, ?, ?)");

      PreparedStatement pstmt2 = con.prepareStatement(
        "INSERT INTO emp_photo (photo_format, empno, picture) " +
        "  VALUES (?, ?, ?)");

      System.out.println();
      System.out.println(
        "    Execute the prepared statement using:\n" +
        "      photo_format = 'bitmap'\n" +
        "      empno = '200140'\n" +
        "    And the blob object that we get from reading the\n" +
        "      file 'photo.*' eariler.");

      empno = "200140";
      pstmt2.setString(1, photoFormat);
      pstmt2.setString(2, empno);
      pstmt2.setBlob(3, blob);
      pstmt2.executeUpdate();
      rs.close();
      pstmt.close();
      pstmt2.close();

      System.out.println();
      System.out.println("  INSERT BLOB FILE TO DB SUCCESSFULLY!");

      // ------------ Delete NEW RECORD from the database ---------
      System.out.println();
      System.out.println(
        "  ---------------------------------------------------\n" +
        "  DELETE THE NEW RECORD FROM THE DATABASE:");

      System.out.println();
      System.out.println(
        "    Prepare the statement:\n" +
        "      DELETE FROM emp_photo WHERE empno = ?");

      PreparedStatement pstmt3 = con.prepareStatement(
        "DELETE FROM emp_photo WHERE empno = ? ");

      System.out.println();
      System.out.println(
        "    Execute the prepared statement using:\n" +
        "      empno = '200140'");

      pstmt3.setString(1, empno);
      pstmt3.executeUpdate();
      pstmt3.close();

      System.out.println();
      System.out.println("  DELETE THE NEW RECORD FROM DB SUCCESSFULLY!");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // blobFileUse

  static void clobUse(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "  INSERT\n" +
        "  DELETE\n" +
        "TO SHOW HOW TO USE CHARACTER LARGE OBJECT (CLOB) DATA TYPE.");

      // ----------- Read CLOB data type from DB ----------------
      System.out.println();
      System.out.println(
        "  ---------------------------------------------------\n" +
        "  READ CLOB DATA TYPE:");

      System.out.println();
      System.out.println(
        "    Execute the statement:\n" +
        "      SELECT resume\n" +
        "        FROM emp_resume\n" +
        "        WHERE resume_format = 'ascii' AND empno = '000130'\n" +
        "\n" +
        "    Note: resume is a CLOB data type!");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT resume " +
        "  FROM emp_resume " +
        "  WHERE resume_format = 'ascii' AND empno = '000130'");

      rs.next();
      Clob clob = rs.getClob(1);

      System.out.println();
      System.out.println("  READ CLOB DATA TYPE FROM DB SUCCESSFULLY!");

      // ------------ Display the CLOB data onto the screen -------
      long clobLength = clob.length();

      System.out.println();
      System.out.println(
        "  ---------------------------------------------------\n" +
        "  HERE IS THE RESUME WITH A LENGTH OF " + clobLength +
        " CHARACTERS.");

      String clobString = clob.getSubString(1, (int)clobLength);
      System.out.println();
      System.out.println(clobString);
      System.out.println("    --- END OF RESUME ---");

      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // clobUse

  static void clobFileUse(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  SELECT\n" +
        "TO SHOW HOW TO USE CHARACTER LARGE OBJECT (CLOB) DATA TYPE.");

      String fileName = "RESUME.TXT";

      // ----------- Read CLOB data type from DB -----------------
      System.out.println();
      System.out.println(
        "  ---------------------------------------------------\n" +
        "  READ CLOB DATA TYPE:");

      System.out.println();
      System.out.println(
        "    Execute the statement:\n" +
        "      SELECT resume\n" +
        "        FROM emp_resume\n" +
        "        WHERE resume_format = 'ascii' AND empno = '000130'\n" +
        "\n" +
        "    Note: resume is a CLOB data type!");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT resume " +
        "  FROM emp_resume " +
        "  WHERE resume_format = 'ascii' AND empno = '000130'");
      rs.next();
      Clob clob = rs.getClob(1);

      System.out.println();
      System.out.println("  READ CLOB DATA TYPE DB SUCCESSFULLY!");

      // ---------- Write CLOB data into file -------------------
      long clobLength = clob.length();

      System.out.println(
        "  ---------------------------------------------------\n" +
        "  WRITE THE CLOB DATA THAT WE GET FROM ABOVE INTO THE " +
        "FILE '" + fileName + "'");

      String clobString = clob.getSubString(1, (int)clobLength);

      FileWriter letters = new FileWriter(fileName);
      letters.write(clobString, 0, (int)clobLength-1);
      letters.close();

      rs.close();
      stmt.close();

      System.out.println();
      System.out.println("  WRITE CLOB DATA TYPE INTO FILE SUCCESSFULLY!");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // clobFileUse

static void clobSearchStringUse(Connection con)
{
  try
  {
    System.out.println();
    System.out.println(
    "----------------------------------------------------------\n"
    + "USE THE SQL STATEMENTS:\n"
    + " SELECT\n"
    + "TO SHOW HOW TO SEARCH A SUBSTRING WITHIN A CLOB OBJECT.");

    // ----------- Read CLOB data from file -------------------
    System.out.println();
    System.out.println(
    " ---------------------------------------------------\n" + " READ CLOB DATA TYPE:");

    System.out.println();
    System.out.println(
    " Execute the statement:\n"
    + " SELECT resume\n"
    + " FROM emp_resume\n"
    + " WHERE resume_format = 'ascii' AND empno = '000130'\n"
    + "\n"
    + " Note: resume is a CLOB data type!");

    Statement stmt = con.createStatement();
    ResultSet rs =

    stmt.executeQuery(
    "SELECT resume "
    + " FROM emp_resume "
    + " WHERE resume_format = 'ascii' AND empno = '000130'");

    rs.next();

    ResultSetMetaData rsMetaData = rs.getMetaData();
    int clobType = rsMetaData.getColumnType(1);
    Clob clob = rs.getClob(1);

    System.out.println();
    System.out.println(" READ CLOB DATA TYPE FROM DB SUCCESSFULLY!");
    // ------ Display the ORIGINAL CLOB data onto the screen -------

    long clobLength = clob.length();
    System.out.println(" The original CLOB is " + clobLength + " bytes long.");

    System.out.println();
    System.out.println(
    " ***************************************************\n"
    + " ORIGINAL RESUME -- VIEW \n"
    + " ***************************************************");

    String clobString = clob.getSubString(1, (int) clobLength);
    System.out.println(clobString);
    System.out.println(" -- END OF ORIGINAL RESUME -- ");

    System.out.println();
    System.out.println(
    " ***************************************************\n"
    + " NEW RESUME -- CREATE \n"
    + " ***************************************************");

    // Determine the starting position of each section of the resume
    long resPos = 1; //this is the 'Resume: Delores M. Quintana' part 
    long prsPos = clob.position("Personal Information", 1); 
    long depPos = clob.position("Department Information", 1);
    long eduPos = clob.position("Education", 1); 
    long wrkPos = clob.position("Work History", 1); 
    long intPos = clob.position("Interests", 1); 

    // Determine the length of each section of the resume
    long resLength = prsPos - 1;
    long prsLength = depPos - prsPos;
    long depLength = eduPos - depPos;
    long eduLength = wrkPos - eduPos;
    long wrkLength = intPos - wrkPos;
    long intLength = clobLength - intPos + 1;

    System.out.println();
    System.out.println(" Create new resume with Department info at end.");
    // Create a separate String for each section of the resume 
    String resInfo = clob.getSubString(resPos, (int) resLength);
    String prsInfo = clob.getSubString(prsPos, (int) prsLength);
    String depInfo = clob.getSubString(depPos, (int) depLength);
    String eduInfo = clob.getSubString(eduPos, (int) eduLength);
    String wrkInfo = clob.getSubString(wrkPos, (int) wrkLength);
    String intInfo = clob.getSubString(intPos, (int) intLength);

    rs.close();
    stmt.close();

    // Concatenate the sections in the desired order 
    String newClobString = resInfo + prsInfo + eduInfo + wrkInfo + intInfo + "\r\n \r\n " + depInfo;

    // Put the new resume in the database but use a different employee number, 200140, so that the 
    // original row is not overlaid. 
    System.out.println();
    System.out.println(" Insert the new resume into the database.");

    PreparedStatement pstmt = con.prepareStatement(
      "INSERT INTO emp_resume (empno, resume_format, resume) " + " VALUES (?, ?, ?)");

    String empno = "200140";
    String resume_format = "ascii";
    Object newObject = newClobString;
    pstmt.setString(1, empno);
    pstmt.setString(2, resume_format);
    pstmt.setObject(3, newObject, clobType);
    pstmt.executeUpdate();
    pstmt.close();

    System.out.println();
    System.out.println(
    " ***************************************************\n"
    + " NEW RESUME -- VIEW \n"
    + " ***************************************************");

    // ----------- Read the NEW RESUME (CLOB) from DB ------------
    System.out.println();
    System.out.println(
    " ---------------------------------------------------\n" + " READ CLOB DATA TYPE:");

    System.out.println();
    System.out.println(
    " Execute the statement:\n"
    + " SELECT resume\n"
    + " FROM emp_resume\n"
    + " WHERE resume_format = 'ascii' AND empno = '200140'");

    Statement stmt2 = con.createStatement();
    ResultSet rs2 = stmt2.executeQuery(
    "SELECT resume " + " FROM emp_resume " + " WHERE empno = '200140'");

    rs2.next();

    Clob clob2 = rs2.getClob(1);
    System.out.println();
    System.out.println(" READ NEW RESUME (CLOB) FROM DB SUCCESSFULLY!");

    // ------ Display the NEW RESUME (CLOB) onto the screen -------
    long clobLength2 = clob2.length();
    System.out.println(" The new CLOB is " + clobLength2 + " bytes long.");

    System.out.println();
    System.out.println(
    " ---------------------------------------------------\n"
    + " HERE IS THE NEW RESUME:");

    String clobString2 = clob2.getSubString(1, (int) clobLength2);
    System.out.println(clobString2);
    System.out.println();
    System.out.println(" -- END OF NEW RESUME --");

    rs2.close();
    stmt2.close();
    // ---------- Delete the NEW RESUME from the database ----
    System.out.println();
    System.out.println(
    " ***************************************************\n"
    + " NEW RESUME -- DELETE \n"
    + " ***************************************************");
    Statement stmt3 = con.createStatement();
    stmt3.executeUpdate("DELETE FROM emp_resume WHERE empno = '200140' ");
    stmt3.close();
  }
  catch (Exception e)
  {
    JdbcException jdbcExc = new JdbcException(e);
    jdbcExc.handle();
  }
} // clobSearchStringUse

} // DtLob Class

