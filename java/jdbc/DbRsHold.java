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
// SOURCE FILE NAME: DbRsHold.java
//
// SAMPLE: How to use result set cursor holdability in Universal JDBC driver.
//         The Universal JDBC driver implements the result set cursor holdability
//         APIS specified in JDBC3. To compile this sample, you need JDK1.4
//         or above; To run this sample, you need JRE1.4 or above.
//
// SQL Statements Used:
//         SELECT 
//         UPDATE
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
// OUTPUT FILE: DbRsHold.out (available in the online documentation)
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
import javax.sql.*;

public class DbRsHold 
{
  // The SQL statements used in this sample
  static final String sqlQuery = "SELECT empno, firstnme, lastname, salary "
                               + "  FROM employee WHERE workdept='A00'";
  static final String sqlUpdt = "SELECT empno, firstnme, lastname, salary\n"
                               + "  FROM employee WHERE workdept='A00'"
                               + "  FOR UPDATE of salary";
  static double salaryInc = 0.0;
    
  public static void main(String[] args)
  {
    if( args.length > 5 ||
        ( args.length == 1 &&
          ( args[0].equals( "?" )               ||
            args[0].equals( "-?" )              ||
            args[0].equals( "/?" )              ||
            args[0].equalsIgnoreCase( "-h" )    ||
            args[0].equalsIgnoreCase( "/h" )    ||
            args[0].equalsIgnoreCase( "-help" ) ||
            args[0].equalsIgnoreCase( "/help" ) ) ) )
    {
      System.out.println(
        "Usage: prog_name -u2 [dbAlias] [userId passwd] " + 
                "(use universal JDBC type 2 driver)\n" + 
        "       prog_name [dbAlias] server portNum userId passwd " + 
                "(use universal JDBC type 4 driver)");
      System.exit(0);
    }

      // Check the JRE version. JRE1.4 or above is required
      String jreVersion = System.getProperty("java.version");
      StringTokenizer token = new StringTokenizer(jreVersion, ".");
      String simpVersion = jreVersion;
        
      if(token.hasMoreTokens())
        simpVersion = token.nextToken();
      if(token.hasMoreTokens())
        simpVersion = simpVersion + "." + token.nextToken();

      float fVersion = (new Float(simpVersion)).floatValue();
      if(fVersion < (float)1.4)
      {
        System.out.println("To run this sample by using the Universal JDBC" +
                           " driver, you need JRE1.4 or above"); 
        System.exit(0);
      }
                            
      holdabilityOfUniversalDriver(args);
    
  } //main 
  
  static void holdabilityOfUniversalDriver(String[] args)
  {
    // Db class is used to connect to the database
    // Variable conn is the connection that shows cursor holdability changes
    // Variable connDd is the connection that displays data in the table
    Db db = null;
    Db dbDd = null;
    Connection conn = null;
    Connection connDd = null;
    
    try
    {
      db = new Db(args);
      conn = db.connect();
      dbDd = new Db(args);
      connDd = dbDd.connect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
    
    // Print different types of result set cursor holdability
    System.out.println(
      "-----------------------------------------------------------------\n" +
      "ResultSet.HOLD_CURSORS_OVER_COMMIT = " + 
      ResultSet.HOLD_CURSORS_OVER_COMMIT);
    System.out.println(
      "ResultSet.CLOSE_CURSORS_AT_COMMIT = " + 
      ResultSet.CLOSE_CURSORS_AT_COMMIT + "\n");

    // Set cursor holdability at connection level: HOLD_CURSORS_OVER_COMMIT
    System.out.println(
      "-----------------------------------------------------------------\n" +
      "Set cursor holdability at connection level: " + 
      "HOLD_CURSORS_OVER_COMMIT\n");
    salaryInc = 2000.00;
    setHoldabilityAtConnection(conn, 
                               ResultSet.HOLD_CURSORS_OVER_COMMIT, 
                               connDd);

    // Set cursor holdability at connection level: CLOSE_CURSORS_AT_COMMIT
    // SQLException is expected since the cursor will be closed at commit
    System.out.println(
      "-----------------------------------------------------------------\n" +
      "Set cursor holdability at connection level: " +
      "CLOSE_CURSORS_AT_COMMIT\n" +
      "'Result set closed' ERROR IS EXPECTED AFTER THE FIRST COMMIT\n");
    setHoldabilityAtConnection(conn, 
                               ResultSet.CLOSE_CURSORS_AT_COMMIT,
                               connDd);

    // Set cursor holdability at statement level: HOLD_CURSORS_OVER_COMMIT
    System.out.println(
      "-----------------------------------------------------------------\n" +
      "Set cursor holdability at statement level: " +
      "HOLD_CURSORS_OVER_COMMIT");
    salaryInc = -2000.0;
    setHoldabilityAtStatement(conn,
                              ResultSet.HOLD_CURSORS_OVER_COMMIT, 
                              connDd);

    // Set cursor holdability at statement level: CLOSE_CURSORS_AT_COMMIT
    // SQLException is expected since the cursor will be closed at commit
    System.out.println(
      "-----------------------------------------------------------------\n" +
      "Set cursor holdability at statement level: " +
      "CLOSE_CURSORS_AT_COMMIT\n" +
      "'Result set closed' ERROR IS EXPECTED AFTER THE FIRST COMMIT\n");
    setHoldabilityAtStatement(conn, 
                              ResultSet.CLOSE_CURSORS_AT_COMMIT, 
                              connDd);

    System.out.println(
      "-----------------------------------------------------------------");
      
    try
    {
      db.disconnect();
      dbDd.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
    
  } // holdabilityOfUniversalDriver

  // This method shows how to set cursor holdability at the connection level
  static void setHoldabilityAtConnection(Connection conn, 
                                         int holdability, 
                                         Connection connDd)
  {
    ResultSet rs = null;

    try
    {
      // Set cursor holdability at the connection level
      conn.setHoldability(holdability);

      // Print the cursor holdability of the connection
      System.out.println("Connection.getHoldability = " + 
                         conn.getHoldability());

      // Print the database MetaData supports for cursor holdability
      DatabaseMetaData dbMeta = conn.getMetaData();
      System.out.println("DatabaseMetaData.getResultSetHoldability =  " + 
                         dbMeta.getResultSetHoldability());
      System.out.println("  Supports HOLD_CURSORS_OVER_COMMIT = " + 
                         dbMeta.supportsResultSetHoldability(
                         ResultSet.HOLD_CURSORS_OVER_COMMIT));
      System.out.println("  Supports CLOSE_CURSORS_AT_COMMIT = " + 
                         dbMeta.supportsResultSetHoldability(
                         ResultSet.CLOSE_CURSORS_AT_COMMIT));

      // Create a statement with the holdability from the connection
      Statement stmt = conn.createStatement(ResultSet.TYPE_SCROLL_SENSITIVE,
                                            ResultSet.CONCUR_UPDATABLE);

      // Print the cursor holdability of the statement, 
      // which should be same as the connection's
      System.out.println("Statement.getResultSetHoldability = " + 
                         stmt.getResultSetHoldability() + "\n");

      // Execute the query and obtain the result set
      rs = stmt.executeQuery(sqlQuery);		

      // Update rows in the result set and commit one by one
      updateData(conn, rs, connDd);

    } 
    catch (Exception e)
    {     
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    } 
    finally
    {
      try
      {
        if (rs != null)
          rs.close();
      }
      catch(Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e);
        jdbcExc.handle();
      }
    }

  } // setHoldabilityAtConnection

  // This method shows how to set cursor holdability at the statement level
  static void setHoldabilityAtStatement(Connection conn, 
                                        int holdability, 
                                        Connection connDd)
  {
    ResultSet rs = null;

    try
    {
      // Print the cursor holdability of the connection
      System.out.println("Connection.getHoldability = " + 
                         conn.getHoldability());

      // Print the database MetaData supports for cursor holdability
      DatabaseMetaData dbMeta = conn.getMetaData();
      System.out.println("DatabaseMetaData.getResultSetHoldability =  " + 
                         dbMeta.getResultSetHoldability());
      System.out.println("  Supports HOLD_CURSORS_OVER_COMMIT = " + 
                         dbMeta.supportsResultSetHoldability(
                         ResultSet.HOLD_CURSORS_OVER_COMMIT));
      System.out.println("  Supports CLOSE_CURSORS_AT_COMMIT = " + 
                         dbMeta.supportsResultSetHoldability(
                         ResultSet.CLOSE_CURSORS_AT_COMMIT));
			
      // Set cursor holdability at the statement level
      // which can override the connection's
      PreparedStatement prepStmt = conn.prepareStatement(sqlQuery, 
                                     ResultSet.TYPE_SCROLL_SENSITIVE, 
                                     ResultSet.CONCUR_UPDATABLE, 
                                     holdability);

      // Print the cursor holdability of the statement, 
      // which can be different from the connection's
      System.out.println("Statement.getResultSetHoldability = " + 
                         (prepStmt).getResultSetHoldability() +
                         "\n");

      // Execute the query and obtain the result set
      rs = prepStmt.executeQuery();	

      // Update rows in the result set and commit one by one
      updateData(conn, rs, connDd);

    } 
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    } 
    finally
    {
      try
      {
        if (rs != null)
          rs.close();
      }
      catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e);
        jdbcExc.handle();
      }
    }

  } // setHoldabilityAtStatement

  // This method updates the rows in the result set and commit one by one.
  // Depending on the result set cursor holdability, the cursor is open or 
  // closed each commits.
  static void updateData(Connection conn, 
                         ResultSet rs, 
                         Connection connDd)
  {
    try
    {
      System.out.println("Original data:");
      displayData(connDd);
      int num = 1;
      
      while (rs.next())
      {
      	System.out.println("UPDATE salary: row " + num);
      	float salary = rs.getFloat("SALARY");
        rs.updateFloat("SALARY", (float)(salary + salaryInc));
        rs.updateRow();

        // If cursor holdability is HOLD_CURSORS_OVER_COMMIT,
        // the cursor is still open after commit;
        // If cursor holdability is CLOSE_CURSORS_AT_COMMIT,
        // the cursor is closed after commit.
        System.out.println("COMMIT updates: row " + num);
        conn.commit();
				
        displayData(connDd);
        num ++;
      }
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    } 

  } // updateData

  // This method is a helping method. It displays the content
  // in the EMPLOYEE table and reflects the data updates.
  static void displayData(Connection connDd)
  {
    ResultSet rs = null;

    try
    {
      // Create a prepared statement to execute the query
      PreparedStatement prepStmt = connDd.prepareStatement(sqlQuery, 
                                   ResultSet.TYPE_FORWARD_ONLY, 
                                   ResultSet.CONCUR_READ_ONLY);

      // Execute the query and obtain the result set
      rs = prepStmt.executeQuery();
	
      // Print the content of the result set
      System.out.println(
        "     EMPNO        NAME          SALARY\n" +
        "     ------ ------------------- ----------");
      while (rs.next())
        System.out.println("     " + Data.format(rs.getString("EMPNO"), 7) + 
                           Data.format(rs.getString("FIRSTNME") + " " + 
                                       rs.getString("LASTNAME"), 20) + 
                           rs.getFloat("SALARY"));
      System.out.println();
      connDd.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    } 
    finally
    {
      try
      {
        if (rs != null)
          rs.close();
       }
      catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e);
        jdbcExc.handle();
      }
    }

  } // displayData
 
} // DbRsHold
