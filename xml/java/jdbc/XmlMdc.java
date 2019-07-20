//***************************************************************************
//   (c) Copyright IBM Corp. 2008 All rights reserved.
//   
//   The following sample of source code ("Sample") is owned by International 
//   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
//   copyrighted and licensed, not sold. You may use, copy, modify, and 
//   distribute the Sample in any form without payment to IBM, for the purpose 
//   of assisting you in the development of your applications.
//   
//   The Sample code is provided to you on an "AS IS" basis, without warranty 
//   of any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS 
//   OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
//   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions 
//   do not allow for the exclusion or limitation of implied warranties, so the 
//   above limitations or exclusions may not apply to you. IBM shall not be liab
//   le for any damages you suffer as a result of using, copying, modifying or 
//   distributing the Sample, even if IBM has been advised of the possibility 
//   of such damages.
//***************************************************************************
//                                                            
//  SAMPLE FILE NAME: XmlMdc.java                                          
//                                                                          
//  PURPOSE:  This sample demonstrates the following features
//	1. XML data type columns in MDC tables.
//      2. Faster insert and faster delete options supported in MDC tables
//	   having XML columns.
//                                                                          
//  USAGE SCENARIO: The scenario is for a Book Store that has two types 
//      of customers, retail customers and corporate customers. 
//      Corporate customers do bulk purchases of books for their company
//      libraries. The store's DBA maintains the database, 
//      the store manager runs queries on different tables to view 
//      the book sales. 
//
//      The store expands and opens four more branches
//      in the city, all the books are spread across different branches. 
//      The store manager complains to the DBA that queries to get details
//      like availability of a particular book by a particular author
//      in a particular branch are very slow. 
// 
//      The DBA decides to improve the query performance by converting a 
//      non-MDC table, for books available in different branches of the
//      store, into an MDC table. To further improve the query performace,
//      the DBA decides to create partition on the MDC table based on 
//      the published date of the book. By creating an MDC table, the query 
//      performance increases and the sales clerk can do faster inserts into 
//      this table when he receives books from different suppliers. He can 
//      also do faster deletes when he wants to delete a particular type of
//      book due to low sales in a particular branch for that category of 
//      book in that location.
//                                                                          
//  PREREQUISITE: None
//                              
//  EXECUTION:    i)   javac Util.java
//                ii)  javac XmlMdc.java
//                iii) java XmlMdc <SERVER_NAME> <PORT_NO> <USERID> <PASSWORD>
//                                                                          
//  INPUTS:       NONE
//                                                                          
//  OUTPUTS:      Successfull execution of all the queries.
//                                                                          
//  OUTPUT FILE:  XmlMdc.out (available in the online documentation)      
//                                     
//  SQL Statements USED:
//         CREATE
//         INSERT
//         DROP
//
//
// SQL/XML Functions USED:
//         XMLEXISTS
//
// *************************************************************************
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// *************************************************************************/
//
//  SAMPLE DESCRIPTION                                                      
//
// /*************************************************************************
// This sample will demonstrate
// 1. Moving data from a non-MDC table to an MDC table.
// 2. MDC table with partition.
// 3. Faster inserts into MDC table containing an XML column.
// 4. Faster delete on MDC table containing an XML column.
// 5. Exploiting block indexes and XML indexes in a query.
// *************************************************************************/

import java.lang.*;
import java.sql.*;
import java.util.*;
import java.io.*;

class XmlMdc
{
  static Db db;
  public static void main(String argv[])
  {
    String url="jdbc:db2:sample";
    Connection con = null;
    ResultSet rs = null;
    javax.sql.DataSource ds = null;
    try
    {
       db=new Db(argv);
    }
    catch (Exception e)
    {
       System.out.println("  Error loading DB2 Driver...\n");
       System.out.println(e);
       System.exit(1);
    }
    try
    {
       con = db.connect();
    }
    catch (Exception e)
    {
       System.out.println("Connection to sample db can't be established.");
       System.err.println(e) ;
       System.exit(1);
    }
    System.out.println("This sample demonstrates the following: ");
    System.out.println("XML data type columns in MDC tables");
    System.out.println("Faster insert and Faster delete options support in MDC"+
                       " tables having XML columns");
    try
    {
      moveFromNonMdcToMdc(con);
      mdcWithRangepartition(con);
      mdcFasterInsert(con);
      mdcFasterDelete(con);
      mdcWithXmlAndBlockIndexes(con);
      cleanUp(con);
    } 
    catch(Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  static void moveFromNonMdcToMdc(Connection con)
  {
    Statement stmt = null;
    try
    {
      System.out.println("\n-------------------------------------------------");
      System.out.println("1. Moving data from a non-MDC table to an MDC table");
      System.out.println("-------------------------------------------------\n");

      stmt = con.createStatement();
    
      System.out.println("CREATE TABLE books(book_id VARCHAR(10), "+
                       "publish_date DATE, category VARCHAR(20),"+
                       "location VARCHAR(20), status VARCHAR(15))");

      stmt.executeUpdate(" CREATE TABLE books(book_id VARCHAR(10), "+
                         "publish_date "+
                         "DATE, category VARCHAR(20),"+
                         "location VARCHAR(20), status VARCHAR(15))");

      String cmd = "INSERT INTO books VALUES ('BK101', '10-01-2008', "+
                       "'Management', 'Tasman','available')";
      stmt.executeUpdate(cmd);

      cmd = "INSERT INTO books VALUES ('BK102', '01-01-2008', "+
                       "'Fantasy', 'Cupertino', 'available')";

      stmt.executeUpdate(cmd);

      cmd = "INSERT INTO books VALUES('BK103', '10-10-2007', "+
                       "'Fantasy', 'Cupertino', 'ordered')";
      stmt.executeUpdate(cmd);

      cmd = "INSERT INTO books VALUES ('BK104', '05-02-2007', "+
                       "'Spiritual', 'Tasman', 'available')";
      stmt.executeUpdate(cmd);

      System.out.println("\n--------------------------------------------------");
      System.out.println("Create 'books_mdc' table partitioned by "+
                         "'publish date' and organized by multiple dimensions -"+
                         " category, location and status.");
      System.out.println("\n-------------------------------------------------");
      System.out.println("CREATE TABLE books_mdc(book_id VARCHAR(20), "+
                " publish_date DATE, category"+
		" VARCHAR(20), location VARCHAR(20), status VARCHAR(15),"+ 
		" book_details XML)"+ 
		" DISTRIBUTE BY HASH(book_id)"+
		" PARTITION BY RANGE(publish_date)"+
		" (STARTING FROM ('01-01-2007')"+
		" ENDING ('12-12-2008') EVERY 3 MONTHS)"+
		" ORGANIZE BY DIMENSIONS (category, location, status)");

      cmd = "CREATE TABLE books_mdc (book_id VARCHAR(20), "+
            " publish_date DATE, category"+
            " VARCHAR(20), location VARCHAR(20), status VARCHAR(15),"+ 
            " book_details XML)"+ 
            " DISTRIBUTE BY HASH(book_id)"+
            " PARTITION BY RANGE(publish_date)"+
            " (STARTING FROM ('01-01-2007')"+
            " ENDING ('12-12-2008') EVERY 3 MONTHS)"+
            " ORGANIZE BY DIMENSIONS (category, location, status)";
      stmt.executeUpdate(cmd);

      System.out.println("Move the book details data from 'books' table and "+
                         "insert them into 'books_mdc' table");

      cmd = "INSERT INTO books_mdc (book_id, publish_date, category, "+
                       "location, status) SELECT book_id, publish_date, "+
                       "category, location, status FROM books";
      stmt.executeUpdate(cmd);

      cmd = "UPDATE books_mdc SET book_details =  "+
                       "'<book_details id=\"BK101\"> "+
					"<name>Communication skills</name>"+
					"<author>Peter Sharon</author>"+
					"<price>120</price>"+
					"<publications>Wroxa</publications>"+
				"</book_details>'"+
			"WHERE book_id='BK101'";
      stmt.executeUpdate(cmd);

      cmd = "UPDATE books_mdc SET book_details = "+
                        "'<book_details id=\"BK102\">"+
					"<name>Blue moon</name>"+
					"<author>Paul Smith</author>"+
					"<price>100</price>"+
					"<publications>Orellier</publications>"+
				"</book_details>'"+
			"WHERE book_id='BK102'";
      stmt.executeUpdate(cmd);
    
      cmd = "UPDATE books_mdc SET book_details = "+ 
                       "'<book_details id=\"BK103\">"+
					"<name>Paint your house</name>"+
					"<author>Roger Martin</author>"+
					"<price>120</price>"+
					"<publications>BPBH</publications>"+
				"</book_details>'"+
			"WHERE book_id='BK103'";
      stmt.executeUpdate(cmd);

      cmd = "UPDATE books_mdc SET book_details = "+
                        "'<book_details id=\"BK104\">"+
					"<name>Ramayan</name>"+
					"<author>Eric Mathews</author>"+
					"<price>90</price>"+
					"<publications>Tata Ho</publications>"+
				"</book_details>'"+
			"WHERE book_id = 'BK104'";
      stmt.executeUpdate(cmd);
      stmt.executeUpdate("COMMIT");

      cmd = "SELECT book_id, publish_date, "+
          "category, location, status FROM books_mdc";
      ResultSet rs = stmt.executeQuery(cmd);
                              
      System.out.println("\n\nSELECT book_id, publish_date, "+
                              "category, location, status FROM books_mdc");
      String bk_id, cat, loc, stat;
      java.util.Date dt;
   
      System.out.println("bookid   publish_date  category  location  status");
      System.out.println("--------------------------------------------------");

      while (rs.next())
      {
        bk_id = rs.getString(1);
        dt = rs.getDate(2);
        cat = rs.getString(3);
        loc = rs.getString(4);
        stat = rs.getString(5);
      
        System.out.println(""+bk_id+"   "+dt+"         "+cat+"      "+loc+""+
                           ""  +stat+" "); 
      }

      rs.close();
      stmt.close();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // moveFromNonMdcToMdc

  static void mdcWithRangepartition(Connection con)
  {
    Statement stmt = null;
    try
    {
      System.out.println("-------------------------------------------------");
      System.out.println("2. MDC table with partition");
      System.out.println("-------------------------------------------------");
    
      System.out.println("\nThis query gets the details of list of 'Management'"+
                         " books available in 'Tasman' branch whose published "+
                         " date is 10-01-2008 ");

      stmt = con.createStatement();
      String str = "SELECT book_id, publish_date, category, location, status "+
           " FROM books_mdc "+
           " WHERE  location='Tasman' and category='Management' and"+
  	   " publish_date='10-01-2008' and "+
           " XMLEXISTS ('$b/book_details[author=\"Peter Sharon\"]'  "+
	   " PASSING book_details as \"b\")";
      System.out.println(str);

      ResultSet rs = stmt.executeQuery(str);
      String bk_id, cat, loc, stat;
      java.util.Date dt;

      System.out.println("\nbookid   publish_date  category  location  status");
      System.out.println("----------------------------------------------------");
   
      while (rs.next())
      {
        bk_id = rs.getString(1);
        dt = rs.getDate(2);
        cat = rs.getString(3);
        loc = rs.getString(4);
        stat = rs.getString(5);
      
        System.out.println(""+bk_id+"   "+dt+"         "+cat+"      "+loc+""+
                           ""+stat+" "); 
      }
      rs.close();
      stmt.close();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
  } // mdcWithRangepartition

  static void mdcFasterInsert(Connection con) throws Exception
  {
    Statement stmt = null;
    String tableName = "BOOKS_MDC";
    String schemaName = getSchemaName(con, tableName);
    String fullTableName = schemaName +"."+ tableName;

    try
    {
      System.out.println("\n-------------------------------------------------");
      System.out.println("3. Faster inserts into MDC table containing "+
                         "an XML column.");
      System.out.println("-------------------------------------------------\n");

      System.out.println("\n Enable the LOCKSIZE BLOCKINSERT option for ");
      System.out.println("faster insert on MDC table ");

      stmt = con.createStatement();
      String str = "ALTER TABLE books_mdc LOCKSIZE BLOCKINSERT";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println("Insert data into Block 0");

      str = "INSERT INTO books_mdc VALUES('BK105', '12-10-2007', 'Management', "+
            "'Schaumberg', "+
            "'available','<book_details id=\"BK105\"> "+
					"<name>How to Sell or Market</name> "+
					"<author>Rusty Harold</author> "+
					"<price>450</price>"+
					"<publications>Orellier</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      str = "INSERT INTO books_mdc VALUES('BK106', '03-12-2007', 'Management', "+
            "'Schaumberg', "+
            "'available','<book_details id=\"BK106\">"+
					"<name>How to become CEO</name>"+
					"<author>Booster Hoa</author>"+
					"<price>150</price>"+
					"<publications>wroxa</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      str = "INSERT INTO books_mdc VALUES('BK107', '06-25-2008', 'Management', "+
            "'Schaumberg',"+
            "'available','<book_details id=\"BK107\">"+
				"<name>Effective Email communication</name>"+
				"<author>Sajer Menon</author>"+
				"<price>100</price>"+
				"<publications>PHPB</publications>"+
			"</book_details>')";
      stmt.executeUpdate(str);
      stmt.executeUpdate("commit");   

      System.out.println("Insert data into block 1");
      str = "INSERT INTO books_mdc VALUES('BK108', '04-23-2008', "+
        "'Management', 'Cupertino',"+
        "'Not available','<book_details id=\"BK108\">"+
					"<name>Presentation skills</name>"+
					"<author>Martin Lither</author>"+
					"<price>125</price>"+
					"<publications>PHPB</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);
 
      str = "INSERT INTO books_mdc VALUES('BK109', '09-25-2007', "+
       "'Management', 'Cupertino',"+
       "'Not available','<book_details id=\"BK109\">"+
					"<name>Assertive Skills</name>"+
					"<author>Robert Steve</author>"+
					"<price>250</price>"+
					"<publications>wroxa</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      str = "INSERT INTO books_mdc VALUES('BK110', '05-29-2007', "+
            "'Management', 'Cupertino',"+
            "'Not available','<book_details id=\"BK110\">"+
					"<name>Relationship building</name>"+
					"<author>Bunting Mexa</author>"+
					"<price>190</price>"+
					"<publications>Tata Ho</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);
      stmt.executeUpdate("commit");

      System.out.println("Insert data in block 2");

      str = "INSERT INTO books_mdc VALUES('BK111', '08-14-2008', "+
             "'Management', 'Tasman',"+
             "'available','<book_details id=\"BK111\">"+
					"<name>Manage your Time</name>"+
					"<author>Pankaj Singh</author>"+
					"<price>125</price>"+
					"<publications>Orellier</publications>"+
				"</book_details>')";
       stmt.executeUpdate(str);

       str = "INSERT INTO books_mdc VALUES('BK112', '07-25-2008', "+
           "'Management', 'Tasman',"+
           "'available','<book_details id=\"BK112\">"+
					"<name>Be in the Present</name>"+
					"<author>Hellen Sinki</author>"+
					"<price>200</price>"+
					"<publications>Orellier</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      str = "INSERT INTO books_mdc VALUES('BK113', '06-23-2008', "+
           "'Management', 'Tasman',"+
           "'available',	'<book_details id=\"BK113\">"+
					"<name>How to become Rich</name>"+
					"<author>Booster Hoa</author>"+
					"<price>200</price>"+
					"<publications>wroxa</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);
      stmt.executeUpdate("commit");

      System.out.println("Insert data into block 3");

      str = "INSERT INTO books_mdc VALUES('BK114', '08-08-2008',"+
           " 'Fantasy', 'Schaumberg',"+
           "'available','<book_details id=\"BK114\">"+
					"<name>Dream home</name>"+
					"<author>Hellen Sinki</author>"+
					"<price>250</price>"+
					"<publications>wroxa</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      str = "INSERT INTO books_mdc VALUES('BK115', '05-12-2008', "+
             "'Fantasy', 'Schaumberg',"+
             "'available',	'<book_details id=\"BK115\">"+
					"<name>Dream world</name>"+
					"<author>Hellen Sinki</author>"+
					"<price>100</price>"+
					"<publications>wroxa</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);
      stmt.executeUpdate("commit");

      System.out.println("Insert data into block 4");
      str = "INSERT INTO books_mdc VALUES('BK116', '09-10-2007', "+
            "'Fantasy', 'Cupertino',"+
            "'Not available','<book_details id=\"BK116\">"+
					"<name>Mothers Island</name>"+
					"<author>Booster Hoa</author>"+
					"<price>250</price>"+
					"<publications>wroxa</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      str = "INSERT INTO books_mdc VALUES('BK117', '03-11-2007', "+
            " 'Fantasy', 'Cupertino',"+
            "'Not available','<book_details id=\"BK117\">"+
					"<name>The destiny </name>"+
					"<author>Marran</author>"+
					"<price>250</price>"+
					"<publications>Orellier</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      stmt.executeUpdate("commit");

      System.out.println("Insert data into block 5");

      str = "INSERT INTO books_mdc VALUES('BK118', '03-12-2007', "+
           "'Spiritual', 'Tasman',"+
           "'available','<book_details id=\"BK118\">"+
					"<name>Mahabharat</name>"+
					"<author>Narayana Murthy</author>"+
					"<price>250</price>"+
					"<publications>PHPB</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      str = "INSERT INTO books_mdc VALUES('BK119', '09-09-2008', "+
           " 'Spiritual', 'Tasman',"+
           "'available','<book_details id=\"BK119\">"+
					"<name>Bhagavat Gita</name>"+
					"<author>Narayana Murthy</author>"+
					"<price>250</price>"+
					"<publications>PHPB</publications>"+
				"</book_details>')";
      stmt.executeUpdate(str);

      stmt.executeUpdate("commit");

      System.out.println("Run Runstats command on MDC table to "+
                         "update statistics in the catalog tables.");

      try
      {
        File outputFile = new File("RunstatsCmd.db2");
        FileWriter out = new FileWriter(outputFile);

        String cmd = "RUNSTATS ON TABLE "+fullTableName +" WITH DISTRIBUTION "+
                     " AND DETAILED INDEXES ALL";
        out.write("CONNECT TO SAMPLE;\n");
        out.write(cmd+";\n");
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
  
        //stmt.executeUpdate(str);
      }
      catch (IOException e)
      {
        e.printStackTrace();
        System.exit(-1);
      }
     
      System.out.println("Change the locksize to default ");
      stmt.executeUpdate("ALTER TABLE books_mdc LOCKSIZE ROW");    
      stmt.close();
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // mdcFasterInsert

  static void mdcFasterDelete(Connection con)
  {
    Statement stmt = null;
    try
    {
      System.out.println("\n-------------------------------------------------");
      System.out.println("4. Faster delete on MDC table containing an XML "+
                         "column.");
      System.out.println("-------------------------------------------------\n");

      stmt = con.createStatement();
      System.out.println("Set MDC ROLLOUT option to make the delete "+
                         "operation faster.\n");
      String str = "SET CURRENT MDC ROLLOUT MODE IMMEDIATE";
      stmt.executeUpdate(str);
      System.out.println(str);

      System.out.println("Delete all 'Fantasy' category books from "+
                         "'books_mdc' table \n");
      str = "DELETE from books_mdc "+
  		      "WHERE category='Fantasy' AND location = 'Cupertino'";
      stmt.executeUpdate(str);
      System.out.println(str);

      stmt.close();
    }
    catch(Exception e)
    {
      System.out.println("Could not delete" + e);
    }
  } // mdcFasterDelete

  static void mdcWithXmlAndBlockIndexes(Connection con) 
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();

      System.out.println("\n-------------------------------------------------");
      System.out.println("5. Exploiting block indexes and XML indexes in a query");
      System.out.println("-------------------------------------------------\n");


      System.out.println("For faster retrieval of data the DBA creates "+
                         "an XML index on the author element of book_details"+
                         " XML document. \n");

      String str = "CREATE INDEX auth_ind on books_mdc (book_details)"+
		"  GENERATE KEY USING XMLPATTERN '/book_details/author' AS SQL "+
		"  VARCHAR(20)";
      stmt.executeUpdate(str);
      System.out.println(str);


      System.out.println("Query the table to get all 'Management' books"+
                         " available in the store by author 'Booster Ho'. "+
                         " This query exploits both block index and XML index.\n");
   
      str = "SELECT book_id, publish_date, category, location, status "+
            " FROM books_mdc "+
	    " WHERE category='Management' and status='available' "+
	    " and XMLEXISTS('$b/book_details[author=\"Booster Hoa\"]' "+ 
  	    " PASSING book_details as \"b\")";

      ResultSet rs =  stmt.executeQuery(str);
      System.out.println();
      System.out.println(str);

      String bk_id, cat, loc, stat;
      java.util.Date dt;

      System.out.println("\nbookid   publish_date  category  location  status");
      System.out.println("--------------------------------------------------");
   
      while (rs.next())
      {
        bk_id = rs.getString(1);
        dt = rs.getDate(2);
        cat = rs.getString(3);
        loc = rs.getString(4);
        stat = rs.getString(5);
      
        System.out.println(""+bk_id+"   "+dt+"         "+cat+"      "+loc+""+ 
                           " "+stat+" "); 
      }
      rs.close();
      stmt.close();
    
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try {con.rollback(); }
      catch (Exception e) {}
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // mdcWithXmlAndBlockIndexes

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

  static void cleanUp(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt=con.createStatement();
      String str = "DROP TABLE books";
      System.out.println(str);
      stmt.executeUpdate(str);

      str = "DROP TABLE books_mdc";
      stmt.executeUpdate(str);
      System.out.println(str);
      stmt.executeUpdate("commit");

      stmt.close();

      db.disconnect();
    }
    catch(Exception e)
    {
      System.out.println("Cleanup failed");
    }
  } // cleanUp
} // XmlMdc
