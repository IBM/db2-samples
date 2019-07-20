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
// SOURCE FILE NAME: AdmCmdOnlineBackup.java
//
// SAMPLE: Use the stored procedure ADMIN_CMD to do 
//         Online Backup
//
// The sample should be run using the following steps:
//         1. Create the "sample" database using db2sampl command
//
//         2. Set the DB CFG parameter LOGARCHMETH1 to LOGRETAIN 
//    
//         3. Set the DB CFG parameter LOGARCHMETH2 to OFF 
//
//         4. Do an offline BACKUP of SAMPLE database
//
//         5. Compile the program with the following command:
//            javac AdmCmdOnlineBackup.java
//
//         6. Run this sample with the following command:
//            java AdmCmdOnlineBackup <path for backup>
//            The path being given for backup should be an absolute path.
//
// Note:   User needs either SYSADM, SYSCTRL or SYSMAINT authorization to set
//         the DB CFG parameters & for backing up the database.
//
//  JAVA 2 CLASSES USED:
//         CallableStatement
//         ResultSet
//
// Classes used from Util.java are:
//         JdbcException
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
//Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: AdmCmdOnlineBackup.out (available in the online 
//                                      documentation)
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

class AdmCmdOnlineBackup 
{
  public static void main(String argv[])
  {    
   
    System.out.print("THIS SAMPLE SHOWS HOW TO DO ONLINE BACKUP ");
    System.out.println("USING ADMIN_CMD.");
    Connection con = null;
    CallableStatement callStmt = null;
    ResultSet rs = null;
 
    if (argv.length < 1)
    {
      System.out.print("\n Usage: java AdmCmdOnlineBackup <absolute path"); 
      System.out.println(" for backup>\n");
    }
    else
    {           
      try
      {
        // initialize DB2Driver and establish database connection.
        Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();       
        con = DriverManager.getConnection("jdbc:db2:SAMPLE");

        // prepare the CALL statement for ADMIN_CMD
        String sql = "CALL SYSPROC.ADMIN_CMD(?)";
        callStmt = con.prepareCall(sql);
        
        // execute database backup to the specified path
        String param = "BACKUP DB SAMPLE TO " + argv[0].trim();

        // set the input parameter  
        callStmt.setString(1, param);

        System.out.println("\nCALL ADMIN_CMD('" + param + "')");
        // call the stored procedure
        callStmt.execute();
      
        // get the result set       
        rs = callStmt.getResultSet();
   
        if (rs.next())
        { 
          // getting the time taken for the database backup 
          String backupTime = rs.getString(1); 
          System.out.print("\nTimestamp for the backup image is = ");
          System.out.println(backupTime);
        }
 
        System.out.println("\nOnline backup completed successfully");        
      }
      catch(Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e);
        jdbcExc.handle();
      }
      finally
      {
        try
        {
          // close the resultset and callStmt
          rs.close();
          callStmt.close();

          // roll back any changes to the database made by this sample
          con.rollback();                                   

          // closing the connection
          con.close();
        }
        catch (Exception x)
        { 
          System.out.print("\n Unable to Rollback/Disconnect ");
          System.out.println("from 'sample' database");  
        }
      }
    } // else
  } // main
} // AdmCmdOnlineBackup 
