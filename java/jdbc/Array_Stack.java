//****************************************************************************
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
//****************************************************************************
//
// SAMPLE FILE NAME: array_stack.java
//
// PURPOSE: To demonstrate the new ARRAY type and functions CARDINALITY,
// TRIM_ARRAY and UNNEST.
//
// USAGE SCENARIO: The Sample will show use of new ARRAY type in 
// implementation of Stack using stored procedures. A Stack follows last in 
// first out strategy to insert and retrieve values. This sample implements 
// methods to push, pop and select the top value from the Stack. Stacks can 
// be used to store logs for different operations of an application. These 
// logs can later be written to disk or destroyed when the application is 
// closed. Stacks can also be used to store intermediate results while solving 
// complex mathematical expressions. 
//
// PREREQUISITE: Call the script stack_functions.db2 to register the
//               procedures required for stack operations.
//
//               db2 -td@ -vf stack_functions.db2
//
// EXECUTION: javac Array_Stack.java
//            java Array_Stack
//
// INPUTS: NONE
//
// OUTPUT: Creation of object of Array type ,int_stack, in database.
//         Stack values are displayed along with the values returned by pop 
//         and top methods.
//
// OUTPUT FILE: Array_Stack.out (available in the online documentation)
//
// SQL STATEMENTS USED:
//               CALL
//
//***************************************************************************
// For more information about the command line processor (CLP) scripts,
// see the README file.
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, building, and running DB2
// applications, visit the DB2 application development website:
// http://www.software.ibm.com/data/db2/udb/ad
//
//**************************************************************************
//
// SAMPLE DESCRIPTION
//
//**************************************************************************
// 1. Call the "use_stack" store procedure.
//*************************************************************************
import java.sql.*;

public class Array_Stack
{
  public static void main(String argv[])
  {
  
    int val1,val2;
    Integer[] stack=new Integer[3];
    String url = "jdbc:db2:sample";
    int percentage=10;
    com.ibm.db2.jcc.DB2Connection con = null;
    ResultSet rs;
    try
    {

      // connect to the db
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
      // connect to the 'sample' database
      con = (com.ibm.db2.jcc.DB2Connection) DriverManager.getConnection( url );
//*****************************************************************************
//
// 1. Call the "use_stack" store procedure. 
//
//*****************************************************************************

      // prepare the call statement
      String sql = "CALL use_stack(?, ?, ?)";
      CallableStatement callStmt = con.prepareCall(sql);

      // Create an ARRAY type
      stack[0]=new Integer(1);
      stack[1]=new Integer(2);
      stack[2]=new Integer(3);
      java.sql.Array stackArray=con.createArrayOf("INTEGER",stack);

      // set IN parameters
      callStmt.setArray(1,stackArray );

      // Register OUT parameter
      callStmt.registerOutParameter(2, java.sql.Types.INTEGER);
      callStmt.registerOutParameter(3, java.sql.Types.INTEGER);
     
      // call the procedure
      callStmt.execute();
     
      // Retrive the OUT parameter
      val1=callStmt.getInt(2);
      val2=callStmt.getInt(3);
      
      // Retrieve the result set 
      rs=callStmt.getResultSet();
      System.out.println("Stack Contents");
      while(rs.next())
      {
       System.out.println(rs.getInt(1));
      }
      System.out.println("Result of the POP operation : " +val1);
      System.out.println("Result of the TOP operation : " +val2);
     
      // cleanup
      callStmt.close();
      con.close();
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
}

