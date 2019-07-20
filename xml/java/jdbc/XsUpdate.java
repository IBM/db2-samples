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
//  SAMPLE FILE NAME: XsUpdate.java                                          
//                                                                          
//  PURPOSE:  To demonstrate how to update an existing XML schema with
//            a new schema that is compatible with the original schema.
//                                                                          
//  USAGE SCENARIO: A store manager maintains product details in an XML     
//                  document that conforms to an XML schema. The product     
//                  details are: Name, SKU and Price. The store manager      
//                  wants to add a product description for each of the         
//                  products along with the existing product details.                     
//                                                                          
//  PREREQUISITE: The original schema and the new schema should be     
//                present in the same directory as the sample.             
//                Copy prod.xsd, newprod.xsd from directory    
//                <install_path>/xml/data to the working directory.                           
//                                                                          
//  EXECUTION:    i)  javac XsUpdate.java   (compile the sample)
//                ii) java XsUpdate.class   (run the sample)
//                                                                          
//  INPUTS:       NONE
//                                                                          
//  OUTPUTS:      Updated schema and successful insertion of XML  
//                documents with the new product descriptions.                                              
//                                                                          
//  OUTPUT FILE:  XsUpdate.out (available in the online documentation)      
//                                     
//  SQL Statements USED:
//         CREATE
//         INSERT
//         DROP
//
//  Stored Procedures USED:
//         SYSPROC.XSR_REGISTER
//         SYSPROC.XSR_COMPLETE
//         SYSPROC.XSR_UPDATE
//
// SQL/XML Functions USED:
//         XMLVALIDATE
//         XMLPARSE
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
//  1. Register the original schema with product details:Name, SKU and Price.
//  2. Register the new schema containing the product description element 
//     along with the existing product details.
//  3. Call the XSR_UPDATE stored procedure to update the original schema.      
//  4. Insert an XML document containing the product description elements.
// *************************************************************************/

// import the required classes 
import java.lang.*;
import java.sql.*;
import java.io.*;
import java.util.*;
import com.ibm.db2.jcc.DB2Xml;

class XsUpdate
{
  
  // /*************************************************************************
  //    SETUP                                                                 
  // **************************************************************************/
  public static String relSchema=new String("STORE");
  public static String schemaName=new String("PROD");;
  public static String schemaLocation= new String("http://product");
  public static String primaryDocument= new String("prod.xsd");
  
  public static String newSchemaName=new String("NEWPROD");;
  public static String newSchemaLocation= new String("http://newproduct");
  public static String newPrimaryDocument= new String("newprod.xsd");
  
  public static int shred = 0; 

  public static String xmlData1 = new String("<products><product color='green' weight='20'><name>Ice Scraper, Windshield 4 inch</name><sku>stores</sku><price>999</price></product><product color='blue' weight='40'><name>Ice Scraper, Windshield 8 inch</name><sku>stores</sku><price>1999</price></product><product color='green' weight='26'><name>Ice Scraper, Windshield 5 inch</name><sku>stores</sku><price>1299</price></product></products>");

  public static String xmlData2 =  new String("<products><product color='green' weight='20'><name>Ice Scraper, Windshield 4 inch</name><sku>stores</sku><price>999</price><description>A new prod</description></product><product color='blue' weight='40'><name>Ice Scraper, Windshield 8 inch</name><sku>stores</sku><price>1999</price><description>A new prod</description></product><product color='green' weight='26'><name>Ice Scraper, Windshield 5 inch</name><sku>stores</sku><price>1299</price></product></products>");

  public static void main(String argv[])
  {
    int rc=0;
    String url = "jdbc:db2:sample";
    Connection con=null;
    try
    {
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
      
      // connect to the Sample database
      con = DriverManager.getConnection( url );
      System.out.println("\n Connected to Sample database \n");
  
      // create a table for storing product details
      Statement create1 = con.createStatement();
      create1.executeUpdate("CREATE TABLE store.products(id INT GENERATED ALWAYS AS IDENTITY,plist XML)"); 

      // /*************************************************************************
      // 1. Register the original schema with product details: Name, SKU and Price.
      // *************************************************************************/

      // register the XML Schema
      registerXmlSchema(con,schemaName,schemaLocation,primaryDocument);
     
      // insert data into the table validating against the schema STORE.PROD
      PreparedStatement prepStmt=con.prepareStatement("INSERT INTO store.products(plist) "
             + "VALUES(xmlvalidate(cast(? as XML) ACCORDING TO XMLSCHEMA ID store.prod))");
      prepStmt.setString(1,xmlData1);
      System.out.println("Inserting data into table validating against the schema: STORE.PROD");
      prepStmt.executeUpdate();

      // select data from  the table
      com.ibm.db2.jcc.DB2Xml outData = null;
      PreparedStatement stmt1 = con.prepareStatement("SELECT * FROM STORE.PRODUCTS");
      ResultSet rs1 = stmt1.executeQuery();
      System.out.println("\n Inserted Data is: ");
      while(rs1.next())
         {
		outData = (DB2Xml) rs1.getObject(2);
                System.out.println(outData.getDB2XmlString());
         }
      rs1.close();
 
      // /**************************************************************************
      //  2. Register the new schema containing the product description element 
      //     along with the existing product details.                                      
      // **************************************************************************/

      // register the new XML Schema
      registerXmlSchema(con,newSchemaName,newSchemaLocation,newPrimaryDocument); 

      // /*************************************************************************
      //  3. Call the XSR_UPDATE stored procedure to update the original schema.
      // **************************************************************************/
 
      // update the original schema to reflect the changes in the new schema
      updateXmlSchema(con,schemaName,newSchemaName);         

      // /*************************************************************************
      //  4. Insert an XML document containing the product description elements.          
      // **************************************************************************/

      // insert data into the table validating against the updated XML schema STORE.PROD
      System.out.println("Inserting data into table validating against the "
                       + "updated schema: STORE.PROD");
      prepStmt.setString(1,xmlData2);
      prepStmt.executeUpdate();
      prepStmt.close(); 
   
      // check whether data is inserted or not
      ResultSet rs2 = stmt1.executeQuery();
      System.out.println("\n Inserted Data is: ");
      while(rs2.next())
         {
                outData = (DB2Xml) rs2.getObject(2);
                System.out.println(outData.getDB2XmlString());
         }
      rs2.close();
      // drop the created objects
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
  
  // Method to register an XML Schema
  static void registerXmlSchema(Connection con,String schName,String schLoc,String schDoc)
  {
    try
    {
      // register XML Schema
      System.out.println("\nRegistering Schema "+ relSchema + "." +schName +"..."); 
      CallableStatement callStmt = con.prepareCall("CALL SYSPROC.XSR_REGISTER(?,?,?,?,NULL)");
      File xsdFile = new File(schDoc);
      FileInputStream xsdData = new FileInputStream(xsdFile);
      callStmt.setString(1, relSchema);
      callStmt.setString(2, schName);
      callStmt.setString(3, schLoc);
      callStmt.setBinaryStream(4, xsdData, (int)xsdFile.length() );
      callStmt.execute();
      xsdData.close();
   
      // complete the registration 
      System.out.println("Completing XML Schema registration...");
      callStmt=con.prepareCall("CALL SYSPROC.XSR_COMPLETE(?,?,NULL,?)");
      callStmt.setString(1, relSchema);
      callStmt.setString(2, schName);
      callStmt.setInt(3, shred);
      callStmt.execute();
      System.out.println("Schema "+ relSchema + "." +schName +" registered successfully \n\n");
      callStmt.close();
    } 
    catch(SQLException sqle)
    {
      System.out.println("Error Msg: "+sqle.getMessage());
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
      System.out.println("Error opening file " + schDoc);
    }
  }// registerXmlSchema

  // Method to update an XML schema
  static void updateXmlSchema(Connection con,String schName,String newSchName)
  {
    try
    {
      System.out.println(" Updating the Schema "+ relSchema + "." +schName +"...");
      CallableStatement callStmt = con.prepareCall("CALL SYSPROC.XSR_UPDATE(?,?,?,?,1)");
      callStmt.setString(1,relSchema);
      callStmt.setString(2,schName);
      callStmt.setString(3,relSchema);
      callStmt.setString(4,newSchName);
      callStmt.execute();
      System.out.println(" Updated the schema "+ relSchema + "." + schName + " successfully \n\n");
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
  } //updateXmlSchema
 
  // Method to drop the created objects
  static void cleanUp(Connection con)
  {
    try
    {
      Statement stmt=con.createStatement();
      String query1="DROP XSROBJECT STORE." + schemaName;
      String query2="DROP TABLE STORE.PRODUCTS";
      System.out.println("\n\n"+query1);
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
} // XsUpdate

