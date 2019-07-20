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
// SOURCE FILE NAME: XmlUpDel.java
//
// SAMPLE: How to update and delete XML data from table
//
// SQL Statements USED:
//         SELECT
//
// JAVA 2 CLASSES USED:
//         Statement
//         PreparedStatement
//         ResultSet
//
// Classes used from Util.java are:
//         Db
//         Data
//         JdbcException
//
// PREREQUISITE : copy the files cust1021.xml, cust1022.xml and
//                cust1023.xml to working directory before running the
//                sample. These files can be found in xml/data
//                directory.
// OUTPUT FILE: XmlUpDel.out (available in the online documentation)
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
import java.sql.*;

class XmlUpDel
{
  public static void main(String argv[])
  {
    Connection con = null;
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO UPDATE AND DELETE XML TABLE DATA.");

      // connect to the 'sample' database
      db.connect();
      
      preRequisites(db.con);
      mostSimpleUpdatewithConstantString(db.con); 
      UpdatewhereSourceisAnotherXmlColumn(db.con);
      UpdatewhereSourceisAnotherStringColumn(db.con);    
      UpdateAnotherStringColumnWithImplicitParsing(db.con);
      UpdateUsingVarcharWithImplicitParsing(db.con);
      UpdatewhereSourceisBlobWithImplicitParsing(db.con);  
      UpdatewhereSourceisBlob(db.con);
      UpdatewhereSourceisClob(db.con);
      DeleteofRowwithXmlData(db.con);
      rollbackChanges(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // main

  static void mostSimpleUpdatewithConstantString(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
          "----------------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  UPDATE\n" +
          "TO PERFORM A SIMPLE UPDATE.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " UPDATE customer\n" +
                       " SET info=XMLPARSE(document'<newcustomerinfo>"+
                       " <name>rohit<street>park street</street>\n" +
                       " <city>delhi</city></name></newcustomerinfo>'"+
                       " preserve whitespace)\n" +
		       " WHERE cid=1008\n" +
	               "\n");

      
      PreparedStatement stmt1 = con.prepareStatement(
            "UPDATE customer" +                  
            " SET info=XMLPARSE(document'<newcustomerinfo><name>rohit"+
            "<street>park street</street>" +
            "<city>delhi</city></name></newcustomerinfo>'preserve " + 
            "whitespace) WHERE cid=1008");

      stmt1.execute();
      stmt1.close();
 
      System.out.println();
      System.out.println();
     
      
      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      //     rs.close();
      stmt1.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // mostSimpleUpdatewithConstantString

  static void UpdatewhereSourceisAnotherXmlColumn(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      //   System.out.println();
      System.out.println(
          "----------------------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  UPDATE\n" +
          " TO PERFORM AN UPDATE WHERE SOURCE IS FROM ANOTHER XML COLUMN.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      System.out.println();
      System.out.println("  Perform:\n" +
                   " UPDATE customer\n" +
                  " SET info=(SELECT information FROM oldcustomer p\n" +
                  " WHERE p.ocid=1009)\n" +
                  " WHERE cid=1008\n" +
		  "\n");
      
      PreparedStatement stmt1 = con.prepareStatement(
             "UPDATE customer" +                  
             " SET info=(SELECT information " +
             " FROM oldcustomer p" + 
             " WHERE p.ocid=1009)" +
             " WHERE cid=1008");
      stmt1.execute();
     
      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      //     rs.close();
      stmt1.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // UpdatewhereSourceisAnotherXmlColumn

  static void UpdatewhereSourceisAnotherStringColumn(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
          "-----------------------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  UPDATE\n" +
          "TO PERFORM AN UPDATE WHERE SOURCE IS FROM ANOTHER STRING COLUMN.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      System.out.println();
      System.out.println("  Perform:\n" +
                         " UPDATE customer\n" +
    			 " SET info=(SELECT XMLPARSE(document " +
                         " addr preserve whitespace)\n" +
                         " FROM oldcustomer p\n" +
			 " WHERE p.ocid=1009)\n" +
			 " WHERE cid=1008\n" +
			 "\n");

      PreparedStatement stmt1 = con.prepareStatement(
        "UPDATE customer" +                  
        " SET info=(SELECT XMLPARSE(document addr preserve whitespace)" +    
        " FROM oldcustomer p" + 
        " WHERE p.ocid=1009)" +
        " WHERE cid=1008");
      stmt1.execute();
      
      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      //     rs.close();
      stmt1.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // UpdatewhereSourceisAnotherStringColumn

  static void UpdateAnotherStringColumnWithImplicitParsing(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
          "--------------------------------------------\n\n" +
          " USE THE SQL STATEMENT:\n" +
          "  UPDATE\n" +
          " TO PERFORM AN UPDATE WHERE SOURCE IS FROM "+
          " ANOTHER STRING COLUMN" +
          " WITH IMPLICIT PARSING.");

      System.out.println();
      System.out.println("  Perform:\n" +
          " UPDATE customer\n" +
          " SET info=SELECT addr " +
          " FROM oldcustomer p\n" +
          " WHERE p.ocid=1009)\n" +
          " WHERE cid=1008\n" +
          "\n");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(
          "UPDATE customer " +
          "SET info=(SELECT addr " +
          "FROM oldcustomer p " +
          "WHERE p.ocid=1009) " +
          "WHERE cid=1008");

      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con, 1008);
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } //UpdateAnotherStringColumnWithImplicitParsing

  static void UpdateUsingVarcharWithImplicitParsing(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
          "----------------------------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  UPDATE\n" +
          "TO PERFORM A UPDATE USING VARCHAR WITH IMPLICIT PARSING.");

      // display the content of the 'customer' table
      // CustomerTbContentDisplay(1008);

      System.out.println();
      System.out.println("  Perform:\n" +
          " UPDATE customer\n" +
          " SET info='<newcustomerinfo><name>"+
          " rohit<street>park street</street>\n" +
          " <city>delhi</city></name></newcustomerinfo>'" +
          " WHERE cid=1008\n" +
          " \n");


      Statement stmt = con.createStatement();
      stmt.executeUpdate( 
          "UPDATE customer " +
          "SET info = '<newcustomerinfo><name> "+
          "rohit<street>park street</street>"+
          "<city>delhi</city></name></newcustomerinfo>' "+
          "WHERE cid=1008");

      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } //UpdateUsingVarcharWithImplicitParsing

  static void UpdatewhereSourceisBlobWithImplicitParsing(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      String xsdData = new String();
      xsdData=returnFileValues("cust1021.xml");
      byte[] Array=xsdData.getBytes();

      // Create a BLOB object
      java.sql.Blob blobData =
         com.ibm.db2.jcc.t2zos.DB2LobFactory.createBlob(Array);

      System.out.println();
      System.out.println(
          "-------------------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  UPDATE\n" +
          "TO PERFORM AN  UPDATE WHERE SOURCE IS A BLOB VARIABLE"+
          " WITH IMPLICIT PARSING \n");

      // display the content of the 'customer' table
      //CustomerTbContentDisplay(1008);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " UPDATE customer\n" +
                       " SET INFO= :blobData "  +
                       " WHERE cid=1008\n" +
                       "\n");

      PreparedStatement pstmt = con.prepareStatement( 
          " UPDATE customer SET INFO = " +
          " cast(? as Blob)" +
          " WHERE cid=1008");
      pstmt.setBlob(1, blobData);
      pstmt.execute(); 

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con, 1008);
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } //UpdatewhereSourceisBlobWithImplicitParsing

  static void UpdatewithValidation(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
          "-----------------------------------------------\n\n" +
          " USE THE SQL STATEMENT:\n" +
          " UPDATE\n" +
          " TO PERFORM AN UPDATE WITH VALIDATION WHERE " +
          " SOURCE IS TYPED OF VARCHAR.");
                                                         
      //  display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " UPDATE customer\n" +
                       " SET info=(SELECT XMLVALIDATE(XMLPARSE"+
                       " (document addr preserve whitespace)\n" +
	               " according to XMLSCHEMA ID customer)\n" +
		       " FROM oldcustomer p\n" + 
                       " WHERE p.ocid=1009)\n" +
                       " WHERE cid=1008\n" +
		       "\n");
      
      PreparedStatement stmt1 = con.prepareStatement(
        "UPDATE customer" +                  
        " SET info=(SELECT XMLVALIDATE(XMLPARSE(document " +
        " addr preserve whitespace)" +
        " according to XMLSCHEMA ID customer)" +
        " FROM oldcustomer p" + 
        " WHERE p.ocid=1009)" +
        " WHERE cid=1008");
      stmt1.execute();
     
      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      //     rs.close();
      stmt1.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // UpdatewithValidation

  static void UpdatewhereSourceisBlob(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      String xsdData = new String();
      xsdData=returnFileValues("cust1022.xml");
      byte[] Array=xsdData.getBytes();
      // Create a BLOB object

      java.sql.Blob blobData = 
            com.ibm.db2.jcc.t2zos.DB2LobFactory.createBlob(Array);

      System.out.println();
      System.out.println(
         "------------------------------------------------\n\n" +
         "USE THE SQL STATEMENT:\n" +
         "  UPDATE\n" +
         "TO PERFORM AN  UPDATE WHERE SOURCE IS A BLOB VARIABLE.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);
 
      System.out.println();
      System.out.println("  Perform:\n" +
                       " UPDATE customer\n" +
                       " SET INFO= XMLPARSE(document "  +
                       " cast(? as Blob) strip whitespace)\n" +
                       " WHERE cid=1008\n" +
                       "\n");


      PreparedStatement pstmt = con.prepareStatement(
          "UPDATE customer " +
          "SET INFO=XMLPARSE(document cast(? as Blob) strip whitespace)" +
          " WHERE cid=1008");

      System.out.println();

      pstmt.setBlob(1, blobData);

      System.out.println("  Execute prepared statement");
      pstmt.execute();

      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      pstmt.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // UpdatewhereSourceisBlob
  
  static void UpdatewhereSourceisClob(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      String Data = new String();
      Data=returnFileValues("cust1023.xml");

      // Create a CLOB object

      java.sql.Clob clobData = 
               com.ibm.db2.jcc.t2zos.DB2LobFactory.createClob(Data);

      System.out.println();
      System.out.println(
          "------------------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  UPDATE\n" +
          "TO PERFORM AN  UPDATE WHERE SOURCE IS A CLOB VARIABLE.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      System.out.println();

      System.out.println("  Perform:\n" +
                       " UPDATE customer\n" +
                       " SET INFO= XMLPARSE(document "  +
                       " cast(? as Clob) strip whitespace)\n" +
                       " WHERE cid=1008\n" +
                       "\n");

      PreparedStatement pstmt = con.prepareStatement(
          "UPDATE customer " +
          "SET INFO=XMLPARSE(document cast(? as Clob) strip whitespace)" +
          " WHERE cid=1008");

      System.out.println("  Set parameter value: parameter 1 = " + "clobData" );

      pstmt.setClob(1, clobData);

      System.out.println("  Execute prepared statement");
      pstmt.execute();

      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);
      pstmt.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // UpdatewhereSourceisClob

  // helping function
  static void preRequisites(Connection con)
  {
    try
    {
      Statement stmt = con.createStatement();

      // create table 'oldcustomer'
      stmt.executeUpdate(
        "CREATE TABLE oldcustomer(ocid integer," +
        "firstname varchar(15)," +
        "lastname varchar(15)," +
        "addr varchar(300)," +
        "information XML)");

      stmt.close();

      // populate table oldcustomer with data
      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate(
        "INSERT INTO oldcustomer " +
        "VALUES(1009,'Rahul','kumar'," +
        "'<customerinfo " +
        "  Cid=\"1009\"><name>Rahul</name><addr country=" +
        " \"Canada\"><street>25</street><city>Markham</city>" +
        " <prov-state>Ontario</prov-state><pcode-zip>N9C-3T6" +
        " </pcode-zip></addr><phone type=\"work\">905-555-7258" +
        "</phone></customerinfo>'," +
        "XMLPARSE(document '<oldcustomerinfo ocid=\"1009\">" +
        " <address country=\"Canada\"><street>25 Westend" +
        "</street><city>Markham</city><state>Ontario</state>"+
        " </address></oldcustomerinfo>'preserve whitespace))");

      stmt3.close();

      // populate table customer with data
      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
        "INSERT INTO customer(cid,info) " +
        "VALUES(1008,XMLPARSE(document '<customerinfo Cid=\"1008\"><name>" +
        "divya</name></customerinfo>' preserve whitespace))");

      stmt2.close();

      // Commit
      con.commit();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // PreRequisites

  // helping function
  static void CustomerTbContentDisplay(Connection con,int Cid)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      // prepare the query
      System.out.println();
      System.out.println(
        "  Prepare Statement:\n" +
        "    SELECT cid,XMLSERIALIZE(info as varchar(600))\n" +
        "    FROM  customer WHERE cid=" + "Cid");

      PreparedStatement pstmt = con.prepareStatement(
         "SELECT cid,XMLSERIALIZE(info as varchar(600)) " +
         "FROM customer WHERE cid = ?");

      System.out.println();
      System.out.println("  Set parameter value: parameter 1 = " + Cid);

      pstmt.setInt(1, Cid);

      System.out.println();
      System.out.println("  Execute prepared statement");
      ResultSet rs = pstmt.executeQuery();


      System.out.println(
        "    CUSTOMERID    CUSTOMERINFO \n" +
        "    ----------    -------------- ");


      // retrieve and display the result from the SELECT statement
      while (rs.next())
      {
         customerid = rs.getInt(1);
         customerInfo = rs.getString(2);

         System.out.println(
            "    " +
         Data.format(customerid, 10)  + "   " +
         Data.format(customerInfo, 600));
      }

      rs.close();
      pstmt.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // CustomerTableContentDisplay


  // this function will Read a file in a buffer and 
  // return the String value to cal
  public static String returnFileValues(String fileName)
  {
    String record = null;
    try
    {
      FileReader fr     = new FileReader(fileName);
      BufferedReader br = new BufferedReader(fr);
      record = new String();
      record = br.readLine();
      String descReturn=record;
      while ((record = br.readLine()) != null)
          descReturn=descReturn+record;
          return descReturn;
    }
    catch (IOException e)
    {
       // catch possible io errors from readLine()
       System.out.println("     file " + fileName + "doesn't exist");

       System.out.println("     Quitting program!");
       System.out.println();
       System.exit(-1);
    }
    return null;
  }// returnFileValues

  static void DeleteofRowwithXmlData(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
          "-------------------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  DELETE\n" +
          "TO PERFORM A DELETION OF ROWS WITH XML DATA.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " DELETE FROM customer\n" +
                       " WHERE cid=1008\n" +
	               "\n");

      PreparedStatement stmt1 = con.prepareStatement(
        	  "DELETE FROM customer" +                  
                  " WHERE cid=1008");
      stmt1.execute();
       
      System.out.println();
      System.out.println();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      //     rs.close();
      stmt1.close();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // DeleteofRowwithXmlData

  static void rollbackChanges(Connection con)
  {
    try
    {
      PreparedStatement stmt1 = con.prepareStatement(
        	  "DROP TABLE oldcustomer");
      stmt1.execute();
      stmt1.close();

      // Commit
      con.commit();
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
      System.exit(1);
    }
    catch(Exception e)
    {}
  } // rollbackChanges
}
