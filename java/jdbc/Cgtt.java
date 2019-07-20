//-----------------------------------------------------------------------------
// (c) Copyright IBM Corp. 2008 All rights reserved.
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
//-----------------------------------------------------------------------------
//
// SOURCE FILE NAME: Cgtt.java
//
// SAMPLE: 
//      The sample demonstrates the following:
//       i) Use of Created Temporary table (CGTT) to store intermediate   
//          results. 
//      ii) Use of Created Temporary table with Procedures, Functions, Triggers 
//       and Views. 
//
// PREREQUISITE:
//       1) Sample database is setup on the machine.
//       2) Valid system authorization IDs and password.
//               bob with "bob12345"
//               joe with "joe12345"       
//       3) Execute 'CreateCGTT.db2' script. This script creates all database  
//       objects required for the executing this sample and GRANTS required  
//       privileges to bob an joe.
// 
//
// USAGE SCENARIO:
//                The scenario deals with the employee tax computation process.  
//       At the end of a financial year, the payroll department computes tax 
//       payable by all the employees. The sample demonstrates the use of 
//       created temporary table to store intermediate results during the tax 
//       calculation process. The database contains employee, and payroll tables. 
//       The employee table contains employee details and the payroll table 
//       contains details of employee salary and the total tax payable by the  
//       employee based on his income (salary + bonus) in a finnancial year.
//
//       		Each employee gets tax exemption for salary upto 100,000  
//       the proof for exemption is submitted at the end of the financial 
//       year. At the beginning of financial year the tax payable by an employee 
//       is calculated based on the employees income and the 100,000 exemption 
//       limit. At the end of the year after all the employees of a department 
//       have submitted their tax proofs, the tax calculation process for the 
//       department is trigered. The tax process updates the payroll table with
//       the total tax and the balance tax payable. An Income Tax(IT) statement 
//       is also generated for each employee of the department. 
//
//       	      A TRIGGER is invoked after tax proofs is submitted by all 
//       the employee of a department. The trigger populates the created temporary 
//       table with the details of the employee and his income (salary + any bonus)
//       details and calls a procedure to calculate the tax. All the intermediate
//       results of tax calculation are updated in the CGTT. After the tax calculation
//       is complete another procedure updates the payrool table with the tax data 
//       from the created temporary table. A function generates the IT sheet for  
//       all the employees.
// 
// SAMPLE EXECUTION:
//
//     1) Execute 'CreateCGTT.db2' to create required database objects using 
//        command :
//             db2 -td@ -vf CreateCGTT.db2
//     2) Compile and Execute this sample using commands :       
//             i) javac Cgtt.java
//            ii) java Cgtt.java <Server-name> <Port-number> 
//     3) Execute 'DropCGTT.db2' to drop all the database objects created by the 
//        sample :
//             db2 -td@ -vf DropCGTT.db2
//
// SQL STATEMENTS USED:
//       1) CREATE GLOBAL TEMPORARY TABLE		
//       2) CREATE INDEX
//       3) CREATE VIEW
//       4) CREATE TRIGGER
//       5) CREATE PROCEDURE
//       6) CREATE FUNCTION
//       7) CALL
//       8) RUNSTATS
//       9) TRUNCATE TABLE
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
//-----------------------------------------------------------------------------
// The sample has seven major steps:
//
// ************************************************************************* //
//       Step1 to Step 5 creates all the database objects required for the   //
//       execution of the sample.                                            //
//       Execute 'CreateCGTT.db2' script to create the required database     //
//       objects.                                                            //
//       To execute 'CreateCGTT.db2' issue the command :                     //
//                 db2 -td@ -vf CreateCGTT.db2                               //
// ************************************************************************* //
//       Step1: Create table 'payroll' and populate it.
//       Step2: Create the following objects:
//              - Create a CGTT 'tax_cal'.
//              - View 'ViewOnCgtt' based on 'tax_cal'.
//              - Index 'IndexOnCgtt' based on 'tax_cal'.
//       Step3: Create three procedures and a function 
//                1) tax_compute        : Calculates the tax payable by an 
//                                        employee and returns the value to the 
//                                        CALLER. 
//                2) initial_tax_compute: Calculates the tax payable by an 
//                                        employee initially with a tax   
//                                        exemption of 100,000. This procedure 
//                                        calls the function 'tax_compute' to  
//                                        do the calculation.
//                3) final_tax_compute  : Calculates the tax payable by an 
//                                        employee based on his or her total   
//                                        income (salary + any bonus) and the  
//                                        tax proofs he or she submits. This 
//                                        procedure calls the function 
//                                        'tax_compute' to do the calculation. 
//                4) update             : Updates the created temporary table  
//                                        'tax_cal' with the final results, To  
//                                        update the 'payroll' table to reflect 
//                                        the created temporary table.
//       Step4: Create a function 'printITSheet' to print the IT sheet for the 
//              employees, using the data in the created temporary table 'tax_cal'  
//              through the view 'ViewOnCgtt'.
//       Step5: Create a Trigger 'tax_update' on 'Payroll' table to start the
//              tax calculation process.
//
// ************************************************************************* //
//       Step6 - calculation of tax to be paid by the employees of two       //
//       departments 'D11' and 'D21' is done by this sample 'Cgtt.java'.     //
// ************************************************************************* //
//       Step6: Start the tax computation process for two departments. 
//
// ************************************************************************* //
//       Step7 cleans up all the database objects created by 'CreateCGTT.db2'//
//       Execute 'DropCGTT.db2' script to drop all the database objects      //
//                                                                           //  
//       To execute 'DropCGTT.db2' issue the command :                       //
//                 db2 -td@ -vf DropCGTT.db2                                 //
// ************************************************************************* //
//       Step7: Run the Clean up scripts.
//-----------------------------------------------------------------------------

import java.sql.*;

class Cgtt
{
   static Db db; 
   public static void main(String argv[])
   {
      try
      {
         Connection con1 = null, con2 = null, con3 = null;
         String user1 = "joe";
         String password1 = "joe12345";
         String server = argv[0];
         String port=argv[1];
         
         
         // connect to sample database
         con1 = ConHandler(user1,password1,server,port); 
         con1.setAutoCommit(false); 
         CalTax(con1,"D11",user1);
         
         String user2 = "bob";
         String password2 = "bob12345";
         con2 = ConHandler(user2,password2,server,port); 
         con2.setAutoCommit(false);
         CalTax(con2,"D21",user2);
         db.disconnect();
      }
      catch (Exception e)
      {
         System.out.println("Error Msg: "+ e.getMessage());
      }
   }
  


   public static Connection ConHandler(String user, String password, String serverAdd, String port)
   {
      Connection con = null;	
      String args[]=new String[4];
      args[1]=port;
      args[0]=serverAdd;
      args[2]=user;
      args[3]=password;
      try
      {
         db=new Db(args);
      }
      catch (Exception e)
      {
         System.out.println("  Error loading DB2 Driver...\n");
         System.out.println(e);
         System.exit(1);
      }
         
      try
      {
         con = db.connect();
         con.setAutoCommit(false);
      }
      catch (Exception e)
      {
         System.out.println("Error while Connecting to sample database.");
         System.err.println(e) ;
         System.exit(1);
      }
      return con; 
   }


   static void CalTax(Connection con, String deptnum, String user)
   {
      try
      {
         System.out.print("\n-----------------------------------------------------"+
         "----------------------------------------------------------------------\n");
         System.out.print("Employee of the company '"+user+"' calculates "+ 
                          "the tax for department '"+deptnum+"'...\n");
         System.out.print("'"+user+"' updates the 'payroll' table as per "+
                          "the tax proof submitted by the employees of "+
                          "department '"+deptnum+"'...\n");
         System.out.print("As per the scenario, all employees of '"+deptnum+"' submit "+
                          "tax proofs for '50000'...\n");
         System.out.print("\n------------------------------------------------------"+
         "----------------------------------------------------------------------\n\n");

         String st1 = "UPDATE cgtt.payroll SET tax_proof = 50000 "+
                      "WHERE deptno = '"+deptnum+"'";


         System.out.print("\n'"+user+"' triggers the process of tax "+
                          "calculation by updating the 'calculate_tax' to one "+
                          "for all employees of \n department '"+deptnum+"' after all the "+
                          "employees of the department submit the tax proof\n");
         String st2 = "UPDATE cgtt.payroll SET calculate_tax = 1 "+
                      "WHERE deptno = '"+deptnum+"'";


         System.out.print("Once tax calculation is complete, '"+user+"' "+
                          "set the 'calculate_tax' column back to zero\n"); 
         String stn = "UPDATE cgtt.payroll SET calculate_tax = 0 ";
         

         System.out.println("\nUPDATE payroll SET tax_proof = 50000 "+ 
                               "WHERE deptno = '"+deptnum+"'\n ");

         Statement stmt1 = con.createStatement();
         stmt1.executeUpdate(st1);


         System.out.println("\nUPDATE payroll SET calculate_tax = 1 "+ 
                               "WHERE deptno = '"+deptnum+"'\n \n");

         Statement stmt2 = con.createStatement();
         stmt2.executeUpdate(st2);

         
         Statement stmt3 = con.createStatement();
         stmt3.executeUpdate(stn);

         Process(con);
         PrintITReport(con);         
         con.commit();
      }
      catch(Exception e)
      {
         String Message = e.getMessage();
         System.out.println(Message);
      }
   }


 static void Process(Connection con)
 {
    try 
    {
       java.sql.CallableStatement cstmt;
       String Proc = "CALL cgtt.update()";
       cstmt = con.prepareCall(Proc);
       cstmt.execute(); 
    }
    catch(Exception e)
    {
       String Message = e.getMessage();
       System.out.println(Message);
    }
 }

 static void PrintITReport(Connection con)
 {
    try
    {
       Statement stmt = con.createStatement();
       ResultSet rs = stmt.executeQuery("SELECT * FROM "+
                           "TABLE(cgtt.printITSheet()) as ITSheet");

       ResultSetMetaData rsm = rs.getMetaData();				
       int columnCount = rsm.getColumnCount();
       int i=1;	
       while(i <= columnCount )
       {
          System.out.print(rsm.getColumnName(i)+"\t     ");
          i++;
       }

       System.out.print("\n-----------------------------------------------------"+
       "----------------------------------------------------------------------\n");
       while(rs.next()){
          
          int j=1;
          while(j <= columnCount )
          {
             System.out.print(rs.getString(rsm.getColumnName(j))+"\t     ");
             j++;
          }
             System.out.print("\n");
        }	
        rs.close();
        stmt.close();
       System.out.print("\n-----------------------------------------------------"+
       "----------------------------------------------------------------------\n");
    }
   catch(Exception e)
    {
       String Message = e.getMessage();
       System.out.println(Message);
    }
 }

}
