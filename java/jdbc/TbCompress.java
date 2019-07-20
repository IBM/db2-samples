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
// SOURCE FILE NAME: TbCompress.java
//
// SAMPLE: How to create tables with null and default value compression 
//         option. 
//
// SQL STATEMENTS USED:
//         CREATE TABLE 
//         ALTER TABLE
//         DROP TABLE
//
// JAVA 2 CLASSES USED:
//         Statement
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
// OUTPUT FILE: TbCompress.out (available in the online documentation)
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
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//     http://www.software.ibm.com/data/db2/udb/ad
//**************************************************************************

import java.lang.*;
import java.sql.*;

class TbCompress
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO USE NULL AND DEFAULT VALUE\n" + 
        "COMPRESSION OPTION AT TABLE LEVEL AND COLUMN LEVEL \n");

      // connect to database
      db.connect();

      // create a new table
      tbCreate(db.con);
      
      // activate null and default value compression
      tbCompress(db.con);
      
      // drop the table created
      tbDrop(db.con);

      // disconnect from 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // main

  // create a new table
  static void tbCreate(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();
      
      // create base table            
      System.out.println(
        "\n-----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT \n" +
        "  CREATE TABLE \n" +
        "TO CREATE A TABLE \n\n" +  
        "  CREATE TABLE comp_tab(col1 INT NOT NULL WITH DEFAULT,\n" + 
        "                        col2 CHAR(7),\n" +
        "                        col3 VARCHAR(7) NOT NULL,\n" +
        "                        col4 DOUBLE) \n");
      stmt.executeUpdate(
        "CREATE TABLE comp_tab(col1 INT NOT NULL WITH DEFAULT," +
        "                      col2 CHAR(7)," +
        "                      col3 VARCHAR(7) NOT NULL," +
        "                      col4 DOUBLE)");
      System.out.println("  COMMIT");
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    } 
  } // tbCreate
  
  // activate null and default value compression
  static void tbCompress(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();
          
      System.out.println(
        "\n-----------------------------------------------------------\n" +
        "USE THE SQL STATEMENT \n" +
        "  ALTER TABLE \n" +
        "TO ALTER COMPRESSION OPTIONS OF THE TABLE\n\n" + 
        "To activate VALUE COMPRESSION at table level and COMPRESS \n" +
        "SYSTEM DEFAULT at column level \n\n" +
        "  ALTER TABLE comp_tab ACTIVATE VALUE COMPRESSION \n\n" +
        "Rows will be formatted using the new row format on subsequent\n" +
        "insert, load and update operation, and NULL values will not be\n" +
        "taking up space if applicable.\n");

      // if the table comp_tab does not have many NULL values, enabling
      // compression will result in using more disk space than using 
      // the old row format 
      stmt.executeUpdate("ALTER TABLE comp_tab ACTIVATE VALUE COMPRESSION");
      con.commit();
      
      System.out.println(
        "\nTo save more disk space on system default value for column\n" +
        "col1, enter\n" +
        "\n  ALTER TABLE comp_tab ALTER col1 COMPRESS SYSTEM DEFAULT\n" +
        "\nOn subsequent insert, load, and update operations, numerical\n" +
        "0 value (occupying 4 bytes of storage) for column col1 will\n" +
        "not be saved on disk.\n");     
      stmt.executeUpdate("ALTER TABLE comp_tab "+
                         "  ALTER col1 COMPRESS SYSTEM DEFAULT");
      con.commit();
      
      System.out.println(
        "\nTo switch the table to use the old format, enter\n\n" +
        "  ALTER TABLE comp_tab DEACTIVATE VALUE COMPRESSION\n\n" +
        "Rows inserted, loaded or updated after the ALTER statement\n" +
        "will have old row format.");      
      stmt.executeUpdate( "ALTER TABLE comp_tab " +
                          "  DEACTIVATE VALUE COMPRESSION");
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    } 
  } // tbCompress

  // drop the table created
  static void tbDrop(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();
     
      // drop the table
      System.out.println(
        "\n-----------------------------------------------------------" +
        "\nUSE THE SQL STATEMENT\n" +
        "  DROP TABLE\n" +
        "TO DROP THE TABLE\n\n" +
        "  DROP TABLE comp_tab\n");
      stmt.executeUpdate("DROP TABLE comp_tab");
      System.out.println("\n  COMMIT");
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    } 
  } // tbDrop
} // TbCompress
