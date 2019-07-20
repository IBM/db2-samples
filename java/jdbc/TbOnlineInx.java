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
// SOURCE FILE NAME: TbOnlineInx.java
//
// SAMPLE: How to create and reorg indexes on a table
//
// SQL STATEMENTS USED:
//         INCLUDE 
//         CREATE INDEX 
//         DROP INDEX
//         REORG
//         LOCK
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
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: TbOnlineInx.out (available in the online documentation)
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

public class TbOnlineInx
{
  public static void main(String argv[]) 
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO CREATE AND REORG ONLINE INDEXES\n" +
        "ON TABLES.");
            
      // connect to the 'sample' database
      db.connect();
      
      // create online index on a table 
      createIndex(db.con);
      
      // reorg online index on a table 
      reorgIndex(db.con);
      
      // drop online index created
      dropIndex(db.con);
      
      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  // How to create an index on a table with different levels
  // of access to the table like read-write, read-only, no access 
  static void createIndex(Connection conn) throws Exception
  {
  
    System.out.print(
      "\n-----------------------------------------------------------" +
      "\nUSE THE SQL STATEMENT\n" +
      "  CREATE INDEX\n" +
      "TO CREATE AN INDEX\n");

    // create an online index with read-write access to the table 
    System.out.print(
      "\nTo create an index on a table allowing read-write access\n" +
      "to the table, use the following SQL command:\n\n" +
      "  CREATE INDEX index1 ON employee (lastname ASC)\n");
    
    Statement stmt = conn.createStatement();
    stmt.executeUpdate("CREATE INDEX index1 ON employee (lastname ASC)");
    conn.commit();
  
    dropIndex(conn);
  
    // create an index on a table while allowing only read access to it 
    System.out.println(
      "\nTo create an index on a table allowing only read access\n" +
      "to the table, use the following two SQL commands:\n\n" +
      "  LOCK TABLE employee IN SHARE MODE\n" +
      "  CREATE INDEX index1 ON employee (lastname ASC)");
  
    stmt.executeUpdate("LOCK TABLE employee IN SHARE MODE");
    conn.commit(); 

    stmt.executeUpdate("CREATE INDEX index1 ON employee (lastname ASC)");
    conn.commit();

    dropIndex(conn);
   
    // create an online index allowing no access to the table
    System.out.println(
      "\nTo create an index on a table allowing no access to the \n" +
      "table (only uncommitted readers allowed), use the \n" +
      "following two SQL statements:\n\n" +
      "  LOCK TABLE employee IN EXCLUSIVE MODE\n" +
      "  CREATE INDEX index1 ON employee (lastname ASC)");
    
    stmt.executeUpdate("LOCK TABLE employee IN EXCLUSIVE MODE");
    conn.commit();

    stmt.executeUpdate("CREATE INDEX index1 ON employee (lastname ASC)"); 
    conn.commit();  
 
    stmt.close();
  } // createIndex 
  
  // Create 3 CLP files for REORG command with write, read and no access,
  // respectively.
  static void createFiles(Connection conn) throws Exception 
  {
    // get fully qualified name of the table
    String tableName = "EMPLOYEE"; 
    String schemaName = getSchemaName(conn, tableName);    
    String fullTableName = schemaName + "." + tableName;      
       
    // reorg command has to be executed with three different options, namely,
    // 'with write access', 'with read access' and 'with no access'
    String[] fileNames = { "ReorgCmdAllowWrite.db2", 
                           "ReorgCmdAllowRead.db2", 
                           "ReorgCmdAllowNone.db2" };
     
    String[] options = { " WRITE ACCESS",
                         " READ ACCESS",
                         " NO ACCESS" };

    for (int i = 0; i < 3; i++)
    { 
      // create a CLP file with the REORG command and execute the file
      File outputFile = new File(fileNames[i]);
      FileWriter out = new FileWriter(outputFile);
    
      out.write("CONNECT TO SAMPLE;\n");
      out.write("REORG INDEXES ALL FOR TABLE " + fullTableName + 
                " ALLOW" + options[i] + ";\n");
      out.write("CONNECT RESET;");
      out.close();   
        
      // on exit, delete the temporary files created 
      outputFile.deleteOnExit();                
    }
  } //createFiles  
 
  // How to reorg an index on a table with different levels of 
  // access to the table like read-write, read-only, no access 
  static void reorgIndex(Connection conn) 
  {
    System.out.print(
      "\n-----------------------------------------------------------\n" +
      "\nUSE THE SQL STATEMENT:\n"+
      "  REORG\n" +
      "TO REORGANIZE A TABLE OR INDEX\n");

    
    String[] fileNames = { "ReorgCmdAllowWrite.db2", 
                           "ReorgCmdAllowRead.db2", 
                           "ReorgCmdAllowNone.db2" };
    
    String[] options = { " write access",
                         " read access",
                         " no access" };
    try
    {   
      // create 3 files with REORG commands
      createFiles(conn);
      
      for (int i = 0; i < 3; i++)
      { 
        System.out.println(
          "\nReorganize the indexes on a table allowing" + options[i] + 
          "\n-----------------------------------------------------------");
                 
        String s = null;  
        String execCmd = "db2 -tvf " + fileNames[i];
              
        // execute the command to run the CLP file
        Process p = Runtime.getRuntime().exec(execCmd);           
                                            
        // open streams for the process's input and error  
        BufferedReader stdInput = new BufferedReader(new 
                                        InputStreamReader(p.getInputStream()));
        BufferedReader stdError = new BufferedReader(new
                                        InputStreamReader(p.getErrorStream()));
    
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
     
        p.destroy();
              
      } // for            
    } // try
    
    catch (IOException e)
    {
      e.printStackTrace();
      System.exit(-1);             
    }  
     
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }       
         
  } // reorgIndex
  
  // How to drop the index on a table 
  static void dropIndex(Connection conn)
  {
    System.out.println(
      "\nUSE THE SQL STATEMENT\n" +
      "  DROP\n" +
      "TO DROP AN INDEX:");
    try
    {
      // drop the indexes 
      System.out.println(
        "  Execute the statement\n" +
        "    DROP INDEX index1\n" +
        "\n-----------------------------------------------------------");
      Statement stmt = conn.createStatement();
      stmt.executeUpdate("DROP INDEX index1");
      conn.commit();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // dropIndex 

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
} // TbOnlineInx    
