//******************************************************************************
//   (c) Copyright IBM Corp. 2008 All rights reserved.
//
//   The following sample of source code ("Sample") is owned by International
//   Business Machines Corporation or one of its subsidiaries ("IBM") and is
//   copyrighted and licensed, not sold. You may use, copy, modify, and
//   distribute the Sample in any form without payment to IBM, for the purpose
//   of assisting you in the development of your applications.
//
//   The Sample code is provided to you on an "AS IS" basis, without warranty of
//   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR
//   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
//   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do
//   not allow for the exclusion or limitation of implied warranties, so the
//   above limitations or exclusions may not apply to you. IBM shall not be
//   liable for any damages you suffer as a result of using, copying, modifying
//   or distributing the Sample, even if IBM has been advised of the possibility
//   of such damages.
//******************************************************************************
//
//  SAMPLE FILE NAME: ImplicitCasting.java
//
//  PURPOSE: To demonstrate use of implicit casting. 
//                01. STRING to NUMERIC assignment
//                02. NUMERIC to STRING assignment
//                03. STRING to NUMERIC comparison
//                04. NUMERIC to STRING comparison
//                05. USE of BETWEEN PREDICATE 
//                06. Implicit Casting with UNION
//                07. Assignment of a TIMESTAMP
//                08. Implicit Casting in following scalar functions
//                    a. CONCAT
//                    b. REAL
//                09. Untyped null
//                10. Untyped Expression
//                 
//
//  PREREQUISITE: 
//
//
//  INPUTS:       NONE
//
//  OUTPUT:       Result of all the functionalities
//
//  OUTPUT FILE: ImplicitCasting.out (available in online documentation)
//
//  SQL STATEMENTS USED:
//			     CREATE TABLE
//			     INSERT
//		 	     SELECT
//		 	     VALUES
//		 	     TRUNCATE TABLE
//			     DROP TABLE
//
//  SQL ROUTINES USED:
//         NONE
//
//  JAVA 2 CLASSES USED:
//         Statement
//         ResultSet
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// *************************************************************************
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//
// http://www.ibm.com/software/data/db2/ad/
//
// *************************************************************************/
//  SAMPLE DESCRIPTION
//
// /*************************************************************************
//
//  1. Implicit casting between string and numeric data on assignments.
//  2. Implicit casting between string and numeric data on comparisons.
//  3. USE of BETWEEN PREDICATE
//  4. Implicit casting between string and numeric data for arithmetic
//     operations.
//  5  Support for assignment of a timestamp to a date or time.
//  6. Implicit Casting in scalar functions.
//  7. Untyped null
//  8. Untyped Expression
//
/***************************************************************************/

import java.lang.*;
import java.sql.*;

class ImplicitCasting
{
  static Db db;
  public static void main(String argv[])
  {
    try
    {
      System.out.println();
      System.out.println("This sample is to demonstrate use of implicit casting");
      
      Connection con = null;
      ResultSet rs = null;
      
      // connect to sample database
      try
      {
         db=new Db(argv);

      }
      catch (Exception e)
      {
         System.out.println("  Error loading DB2 Driver...\n");
         System.out.println(e);
         System.exit(1);
      }
      try
      {
         con=db.connect();
         con.setAutoCommit(false);
      }
      catch (Exception e)
      {
         System.out.println("Connection to sample db can't be established.");
         System.err.println(e) ;
         System.exit(1);
      }

      // Create the temp table
      CreateTable(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Implicit Casting between string and numeric data on           */");
      System.out.println("/* assignments.                                                  */");
      System.out.println("/*****************************************************************/");
    
      StringAndNumeric(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* USE BETWEEN PREDICATE                                         */");
      System.out.println("/*****************************************************************/");

      UseBetween(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Implicit casting with UNION                                   */");
      System.out.println("/*****************************************************************/");

      WithUnion(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Implicit casting between string and numeric data for          */");
      System.out.println("/* arithmetic operations.                                        */");
      System.out.println("/*****************************************************************/");

      CastingForArithmetic(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Implicit casting in assignment of a timestamp                 */");
      System.out.println("/*****************************************************************/");

      AssignTimestamp(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Implicit Casting in some scalar functions.                    */");
      System.out.println("/*****************************************************************/");

      CastingForScalarFunctions(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Null Enhancements with Implicit Casting                       */");
      System.out.println("/*****************************************************************/");

      NullEnhancements(con);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Use of Untyped Expressions                                    */");
      System.out.println("/*****************************************************************/");

      UntypedExpressions(con);

      // Drop the temp_employee table
      DropTable(con);
  }
  catch (Exception e)
   {
      System.out.println("Error Msg: "+ e.getMessage());
   }
 }// Main

 static void CreateTable(Connection con)
 {
   try
   {
      String st="CREATE TABLE temp_employee(" +
			" empno INT NOT NULL," +
                        " firstname CHAR(12) NOT NULL," +
			" midinit CHAR(1)," +
			" lastname CHAR(15) NOT NULL," +
			" workdept VARCHAR(3)," +
			" phoneno CHAR(4)," +
			" hiredate DATE," +
                        " job CHAR(8)," +
			" edlevel SMALLINT NOT NULL," +
			" sex CHAR(1), birthdate DATE," +
			" salary DECIMAL(9,2), bonus INT, comm INT)";
                    
      System.out.println("\n\n CREATE TABLE temp_employee(" +
                        " empno INT NOT NULL," +
                        " firstname CHAR(12) NOT NULL," +
                        " midinit CHAR(1)," +
                        " lastname CHAR(15) NOT NULL," +
                        " workdept VARCHAR(3)," +
                        " phoneno CHAR(4)," +
                        " hiredate DATE," +
                        " job CHAR(8)," +
                        " edlevel SMALLINT NOT NULL," +
                        " sex CHAR(1), birthdate DATE," +
                        " salary DECIMAL(9,2), bonus INT, comm INT))\n \n");
      Statement stmt = con.createStatement();
      stmt.executeUpdate(st);
    }
    catch(Exception e)
    {
       System.out.print(" Create Table temp_employee Failed....."+e);
    }
 }//CreateTable

static void DescribeTable(Connection con,String tablename)
{

    try
     {
      String tabname = tablename;
      CallableStatement callStmt = null;

      // prepare the CALL statement
      String sql = "CALL SYSPROC.ADMIN_CMD(?)";
      callStmt = con.prepareCall(sql);

      String param = "DESCRIBE TABLE " + tabname;

      // setting the imput parameter
      callStmt.setString(1, param);

      System.out.println("\nCALL ADMIN_CMD('" + param + "')");
      callStmt.execute();

      ResultSet rs = callStmt.getResultSet();
 
      // retrieving the resultset
      while (rs.next())
      {

        // retrieving column name and displaying it
        String colname = rs.getString(1);
        System.out.println("\nColname     = " + colname);

        // retrieving typeschema and displaying it
        String typeschema = rs.getString(2);
        System.out.println("Typeschema  = " + typeschema);

        // retrieving typename and displaying it
        String typename = rs.getString(3);
        System.out.println("Typename    = " + typename);

        // retrieving length and displaying it
        int length = rs.getInt(4);
        System.out.println("Length      = " + length);

        // retrieving scale and displaying it
        int scale = rs.getInt(5);
        System.out.println("Scale       = " + scale);

        // retrieving nullable and displaying it
        String nullable = rs.getString(6);
        System.out.println("Nullable    = " + nullable);

      }
      rs.close();
      callStmt.close();

    }
    catch(Exception e)
    {
       System.out.print(" Describe Table Failed....."+e);
    }

}// DescribeTable

// Select data from the Employee table
static void SelectFromEmployee(ResultSet rs)
{
try
   {

      System.out.println("\n\n Empno \t Firstname \t Midint \t Lastname \t " +
                         "Workdept \t Phoneno  \t Hiredate \t Job \t Edlevel \t " +
                         "Sex \t Birthdate \t Salary \t Bonus \t Comm  ");

      System.out.println("\n ------------------------------------------------------- " +
                             "-------------------------------------------------------------\n");
      while (rs.next())
       {
                  
        String empno = rs.getString(1);
        System.out.print(empno);

        String firstname = rs.getString(2);
        System.out.print("\t" + firstname);

        String midint = rs.getString(3);
        System.out.print("\t" + midint);

        String lastname = rs.getString(4);
        System.out.print("\t" + lastname);

        String workdept = rs.getString(5);
        System.out.print("\t" + workdept);

        String phoneno = rs.getString(6);
        System.out.print("\t" + phoneno);

        Date hiredate = rs.getDate(7);
        System.out.print("\t" + hiredate);

        String job = rs.getString(8);
        System.out.print("\t" + job);
        
        int edlevel = rs.getInt(9);
        System.out.print("\t" + edlevel);
        
        String sex = rs.getString(10);
        System.out.print("\t" + sex);

        Date birthdate = rs.getDate(11);
        System.out.print("\t" + birthdate);

        String salary = rs.getString(12);
        System.out.print("\t" + salary);

        String bonus = rs.getString(13);
        System.out.print("\t" + bonus);

        String comm = rs.getString(14);
        System.out.print("\t" + comm);
 
        System.out.println("\n ");

       }
       rs.close();

   }
    catch(Exception e)
    {
       System.out.print(" Select from employee Failed....."+e);
    }

}// SelectFromEmployee

// Select data from temp_Employee table
static void SelectFromTempEmployee(ResultSet rs)
{
try
   {

      System.out.println("\n\n Temp_Empno \t Temp_Firstname \t Temp_Midint \t Temp_Lastname  " +
                             "Temp_Workdept \t Temp_Phoneno \t Temp_Hiredate \t Temp_Job \t " +
                             "Temp_Edlevel \t Temp_Sex \t Temp_Birthdate \t Temp_Salary \t " +
                             "Temp_Bonus \t Temp_Comm  ");

      System.out.println("\n ------------------------------------------------------- " +
                             "------------------------------------------------------------\n");
       while (rs.next())
       {

        int temp_empno = rs.getInt(1);
        System.out.print(temp_empno);

        String temp_firstname = rs.getString(2);
        System.out.print("\t" + temp_firstname);

        String midint = rs.getString(3);
        System.out.print("\t" + midint);

        String temp_lastname = rs.getString(4);
        System.out.print("\t" + temp_lastname);

        String temp_workdept = rs.getString(5);
        System.out.print("\t" + temp_workdept);

        String temp_phoneno = rs.getString(6);
        System.out.print("\t" + temp_phoneno);

        Date temp_hiredate = rs.getDate(7);
        System.out.print("\t" + temp_hiredate);

        String temp_job = rs.getString(8);
        System.out.print("\t" + temp_job);

        int temp_edlevel = rs.getInt(9);
        System.out.print("\t" + temp_edlevel);

        String temp_sex = rs.getString(10);
        System.out.print("\t" + temp_sex);

        Date temp_birthdate = rs.getDate(11);
        System.out.print("\t" + temp_birthdate);

        float temp_salary = rs.getFloat(12);
        System.out.print("\t" + temp_salary);

        String temp_bonus = rs.getString(13);
        System.out.print("\t" + temp_bonus);

        String temp_comm = rs.getString(14);
        System.out.print("\t" + temp_comm);

        System.out.println("\n ");

       }
       rs.close();
      
   }
    catch(Exception e)
    {
       System.out.print(" Select from temp_employee Failed....."+e);
    }

}// SelectFromTempEmployee



static void StringAndNumeric(Connection con)
{
  try
   {

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* STRING TO NUMERIC ASSIGNMENT                                  */");
      System.out.println("/*****************************************************************/");

      System.out.println("\n DESCRIBE TABLE temp_employee");
      System.out.println("\n------------------------------------\n");

      DescribeTable(con,"temp_employee");
 

      System.out.println("\n DESCRIBE TABLE employee");
      System.out.println("\n------------------------------------\n");

      DescribeTable(con,"employee");


      System.out.println("\nSELECT * FROM employee "+
                         "WHERE empno < '000100' ");
      System.out.println("\n------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM employee "+
                              "WHERE empno < '000100'");
       
      SelectFromEmployee(rs);


       // In employee table empno is of STRING type and in temp_employee table
       // empno is of NUMERIC type.

       // Copy data from one table to another table of different datatypes without 
       // changing the table structure.

       stmt.executeUpdate("INSERT INTO temp_employee SELECT * FROM employee");

       // Fetch data from temp_employee table
       System.out.println("\nSELECT * FROM temp_employee "+
                                      "WHERE empno < 000100 ");
       System.out.println("\n------------------------------------\n");

       rs = stmt.executeQuery("SELECT * FROM temp_employee "+
                              "WHERE empno < 000100");

       SelectFromTempEmployee(rs);

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* NUMERIC TO STRING ASSIGNMENT                                  */");
      System.out.println("/*****************************************************************/");

      // In temp_table data type of column phoneno is STRING. Update phoneno column
      // by passing NUMERIC phone number.

      System.out.println("\n UPDATE temp_employee " + 
                                      "SET phoneno = 5678 "+
                                      "WHERE empno = '000110'");
      System.out.println("\n------------------------------------\n");

      stmt.executeUpdate("UPDATE temp_employee " + 
                                  "SET phoneno = 5678 "+
                                  "WHERE empno = '000110'");

      System.out.println("\nSELECT * FROM temp_employee "+
                         "WHERE phoneno = 5678 ");
      System.out.println("\n------------------------------------\n");

       rs = stmt.executeQuery("SELECT * FROM temp_employee "+
                              "WHERE phoneno = 5678");
       SelectFromTempEmployee(rs);
       rs.close();
       
      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* Implicit Casting between string and numeric data on comparison*/");
      System.out.println("/*****************************************************************/");

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* STRING TO NUMERIC COMPARISON                                  */");
      System.out.println("/*****************************************************************/");


     // Retrieve rows from temp_employee table where empno is 000330.
     // In temp_employee table empno is of NUMERIC TYPE.
     // Pass empno as STRING while fetching the data from table.

     System.out.println("\nSELECT * FROM temp_employee "+
                         " WHERE empno = '000330'");
     System.out.println("\n------------------------------------\n");

      rs = stmt.executeQuery("SELECT * FROM temp_employee "+
                              " WHERE empno = '000330'");
      SelectFromTempEmployee(rs);
      rs.close();
      

      System.out.println("\n\n/*****************************************************************/");
      System.out.println("/* NUMERIC TO STRING COMPARISON                                  */");
      System.out.println("/*****************************************************************/");

      // Retrieve rows from temp_employee table where salary is 37750.00 
      // or bonus is 400 or comm is 1272.
      // 
      // In temp_employee table salary, bonus, comm is of NUMERIC TYPE.
      // Pass salary, bonus, comm as STRING while fetching the data from table.


     System.out.println("\nSELECT * FROM temp_employee "+
                         " WHERE salary = '37750.00'" +
                         " OR bonus = '400' OR comm = '1272'");
     System.out.println("\n------------------------------------\n");
  
      rs = stmt.executeQuery("SELECT * FROM temp_employee "+
                         " WHERE salary = '37750.00'" +
                         " OR bonus = '400' OR comm = '1272'");
      SelectFromTempEmployee(rs);
      rs.close();
      stmt.close();

    }
    catch(Exception e)
    {
       System.out.print("Implicit Casting between string and numeric data Failed....."+e);
    }
 }//StringAndNumeric


static void UseBetween(Connection con)
{

try
   {
     // BETWEEN predicate compares a value with a range of values.
     // Pass STRING value of empno as range1 and NUMERIC value of empno as range2.
 
     System.out.println("\nSELECT * FROM temp_employee "+
                         " WHERE empno" +
                         " BETWEEN '000120' AND 000160");
     System.out.println("\n------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM temp_employee "+
                         " WHERE empno" +
                         " BETWEEN '000120' AND 000160");
      SelectFromTempEmployee(rs);
      rs.close();
      stmt.close();


}
    catch(Exception e)
    {
       System.out.print(" UseBetween Failed....."+e);
    }


}// UseBetween
 

static void WithUnion(Connection con)
{

try
   {

    //  Here columns in the query are of different type.
    //  firstname is of CHAR type, phoneno is of CHAR type, projname is of VARCHAR
    //  type and prstaff is of DECIMAL type.

     System.out.println("\nSELECT firstname, phoneno AS col1 "+
                         " FROM temp_employee" +
                         " WHERE workdept = 'D11' " +
                         " UNION " +
                         " SELECT projname, prstaff AS col2" +
                         " FROM proj" +
                         " WHERE deptno = 'E21'");
     System.out.println("\n------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT firstname, phoneno AS col1 "+
                         " FROM temp_employee" +
                         " WHERE workdept = 'D11' " +
                         " UNION " +
                         " SELECT projname, prstaff AS col2" +
                         " FROM proj" +
                         " WHERE deptno = 'E21'");

     System.out.println("\n Col1      col2  \n");
     
     // retrieving the resultset
      while (rs.next())
      {
        // retrieving data and displaying it
        String col1 = rs.getString(1);
        System.out.print(col1);

        String col2 = rs.getString(2);
        System.out.print("\t"+col2);

        System.out.println("\n ");
      }

      rs.close();
      stmt.close();


}
    catch(Exception e)
    {
       System.out.print(" WithUnion Failed....."+e);
    }
}// WithUnion 


static void CastingForArithmetic(Connection con)
{
try
   {
     // STRING and NUMERIC data can be used in arithmetic operation.
     // Update salary of empno 000250 by adding bonus + comm 

     System.out.println("\nUPDATE temp_employee "+
                         " SET SALARY = SALARY + comm + bonus + '1000'" +
                         " WHERE empno = 000250");
     System.out.println("\n------------------------------------\n");

     Statement stmt = con.createStatement();
     stmt.executeUpdate("UPDATE temp_employee "+
                         " SET SALARY = SALARY + comm + bonus + '1000'" +
                         " WHERE empno = 000250");
    

     System.out.println("\nSELECT salary AS updated_salary "+
                         " FROM temp_employee" +
                         " WHERE empno = '000250'");
     System.out.println("\n------------------------------------\n");
     ResultSet rs = stmt.executeQuery("SELECT salary AS updated_salary "+
                         " FROM temp_employee" +
                         " WHERE empno = '000250'");

     System.out.println("\n Updated_salary ");
      // retrieving the resultset
      while (rs.next())
      {
        // retrieving updated_salary and displaying it
        int sal= rs.getInt(1);
        System.out.println(sal);

       }
      rs.close();
      stmt.close();

}
    catch(Exception e)
    {
       System.out.print("CastingForArithmetic Failed....."+e);
    }

}// CastingForArithmetic


static void AssignTimestamp(Connection con)
{
try
   {

     Statement stmt = con.createStatement();
  
     //  Create table date_time 
     System.out.print("CREATE TABLE date_time (new_date DATE, new_time TIME)");
     stmt.executeUpdate("CREATE TABLE date_time (new_date DATE, new_time TIME)");


     //  Insert values into date_time
     stmt.executeUpdate("INSERT INTO date_time " +
                            " VALUES ('2008-04-11-03.45.30.999', " +
                            " '2008-04-11-03.45.30.999')"); 

     stmt.executeUpdate("INSERT INTO date_time " +
                            " VALUES ('2008-05-12-03.45.30.123', " +
                            " '2008-05-12-03.45.30.123')");

     // Fetch data from data_time table
     System.out.println("\nSELECT TO_CHAR(new_date, 'DAY-YYYY-Month-DD'), "+
                         " new_time FROM date_time");
     System.out.println("\n------------------------------------\n");
     ResultSet rs = stmt.executeQuery("SELECT TO_CHAR(new_date, 'DAY-YYYY-Month-DD'), "+
                         " new_time FROM date_time");

     System.out.println("\n NewDate          NewTime \n");
     System.out.println("\n------------------------------------\n");
      
     // retrieving the resultset
     while (rs.next())
      {
        // retrieving data and displaying
        String newdate= rs.getString(1);
        System.out.print(newdate);

	Time newtime = rs.getTime(2);
        System.out.print("\t" + newtime); 
        
        System.out.println("\n ");

       }
      rs.close();

     //  drop table date_time 
     System.out.print("DROP TABLE date_time");
     stmt.executeUpdate("DROP TABLE date_time");

      stmt.close();


}
    catch(Exception e)
    {
       System.out.print(" AssignTimestamp Failed....."+e);
    }
}// AssignTimestamp


static void CastingForScalarFunctions(Connection con)
{



      System.out.println("/*****************************************************************/");
      System.out.println("/* USE of CONCAT scalar function                                 */");
      System.out.println("/*****************************************************************/");
      try
      {

      //  CONCAT scalar function can take arguments of different data types.
      System.out.println("\nSELECT CONCAT (CONCAT (CONCAT "+
                         "(CONCAT (empno, ' || ' ), "+
                         " firstname),' || '), hiredate) AS employee_information" +
                         " FROM temp_employee " +
                         " WHERE empno BETWEEN " +
                         " 000100 AND '000340' ");
      System.out.println("\n------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT CONCAT (CONCAT (CONCAT "+
                         "(CONCAT (empno, ' || ' ), "+
                         " firstname),' || '), hiredate) AS employee_information" +
                         " FROM temp_employee " +
                         " WHERE empno BETWEEN " +
                         " 000100 AND '000340' ");
      
     System.out.println("\n employee_information");
     System.out.println("\n------------------------------------\n");
      
     // retrieving the resultset
     while (rs.next())
     {
        // retrieving data and displaying
        String empinfo= rs.getString(1);
        System.out.println(empinfo);

      }
      rs.close();
      stmt.close();

    }
    catch(Exception e)
    {
       System.out.print(" UseConcat Failed....."+e);
    }

      
     System.out.println("\n\n/*****************************************************************/");
     System.out.println("/* USE of REAL scalar function                                   */");
     System.out.println("/*****************************************************************/");
     try
     {

     // Real scalar function can take string and numeric arguments.
     System.out.println("\nSELECT REAL (salary) as real_salary "+
                                          " FROM temp_employee ");
     System.out.println("\n------------------------------------\n");
     Statement stmt = con.createStatement();
     ResultSet rs = stmt.executeQuery("SELECT REAL(salary) as real_salary FROM temp_employee ");

     System.out.println("\n real_salary");
     System.out.println("\n------------------------------------\n");
      // retrieving the resultset
      while (rs.next())
      {
        // retrieving data and displaying
        int real_salary= rs.getInt(1);
        System.out.println(real_salary);

       }
      rs.close();    

     System.out.println("\nSELECT REAL (CAST(salary AS CHAR(9))) "+
                         " as real_salary FROM temp_employee ");
     System.out.println("\n------------------------------------\n");

     rs = stmt.executeQuery("SELECT REAL (CAST(salary AS CHAR(9))) "+
                         " as real_salary FROM temp_employee ");
     System.out.println("\n real_salary");
     System.out.println("\n------------------------------------\n");
     // retrieving the resultset
     while (rs.next())
      {
        // retrieving data and displaying
        int realsalary= rs.getInt(1);
        System.out.println(realsalary);

       }

      rs.close();
      stmt.close();

    }
    catch(Exception e)
    {
       System.out.print(" UseReal Failed....."+e);
    }
      

}// CastingForScalarFunctions

static void NullEnhancements(Connection con)
{
   try
   {

    // Null can be used anywhere in the expression. 
    Statement stmt = con.createStatement();
    stmt.executeUpdate(" UPDATE temp_employee SET comm = NULL  WHERE empno = 000330");

    // Select row where empno is 000330
    System.out.println("\nSELECT * FROM temp_employee WHERE empno = 000330 ");
    System.out.println("\n------------------------------------\n");
    ResultSet rs = stmt.executeQuery("SELECT * FROM temp_employee WHERE empno = 000330");
    SelectFromTempEmployee(rs);
    rs.close();
     
    //  If either operand is null, the result will be null.
    stmt.executeUpdate(" UPDATE temp_employee SET salary = salary + comm + NULL  WHERE empno = 000330 ");

    // Select row where empno is 000330
    rs = stmt.executeQuery("SELECT * FROM temp_employee WHERE empno = 000330 ");
    SelectFromTempEmployee(rs); 
    rs.close();
    stmt.close();

    }
    catch(Exception e)
    {
       System.out.print(" NullEnhancements Failed....."+e);
    }
}// NullEnhancements

static void UntypedExpressions(Connection con)
{	
   try
   {

   System.out.println("\n\n*****************************************************");
   System.out.println("\n Use of Untyped Expressions" );
   System.out.println("*****************************************************");

   /* Pass empno as numeric and string in parameter marker */
   System.out.println("\n SELECT fisrtname, lastname FROM org WHERE empno = ?");
   System.out.println("\n------------------------------------\n");

   String empno = "000110";
   Statement stmt = con.createStatement();
   ResultSet rs = stmt.executeQuery("SELECT firstname,lastname FROM temp_employee WHERE empno = " + empno);
    
   System.out.println("\n fisrtname lastname ");
   System.out.println("\n------------------------------------\n");
   // retrieving the resultset
   while (rs.next())
   {
        // retrieving data and displaying
        String fname= rs.getString(1);
        System.out.print(fname);

        String lname= rs.getString(2);
        System.out.print("\t" +lname);

        System.out.println("\n ");
   }
   
    rs.close();
    stmt.close();

   }
   catch(Exception e)
   {
      System.out.println("Untyped Expression failed.....");
   }
 } // UntypedExpressions


//Drop table temp_employee

static void DropTable(Connection con)
{	
   try
   {
      String st="DROP TABLE temp_employee";
      Statement stmt = con.createStatement();
      stmt.executeUpdate(st);
      System.out.println("\n\nDrop table temp_employee; \n");
      con.commit();
      db.disconnect();
   }
   catch(Exception e)
   {
      System.out.println("Unable to drop table.....");
   }
 } //DropTable

}// ImplicitCasting


