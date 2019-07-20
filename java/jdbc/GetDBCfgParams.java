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
// SOURCE FILE NAME: GetDBCfgParams.java
//
// SAMPLE: Use the view SYSIBMADM.DBCFG to retrieve a 
//         database configuration parameter.
//
// The sample should be run using the following steps:
//         1. Create and populate the "sample" database 
//            with the following command:
//            db2sampl
//
//         2. Compile the program with the following command:
//            javac GetDBCfgParams.java Util.java
//
//         3. Run this sample with the following command:
//            java GetDBCfgParams <configuration parameter names>
//
// JAVA 2 CLASSES USED:
//         Statement
//         ResultSet
//
// Class used from Util.java are:
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
// OUTPUT FILE: GetDBCfgParams.out (available in the online documentation)
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

class GetDBCfgParams
{
  public static void main(String argv[])
  {    
   
    System.out.print("--------------------------------------------------"); 
    System.out.println("----------------------------------------"); 
    System.out.print("THIS SAMPLE SHOWS HOW TO SELECT THE DB CONFIGURATION");
    System.out.println(" PARAMETERS FROM SYSIBMADM.DBCFG");
    System.out.print("--------------------------------------------------");    
    System.out.println("----------------------------------------");    
    System.out.println();
    Connection con = null;
    Statement stmt = null; 
    ResultSet rs = null;

    if (argv.length < 1)
    {
      System.out.print("Missing input arguments. Enter one or more ");
      System.out.println("configuration parameter names.");
    }
    else
    {           
      try
      {
        // initialize DB2Driver and establish database connection.
        Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
        con = DriverManager.getConnection("jdbc:db2:SAMPLE");

        // create the SQL statement and execute.
        stmt = con.createStatement();
  
        String whereClause = "WHERE NAME IN (";
        
        for (int i = 0; i < argv.length; i++)
        {
          whereClause += "'" + argv[i].trim() + "',";
        }
        
        whereClause = whereClause.substring(0, whereClause.length()-1) + ")";
 
        String stmtText = "SELECT NAME, VALUE, DEFERRED_VALUE, DATATYPE, "+
                          "DBPARTITIONNUM FROM  SYSIBMADM.DBCFG " + 
                          whereClause;
                          
        System.out.println(stmtText);

        rs = stmt.executeQuery(stmtText);

        while (rs.next()) 
        {        
          String paramName = rs.getString("NAME").trim();
          String paramValue = rs.getString("VALUE");
          String paramDeferredValue = rs.getString("DEFERRED_VALUE");
          String paramType = rs.getString("DATATYPE").trim();
          String partitionNum = rs.getString("DBPARTITIONNUM");
        
          paramValue = (paramValue == null) ? "" : paramValue.trim();
          paramDeferredValue = (paramDeferredValue == null) ? 
                                "" : paramDeferredValue.trim();
          partitionNum = (partitionNum == null) ? "" : partitionNum.trim();
        
          System.out.println();
          System.out.println("Parameter Name            = " + paramName);
          System.out.println("Parameter Value           = " + paramValue);
          System.out.print("Parameter Deferred Value  = ");
          System.out.println(paramDeferredValue);
          System.out.println("Parameter Data Type       = " + paramType);
          System.out.println("Database partition number = " + partitionNum);
                        
          // cast parameter value to appropriate type if needed.
          if (paramType.equals("INTEGER")) 
          {
            int value = Integer.parseInt(paramValue);
          }
          else if (paramType.equals("BIGINT")) 
          {
            long value = Long.parseLong(paramValue);
          }
          else if (paramType.equals("DOUBLE"))
          {
            double value = Double.parseDouble(paramValue);
          }
          else if (paramType.startsWith("VARCHAR"))
          {
            String value = paramValue;
          }
        }
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
          // close the resultset
          rs.close();      

          // close the statement
          stmt.close();
    
          // close the connection
          con.close();   
        }
        catch (Exception x)
        { 
          System.out.print("\n Unable to Rollback/Disconnect ");
          System.out.println("from 'sample' database"); 
        }
      }
    }
  } // main
} // GetDBCfgParams
