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
// SAMPLE FILE NAME: XmlCheckConstraint.java
//
// PURPOSE: This sample shows how to create check constraints on XML column. 
//         
// USAGE SCENARIO: Super market maintains different stores for different 
//     products like music players, boots, headphones. Each store sells one 
//     type of product, as they would want to have separate accounting or 
//     billing for their products. Super market application maintains a 
//     separate table data for each product to make his work easy.Whenever 
//     a customer purchases some product an entry is made in the corresponding 
//     table restricting the table to a particular product entry. 
//     Because there are multiple tables and if the manager wants to frequently
//     view data from multiple tables, he creates a view on top of these product
//     tables with required columns. Also, when a customer purchases 2 or 
//     more products, inserting data from view has made his job easy. 
//     Some times when he wants to get the customer address details, he uses 
//     "customer" table from sample database to get only valid data using 
//     IS VALIDATED predicate. In XML case, users can insert data into tables 
//     through views. But if the user wants to select data, as indexes are 
//     created on XML documents on base tables and not on views, it would be 
//     best to make use of indexes on base tables rather than using 
//     select on views.
//
// PREREQUISITE:
//    On Unix:    copy boots.xsd file from <install_path>/sqllib
//                /samples/xml/data directory to current directory.
//                copy musicplayer.xsd file from <install_path>/sqllib
//                /samples/xml/data directory to current directory. 
//    On Windows: copy boots.xsd file from <install_path>\sqllib\samples\
//                xml\data directory to current directory
//                copy musicplayer.xsd file from <install_path>\sqllib\
//                samples\xml\data directory to current directory
//
// EXECUTION: javac XmlCheckConstraint.java
//            java XmlCheckConstraint
//
// INPUTS: NONE
//
// OUTPUTS: One of the insert statements will fail because of check
//          constraint violation. All other statements will succeed.
//          
//
// OUTPUT FILE: XmlCheckConstraint.out (available in the online documentation)
//
// SQL STATEMENTS USED:
//           CREATE
//           INSERT
//           DELETE
//           DROP
//
// SQL/XML FUNCTIONS USED:
//           XMLDOCUMENT
//           XMLPARSE
//           XMLVALIDATE
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
//
// 1. Register XML schemas
//
// 2. Create tables with check constraint on XML column and insert data into
//    tables.
//
// 3. Show partitioning of tables by schema.
//
// 4. Show usage of IS VALIDATED and IS NOT VALIDATED predicates.
//
// 5. Shows insert statement failure when check constraint is violated.
//
// 6. Show check constraint and view dependency on schema.
//
//***************************************************************************
//
//   IMPORT ALL PACKAGES AND CLASSES
//
//**************************************************************************/

import java.lang.*;
import java.sql.*;
import java.io.*;
import java.util.*;
import com.ibm.db2.jcc.DB2Xml;

class XmlCheckConstraint
{
  public static void main(String argv[])
  {
    int rc = 0;
    String url = "jdbc:db2:sample";
    Connection con = null;
    try
    {

      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();

      // connect to the 'sample' database
      con = DriverManager.getConnection( url );
      System.out.println();
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
  
    System.out.println("THIS SAMPLE SHOWS HOW TO CREATE CHECK CONSTRAINTS"); 
    System.out.println(" ON XML COLUMN");
    System.out.println("------------------------------------------------\n");

    registerXmlSchemaBoots(con);
    registerXmlSchemaMusicPlayer(con);
    createCheckConstrainOnXmlColumn(con);
    partitionTablesBySchema(con);
    usageOfValidatedPredicates(con);
    checkConstraintViolation(con);
    dependencyOnSchema(con);
    cleanUp(con);
  } //main

  //**************************************************************************
  // 1. Register XML schemas
  //**************************************************************************
  static void registerXmlSchemaBoots(Connection con)
  {
    String relSchema=new String("POSAMPLE1");
    String schemaName=new String("boots");;
    String schemaLocation= new String("http://posample1.org/boots");
    String primaryDocument= new String("boots.xsd");
    int shred = 0;

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
  } //registerXmlSchemaBoots

  static void registerXmlSchemaMusicPlayer(Connection con)
  {
    String relSchema=new String("POSAMPLE1");
    String schemaName=new String("musicplayer");;
    String schemaLocation= new String("http://posample1.org/musicplayer");
    String primaryDocument= new String("musicplayer.xsd");
    int shred = 0;

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
  } //registerXmlSchemaMusicPlayer

  //**************************************************************************
  // 2. Create tables with check constraint on XML column and insert data into
  //    tables.
  //**************************************************************************
  static void createCheckConstrainOnXmlColumn(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();

      System.out.println("Create table with check constraints and insert");
      System.out.println(" data into tables ");
      System.out.println("-----------------------------------------------\n");

      // Shows check constraint on multiple schemas
      String str = "CREATE TABLE item(custid int, xmldoc XML constraint "+
                   "valid_check CHECK(xmldoc IS VALIDATED ACCORDING TO "+
                   "XMLSCHEMA IN (ID posample1.musicplayer, ID posample1.boots)))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);
   
      str = "INSERT INTO item "+
            "VALUES(100, xmlvalidate(xmlparse(document "+
            "'<Product xmlns=\"http://posample1.org\"  PoNum=\"5001\" "+
              "PurchaseDate= \"2006-03-01\"> "+
                "<musicplayer>"+
                  "<name>samsung</name>"+
                  "<power> 200 watts</power> "+
                  "<NoOfSpeakers>5</NoOfSpeakers>"+
                  "<NoiseRatio>3</NoiseRatio>"+
                  "<NoOfDiskChangers>2</NoOfDiskChangers>"+
                  "<price>400.00</price>"+
                "</musicplayer>"+
            " </Product>') ACCORDING TO XMLSCHEMA ID posample1.musicplayer))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);

      str = "INSERT INTO item "+
            "VALUES (100, XMLVALIDATE(XMLPARSE(document "+
            "'<Product xmlns=\"http://posample1.org\" PoNum=\"5002\" "+
              "PurchaseDate=\"2006-04-02\">"+
                "<boots>"+
                 "<name>adidas</name>"+
                 "<size>7</size>"+
                 "<quantity>10</quantity>"+
                 "<price>299.9</price>"+
                "</boots>"+
            "</Product>') ACCORDING TO XMLSCHEMA ID posample1.boots))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);
 
      str = "CREATE TABLE musicplayer (custid int, "+
                   "xmldoc XML constraint valid_check1 CHECK(xmldoc "+
                   "IS VALIDATED ACCORDING TO XMLSCHEMA ID "+
                   " posample1.musicplayer))";

      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);

      str = "INSERT INTO musicplayer "+
            "VALUES(100, xmlvalidate(xmlparse(document "+
              "'<Product xmlns=\"http://posample1.org\" PoNum=\"1001\" "+
               "PurchaseDate=\"2006-03-01\">"+
                 "<musicplayer>"+
                   "<name>sony</name>"+
                   "<power> 100 watts</power>"+
                   "<NoOfSpeakers>5</NoOfSpeakers>"+
                   "<NoiseRatio>3</NoiseRatio>"+
                   "<NoOfDiskChangers>4</NoOfDiskChangers>"+
                   "<price>200.00</price>"+
                 "</musicplayer>"+
              " </Product>') ACCORDING TO XMLSCHEMA ID posample1.musicplayer))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);

      str = "CREATE TABLE boots (custid int, "+
            "xmldoc XML constraint valid_check2 CHECK(xmldoc "+
            "IS VALIDATED ACCORDING TO XMLSCHEMA ID posample1.boots))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);

      str = "INSERT INTO boots "+
            "VALUES (100, XMLVALIDATE(XMLPARSE(document "+
            "'<Product xmlns=\"http://posample1.org\" PoNum=\"1002\" "+
              "PurchaseDate=\"2006-04-02\">"+
                "<boots>"+
                   "<name>nike</name>"+
                   "<size>7</size>"+
                   "<quantity>10</quantity>"+
                   "<price>99.9</price>"+
                "</boots>"+
             "</Product>') ACCORDING TO XMLSCHEMA ID posample1.boots))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);
     
      stmt.close(); 
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
  } //createCheckConstrainOnXmlColumn

  //**************************************************************************
  // 3. Show partitioning of tables by schema.
  //**************************************************************************

  static void partitionTablesBySchema(Connection con)
  {
    Statement stmt = null;
    try
    {
      System.out.println();
      System.out.println("--------------------------------------------");
      System.out.println(" Partition tables by schema                 ");
      System.out.println("--------------------------------------------");
      System.out.println();
        
      stmt = con.createStatement();
      String str = "CREATE VIEW view_purchases(custid, xmldoc) AS "+
                   "(SELECT  * FROM musicplayer " +
                   "UNION ALL SELECT * FROM boots)";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);
    
      str = "INSERT INTO view_purchases "+
            "VALUES (1001,xmlvalidate(xmlparse(document "+
            "'<Product xmlns=\"http://posample1.org\"  PoNum=\"1007\" "+
              "PurchaseDate=\"2006-03-10\">"+
                "<musicplayer>"+
                   "<name>philips</name>"+
                   "<power> 1000 watts</power>"+
                   "<NoOfSpeakers>2</NoOfSpeakers>"+
                   "<NoiseRatio>5</NoiseRatio>"+
                   "<NoOfDiskChangers>4</NoOfDiskChangers>"+
                   "<price>1200.00</price>"+
                "</musicplayer>"+
             "</Product>') ACCORDING TO XMLSCHEMA ID posample1.musicplayer))";
      System.out.println();
      System.out.println(str);
      stmt.executeUpdate(str);
  
      str = "INSERT INTO view_purchases "+
            "VALUES (1002, XMLVALIDATE(XMLPARSE(document "+
            "'<Product xmlns=\"http://posample1.org\" PoNum=\"1008\" "+
              "PurchaseDate=\"2006-04-12\">"+
                "<boots>"+
                   "<name>adidas</name>"+
                   "<size>10</size>"+
                   "<quantity>2</quantity>"+
                   "<price>199.9</price>"+
                "</boots>"+
            "</Product>') ACCORDING TO XMLSCHEMA ID posample1.boots))"; 
      System.out.println();
      System.out.println(str);
      stmt.executeUpdate(str);


      System.out.println();
      System.out.println("SELECT * FROM musicplayer ORDER BY custid");
      System.out.println("--------------------------------------------");
      System.out.println();
      PreparedStatement pstmt = con.prepareStatement(
                                "SELECT * FROM musicplayer ORDER BY custid");
      ResultSet rs = pstmt.executeQuery(); 
  
      int custid = 0;
      String info = null;
      
      while (rs.next())
      {
        custid = rs.getInt(1);
        info= rs.getString(2);

        System.out.println(Data.format(custid , 10)+"      "+
                           Data.format(info,1024));
      }
  

      System.out.println("SELECT * FROM boots ORDER BY custid");
      System.out.println("--------------------------------------------");
      System.out.println();

      pstmt = con.prepareStatement("SELECT * FROM boots ORDER BY custid");
      rs = pstmt.executeQuery();

      while (rs.next())
      {
        custid = rs.getInt(1);
        info= rs.getString(2);

        System.out.println(Data.format(custid , 10)+"      "+
                           Data.format(info,1024));
      }

      rs.close();

      stmt.close();
      pstmt.close();
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
  } //partitionTablesBySchema

  //**************************************************************************
  // 4. Show usage of IS VALIDATED and IS NOT VALIDATED predicates.
  //**************************************************************************

  static void usageOfValidatedPredicates(Connection con)
  {
    try
    {
      System.out.println("-------------------------------------------");
      System.out.println("Show usage of IS VALIDATED predicate");
      System.out.println("-------------------------------------------");

      System.out.println("Get customer addresses from customer table"+
                         " for the customers who purchased boots or "+
                         " musicplayers ");
      System.out.println();

      PreparedStatement pstmt = con.prepareStatement(
                         "SELECT custid, info "+
                         "FROM customer C, view_purchases V "+
                         "WHERE V.custid = C.Cid AND info IS VALIDATED ORDER BY custid");

      System.out.println("SELECT custid, info "+
                         "FROM customer C, view_purchases V "+
                         "WHERE V.custid = C.Cid AND info IS VALIDATED");
      System.out.println();
      ResultSet rs = pstmt.executeQuery();

      int custid = 0;
      String info = null;

      while (rs.next())
      {
        custid = rs.getInt(1);
        info = rs.getString(2);

        System.out.println(Data.format(custid, 10)+"             "+
                           Data.format(info, 1024)); 
      }

      System.out.println("Show usage of IS NOT VALIDATED predicate");
      System.out.println("-------------------------------------------");
      System.out.println();

      String str = "CREATE TABLE temp_table (custid int, xmldoc XML)"; 
      Statement stmt = con.createStatement();
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);
 
      str = "INSERT INTO temp_table "+
            "VALUES(1003, "+
            "'<Product xmlns=\"http://posample1.org\" PoNum=\"1009\" "+
              "PurchaseDate=\"2006-04-17\">"+
                "<boots>"+
                  "<name>Red Tape</name>"+
                  "<size>6</size>"+
                  "<quantity>2</quantity>"+
                  "<price>1199.9</price>"+
                "</boots>"+
            "</Product>')"; 

      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);

  
      str = "INSERT INTO temp_table "+
            "VALUES(1004, XMLVALIDATE(XMLPARSE(document "+
            "'<Product xmlns=\"http://posample1.org\" PoNum=\"1010\" "+
              "PurchaseDate=\"2006-04-19\">"+
                 "<boots>"+
                    "<name>Liberty</name>"+
                    "<size>6</size>"+
                    "<quantity>2</quantity>"+
                    "<price>900.90</price>"+
                 "</boots>"+
            "</Product>') ACCORDING TO XMLSCHEMA ID posample1.boots))";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);


      str = "CREATE VIEW temp_table_details AS "+
            "(SELECT * FROM temp_table "+
            "WHERE xmldoc IS NOT VALIDATED)";
      System.out.println(str);
      System.out.println();
      stmt.executeUpdate(str);

      pstmt = con.prepareStatement("SELECT * FROM temp_table_details");
      rs = pstmt.executeQuery();
  
      while (rs.next())
      {
        custid = rs.getInt(1);
        info = rs.getString(2);
        System.out.println(Data.format(custid, 10)+"             "+
                           Data.format(info, 1024));
      }
     
      rs.close();
      stmt.close();
      pstmt.close(); 
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
  } //usageOfValidatedPredicates

  //**************************************************************************
  // 5. Shows insert statement failure when check constraint is violated.
  //**************************************************************************

  static void checkConstraintViolation(Connection con)
  {
    Statement stmt = null;
    try
    {
      stmt = con.createStatement();
      String str = "INSERT INTO musicplayer "+
                   "VALUES (1005, XMLVALIDATE(XMLPARSE(document "+
                   "'<Product xmlns=\"http://posample1.org\" PoNum=\"1011\" "+
                      "PurchaseDate=\"2006-04-17\">"+
                         "<boots>"+
                            "<name>Red Tape</name>"+
                            "<size>6</size>"+
                            "<quantity>2</quantity>"+
                            "<price>1199.9</price>"+
                         "</boots>"+
                   "</Product>') ACCORDING TO XMLSCHEMA ID posample1.boots))";
       stmt.executeUpdate(str);
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
    }
    catch(Exception e)
    {}
  } //checkConstraintViolation  

  //**************************************************************************
  // 6. Show check constraint and view dependency on schema.
  //**************************************************************************

  static void dependencyOnSchema(Connection con)
  {
    Statement stmt = null;
    try
    {

       System.out.println("Shows constraint and view dependency on schema");
       System.out.println("-----------------------------------------------");
       System.out.println();

       stmt = con.createStatement();
       String str = "DROP XSROBJECT posample1.boots";
   
       System.out.println("DROP XSROBJECT posample1.boots");
       System.out.println();
       stmt.executeUpdate(str);

       str = "INSERT INTO boots "+
             "VALUES (1006, "+
             "'<Product xmlns=\"http://posample1.org\" PoNum=\"1011\" "+
                "PurchaseDate=\"2006-04-17\">"+
                  "<boots>"+
                    "<name>Red Tape</name>"+
                    "<size>6</size>"+
                    "<quantity>2</quantity>"+
                    "<price>1199.9</price>"+
                  "</boots>"+
             " </Product>')";
       System.out.println(str);
       System.out.println();
       System.out.println("Insert succeeds without any validation\n");
       stmt.executeUpdate(str);

       str = "INSERT INTO view_purchases "+
             "VALUES (1007, "+
             "'<musicplayer xmlns=\"http://posample1.org\"  PoNum=\"1006\" "+
               "PurchaseDate=\"2006-03-10\">"+
                 "<name>philips</name>"+
                 "<power> 1000 watts</power>"+
                 "<NoOfSpeakers>2</NoOfSpeakers>"+
                 "<NoiseRatio>5</NoiseRatio>"+
                 "<NoOfDiskChangers>4</NoOfDiskChangers>"+
                 "<price>1200.00</price>"+
             "</musicplayer>')";
       System.out.println(str);
       System.out.println();
       System.out.println("Insert succeeds without any validation\n");
       stmt.executeUpdate(str);

       stmt.close();
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
    }
    catch(Exception e)
    {}
  } //dependencyOnSchema

  //**************************************************************************
  //                      Cleanup
  //**************************************************************************

  static void cleanUp(Connection con)
  {
    Statement stmt = null;

    try
    {
      stmt = con.createStatement();

      String str = "DROP XSROBJECT POSAMPLE1.MUSICPLAYER";
      stmt.executeUpdate(str);

      str = "DROP TABLE item";
      stmt.executeUpdate(str);

      str = "DROP TABLE musicplayer";
      stmt.executeUpdate(str);

      str = "DROP TABLE boots";
      stmt.executeUpdate(str);

      str = "DROP VIEW view_purchases";
      stmt.executeUpdate(str);
 
      str = "DROP VIEW temp_table_details";
      stmt.executeUpdate(str); 
   
      str = "DROP TABLE temp_table";
      stmt.executeUpdate(str); 

      stmt.close();
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
  } //cleanUp
} //XmlCheckConstraint class
