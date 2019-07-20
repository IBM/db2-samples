//***************************************************************************
//   (c) Copyright IBM Corp. 2007 All rights reserved.
//   
//   The following sample of source code ("Sample") is owned by International 
//   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
//   copyrighted and licensed, not sold. You may use, copy, modify, and 
//   distribute the Sample in any form without payment to IBM, for the purpose of 
//   assisting you in the development of your applications.
//   
//   The Sample code is provided to you on an "AS IS" basis, without warranty of 
//   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
//   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
//   not allow for the exclusion or limitation of implied warranties, so the above 
//   limitations or exclusions may not apply to you. IBM shall not be liable for 
//   any damages you suffer as a result of using, copying, modifying or 
//   distributing the Sample, even if IBM has been advised of the possibility of 
//   such damages.
//***************************************************************************
//                                                            
//  SAMPLE FILE NAME: TrustedContext.java
//                                                                          
//  PURPOSE:  To demonstrate 
//                1. Creating a trusted Context object.
//                2. How to establish explicit trusted connection.
//                3. Authorizing switching of the user on a trusted connection.
//                4. Acquiring trusted context-specific privileges through Role inheritance.
//                5. Altering a trusted context object.
//                6. Dropping a trusted context object.
//                                                                          
//  PREREQUISITES: 
//                1. a) Database "testdb" must exist.
//                      Create the database using command given below:
//                      db2 "CREATE DATABASE testdb"
//                   b) Update the configuration parameter SVCENAME.
//                      db2 "update dbm cfg using svcename <TCP/IP port num>"
//                   c) Set communication protocol to TCP/IP.
//                      db2set DB2COMM=TCPIP
//                   d) Stop and start the DB2 instance.
//                      db2 terminate;
//                      db2stop;
//                      db2start;
//                2. Following users with corresponding passwords must exist 
//                   a) A user with SECADM authority on database.
//	                   padma with "padma123"  
//                      Grant SECADM authority to user "padma" commands given below:
//                         db2 "CONNECT TO testdb" 
//                         db2 "GRANT SECADM ON DATABASE TO USER padma"
//                         db2 "CONNECT RESET"
//                   b) A valid system authorization ID and passord.
//                         bob with "bob123"          
//                   c) Normal Users without SYSADM and DBADM authorities.
//                         joe with "joe123"
//                         pat with "pat123"
//                         mat with "mat123"
//                                                                                                  
//  EXECUTION: i)  javac TrustedContext.java  (compile the sample)
//             ii) java TrustedContext <serverName> <portNumber> <userid> <password>
//                 eg: java TrustedContext db2aix.ibm.com 30308 padma padma123
//                 userid and password that are passed must have the SECADM authority.
//                                                                          
//  INPUTS:    NONE
//                                                                          
//  OUTPUTS:  Successful establishment of trusted connection and switch user.
//                                                                          
//  OUTPUT FILE:  TrustedContext.out (available in the online documentation)      
//                                     
//  SQL Statements USED:
//         CREATE TRUSTED CONTEXT
//         ALTER TRUSTED CONTEXT
//         GRANT
//         CREATE TABLE 
//         CREATE ROLE
//         INSERT
//         UPDATE
//         DROP ROLE
//         DROP TRUSTED CONTEXT
//         DROP TABLE
//
//  JAVA CLASSES USED:
//         Statement
//         ResultSet
//         Connection
//         DB2ConnectionPoolDataSource
//         DB2PooledConnection
//         Properties
//
// *************************************************************************
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
// *************************************************************************/                       
//
//  SAMPLE DESCRIPTION                                                      
//
// /*************************************************************************
//  1. Connect to database and create the trusted context object.
//  2. Establish the explicit trusted connection and grant privileges to the roles.      
//  3. Switch the current user on the connection to a different user 
//     with and without authentication.
//  4. Switch the current user on the connection to an invalid user.
//  5. Alter the trusted context object after disabling it.
//  6. Drop the objects created for trusted context and roles.
// *************************************************************************/

// import the required classes 
import java.util.*;
import java.sql.*;
import java.io.*;
import java.net.InetAddress;
import com.ibm.db2.jcc.*;
import com.ibm.db2.jcc.DB2Connection;
import com.ibm.db2.jcc.DB2ConnectionPoolDataSource;

class TrustedContext
{
   public static void main (String[] args)
   { 
   try {  
      // Users and Passwords
      String authid = new String("bob");
      String authid_pwd = new String("bob123");
      String user1 = new String("joe");
      String user1_pwd = new String("joe123");
      String user2 = new String("pat");
      String user2_pwd = new String("pat123");
      String user3 = new String("mat");
      String user3_pwd = new String("mat123");

						
      // get the command line arguments
      String serverName = args[0];
      String portNumber = args[1];
      String userid = args[2];
      String password = args[3];
   
      // Local variables and classes 
      String ctname = new String("CTX1");  
      String databaseName = new String("testdb");
      Connection con = null;
      Statement stmt;
      ResultSet rs=null;
      String url,newUser,newPassword;
      String sqlid = " ";
      Object[] objects = new Object[6];
      byte[] cookie = new byte[1];
      com.ibm.db2.jcc.DB2ConnectionPoolDataSource ds1 = 
               new com.ibm.db2.jcc.DB2ConnectionPoolDataSource();
      java.util.Properties properties = new java.util.Properties();
      com.ibm.db2.jcc.DB2PooledConnection pooledCon = 
               (com.ibm.db2.jcc.DB2PooledConnection)objects[0];

      // load the driver
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
      url = "jdbc:db2://"+serverName+":"+portNumber+"/testdb";
    
      System.out.println("\n This sample will demonstrate "
                       + "\n\t 1. Creating a trusted Context object. "
                       + "\n\t 2. How to establish explicit trusted connection. "
                       + "\n\t 3. Authorizing the switching of the user on a trusted connection. "
                       + "\n\t 4. Acquiring trusted context-specific privileges through Role inheritance. "
                       + "\n\t 5. Altering a trusted context object. "
                       + "\n\t 6. Dropping a trusted context object. ");
      System.out.println("\n");

      // connect to the database
      try {
      con = DriverManager.getConnection(url,userid,password );
      System.out.println(userid + " connected to the database");
      con.setAutoCommit(true); 
      }
      catch(Exception ex)
      {
       System.out.println(" Connect to database failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      // Create roles 
      try {
      stmt = con.createStatement();
      stmt.execute("CREATE ROLE def_role");
      System.out.println("\n Role def_role created ");
      stmt.execute("CREATE ROLE tc_role");
      System.out.println("\n Role tc_role created ");
      stmt.execute("grant role def_role to user "+user1);
      stmt.execute("grant role tc_role to user "+user2);
      stmt.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Role creation failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      // Create the trusted context object with 
      // system authorization id as authid
      // for IP domain name containing serverName
      // with no default role 
      // users as  user1 with authentication and 
      // user2 having tc_role privileges and without authentication
      try {
      stmt = con.createStatement();
      String sql = "CREATE TRUSTED CONTEXT " + ctname
                   + " BASED UPON CONNECTION USING SYSTEM AUTHID " + authid
                   + " ATTRIBUTES ( ADDRESS '" + serverName + "') "
                   + " DEFAULT ROLE def_role"
                   + " ENABLE "
                   + " WITH USE FOR " + user1 + " WITH AUTHENTICATION, "
                   + user2 + " ROLE tc_role WITHOUT AUTHENTICATION"; 
      stmt.execute(sql);
      System.out.println();
      System.out.println(sql);
      System.out.println(" Trusted context object "+ ctname +" Created" );
      stmt.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Trusted context object " + ctname + " creation failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }
       
      // Add a comment to the Trusted context object 
      try
      {
      stmt = con.createStatement();
      stmt.execute("COMMENT ON TRUSTED CONTEXT ctx1 IS 'Trusted Context object used to establish explicit trusted connection!'");
      con.commit();
      stmt.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Adding a comment to the Trusted context object failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      try
      {
      String remarks = "";

      System.out.println();
      System.out.println("SELECT remarks FROM SYSIBM.SYSCOMMENTS");
      System.out.println(
        "    COMMENT ON TRUSTED CONTEXT\n" +
        "    -----------------------------\n");

      stmt = con.createStatement();
      // perform a SELECT
      rs = stmt.executeQuery("SELECT remarks FROM SYSIBM.SYSCOMMENTS");

      // retrieve and display the result from the SELECT statement
      while (rs.next())
      {
        remarks = rs.getString(1);
        System.out.println( "    " + remarks);
      }
      rs.close();
      stmt.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Trusted context object comment not created");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }
 
      // close the connection
      con.close();
      
      // establish explicit trusted connection and switch user id to a different user

      /**************************************************
      * Create datasource for connection to database.  
      **************************************************/

      try
      {    
      ds1.setServerName(serverName);
      ds1.setPortNumber(Integer.valueOf(portNumber).intValue());
      ds1.setDatabaseName(databaseName);
      ds1.setDriverType (4);
      }
      catch(Exception ex)
      {
       System.out.println(" Datasource creation failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      /************************************
      * Establish the explicit trusted connection
      *************************************/
         
      try
      {
      System.out.println("\n Establish explicit trusted connection using "+ authid +"...");
      objects = ds1.getDB2TrustedPooledConnection(authid, authid_pwd, properties); 
      pooledCon = (com.ibm.db2.jcc.DB2PooledConnection)objects[0];    
      System.out.println(" Established explicit trusted connection for "+ authid );
      cookie = (byte[])objects[1];    
      newUser = null;
      newPassword = null;
      rs = null;
      sqlid = null;
      stmt = null;
      }
      catch(Exception ex)
      {
       System.out.println(" Failed to establish trusted connection for " + authid );
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      /**************************************************************
      * Connect as authid to check explicit trusted connection worked or not
      * authid is the system authorization ID defined for the trusted context
      ***************************************************************/
      newUser = authid;
      newPassword = authid_pwd;
         
      try
      {
      System.out.println("\n Get connection as "+ newUser +" ...");
      con = pooledCon.getDB2Connection(cookie, newUser, newPassword,
                                                      null, null, null, properties);

      stmt = con.createStatement();
      System.out.println("\t Check who is currently connected to database, should be "+ newUser +" ...");
      rs = stmt.executeQuery("values SYSTEM_USER");
      rs.next();
      sqlid = rs.getString(1);
      System.out.println("\tCurrent user connected to database = " + sqlid);
      if((sqlid.trim()).equalsIgnoreCase(newUser.trim()))
      {
      System.out.println(" Connected as "+newUser);
      System.out.println(" Trusted connection worked ");
      }
      else
      {
      System.out.println(" Trusted connection failed ");
      }
      }
      catch(Exception ex)
      {
       System.out.println(" Trusted connection for "+ newUser +" failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      // Create a table and populate the table
      Statement stmt1 = con.createStatement();
      try
      { 
      stmt1.executeUpdate("CREATE TABLE test.tc_emp_table (emp_no INT, emp_name VARCHAR (20), emp_sal DECIMAL)");
      stmt1 = con.createStatement();
      stmt1.executeUpdate("INSERT INTO test.tc_emp_table VALUES(100, 'Padma Kota', 30000)");
      stmt1.executeUpdate("INSERT INTO test.tc_emp_table VALUES(200, 'Kathy Smith',20000)");
      System.out.println("\n Created and Inserted data into table test.tc_emp_table using " + sqlid );
      }
      catch(Exception ex)
      {
       System.out.println("\n Failed to create table test.tc_emp_table and populate it");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      // Grant privileges to the roles. 
      try
      {
      // Grant SELECT privilege on this table to the role def_role
      stmt1.execute("GRANT SELECT ON TABLE test.tc_emp_table TO ROLE def_role");
      System.out.println(" Granted SELECT privilege on table test.tc_emp_table to def_role ");
      // Grant UPDATE privilege on this table to the role tc_role
      stmt1.execute("GRANT UPDATE ON TABLE test.tc_emp_table TO ROLE tc_role");
      System.out.println(" Granted UPDATE privilege on table test.tc_emp_table to tc_role ");
      stmt1.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Failed to grant privileges on the table test.tc_emp_table");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      /*************************************************************
      * Switch to new user user1 under a trusted connection by 
      * providing authentication information.
      * user1 is explicitly defined as a user of the trusted context
      **************************************************************/
       
      newUser = user1;
      newPassword = user1_pwd;
      
      try
      {  
      System.out.println("\n Attempt switch user to "+newUser+" ...");
      con = pooledCon.getDB2Connection(cookie,newUser, newPassword,
                                                      null, null, null, properties);
      stmt = con.createStatement();
      System.out.println("\t Check who is currently connected to database, should be "+ newUser +" ...");
      rs = stmt.executeQuery("values SYSTEM_USER");
      rs.next();
      sqlid = rs.getString(1);
      System.out.println("\tCurrent user connected to database = " + sqlid);
      if((sqlid.trim()).equalsIgnoreCase(newUser.trim()))     
      {
      System.out.println(" Connected as "+newUser);
      System.out.println(" Success on switch user for "+newUser+
                         " by providing authentication information");
      }
      else
      {
      System.out.println(" Switch user failed ");
      }  
      rs.close();
      }
      catch(Exception ex)
      {
      System.out.println(" Switch user for " +newUser+" failed ");
      if (ex instanceof java.sql.SQLException)
      {
        System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
      }
      ex.printStackTrace();
      }

      // check whether the user inherited trusted context-specific default privileges
      try
      {
      stmt = con.createStatement();
      rs = stmt.executeQuery("SELECT emp_name FROM test.tc_emp_table where emp_no = 100 ");
      System.out.println("\n Select emp_name from table tc_emp_table... ");
      while (rs.next())
      {
        String name = rs.getString(1);
        System.out.println("\t" + name);
      }
      rs.close();
      System.out.println(" User "+ sqlid +" has inherited trusted context-specific default privileges");
      }
      catch(Exception ex)
      {
       System.out.println(" Failed to inherit trusted context-specific privileges ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      } 

      /**********************************************************************
      * Switch to new user user2 under a trusted connection without 
      * providing authentication information.
      * Update the table as user2 has UPDATE privilege on the table. 
      ***********************************************************************/

      newUser = user2;

      //  Connect to database not from trusted conection and try to update the table
      //  user2 should not be able to update the table 
      try {
      // connect to the database
      Connection con1 = DriverManager.getConnection(url,user2,user2_pwd );
      System.out.println(user2 + " Connected to the database not from trusted connection");
      stmt = con1.createStatement();
      System.out.println("\n Update table tc_emp_table.... ");
      stmt.executeUpdate("UPDATE test.tc_emp_table set emp_sal = 38000 where emp_no = 200");
      System.out.println("\n Updated table tc_emp_table");
      con1.close();
      }
      catch (SQLException sqle)
      {
      System.out.println(" Update table failed ");
      }     

      try
      {
      System.out.println("\n Attempt switch user to "+newUser+" ...");
      con = pooledCon.getDB2Connection(cookie,newUser, null,
                                                      null, null, null, properties);
      stmt = con.createStatement();
      System.out.println("\t Check who is currently connected to database, should be "+ newUser +" ...");
      rs = stmt.executeQuery("values SYSTEM_USER");
      rs.next();
      sqlid = rs.getString(1);
      System.out.println("\tCurrent user connected to database = " + sqlid);     
      if((sqlid.trim()).equalsIgnoreCase(newUser.trim())) 
      {
      System.out.println(" Connected as "+newUser);
      System.out.println(" Success on switch user for "+newUser+
                         " without providing authentication information");
      }
      else
      {
      System.out.println(" Switch user failed ");
      }
      }
      catch(Exception ex)
      {
       System.out.println(" Switch user failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      } 

      // check whether the user inherited trusted context-specific privileges
      try
      {
      stmt = con.createStatement();
      stmt.executeUpdate("UPDATE test.tc_emp_table set emp_sal = 38000 where emp_no = 200");
      System.out.println("\n Updated table tc_emp_table");
      System.out.println(" User "+ sqlid +" has inherited trusted context-specific privileges");
      }
      catch(Exception ex)
      {
       System.out.println(" Failed to inherit trusted context-specific privileges ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      /*************************************************************
      * Switch to user authid under a trusted connection to drop 
      * the objects created.
      **************************************************************/

      newUser = authid;
      newPassword = authid_pwd;

      try
      {
      System.out.println("\n Attempt switch user to "+newUser+" ...");
      con = pooledCon.getDB2Connection(cookie,newUser, newPassword,
                                                      null, null, null, properties);
      stmt = con.createStatement();
      System.out.println("\t Check who is currently connected to database, should be "+ newUser +" ...");
      rs = stmt.executeQuery("values SYSTEM_USER");
      rs.next();
      sqlid = rs.getString(1);
      System.out.println("\tCurrent user connected to database = " + sqlid);
      if((sqlid.trim()).equalsIgnoreCase(newUser.trim()))
      {
      System.out.println(" Connected as "+newUser);
      System.out.println(" Success on switch user for "+newUser+
                         " by providing authentication information");
      }
      else
      {
      System.out.println(" Switch user failed ");
      }
      rs.close();
      }
      catch(Exception ex)
      {
      System.out.println(" Switch user failed ");
      if (ex instanceof java.sql.SQLException)
      {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
      }
      ex.printStackTrace();
      }
 
      // Drop the table created 
      try
      {
      stmt = con.createStatement();
      System.out.println(" DROP the tables...");
      System.out.println(" DROP TABLE test.tc_emp_table");
      stmt.execute(" DROP TABLE test.tc_emp_table");
      stmt.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Alter trusted context  failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      /*************************************************************
      * Switch to a new user who is not defined as a user of the 
      * trusted context and this switch request made is not allowed 
      **************************************************************/

      newUser = user3;
      newPassword = user3_pwd;

      try
      {
      System.out.println("\n Attempt switch user to user "+newUser+" ...");
      con = pooledCon.getDB2Connection(cookie,newUser, newPassword,
                                                      null, null, null, properties);
      stmt = con.createStatement();
      System.out.println("\t Check who is currently connected to database, should be "+ newUser +" ...");
      rs = stmt.executeQuery("values SYSTEM_USER");
      rs.next();
      sqlid = rs.getString(1);
      System.out.println("\tCurrent user connected to database = " + sqlid);
      if((sqlid.trim()).equalsIgnoreCase(newUser.trim()))
      {
      System.out.println(" Connected as "+newUser);
      System.out.println(" Success on switch user for "+newUser);
      }
      else
      {
      System.out.println(" Switch user failed ");
      }
      }
      catch(Exception ex)
      {
       System.out.println(" Switch user failed ");
       System.out.println(" This is an Expected error!! ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      /************************************************
      * Close open connections
      ***********************************************/
      finally{    
              System.out.println("\n Close open connections");
              con.close();
             }  
    
      /*******************************************************
      * ALTER TRUSTED CONTEXT 
      ******************************************************/
      // connect to the database
      try {
      con = DriverManager.getConnection(url,userid,password );
      System.out.println(userid + " Connected to the database");
      con.setAutoCommit(true); 
      }
      catch (SQLException sqle)
      {
      System.out.println(" Connect to database failed ");
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      }     

      try
      {
      // Alter the trusted context to add new attributes
      stmt = con.createStatement();
      // Disable the trusted context object
      System.out.println("\n Disable the trusted context object");
      String st = "ALTER TRUSTED CONTEXT " + ctname + " ALTER DISABLE";
      stmt.execute(st);
      System.out.println(st);
      System.out.println("\n Alter the trusted context ");
      st = "ALTER TRUSTED CONTEXT " + ctname + " ADD USE FOR PUBLIC WITH AUTHENTICATION";
      stmt.execute(st);
      System.out.println(st); 
      stmt.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Alter trusted context failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }

      // Drop the trusted context object and role
      try
      {
      stmt = con.createStatement(); 
      // Drop the trusted context 
      System.out.println("\n Drop the trusted context... ");
      System.out.println(" DROP TRUSTED CONTEXT " + ctname);    
      stmt.execute(" DROP TRUSTED CONTEXT " + ctname);
      // Drop the role
      System.out.println("\n Drop the roles...");
      System.out.println(" DROP ROLE tc_role ");   
      stmt.execute(" DROP ROLE tc_role ");
      System.out.println(" DROP ROLE def_role ");   
      stmt.execute(" DROP ROLE def_role ");
      stmt.close();
      }
      catch(Exception ex)
      {
       System.out.println(" Alter trusted context  failed ");
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
      }
      
      // Close the connection
      con.close();   
    }
    catch(Exception ex)
    {
       if (ex instanceof java.sql.SQLException)
       {
         System.out.println("error code: " + ((java.sql.SQLException)(ex)).getErrorCode());
       }
       ex.printStackTrace();
    }
  } // main
} // TrustedContext

