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
// SAMPLE FILE NAME: XmlTrig.java
//
// PURPOSE: This sample shows how triggers are used to enforce automatic
//          validation while inserting/updating XML documents
//
// USAGE SCENARIO: When a customer places a purchase order request an entry
//                 is made in the "customer" table by inserting customer
//                 information and his history details. If the customer is
//                 new, and is placing request for the first time with this 
//                 supplier,then the history column in the "customer" table 
//                 will be NULL. If he's an old customer, data in "customer" 
//                 table info and history columns are inserted.
//
// PREREQUISITE: 
//    On Unix:    copy boots.xsd file from <install_path>/sqllib
//                /samples/xml/data directory to current directory.
//    On Windows: copy boots.xsd file from <install_path>\sqllib\samples\
//                xml\data directory to current directory
//
// EXECUTION: javac XmlTrig.java
//            java XmlTrig
//
// INPUTS: NONE
//
// OUTPUTS: The last trigger statement which uses XMLELEMENT on transition
//          variable will fail. All other trigger statements will succeed.
//
// OUTPUT FILE: XmlTrig.out (available in the online documentation)
//
// SQL STATEMENTS USED:
//           CREATE TRIGGER
//           INSERT
//           DELETE
//           DROP
//
// SQL/XML FUNCTIONS USED:
//           XMLDOCUMENT
//           XMLPARSE
//           XMLVALIDATE
//           XMLELEMENT
//
//
//***************************************************************************
// For more information about the command line processor (CLP) scripts,
// see the README file.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, building, and running DB2
// applications, visit the DB2 application development website:
//     http://www.software.ibm.com/data/db2/udb/ad
//
//***************************************************************************
// SAMPLE DESCRIPTION
//
//***************************************************************************
// 1. Register boots.xsd schema with http://posample1.org namespace.
//
// 2. This sample consists of four different cases of create trigger
//    statements to show automatic validation of xml documents with
//    triggers.
//
//    Case1: This first trigger statement shows how to assign values to
//    non-xml transition variables, how to validate XML documents and
//    also to show that NULL values can be assigned to XML transition
//    variables in triggers.
//
//    Case2: Create a BEFORE INSERT trigger to validate info column in
//    "customer" table and insert a value for history column without 
//    any validation
//
//    Case3: Create a BEFORE UPDATE trigger with ACCORDING TO clause used
//    with WHEN clause.This trigger statement shows that only when WHEN 
//    condition is satisfied, the action part of the trigger will be 
//    executed.WHEN conditions are used with BEFORE UPDATE triggers.
//
//    Case4: Create a BEFORE INSERT trigger with XMLELEMENT function being
//    used on a transition variable. This case results in a failure as only
//    XMLVALIDATE function is allowed on transition variables.
//
// NOTE: In a typical real-time scenario, DBAs will create triggers and users
//    will insert records using multiple insert/update statements, not just
//    one insert statement as shown in this sample.
//***************************************************************************
//
//   IMPORT ALL PACKAGES AND CLASSES
//
//**************************************************************************/

import java.lang.*;
import java.sql.*;
import java.util.*;
import java.io.*;


class XmlTrig
{
  private static String relSchema=new String("POSAMPLE1");
  private static String schemaName=new String("boots");;
  private static String schemaLocation= new String("http://www.test.com/order");
  private static String primaryDocument= new String("boots.xsd");
  private static int shred = 0;

  public static void main(String argv[])
  {
    String url="jdbc:db2:sample";
    Connection con = null;

    try
    {
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
      con = DriverManager.getConnection(url);
      con.setAutoCommit(false);
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
      System.out.println("sth wrong her tooooooo");
      System.out.println(e);
    }

    System.out.println("THIS SAMPLE SHOWS HOW TO AUTOMATIC XML DOCUMENTS");
    System.out.println(" VALIDATION USING BEFORE TRIGGERS\n\n");

    registerXmlSchema(con);
    validateXmlDocCase1(con); 
    validateXmlDocCase2andCase3(con);
    validateXmlDocCase4(con);
    clearCustomerInfo(con);

  } // main  
  
  static void validateXmlDocCase1(Connection con)
  {
    Statement stmt = null;
    try
    {
      //*********************************************************************
      //    Case1: This first trigger statement shows how assign values to
      //    non-xml transition variables, how to validate XML documents and
      //    also to show that NULL values can be assigned to XML transition
      //    variables in triggers.
      //*********************************************************************

      System.out.println("CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON " +
                       " CUSTOMER EFERENCING NEW AS n " +
                       "FOR EACH ROW MODE DB2SQL " +
                       "BEGIN ATOMIC "+
                       "  set n.Cid = 5000" +
                       "  set n.info = XMLVALIDATE(n.info ACCORDING TO " +
                       "XMLSCHEMA ID CUSTOMER) " +
                       " set n.history = NULL "+
                       "END");

      stmt = con.createStatement();
      stmt.executeUpdate( "CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON" +
                   " customer REFERENCING NEW AS n " + 
                   "FOR EACH ROW MODE DB2SQL " +
                   "BEGIN ATOMIC "+
                   "  set n.Cid = 5000;" +
                   "  set n.info = XMLVALIDATE(n.info ACCORDING TO " +
                   "XMLSCHEMA ID CUSTOMER); " +
                   " set n.history = NULL ;"+
                   "END");

      System.out.println();
      System.out.println();
      System.out.println("INSERT info and history values in customer table");
      // insert xml document into customer table 
      String str = "INSERT INTO customer VALUES (1008,xmlparse(document " +
                "'<customerinfo Cid=\"1008\">"+
                "<name>Larry Menard</name><addr country=\"Canada\">"+
                "<street>223 Koramangala ring Road</street>"+
                "<city>Toronto</city><prov-state>Ontario</prov-state>"+
                "<pcode-zip>M4C 5K8</pcode-zip></addr><phone type=\"work\">"+
                "905-555-9146</phone><phone type=\"home\">416-555-6121 "+
                "</phone><assistant><name>Goose Defender</name><phone "+
                "type=\"home\">416-555-1943</phone></assistant>"+
                "</customerinfo>' preserve whitespace), NULL)";
      stmt.executeUpdate(str);

      displayCustomerInfo(con, 5000);
 
      // Drop trigger tr1 
      str = "DROP TRIGGER TR1";
      stmt.executeUpdate(str);

      // close all statement connections
      stmt.close();
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
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // validateXmlDocCase1

  static void validateXmlDocCase2andCase3(Connection con)
  {
    Statement stmt = null;
    try
    {
       //*********************************************************************
       //    Case2: Create a BEFORE INSERT trigger to validate info column in
       //    "customer" table and insert a value for history column without 
       //    any validation
       //*********************************************************************

       System.out.println("CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON " +
                       " customer REFERENCING NEW AS n " +
                       "FOR EACH ROW MODE DB2SQL " +
                       "BEGIN ATOMIC "+
                       "  set n.Cid = 5001" +
                       "  set n.info = XMLVALIDATE(n.info ACCORDING TO " +
                       "XMLSCHEMA ID CUSTOMER) " +
                       " set n.history = \'<customerinfo " +
                       "Cid = \"1009\"><name>suzan" +
                       "</name></customerinfo>\';"  +
                       "END");

      stmt = con.createStatement();
      String str = "CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON customer "+
                   "REFERENCING NEW AS n " +
		   "FOR EACH ROW MODE DB2SQL " +
                   "BEGIN ATOMIC "+
                   "  set n.Cid = 5001;" +
                    "  set n.info = XMLVALIDATE(n.info ACCORDING TO " +
                   "XMLSCHEMA ID CUSTOMER); " +
                   " set n.history = \'<customerinfo " +
                   "Cid = \"1009\"><name>suzan" +
                   "</name></customerinfo>\';"  +
                   "END";  	
      stmt.executeUpdate(str);

      System.out.println();
      System.out.println();
      System.out.println("INSERT info, history values into customer table"); 
      str = "INSERT INTO customer VALUES (1009, xmlparse(document "+
                "'<customerinfo Cid=\"1009\">"+
                "<name>Larry Menard</name><addr country"+
                "=\"India\"><street>223 Koramangala ring Road</street>"+
                "<city>Bangalore</city><prov-state>Ontario</prov-state>"+
                "<pcode-zip>M4C 5K8</pcode-zip></addr><phone type=\"work\">"+
                "905-555-9146</phone><phone type=\"home\">416-555-6121 "+
                "</phone><assistant><name>Tim Luther</name><phone "+
                "type=\"home\">416-555-1943</phone></assistant>"+
                "</customerinfo>'), NULL)";
      stmt.executeUpdate(str);

      displayCustomerInfo(con, 5001);


      //***********************************************************************
      //    Case3: Create a BEFORE UPDATE trigger with ACCORDING TO clause used
      //    with WHEN clause.This trigger statement shows that only when WHEN 
      //    condition is satisfied, the action part of the trigger will be 
      //    executed.WHEN conditions are used with BEFORE UPDATE triggers.
      //***********************************************************************

      System.out.println("CREATE TRIGGER TR2 NO CASCADE BEFORE UPDATE"+
               "ON customer REFERENCING NEW AS n "+
               "FOR EACH ROW MODE DB2SQL "+
               "WHEN (n.info is not validated ACCORDING TO XMLSCHEMA "+
                        "ID CUSTOMER)"+
               "BEGIN ATOMIC"+    
               "  set (n.cid) = (5002); " +
               "  set (n.info) = xmlvalidate(n.info ACCORDING TO " +
                               "XMLSCHEMA ID CUSTOMER);"+   
               "  set (n.history) = \'<customerinfo "+
                              "Cid=\"1010\"><name>"+
                              "madhavi</name></customerinfo>';" +
               "END");

      // create a BEFORE UPDATE trigger  
      str = "CREATE TRIGGER TR2 NO CASCADE BEFORE UPDATE ON customer " + 
	    "REFERENCING NEW AS n  "+
            "FOR EACH ROW MODE DB2SQL "+
            "WHEN (n.info is not validated ACCORDING TO XMLSCHEMA"+
            " ID CUSTOMER)"+
            "BEGIN ATOMIC"+
	    "  set (n.cid) = (5002); " +
            "  set (n.info) = xmlvalidate(n.info ACCORDING TO " +
                               "XMLSCHEMA ID CUSTOMER);"+
	    "  set (n.history) = \'<customerinfo "+
                                 "Cid=\"1010\"><name>"+
                                 "madhavi</name></customerinfo>';" +
            "END"; 
      stmt.executeUpdate(str);
  
      System.out.println();
      System.out.println();
      System.out.println("UPDATE customer info where Cid = 5001");
      str = "UPDATE CUSTOMER SET customer.info = XMLPARSE(document "+
            "'<customerinfo Cid=\"1012\">"+
            "<name> Russel</name><addr country"+
            "=\"India\"><street>223 Koramangala ring Road</street>"+
            "<city>Bangalore</city><prov-state>Karnataka</prov-state>"+
            "<pcode-zip>M4C 5K8</pcode-zip></addr><phone type=\"work\">"+
            "905-555-9146</phone><phone type=\"home\">416-555-6121 "+
            "</phone><assistant><name>Vincent luther</name><phone "+
            "type=\"home\">416-555-1943</phone></assistant>"+
            "</customerinfo>' preserve whitespace) WHERE Cid=5001";
      stmt.executeUpdate(str);
   
      displayCustomerInfo(con, 5002);

      // drop triggers 
      str = "DROP TRIGGER TR1";
      stmt.executeUpdate(str);

      str = "DROP TRIGGER TR2";
      stmt.executeUpdate(str);
     
      // close all the statement connections
      stmt.close();  
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
    }
    catch(Exception e)
    { 
      System.out.println(e);
    }
  } // validateXmlDocCase2andCase3

  static void validateXmlDocCase4(Connection con) 
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();

      String str = "CREATE TABLE boots (Cid int, doc1 XML, doc2 XML)";
      stmt.executeUpdate(str);
      
      //*********************************************************************   
      //    Case4: Create a BEFORE INSERT trigger with XMLELEMENT function being
      //    used on a transition variable. This case results in a failure as 
      //    only XMLVALIDATE function is allowed on transition variables.
      //********************************************************************   

      System.out.println("CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT "+
         "ON boots REFERENCING NEW AS n  "+
         "FOR EACH ROW MODE DB2SQL  "+
         "BEGIN ATOMIC "+
         "set (n.Cid) = (5004); "+
         "set (n.doc1) = xmlvalidate(n.doc1 ACCORDING TO XMLSCHEMA "+
                               "URI 'http://posample.org');"+
         "set (n.doc2) = XMLDOCUMENT(XMLELEMENT(name Red Tape,n.doc2));"+
         "END;");
  
       System.out.println("This create trigger statement will fail as " +
                   " XMLELEMENT is not allowed on transition variable. " +
                   " Only XMLVALIDATE is allowed");
       
       str = "CREATE TRIGGER TR1 NO CASCADE BEFORE INSERT ON boots "+
             "REFERENCING NEW AS n  "+
             "FOR EACH ROW MODE DB2SQL  "+
             "BEGIN ATOMIC "+
             "set (n.Cid) = (5004); "+
             "set (n.doc1) = xmlvalidate(n.doc1 ACCORDING TO XMLSCHEMA "+
                               "URI 'http://posample1.org'); "+
             "set (n.doc2) = XMLDOCUMENT(XMLELEMENT(name RedTape,"+
                                 " n.doc2));"+
             "END";
       stmt.executeUpdate(str);
       con.rollback();
       
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
  } // validateXmlDocCase4
  
  static void displayCustomerInfo(Connection con, int custid)
  {
    try
    {
      String info = null;
      int cid = 0;
      String history = null;

      // Display contents of customer table
      PreparedStatement pstmt = con.prepareStatement(
                 "SELECT Cid, info, history FROM customer WHERE Cid = ?");

      // Set the customer id parameter marker value
      pstmt.setInt(1, custid);

      //execute the query
      ResultSet rs = pstmt.executeQuery();
      rs.next();
      cid = rs.getInt(1);
      info = rs.getString(2);
      history = rs.getString(3);

      // When history column value is not null
      if (rs.getString(3) != null)
      {
        System.out.println("--------------------------------------------");
        System.out.println("     Cid      info     history              "); 
        System.out.println("--------------------------------------------");
        System.out.println("  " + Data.format(cid, 10) +
                         "             " + Data.format(info, 1024) +
                         "             " + Data.format(history,1024));
      }
      else
      // When history column value is null
      {
        System.out.println("--------------------------------------------");
        System.out.println("     Cid      info     history              ");
        System.out.println("--------------------------------------------");
        System.out.println("  " + Data.format(cid, 10) +
                         "             " + Data.format(info, 1024)); 
      }

      // close result set and statement connections
      rs.close();
      pstmt.close();
    }
    catch(SQLException sqle)
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
  } // displayCustomerInfo

  static void clearCustomerInfo(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
      String str = "DELETE FROM CUSTOMER WHERE Cid > 1005";
      stmt.executeUpdate(str);

      str = "DROP XSROBJECT POSAMPLE1.BOOTS";
      stmt.executeUpdate(str);

      stmt.close();
      con.commit();
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  }

  // This function will register the Primary XML Schema
  static void registerXmlSchema(Connection con)
  {
    try
    {
      // register primary XML Schema
      System.out.println("--------------------------------------------------");  
      System.out.println("Registering main schema "+ primaryDocument +"...");
      CallableStatement callStmt = 
                  con.prepareCall("CALL SYSPROC.XSR_REGISTER(?,?,?,?,NULL)");
      File xsdFile = new File(primaryDocument);
      FileInputStream xsdData = new FileInputStream(xsdFile);
      callStmt.setString(1, relSchema);
      callStmt.setString(2, schemaName);
      callStmt.setString(3, schemaLocation );
      callStmt.setBinaryStream(4, xsdData, (int)xsdFile.length() );
      callStmt.execute();
      xsdData.close();

     // complete the registeration
      System.out.println("  Completing XML Schema registeration");
      callStmt=con.prepareCall("CALL SYSPROC.XSR_COMPLETE(?,?,NULL,?)");
      callStmt.setString(1,relSchema);
      callStmt.setString(2, schemaName);
      callStmt.setInt(3, shred);
      callStmt.execute();
      System.out.println("Schema registered successfully");
      callStmt.close();
      System.out.println("-------------------------------------------------");
      System.out.println("\n\n");

    }
    catch(SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try { con.rollback(); }
      catch (Exception e) {}
      System.exit(1);
    }
    catch(IOException ioe)
    {
      System.out.println("Error opening file " + primaryDocument);
    }
  }// registerXmlSchema
} // XmlTrig class
