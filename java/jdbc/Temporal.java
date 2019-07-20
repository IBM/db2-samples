//***************************************************************************
// (c) Copyright IBM Corp. 2011 All rights reserved.
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
// SOURCE FILE NAME: Temporal.java
//
// SAMPLE: How to create a temporal table and perform insert, 
//         update and select data using parameter marker.
// Scenario : 
//  1) Customer takes loan from bank. The details of the loan like account number,  
// 		loan type, rate of interest, loan period and balance are stored in a table. 
//  2) The rate of interest will be updated and is applicable 
//      for future loan payments. The rate of interest for the previous date
// 		should be maintainned.
//  3) The history of these inserts and updates should be maintainned 
//        with the time of these changes.
//  4) When querying the data for reports the data should be fetched 
//        for a particular period of time.
//  5) The result of the query should exactly match the loan details for 
//      that particular point of time as it happened in history.
//  
// Solution :
// 1)	This Solution creates a loan_accounts_btt BI-Temporal 
//      table and loan_accounts_history_btt. 
// 2)	Inserts the loan details of customers in loan_accounts_btt 
//      and the history in loan_accounts_history_btt.
// 3)   The period for which the loan is taken becomes the temporal 
//      BUSINESS_TIME having begin and end dates.
// 4)	The period at which the actual changes happen for the data 
//      in the table is maintainnned by SYSTEM_TIME sysbegin and sysend TIMESTAMPs.
// 5)	The query will fetch data for different BUSINESS_TIME and SYSTEM_TIME.
// 6)	The CURRENT TEMPORAL SYSTEM_TIME and CURRENT TEMPORAL 
//      BUSINNESS_TIME special register 
//      sets the temporal table for the specified period mentionned by the 
//      register and any query without predicates will return data 
//      for that particular period.
// 7)	Temporal table thus helps to set automatic history maintanance by capturing 
//      each and every change to rows in the master with its corresponding 
//      history table using SYSTEM_TIME and BUSINESS_TIME 
//      and helps while generating reports.
//
// SQL Statements USED:
//         CREATE TABLE
//		   ALTER TABLE
//         INSERT
//         SELECT 
//		   UPDATE
//		   SET 
//         DROP TABLE
// 
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac Temporal.java
//
// Run: java Temporal <username> <pwd>
//	or
//      java Temporal <server_name> <port_num> <username> <pwd>
//        
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
import java.util.*;
import java.lang.*;

public class Temporal
{	

  //Creates Temporal tables and inserts data
  public void AddTemporal(Connection conn)
  {
    System.out.println("THIS SAMPLE DEMONSTRATES THE TEMPORAL TABLE FEATURE.");
    System.out.println("***************************************************");
    try
    {
      System.out.println("Creating a Bi-Temporal Table");
      System.out.println();
      System.out.println(
      "CREATE TABLE loan_accounts_btt (   \n" +
      "                               account_number     INTEGER NOT NULL, \n" +
      "                               loan_type          VARCHAR(10), \n" +
      "                               rate_of_interest   DECIMAL(5,2) NOT NULL,\n" +
      "                               balance            DECIMAL (10,2), \n" +
      "                               bus_begin          DATE NOT NULL, \n" +
      "                               bus_end            DATE NOT NULL, \n" +
      "                               system_begin       TIMESTAMP(12) \n" +
	  "                               NOT NULL IMPLICITLY HIDDEN, \n" +
      "                               system_end         TIMESTAMP(12)  \n" +
	  "                               NOT NULL IMPLICITLY HIDDEN, \n" +
      "                               PERIOD BUSINESS_TIME(bus_begin, bus_end) \n" +
      "                               ) ;\n\n" );

      Statement stmt1 = conn.createStatement();
      stmt1.executeUpdate(
      "CREATE TABLE loan_accounts_btt( " +
      "                              account_number     INTEGER NOT NULL, " +
      "                              loan_type          VARCHAR(10)," +
      "                              rate_of_interest   DECIMAL(5,2) NOT NULL, " +
      "                              balance            DECIMAL (10,2), " +
      "                              bus_begin          DATE NOT NULL, " +
      "                              bus_end            DATE NOT NULL, " +
      "                              system_begin       TIMESTAMP(12) " +
	  "                              NOT NULL IMPLICITLY HIDDEN, " +
      "                              system_end         TIMESTAMP(12)  " +
	  "                              NOT NULL IMPLICITLY HIDDEN, " +
      "                              PERIOD BUSINESS_TIME(bus_begin, bus_end)) ");
      stmt1.close();

      System.out.println("Creating a UNIQUE index " +
	    " with account_number and BUSINESS_TIME");

      System.out.println(
        "CREATE UNIQUE INDEX ix_loan_accounts \n" +
        " ON loan_accounts_btt (account_number, BUSINESS_TIME WITHOUT OVERLAPS);\n");

      Statement stmt2 = conn.createStatement();
      stmt2.executeUpdate(
        "CREATE UNIQUE INDEX ix_loan_accounts " +
        " ON loan_accounts_btt (account_number, BUSINESS_TIME WITHOUT OVERLAPS) " );
      stmt2.close();

      // Creating history table which maintains 
	  //history as the master table is modified
      System.out.println("Creating a history table " +
	    " for the loan_accounts_btt table.");
      System.out.println(
        "CREATE TABLE loan_accounts_btt_history \n" +
        " LIKE loan_accounts_btt    \n" );

      Statement stmt3 = conn.createStatement();
      stmt3.executeUpdate(
        "CREATE TABLE loan_accounts_btt_history " +
        " LIKE loan_accounts_btt  " );
      stmt3.close();

      System.out.println("INSERT data into the loan_accounts_btt " +
		" and loan_accounts_btt_history table");

      System.out.println("INSERT INTO loan_accounts_btt (account_number, " +
	    "loan_type,rate_of_interest, balance, system_begin,  \n" +
        " system_end, bus_begin, bus_end) \n" +
        " VALUES (2111, 'A21', 9.5, 559500, '2010-02-01-05.45.02', " +
	    "  '9999-12-31-00.00.00', '2009-11-01', '2013-11-01'), \n" +
        "  (2112, 'A10', 12, 450320, '2010-02-02-03.21.18',  " +
	    "  '9999-12-31-00.00.00', '2010-01-02', '2013-02-02'),   \n" +
        "  (2113, 'A21', 9, 100000, '2010-02-06-13.15.06',  " +
	    "  '9999-12-31-00.00.00', '2010-02-06', '2010-12-30'), \n" +
        "  (2114, 'A15', 10, 200000, '2010-02-07-22.20.15', " +
	    "  '9999-12-31-00.00.00', '2010-02-07', '2011-08-31')   \n" );

      System.out.println();
      Statement stmt4 = conn.createStatement();
      stmt4.executeUpdate(
        "INSERT INTO loan_accounts_btt (account_number,loan_type,rate_of_interest, " +
        " balance, system_begin, system_end, bus_begin, bus_end) " +
        " VALUES (2111, 'A21', 9.5, 559500, '2010-02-01-05.45.02',  " +
	    "  '9999-12-31-00.00.00', '2009-11-01', '2013-11-01'), " +
        "  (2112, 'A10', 12, 450320, '2010-02-02-03.21.18', " +
	    "  '9999-12-31-00.00.00', '2010-01-02', '2013-02-02'), " +
        "  (2113, 'A21', 9, 100000, '2010-02-06-13.15.06',  " +
	    "  '9999-12-31-00.00.00', '2010-02-06', '2010-12-30'), " +
        "  (2114, 'A15', 10, 200000, '2010-02-07-22.20.15', " +
	    "  '9999-12-31-00.00.00', '2010-02-07', '2011-08-31')" );
      stmt4.close();


      System.out.println();

      System.out.println(
        "INSERT INTO loan_accounts_btt_history (account_number, " +
	    " loan_type, rate_of_interest, balance,   \n" +
        " system_begin, system_end, bus_begin, bus_end)  \n " +
        " VALUES (2111, 'A21', 8, 669000, '2009-09-01-23.45.01', " +
	    "  '2009-10-01-14.33.08', '2009-08-01', '2013-11-01'),  \n" +
        "  (2111, 'A21', 8, 648000, '2009-10-01-14.33.08', " +
	    "  '2009-11-01-09.56.17', '2009-08-01', '2013-11-01'),  \n" +
        "  (2111, 'A21', 9.5, 625875, '2009-11-01-09.56.17', " +
	    "  '2009-12-01-07.03.18', '2009-11-01', '2013-11-01'),  \n" +
        "  (2111, 'A21', 9.5, 603750, '2009-12-01-07.03.18',  " +
	    "  '2010-01-01-00.00.00', '2009-11-01', '2013-11-01'),  \n" +
        "  (2111, 'A21', 9.5, 581625, '2010-01-01-00.00.00',  " +
	    "  '2010-02-01-05.45.02', '2009-11-01', '2013-11-01'), \n" +
        "  (2112, 'A10', 12, 468000, '2010-01-02-09.04.16', " +
	    "  '2010-02-02-03.21.18', '2010-01-02', '2013-02-02') \n"
      );

      Statement stmt11 = conn.createStatement();
      stmt11.executeUpdate(
        "INSERT INTO loan_accounts_btt_history (account_number, loan_type,  " +
        " rate_of_interest, balance,system_begin, system_end, bus_begin, bus_end) " +
        " VALUES (2111, 'A21', 8, 669000, '2009-09-01-23.45.01', " +
	    "  '2009-10-01-14.33.08', '2009-08-01', '2013-11-01'),  " +
        "  (2111, 'A21', 8, 648000, '2009-10-01-14.33.08',  " +
	    "  '2009-11-01-09.56.17', '2009-08-01', '2013-11-01'),  " +
        "  (2111, 'A21', 9.5, 625875, '2009-11-01-09.56.17',  " +
	    "  '2009-12-01-07.03.18', '2009-11-01', '2013-11-01'),  " +
        "  (2111, 'A21', 9.5, 603750, '2009-12-01-07.03.18',  " +
	    "  '2010-01-01-00.00.00', '2009-11-01', '2013-11-01'),  " +
        "  (2111, 'A21', 9.5, 581625, '2010-01-01-00.00.00',  " +
	    "  '2010-02-01-05.45.02', '2009-11-01', '2013-11-01'), " +
        "  (2112, 'A10', 12, 468000, '2010-01-02-09.04.16',  " +
	    "  '2010-02-02-03.21.18', '2010-01-02', '2013-02-02') "  );

      stmt4.close();

      System.out.println();
      System.out.println("Adding SYSTEM_TIME columns to loan_accounts_btt");
      System.out.println("ALTER TABLE loan_accounts_btt  \n" +
        " ALTER COLUMN system_begin SET GENERATED AS ROW BEGIN   \n" );

      Statement stmt5 = conn.createStatement();
      stmt5.executeUpdate("ALTER TABLE loan_accounts_btt  " +
        "ALTER COLUMN system_begin SET GENERATED AS ROW BEGIN  " );
      stmt5.close();

      System.out.println();

      System.out.println("ALTER TABLE loan_accounts_btt  \n" +
        "ALTER COLUMN system_end SET GENERATED AS ROW END    \n" );

      Statement stmt6 = conn.createStatement();
      stmt6.executeUpdate("ALTER TABLE loan_accounts_btt  " +
        "ALTER COLUMN system_end SET GENERATED AS ROW END  " );
      stmt6.close();

      System.out.println("ALTER loan_accounts_btt " +
	    " to include SYSTEM_TIME columns.");

      System.out.println("ALTER TABLE loan_accounts_btt  \n" +
        "ADD PERIOD SYSTEM_TIME (system_begin, system_end);   \n" );

      Statement stmt7 = conn.createStatement();
      stmt7.executeUpdate("ALTER TABLE loan_accounts_btt  " +
        "ADD PERIOD SYSTEM_TIME (system_begin, system_end)  " );
      stmt7.close();

      System.out.println("ALTER table loan_accounts_btt " +
	    " to add column trans_start");

      System.out.println("ALTER TABLE loan_accounts_btt " +
	    " ADD COLUMN trans_start TIMESTAMP(12)  \n" +
        " GENERATED AS TRANSACTION START ID IMPLICITLY HIDDEN;    \n" );

      Statement stmt8 = conn.createStatement();
      stmt8.executeUpdate("ALTER TABLE loan_accounts_btt " +
	    " ADD COLUMN trans_start TIMESTAMP(12)  " +
        " GENERATED AS TRANSACTION START ID IMPLICITLY HIDDEN  " );
      stmt8.close();

      System.out.println("ALTER table loan_accounts_btt_history " +
	    " to add column trans_start");

      System.out.println("ALTER TABLE loan_accounts_btt_history  \n " +
        "ADD COLUMN trans_start TIMESTAMP(12) IMPLICITLY HIDDEN;  \n" );

      Statement stmt9 = conn.createStatement();
      stmt9.executeUpdate("ALTER TABLE loan_accounts_btt_history   " +
        "ADD COLUMN trans_start TIMESTAMP(12) IMPLICITLY HIDDEN  " );
      stmt9.close();

      System.out.println("ALTER table loan_accounts_btt " +
	    " to add VERSIONING using loan_accounts_btt_history.");

      System.out.println("ALTER TABLE loan_accounts_btt  \n" +
        "ADD VERSIONING USE HISTORY TABLE loan_accounts_btt_history  \n" );

      Statement stmt10 = conn.createStatement();
      stmt10.executeUpdate("ALTER TABLE loan_accounts_btt  " +
        "ADD VERSIONING USE HISTORY TABLE loan_accounts_btt_history  " );
      stmt10.close();

      System.out.println("Set up done!!!!!");
      System.out.println();
    }
    catch(Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }

  }
  //Query Temporal tables for specified temporal SYSTEM_TIME and BUSINESS_TIME
  public void FetchTemporal(Connection conn,ResultSet rs)
  {
    try
    {
      //********************************************************************
      System.out.println();
      System.out.println("Query FOR BUSINESS_TIME AS OF " +
	    " 2011-12-01 using parameter marker");
      System.out.println();
      System.out.println("***********************************" +
	    "*************************************");
      System.out.println(
        "SELECT account_number,loan_type, rate_of_interest, bus_begin, " +
	    " bus_end, system_begin, system_end \n" +
        " FROM loan_accounts_btt \n" +
        " FOR BUSINESS_TIME AS OF  ? " );
      System.out.println("*****************************" +
	    "*******************************************");
      System.out.println();

      PreparedStatement pstmnt1 = conn.prepareStatement(
        "SELECT account_number,loan_type, rate_of_interest," +
	    " bus_begin, bus_end, system_begin, system_end " +
        " FROM loan_accounts_btt " +
        " FOR BUSINESS_TIME AS OF  ?" ) ;

      pstmnt1.setString(1, "2011-12-01");
      // execute the statement
      rs =  pstmnt1.executeQuery();
      displayTemporal(conn,rs);
      pstmnt1.close();

      //*************************************************************************
      System.out.println();
      System.out.println("Query FOR BUSINESS_TIME AS OF 2009-12-01 and " +
	    "SYSTEM_TIME AS OF 2009-10-01 using parameter marker");
      System.out.println();
      System.out.println("*******************************************" +
	    "*****************************");
      System.out.println(
        "SELECT account_number,loan_type, rate_of_interest, bus_begin, " +
	    " bus_end, system_begin, system_end \n" +
        " FROM loan_accounts_btt \n" +
        " FOR BUSINESS_TIME AS OF ? \n" +
        " FOR SYSTEM_TIME AS OF  ? \n"  );
      System.out.println("**************************************" +
	    "**********************************");
      System.out.println();

      pstmnt1 = conn.prepareStatement(
        "SELECT account_number,loan_type, rate_of_interest, bus_begin,  " +
	    " bus_end, system_begin, system_end " +
        " FROM loan_accounts_btt " +
        " FOR BUSINESS_TIME AS OF  ? " +
        " FOR SYSTEM_TIME AS OF   CAST(? AS TIMESTAMP)" ) ;

      pstmnt1.setString(1, "2009-12-01");
      pstmnt1.setString(2, "2009-10-01");

      // execute the statement

      rs =  pstmnt1.executeQuery();
      displayTemporal(conn,rs);
      pstmnt1.close();

      //***********************************************************************
      System.out.println();
      System.out.println("Query FOR SYSTEM_TIME FROM 0001-01-01 " +
	    " TO 9999-12-31 using parameter marker");
      System.out.println();
      System.out.println("**************************************" +
	  "**********************************");
      System.out.println(
        "SELECT account_number,loan_type, rate_of_interest, system_begin, " +
	    " system_end, bus_begin, bus_end \n" +
        " FROM loan_accounts_btt \n" +
        " FOR SYSTEM_TIME FROM ? TO ? \n" +
        " WHERE account_number = ? \n"  );
      System.out.println("***********************************" +
	  "*************************************");
      System.out.println();

      pstmnt1 = conn.prepareStatement(
        "SELECT account_number,loan_type, rate_of_interest, " +
	    " system_begin, system_end, bus_begin, bus_end " +
        " FROM loan_accounts_btt " +
        " FOR SYSTEM_TIME FROM CAST(? AS TIMESTAMP) TO CAST(? AS TIMESTAMP) " +
        " WHERE account_number =  ?" ) ;

      pstmnt1.setString(1, "0001-01-01");
      pstmnt1.setString(2, "9999-12-31");
      pstmnt1.setString(3, "2111");
      // execute the statement

      rs =  pstmnt1.executeQuery();
      displayTemporal(conn,rs);
      pstmnt1.close();

      //****************************************************************
      System.out.println();
      System.out.println("Query FOR BUSINESS_TIME BETWEEN 2009-06-01 " +
	    "TO 2010-01-02 using parameter marker");
      System.out.println();
      System.out.println("*******************************************" +
	  "*****************************");
      System.out.println(
        "SELECT account_number,loan_type, rate_of_interest, system_begin, " +
	    " system_end, bus_begin, bus_end \n" +
        " FROM loan_accounts_btt \n" +
        " FOR BUSINESS_TIME BETWEEN ? AND ?  \n"  );
      System.out.println("**********************************" +
	  "**************************************");
      System.out.println();

      pstmnt1 = conn.prepareStatement(
        "SELECT account_number,loan_type, rate_of_interest, system_begin, " +
	    " system_end, bus_begin, bus_end " +
        " FROM loan_accounts_btt " +
        " FOR BUSINESS_TIME BETWEEN ? AND ? " ) ;

      pstmnt1.setString(1, "2009-06-01");
      pstmnt1.setString(2, "2010-01-02");
      // execute the statement

      rs =  pstmnt1.executeQuery();
      displayTemporal(conn,rs);
      pstmnt1.close();

      //***********************************************************************
      System.out.println();
      System.out.println("Update FOR PORTION OF BUSINESS_TIME FROM  " +
	    "2010-03-01 TO 2010-09-01 using parameter marker");
      System.out.println();
      System.out.println("**************************************" +
	  "**********************************");
      System.out.println(
        "UPDATE loan_accounts_btt  \n" +
        " FOR PORTION OF BUSINESS_TIME FROM ? TO ? \n" +
        " SET rate_of_interest = ? \n" +
        " WHERE account_number = ?  \n"  );
      System.out.println("*********************************" +
	    "***************************************");
      System.out.println();

      pstmnt1 = conn.prepareStatement(
        "UPDATE loan_accounts_btt  " +
        " FOR PORTION OF BUSINESS_TIME FROM ? TO ? " +
        " SET rate_of_interest = ? " +
        " WHERE account_number = ? " ) ;

      pstmnt1.setString(1, "2010-03-01");
      pstmnt1.setString(2, "2010-09-01");
      pstmnt1.setString(3, "10");
      pstmnt1.setString(4, "2111");
      // execute the statement

      pstmnt1.executeUpdate();
      System.out.println("Update Done Successfully");
      pstmnt1.close();


      //***********************************************************************
      System.out.println();
      System.out.println("SET Special register CURRENT TEMPORAL BUSINESS_TIME");
      System.out.println();
      System.out.println("***********************************" +
	  "*************************************");
      System.out.println( "SET CURRENT TEMPORAL BUSINESS_TIME = '2011-01-01' \n"  );
      System.out.println("*********************************" +
	  "***************************************");
      System.out.println();

      pstmnt1 = conn.prepareStatement("SET CURRENT TEMPORAL BUSINESS_TIME = ?  ") ;

      pstmnt1.setString(1, "2011-01-01");

      // execute the statement

      pstmnt1.execute();
      System.out.println("Special register set Successfully");
      pstmnt1.close();

      //***********************************************************************
      System.out.println();
      System.out.println("SET Special register CURRENT TEMPORAL SYSTEM_TIME");
      System.out.println();
      System.out.println("*************************************" +
	  "***********************************");
      System.out.println( "SET CURRENT TEMPORAL SYSTEM_TIME = '2010-10-01' \n"  );
      System.out.println("************************************" +
	  "************************************");
      System.out.println();

      pstmnt1 = conn.prepareStatement("SET CURRENT TEMPORAL SYSTEM_TIME = ? ") ;

      pstmnt1.setString(1, "2010-10-01");

      // execute the statement
      pstmnt1.execute();
      System.out.println("Special register set Successfully");
      pstmnt1.close();


      //***********************************************************************
      System.out.println();
      System.out.println("Query loan_accounts_btt table " +
	    " after setting the Special register");
      System.out.println();
      System.out.println("*************************************" +
	    "***********************************");
      System.out.println(
        "SELECT  account_number,loan_type, rate_of_interest,  " +
	    " bus_begin, bus_end, system_begin, system_end \n" +
        " FROM loan_accounts_btt  \n"  );
      System.out.println("****************************" +
	    "********************************************");
      System.out.println();

      pstmnt1 = conn.prepareStatement(
        "SELECT  account_number,loan_type, rate_of_interest,  " +
	    " bus_begin, bus_end, system_begin, system_end " +
        " FROM loan_accounts_btt  " ) ;

      // execute the statement

      rs =  pstmnt1.executeQuery();
      displayTemporal(conn,rs);
      pstmnt1.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  }
  //Generate Resultsets for the query specified
  public void displayTemporal(Connection conn,ResultSet rs)
  {
    try
    {
      int acc_num;
      String loan_typ;
      double roi;
      String bus_beg;
      String bus_end;
      String sys_beg;
      String sys_end;
      System.out.println("----------------------------------------------------------" +
	    "---------------------------------------------------------------------------" +
	    "-------------");
      System.out.println(
        "Acc #  Loan Type  Rate of Interest       bus_begin            " +
	    "       bus_end           " + 
	    "          system_begin                      system_end\n" +
        "------ ---------  ----------------   ----------------   " +
	    "          ---------------               ------------------------   " +
	    "-------------------------");

      while (rs.next())
      {
        acc_num = rs.getInt(1);
        loan_typ = rs.getString(2);
        roi = rs.getDouble(3);
        bus_beg = rs.getString(4);
        bus_end = rs.getString(5);
        sys_beg = rs.getString(6);
        sys_end = rs.getString(7);

        System.out.println(
          Data.format(acc_num, 5)  + " " +
          Data.format(loan_typ, 10) + " " +
          Data.format(String.valueOf(roi), 20)   + " " +
          Data.format(bus_beg, 30) + " " +
          Data.format(bus_end, 30) + " " +
          Data.format(sys_beg, 30) + " " +
          Data.format(sys_end, 30));
      }
        rs.close();
    }
	catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }

  }
  //Drop the Database connection created
  static void Drop(Connection conn)
  {
    try
    {
      System.out.println();
      System.out.println("DROP TABLE loan_accounts_btt\n");
      Statement stmt = conn.createStatement();
      stmt.executeUpdate("DROP TABLE loan_accounts_btt");
      stmt.close();

      // Commit
      conn.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, conn);
      jdbcExc.handle();
    }
  }
  public static void main(String args[])
  {

    Temporal temp = new Temporal();
    try
    {
      // Obtain a Connection to the 'sample' database
      Db db = null;
      ResultSet rs = null;
      Connection conn = null ;
      db = new Db(args);
      db.connect();
      conn = db.con;

      temp.AddTemporal(conn);
      temp.FetchTemporal(conn,rs);
      temp.Drop(conn);
      conn.close();
    }
    catch(ClassNotFoundException cle)
    {
      System.out.println("  Driver class not found, please check the PATH" +
        " and CLASSPATH system variables to ensure they are correct");
    }
    catch(SQLException sqle)
    {
      System.out.println("  Could not open connection");
      sqle.printStackTrace();
    }
    catch(Exception ne)
    {
      System.out.println("  Unexpected Error");
      ne.printStackTrace();
    }
    System.out.println("Disconnect from 'sample' database.");
    System.out.println("Exiting...............");
  }

}

