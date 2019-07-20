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
// SOURCE FILE NAME: XmlIndex.java
//
// SAMPLE: How to create an index on an XML column in different ways
//
// SQL Statements USED:
//         SELECT
//
// JAVA 2 CLASSES USED:
//         Statement
//         PreparedStatement
//         ResultSet
//
//
// OUTPUT FILE: XmlIndex.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//***************************************************************************
//
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//     http://www.software.ibm.com/data/db2/udb/ad
//**************************************************************************/

import java.lang.*;
import java.sql.*;
import java.io.*;
import java.util.*;
import com.ibm.db2.jcc.DB2Xml;

class XmlIndex
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

   
    System.out.println("THIS SAMPLE SHOWS HOW TO CREATE INDEX ON "+
                       "XML COLUMNS IN DIFFERENT WAYS"); 

    //Different ways to create an index on XML columns 
    createandInsertIntoTable(con);
    createIndex(con); 
    createIndexwithSelf(con);
    createIndexonTextnode(con);  
    createIndexwith2Paths(con);
    createIndexwithNamespace(con);
    createIndexwith2Datatypes(con);
    createIndexuseAnding(con);
    createIndexuseAndingOrOring(con);  
    createIndexwithDateDatatype(con);
    createIndexOnCommentNode(con);
    dropall(con);

  } // main

  // This function creates a table and inserts rows having
  // XML data
  static void createandInsertIntoTable(Connection con)
  {
    Statement stmt = null;
    try
    {
      System.out.println();
      System.out.println(
         "-------------------------------------------------\n" +
         "USE JAVA 2 CLASS: \n" +
         "statement \n" +
         "To execute a query. ");      

      stmt = con.createStatement();
    
      //execute the query
    
      System.out.println();
      System.out.println(
          "Execute Statement:" +
          "   CREATE TABLE COMPANY(id INT, docname VARCHAR(20), doc XML)");

      String create = "CREATE TABLE company(id INT,"+ 
                                            "docname VARCHAR(20),"+ 
                                            "doc XML)";
      stmt.executeUpdate(create);

      System.out.println(); 
      System.out.println("Insert row1 into table \n");
      stmt = con.createStatement(); 
      stmt.executeUpdate(
           "INSERT INTO company VALUES (1, 'doc1', xmlparse " +
           "(document '<company name = \"Company1\"> <emp id = \"31201\""+
           " salary = \"60000\" gender = \"Female\" DOB = \"10-10-80\">" +
           " <name><first>Laura </first><last>Brown</last></name>" +
           "<dept id = \"M25\">Finance</dept><!-- good --></emp>" +
           "</company>'))"); 

      stmt = con.createStatement(); 
      System.out.println("Insert row2 into table \n");
      stmt.executeUpdate(
           " INSERT INTO company VALUES (2,'doc2',xmlparse (" +
           "document '<company name = \"Company2\"><emp id = \"31664\" "+
           "salary = \"60000\" gender = \"Male\" DOB = \"09-12-75\"><name> " +   
           "<first>Chris</first><last>Murphy</last></name> " +
           "<dept id = \"M55\">Marketing</dept></emp><emp id = \"42366\" "+
           "salary = \"50000\" gender = \"Female\" DOB = \"08-21-70\"><name> "+
           "<first>Nicole</first><last>Murphy</last></name> " +
           "<dept id = \"K55\">Sales</dept></emp>  </company>'))" );
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // createandInsertIntoTable

  // This function creates an index and shows how we can use XQUERY on 
  // the index created
  static void createIndex(Connection con)
  {
    try
    {
      System.out.println("create index on attribute \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex1 ON company(doc) " +
                         "GENERATE KEY USING XMLPATTERN '/company/emp/@*'"+
                         " AS SQL VARCHAR(25)\n ");
      stmt.executeUpdate(
                "CREATE INDEX empindex1 ON company(doc) GENERATE KEY "+
                "USING XMLPATTERN '/company/emp/@*' AS SQL VARCHAR(25) ");

      ResultSet rs = stmt.executeQuery("XQUERY for $i in db2-fn:" +
                             "xmlcolumn('COMPANY.DOC') /company/"+
                             "emp[@id = '42366'] return $i/name "); 

      System.out.println("-----------------------------------------------");
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        System.out.println();
      } 
      System.out.println("-----------------------------------------------");
    
      rs.close(); 
      stmt.close();
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // createIndex

  // This function creates an index with self or descendent forward 
  // axis and shows how we can use XQUERY on the index
  static void createIndexwithSelf(Connection con)
  {
    try
    {
      System.out.println("create index with self or " +
                         "descendent forward axis \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex2 ON company(doc)  "+
                          "GENERATE KEY USING XMLPATTERN '//@salary' "+
                          "AS SQL DOUBLE\n");

      stmt.executeUpdate(
               "CREATE INDEX empindex2 ON company(doc)  GENERATE KEY "+
               "USING XMLPATTERN '//@salary' AS SQL DOUBLE  ");
      ResultSet rs = stmt.executeQuery("XQUERY for $i in db2-fn:xmlcolumn"+
                                   "('COMPANY.DOC') /company/emp[@salary "+
                                   "> 35000] return <salary>{$i/@salary}"+
                                   " </salary>");

      System.out.println("-----------------------------------------------");
      String name = null;
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        System.out.println();
      }

      System.out.println("-----------------------------------------------");
      rs.close();
      stmt.close();
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // createIndexwithSelf

  // This function creates an index on a text mode and shows how to use 
  // XQUERY on the index
  static void createIndexonTextnode(Connection con)
  {
    try
    {
      System.out.println("create index on a text mode\n");
      Statement stmt = con.createStatement();
      System.out.println("CREATE INDEX empindex3 ON company(doc) GENERATE"+
                         " KEY USING XMLPATTERN '/company/emp/dept/text()'"+
                         " AS SQL VARCHAR(30)\n ");                
      stmt.executeUpdate(
               "CREATE INDEX empindex3 ON company(doc) GENERATE KEY USING"+
               " XMLPATTERN '/company/emp/dept/text()' AS SQL VARCHAR(30) "); 

      ResultSet rs = stmt.executeQuery("XQUERY for $i in db2-fn:xmlcolumn"+
                                       "('COMPANY.DOC')/ company/emp[dept"+
                                       "/text() = 'Finance' or dept/text()"+
                                       " = 'Marketing'] return $i/name"  );

      System.out.println("-----------------------------------------------");
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        System.out.println();
      }
      System.out.println("-----------------------------------------------");
      rs.close();
      stmt.close();

    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } //createIndexonTextnode

  // This function creates an index when 2 paths are qualified by 
  // an XML and also shows how to use XQUERY on the index
  static void createIndexwith2Paths(Connection con)
  {
    try
    {
      System.out.println("create index when 2 paths are qualified "+
                                                     "by an XML \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex4 ON company(doc) "+
                         "GENERATE KEY USING XMLPATTERN '//@id' AS "+
                         "SQL VARCHAR(25)\n");

      stmt.executeUpdate(
                "CREATE INDEX empindex4 ON company(doc) GENERATE KEY USING"+
                " XMLPATTERN '//@id' AS SQL VARCHAR(25)");
      ResultSet rs = stmt.executeQuery("XQUERY for $i in db2-fn:xmlcolumn" +
                                       "('COMPANY.DOC') /company/emp[@id = "+
                                       "'31201']  return $i/name");     
      System.out.println("-----------------------------------------------");
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        System.out.println();
      }
      System.out.println("-----------------------------------------------");

      System.out.println("XQUERY for $j in db2-fn:xmlcolumn('COMPANY.DOC')"+
             "/company/emp[dept/@id = 'K55']  return $j/name");

      ResultSet rs1  = stmt.executeQuery("XQUERY for $j in db2-fn:xmlcolumn"+
                                         "('COMPANY.DOC') /company/emp"+
                                         "[dept/@id = 'K55']  return $j/name");

      System.out.println("-----------------------------------------------");
      while (rs1.next())
      {
        com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs1.getObject(1);
        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        System.out.println();
      }
      System.out.println("-----------------------------------------------");
      rs.close();
      rs1.close();
      stmt.close();

    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // createIndexwith2Paths

  // This function creates an index with namespace
  static void createIndexwithNamespace(Connection con)
  {
    try
    {
      System.out.println("create index with namespace \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex5 ON company(doc) GENERATE "+
                         "KEY USING XMLPATTERN 'declare default element "+
                         "namespace \"http://www.mycompany.com/\";declare "+
                         "namespace m = \"http://www.mycompanyname.com/\";"+
                         "/company/emp/ @m:id' AS SQL VARCHAR(30)\n");
              
      stmt.executeUpdate(
                "CREATE INDEX empindex5 ON company(doc) GENERATE KEY USING"+
                " XMLPATTERN 'declare default element namespace  " +
                "\"http://www.mycompany.com/\";declare namespace " +
                "m = \"http://www.mycompanyname.com/\";/company/emp/ "+
                "@m:id' AS SQL VARCHAR(30)"); 

      stmt.close();
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // createIndexwithNamespace

  // This function creates an index with two different data types
  static void createIndexwith2Datatypes(Connection con)
  {
    try
    {
      System.out.println("create indexes with same XMLPATTERN but "+
                         "with different data types \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex6 ON company(doc) GENERATE "+
                         "KEY USING XMLPATTERN '/company/emp/@id' AS SQL "+
                         "VARCHAR(10)\n");

      stmt.executeUpdate(
                 "CREATE INDEX empindex6 ON company(doc)  GENERATE KEY "+
                 "USING XMLPATTERN '/company/emp/@id' AS SQL VARCHAR(10)");    

      System.out.println("CREATE INDEX empindex7 ON company(doc) GENERATE "+
                 " KEY USING XMLPATTERN '/company/emp/@id' AS SQL DOUBLE\n");

      stmt.executeUpdate(
                "CREATE INDEX empindex7 ON company(doc) GENERATE KEY "+
                " USING XMLPATTERN '/company/emp/@id' AS SQL DOUBLE");

      stmt.close();
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // createIndexwith2Datatypes

  // This function creates an index using joins and shows how 
  // to use XQUERY on the index created
  static void createIndexuseAnding(Connection con)
  {
    try
    {
      System.out.println("create index using joins (Anding) \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex8 ON company(doc) GENERATE "+
 	                 "KEY USING XMLPATTERN '/company/emp/name/last' "+
                         "AS SQL VARCHAR(100)\n");

      stmt.executeUpdate(
               "CREATE INDEX empindex8 ON company(doc) GENERATE KEY USING "+
               " XMLPATTERN '/company/emp/name/last' AS SQL VARCHAR(100)");

      System.out.println("CREATE INDEX deptindex on company(doc) GENERATE "+
                         "KEY USING XMLPATTERN '/company/emp/dept/text()' "+
                         "AS SQL VARCHAR(30)\n");

      stmt.executeUpdate(
               "CREATE INDEX deptindex on company(doc) GENERATE KEY USING "+
               " XMLPATTERN '/company/emp/dept/text()' AS SQL VARCHAR(30)");
 
      System.out.println("XQUERY for $i in db2-fn:xmlcolumn('COMPANY.DOC')"+
                         "/company/ emp[name/last = 'Murphy' and dept/text()"+
                         " = 'Sales']return $i/name/last");

      ResultSet rs = stmt.executeQuery("XQUERY for $i in db2-fn:xmlcolumn"+
                                       "('COMPANY.DOC')/company/ emp[name"+
                                       "/last = 'Murphy' and dept/text() ="+
                                       " 'Sales']return $i/name/last");

      System.out.println("----------------------------------------------");
      while (rs.next())
      {
         com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        System.out.println();
      }
      System.out.println("----------------------------------------------");
      rs.close();
      stmt.close();
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // createIndexuseAnding

  // This function creates an index using joins (ANDing or ORing)
  // and shows how to use XQUERY on the index created
  static void createIndexuseAndingOrOring(Connection con)  
  {
    try
    {
      System.out.println("create index using joins (Anding or Oring ) \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex9 ON company(doc) "+
                         "GENERATE KEY USING XMLPATTERN '/company"+
                         "/emp/@salary' AS SQL DOUBLE\n");
      stmt.executeUpdate(
                   "CREATE INDEX empindex9 ON company(doc) GENERATE KEY "+
   		   "USING XMLPATTERN '/company/emp/@salary' AS SQL DOUBLE");

      System.out.println("CREATE INDEX empindex10 ON company(doc) GENERATE"+
                         " KEY USING XMLPATTERN '/company/emp/dept' AS "+
                         " SQL VARCHAR(25)\n");
      stmt.executeUpdate(
                 "CREATE INDEX empindex10 ON company(doc) GENERATE KEY "+
                 "USING XMLPATTERN '/company/emp/dept' AS SQL VARCHAR(25)");

      System.out.println("CREATE INDEX empindex11 ON company(doc) GENERATE "+
                         "KEY USING XMLPATTERN '/company/emp/name/last' "+
                         "AS SQL VARCHAR(25)\n");
      stmt.executeUpdate(
                   "CREATE INDEX empindex11 ON company(doc) GENERATE KEY "+
                   "USING XMLPATTERN '/company/emp/name/last' AS SQL "+
                   "VARCHAR(25)");

      ResultSet rs = stmt.executeQuery("XQUERY for $i in db2-fn:xmlcolumn"+
                                 "('COMPANY.DOC')/company/emp [@salary"+
                                 " > 50000 and dept = 'Finance']/name"+
                                 "[last = 'Brown'] return $i/last");

      System.out.println("----------------------------------------------");
      while (rs.next())
      {
         com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
         // Print the result as an DB2 XML String
         System.out.println();
         System.out.println(data.getDB2XmlString());
         System.out.println();
      }
      System.out.println("----------------------------------------------");
      rs.close();
      stmt.close();

    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // createIndexuseAndingOrOring

  // This function creates an index with Date Data type and shows how
  // how to use an XQUERY on the index created
  static void createIndexwithDateDatatype(Connection con)
  {
    try
    {
      System.out.println("create index with Date Data type \n");
      Statement stmt = con.createStatement();

      System.out.println("CREATE INDEX empindex12 ON company(doc) GENERATE"+
                         "KEY USING XMLPATTERN '/company/emp/@DOB' as "+
                         "SQL DATE\n");
      stmt.executeUpdate(
                   "CREATE INDEX empindex12 ON company(doc) GENERATE KEY "+
                   "USING XMLPATTERN '/company/emp/@DOB' as SQL DATE");
      ResultSet rs = stmt.executeQuery("XQUERY for $i in db2-fn:xmlcolumn"+
                                    "('COMPANY.DOC') /company/emp[@DOB < "+
                                    "'11-11-78'] return $i/name");

      System.out.println("----------------------------------------------");
      while (rs.next())
      {
        com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
        // Print the result as an DB2 XML String
        System.out.println();
        System.out.println(data.getDB2XmlString());
        System.out.println();
      }
      System.out.println("----------------------------------------------");
      rs.close();
      stmt.close();
  
    }
    catch(Exception e)
    {
      System.out.println(e);
    }
  } // createIndexwithDateDatatype

  // This function creates an index on the comment node and shows
  // how to use XQUERY on the index created
  static void createIndexOnCommentNode(Connection con)
  {
    try
    {
       System.out.println("create index on comment node\n");
       Statement stmt = con.createStatement();

       System.out.println("CREATE INDEX empindex13 ON company(doc) GENERATE"+
                        "KEY USING XMLPATTERN '/company//comment() AS"+
                        " SQL VARCHAR HASHED");

       stmt.executeUpdate("CREATE INDEX empindex13 ON company(doc) GENERATE"+
                        " KEY USING XMLPATTERN '/company//comment()' AS"+
                        " SQL VARCHAR HASHED");

       ResultSet rs  = stmt.executeQuery("XQUERY for $i in db2-fn:xmlcolumn("+
                                        "'COMPANY.DOC') /company/emp[comment"+
                                        "() = ' good ']return $i/name");

       System.out.println("----------------------------------------------");
       while (rs.next())
       {
         com.ibm.db2.jcc.DB2Xml data = (com.ibm.db2.jcc.DB2Xml) rs.getObject(1);
         // Print the result as an DB2 XML String
         System.out.println();
         System.out.println(data.getDB2XmlString());
         System.out.println();
       }
       System.out.println("----------------------------------------------");
       rs.close();
       stmt.close();
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // createIndexOnCommentNode

  // This function does all clean up work. It drops all the indexes 
  // created and drops the table created
  static void dropall(Connection con)
  {
    try
    {
      Statement stmt = null;

      System.out.println("drop all indexes and table\n");
      System.out.println("-----------------------------\n");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX1\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX2\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX3\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX4\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX5\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX6\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX7\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX8\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX9\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX10\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX11\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX12\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"EMPINDEX13\"");
      stmt = con.createStatement();
      stmt.executeUpdate("DROP INDEX \"DEPTINDEX\"");


      System.out.println("drop table \n");
      stmt = con.createStatement();
      String drop = "DROP TABLE \"COMPANY\"";
      stmt.executeUpdate(drop);
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // dropall 
}
