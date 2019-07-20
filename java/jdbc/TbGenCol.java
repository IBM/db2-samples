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
// SOURCE FILE NAME: TbGenCol.java
//
// SAMPLE: How to use generated columns
//
//         This sample demonstrates how to use generated columns.
//         It first creates a table and populates it with some data.
//         Then, the integrity of the table is set to off and a
//         generated column is added to the table.  The integrity of
//         the table is then set to IMMEDIATE CHECKED FORCE GENERATED
//         to refresh the values of the newly added column.  Finally,
//         an index is created on the generated column to illustrate
//         how they can be used to improve query performance.  The
//         sample drops the table it created before exiting.
//
// SQL STATEMENTS USED:
//         CREATE TABLE
//         INSERT
//         SELECT
//         SET INTEGRITY
//         ALTER TABLE
//         CREATE INDEX
//         DROP TABLE
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
// OUTPUT FILE: TbGenCol.out (not available in the samples directory).
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

class TbGenCol
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO USE GENERATED COLUMNS.");

      // connect to the 'sample' database
      db.connect();

      createTableWithData(db.con);
      addGeneratedColumntoTable(db.con);
      createIndexOnGeneratedCol(db.con);
      dropTable(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // Helping function: This function display the content of the table
  // 'genColClassSchedule'.
  static void tbContentDisplay(Connection con, boolean columnadded)
  {
    try
    {
      Integer c_id = new Integer(0);
      String c_name = null;
      String type = null;
      String days = null;
      String starting = null;
      String ending = null;
      Integer duration = new Integer(0);

      System.out.println();
      System.out.println(
        "  SELECT * FROM genColClassSchedule");
      if (columnadded)
      {
        System.out.println(
        "    " +
        "C_ID C_NAME        TYPE  DAYS  STARTING  ENDING    DURATION\n" +
        "    " +
        "---- ------------- ----- ----- --------- --------- --------");
      }
      else
      {
        System.out.println(
        "    C_ID C_NAME        TYPE  DAYS  STARTING  ENDING\n" +
        "    ---- ------------- ----- ----- --------- ---------");
      }

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery(
        "SELECT * FROM genColClassSchedule");

      while (rs.next())
      {
        c_id = Integer.valueOf(rs.getString(1));
        c_name = rs.getString(2);
        type = rs.getString(3);
        days = rs.getString(4);
        starting = rs.getString(5);
        ending = rs.getString(6);

        if (columnadded)
        {
          duration = Integer.valueOf(rs.getString(7));
        }

        System.out.print("  "+ Data.format(c_id, 4) + "  " +
                         " " + Data.format(c_name, 13) +
                         " " + Data.format(type, 5) +
                         " " + Data.format(days, 5) +
                         " " + Data.format(starting, 9) +
                         " " + Data.format(ending, 9));

        if (columnadded)
        {
          System.out.println(" " + Data.format(duration, 8));
        }
        else
        {
          System.out.println();
        }
      }
      System.out.println();

      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // tbContentDisplay

  // Helping function: This function creates a table called
  // 'genColClassSchedule' and inserts some data into the table.
  static void createTableWithData(Connection con) {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  CREATE TABLE\n" +
        "  INSERT INTO\n" +
        "TO CREATE A TABLE WITH DATA");

      System.out.println();
      System.out.println(
        "  CREATE TABLE genColClassSchedule(\n" +
        "    c_id int,\n"+
        "    c_name varchar(20),\n"+
        "    type varchar(3),\n"+
        "    days varchar(3),\n"+
        "    start time,\n"+
        "    end time)\n");

      Statement stmt = con.createStatement();
      stmt.execute(
        "CREATE TABLE genColClassSchedule(c_id int," +
        " c_name varchar(20),"+
        " type varchar(3)," +
        " days varchar(3)," +
        " start time," +
        " end time)");

      System.out.println(
        "  INSERT INTO genColClassSchedule \n" +
        "    VALUES (10,'CMPUT 391','LEC','MWF','14:00:00','14:50:00'),\n" +
        "           (20,'ENGLISH 101','LEC','MWF','08:00:00','08:50:00'),\n" +
        "           (30,'MATH 117','LEC','TR','11:00:00','12:20:00'),\n" +
        "           (40,'CMPUT 391','LAB','T','14:00:00','16:50:00'),\n" +
        "           (50,'PHYS 102','LEC','MWF','09:00:00','09:50:00')");

      stmt.executeUpdate(
        "INSERT INTO genColClassSchedule " +
          "VALUES (10,'CMPUT 391','LEC','MWF','14:00:00','14:50:00'), " +
                 "(20,'ENGLISH 101','LEC','MWF','08:00:00','08:50:00'), " +
                 "(30,'MATH 117','LEC','TR','11:00:00','12:20:00'), " +
                 "(40,'CMPUT 391','LAB','T','14:00:00','16:50:00'), " +
                 "(50,'PHYS 102','LEC','MWF','09:00:00','09:50:00')");

      stmt.close();
      con.commit();

      tbContentDisplay(con,false);
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // createTableWithData

  // This function adds a generated column called 'duration' to the table.
  static void addGeneratedColumntoTable(Connection con)
  {
    try
    {
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  ALTER TABLE\n" +
        "TO ADD A GENERATED COLUMN INTO A TABLE");

      System.out.println();
      System.out.println("  SET INTEGRITY FOR genColClassSchedule OFF\n");

      Statement stmt = con.createStatement();
      stmt.execute("SET INTEGRITY FOR genColClassSchedule OFF");

      // the expression (60*hour(end-start)+minute(end-start)) converts
      // the decimal result of time arithmetic into minutes
      System.out.println(
        "  ALTER TABLE genColClassSchedule\n" +
        "    ADD COLUMN DURATION INTEGER\n" +
        "    GENERATED ALWAYS AS (60*hour(end-start)+minute(end-start))\n");

      stmt.execute("ALTER TABLE genColClassSchedule " +
                   "ADD COLUMN DURATION INTEGER " +
                   "GENERATED ALWAYS AS " +
                   "(60*hour(end-start)+minute(end-start))");

      System.out.println(
        "  SET INTEGRITY FOR genColClassSchedule\n"+
        "    IMMEDIATE CHECKED FORCE GENERATED");

      stmt.execute("SET INTEGRITY FOR genColClassSchedule " +
                   "IMMEDIATE CHECKED FORCE GENERATED");

      stmt.close();
      con.commit();

      tbContentDisplay(con,true);
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // addGeneratedColumntoTable

  // This function creates an index on the generated column
  static void createIndexOnGeneratedCol(Connection con)
  {
    try
    {
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  CREATE INDEX\n" +
        "TO CREATE AN INDEX ON THE GENERATED COLUMN");

      System.out.println();
      System.out.println(
        "  CREATE INDEX duration_index\n" +
        "    ON genColClassSchedule (duration)\n");

      Statement stmt = con.createStatement();
      stmt.execute("CREATE INDEX duration_index " +
                   "ON genColClassSchedule (duration)");

      System.out.println(
        "  SELECT * from genColClassSchedule\n" +
        "    WHERE (60*hour(end-start)+minute(end-start)) > 60");
      System.out.println(
        "      " +
        "C_ID C_NAME        TYPE  DAYS  STARTING  ENDING    DURATION\n" +
        "      " +
        "---- ------------- ----- ----- --------- --------- --------");

      ResultSet rs = stmt.executeQuery("SELECT * from genColClassSchedule " +
                                       "WHERE (60*hour(end-start)" +
                                             " + minute(end-start)) > 60");

      Integer c_id = new Integer(0);
      String c_name = null;
      String type = null;
      String days = null;
      String starting = null;
      String ending = null;
      Integer duration = new Integer(0);

      while (rs.next())
      {
        c_id = Integer.valueOf(rs.getString(1));
        c_name = rs.getString(2);
        type = rs.getString(3);
        days = rs.getString(4);
        starting = rs.getString(5);
        ending = rs.getString(6);
        duration = Integer.valueOf(rs.getString(7));

        System.out.println("    "+ Data.format(c_id, 4) + "  " +
                           " " + Data.format(c_name, 13) +
                           " " + Data.format(type, 5) +
                           " " + Data.format(days, 5) +
                           " " + Data.format(starting, 9) +
                           " " + Data.format(ending, 9) +
                           " " + Data.format(duration, 8));
      }
      rs.close();
      stmt.close();

      System.out.println();
      System.out.println(
      "  NOTE:\n" +
      "    Indexes can be created on generated columns to improve query\n"+
      "    performance. If a query predicate contains a clause identical\n"+
      "    to the clause used to define the generated column and the\n"+
      "    generated column is indexed, the optimizer will use the index.\n"+
      "    The SELECT query:\n\n"+
      "      SELECT * FROM genColClassSchedule\n" +
      "        WHERE (60*hour(end-start)+minute(end-start)) > 60\n\n" +
      "    will, in general, perform better using the indexed generated\n" +
      "    column than without it. The idea is to add expressions that\n" +
      "    occur frequently in queries as generated columns and then\n" +
      "    index them to improve query performance.");

      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // createIndexOnGeneratedCol

  // Helping function: This function drops the table created by this program
  static void dropTable(Connection con) {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE SQL STATEMENTS:\n" +
        "  DROP TABLE\n" +
        "TO DROP A TABLE");

      System.out.println();
      System.out.println("  DROP TABLE genColClassSchedule");

      Statement stmt = con.createStatement();
      stmt.execute("DROP TABLE genColClassSchedule");

      stmt.close();
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // dropTable
} // TbGenCol
