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
// SOURCE FILE NAME: Applt.java
//
// SAMPLE: A Java applet that use JDBC JCC driver to access a database //
//         
//         This sample shows how to write a Java Applet that uses the
//         JDBC Type 4 driver to access a DB2 database.
//
//         This sample uses JDBC Type 4 driver to connect to 
//         the "sample" database. Run this sample using the 
//         following steps:
//         1. Create and populate the "sample" database with the following
//            command: db2sampl
//
//         2. Customize Applt.html with your server, port, user ID, and
//            password. Refer to Applt.html for details.
//
//         3. Compile the program with the following command:
//              javac Applt.java
//
//            Alternatively, you can compile the program with the following 
//            command if you have a compatible make/nmake program on 
//            your system:
//              make/nmake Applt 
//
//         4. Ensure that your working directory is accessible by your web
//            browser. If it is not, copy Applt.class and Applt.html into
//            a directory that is accessible.
//
//         5. Copy sqllib\java\db2jcc.jar on
//            Windows or sqllib/java/db2jcc.jar on UNIX, into the same
//            directory as Applt.class and Applt.html.
//
//         6. To run this sample, start your web browser (which must support
//            Java 1.3) and load Applt.html on your client machine.
//            You can view it locally with the following command:
//              appletviewer Applt.html
//
//
// SQL Statements USED:
//         SELECT
//         UPDATE
//
// OUTPUT FILE: None
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

import java.sql.*;
import java.awt.*;
import java.applet.Applet;

public class Applt extends Applet
{
  Connection con;

  public void init()
  {
    try
    {
      // get parameter values from the html page
      String server = getParameter("server");
      String port = getParameter("port");

      // construct the URL (sample is the database name)
      String url = "jdbc:db2://"+server+":"+port+"/sample";

      String userid = getParameter("userid");
      String password = getParameter("password");

      // use driverType=4
      
        Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();

      // connect to the 'sample' database with userid and password
      con = DriverManager.getConnection(url, userid, password);
    }
    catch(Exception e)
    {
      e.printStackTrace();
    }
  }

  public void paint(Graphics g)
  {
    try
    {
      // retrieve data from database
      g.drawString(
        "First, let's retrieve some data from the database...", 10, 10);

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM employee");
      g.drawString("Received results:", 10, 25);

      // display the result set
      // rs.next() returns false when there are no more rows
      int y = 50;
      int i = 0;
      while (rs.next() && (i < 2))
      {
        i++;
        String a= rs.getString(1);
        String str = rs.getString(2);
        String oneLine = " empno= " + a + " firstname= " + str;
        g.drawString(oneLine, 20, y);
        y = y + 15;
      }
      stmt.close();

      // update the database
      g.drawString("Now, update the database...", 10, 100);
      stmt = con.createStatement();
      int rowsUpdated = stmt.executeUpdate(
        "UPDATE employee SET firstnme = 'SHILI' WHERE empno = '000010'");

      // display the number of rows updated
      String msg = "Updated " + rowsUpdated;

      if (1 == rowsUpdated)
      {
        msg = msg +" row.";
      }
      else
      {
        msg = msg +" rows.";
      }
      y = y + 40;
      g.drawString(msg, 20, y);

      stmt.close();

      // rollback the update
      y = y + 40;
      g.drawString("Now, rollback the update...", 10, y);
      con.rollback();
      y = y + 15;
      g.drawString("Rollback done.", 10, y);
    }
    catch(Exception e)
    {
      e.printStackTrace();
    }
  }
} // Applt

