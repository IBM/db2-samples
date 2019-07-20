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
// SOURCE FILE NAME: SpClient.java
//
// SAMPLE: Call the set of stored procedures implemented in SpServer.java
//
// Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system, 
//            do the following:
//            1. Compile the server source file SpServer.java (this will also 
//               compile the utility file, Util.java, erase the existing 
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
//             4. Catalog the stored procedures in the database with:
//                  spcat
//             5. Compile SpClient with:
//                  javac SpClient.java
//             6. Run SpClient with:
//                  java SpClient
//
// SpClient calls nine methods that call stored procedures:
//  (1) callOutLanguage: Calls a stored procedure that returns the 
//      implementation language of the stored procedure library
//        Parameter types used: OUT CHAR(8)
//  (2) callOutParameter: Calls a stored procedure that returns median 
//      salary of employee salaries
//        Parameter types used: OUT DOUBLE                    
//  (3) callInParameters: Calls a stored procedure that accepts 3 salary 
//      values and updates employee salaries in the EMPLOYEE table based 
//      on these values for a given department.
//        Parameter types used: IN DOUBLE
//                              IN DOUBLE
//                              IN DOUBLE
//                              IN CHAR(3)
//  (4) callInoutParameter: Calls a stored procedure that accepts an input
//      value and returns the median salary of those employees in the
//      EMPLOYEE table who earn more than the input value. Demonstrates how 
//      to use null indicators in a client application. The stored procedure
//      has to be implemented in the following parameter styles for it to be
//      compatible with this client application.
//        Parameter style for a C stored procedure:  SQL
//        Parameter style for a Java(JDBC/SQLJ) stored procedure:  JAVA
//        Parameter style for an SQL stored procedure:  SQL
//        Parameter types used: INOUT DOUBLE
//  (5) callClobExtract: Calls a stored procedure that extracts and returns a 
//      portion of a CLOB data type
//        Parameter types used: IN CHAR(6)
//                              OUT VARCHAR(1000)
//  (6) callDecimalType: Calls a stored procedure that passes and receives a 
//      DECIMAL data type from a stored procedure
//        Parameter types used: INOUT DECIMAL
//  (7) callAllDataTypes: Calls a stored procedure that uses a variety of 
//      common data types (not DECIMAL, GRAPHIC, VARGRAPHIC, BLOB, CLOB, 
//      DBCLOB). This sample shows only a subset of DB2 supported data types.
//      For a full listing of DB2 data types, please see the SQL Reference.
//        Parameter types used: INOUT SMALLINT
//                              INOUT INTEGER
//                              INOUT BIGINT
//                              INOUT REAL
//                              INOUT DOUBLE
//                              OUT CHAR(1)
//                              OUT CHAR(15)
//                              OUT VARCHAR(12)
//                              OUT DATE
//                              OUT TIME
//  (8) callOneResultSet: Calls a stored procedure that returns a result set to
//      the client application
//        Parameter types used: IN DOUBLE
//  (9) callTwoResultSets: Calls a stored procedure that returns two result sets 
//      to the client application
//        Parameter types used: IN DOUBLE
//
// SQL Statements USED:
//         CALL
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


import java.sql.*;            // JDBC classes           
import java.math.BigDecimal;  // BigDecimal support for packed decimal type

class SpClient
{
  static double outMedian = 0;
  static Db db;
  public static void main(String argv[])
  {
    String language = "";
    
      Connection con = null;
      
      try
      { 
        int prt=Integer.parseInt(argv[1]);
        javax.sql.DataSource ds=null;
        ds=new com.ibm.db2.jcc.DB2SimpleDataSource();
        ((com.ibm.db2.jcc.DB2BaseDataSource) ds).
	setServerName(argv[0]);
        ((com.ibm.db2.jcc.DB2BaseDataSource) ds).
	setPortNumber(prt);
        ((com.ibm.db2.jcc.DB2BaseDataSource) ds).
	setDatabaseName("sample");
        ((com.ibm.db2.jcc.DB2BaseDataSource) ds).
	setDriverType(4);
        ((com.ibm.db2.jcc.DB2BaseDataSource) ds).
	setTraceFile("jcctrace.txt");
        ((com.ibm.db2.jcc.DB2BaseDataSource) ds).setEnableNamedParameterMarkers(1);
        con = ds.getConnection(argv[2],argv[3]);
	System.out.println("  Connect to 'sample' database using JDBC Universal type 4 driver.");
        con.setAutoCommit(false);
      }
      catch (Exception e)
      {
        System.out.println("  Error loading DB2 Driver...\n");
        System.out.println(e);
        System.exit(1);
      }



    try
    {
     

      System.out.println("HOW TO CALL VARIOUS STORED PROCEDURES.\n");
            
      language = callOutLanguage(con);
      callOutParameter(con);
      callInParameters(con);
      
      // call INOUT_PARAM stored procedure using the median returned
      // by the call to OUT_PARAM
      System.out.println("\nCall stored procedure named INOUT_PARAM");
      System.out.println("using the median returned by the call to " + 
                         "OUT_PARAM");
      callInoutParameter(con, outMedian);
      
      // call INOUT_PARAM stored procedure again in order to depict a        
      // NOT FOUND error condition
      System.out.println("\nCALL stored procedure INOUT_PARAM again");
      System.out.println("with an input value that causes a NOT FOUND error");
      callInoutParameter(con, 99999.99);
            
      callClobExtract("000140", con);
      callDecimalType(con);
      callAllDataTypes(con);
      callOneResultSet(con);
      callTwoResultSets(con);

      // roll back any changes to the database made by this sample
      con.rollback();                                   
      con.close();
      System.out.println();
      System.out.println("  Disconnect from 'sample' database.");
    }
    catch (Exception e)
    {
      try
      {
        con.rollback();
        con.close();
      }
      catch (Exception x)
      { }

      e.printStackTrace();
    }
  } // end main

  public static String callOutLanguage(Connection con)
  {
    String outLang = "";
    try
    {
      // prepare the CALL statement for OUT_LANGUAGE
      String procName = "OUT_LANGUAGE";
      String sql = "CALL " + procName + "(:Typchar)";
      CallableStatement callStmt = con.prepareCall(sql);

      // register the output parameter
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("Typchar", Types.CHAR);

      // call the stored procedure
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();

      // retrieve output parameters
      outLang = callStmt.getString(1);
      System.out.println("Stored procedures are implemented in language "
                         + outLang);
                         
      // clean up resources
      callStmt.close();                                                  
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
    return(outLang);
  } // callOutLanguage

  public static void callOutParameter(Connection con)
  {
    try
    {
      // prepare the CALL statement for OUT_PARAM
      String procName = "OUT_PARAM";
      String sql = "CALL " + procName + "(:Typdouble)";
      CallableStatement callStmt = con.prepareCall(sql);

      // register the output parameter                   
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("Typdouble", Types.DOUBLE);
      
      // call the stored procedure                       
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      
      callStmt.execute();

      // retrieve output parameters                      
      outMedian = callStmt.getDouble(1);
      
      System.out.println(procName + " completed successfully");
      System.out.println("Median salary returned from " + procName + " = "
                         + outMedian);
                         
      // clean up resources
      callStmt.close();                         
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
  } // callOutParameter


  public static void callInParameters(Connection con) throws SQLException
  {
    try
    {
      // prepare the CALL statement for IN_PARAMS
      String procName = "IN_PARAMS";
      String sql = "CALL " + procName + "(:lowsal, :medsal, :hisal, :dept)";
      CallableStatement callStmt = con.prepareCall(sql);
    
      // display total salary before calling IN_PARAMS
      String query = "SELECT SUM(salary) FROM employee WHERE workdept = :dept";
      PreparedStatement queryStmt = con.prepareStatement(query);
      ((com.ibm.db2.jcc.DB2PreparedStatement)queryStmt).setJccStringAtName("dept", "E11");
      ResultSet queryRS = queryStmt.executeQuery();
      queryRS.next();
      double sumSalary = queryRS.getDouble(1);
      queryRS.close();
      System.out.println();
      System.out.println("Sum of salaries for dept. E11 = " +
                         sumSalary + " before " + procName);
     
      // set input parameters
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccDoubleAtName("lowsal", 15000);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccDoubleAtName("medsal", 20000);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccDoubleAtName("hisal", 25000);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccStringAtName("dept", "E11");

      // call the stored procedure
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();

      System.out.println(procName + " completed successfully");

      // display total salary after calling IN_PARAMS
      queryRS = queryStmt.executeQuery();
      queryRS.next();
      sumSalary = queryRS.getDouble(1);
      queryRS.close();
      System.out.println("Sum of salaries for dept. E11 = "
                         + sumSalary + " after " + procName);
      
      // clean up resources
      queryStmt.close();
      callStmt.close();
    }
    catch (SQLException e)
    {
      // roll back any UPDATE statements issued before the SQLException 
      con.rollback();
      System.out.println(e.getMessage());
    }
  } // callInParameters

  public static void callInoutParameter(Connection con, double median)
  {
    try
    {
      // prepare the CALL statement for INOUT_PARAM
      String procName = "INOUT_PARAM";
      String sql = "CALL " + procName + "(:median)";
      CallableStatement callStmt = con.prepareCall(sql);

      // set input parameter to median value passed back by OUT_PARAM
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccDoubleAtName("median", median);

      // register the output parameters
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("median", Types.DOUBLE);

      if (median == 99999.99)
      {        
        System.out.println("\n-- The following error report is " +
                           "expected! --");
      }
      callStmt.execute();

      // retrieve output parameters
      double inoutMedian = callStmt.getDouble(1);
      
      System.out.println(procName + " completed successfully");
      System.out.println("Median salary returned from " + procName + " = "
                         + inoutMedian);
                         
     // clean up resources
     callStmt.close();                         
      
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
  } // callInoutParameter

  public static void callClobExtract(String empNo, Connection con)
  {
    String outResume;
    try
    {
      // prepare the CALL statement for CLOB_EXTRACT
      String procName = "CLOB_EXTRACT";
      String sql = "CALL " + procName + "(:empNo, :Typvarchar)";
      CallableStatement callStmt = con.prepareCall(sql);

      // set input parameter to median value passed back by OUT_PARAM
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccStringAtName("empNo", empNo);
      
      // register the output parameters
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("Typvarchar", Types.VARCHAR);

      // call the stored procedure
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();

      // retrieve output parameters
      outResume = callStmt.getString(2);
      
      System.out.println(procName + " completed successfully");
      System.out.println("Resume section returned for employee "
                         + empNo + "=\n" + outResume);
          
    }
    catch (Exception e)
    {
      System.out.println(e.getMessage());
    }
  } // callClobExtract

  //*************************************************************************
  // PARAMETER STYLE JAVA procedures do not support the DBINFO clause.
  // The following PARAMETER STYLES can be used with DBINFO or PROGRAM TYPE
  // clauses: 
  //          - DB2SQL
  //          - GENERAL
  //          - GENERAL WITH NULLS
  //          - SQL
  // Please see the SpClient implementation for C/C++/CLI language to
  // see this functionality.
  //*************************************************************************

  //*************************************************************************
  // PROGRAM TYPE MAIN is only valid for LANGUAGE C, COBOL or CLR, and 
  // following PARAMETER STYLE:
  //          - DB2SQL
  //          - GENERAL
  //          - GENERAL WITH NULLS
  //          - SQL
  // Please see the SpClient implementation for C/C++/CLI language to
  // see this functionality.
  //*************************************************************************

  public static void callDecimalType(Connection con)
  {
    try
    {
      // prepare the CALL statement for DECIMAL_TYPE
      String procName = "DECIMAL_TYPE";
      String sql = "CALL " + procName + "(:inoutDec)";
      CallableStatement callStmt = con.prepareCall(sql);

      // declare and initialize input variable
      BigDecimal inoutDecimal = new BigDecimal("400000.00");

      // set input parameter
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccBigDecimalAtName("inoutDec", inoutDecimal);

      // register the output parameters
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("inoutDec", Types.DECIMAL, 2);

      // call the stored procedure
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();
   
      System.out.println(procName + " completed successfully");

      // retrieve output parameters
      inoutDecimal = callStmt.getBigDecimal(1).setScale( 2 );
      System.out.println("Value of DECIMAL = " + inoutDecimal);

      callStmt.close();
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
  } // callDecimalType

  public static void callAllDataTypes(Connection con)
  {
    try
    {
      // prepare the CALL statement for ALL_DATA_TYPES
      String procName = "ALL_DATA_TYPES";
      String sql = "CALL " +
                   procName + "(:iosmall, :ioint, :iobigint, :ioreal, :iodouble, :char1, :char2, :varchar, :date, :time)";
      CallableStatement callStmt = con.prepareCall(sql);

      // declare and initialize input variables
      short inoutSmallint = 32000;
      int inoutInteger = 2147483000;
      long inoutBigint = 2147483000;
      float inoutReal = 100000;
      double inoutDouble = 2500000;

      // declare output variables
      String outChar, outChars, outVarchar;
      Date outDate;
      Time outTime;

      // set input parameters
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccShortAtName("iosmall", inoutSmallint);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccIntAtName("ioint", inoutInteger);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccLongAtName("iobigint", inoutBigint);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccFloatAtName("ioreal", inoutReal);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccDoubleAtName("iodouble", inoutDouble);

      // register the output parameters
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("iosmall", Types.SMALLINT);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("ioint", Types.INTEGER);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("iobigint", Types.BIGINT);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("ioreal", Types.REAL);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("iodouble", Types.DOUBLE);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("char1", Types.CHAR);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("char2", Types.CHAR);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("varchar", Types.VARCHAR);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("date", Types.DATE);
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).registerJccOutParameterAtName("time", Types.TIME);

      // call the stored procedure
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();
      
      System.out.println(procName + " completed successfully");

      // retrieve output parameters
      inoutSmallint = callStmt.getShort(1);
      inoutInteger = callStmt.getInt(2);
      inoutBigint = callStmt.getLong(3);
      inoutReal = callStmt.getFloat(4);
      inoutDouble = callStmt.getDouble(5);
      outChar = callStmt.getString(6);
      outChars = callStmt.getString(7);
      outVarchar = callStmt.getString(8);
      outDate = callStmt.getDate(9);
      outTime = callStmt.getTime(10);

      System.out.println("Value of SMALLINT = " + inoutSmallint);
      System.out.println("Value of INTEGER = " + inoutInteger);
      System.out.println("Value of BIGINT = " + inoutBigint);
      System.out.println("Value of REAL = " + inoutReal);
      System.out.println("Value of DOUBLE = " + inoutDouble);
      System.out.println("Value of CHAR(1) = " + outChar);
      System.out.println("Value of CHAR(15) = " + outChars.trim());
      System.out.println("Value of VARCHAR(12) = " + outVarchar.trim());
      System.out.println("Value of DATE = " + outDate);
      System.out.println("Value of TIME = " + outTime);
      
      callStmt.close();
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
  } // callAllDataTypes

  public static void callOneResultSet(Connection con)
  {
    try
    {
      // prepare the CALL statement for ONE_RESULT_SET
      String procName = "ONE_RESULT_SET";
      String sql = "CALL " + procName + "(:outMedian)";
      CallableStatement callStmt = con.prepareCall(sql);

      // set input parameter to median value passed back by OUT_PARAM
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccDoubleAtName("outMedian", outMedian);
      
      // call the stored procedure
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();

      System.out.println(procName + " completed successfully");
      ResultSet rs = callStmt.getResultSet();
      fetchAll(rs);

      // close ResultSet and callStmt
      rs.close();
      callStmt.close();
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
  } // callOneResultSet

  public static void callTwoResultSets(Connection con)
  {
    try
    {
      // prepare the CALL statement for TWO_RESULT_SETS
      String procName = "TWO_RESULT_SETS";
      String sql = "CALL " + procName + "(:outMedian)";
      CallableStatement callStmt = con.prepareCall(sql);

      // set input parameter to median value passed back by OUT_PARAM
      ((com.ibm.db2.jcc.DB2CallableStatement)callStmt).setJccDoubleAtName("outMedian", outMedian);

      // call the stored procedure
      System.out.println();
      System.out.println("Call stored procedure named " + procName);
      callStmt.execute();

      System.out.println(procName + " completed successfully");

      System.out.println(
        "Result set 1: Employees with salaries greater than " + outMedian);
      // get first result set
      ResultSet rs = callStmt.getResultSet();
      fetchAll(rs);

      System.out.println();
      System.out.println("Result set 2: Employees with salaries less than " +
                         outMedian);
      // get second result set
      callStmt.getMoreResults();
      rs = callStmt.getResultSet();
      fetchAll(rs);

      // close ResultSet and callStmt
      rs.close();
      callStmt.close();
      
    }
    catch (SQLException e)
    {
      System.out.println(e.getMessage());
    }
  } // callTwoResultSets

  //*************************************************************************
  // PARAMETER STYLE GENERAL and GENERAL WITH NULLS can be specified when
  // LANGUAGE C, COBOL, or CLR is used.
  // Please see the SpClient implementation for CLI language to see this 
  // functionality.
  //*************************************************************************

  // ======================================================
  // Method: fetchAll -- returns all rows from a result set
  // ======================================================
  public static void fetchAll(ResultSet rs)
  {
    try
    {
      System.out.println(
        "=============================================================");
    
      // retrieve the  number, types and properties of the 
      // resultset's columns
      ResultSetMetaData stmtInfo = rs.getMetaData();
      
      int numOfColumns = stmtInfo.getColumnCount();
      int r = 0;

      while (rs.next())
      {
        r++;
        System.out.print("Row: " + r + ": ");
        for (int i = 1; i <= numOfColumns; i++)
        {
          if (i == 3)
          {
            System.out.print(Data.format(rs.getDouble(i), 7, 2));
          }
          else
          {
            System.out.print(rs.getString(i));
          }

          if (i != numOfColumns)
          {
            System.out.print(", ");
          }
        }
        System.out.println();
      }
    }
    catch (Exception e)
    {
      System.out.println("Error: fetchALL: exception");
      System.out.println(e.getMessage());
    }
  } // fetchAll
} // SpServer
