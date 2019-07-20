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
// SOURCE FILE NAME: TbSel.java
//
// SAMPLE: How to select from each of: insert, update, delete.
//
// SQL Statements USED:
//         INCLUDE
//         CREATE TABLE
//         INSERT
//         SELECT FROM INSERT
//         SELECT FROM UPDATE
//         SELECT FROM DELETE
//         PREPARE
//         DROP TABLE
// 
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//        
// OUTPUT FILE: TbSel.out (available in the online documentation)
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

import java.lang.*;
import java.sql.*;

class TbSel
{
  static Db db;
  public static void main(String argv[])
  {
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
    

      System.out.println();
      System.out.println(
        "THIS EXAMPLE SHOWS HOW TO SELECT FROM EACH OF: " +
	"INSERT, UPDATE, DELETE.\n");

    

      Create(con);
      Print(con);
      Buy_Company(con);
      Print(con);
      Drop(con);

      // Disconnect from database.
      con.close();
      System.out.println();
      System.out.println("  Disconnect from 'sample' database.");
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
  } // Main

  /* The Create function creates and populates the tables used by the 
     sample. 
  */
  static void Create(Connection con)
  {
    try
    {

      /* The context for this sample is that of a Company B taking over 
         a Company A.  This sample illustrates how company B incorporates 
         data from table company_b into table company_a.
      */

      System.out.println(
        "\nCREATE TABLE company_a \n" +
	" (ID SMALLINT NOT NULL UNIQUE, \n" +
	" NAME VARCHAR(9), \n" +
	" DEPARTMENT SMALLINT, \n" +
	" JOB CHAR(5), \n" +
	" YEARS SMALLINT, \n" +
	" SALARY DECIMAL(7,2))\n"); 

      // Company A is being bought out.
      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "CREATE TABLE company_a " +
	"(ID SMALLINT NOT NULL UNIQUE, " +
	"NAME VARCHAR(9), " +
	"DEPARTMENT SMALLINT, " +
	"JOB CHAR(5), " +
	"YEARS SMALLINT, " +
	" SALARY DECIMAL(7,2))"); 
      stmt.close();

      System.out.println(
       	"CREATE TABLE company_b \n" +
	" (ID SMALLINT GENERATED BY DEFAULT AS IDENTITY (START WITH 2000, " +
	"INCREMENT BY 1) NOT NULL, \n" +
	" NAME VARCHAR(9), \n" +
	" DEPARTMENT SMALLINT, \n" +
	" JOB CHAR(5), \n" +
	" YEARS SMALLINT, \n" +
	" SALARY DECIMAL(7,2), \n" +
	" BENEFITS VARCHAR(50), \n" +
	" OLD_ID SMALLINT)\n");
      
      // Company B is buying out Company A.  This table has a few 
      // additional columns and differences from the previous table.
      // Specifically, the ID column is generated.
      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate(
	"CREATE TABLE company_b " +
	"(ID SMALLINT GENERATED BY DEFAULT AS IDENTITY (START WITH 2000, " +
	"INCREMENT BY 1) NOT NULL, " +
	"NAME VARCHAR(9), " +
	"DEPARTMENT SMALLINT, " +
	"JOB CHAR(5), " +
	"YEARS SMALLINT, " +
	"SALARY DECIMAL(7,2), " +
	"BENEFITS VARCHAR(50), " +
	"OLD_ID SMALLINT)");
      stmt1.close();

      System.out.println(
	"CREATE TABLE salary_change \n" +
	" (ID SMALLINT NOT NULL UNIQUE, \n" + 
	" OLD_SALARY DECIMAL(7,2), \n" +
	" SALARY DECIMAL(7,2))\n"); 

      // This table can be used by the management of Company B to see how 
      // much of a raise they gave to employees from Company A for joining
      // Company B (in a dollar amount, as opposed to a 5% increase).
      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate(
	"CREATE TABLE salary_change " +
	"(ID SMALLINT NOT NULL UNIQUE, " + 
	"OLD_SALARY DECIMAL(7,2), " +
	"SALARY DECIMAL(7,2))");	
      stmt2.close();

      System.out.println(
	"INSERT INTO company_a VALUES(5275, 'Sanders', 20, 'Mgr', 15, " +
	"18357.50), \n" +
        " (5265, 'Pernal', 20, 'Sales', NULL, 18171.25), \n" + 
        " (5791, 'O''Brien', 38, 'Sales', 9, 18006.00)\n");

      // Populate table company_a with data.
      Statement stmt3 = con.createStatement();
      stmt3.executeUpdate(
	"INSERT INTO company_a VALUES(5275, 'Sanders', 20, 'Mgr', 15, " +
	"18357.50), " +
        "(5265, 'Pernal', 20, 'Sales', NULL, 18171.25), " + 
        "(5791, 'O''Brien', 38, 'Sales', 9, 18006.00)");
      stmt3.close();

      System.out.println(
	"INSERT INTO company_b VALUES " +
	" (default, 'Naughton', 38, 'Clerk', NULL, 12954.75, " +
	"'No Benefits', NULL), \n" +
        " (default, 'Yamaguchi', 42, 'Clerk', 5, 10505.00, " +
	"'Basic Health Coverage', NULL), \n" +
        " (default, 'Fraye', 51, 'Mgr', 8, 21150.00, " +
	"'Basic Health Coverage', NULL), \n" +
        " (default, 'Williams', 51, 'Sales', 10, 19456.50, " +
	"'Advanced Health Coverage', NULL), \n" +
        " (default, 'Molinare', 10, 'Mgr', 15, 22959.20, " +
	"'Advanced Health Coverage and Pension Plan', NULL)");

      // Populate table company_b with data.
      Statement stmt4 = con.createStatement();
      stmt4.executeUpdate(
	"INSERT INTO company_b VALUES " +
	"(default, 'Naughton', 38, 'Clerk', NULL, 12954.75, " +
	"'No Benefits', NULL), " +
        "(default, 'Yamaguchi', 42, 'Clerk', 5, 10505.00, " +
	"'Basic Health Coverage', NULL), " +
        "(default, 'Fraye', 51, 'Mgr', 8, 21150.00, " +
	"'Basic Health Coverage', NULL), " +
        "(default, 'Williams', 51, 'Sales', 10, 19456.50, " +
	"'Advanced Health Coverage', NULL), " +
        "(default, 'Molinare', 10, 'Mgr', 15, 22959.20, " +
	"'Advanced Health Coverage and Pension Plan', NULL)");
      stmt4.close();

      // Commit
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // Create

  /* The Buy_Company function encapsulates the table updates after Company 
     B takes over Company A.  Each employees from table company_a is 
     allocated a benefits package.  The employee data is moved into table 
     company_b.  Each employee's salary is increased by 5%.  The old and 
     new salaries are recorded in a table salary_change.
  */
  static void Buy_Company(Connection con)
  {
    try
    {
      int id;				// Employee's ID
      int department;			// Employee's department
      int years;     			// Number of years employee has 
      					// worked with the company
      int new_id = 0;   		// Employee's new ID when they 
      					// switch companies

      String name;			// Employee's name
      String job;			// Employee's job title
      String benefits = new String();	// Employee's benefits

      double salary;			// Employee's current salary
      double old_salary;		// Employee's old salary

      /* The following SELECT statement references a DELETE statement in its
         FROM clause.  It deletes all rows from company_a, selecting all 
	 deleted rows into the ResultSet rs.
      */
      Statement stmt = con.createStatement();
      ResultSet rs = 
        stmt.executeQuery("SELECT ID, NAME, DEPARTMENT, JOB, YEARS, SALARY " +
                          "FROM OLD TABLE (DELETE FROM company_a)");
      while(rs.next())
      {
        id = rs.getInt(1);
	name = rs.getString(2);
	department = rs.getInt(3);
	job = rs.getString(4);
	years = rs.getInt(5);
	salary = rs.getDouble(6);

        /* The following if statement sets the new employee's benefits based
	   on their years of experience.
        */
	if(years > 14)
	  benefits = "Advanced Health Coverage and Pension Plan";
	else if(years > 9)
	  benefits = "Advanced Health Coverage";
	else if(years > 4)
	  benefits = "Basic Health Coverage";
	else
          benefits = "No Benefits";

        /* The following SELECT statement references an INSERT statement in
	   its FROM clause.  It inserts an employee record from host 
	   variables into table company_b.  The current employee ID from the
	   ResultSet is selected into the host variable new_id.  The 
	   keywords FROM FINAL TABLE determine that the value in new_id is 
	   the value of ID after the INSERT statement is complete.

           Note that the ID column in table company_b is generated and 
	   without the SELECT statement an additional query would have to be
	   made in order to retrieve the employee's ID number.
        */
        PreparedStatement stmt1 = con.prepareStatement(
	"SELECT ID " + 
          "FROM FINAL TABLE (INSERT INTO company_b " +
	  "VALUES(default, :name, :dept, :job, :yrs, :sal, :benefits, :id))");
	
      ((com.ibm.db2.jcc.DB2PreparedStatement)stmt1).setJccStringAtName ("name", name);
      ((com.ibm.db2.jcc.DB2PreparedStatement)stmt1).setJccIntAtName("dept",department);
      ((com.ibm.db2.jcc.DB2PreparedStatement)stmt1).setJccStringAtName("job",job);
      ((com.ibm.db2.jcc.DB2PreparedStatement)stmt1).setJccIntAtName("yrs",years);
      ((com.ibm.db2.jcc.DB2PreparedStatement)stmt1).setJccDoubleAtName("sal",salary);
      ((com.ibm.db2.jcc.DB2PreparedStatement)stmt1).setJccStringAtName("benefits",benefits);
      ((com.ibm.db2.jcc.DB2PreparedStatement)stmt1).setJccIntAtName("id",id);



	ResultSet rs1 = stmt1.executeQuery();
	rs1.next();

	new_id = rs1.getInt(1);

	stmt1.close();
	rs1.close();

        /* The following SELECT statement references an UPDATE statement in
	   its FROM clause.  It updates an employee's salary by giving them 
	   a 5% raise.  The employee's id, old salary and current salary are
	   all read into host varibles via a ResultSet for later use in this
	   function.
       
           The INCLUDE statement works by creating a temporary column to 
	   keep track of the old salary.  This temporary column is only 
	   available for this statement and is gone once the statement 
	   completes.  The only way to keep this data after the statement
	   completes is to read it into a host variable.
        */
        PreparedStatement stmt2 = con.prepareStatement(
	"SELECT ID, OLD_SALARY, SALARY " + 
        "FROM FINAL TABLE (UPDATE company_b INCLUDE " +
	                  "(OLD_SALARY DECIMAL(7,2)) " +
                          "SET OLD_SALARY = SALARY, " +
                          "    SALARY = SALARY * 1.05 " + 
                          "WHERE ID = :nwID)");
    	((com.ibm.db2.jcc.DB2PreparedStatement)stmt2).setJccIntAtName("nwID", new_id);

	ResultSet rs2 = stmt2.executeQuery();
	rs2.next();

	id = rs2.getInt(1);
	old_salary = rs2.getDouble(2);
	salary = rs2.getDouble(3);
    
	stmt2.close();
	rs2.close();

        /* This INSERT statement inserts an employee's id, old salary and 
	   current salary into the salary_change table.
        */
	PreparedStatement stmt3 = con.prepareStatement(
	"INSERT INTO salary_change VALUES(:id, :old_sal, :sal)");

	((com.ibm.db2.jcc.DB2PreparedStatement)stmt3).setJccIntAtName("id", id);
	((com.ibm.db2.jcc.DB2PreparedStatement)stmt3).setJccDoubleAtName("old_sal", old_salary);
	((com.ibm.db2.jcc.DB2PreparedStatement)stmt3).setJccDoubleAtName("sal", salary);
	stmt3.execute();
	stmt3.close();
      }
      rs.close();
      stmt.close();

      /* The following DELETE statement references a SELECT statement in its 
         FROM clause.  It lays off the highest paid manager.  This DELETE 
	 statement removes the manager from the table company_b.
      */
      PreparedStatement stmt4 = con.prepareStatement(
        "DELETE FROM (SELECT * FROM company_b ORDER BY SALARY DESC FETCH " +
	"FIRST ROW ONLY)");
      stmt4.execute();
      stmt4.close();

      /* The following UPDATE statement references a SELECT statement in its 
         FROM clause.  It gives the most senior employee a $10000 bonus.  
	 This UPDATE statement raises the employee's salary in the table 
	 company_b.
      */
      PreparedStatement stmt5 = con.prepareStatement(
        "UPDATE (SELECT MAX(YEARS) OVER() AS max_years, " + 
                          "YEARS, " +
                          "SALARY" +
                  " FROM company_b) " +
                  " SET SALARY = SALARY + 10000 " +
                  " WHERE max_years = YEARS");
      stmt5.execute();
      stmt5.close();
      
      // Commit
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // Buy_Company

  /* The Print function outputs the data in the tables: company_a, 
     company_b and salary_change.  For each table, a while loop and 
     ResultSet are used to fetch and display row data.
  */
  static void Print(Connection con)
  {
    try
    {
      int id;				// Employee's ID
      int department;			// Employee's department
      int years;     			// Number of years employee has worked with 
      					// the company
      int new_id = 0;			// Employee's new ID when they switch 
      					// companies

      String name;			// Employee's name
      String job;			// Employee's job title
      String benefits = new String();	// Employee's benefits

      double salary;			// Employee's current salary
      double old_salary;		// Employee's old salary

      System.out.println("\nSELECT * FROM company_a\n");
      System.out.println(
        "ID     NAME      DEPARTMENT JOB   YEARS  SALARY\n" +
        "------ --------- ---------- ----- ------ ---------");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT * FROM company_a");

      while (rs.next())
      {
        id = rs.getInt(1);
        name = rs.getString(2);
        department = rs.getInt(3);
        job = rs.getString(4);
        years = rs.getInt(5);
	salary = rs.getDouble(6);

        System.out.println(
          Data.format(id, 6)  + " " +
          Data.format(name, 9) + " " +
          Data.format(department, 10)   + " " +
          Data.format(job, 5) + " " +
          Data.format(years, 6) + " " +
	  Data.format(String.valueOf(salary), 9));
      }
      rs.close();
      stmt.close();

      System.out.println();
      System.out.println("SELECT * FROM company_b\n");
      System.out.println(
        "ID     NAME      DEPARTMENT JOB   YEARS  SALARY    \nBENEFITS                                           OLD_ID\n" +
        "------ --------- ---------- ----- ------ --------- \n-------------------------------------------------- ------");

      Statement stmt1 = con.createStatement();
      ResultSet rs1 = stmt1.executeQuery("SELECT * FROM company_b");

      while (rs1.next())
      {
        new_id = rs1.getInt(1);
        name = rs1.getString(2);
        department = rs1.getInt(3);
        job = rs1.getString(4);
        years = rs1.getInt(5);
	salary = rs1.getDouble(6);
	benefits = rs1.getString(7);
	id = rs1.getInt(8);

        System.out.println(
          Data.format(new_id, 6)  + " " +
          Data.format(name, 9) + " " +
          Data.format(department, 10)   + " " +
          Data.format(job, 5) + " " +
          Data.format(years, 6) + " " +
	  Data.format(String.valueOf(salary), 9) + "\n" +
	  Data.format(benefits, 50) + " " +
	  Data.format(id, 6) + "\n");
      }
      rs1.close();
      stmt1.close();

      System.out.println("SELECT * FROM salary_change\n");
      System.out.println(
        "ID     OLD_SALARY SALARY\n" +
        "------ ---------- ---------");

      Statement stmt2 = con.createStatement();
      ResultSet rs2 = stmt2.executeQuery("SELECT * FROM salary_change");

      while (rs2.next())
      {
        id = rs2.getInt(1);
        old_salary = rs2.getDouble(2);
        salary = rs2.getDouble(3);
        
        System.out.println(
          Data.format(id, 6)  + " " +
          Data.format(String.valueOf(old_salary), 11) + " " +
          Data.format(String.valueOf(salary), 9));
      }
      rs2.close();
      stmt2.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // Print

  /* The Drop function drops the tables used by this sample. */
  static void Drop(Connection con)
  {
    try
    {
      System.out.println();
      System.out.println("DROP TABLE company_a\n");
      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE company_a");
      stmt.close();

      System.out.println("DROP TABLE company_b\n");
      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("DROP TABLE company_b");
      stmt1.close();

      System.out.println("DROP TABLE salary_change");
      Statement stmt2 = con.createStatement();
      stmt2.executeUpdate("DROP TABLE salary_change");
      stmt2.close();

      // Commit
      con.commit();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // Drop
} // TbSel

