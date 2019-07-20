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
// SOURCE FILE NAME: XmlSchema.java
//
// SAMPLE: How to registere XML Schema
// SAMPLE: How to register an XML Schema
// SAMPLE USAGE SCENARIO: Consider a user who needs to insert an XML type value
// into the table. The user would like to ensure that the XML value conforms to a
// deterministic XML schema.
//
// PROBLEM: User has schema's for all the XML values and like to validate the values
// as per schema while inserting it to the tables.
//
// SOLUTION:
// To achieve the goal, the sample will follow the following steps:
// a) Register the primary XML schema
// b) Add the XML schema documents to the primary XML schema to ensure that the
//    schema is deterministic
// c) Insert an XML value into an existing XML column and perform validation
//
// SQL Statements USED:
//         INSERT
//
// Stored Procedure USED
//         SYSPROC.XSR_REGISTER
//         SYSPROC.XSR_ADDSCHEMADOC
//         SYSPROC.XSR_COMPLETE
//
// SQL/XML Function USED
//         XMLVALIDATE
//         XMLPARSE
//
// PREREQUISITE: copy product.xsd, order.xsd, 
//               customer.xsd, header.xsd Schema files, order.xml XML 
//               document from xml/data directory to working 
//               directory.
// OUTPUT FILE: XmlSchema.out (available in the online documentation)
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
import java.io.*;
import java.util.*;

class XmlSchema
{
  private static String relSchema=new String("POSAMPLE");
  private static String schemaName=new String("order");;
  private static String schemaLocation= new String("http://www.test.com/order");
  private static String primaryDocument= new String("order.xsd");
  private static String multipleSchema1= new String("header.xsd");
  private static String multipleSchema2= new String("customer.xsd");
  private static String multipleSchema3= new String("product.xsd"); 
  private static String xmlDoc = new String("order.xml"); 
  private static int shred = 0; 
  private static int poid=10;
  private static String status=new String("shipped");

  public static void main(String argv[])
  {
    int rc=0;
    String url = "jdbc:db2:sample";
    Connection con=null;
    try
    {
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
      
      // connect to the 'sample' database
      con = DriverManager.getConnection( url );
      System.out.println();
      
      // register the XML Schema
      registerXmlSchema(con);
      
     // Select the information about the registered schema from catalog table
     selectInfo(con);
 
     // insert the XML value validating according to the registered schema
     insertValidatexml(con);
      
     // drop the registered the schema
      cleanUp(con); 
      con.close();
    } 
    catch (SQLException sqle)
    {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try { con.rollback(); }
      catch (Exception e)
      {
      }
      System.exit(1);
    }
    catch(Exception e)
   {}
  }// main
  
  // This function will register the Primary XML Schema
  static void registerXmlSchema(Connection con)
  {
    try
    {
      // register primary XML Schema
      System.out.println("Registering main schema "+ primaryDocument +"..."); 
      CallableStatement callStmt = con.prepareCall("CALL SYSPROC.XSR_REGISTER(?,?,?,?,NULL)");
      File xsdFile = new File(primaryDocument);
      FileInputStream xsdData = new FileInputStream(xsdFile);
      callStmt.setString(1, relSchema);
      callStmt.setString(2, schemaName);
      callStmt.setString(3, schemaLocation );
      callStmt.setBinaryStream(4, xsdData, (int)xsdFile.length() );
      callStmt.execute();
      xsdData.close();
 
      // add XML Schema document to the primary schema
      System.out.println("  Adding XML Schema document "+ multipleSchema1 +"...");
      addXmlSchemaDoc(con,multipleSchema1);
      System.out.println("  Adding XML Schema document "+ multipleSchema2 +"...");
      addXmlSchemaDoc(con,multipleSchema2);
      System.out.println("  Adding XML Schema document " + multipleSchema3 +"...");
      addXmlSchemaDoc(con,multipleSchema3);
   
     // complete the registeration 
      System.out.println("  Completing XML Schema registeration");
      callStmt=con.prepareCall("CALL SYSPROC.XSR_COMPLETE(?,?,NULL,?)");
      callStmt.setString(1,relSchema);
      callStmt.setString(2, schemaName);
      callStmt.setInt(3, shred);
      callStmt.execute();
      System.out.println("Schema registered successfully");
      callStmt.close();
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

  // This function will ADD the Schema document to already registered schema.
  // The Schema documents referred in the primary XML schema (using Import or include)
  // should be added to the registered schema before completing the registeration.
  static void addXmlSchemaDoc(Connection con,String schemaDocName)
  {
    try
    {
      File xsdFile = new File(schemaDocName);
      FileInputStream xsdData = new FileInputStream(xsdFile);  
      CallableStatement callStmt = con.prepareCall("CALL SYSPROC.XSR_ADDSCHEMADOC(?,?,?,?,NULL)");
      callStmt.setString(1, relSchema);
      callStmt.setString(2, schemaName);
      callStmt.setString(3, schemaLocation );
      callStmt.setBinaryStream(4, xsdData, (int)xsdFile.length() );
      callStmt.execute();
      xsdData.close();
      callStmt.close();
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
      System.out.println("Error opening file " + schemaDocName);
    }
  }// addXmlSchemaDoc
 
  // this function will insert the XML value in the table validating it according
  // to the registered schema
  static void insertValidatexml(Connection con)
  {
    try
    {
      PreparedStatement prepStmt=con.prepareStatement("INSERT INTO PURCHASEORDER(poid,status,porder) VALUES(?,?,xmlvalidate(cast(? as XML) ACCORDING TO XMLSCHEMA ID posample.order))");
      File xmlFile = new File(xmlDoc);
      FileInputStream xmlData = new FileInputStream(xmlFile);
      prepStmt.setInt(1,poid);
      prepStmt.setString(2,status);
      prepStmt.setBinaryStream(3, xmlData, (int)xmlFile.length() );
      prepStmt.executeUpdate();
      prepStmt.close();
      xmlData.close(); 	 
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
      System.out.println("Error opening file " + xmlDoc);
    }
  }// insertValidatexml

  // This function will select the information about the registered schema 
  static void selectInfo(Connection con)
  {
   try
    {
      Statement stmt=con.createStatement();
      String query="SELECT OBJECTSCHEMA, OBJECTNAME FROM syscat.xsrobjects WHERE OBJECTNAME= '" + schemaName.toUpperCase() +"'";
      System.out.println(query);
      ResultSet rs=stmt.executeQuery(query);
      System.out.println("RELATIONAL SCHEMA      XML SCHEMA ID");
      rs.next();
      System.out.println(); 
      System.out.println(rs.getString(1)+"           "+ rs.getString(2));
      stmt.close();
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
  } // selectInfo
  
  // This function will drop the registered schema and delete the inserted row
  static void cleanUp(Connection con)
  {
    try
    {
      Statement stmt=con.createStatement();
      String query1="DROP XSROBJECT posample." + schemaName;
      String query2="DELETE FROM purchaseorder WHERE poid="+poid; 
      System.out.println(query1);
      stmt.executeUpdate(query1);
      System.out.println(query2); 
      stmt.executeUpdate(query2);
      stmt.close();
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
  } // cleanUp
} // XmlSchema

