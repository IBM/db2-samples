// *************************************************************************
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
// *************************************************************************
//                                                                          
// SAMPLE FILE NAME: XmlDecomposition.java                                     
//
// PURPOSE: To demonstrate annotated XML schema decomposition 
//
// USER SCENARIO:
//	       A bookstore has books for sale and the descriptive information about
//         each book is stored as an XML document. The store owner needs to store 
//         these details in different relational tables with referential 
//         constraints for easy retreival of data.
//         The Bookstore that has two types of customers, retail customers and
//         corporate customers. Corporate customers do bulk purchases of books
//         for their company libraries. The store has a DBA for maintaining 
//         the database, the store manager runs queries on different tables 
//         to view the book sales. The information about books returned by 
//         customers due to damage or due to exchange with some other book
//         is stored as xml document in books_returned table. At the end of 
//         the day a batch process decomposes these XML documents to update 
//         the books available status with the latest information. The batch 
//         process uses the DECOMPOSE XML DOCUMENTS command to decompose 
//         binary or XML column data into relational tables. 
//
// SOLUTION:
//         The store manager must have an annotated schema based on which the XML data 
//         can be decomposed. Once a valid annotated schema for the instance document  
//         is ready, it needs to be registered with the XML schema repository with 
//         the decomposition option enabled. Also, the tables in which the data will be 
//         decomposed must exist before the schema is registered. The user can 
//         decompose the instance documents and store the data in the relational 
//         tables using annotated XML Decomposition.
//
//    
//  PREREQUISITE:
//        The instance documents and the annotated schema must exist in the same
//        directory as the sample.
//        Copy bookdetails.xsd, booksreturned.xsd, bookdetails.xml,
//        booksreturned.del, booksreturned1.xml, booksreturned2.xml, booksreturned3.xml,
//        setupfordecomposition.db2 and cleanupfordecomposition.db2 from directory
//        <install_path>/sqllib/samples/xml/data in UNIX and
//        <install_path>\sqllib\samples\xml\data in Windows to the working directory.
//                                                                          
//  EXECUTION:    i)   db2 -tvf setupfordecomposition.db2 (setup script 
//                     to create the required tables and populate them)
//                ii)  javac XmlDecomposition.java (compile the sample)
//                     java XmlDecomposition (run the sample)               
//                iii) db2 -tvf cleanupfordecomposition.db2 (clean up 
//                     script to drop all the objects created)
//                                                                          
//  INPUTS:       NONE
//                                                                          
//  OUTPUTS:      Decomposition of XML documents according to the dependencies 
//                specified in the annotated XML schema.
//                                                                          
//  OUTPUT FILE:  XmlDecomposition.out  (available in the online documentation)      
//                                     
// SQL STATEMENTS USED:
//         REGISTER XMLSCHEMA
//         COMPLETE XMLSCHEMA
//         SELECT
//         CALL
//         DECOMPOSE XML DOCUMENT
//         DECOMPOSE XML DOUMENTS IN
//
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
//***************************************************************************
//
//  SAMPLE DESCRIPTION                                                     
//
// *************************************************************************
// 1. Register the annotated XML schemas.
// 2. Decompose a single XML document using the registered XML schema.
// 3. Decompose XML documents using the registered XML schema from
//    3.1. An XML column.
//    3.2. A BLOB column. 
// 4. Decompose XML documents from an XML column resulted by
//    4.1. Join operation 
//    4.2. Union operation
// *************************************************************************

import java.lang.*;
import java.sql.*;
import java.io.*;

class XmlDecomposition
{
	
  public static String relSchema=new String("XDB");
  public static String schemaName=new String("BOOKDETAILS");;
  public static String schemaLocation= new String("http://book.com/bookdetails.xsd");
  public static String primaryDocument= new String("bookdetails.xsd");
  
  public static String schemaName1=new String("BOOKSRETURNED");;
  public static String schemaLocation1= new String("http://book.com/booksreturned.xsd");
  public static String primaryDocument1= new String("booksreturned.xsd");

  public static String query = " "; 
  
  public static void main(String argv[])
  {
    try
    {
 
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS HOW TO " + "\n 1. DECOMPOSE A SINGLE XML DOCUMENT");
      System.out.println(" 2. DECOMPOSE XML DATA FROM AN XML COLOUMN ");
      System.out.println(" 3. DECOMPOSE XML DATA FROM A BLOB COLOUMN ");
      System.out.println(" 4. DECOMPOSE XML DATA FROM AN XML COLOUMN RESULT OF JOIN OPERATION");
      System.out.println(" 5. DECOMPOSE XML DATA FROM AN XML COLOUMN RESULT OF UNION OPERATION");

      // connect to the 'sample' database
      db.connect();
 
      // register the XML Schemas
      registerXmlSchema(db.con,schemaName,schemaLocation,primaryDocument);
      registerXmlSchema(db.con,schemaName1,schemaLocation1,primaryDocument1);
      
      System.out.println("/*************************************************************************");
      System.out.println(" Decompose a single XML document using the registered XML schema.");
      System.out.println("*************************************************************************/");

      singleXMLDecompose(db.con);
      
      System.out.println("/*************************************************************************");
      System.out.println(" Decompose XML documents from an XML column.");
      System.out.println("*************************************************************************/");

      query = "SELECT customerID, booksreturned FROM xdb.books_returned";
      bulkXmlDecompose(db.con, query);

      System.out.println("/************************************************************************* ");
      System.out.println(" Decompose XML documents from a BLOB column.");
      System.out.println("*************************************************************************/ ");

      query = "SELECT supplierID, booksinfo from xdb.books_received_BLOB";
      bulkXmlDecompose(db.con, query);

      System.out.println("/*************************************************************************");
      System.out.println(" Decompose XML documents from an XML column resulted by Join operation.");
      System.out.println("*************************************************************************/");
      query = "SELECT id, data FROM(SELECT br.customerID as id, br.booksreturned AS info " +
              "FROM xdb.books_returned as br,xdb.books_received AS brd " +
              "WHERE XMLEXISTS('$bi/books/book[@isbn] = $bid/books/book[@isbn]' " +
              "PASSING br.booksreturned as \"bi\", " +
              "brd.booksinfo as  \"bid\")) AS temp(id,data)";
      bulkXmlDecompose(db.con, query);

      
      System.out.println("/*************************************************************************");
      System.out.println(" Decompose XML documents from an XML column resulted by union operation.");
      System.out.println("*************************************************************************/");
      
      query = "SELECT id, data FROM(SELECT customerID as cid, booksreturned AS info " +
              "FROM xdb.books_returned " +
              "WHERE XMLEXISTS('$bk/books/book[author=\"Carl\"]' " +
              "PASSING booksreturned AS \"bk\") "+
              "UNION ALL " +
              "SELECT supplierID as sid, booksinfo AS books " +
              "FROM xdb.books_received " +
              "WHERE XMLEXISTS('$br/books/book[author=\"Carl\"]' " +
              "PASSING booksinfo AS \"br\")) AS temp(id,data) ";
      bulkXmlDecompose(db.con, query);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main

  
  
  // Method to register an XML Schema
  static void registerXmlSchema(Connection con,String schName,String schLoc,String schDoc)
  {
    try
    {
    	int shred = 1;
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
      
      // Check the status of the XSR object registered.
      PreparedStatement pstmt = con.prepareStatement(
           "SELECT status, decomposition, decomposition_version " +
           "FROM SYSIBM.SYSXSROBJECTS WHERE XSROBJECTNAME = ? ");
      pstmt.setString(1,schName);
      ResultSet rs = pstmt.executeQuery();
      while(rs.next())
          {
            String Status = rs.getString(1);
            String Decomposition = rs.getString(2);
            String Decomposition_version = rs.getString(3);

            System.out.println("\nStatus : " + Status + "\n" +
                               "Decomposition  : " + Decomposition + "\n" +
                               "Version : " + Decomposition_version);
          } 
      rs.close();    
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
  
  static void singleXMLDecompose(Connection con)
  {
    try
      {
         String xmlfilename = "bookdetails.xml";
         int shred = 1;
         
        // Decompose the XML document by calling the SYSPROC.XDBDECOMPXML
        CallableStatement callStmt = con.prepareCall("CALL SYSPROC.XDBDECOMPXML(?,?,?,?,?, NULL, NULL, NULL)");
        File xmlfile = new File(xmlfilename);
        FileInputStream xmlfileis = new FileInputStream(xmlfile);
        callStmt.setString(1, relSchema );
        callStmt.setString(2, schemaName );
        callStmt.setBinaryStream(3, xmlfileis, (int)xmlfile.length() );
        callStmt.setString(4, schemaName );
        callStmt.setInt(5, shred);
        callStmt.execute();
        xmlfileis.close();
        callStmt.close();
        System.out.println("**** CALL SYSPROC.XDBDECOMPXML SUCCESSFULLY");

        // Read Data from the tables, where the data is stored after decomposition.
        SelectFromAllTables(con);
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
      System.out.println("Error opening file ");
    }

  }
  
 static void bulkXmlDecompose(Connection con, String query)
  {
    try
      {
         System.out.print(query); 
        // Decompose the XML document by calling the SYSPROC.XDBDECOMPXML
        CallableStatement callStmt = 
        con.prepareCall("CALL SYSPROC.XDB_DECOMP_XML_FROM_QUERY('XDB','BOOKSRETURNED',?, 1, 0, 0, NULL, NULL, 1, ?, ?, ?)");
        System.out.println("Calling SYSPROC.XDB_DECOMP_XML_FROM_QUERY....");
        // register the output parameter
        callStmt.setString(1, query);
        callStmt.registerOutParameter(2, Types.INTEGER);
        callStmt.registerOutParameter(3, Types.INTEGER);
        callStmt.registerOutParameter(4, Types.BLOB);
        callStmt.execute();
        ResultSet rs = callStmt.getResultSet();   
        System.out.println("\n CALLED SYSPROC.XDB_DECOMP_XML_FROM_QUERY SUCCESSFULLY");
        int  totaldocs = callStmt.getInt(2);
        System.out.println("\nTotal documents to be decomposed:" + totaldocs);
        int  numdocsdecomposed = callStmt.getInt(3);
        System.out.println("\nNumber of documents decomposed:" + numdocsdecomposed);
        String err = callStmt.getObject(4).toString();     
        System.out.println("\n \n Error report :" + err);
        //callStmt.close();      

        // Read Data from the tables, where the data is stored after decomposition.
        SelectFromBooksAvail(con);
        //rs.close();      

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
  }
    
  
  static void SelectFromBooksAvail(Connection con)
  {
    try
      {
        String isbn = " ";
        int authid = 0;
        String authname = " ";
        String book_title = " ";
        float price =  0;
        int no_of_copies = 0;

        Statement stmt = con.createStatement();
        ResultSet rs1 = stmt.executeQuery("SELECT isbn, book_title, authid, authname, price, no_of_copies FROM XDB.BOOKS_AVAIL");
        System.out.println("\n SELECT isbn, book_title, authid, authname, price, no_of_copies FROM XDB.BOOKS_AVAIL");
        while(rs1.next())
          {
            isbn = rs1.getString(1);
            book_title = rs1.getString(2);
            authid = rs1.getInt(3);
            authname = rs1.getString(4);
            price = rs1.getFloat(5);
            no_of_copies = rs1.getInt(6);

            System.out.println("\nISBN  : " + isbn + 
                              "\nBook Title : " + book_title +
                              "\nAuthor ID : " + authid +
                              "\nAuthor : " + authname +
                              "\nPrice : " + price +
                              "\nNo of copies : " + no_of_copies);
          }
       // rs1.close();
       // stmt.close();
        Statement stmt1 = con.createStatement();
        stmt1.executeUpdate("DELETE FROM XDB.BOOKS_AVAIL");
       // stmt1.close();
 
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
 }  //SelectFromBooksAvail

  static void SelectFromAllTables(Connection con)
  {
    try
      {
        String isbn = " ";
        int chptnum = 0;
        String chpttittle = " ";
        String chptcontent = " ";
        int authid = 0;
        String authname = " ";
        String book_title = " ";
        String status = " ";
        String decompose = " ";
        String decomp_version = " ";

        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery(
          "SELECT isbn, chptnum, chpttitle, chptcontent FROM XDB.BOOK_CONTENTS");
        System.out.println("\n SELECT isbn, chptnum, chpttitle, chptcontent FROM XDB.BOOK_CONTENTS");
        while (rs.next())
          {
            isbn = rs.getString(1);
            chptnum = rs.getInt(2);
            chpttittle = rs.getString(3);
            chptcontent = rs.getString(4);
 
            System.out.println("\nISBN          : " + isbn + "\n" +
                               "Chapter Number  : " + chptnum + "\n" +
                               "Chapter Title   : " + chpttittle + "\n" +
                               "Chapter Content : " + chptcontent);
          } 
  
        // Select data from the ADMIN.BOOK_AUTHOR TABLE.
        rs = stmt.executeQuery("SELECT authid, authname, isbn, book_title FROM ADMIN.BOOK_AUTHOR");
        System.out.println("\n SELECT authid, authname, isbn, book_title FROM ADMIN.BOOK_AUTHOR");
        while(rs.next())
          {
            authid = rs.getInt(1);
            authname = rs.getString(2);
            isbn = rs.getString(3);
            book_title = rs.getString(4);
            
            System.out.println("\nAuthor ID   : " + authid + "\n" +
                              "Author Name    : " + authname + "\n" +
                              "ISBN       : " + isbn + "\n" +
                              "Book Title : " + book_title);
          } 
          rs.close();
          
          // Select data from the XDB.BOOKS_AVAIL TABLE.
          SelectFromBooksAvail(con);
 
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
   }  //SelectFromAllTables
   
   
}  //XmlDecomposition Class  
   

