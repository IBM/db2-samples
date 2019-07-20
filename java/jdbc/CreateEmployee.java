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
// SOURCE FILE NAME: CreateEmployee.java
//
// SAMPLE: Create an employee record
//
// SQL Statements USED:
//         INSERT
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

public class CreateEmployee
{
  // Empty Constructor for use in other programs
  public CreateEmployee()
  {
  }

  public static void main(String[] args)
  {
    System.out.println();
    System.out.println("THIS SAMPLE CREATES A NEW EMPLOYEE RECORD.");

    Connection conn = null ;
    Db db = null ;
    // Use the db Class to get a connection
    try
    {
      db = new Db(args);
      db.connect();
      conn = db.con;
      System.out.println("...............................................");
    }
    catch(ClassNotFoundException cle)
    {
      System.out.println("  Driver class not found, please check the PATH and"
        + " CLASSPATH system variables to ensure they are correct");
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
    //If a connection was properly obtained use it to get a new Employee
    if(conn != null)
    {
      try
      {
        // Use the getEmployee method from below to create a new Employee
        // with user input
        Employee emp = getEmployee();
        // Use the Statement Object to Insert the new Employee into the
        // Employee table
        Statement st = conn.createStatement();
        System.out.println("    USE THE SQL STATEMENT\n      INSERT");
        System.out.println("    TO INSERT DATA INTO A TABLE");
        System.out.println("    INSERT INTO EMPLOYEE VALUES('" + emp.getEmployeeNumber()
          + "','" + emp.getFirstName()
          + "','" + emp.getMiddleInitial()
          + "','" + emp.getLastName()
          + "','" + emp.getWorkDepartment()
          + "','" + emp.getPhoneNumber()
          + "','" + emp.getHireDate()
          + "','" + emp.getJob()
          + "'," + emp.getEducationLevel()
          + ",'" + emp.getSex()
          + "','" + emp.getBirthDate()
          + "'," + emp.getSalary()
          + "," + emp.getBonus()
          + "," + emp.getCommission()
          + ")");
        st.execute("INSERT INTO EMPLOYEE VALUES('" + emp.getEmployeeNumber()
          + "','" + emp.getFirstName()
          + "','" + emp.getMiddleInitial()
          + "','" + emp.getLastName()
          + "','" + emp.getWorkDepartment()
          + "','" + emp.getPhoneNumber()
          + "','" + emp.getHireDate()
          + "','" + emp.getJob()
          + "'," + emp.getEducationLevel()
          + ",'" + emp.getSex()
          + "','" + emp.getBirthDate()
          + "'," + emp.getSalary()
          + "," + emp.getBonus()
          + "," + emp.getCommission()
          + ")");
        // Close the Statement object
        conn.commit();
        st.close();
        System.out.println("    Created new employee successfully");
        //System.out.println("    Rolling Back transactions");
        // Rollback all changes to the database so it is clean for other samples
        //conn.rollback();
        //System.out.println("    Transaction Rolled Back");
	
      }
      catch(SQLException sqle)
      {
        System.out.println("Error while inserting new Employee");
        sqle.printStackTrace();
      }
      /*
         Use the finally clause to close connections, this ensures that they
         are closed before the code exits.
      */
      finally{
        System.out.println("...............................................");
        // Check if the Connection equals null (is valid)
        if(conn!=null)
        {
          try
          {
          // Close the connection object, and disconnect using the db class
            conn.close();
            db.disconnect();
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

  /*
     getEmployee method takes user input and creates a new Employee object
     using the Employee class
  */
  private static Employee getEmployee()
  {
    // Create a new default Employee object
    Employee emp = new Employee();
    try
    {
     // Fill all the Employee Class fields with user input
      String info = null;
      System.out.println("Enter new Employee Number (6 Characters):");
      if((info = getUserInput()) != null)
      {
        emp.setEmployeeNumber(info);
      }
      System.out.println("Enter Employee's First Name (12 Characters):");
      if((info = getUserInput()) != null)
      {
        emp.setFirstName(info);
      }
      System.out.println("Enter Employee's Middle Initial (1 Character):");
      if((info = getUserInput()) != null)
      {
        emp.setMiddleInitial(info);
      }
      System.out.println("Enter Employee's Last Name (15 Characters):");
      if((info = getUserInput()) != null)
      {
        emp.setLastName(info);
      }
      System.out.println("Enter Employee's Work Department (3 Characters):");
      if((info = getUserInput()) != null)
      {
        emp.setWorkDepartment(info);
      }
      System.out.println("Enter Employee's Phone Number (4 digits):");
      if((info = getUserInput()) != null)
      {
        emp.setPhoneNumber(info);
      }
      System.out.println("Enter Employee's Job (8 Characters):");
      if((info = getUserInput()) != null)
      {
        emp.setJob(info);
      }
      System.out.println("Enter Employee's Sex (M/F):");
      if((info = getUserInput()) != null)
      {
        emp.setSex(info);
      }
      System.out.println("Enter Employee's BirthDate (YYYY-MM-DD):");
      if((info = getUserInput()) != null)
      {
        emp.setBirthDate(info);
      }
      System.out.println("Enter Employee's HireDate (YYYY-MM-DD):");
      if((info = getUserInput()) != null)
      {
        emp.setHireDate(info);
      }
      System.out.println("Enter Employee's Education Level (1->20):");
      if((info = getUserInput()) != null)
      {
        emp.setEducationLevel(info);
      }
      System.out.println("Enter Employee's Salary (#######.##):");
      if((info = getUserInput()) != null)
      {
        emp.setSalary(info);
      }
      System.out.println("Enter Employee's Bonus (#######.##):");
      if((info = getUserInput()) != null)
      {
        emp.setBonus(info);
      }
      System.out.println("Enter Employee's Commission (#######.##):");
      if((info = getUserInput()) != null)
      {
        emp.setCommission(info);
      }
    }
    catch(Exception e)
    {
      System.out.println("Error getting departments");
      e.printStackTrace();
    }
    return emp;
  }

  /*
     getUserInput takes the user input from the keyboard and returns a
     String representation to be used in creation of the new Employee
  */
  private static String getUserInput()
  {
    char ch = '1';
    String str = "" ;
    int l = 0;
    try{
        while((ch=(char)System.in.read())!= '\n')
        {
          if (ch != '\r')
            str += ch;
        }
        if(str.length()>0)
        {
          return str;
        }
        return null;
      }
      catch(Exception e)
      {
        System.out.println("Error reading input");
        e.printStackTrace();
        return null ;
      }
  }
}

/*
   Employee Class is used as a Bean class to store all information
   about a single Employee from the Employee Table in the Sample Database.

   Each private member represents a field in the Employee Table, and
   some have default values. Above we fill each field with user input using
   the setter methods of the Employee Class. Next we INSERT the information
   into the database with the help of the getter methods in the Employee
   Class
*/
class Employee
{
  private String employeeNumber = null ;
  private String firstName = null ;
  private String middleInitial = null ;
  private String lastName = null ;
  private String workDepartment = null ;
  private String phoneNumber = null ;
  private String job = null ;
  private String sex = null ;

  private Date hireDate = null ;
  private Date birthDate = null ;

  private int educationLevel = 0 ;

  private double salary = 0.0 ;
  private double bonus = 0.0 ;
  private double commission = 0.0 ;

  private Connection conn = null ;
  private Statement stmt = null ;
  private ResultSet rs = null ;

  public Employee(){
    long hdt = 991111111 ;
    long bdt = 711111111 ;
    employeeNumber = "000500" ; // Change this incase of Primary Key
    firstName = "New" ;
    middleInitial = "T" ;
    lastName = "Employee" ;
    workDepartment = "TST" ;
    phoneNumber = "5555" ;
    hireDate = new Date(hdt) ; // Change to use today's date as default
    job = "Tester" ;
    educationLevel = 0 ;
    sex = "M" ;
    birthDate = new Date(bdt) ; // Change to make 25 years old
    salary = 0.00 ;
    bonus = 0.00 ;
    commission = 0.00 ;
  }

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

  public void setPhoneNumber(String phoneNum){
    phoneNumber = phoneNum ;
  }

  public void setHireDate(Date hdt){
    hireDate = hdt ;
  }

  /*************************************************
   * Input: String hdt: date in format "yyyy-mm-dd"
   */
  public void setHireDate(String hdt)
  {
    hireDate = Date.valueOf(hdt);
  }

  public void setJob(String jb){
    job = jb ;
  }

  public void setEducationLevel(int edLvl){
    educationLevel = edLvl ;
  }

  public void setEducationLevel(String edLvl)
  {
    Integer edl = new Integer(edLvl);
    educationLevel = edl.intValue();
  }

  public void setSex(String sx){
    sex = sx ;
  }

  public void setBirthDate(Date bdt){
    birthDate = bdt ;
  }

  /*************************************************
   * Input: String bdt: date in format "yyyy-mm-dd"
   */
  public void setBirthDate(String bdt)
  {  
    birthDate = Date.valueOf(bdt);

  }

  public void setSalary(double sal)
  {
    salary = sal ;
  }

  public void setSalary(String sal)
  {
    Double dbl = new Double(sal);
    salary = dbl.doubleValue();
  }

  public void setBonus(double bns)
  {
    bonus = bns ;
  }

  public void setBonus(String bns)
  {
    Double dbl = new Double(bns);
    bonus = dbl.doubleValue();
  }

  public void setCommission(double comm)
  {
    commission = comm ;
  }

  public void setCommission(String comm)
  {
    Double dbl = new Double(comm);
    commission = dbl.doubleValue();
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

  public String getPhoneNumber(){
    return phoneNumber ;
  }

  public Date getHireDate(){
    return hireDate ;
  }

  public String getJob(){
    return job ;
  }

  public int getEducationLevel(){
    return educationLevel ;
  }

  public String getSex(){
    return sex ;
  }

  public Date getBirthDate(){
    return birthDate ;
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
