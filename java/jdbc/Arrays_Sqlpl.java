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
// SAMPLE FILE NAME: Arrays_Sqlpl.java
//
// PURPOSE: To demonstrate the new ARRAY type and functions UNNEST and 
//          ARRAY_AGG.
//
// USAGE SCENARIO: Scenario is based on the employee data in sample database.
// The management has selected best projects based on the projects performance 
// in the current year and decided to give the employees of these projects a 
// performance bonus. The bonus will be a specific percentage of employee 
// salary.
//
// An array of varchar is used to store the selected project names.
// 
// A stored procedure is implemented to calculate the bonus. The stored 
// procedure takes this array and percentage value as input.
//
// PREREQUISITE: Run the script bonus_calculate.db2 using the following
//               command
//               db2 -td@ -vf bonus_calculate.db2
//               This script do the following 
//
//    1. Create the ARRAY types.
//    2. Create the table "bonus_temp".
//    3. Create a stored procedure to calculate the bonus.
//    	3.1 Select the ID and corresponding bonus values in  
//          corresponding ARRAY type "employees" and "bonus" respectively 
//          using aggregate function ARRAY_AGG.
//    	3.2 Use UNNEST function to select the ARRAY elements from ARRAY 
//          variables and insert the same in "bonus_temp" table.
//
// EXECUTION: javac Arrays_Sqlpl.java
//            java Arrays_Sqlpl
//
// INPUTS: NONE
// 
// OUTPUT: The employee IDs and the corresponding bonus will be calculated and
// stored in a table. An employee can work for multiple projects so multiple 
// entries are possible for the same employee id in this table.
//
// OUTPUT FILE: Arrays_Sqlpl.out (available in the online documentation)
//
// SQL STATEMENTS USED:
//               CREATE TABLE 
//		 SELECT
//               DROP
//               CALL
//		 
//*****************************************************************************
// For more information about the command line processor (CLP) scripts,     
// see the README file.                                                     
// For information on using SQL statements, see the SQL Reference.          
//                                                                          
// For the latest information on programming, building, and running DB2     
// applications, visit the DB2 application development website:             
// http://www.software.ibm.com/data/db2/udb/ad   
//  
//*****************************************************************************
//
// SAMPLE DESCRIPTION
//
//*****************************************************************************
// 1. Call the stored procedure to calculate the bonus. Input to this
//    stored procedure will be the ARRAY of all the projects which are 
//    applicable for the bonus.
// 2. Select the data from the table "bonus_temp".
//*****************************************************************************

import java.sql.*;

public class Arrays_Sqlpl  
{
  public static void main(String argv[])
  {
   String[] projects=new String[10];
    String url = "jdbc:db2:sample";
    int percentage=10;  
    com.ibm.db2.jcc.DB2Connection con = null;

    try
    {

      // connect to the db
      Class.forName("com.ibm.db2.jcc.DB2Driver").newInstance();
      // connect to the 'sample' database
      con = (com.ibm.db2.jcc.DB2Connection) DriverManager.getConnection( url );
      Statement stmt=con.createStatement();
      
//*****************************************************************************
//
// 1. Call the stored procedure to calculate the bonus. The input to this
//   stored procedure will be the ARRAY of all the projects which are 
//   applicable for bonus.
//*****************************************************************************

      // Prepare the call statement
      String sql = "CALL bonus_calculate(?, ?)";
      CallableStatement callStmt = con.prepareCall(sql);

      // Create an SQL Array
      projects[0] = "AD3111";
      projects[1] = "IF1000";
      projects[2] = "MA2111";
      java.sql.Array projectArray=con.createArrayOf("VARCHAR",projects);

      // set IN parameters
      callStmt.setArray(1, projectArray);
      callStmt.setInt(2,percentage);
      
      // call the procedure
      callStmt.execute();

//*****************************************************************************
//
// 2. Select the data from the table "bonus_temp".
//
//*****************************************************************************      
 
      String selectStmt = "SELECT * FROM bonus_temp";
      ResultSet rs = stmt.executeQuery(selectStmt);
      while(rs.next())
      {
       System.out.println("Employee ID :"+rs.getString(1));
       System.out.println("Bonus :"+rs.getDouble(2));
      }

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
} // end Arrays_Sqlpl

