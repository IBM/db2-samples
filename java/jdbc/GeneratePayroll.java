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
// SOURCE FILE NAME: GeneratePayroll.java
//
// SAMPLE: Geneate payroll reports by department
//
// SQL Statements USED:
//         SELECT
//
// Classes used from Util.java are:
//         Db
//         SqljException
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
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


import java.sql.* ;
import java.util.* ;

public class GeneratePayroll
{
  // Empty Constructor for use in other programs
  public GeneratePayroll()
  {
  }

  public static void main(String[] args)
  {
    Db db = null;
    Connection conn = null ;
    System.out.println();
    System.out.println(
      "THIS SAMPLE GENERATES THE PAYROLL REPORTS BY DEPARTMENT.");

    try
    {
    // Obtain a Connection to the 'sample' database
      db = new Db(args);
      db.connect();
      conn = db.con;
    }
    catch(ClassNotFoundException cle)
    {
      System.out.println("  Driver class not found, please check the PATH"
        + " and CLASSPATH system variables to ensure they are correct");
    }
    catch(SQLException sqle)
    {
      System.out.println("  Could not open connection");
      sqle.printStackTrace();
    }
    catch(Exception ne)
    {
      System.out.println("  Unexpected Error");
      ne.printStackTrace();
    }
    // If a connection was obtained successfully run the rest of the Sample
    if(conn != null)
    {
      System.out.println("...............................................");
      System.out.println("  USE THE SQL STATEMENT SELECT TO SELECT");
      System.out.println("  PAYROLL DATA FROM THE EMPLOYEE TABLE");
      try
      {
        Vector al = new Vector();
        Statement st = conn.createStatement();
        // Call getDepartment to get the Work Departments from the Employee
        // Table and to get the users choice
        String dept = getDepartment(conn);

        // Select all Employee information for the Employee's in the Selected
        // Department
        String query = "SELECT EMPNO,FIRSTNME,MIDINIT,LASTNAME"
          + ",WORKDEPT,JOB,SALARY,BONUS,COMM FROM EMPLOYEE";
        if(dept!=null)
        {
          query += " WHERE WORKDEPT LIKE '%" + dept + "%'";
        }
        System.out.println("  "+query);
        // Use a ResultSet Object to store Payroll objects in a vector for
        // later use
        ResultSet rs = st.executeQuery(query);
        for(int i=0;rs.next();i++)
        {
          Payroll pr = new Payroll();
          pr.setEmployeeNumber(rs.getString(1));
          pr.setFirstName(rs.getString(2));
          pr.setMiddleInitial(rs.getString(3));
          pr.setLastName(rs.getString(4));
          pr.setWorkDepartment(rs.getString(5));
          pr.setJob(rs.getString(6));
          pr.setSalary(rs.getDouble(7));
          pr.setBonus(rs.getDouble(8));
          pr.setCommission(rs.getDouble(9));
          al.add(pr);
        }
        Object[] obj = al.toArray();
        Payroll[] pra = new Payroll[obj.length];
        for(int i=0;i<obj.length;i++){
          pra[i]=(Payroll)obj[i];
        }
        // Print the selected users
        printPayroll(pra);
        conn.rollback();
        System.out.println("..............................................");
      }
      catch(SQLException sqle)
      {
        System.out.println("Error while retrieving Payroll");
        sqle.printStackTrace();
      }
      finally{
        if(conn!=null)
        {
          try
          {
            // Try to disconnect from the database
            System.out.println("Disconnecting from 'sample' database ...");
            conn.close();
            db.disconnect();
            System.out.println("Disconnected from 'sample' database.");
          }
          catch(Exception sqle)
          {
            System.out.println("Error closing connection");
            sqle.printStackTrace();
          }
        }
      }
    }
    else
    {
      System.out.println("Retry using correct format");
    }
  }

  private static String getDepartment(Connection conn)
  {
    String[] strArray ;
    try
    {
      Statement st = conn.createStatement() ;
      // Select all Work Departments from the Employee table
      System.out.println(
        "SELECT WORKDEPT FROM EMPLOYEE GROUP BY WORKDEPT"
        );
      ResultSet rs = st.executeQuery(
        "SELECT WORKDEPT FROM EMPLOYEE GROUP BY WORKDEPT"
        );
      strArray = new String[40];
      for(int i=0;rs.next();i++)
      {
        System.out.println(
          (i+1) + ". "
          + rs.getString(1));
        strArray[i] = rs.getString(1);
      }
      rs.close();
      st.close();
      // Get the user input, determine which Department they would like to
      // see the payroll for.
      System.out.println("Select number of Department for generation:");
      char ch = '1';
      String str = "";
      try{
        while((ch=(char)System.in.read())!= '\n')
        {
          str += ch;
        }
        Integer val = new Integer(0);
        try{
          val = new Integer(str);
        }catch(NumberFormatException ne){
          System.out.println("PLEASE USE THE NUMBER IN FRONT OF THE DEPARTMENT NEXT TIME.");
          return null ;
        }
        return strArray[val.intValue()-1];
      }
      catch(Exception e)
      {
        System.out.println("Error reading input");
        e.printStackTrace();
        return null ;
      }
    }
    catch(SQLException e)
    {
      System.out.println("Error getting departments");
      e.printStackTrace();
      return null ;
    }
  }

  // Print the Payroll array for the department that the user selected
  private static void printPayroll(Payroll[] pr)
  {
    for(int i=0;i<pr.length;i++)
    {
      System.out.print(pr[i].getEmployeeNumber()+"\t");
      System.out.print(pr[i].getFirstName()+" ");
      System.out.print(pr[i].getMiddleInitial()+" ");
      System.out.print(pr[i].getLastName()+"\t");
      System.out.print(pr[i].getWorkDepartment()+"\t");
      System.out.print(pr[i].getJob()+"\t");
      System.out.print(pr[i].getSalary()+"\t");
      System.out.print(pr[i].getBonus()+"\t");
      System.out.println(pr[i].getCommission()+"\t");
    }
  }
}

// The Payroll class is used to store the payroll information for a single
// Employee.
class Payroll
{
  private String employeeNumber = "" ;
  private String firstName = "" ;
  private String middleInitial = "" ;
  private String lastName = "" ;
  private String workDepartment = "" ;
  private String job = "" ;

  private double salary = 0.0 ;
  private double bonus = 0.0 ;
  private double commission = 0.0 ;

  // Use a default constructor to create a Payroll object
  public Payroll(){
  }

  // Use the following setters and getters to store and retrieve the
  // payroll information for a given Payroll object.
  public void setEmployeeNumber(String empNo){
    employeeNumber = empNo ;
  }

  public void setFirstName(String fName){
    firstName = fName ;
  }

  public void setMiddleInitial(String mInitial){
    middleInitial = mInitial ;
  }

  public void setLastName(String lName){
    lastName = lName ;
  }

  public void setWorkDepartment(String wDept){
    workDepartment = wDept ;
  }

  public void setJob(String jb){
    job = jb ;
  }

  public void setSalary(double sal){
    salary = sal ;
  }

  public void setBonus(double bns){
    bonus = bns ;
  }

  public void setCommission(double comm){
    commission = comm ;
  }

  public String getEmployeeNumber(){
    return employeeNumber ;
  }

  public String getFirstName(){
    return firstName ;
  }

  public String getMiddleInitial(){
    return middleInitial ;
  }

  public String getLastName(){
    return lastName ;
  }

  public String getWorkDepartment(){
    return workDepartment ;
  }

  public String getJob(){
    return job ;
  }

  public double getSalary(){
    return salary ;
  }

  public double getBonus(){
    return bonus ;
  }

  public double getCommission(){
    return commission ;
  }
}
