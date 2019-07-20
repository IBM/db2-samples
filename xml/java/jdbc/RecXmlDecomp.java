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
// **************************************************************************
//                                                                          
// SAMPLE FILE NAME: RecXmlDecomp.java                                          
//
// PURPOSE: How to register a recursive XML schema to the XSR and
//          enable the same for decomposition.
//
// USER SCENARIO:
//	   The existing PurchaseOrder schema in the Sample database is 
//   enhanced to have new Employee tables to process the purchase orders. 
//   We have Recursive Schema for Employee data management, an employee
//   can be a manager and himself reporting to another employee. The XML document 
//   contains the employee information along with department details which needs
//   to be stored in relational tables for easy retrieval of data.         
//
//  PREREQUISITE:
//        The instance document and the annotated schema should exist in the same 
//        directory as the sample. Copy recemp.xml, recemp.xsd from directory 
//        <install_path>/sqllib/samples/xml/data in UNIX and
//        <install_path>\sqllib\samples\xml\data in Windows to the working directory.
//                                                                          
//  EXECUTION:    i)  javac RecXmlDecomp.java ( Compile the sample)
//                ii) java RecXmlDecomp       ( Run the sample)
//                                                                          
//  INPUTS:       NONE
//                                                                          
//  OUTPUTS:      Decomposition of XML document according to the annotations 
//                in recursive schema. 
//                                                                          
//  OUTPUT FILE:  RecXmlDecomp.out (available in the online documentation)      
//                                     
//  SQL STATEMENTS USED:                                                    
//        REGISTER XMLSCHEMA                                                  
//        COMPLETE XMLSCHEMA      
//        DECOMPOSE XML DOCUMENT                                          
//        CREATE   
//        SELECT 
//        DROP                                          
//  
// Classes used from Util.java are:
//         Db
//         Data
//         JdbcException
//         Statement
//         ResultSet
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
// *****************************************************************************
// 1. Register the annotated recursive XML schema.
// 2. Decompose the XML document using the registered XML schema.
// 3. Select data from the relational tables to see the decomposed data.
// *****************************************************************************

import java.lang.*;
import java.sql.*;
import java.io.*;
import com.ibm.db2.jcc.DB2Xml; 

class RecXmlDecomp
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println();
      System.out.println("THIS SAMPLE SHOWS: How to register a recursive XML schema");
      System.out.println(" to the XSR and enable the same for decomposition.");
      System.out.println();

      // connect to the 'sample' database
      db.connect();

      // call the function to decompose data
      RecXmlDecompose(db.con);

      // disconnect from the 'sample' database
      db.disconnect();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // main
  
  static void RecXmlDecompose(Connection con)
  {
    try
      {
         String dbname;
         String RelSchema;
         String SchemaName;
         String SchemaLocation;
         String PrimaryDocument;
         String xmlfilename;
         int shred = 1;
         String Status;
         String Decomposition;
         String Decomposition_version;
         boolean  xmlRegister = false;
         boolean  xmlAdd = false;
         boolean  xmlComplete = false;
         boolean  xmlDecomp = false;
        
         System.out.println(
          "\n Execute Statement: \n" +
          "CREATE TABLE xdb.poemployee(empid VARCHAR(20),deptid VARCHAR(20),members XML) \n");

         Statement stmt1 = con.createStatement();  
         String create = "CREATE TABLE xdb.poemployee (empid VARCHAR(20), deptid VARCHAR(20), members XML)" ;
         stmt1.executeUpdate(create);

         // ***************************************************************************
         //     1. Register the recursive XML schema.
         // ***************************************************************************

         RelSchema = "xdb";
         SchemaName = "employee";
         SchemaLocation = "http://porder.com/employee.xsd";
         PrimaryDocument = "recemp.xsd";
         xmlfilename = "recemp.xml";
 
         // Register the XML Schema to the XSR.
         CallableStatement callStmt = con.prepareCall("CALL SYSPROC.XSR_REGISTER(?,?,?,?,NULL)");
         File xsdfile = new File(PrimaryDocument);
         FileInputStream xsdfileis = new FileInputStream(xsdfile);

         callStmt.setString(1, RelSchema );
         callStmt.setString(2, SchemaName );
         callStmt.setString(3, SchemaLocation );
         callStmt.setBinaryStream(4, xsdfileis, (int)xsdfile.length() );
         callStmt.execute();
         xsdfileis.close();
         callStmt.close();
         System.out.println("**** CALL SYSPROC.XSR_REGISTER SUCCESSFULLY");

         // Complete the Schema registration with Validate Option true.
         callStmt = con.prepareCall("CALL SYSPROC.XSR_COMPLETE(?,?,NULL,?)");
         callStmt.setString(1, RelSchema );
         callStmt.setString(2, SchemaName );
         callStmt.setInt(3, shred );
         callStmt.execute();
         callStmt.close();
         System.out.println("**** CALL SYSPROC.XSR_COMPLETE SUCCESSFULLY");

         // Check the status of the XSR object registered.
         Statement stmt = con.createStatement();
         ResultSet rs = stmt.executeQuery(
           "SELECT status, decomposition, decomposition_version FROM SYSIBM.SYSXSROBJECTS WHERE XSROBJECTNAME = 'EMPLOYEE'");
   
         while(rs.next())
          {
            Status = rs.getString(1);
            Decomposition = rs.getString(2);
            Decomposition_version = rs.getString(3);

            System.out.println("\nStatus          : " +
                               Data.format(Status, 5) + "\n" +
                               "Decomposition   : " +
                               Data.format(Decomposition, 5) + "\n" +
                               "Version         : " +
                               Data.format(Decomposition_version, 5));
          } 
        rs.close();       

        // ***************************************************************************
        //     2. Decompose the XML document using the registered XML schema.
        // ***************************************************************************

        // Decompose the XML document by calling the SYSPROC.XDBDECOMPXML
        callStmt = con.prepareCall("CALL SYSPROC.XDBDECOMPXML(?,?,?,?,?, NULL, NULL, NULL)");
        File xmlfile = new File(xmlfilename);
        FileInputStream xmlfileis = new FileInputStream(xmlfile);
        callStmt.setString(1, RelSchema );
        callStmt.setString(2, SchemaName );
        callStmt.setBinaryStream(3, xmlfileis, (int)xmlfile.length() );
        callStmt.setString(4, SchemaName );
        callStmt.setInt(5, shred);
        callStmt.execute();
        xmlfileis.close();
        callStmt.close();
        System.out.println("**** CALL SYSPROC.XDBDECOMPXML SUCCESSFULLY");

        // ***************************************************************************
        //     3. Select data from the relational tables to see the decomposed data.
        // ***************************************************************************

        // Read Data from the tables, where the data is stored after decomposition.
        SelectFromTable(con);

        // Drop the XSROBJECT
        String drop = "DROP XSROBJECT xdb.employee"; 
        stmt1.executeUpdate(drop);
 
        // Drop the table
        drop = "DROP TABLE xdb.poemployee";
        stmt1.executeUpdate(drop);
    
      }
    catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e, con);
        jdbcExc.handle();
      }
  }
  static void SelectFromTable(Connection con)
  {
    try
      {
        
        String empid = "";
        String deptid = "";
        String members = "";
        
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery(
          "SELECT empid, deptid,xmlserialize( members as varchar(500)) FROM XDB.POEMPLOYEE ORDER BY empid");

        while (rs.next())
          {
            empid = rs.getString(1);
            deptid = rs.getString(2);
            members = rs.getString(3) ;
 
            System.out.println("\nEMPID          : " +
                               Data.format(empid, 13) + "\n" +
                               "DEPTID           : " +
                               Data.format(deptid, 5) + "\n" +
                               "MEMBERS          : " +
                               Data.format(members, 500) );
          } 
      }
    catch (Exception e)
      {
        JdbcException jdbcExc = new JdbcException(e, con);
        jdbcExc.handle();
      } //Try Block
   }  //SelectFromTable
}  //RecXmlDecomp Class  
   
