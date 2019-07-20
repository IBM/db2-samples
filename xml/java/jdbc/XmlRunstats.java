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
// SOURCE FILE NAME: XmlRunstats.java
//
// SAMPLE: How to perform RUNSTATS on a table containing XML type columns.
//
// SQL STATEMENTS USED:
//         SELECT 
//         CONNECT
//         RUNSTATS
//
// JAVA 2 CLASSES USED:
//         Statement
//         ResultSet
//         File
//         FileWriter
//         Process
//         BufferedReader
//         InputStreamReader
//
// Classes used from Util.java are:
//         Db
//         JdbcException
//
//
// OUTPUT FILE: XmlRunstats.out (available in the online documentation)
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

import java.sql.*;
import java.lang.*;
import java.io.*;

public class XmlRunstats
{
  public static void main(String argv[]) 
  {
    try
    {
      Db db = new Db(argv);

      // connect to the 'sample' database
      db.connect();
      
      // call xmlRunstats that updates the statistics of customer table
      xmlRunstats(db.con);
      
      // disconnect from the 'sample' database
      db.disconnect();  
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main
  
  // call runstats on 'customer' table to update its statistics
  static void xmlRunstats(Connection conn) throws Exception
  {
    System.out.print(
      "\n-----------------------------------------------------------\n" +
      "\nUSE THE SQL STATEMENT:\n"+
      "  RUNSTATS\n" +
      "TO UPDATE TABLE STATISTICS.\n");
    
  // get fully qualified name of the table
     String tableName = "CUSTOMER"; 
     String schemaName = getSchemaName(conn, tableName);    
     String fullTableName = schemaName + "." + tableName;

    try
    {
      // store the CLP commands in a file and execute the file
      File outputFile = new File("RunstatsCmd.db2");
      FileWriter out = new FileWriter(outputFile);
            
      // perform runstats on table customer for all columns including XML columns
      String cmd1 = "RUNSTATS ON TABLE "+ fullTableName ;

      // perform runstats on table customer for XML columns
      String cmd2 = "RUNSTATS ON TABLE "+ fullTableName +
                     " ON COLUMNS (Info, History) ";

      // perform runstats on table customer for XML columns
      // with the following options:
      //
      // Distribution statistics for all partitions
      // Frequent values for table set to 30
      // Quantiles for table set to -1 (NUM_QUANTILES as in DB Cfg)
      // Allow others to have read-only while gathering statistics
      String cmd3 = "RUNSTATS ON TABLE "+ fullTableName +
                     " ON COLUMNS(Info, History LIKE STATISTICS)" +
                     " WITH DISTRIBUTION ON KEY COLUMNS" +
                     " DEFAULT NUM_FREQVALUES 30 NUM_QUANTILES -1" +
                     " ALLOW READ ACCESS";

      // perform runstats on table customer
      // with the following options:
      //
      // EXCLUDING XML COLUMNS.
      // This option allows the user to exclude all XML type columns from 
      // statistics collection. Any XML type columns that have been specified
      // in the cols-list will be ignored and no statistics will be collected 
      // from them. This clause facilitates the collection of statistics 
      // on non XML columns.
      String cmd4 = "RUNSTATS ON TABLE "+ fullTableName +
                     " ON COLUMNS(Info, History LIKE STATISTICS)" +
                     " WITH DISTRIBUTION ON KEY COLUMNS" +
                     " EXCLUDING XML COLUMNS ";

      out.write("CONNECT TO SAMPLE;\n");
      out.write(cmd1 + ";\n");
      out.write(cmd2 + ";\n");
      out.write(cmd3 + ";\n");
      out.write(cmd4 + ";\n");
      out.write("CONNECT RESET;\n");

      out.close();
            
      Process p = Runtime.getRuntime().exec("db2 -vtf RunstatsCmd.db2");

      // open streams for the process's input and error                                       
      BufferedReader stdInput = new BufferedReader(new 
                                      InputStreamReader(p.getInputStream()));
      BufferedReader stdError = new BufferedReader(new
                                      InputStreamReader(p.getErrorStream()));
      String s;
     
      // read the output from the command and set the output variable with 
      // the value
      while ((s = stdInput.readLine()) != null)
      {
        System.out.println(s);
      }
      
      // read any errors from the attempted command and set the error  
      // variable with the value
      while ((s = stdError.readLine()) != null) 
      {
        System.out.println(s);
      }
     
      // destroy the process created 
      p.destroy();          
     
      // delete the temporary file created
      outputFile.deleteOnExit(); 
    }
    catch (IOException e)
    {
      e.printStackTrace();
      System.exit(-1);
    } 
  } // xmlRunstats
  
  // function to get the schema name for a particular table
  static String getSchemaName(Connection conn, String tableName) throws Exception
  {
    Statement stmt = conn.createStatement();
    ResultSet rs = stmt.executeQuery(
                     "SELECT tabschema "+
                     "  FROM syscat.tables "+
                     "  WHERE tabname = '"+ tableName + "'");
                     
    boolean result = rs.next();
    String schemaName = rs.getString("tabschema");
    rs.close();
    stmt.close();
    
    // remove the trailing white space characters from schemaName before 
    // returning it to the calling function
    return schemaName.trim();
  } // getSchemaName       
} // XmlRunstats      
