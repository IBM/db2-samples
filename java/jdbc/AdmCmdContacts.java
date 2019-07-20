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
// SOURCE FILE NAME: AdmCmdContacts.java
//
// SAMPLE: How to add, update and drop contacts and contact groups
//
// Note: The Database Administration Server(DAS) should be running.
//
// JAVA 2 CLASSES USED:
//         Statement
//         CallableStatement
//
// Classes used from Util.java are:
//         Db
//         JdbcException
//
// OUTPUT FILE: AdmCmdContacts.out (available in the online documentation)
// Output will vary depending on the JDBC driver connectivity used.
//*************************************************************************
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

import java.io.*;     //JDBC classes           
import java.lang.*;
import java.util.*;
import java.sql.*;

class AdmCmdContacts
{

  public static void main(String argv[])
  {
    Connection con = null;
    String param = null;   
    CallableStatement callStmt = null;
    Db db = null;

    try
    {
      db = new Db(argv);

      System.out.print("\nTHIS SAMPLE SHOWS HOW TO:\n"); 
      System.out.print("  ADD, UPDATE AND DROP CONTACTS AND CONTACT GROUPS" +
                       " USING ADMIN_CMD.\n\n");
    
      // connect to the 'sample' database
      db.connect();
      con = db.con;

      // prepare the CALL statement for ADMIN_CMD
      String sql = "CALL SYSPROC.ADMIN_CMD(?)";
      callStmt = con.prepareCall(sql);
        
      // add contact testuser1 of type email address testuser1@test.com
      param = "ADD CONTACT testuser1 TYPE EMAIL ADDRESS testuser1@test.com";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact is added successfully\n");
    
      // add contact testuser2 of type email address testuser2@test.com
      param = "ADD CONTACT testuser2 TYPE EMAIL ADDRESS testuser2@test.com";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact is added successfully\n");
 
      // add contact group gname1 containing contact testuser1
      param = "ADD CONTACTGROUP gname1 CONTACT testuser1";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact group is added successfully.\n"); 
      
      // update contact testuser1 changing address to address@test.com
      param = "UPDATE CONTACT testuser1 USING ADDRESS address@test.com";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact is updated successfully\n");
 
      // update contact group gname1 by dropping the contact testuser2
      param = "UPDATE CONTACTGROUP gname1 ADD CONTACT testuser2";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact group is updated successfully\n");

      // get the list of contactgroups

      String str = ""; // used as intermediate string to prepare statement.

      // prepare the query
      System.out.println();
      System.out.println(
        "  Prepare Statement:\n" +
        "    SELECT * FROM  TABLE(SYSPROC.ADMIN_GET_CONTACTGROUPS())" + 
        " AS CONTACTGROUPS");

      str = "SELECT * FROM TABLE(SYSPROC.ADMIN_GET_CONTACTGROUPS())" +
            " AS CONTACTGROUPS";
 
      PreparedStatement pstmt = con.prepareStatement( str );

      System.out.println();
      System.out.println("  Execute prepared statement");
      ResultSet rs = pstmt.executeQuery();

      System.out.println();
      System.out.println("  Results:\n" +
                         "    NAME      DESCRIPTION    MEMBERNAME   " +
                         " MEMBERTYPE\n" +
                         "    -------- -------------- ------------- " + 
                         "------------");

      String name = "";
      String description = "";
      String mname = "";
      String mtype = "";

      while (rs.next())
      {
        name = rs.getString(1);
        description = rs.getString(2);
        mname = rs.getString(3);
        mtype = rs.getString(4);

        System.out.println("    " +
                           Data.format(name, 14) + " " +
                           Data.format(description, 12) + " " +
                           Data.format(mname, 14) + " " +
                           Data.format(mtype, 14));
      }
      rs.close();
      pstmt.close();

      // get the list of contacts

      // prepare the query
      System.out.println();
      System.out.println(
        "  Prepare Statement:\n" +
        "    SELECT * FROM table(SYSPROC.ADMIN_GET_CONTACTS()) AS CONTACTS");

      str = "SELECT * FROM table(SYSPROC.ADMIN_GET_CONTACTS()) AS CONTACTS";
      pstmt = con.prepareStatement( str );

      System.out.println();
      System.out.println("  Execute prepared statement");
      rs = pstmt.executeQuery();

      System.out.println();
      System.out.println("  Results:\n" +
                         "    NAME       TYPE        ADDRESS   \n" +
                         "    --------- --------  ----------------------");

      String cname = "";
      String ctype = "";
      String address = "";

      while (rs.next())
      {
        cname = rs.getString(1);
        ctype = rs.getString(2);
        address = rs.getString(3);

        System.out.println("    " +
                           Data.format(cname, 14) + " " +
                           Data.format(ctype, 12) + " " +
                           Data.format(address, 18));
      }
      rs.close();
      pstmt.close();
           
      // drop contact group gname1 
      param = "DROP CONTACTGROUP gname1";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact group is dropped successfully\n");

      // drop contact testuser1
      param = "DROP CONTACT testuser1";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact is dropped successfully\n");

      // drop contact testuser2
      param = "DROP CONTACT testuser2";

      // set the input parameter  
      callStmt.setString(1, param);
      System.out.println("\nCALL ADMIN_CMD('" + param + "')");

      // call the stored procedure
      callStmt.execute();
      System.out.print("The contact is dropped successfully\n");
  
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }      
    finally
    {
      try
      {
        // close the callStmt
        callStmt.close();

        // roll back any changes to the database made by this sample
        con.rollback();

        // disconnect from the 'sample' database
        db.disconnect();
      }
      catch (Exception x)
      { 
        System.out.print("\n Unable to Rollback/Disconnect ");
        System.out.println("from 'sample' database");    
      }
    }
  } // main
} // AdmCmdContacts
