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
// SOURCE FILE NAME: NestedSP.java
//
// SAMPLE: Client application for invoking nested stored procedures
//
//         This sample calls the method callNestedSP() which invokes the  
//         stored procedures created in nestedsp.db2. 
//
//         The function callNestSP() demonstrates 3 levels of nesting. 
//         It first calls the stored procedure OUT_AVERAGE which calls the 
//         stored procedure OUT_MEDIAN, which then calls the stored procedure
//         MAX_SALARY.
//         The output consists of the following information in order:
//         (1) The average salary of the EMPLOYEE table
//         (2) The median salary of the EMPLOYEE table
//         (3) The maximum salary of the EMPLOYEE table
//         (4) a list of employees who make more than average salary 
//         (5) a list of employees who make less than average salary. 
//
//         To run this sample, perform the following steps:
//         (1) create and populate the SAMPLE database by running the command:
//               db2sampl
//         (2) connect to sample database with:
//               db2 connect to sample
//         (3) register the stored procedures using the nestedsp.db2 script:
//               db2 -td@ -vf nestedsp.db2
//         (4) compile NestedSP with: 
//               (n)make NestedSP
//         (5) run NestedSP with:
//               java NestedSP
//         (6) to drop the stored procedures run the nestedspdrop.db2 script:
//               db2 -td@ -vf nestedspdrop.db2
//
// NOTES: The CLASSPATH and shared library path environment variables
//        must be set, as for any JDBC application
//
// OUTPUT FILE: NestedSP.out (available in the online documentation)
//
//***************************************************************************
// For more information about the sample programs, see the README file.
//
// For information on creating SQL procedures and developing JDBC applications,
// see the Application Development Guide.
//
// For information on using SQL statements, see the SQL Reference. 
//
// For the latest information on programming, building, and running DB2 
// applications, visit the DB2 application development website: 
//     http://www.software.ibm.com/data/db2/udb/ad
//***************************************************************************

import java.sql.*;                          

class NestedSP
{
  
  static
  {
    try
    {
      System.out.println();
      System.out.println("JAVA STORED PROCEDURE SAMPLE");
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
    }
    catch (Exception e)
    {
      System.out.println("\nError loading DB2 Driver...\n");
      e.printStackTrace();
    }
  }

  public static void main(String argv[])
  {
    Db db = null;

    try
    {
      // process command line arguments for database connection
      db = new Db(argv);

      System.out.print("THIS SAMPLE SHOWS HOW NESTED STORED PROCEDURES WORK.");
      System.out.println();

      // connect to the 'sample' database
      db.connect();

      // calling NestedSP function   
      callNestedSP(db.con); 
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
        db.disconnect();
      }
      catch( Exception e )
      {
      }
    }
  } // end main


 public static void callNestedSP(Connection con) 
  {
    ResultSet rs = null;
    CallableStatement callStmt = null;

    try
    {
      double outMedian = 0.0;
      double outAverage = 0.0;
      double outMaxSalary = 0.0;

      String procName = "OUT_AVERAGE";
      String sql = "CALL " + procName + "(?, ?, ?)";
      callStmt = con.prepareCall(sql);

      // register the output parameter                                      
      callStmt.registerOutParameter (1, Types.DOUBLE);
      callStmt.registerOutParameter (2, Types.DOUBLE);
      callStmt.registerOutParameter (3, Types.DOUBLE);

      // call the stored procedure                                          
      System.out.println ("\nCall stored procedure named " + procName);
      callStmt.execute();

      // retrieve output parameters
      outAverage = callStmt.getDouble(1);                                         
      outMedian = callStmt.getDouble(2);
      outMaxSalary = callStmt.getDouble(3);

      System.out.println(procName + " completed successfully");
      System.out.println();
      System.out.println ("Average salary returned from " + procName + " = "
                           + outAverage);
      System.out.println();
      System.out.println ("Median salary returned from OUT_MEDAIN = "
                           + outMedian);
      System.out.println();
      System.out.println ("Max salary returned from MAX_SALARY = "
                           + outMaxSalary);

      System.out.println();
      System.out.println("Result set 1: Employees who make more than " + 
                         outAverage);
      // get the first result set
      rs = callStmt.getResultSet();
      fetchAll(rs);

      System.out.println("\nResult set 2: Employees who make less than " + 
                         outAverage);
      // get the second result set
      callStmt.getMoreResults();
      rs = callStmt.getResultSet();
      fetchAll(rs);
    }
    catch (Exception e)
    {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();

    }
    finally
    {
      // cleanup - close the result set and the statement
      try 
      { 
        rs.close();
      } catch (Exception e)
      {
      }
      try 
      { 
        callStmt.close();
      } catch (Exception e)
      {
      }
    }
  }

  //method fetchAll returns all rows from result set
  public static void fetchAll( ResultSet rs) throws SQLException
  {   
    System.out.println(
      "=============================================================");
    ResultSetMetaData stmtInfo = rs.getMetaData();
    int numOfColumns = stmtInfo.getColumnCount();
    // Do not need to print the last column
    int numColumns = numOfColumns - 1;
    int r = 0;

    while( rs.next() )
    {   
      r++;
      System.out.print("Row: " + r + ": ");
      for( int i=1; i <= numColumns; i++ )
      {   
        System.out.print(rs.getString(i));
        if( i != numColumns ) System.out.print(" , ");
      }
      System.out.println("");
    }
  }

}
  
