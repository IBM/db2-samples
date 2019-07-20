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
// SOURCE FILE NAME: DtInfo.java
//
// SAMPLE: How to get information about data types
//
// JAVA 2 CLASSES USED:
//         Connection
//         ResultSet
//         ResultSetMetaData
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
// OUTPUT FILE: DtInfo.out (available in the online documentation)
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

class DtInfo
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO GET INFO ABOUT DATA TYPES.");

      // connect to the 'sample' database
      db.connect();

      // Get information about the Data type
      infoGet(db.con);

      db.con.commit();

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  static void infoGet(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
        "----------------------------------------------------------\n" +
        "USE THE JAVA APIs:\n" +
        "  Connection.getMetaData()\n" +
        "  ResultSet.getTypeInfo()\n" +
        "  ResultSetMetaData.getMetaData()\n" +
        "TO GET INFO ABOUT DATA TYPES AND\n" +
        "TO RETRIEVE THE AVAILABLE INFO IN THE RESULT SET.");

      DatabaseMetaData dbMetaData = con.getMetaData();

      // Get a description of all the standard SQL types supported by
      // this database
      ResultSet rs = dbMetaData.getTypeInfo();

      // Retrieve the number, type and properties of the resultset's columns
      ResultSetMetaData rsMetaData = rs.getMetaData();

      // Get the number of columns in the ResultSet
      int colCount = rsMetaData.getColumnCount();
      System.out.println();
      System.out.println(
        "  Number of columns in the ResultSet = " + colCount);

      // Retrieve and display the column's name along with its type
      // and precision in the ResultSet
      System.out.println();
      System.out.println("  A LIST OF ALL COLUMNS IN THE RESULT SET:\n" +
                         "    Column Name         Column Type\n" +
                         "    ------------------- -----------");

      String colName, colType;
      for (int i = 1 ; i <= colCount ; i++)
      {
        colName = rsMetaData.getColumnName(i);
        colType = rsMetaData.getColumnTypeName(i);
        System.out.println(
          "    " + Data.format(colName, 19) +
          " "  + Data.format(colType, 13) + " ");
      }

      System.out.println();
      System.out.println(
        "  HERE ARE SOME OF THE COLUMNS' INFO IN THE TABLE ABOVE:\n"+
        "           TYPE_NAME          DATA_  COLUMN    NULL-   CASE_\n"+
        "                              TYPE   _SIZE     ABLE  SENSITIVE\n"+
        "                              (int)                          \n"+
        "    ------------------------- ----- ---------- ----- ---------");

      String typeName;
      int dataType;
      Integer columnSize;
      boolean nullable;
      boolean caseSensitive;

      // Retrieve and display the columns' information in the table
      while (rs.next())
      {
        typeName = rs.getString(1);
        dataType = rs.getInt(2);
        if (rs.getInt(7) == 1)
        {
          nullable = true;
        }
        else
        {
          nullable = false;
        }
        if (rs.getInt(8) == 1)
        {
          caseSensitive = true;
        }
        else
        {
          caseSensitive = false;
        }
	if (rs.getString(3) != null)
	{
          columnSize = Integer.valueOf(rs.getString(3));
          System.out.println(
            "    " + Data.format(typeName, 25) +
            " "  + Data.format(dataType, 5) +
            " "  + Data.format(columnSize, 10) +
            " "  + Data.format(String.valueOf(nullable), 5) +
            " "  + Data.format(String.valueOf(caseSensitive), 10));
	}
	else 
	// for the distinct data type, column size does not apply
	{
          System.out.println(
            "    " + Data.format(typeName, 25) +
            " "  + Data.format(dataType, 5) +
            "        n/a" +
            " "  + Data.format(String.valueOf(nullable), 5) +
            " "  + Data.format(String.valueOf(caseSensitive), 10));
	}
      }
      // close the result set
      rs.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  }
} // DtInfo

