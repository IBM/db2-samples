//*************************************************************************
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
//*************************************************************************
//
// SOURCE FILE NAME: SpServer.java
//    
// SAMPLE: Code implementations of various types of stored procedures
//         The stored procedures defined in this program are called by the
//         client application SpClient.java. Before building and running
//         spclient.java, build the shared library by completing the following
//         steps:
//
// Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system, 
//            do the following:
//            1. Compile the server source file SpServer.java (this will also 
//               compile the Utility file, Util.java, erase the existing 
//               library/class files and copy the newly compiled class files, 
//               SpServer.class, from the current directory to the 
//               $(DB2PATH)\function directory):
//                 nmake/make SpServer
//            2. Compile the client source file SpClient.java (this will also 
//               call the script 'spcat' to create and catalog the stored 
//               procedures):
//                 nmake/make SpClient
//            3. Run the client SpClient:
//                 java SpClient
//
//         II) If you don't have a compatible make/nmake program on your 
//             system do the following:
//             1. Compile the utility file and the server source file with:
//                  javac Util.java
//                  javac SpServer.java
//             2. Erase the existing library/class files (if exists), 
//                SpServer.class from the following path,
//                $(DB2PATH)\function. 
//             3. Copy the class files, SpServer.class from the current
//                directory to the $(DB2PATH)\function.
//             4. Catalog the stored procedures in the database with the script:
//                  spcat
//             5. Compile SpClient with:
//                  javac SpClient.java
//             6. Run SpClient with:
//                  java SpClient
//
// Class SpServer contains nine methods:
//         1. outLanguage: returns the implementation language of the stored 
//            procedure library
//         2. outParameter: returns median salary of employee salaries
//         3. inParams: accepts 3 salary values and updates employee
//            salaries in the EMPLOYEE table based on these values for a
//            given department
//         4. inoutParam: accepts an input value and returns the median
//            salary of those employees in the EMPLOYEE table who earn more 
//            than the input value 
//         5. clobExtract: returns a section of a CLOB type as a string
//         6. decimalType: manipulates an INOUT DECIMAL parameter
//         7. allDataTypes: uses all of the common data types in a stored 
//            procedure
//         8. resultSetToClient: returns a result set to the client 
//            application
//         9. twoResultSets: returns two result sets to the client
//            application
//
// SQL Statements USED:
//         SELECT
//         UPDATE
//
// OUTPUT FILE: SpClient.out (available in the online documentation)
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

import java.sql.*;              // JDBC classes
import java.io.*;               // Input/Output classes
import java.math.BigDecimal;    // Packed Decimal class

///////
// Java stored procedure is in this class
///////
public class SpServer
{
  //*************************************************************************
  //  Stored Procedure: outLanguage
  // 
  //  Purpose:  Returns the code implementation language of
  //            routine 'OutLanguage' (as it appears in the
  //            database catalog) in an output parameter.
  //  
  //  Parameters:
  //
  //   IN:      (none)
  //   OUT:     outLanguage - the code language of this routine
  //
  //*************************************************************************
  public static void outLanguage(String[] outLanguage) // CHAR(8)
  throws SQLException
  {
    
    int errorCode = 0; // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;
    
    try
    {
      String procName;
      
      // initialize variables
      procName = "OUT_LANGUAGE";
      
      errorLabel = "GET CONNECTION";
      // get caller's connection to the database
      Connection con = DriverManager.getConnection("jdbc:default:connection");

      errorLabel = "SELECT STATEMENT";
      
      String query = "SELECT language FROM syscat.procedures "
                     + "WHERE procname = ? ";
      
      errorLabel = "PREPARE STATEMENT";
      PreparedStatement stmt = con.prepareStatement(query);
      stmt.setString(1, procName);
      
      errorLabel = "GET LANGUAGE RESULT SET";
      ResultSet rs = stmt.executeQuery();

      if (!rs.next())
      {
        // set errorCode to SQL0100 to indicate data not found       
        errorLabel = "100 : NO DATA FOUND";
        throw new SQLException(errorLabel);
      }
      else
      {
        // move to first row of result set
        // rs.next();

        // set value for the output parameter
        outLanguage[0] = rs.getString(1);
      }
         
      // clean up resources
      rs.close();
      stmt.close();
      con.close();
    }
    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      throw new SQLException( errorCode + " : " + errorLabel + " FAILED" ); 
    }
  } // outLanguage

  //*************************************************************************
  //  Stored Procedure: outParameter
  //
  //  Purpose:  Sorts table STAFF by salary, locates and returns
  //            the median salary
  //
  //  Parameters:
  //
  //   IN:      (none)
  //   OUT:     outMedianSalary - median salary in table STAFF
  //
  //*************************************************************************
  public static void outParameter(double[] outMedianSalary)  
  throws SQLException    
  {
   
    int counter;
    int numRecords;    
    int errorCode = 0; // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;
    
    try
    {       
      // initialize variables
      counter = 0;
    
      // get caller's connection to the database
      errorLabel = "GET CONNECTION";
      Connection con = DriverManager.getConnection("jdbc:default:connection");
      
      errorLabel = "SELECT STATEMENT";
      String query = "SELECT COUNT(*) FROM staff";
      
      errorLabel = "PREPARE COUNT STATEMENT";
      PreparedStatement stmt1 = con.prepareStatement(query);
      
      errorLabel = "GET COUNT RESULT SET";
      ResultSet rs1 = stmt1.executeQuery();

      // move to first row of result set
      rs1.next();

      // set value for the output parameter
      errorLabel = "GET NUMBER OF RECORDS";
      numRecords = rs1.getInt(1);                         

      // clean up first result set
      rs1.close();
      stmt1.close();

      // get salary result set
      errorLabel = "SELECT STATEMENT";
      query = "SELECT CAST(salary AS DOUBLE) FROM staff ORDER BY salary";
      
      errorLabel = "PREPARE SALARY STATEMENT";
      PreparedStatement stmt2 = con.prepareStatement(query);
      
      errorLabel = "GET SALARY RESULT SET";
      ResultSet rs2 = stmt2.executeQuery();              
      
      errorLabel = "MOVE TO NEXT ROW";   
      while (counter < (numRecords / 2 + 1))
      {
        rs2.next();                                    
        counter++;
      }
      errorLabel = "GET MEDIAN SALARY";
      outMedianSalary[0] = rs2.getDouble(1);              

      // clean up resources
      rs2.close();
      stmt2.close();
      con.close();                                      

    }
    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      throw new SQLException( errorCode + " : " + errorLabel + " FAILED" ); 
    }
  } // outParameter
  
  //*************************************************************************
  //  Stored Procedure: inParams
  //
  //  Purpose:  Updates salaries of employees in department 'inDepartment'
  //            using inputs inLowSal, inMedSal, inHighSal as
  //            salary raise/adjustment values.
  //
  //  Parameters:
  //
  //   IN:      inLowSal      - new salary for low salary employees
  //            inMedSal      - new salary for mid salary employees
  //            inHighSal     - new salary for high salary employees
  //            inDepartment  - department to use in SELECT predicate
  //   OUT:     (none)
  //
  //*************************************************************************
  public static void inParams(double inLowSal,
                              double inMedSal,
                              double inHighSal,
                              String inDepartment) // CHAR(3)
  throws SQLException                        
  {
    double salary;
    String cursorName;
    int errorCode;
    String errorLabel = null;
    
    errorCode = 0; // SQLCODE = 0 unless SQLException occurs

    // initialize variables
    salary = 0;
    cursorName = "";

    try
    {
      // get caller's connection to the database
      errorLabel = "GET CONNECTION";
      Connection con = DriverManager.getConnection("jdbc:default:connection");
     
      errorLabel = "SELECT STATEMENT";
      String query = "SELECT CAST(salary AS DOUBLE) " +
                     "  FROM employee " +
                     "  WHERE workdept = ? " +
                     "  FOR UPDATE";

      errorLabel = "PREPARE STATEMENT 1";
      PreparedStatement stmt = con.prepareStatement(query);
      stmt.setString(1, inDepartment);
      errorLabel = "GET RESULT SET";
      ResultSet rs = stmt.executeQuery();
      cursorName = rs.getCursorName();

      errorLabel = "GET FIRST ROW";
      if (!rs.next())
      {
        // set errorCode to SQL0100 to indicate data not found       
        errorLabel = "100 : NO DATA FOUND";
        throw new SQLException(errorLabel);
      }
      else
      {
        boolean foundData = true;

        String updateByValue = "UPDATE employee SET salary = ? "  +
                               " WHERE CURRENT OF " + cursorName;
        String updateFinal = "UPDATE employee SET salary = (salary * 1.10)" +
                             " WHERE CURRENT OF " + cursorName;

        errorLabel = "PREPARE 'stmtByValue'";
        PreparedStatement stmtByValue = con.prepareStatement(updateByValue);
               
        errorLabel = "PREPARE 'stmtFinal'";
        PreparedStatement stmtFinal = con.prepareStatement(updateFinal);

        while (foundData)
        {
          errorLabel = "GET SALARY";
          salary = rs.getDouble(1);
          if (inLowSal > salary)
          {
            errorLabel = "UPDATE -- LOW CASE";
            // to update the salary to inLowSal value
            stmtByValue.setDouble(1, inLowSal); 
            stmtByValue.executeUpdate();
          }
          else if (inMedSal > salary)
          {
            errorLabel = "UPDATE -- MEDIUM CASE";
            // to update the salary to inMedSal value
            stmtByValue.setDouble(1,  inMedSal);
            stmtByValue.executeUpdate();
          }
          else if (inHighSal > salary)
          {
            errorLabel = "UPDATE -- HIGH CASE";
            // to update the salary to inHighSal value
            stmtByValue.setDouble(1,  inHighSal);
            stmtByValue.executeUpdate();
          }
          else
          {
            errorLabel = "UPDATE -- FINAL CASE";
            stmtFinal.executeUpdate();
          }

          if (!rs.next()) // if next row is not found
          {
            foundData = false;
          }
        }

        stmtByValue.close();
        stmtFinal.close();
      }

      rs.close();
      stmt.close();
      con.close();

    }
    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      if (errorLabel.equalsIgnoreCase("100 : NO DATA FOUND"))
        throw new SQLException(sqle.getMessage());
      else
        throw new SQLException( errorCode + " : " + errorLabel + " FAILED" ); 
    }
  } // inParams

  //*************************************************************************
  //  Stored Procedure: inOutParam
  //
  //  Purpose:  Calculates the median salary of all salaries in the STAFF
  //            above table the input median salary.
  //
  //  Parameters:
  //
  //   IN/OUT:  inOutMedianSalary - median salary
  //                                The input value is used in a SELECT 
  //                                predicate. Its output value is set to the
  //                                median salary. 
  //
  //*************************************************************************
  public static void inoutParam(double[] inoutMedianSalary)
  throws SQLException
  {
    int counter;
    int numRecords;
    double salary;
    String cursorName;  
    int errorCode = 0; // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;
    
    // initialize variables
    counter = 0;
    salary = 0;
    cursorName = "";
    
    try
    {             
      // get the caller's connection to the database
      errorLabel = "GET CONNECTION";
      Connection con = DriverManager.getConnection("jdbc:default:connection");

      errorLabel = "SELECT STATEMENT";
      String query = "SELECT COUNT(*) FROM staff " +
                     "  WHERE CAST(salary AS DOUBLE) > ? ";

      errorLabel = "PREPARE COUNT STATEMENT";
      PreparedStatement stmt1 = con.prepareStatement(query);
      stmt1.setDouble(1, inoutMedianSalary[0]);

      errorLabel = "GET COUNT RESULT SET";
      ResultSet rs1 = stmt1.executeQuery();

      // move to first row of result set
      rs1.next();

      // set value for the output parameter
      errorLabel = "GET NUMBER OF RECORDS";
      numRecords = rs1.getInt(1);

      // clean up first result set
      rs1.close();
      stmt1.close();

      if (numRecords == 0)
      {
        // set errorCode to SQL0100 to indicate data not found       
        errorLabel = "100 : NO DATA FOUND";
        throw new SQLException(errorLabel);
      }
      else
      {
        // get salary result set
        query = "SELECT CAST(salary AS DOUBLE) FROM staff " +
                "  WHERE CAST(salary AS DOUBLE) > ? " +
                "   ORDER BY salary";
        errorLabel = "PREPARE SALARY STATEMENT FAILED";
        PreparedStatement stmt2 = con.prepareStatement(query);
        stmt2.setDouble(1, inoutMedianSalary[0]);
        errorLabel = "GET SALARY RESULT SET";
        ResultSet rs2 = stmt2.executeQuery();

        while (counter < (numRecords / 2 + 1))
        {
          errorLabel = "MOVE TO NEXT ROW";
          rs2.next();
          counter++;
        }
        errorLabel = "GET MEDIAN SALARY";
        inoutMedianSalary[0] = rs2.getDouble(1);

        // clean up resources
        rs2.close();
        stmt2.close();
      }

      // close connection
      con.close();
    }
    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      if (errorLabel.equalsIgnoreCase("100 : NO DATA FOUND"))
        throw new SQLException(sqle.getMessage());
      else
        throw new SQLException( errorCode + " : " + errorLabel + "FAILED" ); 
    }
  } // inoutParam

  //*************************************************************************
  //  Stored Procedure: clobExtract
  //
  //  Purpose:  Extracts department information from a large object (LOB) 
  //            resume of employee data returns this information
  //            to the caller in output parameter outDeptInfo.
  // 
  //  Parameters:
  //  
  //   IN:      inEmpNumber - employee number
  //   OUT:     outDeptInfo - department information section of the 
  //            employee's resume   
  //
  //*************************************************************************
  public static void clobExtract(String inEmpNumber,   // CHAR(6) 
                                 String[] outDeptInfo) // VARCHAR(1000) 
  throws Exception
  {
    int counter;
    int index;
    int maximumLength;
    byte[] clobBytes;
    char[] clobData;
    int errorCode = 0; // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;
    
    try
    {
      errorLabel = "GET CONNECTION";
      
      // get caller's connection to the database
      Connection con = DriverManager.getConnection("jdbc:default:connection");

      errorLabel = "SELECT STATEMENT";
      // choose the employee resume that matches the employee number
      Statement stmt = con.createStatement();       
      ResultSet rs = stmt.executeQuery("SELECT resume FROM emp_resume " +
                                       "  WHERE empno = '" + inEmpNumber + "'" +
                                       "  AND resume_format = 'ascii'");

      if (rs.next())
      {
        // copy the CLOB into an array of characters by converting all
        // bytes into characters as they are read in
        InputStream inStream = rs.getAsciiStream(1);

        // InputStream.available() may not work on larger files
        maximumLength = inStream.available();
        clobBytes = new byte[maximumLength];
        clobData = new char[maximumLength];

        inStream.read(clobBytes);
        for (counter = 0; counter < maximumLength; counter++)
        {
          clobData[counter] = (char)clobBytes[counter];
        }

        String clob = String.valueOf(clobData);

        // copy substring from "Department Info" to "Education"
        // into OUT parameter
        index = clob.indexOf("Department Info");
        if (index == -1)
        {
          outDeptInfo[0] = "Resume does not contain a " +
                           "Department Info section.";
        }
        else
        {
          outDeptInfo[0] = clob.substring(clob.indexOf("Department Info"),
                                          clob.indexOf("Education"));
        }
      }
      else
      {
        outDeptInfo[0] = ("\nEmployee " + inEmpNumber + 
                          " does not have a resume.");
      }
      rs.close();
      stmt.close();
    }
    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      throw new SQLException( errorCode + " : " + errorLabel + "FAILED" );
    }
  } // clobExtract

  //*************************************************************************
  // PARAMETER STYLE JAVA procedures do not support the DBINFO clause.
  // The following PARAMETER STYLES can be used with DBINFO or PROGRAM TYPE
  // clauses: 
  //          - DB2SQL
  //          - GENERAL
  //          - GENERAL WITH NULLS
  //          - SQL
  // Please see the SpServer implementation for C/C++/CLI language to
  // see this functionality.
  //*************************************************************************

  //*************************************************************************
  // PROGRAM TYPE MAIN is only valid for LANGUAGE C, COBOL or CLR, and 
  // following PARAMETER STYLE:
  //          - DB2SQL
  //          - GENERAL
  //          - GENERAL WITH NULLS
  //          - SQL
  // Please see the SpServer implementation for C/C++/CLI language to
  // see this functionality.
  //*************************************************************************

  //*************************************************************************
  //  Stored Procedure: decimalType
  //
  //  Purpose:  Takes in a decimal number as input, divides it by 2 
  //            and returns the resulting decimal rounded off to 2 
  //            decimal places.
  //
  //  Parameters:
  //  
  //   INOUT:   inOutDecimal - DECIMAL(10,2)
  //                            
  //*************************************************************************
  public static void decimalType(BigDecimal[] inoutDecimal) // DECIMAL(10,2)
  throws SQLException
  {
    int errorCode = 0;  // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;   
    
    try
    {
      // get caller's connection to the database
      errorLabel = "GET CONNECTION";  
      Connection con = DriverManager.getConnection("jdbc:default:connection");

      if (inoutDecimal[0].equals(BigDecimal.valueOf(0)))
      {
        inoutDecimal[0].add(BigDecimal.valueOf(1));
      }
      else
      {
        inoutDecimal[0] = inoutDecimal[0].divide(BigDecimal.valueOf(2),
                                                 BigDecimal.ROUND_HALF_UP);
      }

      // close our connection
      con.close();
    }

    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      throw new SQLException( errorCode + " : DECIMAL_TYPE FAILED" ); 
    }
  } // decimalType

  //*************************************************************************
  //  Stored Procedure: allDataTypes 
  //
  //  Purpose: Take each parameter and set it to a new output value.
  //           This sample shows only a subset of DB2 supported data types.
  //           For a full listing of DB2 data types, please see the SQL 
  //           Reference. 
  //
  //  Parameters:
  //  
  //   INOUT:   inOutSmallint, inOutInteger, inOutBigint, inOutReal,
  //            outDouble
  //   OUT:     outChar, outChars, outVarchar, outDate, outTime
  //
  //*************************************************************************
  public static void allDataTypes(short[] inoutSmallint,       
                                  int[] inoutInteger,          
                                  long[] inoutBigint,         
                                  float[] inoutReal,          
                                  double[] inoutDouble,        
                                  String[] outChar, // CHAR(1)           
                                  String[] outChars, // CHAR(15)          
                                  String[] outVarchar, // VARCHAR(13)        
                                  Date[] outDate, // DATE             
                                  Time[] outTime) // TIME              
  throws SQLException
  {
    int errorCode = 0; // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;
      
    try
    {
      // get caller's connection to the database
      errorLabel = "GET CONNECTION";  
      Connection con = DriverManager.getConnection("jdbc:default:connection");

      if (inoutSmallint[0] == 0)
      {
        inoutSmallint[0] = 1;
      }
      else
      {
        inoutSmallint[0] = (short)(inoutSmallint[0] / 2);
      }

      if (inoutInteger[0] == 0)
      {
        inoutInteger[0] = 1;
      }
      else
      {
        inoutInteger[0] = (inoutInteger[0] / 2);
      }

      if (inoutBigint[0] == 0)
      {
        inoutBigint[0] = 1;
      }
      else
      {
        inoutBigint[0] = (inoutBigint[0] / 2);
      }

      if (inoutReal[0] == 0)
      {
        inoutReal[0] = 1;
      }
      else
      {
        inoutReal[0] = (inoutReal[0] / 2);
      }

      if (inoutDouble[0] == 0)
      {
        inoutDouble[0] = 1;
      }
      else
      {
        inoutDouble[0] = (inoutDouble[0] / 2);
      }

      errorLabel = "SELECT MIDINIT, LASTNAME ...";
      
      // get value of midinit, lastname and firstnme
      String query = "SELECT midinit, lastname, firstnme " +
                     "  FROM employee " +
                     "  WHERE empno = '000180' ";
      
      // create the SQL statement
      Statement stmt = con.createStatement();

      // get the result set
      ResultSet rs = stmt.executeQuery(query);

      // move to first row of result set
      rs.next();

      // get the value of the midinit column
      outChar[0] = rs.getString(1);
      // get the value of the lastname column
      outChars[0] = rs.getString(2);
      // get the value of the firstnme column
      outVarchar[0] = rs.getString(3);
      
      // clean up resources
      rs.close();
      stmt.close();    

      errorLabel = "VALUES(CURRENT DATE)";
      // get current date from DB2 server
      query = "VALUES(CURRENT DATE)";
      
      // create the SQL statement
      stmt = con.createStatement();

      // get the result set
      rs = stmt.executeQuery(query);

      // move to first row of result set
      rs.next();

      // get the date value
      outDate[0] = rs.getDate(1);

      // clean up resources
      rs.close();
      stmt.close();

      errorLabel = "VALUES(CURRENT TIME)";
      // get current time from DB2 server
      query = "VALUES(CURRENT TIME)";
      
      // create the SQL statement
      stmt = con.createStatement();

      // get the result set
      rs = stmt.executeQuery(query);

      // move to first row of result set
      rs.next();

      // get the time value
      outTime[0] = rs.getTime(1);

      // clean up resources
      rs.close();
      stmt.close();

      // close our connection
      con.close();
    }

    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      throw new SQLException( errorCode + " : " + errorLabel + " FAILED" ); 
    }
  } // allDataTypes

  //*************************************************************************
  //  Stored Procedure: resultSetToClient
  //
  //  Purpose:  Returns a result set to the caller that identifies employees
  //            with salaries greater than the value of input parameter
  //            inSalaryThreshold.
  //
  //  Parameters:
  // 
  //   IN:      inSalaryThreshold - salary
  //   OUT:     outRs - ResultSet
  //
  //*************************************************************************
  public static void resultSetToClient(double inSalaryThreshold, 
                                       ResultSet[] outRs)           
  throws SQLException
  {
    int errorCode = 0; // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;
    
    try
    {
      // get caller's connection to the database
      errorLabel = "GET CONNECTION";  
      Connection con = DriverManager.getConnection("jdbc:default:connection");

      errorLabel = "SELECT STATEMENT";
      
      // set the SQL statement that will return the desired result set
      String query = "SELECT name, job, CAST(salary AS DOUBLE) " +
	             "  FROM staff " +
                     "  WHERE salary > ? " +
                     "  ORDER BY salary";

      // prepare the SQL statement
      PreparedStatement stmt = con.prepareStatement(query);

      // set the value of the parameter marker (?)
      stmt.setDouble(1, inSalaryThreshold);

      // get the result set that will be returned to the client
      outRs[0] = stmt.executeQuery();
      
      // to return a result set to the client, do not close ResultSet
      con.close();
    }

    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      throw new SQLException( errorCode + " : " + errorLabel + " FAILED" ); 
    }
  } // resultSetToClient

  //*************************************************************************
  //  Stored Procedure: twoResultSets
  //
  //  Purpose:  Return two result sets to the caller. One result set
  //            consists of employee data of all employees with
  //            salaries greater than inSalaryThreshold.  The other
  //            result set contains employee data for employees with salaries
  //            less than inSalaryThreshold.
  //
  //  Parameters:
  // 
  //   IN:      inSalaryThreshold - salary
  //   OUT:     outRs1 - first ResultSet
  //            outRs2 - second ResultSet
  //
  //*************************************************************************
  public static void twoResultSets(double inSalaryThreshold,    
                                   ResultSet[] outRs1,             
                                   ResultSet[] outRs2)            
  throws SQLException
  {
    int errorCode = 0; // SQLCODE = 0 unless SQLException occurs
    String errorLabel = null;
    
    try
    {
      // get caller's connection to the database
      errorLabel = "GET CONNECTION";  
      Connection con = DriverManager.getConnection("jdbc:default:connection");

      errorLabel = "SELECT STATEMENT 1";
      
      // set the SQL statement that will return the desired result set
      String query1 =
        "SELECT name, job, CAST(salary AS DOUBLE) FROM staff " +
        "  WHERE salary > ? " +
        "  ORDER BY salary";

      // prepare the SQL statement
      PreparedStatement stmt1 = con.prepareStatement(query1);

      // set the value of the parameter marker (?)
      stmt1.setDouble(1, inSalaryThreshold);

      // get the result set that will be returned to the client
      outRs1[0] = stmt1.executeQuery();

      errorLabel = "SELECT STATEMENT 2";
      
      // set the SQL statement that will return the desired result set
      String query2 =
        "SELECT name, job, CAST(salary AS DOUBLE) FROM staff " +
        "  WHERE salary < ? " +
        "  ORDER BY salary DESC";

      // prepare the SQL statement
      PreparedStatement stmt2 = con.prepareStatement(query2);

      // set the value of the parameter marker (?)
      stmt2.setDouble(1, inSalaryThreshold);

      // get the result set that will be returned to the client
      outRs2[0] = stmt2.executeQuery();

      // to return the result sets to the client, do not close the ResultSets
      con.close();
    }
    catch (SQLException sqle)
    {
      errorCode = sqle.getErrorCode();
      throw new SQLException( errorCode + " : " + errorLabel + " FAILED" ); 
    }
  } // twoResultSets
  
  //*************************************************************************
  // PARAMETER STYLE GENERAL and GENERAL WITH NULLS can be specified when
  // LANGUAGE C, COBOL, or CLR is used.
  // Please see the SpClient implementation for C/C++/CLI language to see
  // this functionality.
  //*************************************************************************

} // SpServer
