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
// SOURCE FILE NAME: XmlInsert.java
//
// SAMPLE: How to insert rows having XML data into a table.
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
// OUTPUT FILE: XmlInsert.out (available in the online documentation)
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
import java.util.*;
import java.io.*;


class XmlInsert
{
  public static void main(String argv[])
  {
    Connection con = null;
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO INSERT XML TABLE DATA.");

      // connect to the 'sample' database
      db.connect();

      preRequisites(db.con);
      mostSimpleInsert(db.con);      
      InsertFromAnotherXmlColumn(db.con);
      InsertFromAnotherStringColumn(db.con);     
      InsertwhereSourceisXmlFunction(db.con);
      InsertwhereSourceisBlob(db.con);
      InsertwhereSourceisClob(db.con);
      InsertBlobDataWithImplicitParsing(db.con);
      InsertFromStringNotWellFormedXML(db.con);
      InsertwhereSourceisTypecastToXML(db.con); 
      InsertwithValidationSourceisVarchar(db.con);
      ValidateXMLDocument(db.con);
      DeleteofRowwithXmlData(db.con);


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
    }
    catch(Exception e)
    {}
  } // main

  static void mostSimpleInsert(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
          "----------------------------------------------------------\n" +
          "USE THE SQL STATEMENT:\n" +
          "  INSERT\n" +
          "TO PERFORM A SIMPLE INSERT.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1006);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " INSERT INTO customer(cid,info)\n" +
 		       " VALUES(1006,XMLPARSE(document '<customerinfo "+
                       " Cid=\"1006\"><name>divya</name></customerinfo>'" +
                       " preserve whitespace))\n" +
                       "\n");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO customer(cid,info) " + 
        "VALUES(1006,XMLPARSE(document '<customerinfo Cid=\"1006\"><name>" +
        "divya</name></customerinfo>' preserve whitespace))");

      
      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1006);

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
    }
    catch(Exception e)
    {}
  } // mostSimpleInsert

  static void InsertFromAnotherXmlColumn(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
          "---------------------------------------------------\n" +
          "USE THE SQL STATEMENT:\n" +
          "  INSERT\n" +
          "TO PERFORM AN  INSERT WHERE SOURCE IS FROM ANOTHER XML COLUMN.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1007);

      System.out.println();
      System.out.println("  Perform:\n" +
                         " INSERT INTO customer(cid,info)\n" +
    			 " SELECT ocid,information FROM oldcustomer "+
                         "p WHERE p.ocid=1007\n" +
                         "\n");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO customer(cid,info)" + 
        "SELECT ocid,information " +
        "FROM oldcustomer p " +
        "WHERE p.ocid=1007");

      
      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1007);

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
    }
    catch(Exception e)
    {}
  } // InsertFromAnotherXmlColumn

  static void InsertFromAnotherStringColumn(Connection con)
  {
    try
    { 
      System.out.println();
      System.out.println(
          "---------------------------------------------------\n" +
          "USE THE SQL STATEMENT:\n" +
          "  INSERT\n" +
          "TO PERFORM AN  INSERT WHERE SOURCE IS FROM " +
          "ANOTHER STRING COLUMN.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

      System.out.println();
      System.out.println("  Perform:\n" +
                " INSERT INTO customer(cid,info)\n" +
                " SELECT ocid,XMLPARSE(document addr preserve " +
                " whitespace) FROM oldcustomer p " +
                " WHERE p.ocid=1008\n" +
                "\n");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO customer(cid,info) " + 
        "SELECT ocid,XMLPARSE(document addr preserve whitespace) " +
        "FROM oldcustomer p " +
        "WHERE p.ocid=1008");

      
      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1008);

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
    }
    catch(Exception e)
    {}
  } // InsertFromAnotherStringColumn

  static void InsertwithValidationSourceisVarchar(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println(
          "--------------------------------------------------\n" +
          "USE THE SQL STATEMENT:\n" +
          "  INSERT\n" +
          "TO PERFORM AN  INSERT WITH VALIDATION WHERE" +
          " SOURCE IS TYPED OF VARCHAR.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1009);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " INSERT INTO customer(cid,info)\n" +
  	               " SELECT ocid,XMLVALIDATE(XMLPARSE(document "+
                       " addr preserve whitespace)according to  " +
                       " XMLSCHEMA id customer) " +
		       " FROM oldcustomer p " +
         	       " WHERE p.ocid=1009\n" +
                       "\n");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
          "INSERT INTO customer(cid,info) " + 
          "SELECT ocid,XMLVALIDATE(XMLPARSE(document addr "+
          "preserve whitespace)according to " +
          "XMLSCHEMA ID CUSTOMER) " +
 	  "FROM oldcustomer p " +
          "WHERE p.ocid=1009");

      
      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1009);

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
    }
    catch(Exception e)
    {}
  } // InsertwithValidationSourceisVarchar

  static void InsertwhereSourceisXmlFunction(Connection con)
  {
    try
    { 
      System.out.println();
      System.out.println(
        "--------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  INSERT\n" +
        "TO PERFORM AN  INSERT WHERE SOURCE IS A XML FUNCTION.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1010);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " INSERT INTO customer(cid,info)\n" +
    		       " SELECT ocid,XMLPARSE(document " + 
                       " XMLSERIALIZE(content " +
                       " XMLELEMENT(NAME\"oldCustomer\", " +
                       " XMLATTRIBUTES(s.ocid,s.firstname||' '||" +
                       " s.lastname AS \"name\")) " +
		       " as varchar(200)) strip whitespace) " +
                       " FROM oldcustomer s " +
         	       " WHERE s.ocid=1010\n" +
                       "\n");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
        "INSERT INTO customer(cid,info) " + 
        "SELECT ocid,XMLPARSE(document XMLSERIALIZE(content " +
        "XMLELEMENT(NAME\"oldCustomer\",XMLATTRIBUTES" +
        "(s.ocid,s.firstname||' '||s.lastname AS \"name\")) " +
	"as varchar(200)) strip whitespace) " +
 	"FROM oldcustomer s " +
        "WHERE s.ocid=1010");

      
      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1010);

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
    }
    catch(Exception e)
    {}
  } //  InsertwhereSourceisXmlFunction 

  static void InsertwhereSourceisTypecastToXML(Connection con)
  {
    try
    {
       int customerid = 0;
       String customerInfo = "";

       System.out.println();
       System.out.println(
          "----------------------------------------------------------\n" +
          "USE THE SQL STATEMENT:\n" +
          "  INSERT\n" +
          "TO PERFORM AN  INSERT WHERE SOURCE IS TYPECAST TO XML.");

       System.out.println();
       System.out.println("  Perform:\n" +
                         " INSERT INTO customer(cid,info)\n" +
                         " VALUES(1031,XMLCAST(? AS XML))" +
                         "\n");

       PreparedStatement pstmt = con.prepareStatement(
          "INSERT INTO customer(cid,info) " +
          "VALUES(1031,XMLCAST(XMLPARSE(document '<oldcustomerinfo ocid= "+
          " \"1031\"><address country=\"india\"><street>56 hillview</street>"+
          "<city>kolar</city><state>karnataka</state> </address>"+
          "</oldcustomerinfo>' preserve whitespace)  as XML))");
       pstmt.execute();

       //display the content of the 'customer' table
       CustomerTbContentDisplay(con,1031);
 
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
    {}
  } //InsertwhereSourceisTypecastToXML

  static void ValidateXMLDocument(Connection con)
  {
    try
    {
 
        System.out.println();
        System.out.println(
            "-------------------------------------------------\n" +
            "USE THE SQL STATEMENT:\n" +
            "  INSERT\n" +
            " TO PERFORM AN  INSERT WITH VALIDATION WHEN " +
            " DOCUMENT IS NOT AS PER SCHEMA");

        // display the content of the 'customer' table
        //CustomerTbContentDisplay(1012);
        System.out.println();
        System.out.println("  Perform:\n" +
             " INSERT INTO customer(cid,info)\n" +
             " VALUES (1012, XMLVALIDATE(XMLPARSE(document '<customerinfo"+
             " ocid=\"1012\"><address country=\"india\"><street>12 gandhimarg"+
             " </street><city>belgaum</city><state>karnataka</state>"+
             " </address></customerinfo>' preserve whitespace))"+
             " according to XMLSCHEMA ID customer) \n");

        Statement stmt = con.createStatement();
        stmt.executeUpdate(      
           "INSERT INTO customer(cid,info) "+
           "VALUES (1012, XMLVALIDATE(XMLPARSE(document '<customerinfo " + 
           "Cid=\"1012\"><addr country= \"india\"><street>12 gandhimarg" +
           " </street><city>belgaum</city><prov-state>karnataka</prov-state></addr>"+ 
           " </customerinfo>' preserve whitespace )  according to XMLSCHEMA ID"+
           " CUSTOMER ))"); 
      
        // display the content of the 'customer' table
        CustomerTbContentDisplay(con, 1012);

    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      //try {con.rollback(); }
      //catch (Exception e) {}
    }
    catch(Exception e)
    {}
  } //ValidateXMLDocument

  static void InsertwhereSourceisBlob(Connection con)
  {
    try
    { 
      String xsdData = new String();
      xsdData=returnFileValues("cust1021.xml");
      byte[] byteArray=xsdData.getBytes();
      // Create a BLOB object
      java.sql.Blob blobData = 
             com.ibm.db2.jcc.t2zos.DB2LobFactory.createBlob(byteArray);

      System.out.println();
      System.out.println(
        "--------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  INSERT\n" +
        "TO PERFORM AN  INSERT WHERE SOURCE IS A BLOB VARIABLE.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1021);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " INSERT INTO customer(cid,info)\n" +
                       " VALUES(1021,XMLPARSE(document "  +
                       " cast(? as Blob) strip whitespace))\n" +
                       "\n");
     
      PreparedStatement pstmt = con.prepareStatement(
         "INSERT INTO customer(cid,info) " + 
         "VALUES(1021,XMLPARSE(document cast(? as Blob) strip whitespace))");

      System.out.println();
      System.out.println("  Set parameter value: parameter 1 = " + "blobData" );

      pstmt.setBlob(1, blobData);

      System.out.println();
      System.out.println("  Execute prepared statement");
      pstmt.execute();
      
      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1021);

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
    }
    catch(Exception e)
    {}
  } // InsertwhereSourceisBlob

  static void InsertBlobDataWithImplicitParsing(Connection con)
  {
    try
    {
      String xsdData = new String();
      xsdData=returnFileValues("cust1022.xml");
      byte[] byteArray=xsdData.getBytes();
      // Create a BLOB object
      java.sql.Blob blobData =
            com.ibm.db2.jcc.t2zos.DB2LobFactory.createBlob(byteArray);

      System.out.println();
      System.out.println(
          "----------------------------------------------------------\n" +
          "USE THE SQL STATEMENT:\n" +
          "  INSERT\n" +
          "TO PERFORM AN  INSERT WHERE SOURCE IS A BLOB VARIABLE" +
          " WITH IMPLICIT PARSING" );

      // display the content of the 'customer' table
      //CustomerTbContentDisplay(1022);

      System.out.println();
      System.out.println("  Perform:\n" +
                       " INSERT INTO customer(cid,info)\n" +
                       " VALUES(1022, " +
                       " cast(? as Blob) strip whitespace)\n" +
                       "\n");

      PreparedStatement pstmt = con.prepareStatement(
          "INSERT INTO customer(cid,info) " +
          "VALUES(1022, cast(? as Blob))");
      pstmt.setBlob(1, blobData);
      pstmt.execute();


      // display the content of the 'customer' table
      CustomerTbContentDisplay(con, 1022);

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
    {}
  } //InsertBlobDataWithImplicitParsing

  static void InsertwhereSourceisClob(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      String xsdData = new String();
      xsdData=returnFileValues("cust1023.xml");
  
      // Create a CLOB Object
      java.sql.Clob clobData = 
          com.ibm.db2.jcc.t2zos.DB2LobFactory.createClob(xsdData);

      System.out.println();
      System.out.println(
        "----------------------------------------------------\n" +
        "USE THE SQL STATEMENT:\n" +
        "  INSERT\n" +
        "TO PERFORM AN  INSERT WHERE SOURCE IS A CLOB VARIABLE.");

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1023);

      System.out.println();
      System.out.println("  Perform:\n" +
                         " INSERT INTO customer(cid,info)\n" +
    			 " VALUES(1023,XMLPARSE(document "  +
                         " cast(? as Clob) strip whitespace))\n" +
                         "\n");

      
      PreparedStatement pstmt = con.prepareStatement(
        "INSERT INTO customer(cid,info)" + 
        "VALUES(1023,XMLPARSE(document cast(? as Clob) strip whitespace))");

      System.out.println();
      System.out.println("  Set parameter value: parameter 1 = " + "clobData" );

      pstmt.setClob(1, clobData);

      System.out.println();
      System.out.println("  Execute prepared statement");
      pstmt.execute();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1023);

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
    }
    catch(Exception e)
    {}
  } // InsertwithValidationSourceisClob

  static void InsertFromStringNotWellFormedXML(Connection con)
  {
    try
    {
      int customerid = 0;
      String customerInfo = "";

      System.out.println();
      System.out.println(
         "----------------------------------------------------------\n" +
         "USE THE SQL STATEMENT:\n" +
         "  INSERT\n" +
         "TO PERFORM INSERT WITH NOT WELL FORMED XML");

      System.out.println();
      System.out.println("  Perform:\n" +
              " INSERT INTO customer(cid,info)\n" +
              " VALUES(1032, "+
              " '<customerinfo Cid=\"1032\"><name>divya" +
              " </name>')\n" +
              " \n");


      PreparedStatement pstmt = con.prepareStatement(
          "INSERT INTO customer(cid,info) VALUES(1032," +
          "'<customerinfo Cid=\"1032\"><name>divya</name>')"); 
      pstmt.execute();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con, 1032);
    }
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      //try {con.rollback(); }
      //catch (Exception e) {}
    }
    catch(Exception e)
    {}
  } //InsertFromStringNotWellFormedXML

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


      // populate table oldcustomer with data
      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
          "INSERT INTO oldcustomer " +
          "VALUES (1007,'Raghu','nandan','<addr country=\"india\"> " +
          "<state>karnataka<district>bangalore</district></state>" +
          " </addr>',XMLPARSE(document'<oldcustomerinfo ocid= " +
          "\"1007\"><address country=\"india\"><street>24 gulmarg" +
          "</street><city>bangalore</city><state>karnataka " +
          "</state></address></oldcustomerinfo>'preserve whitespace))");

      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
           "INSERT INTO oldcustomer " +
           " VALUES(1008,'Rama','murthy','<addr country=" +
           "\"india\"><state>karnataka<district>belgaum</district>" +
           " </state></addr>',XMLPARSE(document'<oldcustomerinfo " +
           " ocid=\"1008\"><address country=\"india\"><street>12 " +
           " gandhimarg</street> <city>belgaum</city><state>karnataka"+
           "</state> </address></oldcustomerinfo>'preserve whitespace))");


      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate(
        "INSERT INTO oldcustomer " +
        "VALUES(1009,'Rahul','kumar'," +
        "'<customerinfo " +
        " Cid=\"1009\"><name>Rahul</name><addr country=\"Canada\">" +
        " <street>25</street><city>Markham</city><prov-state>Ontario"+
        " </prov-state><pcode-zip>N9C-3T6</pcode-zip></addr><phone" +
        " type=\"work\">905-555-7258</phone></customerinfo>'," +
        "XMLPARSE(document '<oldcustomerinfo ocid=\"1009\"> " +
        " <address country=\"Canada\"><street>25 Westend</street>" +
        "<city>Markham</city><state>Ontario</state></address>" +
        " </oldcustomerinfo>'preserve whitespace))");

      Statement stmt4 = con.createStatement();
      stmt4.executeUpdate(
        "INSERT INTO oldcustomer " +
        "VALUES(1010,'Sweta','Priya','<addr country=\"india\">" +
        "<state>karnataka<district>kolar</district></state></addr>'," +
        "XMLPARSE(document'<oldcustomerinfo ocid=\"1010\"><address " +
        "country=\"india\"><street>56 hillview</street>" +
        "<city>kolar</city><state>karnataka</state> </address>i" +
        "</oldcustomerinfo>'preserve whitespace))");

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
        "    FROM  customer WHERE cid=" + Cid);

      PreparedStatement pstmt = con.prepareStatement(
         "  SELECT cid,XMLSERIALIZE(info as varchar(600)) FROM " +
         "  customer WHERE cid = ?");

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
            Data.format(customerInfo, 1024));
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
    }
    catch(Exception e)
    {}
  } // CustomerTableContentDisplay

  // this function will Read a file in a buffer and 
  // return the String value to called function
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
          "---------------------------------------\n\n" +
          "USE THE SQL STATEMENT:\n" +
          "  DELETE\n" +
          "TO PERFORM A DELETE OF ROW WITH XML DATA.");

      System.out.println();
      System.out.println("  Perform:\n" +
                       " DELETE FROM customer\n" +
                       " WHERE cid>=1006 and cid <= 1032\n" +
                       "\n");

      PreparedStatement stmt1 = con.prepareStatement(
         "DELETE FROM customer " +
         "WHERE cid>=1006 and cid <= 1032");
 
      stmt1.execute();
      PreparedStatement stmt2 = con.prepareStatement(
         "DROP TABLE oldcustomer");  
      stmt2.execute();

      // display the content of the 'customer' table
      CustomerTbContentDisplay(con,1007);

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
    {}
  } //DeleteofRowwithXmlData
} //XmlInsert
