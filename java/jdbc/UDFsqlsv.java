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
// SOURCE FILE NAME: UDFsqlsv.java
// 
// SAMPLE: Provide UDFs to be called by UDFsqlcl.java
//
//         Steps to run the sample with the command line window:
// 
//         I) If you have a compatible make/nmake program on your system, 
//            all you have to do is:
//            1. Compile the server source file UDFsqlsv (this will also compile
//               the Utility file, erase the existing library/class files and
//               copy the newly compiled class files, UDFsqlsv.class and 
//               Person.class from the current directory to the 
//               $(DB2PATH)\function directory):
//                 nmake/make UDFsqlsv
//            2. Connect to the sample database, type:
//                 db2 connect to sample
//            3. Catalog the UDFs defined in UDFsqlsv.java:
//                 db2 -td@ -vf UDFsCreate.db2
//            4. Compile the client source file UDFsqlcl.java:
//                 nmake/make UDFsqlcl
//            5. Run the client UDFsqlcl
//                 java UDFsqlcl
//            6. Uncatalog the UDFs using the following command:
//                 db2 -td@ -vf@ UDFsDrop.db2
//
//         II) If you don't have a compatible make/nmake program on your system,
//             all you have to do is:
//             1. Compile the utility file and the server source file with:
//                  javac Util.java
//                  javac UDFsqlsv.java
//             2. Erase the existing library/class files (if exists), 
//                UDFsqlsv.class and Person.class from the following path,
//                $(DB2PATH)\function. 
//             3. copy the class files, UDFsqlsv.class and Person.class from 
//                the current directory to the $(DB2PATH)\function.
//             4. Connect to the sample database, type:
//                  db2 connect to sample
//             5. Catalog the UDFs defined in UDFsqlsv.java:
//                  db2 -td@ -vf UDFsCreate.db2
//             6. Compile UDFsqlcl with:
//                  javac UDFsqlcl.java
//             7. Run UDFsqlcl with:
//                  java UDFsqlcl
//             8. Uncatalog the UDFs using the following command:
//                  db2 -td@ -vf@ UDFsDrop.db2
//
// SQL Statements USED:
//         SELECT
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: UDFsqlcl.out (available in the online documentation)
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

import java.lang.*;              // for String class
import COM.ibm.db2.app.*;        // UDF and associated classes
import java.sql.*;
import java.math.*; 
import java.io.*;

public class UDFsqlsv extends UDF
{
  Person[] staff;
  int maxRows;
  
  public void Convert (String inSourceCurrency,
                       double inAmount,
                       String inResultCurrency,
                       double result)
    throws Exception
  {
    if (isNull(1) || isNull(2) || isNull(3))
    {
      return;
    }

    try
    {
      // Get caller's connection to the database
      Connection con =
        DriverManager.getConnection("jdbc:default:connection");
      
      String query = "SELECT exchangeRate "
        + "FROM exchangeRate "
        + "WHERE SourceCurrency = ? AND "
        + "ResultCurrency = ?";
      
      PreparedStatement stmt = con.prepareStatement(query);
      stmt.setString(1, inSourceCurrency);
      stmt.setString(2, inResultCurrency);
      
      ResultSet rs = stmt.executeQuery();
      
      // move to first row of result set
      if (!rs.next())
      {
        setSQLstate("38990");
        setSQLmessage("Can't find corresponding exchange rate");
        return;
      }
      
      // set value for the output parameter
      double exchangeRate = rs.getDouble(1);
      
      set(4, exchangeRate * inAmount);

      // clean up resources
      rs.close();
      stmt.close();
      con.close();
    }
    catch (SQLException sqle)
    {
      setSQLstate("38999");
      setSQLmessage("SQLCODE = " + String.valueOf(sqle.getErrorCode()));
      return;
    }
  }  //Convert

  public void sumSalary(String inDeptNo,
                        double outAmount)
    throws Exception
  {

    double result = 0;
   
    if (isNull(1))
    {
      return;
    }
    
    try
    {
      // Get caller's connection to the database
      Connection con =
        DriverManager.getConnection("jdbc:default:connection");
      
      String query = "SELECT Convert(CHAR('CA'), salary, CHAR('US')) " +
                     "FROM employee " +
                     "WHERE workdept = ?";

      PreparedStatement stmt = con.prepareStatement(query);
      stmt.setString(1, inDeptNo);

      ResultSet rs = stmt.executeQuery();
 
      while(rs.next())
      {
        result += rs.getDouble(1);
      }

      set(2, result);

      rs.close();
      stmt.close();
      con.close();

    }
    catch (SQLException sqle)
    {
      setSQLstate("38999");
      setSQLmessage("SQLCODE = " + sqle.getSQLState());
      return;
    }

  } // sumSalary  

 
  // the table UDF
  public void tableUDF(double inSalaryFactor,
                       String outName,
                       String outJob,
                       double outNewSalary)
  throws Exception
  {
    int intRow = 0;
   
    byte[] scratchpad = getScratchpad();

    // variables to read from SCRATCHPAD area
    ByteArrayInputStream
    byteArrayIn = new ByteArrayInputStream(scratchpad);
    DataInputStream
    dataIn = new DataInputStream(byteArrayIn);

    // variables to write into SCRATCHPAD area
    byte[] byteArrayRow;
    int i;
    ByteArrayOutputStream
    byteArrayOut = new ByteArrayOutputStream(10);
    DataOutputStream
    dataOut = new DataOutputStream(byteArrayOut);

    switch (getCallType())
    {
      case SQLUDF_TF_FIRST:
        // do initialization for the whole statement
        // (the statement may invoke tableUDF more than once)
        break;
      case SQLUDF_TF_OPEN:
        // do initialization valid for this invokation of tableUDF

        intRow = 1;
        // save data in SCRATCHPAD area

        try
        {
          // Get caller's connection to the database
          Connection con =
            DriverManager.getConnection("jdbc:default:connection");
                
          Statement stmt = con.createStatement();
          ResultSet rs = stmt.executeQuery("SELECT count(*) FROM STAFF");
                
          rs.next();
                
          maxRows = rs.getInt(1);
          staff = new Person[maxRows];

          rs.close();
                
          rs = stmt.executeQuery("SELECT NAME, JOB, DOUBLE(SALARY) FROM STAFF");
          
          int counter = 0;
          while(rs.next())
          {
            staff[counter] = new Person(rs.getString(1), rs.getString(2), rs.getDouble(3));
            counter ++;
          }

          rs.close();
          stmt.close();
          con.close();
        }
        catch(SQLException sqle)
        {
          setSQLstate("38999");
          setSQLmessage("SQLCODE = " + sqle.getSQLState());
          return;
        }

        dataOut.writeInt(intRow);
        byteArrayRow = byteArrayOut.toByteArray();
        for(i = 0; i < byteArrayRow.length; i++)
        {
          scratchpad[i] = byteArrayRow[i];
        }
        setScratchpad(scratchpad);
        break;
      case SQLUDF_TF_FETCH:
        // get data from SCRATCHPAD area
        intRow = dataIn.readInt();
        // work with data
        if(intRow > maxRows)
        {
          // Set end-of-file signal and return
          setSQLstate ("02000");
        }
        else
        {
          // Set the current output row and increment the row number
          set(2, staff[intRow - 1].getName());
          set(3, staff[intRow - 1].getJob());
          set(4, staff[intRow - 1].getSalary() * inSalaryFactor);
          intRow++;
        }

        // save data in SCRATCHPAD area
        dataOut.writeInt(intRow);
        byteArrayRow = byteArrayOut.toByteArray();
        for(i = 0; i < byteArrayRow.length; i++)
        {
          scratchpad[i] = byteArrayRow[i];
        }
        setScratchpad(scratchpad);
        break;
      case SQLUDF_TF_CLOSE:
        break;
      case SQLUDF_TF_FINAL:
        break;
    }
  } // tableUDF
}    
    
// the class Person is used by the table UDF
class Person
{
  String name;
  String job;
  double salary;

  Person()
  {
    name = null;
    job = null;
    salary = 0.00;
  }

  Person(String n , String j, double s)
  {
    name = n;
    job = j;
    salary = s;
  }

  public String getName()
  {
    return name;
  }

  public String getJob()
  {
    return job;
  }

  public double getSalary()
  {
    return salary;
  }
} // Person class





