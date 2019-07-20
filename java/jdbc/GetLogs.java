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
//  SOURCE FILE NAME: GetLogs.java
//
//  SAMPLE: How to get the customer view of diagnostic log file entries
//
//  This sample shows:
//    1. How to retrieve messages from the notification log starting
//       at a specified point in time.
//    2. How to retrieve messages from the notification log written
//       over the last week.
//    3. How to get all critical log messages logged in the last 24
//       hours using the PDLOGMSGS_LAST24HOURS view.
//
//  SQL STATEMENTS USED:
//    SELECT
//    TERMINATE
//
// JAVA 2 CLASSES USED:
//         Statement
//         ResultSet
//
// Classes used from Util.java are:
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
//  OUTPUT FILE: GetLogs.out (available in the online documentation)
//  Output will vary depending on the JDBC driver connectivity used.
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

class GetLogs
{
  public static void main(String argv[])
  {
    String argvDate = null;
    String argvTime = null;
    String alias = null;
    String userId = null;
    String password = null;
    String url = null;
    Connection con = null;

    try
    {
      // check and assign command line arguments
      switch (argv.length)
      {
        case 2:
          alias = "sample";
          userId = "";
          password = "";
          argvDate = argv[0];
          argvTime = argv[1];
          break;
       
        case 3:
          alias = argv[2];
          userId = "";
          password = "";
          argvDate = argv[0];
          argvTime = argv[1];
          break;

        case 5:
          alias = argv[2];
          userId = argv[3];
          password = argv[4];
          argvDate = argv[0];
          argvTime = argv[1];
          break;
 
        default:
          System.out.println(
            "USAGE: GetLogs <TimeStamp> [dbname] [userid password]\n" + 
            "  Timestamp Format: YYYY-MM-DD  HOUR:MINUTE:SECOND" +
            "  Example1: GetLogs 2005-12-22 06.44.44\n" +
            "  Example2: GetLogs 2005-12-22 06.44.44 <dbname>\n" +
            "  Example3: GetLogs 2005-12-22 06.44.44 <dbname> <userID> <passwd>\n");
        System.exit(0);
      }

      url = "jdbc:db2:" + alias;
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
      con = DriverManager.getConnection( url );

      System.out.println();
      System.out.println(
        " THIS SAMPLE SHOWS HOW TO RETRIEVE NOTIFICATION LOGS MESSAGES.\n");

      // Retrieve all the notification messages written after the specified
      // timestamp. If NULL is specified as the input timestamp to 
      // PD_GET_LOG_MSGS UDF, then all the entries will be returned.
      getPdLogMesgs(con, argvDate, argvTime);

      // Retrieve all notification messages written in the last week from all
      // partitions in chronological order.
      getPdLogMesgsWeek(con);

      // Get all critical log messages logged in the last 24 hours, order by
      // most recent
      getPdLogMesgs24Hours(con);

      // disconnect from 'sample' database
      con.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // main

  // Retrieve all the notification messages written after 
  // the specified timestamp
  static void getPdLogMesgs(Connection con, String date, String time)
  {
    try
    {
      Statement stmt = con.createStatement();

      System.out.println(
        "--------------------------------------------------------------\n" +
        "NOTIFICATION MESSAGES STARTING AT A SPECIFIED POINT IN TIME \n" +
        "FROM ALL PARTITIONS\n" +
        "--------------------------------------------------------------\n");

      System.out.println(
        "SELECT timestamp,\n" +
        "  instancename,\n" +
        "  dbpartitionnum,\n" +
        "  dbname,\n" +
        "  processname,\n" +
        "  appl_id,\n" +
        "  msgtype,\n" +
        "  msgseverity,\n" +
        "  msg \n" +
        "FROM TABLE ( PD_GET_LOG_MSGS( TIMESTAMP('2005-12-22', '06.44.44') ) )\n" +
        "AS t ORDER BY TIMESTAMP;\n\n" );

      String query = "SELECT timestamp, instancename, dbpartitionnum, " + 
                     "  dbname, processname, appl_id, msgtype, msgseverity, " + 
                     "  msg FROM TABLE (PD_GET_LOG_MSGS (TIMESTAMP('" +
                       date + "' , '" +
                       time + "' ))) AS t ORDER BY TIMESTAMP";

      ResultSet rs = stmt.executeQuery(query);

      while (rs.next())
      {
        System.out.println("TimeStamp        : " + rs.getString(1) + "\n" + 
                           "Instance Name    : " + rs.getString(2) + "\n" +
                           "DBPartition No   : " + rs.getInt(3) + "\n" + 
                           "DB Name          : " + rs.getString(4) + "\n" +
                           "ProcessName      : " + rs.getString(5) + "\n" + 
                           "Application ID   : " + rs.getString(6) + "\n" +
                           "Message Type     : " + rs.getString(7) + "\n" + 
                           "Message Severity : " + rs.getString(7) + "\n" + 
                           "Message          : " + rs.getString(8) + "\n") ;
      }

      rs.close();
      stmt.close();
    }

    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // getPdLogMesgs

  // Retrieve all the notification messages written over the last week
  static void getPdLogMesgsWeek(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();

      System.out.println(
        "--------------------------------------------------------------\n" +
        "NOTIFICATION MESSAGES WRITTEN IN THE LAST WEEK FROM \n" +
        "FROM ALL PARTITIONS\n" +
        "--------------------------------------------------------------\n");

      System.out.println(
        "SELECT timestamp,\n" +
        "  instancename,\n"  + 
        "  dbpartitionnum,\n" +
        "  dbname,\n" +
        "  processname,\n" +
        "  appl_id,\n" +
        "  msgtype,\n" +
        "  msgseverity,\n" +
        "  msg \n" +
        "FROM TABLE ( PD_GET_LOG_MSGS( current_timestamp - 7 days) )\n" +
        "AS t ORDER BY TIMESTAMP;\n");

      String query = "SELECT timestamp, instancename, " + 
                     "dbpartitionnum, dbname, processname, appl_id, " +
                     "msgtype, msgseverity, msg FROM TABLE ( PD_GET_LOG_MSGS" +
                     "( current_timestamp - 7 days ) ) AS t ORDER BY TIMESTAMP";
      
      ResultSet rs = stmt.executeQuery(query);

      while (rs.next())
      {
        System.out.println("TimeStamp        : " + rs.getString(1) + "\n" +
                           "Instance Name    : " + rs.getString(2) + "\n" +
                           "DBPartition No   : " + rs.getInt(3) + "\n" +
                           "DB Name          : " + rs.getString(4) + "\n" +
                           "ProcessName      : " + rs.getString(5) + "\n" +
                           "Application ID   : " + rs.getString(6) + "\n" +
                           "Message Type     : " + rs.getString(7) + "\n" +
                           "Message Severity : " + rs.getString(7) + "\n" +
                           "Message          : " + rs.getString(8) + "\n") ;
      }
 
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // getPdLogMesgsWeek

  // Retrieve all the notification messages written in the last 24 hours 
  static void getPdLogMesgs24Hours(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();

      System.out.println(
        "--------------------------------------------------------------\n" +
        "NOTIFICATION MESSAGES WRITTEN OVER LAST 24 HOURS FROM\n" +
        "FROM ALL PARTITIONS\n" +
        "--------------------------------------------------------------\n");

      System.out.println(
        "SELECT timestamp,\n" +
        "  instancename,\n" +
        "  dbpartitionnum,\n" +
        "  dbname,\n" +
        "  processname,\n" +
        "  appl_id,\n" +
        "  msgtype,\n" +
        "  msgseverity,\n" +
        "  msg \n" +
        "FROM SYSIBMADM.PDLOGMSGS_LAST24HOURS WHERE msgseverity = 'C'\n" +
        "ORDER BY TIMESTAMP DESC;\n" );

      String query = "SELECT timestamp, instancename, dbpartitionnum, " + 
                     "dbname, processname, appl_id, msgtype," +
                     "msgseverity, msg FROM SYSIBMADM.PDLOGMSGS_LAST24HOURS " +
                     "WHERE msgseverity = 'C' ORDER BY TIMESTAMP DESC";
   
      ResultSet rs = stmt.executeQuery(query);

      while (rs.next())
      {
        System.out.println("TimeStamp        : " + rs.getString(1) + "\n" +
                           "Instance Name    : " + rs.getString(2) + "\n" +
                           "DBPartition No   : " + rs.getInt(3) + "\n" +
                           "DB Name          : " + rs.getString(4) + "\n" +
                           "ProcessName      : " + rs.getString(5) + "\n" +
                           "Application ID   : " + rs.getString(6) + "\n" +
                           "Message Type     : " + rs.getString(7) + "\n" +
                           "Message Severity : " + rs.getString(7) + "\n" +
                           "Message          : " + rs.getString(8) + "\n") ;
      }
  
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e) ;
      jdbcExc.handle();
    }
  } // getPdLogMesgs24Hours
} // GetLogs
