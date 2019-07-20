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
//  SAMPLE FILE NAME: ScalarFunctions.java
//
//  PURPOSE   :To demonstrate how to use the following scalar functions and
//             the special register.
//                 1. INITCAP  
//                 2. LPAD
//                 3. RPAD
//                 4. TO_CLOB
//                 5. TO_DATE 
//                 6. TO_CHAR
//                 7. TO_NUMBER
//                 8. DAYNAME
//                 9. MONTHNAME
//                10. INSTR
//                11. LOCATE_IN_STRING
//                12. CURRENT LOCALE LC_TIME Register
//                13. TRUNC  
//                14. ROUND
//                15. TRUNC_TIMESTAMP
//                16. ROUND_TIMESTAMP
//                17. VARCHAR_FORMAT
//                18. ADD_MONTHS
//                19. LAST_DAY
//
//
//
//  PREREQUISITE: 
//
//
//  INPUTS:       NONE
//
//  OUTPUT:   
//
//  OUTPUT FILE: ScalarFunctions.out (available in online documentation)
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
//      http://www.ibm.com/software/data/db2/ad/
//
// *************************************************************************/
//  SAMPLE DESCRIPTION
//
// /*************************************************************************
//  1. Use of INITCAP Scalar Function. 
//  2. Use of INITCAP Scalar Function with accented characters.
//  3. Use of LPAD Scalar Function.
//  4. Use of RPAD Scalar Function.
//  5. Use of TO_CLOB Scalar Function.
//  6. Use of TRUNC and TRUNCATE Scalar Function with numeric value.
//  7. Use of TRUNC and TRUNCATE Scalar Function with datetime value.
//  8. Use of ROUND Scalar Function with numeirc value.
//  9. Use of ROUND Scalar Function with datetime value.
// 10. Use of TRUNC_TIMESTAMP Scalar Function with datetime value.
// 11. Use of ROUND_TIMESTAMP Scalar Function with datetime value.
// 12. Use of TO_DATE Scalar Function.
// 13. Use of TO_CHAR Scalar Function.
// 14. Use of DAYNAME Scalar Function.
// 15. Use of MONTHNAME Scalar Function.
// 16. Use of INSTR Scalar Function.
// 17. Use of LOCATE_IN_STRING Scalar Function.
// 18. Use of CURRENT LOCALE LC_TIME register with TO_CHAR Scalar Function.
// 19. Use of CURRENT LOCALE LC_TIME register with TO_DATE Scalar Function.
// 20. Use of LAST_DAY Scalar Function.
// 21. Use of ADD_MONTHS Scalar Function.
// 22. Use of TO_NUMBER Scalar Function.
/***************************************************************************/

import java.lang.*;
import java.sql.*;

class ScalarFunctions
{
  static Db db;
  public static void main(String argv[])
  {
    
    try
    {
      System.out.println();
      System.out.println(
      "This sample shows how to use the following scalar functions: " +
	    "\n\t INITCAP \n" +
	    "\t LPAD \n" +
	    "\t RPAD \n" +
	    "\t TO_CLOB \n" +
	    "\t TO_DATE \n" +
	    "\t TO_CHAR \n" +
	    "\t DAYNAME \n" +
	    "\t MONTHNAME \n" +
	    "\t INSTR \n" +
	    "\t LOCATE_IN_STRING \n" +
	    "\t TO_NUMBER \n" +
	    "\t CURRENT LOCALE LC_TIME Register \n" +
	    "\t TRUNC \n" +
	    "\t ROUND \n" +
	    "\t TRUNC_TIMESTAMP \n" +
	    "\t ROUND_TIMESTAMP \n" +
	    "\t VARCHAR_FORMAT \n" +
	    "\t ADD_MONTHS \n" +
	    "\t LAST_DAY \n");
      Connection con = null;
      
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
         System.out.println("Error while Connecting to sample database.");
         System.err.println(e) ;
         System.exit(1);
      }

      // Functions calls to demonstrate each of the scalar functions
 
      // To Create Table
      
      CreateTable(con);

      /*****************************************************************/
      /* INITCAP                                                       */
      /*****************************************************************/

      InitialCaps(con);
      
      /*****************************************************************/
      /* LPAD AND RPAD                                                 */ 
      /*****************************************************************/

      Padding(con);
      
      /*****************************************************************/
      /* TO_CLOB                                                        */
      /*****************************************************************/

      ToClob(con);
      
      /*****************************************************************/
      /* TO_DATE                                                       */
      /*****************************************************************/

      ToDate(con);
      
      /*****************************************************************/
      /* TO_CHAR                                                       */
      /*****************************************************************/

      ToChar(con);
      
      /*****************************************************************/
      /* TO_NUMBER                                                     */
      /*****************************************************************/

      ToNumber(con);

      /*****************************************************************/
      /* Round                                                         */
      /*****************************************************************/

      UseRound(con);

      /*****************************************************************/
      /* Truncate                                                      */
      /*****************************************************************/

      UseTruncate(con);
      
      // Drop Table
      
      DropTable(con);

      // Disconnect from database.

   }
   catch (Exception e)
   {
      System.out.println("Error Msg: "+ e.getMessage());
   }
 }// Main

 
 //Create table temp_table
 

 static void CreateTable(Connection con)
 {
   try
   {
      String st="CREATE TABLE temp_table(rowno INTEGER,"+
                    "tempdata VARCHAR(30),format VARCHAR(15))";

      System.out.println("\nCREATE TABLE temp_table ("+
                                         "rowno INTEGER, "+
 	                                 "tempdata VARCHAR(30), "+
			                 "format VARCHAR(15))\n \n");

      Statement stmt = con.createStatement();
      stmt.executeUpdate(st);
    }
    catch(Exception e)
    {
       System.out.print("Unable to Create Table....."+e);
    }
 }//CreateTable
	
 // InitCaps
 
 static void InitialCaps(Connection con)
 {
    try
    {
       String name;			// Employee's name

       System.out.println("\nSELECT INITCAP "+
                         "(Firstnme) FROM Employee");
       System.out.println("\n------------------------------------\n");

       //Convert first character of each word to uppercase
       Statement stmt = con.createStatement();
       ResultSet rs = stmt.executeQuery("SELECT INITCAP (Firstnme) "+
                                                   "FROM Employee");
       while (rs.next())
       {
          name = rs.getString(1);
          System.out.println(name);
       }
       rs.close();
       stmt.close();

       System.out.println("\nVALUES INITCAP "+
                         "('THEODORE Q SPENSER is manager')");
       System.out.println("\n------------------------------------\n");

       Statement stmt1 = con.createStatement();
       ResultSet rs1 = stmt1.executeQuery("VALUES INITCAP "+
                         "('THEODORE Q SPENSER is manager')");

       while (rs1.next())
       {
          name = rs1.getString(1);
          System.out.println(name);
       }
       
       // INITCAP handles accented characters
       System.out.println("\nVALUES INITCAP "+
                          "('my name is élizãbeth ñatz')");
       System.out.println("\n------------------------------------\n");

       rs1 = stmt1.executeQuery("VALUES INITCAP "+
                          "('my name is élizãbeth ñatz')");
       while (rs1.next())
       {
          name = rs1.getString(1);
          System.out.println(name);
       }

       rs1.close();
       stmt1.close();

       // Commit
       con.commit();
    }
    catch (SQLException sqle)
    {
       System.out.println("Error Msg: "+ sqle.getMessage());
       System.out.println("SQLState: "+sqle.getSQLState());
       System.out.println("SQLError: "+sqle.getErrorCode());
    }
 } // InitialCaps


//Make a string certain length by adding (padding) a specified characters  

static void Padding(Connection con)
{
   try
   {
      String name;			// Employee's name

      System.out.println("\nSELECT LPAD(Lastname, 10,'*') "+
		                              "AS LastName  FROM Employee");
      System.out.println("\n------------------------------------\n");

      // Make a string certain length by adding (padding) a specified 
      // characters to the left

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT LPAD(Lastname, 10,'*') "+
                             "AS LastName  FROM Employee");

      while (rs.next())
      {
         name = rs.getString(1);
         System.out.println(name);
      }
      rs.close();
      stmt.close();

      System.out.println("\nSELECT RPAD(Firstnme, 20, '.') FROM Employee");
      System.out.println("\n-----------------------------\n");

      // Make a string certain length by adding (padding) a specified 
      // characters to the right

      Statement stmt1 = con.createStatement();
      ResultSet rs1 = stmt1.executeQuery("SELECT RPAD(Firstnme, 20, '.')"+
                          " FROM Employee");

      while (rs1.next())
      {
         name = rs1.getString(1);
         System.out.println(name);
      }
      rs1.close();
      stmt1.close();
   }
   catch (SQLException sqle)
   {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try 
      { 
         con.rollback();
      }
      catch (SQLException sql)
      {
         System.out.println("Error Msg: "+ sql.getMessage());
         System.out.println("SQLState: "+sql.getSQLState());
         System.out.println("SQLError: "+sql.getErrorCode());
      }
      System.exit(1);
   }
} // Padding

//Represent a character string as CLOB type

static void ToClob(Connection con)
{
   try
   {
      Clob job;                      // Employee's Job

      System.out.println("\nSELECT TO_CLOB(Job) FROM Employee");
      System.out.println("\n----------------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT TO_CLOB(Job) FROM Employee");

      while (rs.next())
      {
         job = rs.getClob(1);
         long jobLength = job.length();
         String jobString = job.getSubString(1, (int)jobLength);
         System.out.println(jobString);
      }

      /*****************************************************************/
      /* LOCATE_IN_STRING and INSTR                                    */
      /* Returns the starting position of the first occurrence of      */
      /* search string within another source string.                   */
      /*****************************************************************/

      // Locate character "ß" in the given string starting from position 1	
      System.out.println("\nVALUES LOCATE_IN_STRING('Jürgen lives "+
                         "on Hegelstraße','ß',1,CODEUNITS32)");
      System.out.println("\n----------------------------------------------\n");
      rs=stmt.executeQuery("VALUES LOCATE_IN_STRING('Jürgen lives "+
                           "on Hegelstraße','ß',1,CODEUNITS32)");

      while (rs.next())
      {
         int loc=rs.getInt(1);
         System.out.println(loc);
      }

     // Locate string "position" in the given string.

     System.out.println("\nVALUES LOCATE_IN_STRING('The INSTR function "+
                        "returns the starting position of the first "+
                        "occurrence of one string within another string',"+
                        "'position',1, OCTETS)");
     System.out.println("\n----------------------------------------------\n");

     rs=stmt.executeQuery("VALUES LOCATE_IN_STRING('The INSTR "+
                          "function returns the starting "+
                          "position of the first occurrence "+
                          "of one string within another string',"+
                          "'position',1, OCTETS)");

     while(rs.next())
     {
        int loc1=rs.getInt(1);
        System.out.println(loc1);
     }

     // Locate the fourth occurrence of character "f" in the given string
     System.out.println("\nVALUES INSTR('The INSTR function returns "+
                   "the starting position of the first occurrence "+
                   "of one string within another string', "+
                   "'f',1, 4, OCTETS)");
     System.out.println("\n----------------------------------------------\n");


     rs=stmt.executeQuery("VALUES INSTR('The INSTR function returns "+
                     "the starting position of the first occurrence "+
                     "of one string within another string', "+
                     "'f',1, 4, OCTETS)");
     while(rs.next())
     {
        int instr1=rs.getInt(1);
        System.out.println(instr1);
     }


     // Locate the second occurrence of "string" by searching from the 
     // end of the given string

     System.out.println("\nVALUES INSTR('The INSTR function returns the "+
                        "starting position of the first occurrence of one "+
                        "string within another string', "+
                        "'string', -1, 2, OCTETS)");
     System.out.println("\n----------------------------------------------\n");

     rs=stmt.executeQuery("VALUES INSTR('The INSTR function returns the "+
                          "starting position of the first occurrence of one "+
                          "string within another string', "+
                          "'string', -1, 2, OCTETS)");

     while(rs.next())
     {
        int instr2=rs.getInt(1);
        System.out.println(instr2);
     }


      rs.close();
      stmt.close();
   }
   catch (SQLException sqle)
   {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try 
      { 
         con.rollback();
      }
      catch (SQLException sql)
      {
         System.out.println("Error Msg: "+ sql.getMessage());
         System.out.println("SQLState: "+sql.getSQLState());
         System.out.println("SQLError: "+sql.getErrorCode());
         System.exit(1);
      }
   }
} // ToClob

//Represent character string as a timestamp 

static void ToDate(Connection con)
{
   try
   {
      Date tdate;                      

      // Demonstrate different format elements of TO_DATE function
	
      Statement stmt0 = con.createStatement();
      // Insert data into temp_table

      stmt0.executeUpdate("INSERT INTO temp_table VALUES "+
                 "(1,'1999-12-31 23:59:59', NULL)");

      System.out.println("\nINSERT INTO temp_table VALUES "+
                 "(1,'1999-12-31 23:59:59', NULL)\n");

      System.out.println("\nSELECT TO_DATE(tempdata, 'YYYY-MM-DD HH24:MI:SS') "+
                 "FROM temp_table");
      System.out.println("\n------------------------------------\n");      

      ResultSet rs0 = stmt0.executeQuery("SELECT "+
                 "TO_DATE(tempdata, 'YYYY-MM-DD HH24:MI:SS') FROM temp_table");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }
      rs0.close();
      stmt0.close();

      System.out.println("\nINSERT INTO temp_table VALUES "+
                              "(2,'1999-12-31', 'YYYY-MM-DD')\n");

      Statement stmt = con.createStatement();
      stmt.executeUpdate("INSERT INTO temp_table VALUES (2,'1999-12-31',"+
                                      "'YYYY-MM-DD')");

      System.out.println("\nSELECT TO_DATE(tempdata, format) "+
	                              "FROM temp_table WHERE rowno = 2");
      System.out.println("\n------------------------------------\n");

      ResultSet rs = stmt.executeQuery("SELECT TO_DATE(tempdata, format) "+
	                              "FROM temp_table WHERE rowno = 2");

      while (rs.next())
      {
         tdate = rs.getDate(1);
         System.out.println(tdate);
      }
      rs.close();
      stmt.close();

      System.out.println("\nINSERT INTO temp_table VALUES (3,'1999-DEC-31',"+
                                                "NULL)");

      Statement stmt1 = con.createStatement();
      stmt1.executeUpdate("INSERT INTO temp_table VALUES (3,'1999-DEC-31',"+
                                                 "NULL)");
      System.out.println("\nSELECT TO_DATE(tempdata, "+
          "'YYYY-MON-DD','CLDR 1.5:en_US' ) FROM temp_table WHERE rowno = 3");
      System.out.println("\n------------------------------------\n");

      ResultSet rs1 = stmt1.executeQuery("SELECT TO_DATE(tempdata, "+
          "'YYYY-MON-DD','CLDR 1.5:en_US' ) FROM temp_table WHERE rowno = 3");

      while (rs1.next())
      {
         tdate = rs1.getDate(1);
         System.out.println(tdate);
      }
      rs1.close();
      stmt1.close();
   }
   catch (SQLException sqle)
   {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try 
      { 
         con.rollback(); 
      }
      catch (SQLException sql)
      {
        System.out.println("Error Msg: "+ sql.getMessage());
        System.out.println("SQLState: "+sql.getSQLState());
        System.out.println("SQLError: "+sql.getErrorCode());
      }
      System.exit(1);
   }
 } // ToDate

//Represent timestamp as a character string type

static void ToChar(Connection con)
{
   try
   {
      String ttime;

      // Show tablename and its creation time as a String where tablename
      // starts with 'empl'

      System.out.println("\n\nSELECT VARCHAR(TABNAME, 20) AS Table_Name, "+
         "TO_CHAR(CREATE_TIME, 'YYYY-MM-DD HH24:MI:SS') AS Creation_Time "+
         "FROM SYSCAT.TABLES WHERE TABNAME LIKE 'EMPL%'\n");
      System.out.println("\n------------------------------------\n");

      Statement stmt0 = con.createStatement();
      ResultSet rs0 = stmt0.executeQuery("SELECT VARCHAR(TABNAME, 20) AS "+
          "Table_Name, TO_CHAR(CREATE_TIME, 'YYYY-MM-DD HH24:MI:SS') AS "+
          "Creation_Time FROM SYSCAT.TABLES WHERE TABNAME LIKE 'EMPL%'");

      System.out.println("TableName \t" + "CreationTime");      

      while (rs0.next())
      {
         String tabname = rs0.getString(1); 
         ttime = rs0.getString(2);
         System.out.println(tabname + "\t" + ttime);
      }
      rs0.close();
      stmt0.close();

      // Demonstrate different format elements of a DATE and a TIMESTAMP
      // values with TO_CHAR function
    
      System.out.println("\nSELECT TO_CHAR( received ) FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt2 = con.createStatement();
      ResultSet rs2 = stmt2.executeQuery("SELECT TO_CHAR( received ) "+
                   "FROM in_tray");

      while (rs2.next())
      {
         ttime = rs2.getString(1);
         System.out.println(ttime);
      }
      rs2.close();
      stmt2.close();
 
      System.out.println("\nSELECT TO_CHAR( received,'FF9' ) "+
                     "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt3 = con.createStatement();
      ResultSet rs3 = stmt3.executeQuery("SELECT "+
                     "TO_CHAR( received,'FF9' ) "+
                     "FROM in_tray");

      while (rs3.next())
      {
         ttime = rs3.getString(1);
         System.out.println(ttime);
      }
      rs3.close();
      stmt3.close();

      System.out.println("\nSELECT TO_CHAR( received,'FF12' ) "+
                      "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt4 = con.createStatement();
      ResultSet rs4 = stmt4.executeQuery("SELECT "+
                     "TO_CHAR( received,'FF12' ) "+
                     "FROM in_tray");

      while (rs4.next())
      {
         ttime = rs4.getString(1);
         System.out.println(ttime);
      }
      rs4.close();
      stmt4.close();

      System.out.println("\nSELECT TO_CHAR( received,'MON', 'de_DE') "+
                      "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt5 = con.createStatement();
      ResultSet rs5 = stmt5.executeQuery("SELECT "+
                      "TO_CHAR( received,'MON', 'de_DE') "+
                      "FROM in_tray");

      while (rs5.next())
      {
         ttime = rs5.getString(1);
         System.out.println(ttime);
      }
      rs5.close();
      stmt5.close();	
     
      
      System.out.println("\nSELECT TO_CHAR( received,'DD-YYYY-Month-Day' ) "+
                     "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt6 = con.createStatement();
      ResultSet rs6 = stmt6.executeQuery("SELECT "+
                     "TO_CHAR( received,'DD-YYYY-Month-Day' ) "+
                     "FROM in_tray");

      while (rs6.next())
      {
         ttime = rs6.getString(1);
         System.out.println(ttime);
      }
      rs6.close();
      stmt6.close();
		
      System.out.println("\nSELECT TO_CHAR( received,'DD-YYYY-MONTH-Day' ) "+
                      "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt7 = con.createStatement();
      ResultSet rs7 = stmt7.executeQuery("SELECT "+
                     "TO_CHAR( received,'DD-YYYY-MONTH-Day' ) "+
                     "FROM in_tray");

      while (rs7.next())
      {
         ttime = rs7.getString(1);
         System.out.println(ttime);
      }
      rs7.close();
      stmt7.close();

      System.out.println("\nSELECT TO_CHAR( received,'DD-YYYY-MONTH-DAY' ) "+
                      "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt8 = con.createStatement();
      ResultSet rs8 = stmt8.executeQuery("SELECT "+
                      "TO_CHAR( received,'DD-YYYY-MONTH-DAY' ) "+
                      "FROM in_tray");

      while (rs8.next())
      {
         ttime = rs8.getString(1);
         System.out.println(ttime);
      }
      rs8.close();
      stmt8.close();	

      System.out.println("\nSELECT TO_CHAR( received,'YYYY-MONTH-DD' ) "+
                        "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt9 = con.createStatement();
      ResultSet rs9 = stmt9.executeQuery("SELECT "+
                         "TO_CHAR( received,'YYYY-MONTH-DD' ) "+
                         "FROM in_tray");

      while (rs9.next())
      {
         ttime = rs9.getString(1);
         System.out.println(ttime);
      }
      rs9.close();
      stmt9.close();

      System.out.println("\nSELECT "+
                  "TO_CHAR( received,'YYYY-Month-DAY-DD' ) FROM in_tray");
      System.out.println("\n-----------------------------------------\n");


      Statement stmt00 = con.createStatement();
      rs0 = stmt00.executeQuery("SELECT "+
                  "TO_CHAR( received,'YYYY-Month-DAY-DD' ) "+
		  "FROM in_tray");

      while (rs0.next())
      {
         ttime = rs0.getString(1);
         System.out.println(ttime);
      }
      rs0.close();
      stmt00.close();

      System.out.println("\nSELECT "+
                 "TO_CHAR( received,'DD-YYYY-mon-dy HH-MM-SS' ) FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt18 = con.createStatement();
      ResultSet rs18 = stmt18.executeQuery("SELECT "+
                  "TO_CHAR( received,'DD-YYYY-mon-dy HH-MM-SS' ) "+
                  "FROM in_tray");

      while (rs18.next())
      {
         ttime = rs18.getString(1);
         System.out.println(ttime);
      }
      rs18.close();
      stmt18.close();

      System.out.println("\nSELECT "+
          "TO_CHAR( received,'Dy-YYYY-MON-DD HH12-MM-SS' ) FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt19 = con.createStatement();
      ResultSet rs19 = stmt19.executeQuery("SELECT "+
           "TO_CHAR( received,'Dy-YYYY-MON-DD HH12-MM-SS' ) FROM in_tray");

      while (rs19.next())
      {
         ttime = rs19.getString(1);
         System.out.println(ttime);
      }
      rs19.close();
      stmt19.close();

      System.out.println("\nSELECT "+
             "TO_CHAR( received,'D-YYYY-Mon-DAY-DD HH12-MI-SS' ) FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt20 = con.createStatement();
      ResultSet rs20 = stmt20.executeQuery("SELECT "+
             "TO_CHAR( received,'D-YYYY-Mon-DAY-DD HH12-MI-SS' ) FROM in_tray");

      while (rs20.next())
      {
         ttime = rs20.getString(1);
         System.out.println(ttime);
      } 
      rs20.close();
      stmt20.close();
	
      System.out.println("\nSELECT "+
             "TO_CHAR( received,'DAY-YYYY-Month-DD HH12-MM-SS' ) FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt10 = con.createStatement();
      ResultSet rs10 = stmt10.executeQuery("SELECT "+
             "TO_CHAR( received,'DAY-YYYY-Month-DD HH12-MM-SS' ) FROM in_tray");

       while (rs10.next())
       {
          ttime = rs10.getString(1);
          System.out.println(ttime);
       }
       rs10.close();
       stmt10.close();
	
       System.out.println("\nSELECT "+
             "TO_CHAR( received,'Day-YYYY-Month-DD HH24-MM-SS' ) FROM in_tray");
       System.out.println("\n-----------------------------------------\n");

       Statement stmt11 = con.createStatement();
       ResultSet rs11 = stmt11.executeQuery("SELECT "+
             "TO_CHAR( received,'Day-YYYY-Month-DD HH24-MM-SS' ) FROM in_tray");

       while (rs11.next())
       {
          ttime = rs11.getString(1);
          System.out.println(ttime);
       }
       rs11.close();
       stmt11.close();		

       System.out.println("\nSELECT "+
         "TO_CHAR( received,'DAY-YYYY-Month-DD HH12-MM-SS PM' ) FROM in_tray");
       System.out.println("\n-----------------------------------------\n");

       Statement stmt12 = con.createStatement();
       ResultSet rs12 = stmt12.executeQuery("SELECT "+
        "TO_CHAR( received,'DAY-YYYY-Month-DD HH12-MM-SS PM' ) FROM in_tray");

       while (rs12.next())
       {
          ttime = rs12.getString(1);
          System.out.println(ttime);
       }
       rs12.close();
       stmt12.close();

       System.out.println("\nSELECT "+
                "TO_CHAR( received,'DD-YYYY-MONTH-DAY HH24-MM-SS P.M.' ) "+
                "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt13 = con.createStatement();
      ResultSet rs13 = stmt13.executeQuery("SELECT "+
                "TO_CHAR( received,'DD-YYYY-MONTH-DAY HH24-MM-SS P.M.' ) "+
                "FROM in_tray");

      while (rs13.next())
      {
         ttime = rs13.getString(1);
         System.out.println(ttime);
      }
      rs13.close();
      stmt13.close();

      System.out.println("\nSELECT "+
                "TO_CHAR( received,'DAY-YYYY-MONTH-DD HH12-MM-SS AM' ) "+
                "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt14 = con.createStatement();
      ResultSet rs14 = stmt14.executeQuery("SELECT "+
                "TO_CHAR( received,'DAY-YYYY-MONTH-DD HH12-MM-SS AM' ) "+
                "FROM in_tray");

      while (rs14.next())
      {
         ttime = rs14.getString(1);
         System.out.println(ttime);
      }
      rs14.close();
      stmt14.close();

      System.out.println("\nSELECT "+
                "TO_CHAR( received,'DD-YYYY-Month-day HH12-MM-SS A.M.' ) "+
                "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt15 = con.createStatement();
      ResultSet rs15 = stmt15.executeQuery("SELECT "+
                "TO_CHAR( received,'DD-YYYY-Month-day HH12-MM-SS A.M.' ) "+
                "FROM in_tray");

      while (rs15.next())
      {
         ttime = rs15.getString(1);
         System.out.println(ttime);
      }
      rs15.close();
      stmt15.close();

      System.out.println("\nSELECT "+
                "TO_CHAR( received,'DD-YYYY/MON/DAY', 'en_US' ) "+
                "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt16 = con.createStatement();
      ResultSet rs16 = stmt16.executeQuery("SELECT "+
                "TO_CHAR( received,'DD-YYYY/MON/DAY', 'en_US' ) "+
                "FROM in_tray");

      while (rs16.next())
      {
         ttime = rs16.getString(1);
         System.out.println(ttime);
      }
      rs16.close();
          
      System.out.println("\nVALUES  "+
                "VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'MON','de_DE')");
      System.out.println("\n-----------------------------------------\n");

      rs16 = stmt16.executeQuery("VALUES  "+
                "VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'MON','de_DE')");

      while (rs16.next())
      {
         ttime = rs16.getString(1);
         System.out.println(ttime);
      }
      rs16.close();
      
      System.out.println("\nVALUES "+
                "VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'MON','zh_CN')");
      System.out.println("\n-----------------------------------------\n");

      rs16 = stmt16.executeQuery("VALUES "+
                "VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'MON','zh_CN')");

      while (rs16.next())
      {
         ttime = rs16.getString(1);
         System.out.println(ttime);
      }
      rs16.close();
      
      System.out.println("\nVALUES "+
                "VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'DAY','de_DE')");
      System.out.println("\n-----------------------------------------\n");

      rs16 = stmt16.executeQuery("VALUES "+
                "VARCHAR_FORMAT('1988-12-22-14.07.21.136421', 'DAY','de_DE')");

      while (rs16.next())
      {
         ttime = rs16.getString(1);
         System.out.println(ttime);
      }
      rs16.close();
      stmt16.close();

      
      // Get the month from the TIMESTAMP
      System.out.println("\nSELECT TO_CHAR( received,'MONTH') "+
                "FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt1 = con.createStatement();
      ResultSet rs1 = stmt1.executeQuery("SELECT "+
		"TO_CHAR( received,'MONTH') from in_tray");

      while (rs1.next())
      {
         ttime = rs1.getString(1);
         System.out.println(ttime);
      }
      rs1.close();
      stmt1.close();

      // Get the day from the TIMESTAMP
      System.out.println("\nSELECT TO_CHAR( received,'Dy') FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      Statement stmt17 = con.createStatement();
      ResultSet rs17 = stmt17.executeQuery("SELECT "+
                         "TO_CHAR( received,'Dy') FROM in_tray");

      while (rs17.next())
      {
         ttime = rs17.getString(1);
         System.out.println(ttime);
      }


      /*****************************************************************/
      /* DAYNAME                                                       */
      /*****************************************************************/
      String day;

      // Present dayname in the French locale

      System.out.println("\nSELECT DAYNAME(received, 'CLDR 1.5:fr_FR')"+
                         " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT DAYNAME(received, 'CLDR 1.5:fr_FR')"+
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }

      // Present dayname in the Chinese locale
      System.out.println("\nSELECT DAYNAME(received, 'CLDR 1.5:zh_CN')"+
                         " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT DAYNAME(received, 'CLDR 1.5:zh_CN')"+
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }


      // Present dayname in the Japanese locale
      System.out.println("\nSELECT DAYNAME(received, 'CLDR 1.5:ja_JP')"+
                         " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT DAYNAME(received, 'CLDR 1.5:ja_JP')" +
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }


      // Present dayname in the German locale
      System.out.println("\nSELECT DAYNAME(received, 'CLDR 1.5:de_DE')"+
                         " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT DAYNAME(received, 'CLDR 1.5:de_DE')"+
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }



      /*****************************************************************/
      /* MONTHNAME                                                     */
      /*****************************************************************/

      // Present Monthname in the Spanish locale
      System.out.println("\nSELECT MONTHNAME(received, 'CLDR 1.5:es_ES')"+
                        " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT MONTHNAME(received, 'CLDR 1.5:es_ES')"+
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }


      // Present Monthname in the Italian locale
      System.out.println("\nSELECT MONTHNAME(received, 'CLDR 1.5:it_IT')"+
                         " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT MONTHNAME(received, 'CLDR 1.5:it_IT')"+
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }


      // Present Monthname in the Japanese locale
      System.out.println("\nSELECT MONTHNAME(received, 'CLDR 1.5:ja_JP')"+
                         " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT MONTHNAME(received, 'CLDR 1.5:ja_JP')"+
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }


      // Present Monthname in the German locale
      System.out.println("\nSELECT MONTHNAME(received, 'CLDR 1.5:de_DE')"+
                         " FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      rs17=stmt17.executeQuery("SELECT MONTHNAME(received, 'CLDR 1.5:de_DE')"+
                               " FROM in_tray");
      while(rs17.next())
      {
         day=rs17.getString(1);
         System.out.println(day);
      }

      rs17.close();
      stmt17.close();

      /*****************************************************************/
      /* CURRENT LOCALE LC_TIME                                        */
      /* Use of CURRENT LOCALE LC_TIME with TO_CHAR Scalar Function.   */
      /*****************************************************************/

      // Use of the special register CURRENT LOCALE LC_TIME 

      // Present a TIMESTAMP value in the French locale

      Statement stm=con.createStatement();
      stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR'");

      System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR'\n");
      System.out.println("SELECT TO_CHAR(received) FROM in_tray");
      System.out.println("\n-----------------------------------------\n");

      ResultSet rst=stm.executeQuery("SELECT TO_CHAR(received) FROM in_tray");

      while (rst.next())
      {
        ttime = rst.getString(1);
        System.out.println(ttime);
      }

      // Present a TIMESTAMP value in the Japanese locale

      stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:ja_JP'");

      System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:ja_JP'\n");
      System.out.println("SELECT TO_CHAR(received) FROM in_tray\n");
      System.out.println("\n-----------------------------------------\n");

      rst=stm.executeQuery("SELECT TO_CHAR(received) FROM in_tray");
      while (rst.next())
      {
         ttime = rst.getString(1);
         System.out.println(ttime);
      }

      // Present a TIMESTAMP value in the Chinese locale

     stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:zh_CN'");

     System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:zh_CN'\n");
     System.out.println("SELECT TO_CHAR(received) FROM in_tray");
     System.out.println("\n-----------------------------------------\n");

     rst=stm.executeQuery("SELECT TO_CHAR(received) FROM in_tray");

     while (rst.next())
     {
        ttime = rst.getString(1);
        System.out.println(ttime);
     }
    
     /*****************************************************************/
     /* CURRENT LOCALE LC_TIME                                        */
     /* Use of CURRENT LOCALE LC_TIME with TO_DATE Scalar Function.   */
     /*****************************************************************/
     // Present a DATE value in the French locale

     System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR'");

     stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR'");
    
     // Insert into temp_table 
     stm.executeUpdate("INSERT INTO temp_table VALUES "+
                            "(5,'1999-DÉC.-31', 'YYYY-MON-DD')");
      
     System.out.println("\nINSERT INTO temp_table VALUES "+
                            "(5,'1999-DÉC.-31', 'YYYY-MON-DD')");
     System.out.println("\nSELECT TO_DATE(tempdata, format)FROM "+
                            "temp_table WHERE rowno = 5");
     System.out.println("\n----------------------------------------\n");

     rst=stm.executeQuery("SELECT TO_DATE(tempdata, format)FROM "+
                            "temp_table WHERE rowno = 5");

     while (rst.next())
     {
         ttime = rst.getString(1);
         System.out.println(ttime);
     }



     // Present a DATE value in the English locale
	 
     stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:en_US'");

     // Insert into temp_table 
     stm.executeUpdate("INSERT INTO temp_table VALUES "+
                           "(4,'1999-DEC-31', 'YYYY-MON-DD')");

     System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:en_US'");
     System.out.println("\nINSERT INTO temp_table VALUES "+
                           "(4,'1999-DEC-31', 'YYYY-MON-DD')");
     System.out.println("\nSELECT TO_DATE(tempdata, format)FROM "+
                           "temp_table WHERE rowno = 4");
     System.out.println("\n-----------------------------------------\n");

     rst=stm.executeQuery("SELECT TO_DATE(tempdata, format)FROM "+
                           "temp_table WHERE rowno = 4");
     while (rst.next())
     {
        ttime = rst.getString(1);
        System.out.println(ttime);
     }
	
     /*****************************************************************/
     /* CURRENT LOCALE LC_TIME                                        */
     /* Use of CURRENT LOCALE LC_TIME with DAYNAME Scalar Function    */
     /* MONTHNAME Scalar Function.                                    */
     /*****************************************************************/

     // Present a Dayname in the French locale
     String dayname;
     // SET CURRENT LOCALE 
     System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR'\n");
     stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:fr_FR'");
     System.out.println("\nSELECT DAYNAME(received) FROM in_tray");
     System.out.println("\n-----------------------------------------\n");
     rst=stm.executeQuery("SELECT DAYNAME(received) FROM in_tray");
     while (rst.next())
     {
        dayname = rst.getString(1);
        System.out.println(dayname);
     }


     // Present Dayname in the Italian locale

     // SET CURRENT LOCALE 
     System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:it_IT'\n");
     stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:it_IT'");
     System.out.println("\nSELECT DAYNAME(received) FROM in_tray");
     System.out.println("\n-----------------------------------------\n");
     rst=stm.executeQuery("SELECT DAYNAME(received) FROM in_tray");
     while (rst.next())
     {
        dayname = rst.getString(1);
        System.out.println(dayname);
     }

     // Returns a character string containing the name of the MONTH for the
     // month portion of expression based on the value of LOCALE LC_TIME

     // Present Monthname in the Spanish locale

     // SET CURRENT LOCALE 
     System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:es_ES'\n");
     stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:es_ES'");
     System.out.println("\nSELECT MONTHNAME(received) FROM in_tray");
     System.out.println("\n-----------------------------------------\n");
     rst=stm.executeQuery("SELECT MONTHNAME(received) FROM in_tray");
     while (rst.next())
     {
        dayname = rst.getString(1);
        System.out.println(dayname);
     }

     // Present Monthname in the German locale

     // SET CURRENT LOCALE 
     System.out.println("\nSET CURRENT LOCALE LC_TIME = 'CLDR 1.5:de_DE'\n");
     stm.executeUpdate("SET CURRENT LOCALE LC_TIME = 'CLDR 1.5:de_DE'");
     System.out.println("\nSELECT MONTHNAME(received) FROM in_tray");
     System.out.println("\n-----------------------------------------\n");
     rst=stm.executeQuery("SELECT MONTHNAME(received) FROM in_tray");
     while (rst.next())
     {
        dayname = rst.getString(1);
        System.out.println(dayname);
     }

     /*****************************************************************/
     /*  LAST_DAY                                                     */
     /*****************************************************************/
 
     // Present last day of the month indicated by expression 
     System.out.println("\n VALUES CURRENT DATE\n");
     System.out.println("\n-----------------------------------------\n");
 
     Date tempdate;     
     
     rst=stm.executeQuery("VALUES CURRENT DATE");
     while (rst.next())
     {
        tempdate = rst.getDate(1);
        System.out.println(tempdate);
     }

     System.out.println("\n VALUES LAST_DAY(CURRENT DATE)\n");
     System.out.println("\n-----------------------------------------\n");
      
     rst=stm.executeQuery("VALUES LAST_DAY(CURRENT DATE)");
     while (rst.next())
     {
        tempdate = rst.getDate(1);
        System.out.println(tempdate);
     }

     System.out.println("\n SELECT LAST_DAY(DATE(received)) AS lastday FROM in_tray\n");
     System.out.println("\n-----------------------------------------\n");
      
     rst=stm.executeQuery("SELECT LAST_DAY(DATE(received)) AS lastday FROM in_tray");
     while (rst.next())
     {
        tempdate = rst.getDate(1);
        System.out.println(tempdate);
     }


     /*****************************************************************/
     /*  ADD_MONTHS                                                   */
     /*****************************************************************/

     // Add number of months in given expression

     // Add 6 months in CURRENT DATE
     // Present last day of the month indicated by expression 
     System.out.println("\n VALUES CURRENT DATE\n");
     System.out.println("\n-----------------------------------------\n");   
     
     rst=stm.executeQuery("VALUES CURRENT DATE");
     while (rst.next())
     {
        tempdate = rst.getDate(1);
        System.out.println(tempdate);
     }

     System.out.println("\n VALUES ADD_MONTHS(CURRENT DATE, 6)\n");
     System.out.println("\n-----------------------------------------\n");
      
     rst=stm.executeQuery("VALUES ADD_MONTHS(CURRENT DATE, 6)");
     while (rst.next())
     {
        tempdate = rst.getDate(1);
        System.out.println(tempdate);
     }

     // Add 5 months
     System.out.println("\n SELECT ADD_MONTHS(received, 5) AS new_received FROM in_tray\n");
     System.out.println("\n-----------------------------------------\n");
      
     rst=stm.executeQuery("SELECT ADD_MONTHS(received, 5) AS new_received FROM in_tray");
     while (rst.next())
     {
        tempdate = rst.getDate(1);
        System.out.println(tempdate);
     }

     stm.close();
     rst.close();
            
   }
   catch (SQLException sqle)
   {
      System.out.println("Error Msg: "+ sqle.getMessage());
      System.out.println("SQLState: "+sqle.getSQLState());
      System.out.println("SQLError: "+sqle.getErrorCode());
      System.out.println("Rollback the transaction and quit the program");
      System.out.println();
      try 
      { 
         con.rollback(); 
      }
      catch (Exception e)
      {
         System.out.println("Error"+e);
      }
      System.exit(1);
   }
} // ToChar

// Show string value in DECFLOAT type format.

static void ToNumber(Connection con)
{
   try
   {
      float tnumber;                      
      
      // Each 9 in the format element represents a digit.

      System.out.println("\nSELECT TO_NUMBER(EmpNo, '999999') "+
                  "AS EmpNo FROM Employee\n");
      System.out.println("\n----------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT TO_NUMBER(EmpNo, '999999') "+
                   "AS EmpNo FROM Employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      System.out.println("\nSELECT TO_NUMBER(EmpNo, '000000') AS "+
                   "EmpNo FROM employee\n");
      System.out.println("\n-----------------------------------------\n");

      rs = stmt.executeQuery("SELECT TO_NUMBER(EmpNo, '000000') AS "+
                   "EmpNo FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      // TRUNCATE all data from table temp_table 
	  
      con.commit();
      stmt.executeUpdate("TRUNCATE TABLE temp_table IMMEDIATE");
      System.out.println("\n--------------------------------------\n");

      System.out.println("Table Truncated....");
      System.out.println("\n---------------------------------------\n");


      // INSERT new data into table temp_table
	
      System.out.println("\nINSERT INTO temp_table VALUES (1,'123.45',NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (1,'123.45',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (2,'-123456.78'"+
                         " ,NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (2,'-123456.78',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (3,'+123456.78'," +
                         "NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (3,'+123456.78',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (4,'1.23E4',NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (4,'1.23E4',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (5,'001,234',NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (5,'001,234',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (6,'1234',NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (6,'1234',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (7,'1234-',NULL)");	
      stmt.executeUpdate("INSERT INTO temp_table VALUES (7,'1234-',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (8,'+1234',NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (8,'+1234',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (9,'<1234>',NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (9,'<1234>',NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (10,'123,456.78-',"+
                         "NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (10,'123,456.78-',"+
                         "NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (11,'<123,456.78>',"+
                         "NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (11,'<123,456.78>',"+
                         "NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (12,'$123,456.78',"+
                         "NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (12,'$123,456.78',"+
                         "NULL)");
      
      System.out.println("\nINSERT INTO temp_table VALUES (13,'+123,456.78',"+
                          "NULL)");
      stmt.executeUpdate("INSERT INTO temp_table VALUES (13,'+123,456.78',"+
                           "NULL)");

      // List rows from table temp_table      

      System.out.println("\nSELECT * FROM temp_table\n\n");
      System.out.println("---------------------------------------------------");

      System.out.println("ROWNO \t TEMPDATA \t \t FORMAT\n");
      System.out.println("---------------------------------------------------");

      rs=stmt.executeQuery("SELECT * FROM temp_table");
      while(rs.next())
      {
         System.out.print("\n"+rs.getInt(1)+" \t ");
         System.out.print(rs.getString(2)+"   \t\t ");
         System.out.print(rs.getString(3)+"\n");
      }

      rs.close();
      stmt.close();

      // MI in the format element is to represent the sign of the string
      // If it is a negative number, a trailing minus sign (-) is expected. 
      // If it is a positive number, an optional trailing space is expected.
   
       System.out.println("\n\nSELECT TO_NUMBER(tempdata)FROM "+
                          "temp_table WHERE rowno = 1");
       System.out.println("\n----------------------------\n");

       Statement stmt1=con.createStatement();
       ResultSet rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata)FROM "+
                           "temp_table WHERE rowno = 1");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata)FROM temp_table "+
            "WHERE rowno = 2");
       System.out.println("\n----------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata)FROM temp_table "+
            "WHERE rowno = 2");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       } 

       System.out.println("\n\nSELECT TO_NUMBER(tempdata)FROM temp_table "+
            "WHERE rowno = 3");
       System.out.println("\n-----------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata)FROM temp_table "+
            "WHERE rowno = 3");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       } 

       System.out.println("\n\nSELECT TO_NUMBER(tempdata)FROM temp_table "+
             "WHERE rowno = 4");
       System.out.println("\n-----------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata)FROM temp_table "+
             "WHERE rowno = 4");
       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'000,000')FROM "+
                                  "temp_table WHERE rowno = 5");
       System.out.println("\n------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'000,000')FROM "+
                                  "temp_table WHERE rowno = 5");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'9999.99')FROM "+
                                  "temp_table WHERE rowno = 1");
       System.out.println("\n-------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'9999.99')FROM "+
                                  "temp_table WHERE rowno = 1");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'9999MI')FROM "+
                                   "temp_table WHERE rowno =  6");
       System.out.println("\n--------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'9999MI')FROM "+
                                   "temp_table WHERE rowno =  6");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'9999MI')FROM "+
                                   "temp_table WHERE rowno = 7");
       System.out.println("\n--------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'9999MI')FROM "+
                                  "temp_table WHERE rowno = 7");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'999999MI')FROM "+
                                    "temp_table WHERE rowno = 6");
       System.out.println("\n--------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'999999MI')FROM "+
                                    "temp_table WHERE rowno = 6");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'S9999')FROM "+
                                    "temp_table WHERE rowno = 8");
       System.out.println("\n----------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'S9999')FROM "+
                                    "temp_table WHERE rowno = 8");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'9999PR')FROM "+
                                       "temp_table WHERE rowno = 6");
       System.out.println("\n-----------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'9999PR')FROM "+
                                       "temp_table WHERE rowno = 6");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'9999PR')FROM "+
                                      "temp_table WHERE rowno = 9");
       System.out.println("\n------------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'9999PR')FROM "+
                                      "temp_table WHERE rowno = 9");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'000,000.00MI')FROM "+
                                       "temp_table WHERE rowno = 10");
       System.out.println("\n--------------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'000,000.00MI')FROM "+
                                       "temp_table WHERE rowno = 10");
       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'000,000.00PR')FROM "+
                             "temp_table WHERE rowno = 11");
       System.out.println("\n--------------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'000,000.00PR')FROM "+
                            "temp_table WHERE rowno = 11");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'$999,999.99')FROM "+
                             "temp_table WHERE rowno = 12");
       System.out.println("\n---------------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'$999,999.99')FROM "+
                            "temp_table WHERE rowno = 12");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'$S000,000.00')FROM "+
                                       "temp_table WHERE rowno = 12");
       System.out.println("\n--------------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'$S000,000.00')FROM "+
                            "temp_table WHERE rowno = 12");

       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       System.out.println("\n\nSELECT TO_NUMBER(tempdata,'S000,000.00')FROM "+
                                "temp_table WHERE rowno = 13");
       System.out.println("\n--------------------------------------\n");

       rs1=stmt1.executeQuery("SELECT TO_NUMBER(tempdata,'S000,000.00')FROM "+
                          "temp_table WHERE rowno = 13");
       while (rs1.next())
       {
          tnumber = rs1.getFloat(1);
          System.out.println(tnumber);
       }

       rs1.close();
       stmt1.close();
    }
    catch (SQLException sqle)
    {
       System.out.println("Error Msg: "+ sqle.getMessage());
       System.out.println("SQLState: "+sqle.getSQLState());
       System.out.println("SQLError: "+sqle.getErrorCode());
       System.out.println("Rollback the transaction and quit the program");
       System.out.println();
       try 
       { 
          con.rollback();
       }
       catch (SQLException sql)
       {
          System.out.println("Error Msg: "+ sql.getMessage());
          System.out.println("SQLState: "+sql.getSQLState());
          System.out.println("SQLError: "+sql.getErrorCode());
       }
       System.exit(1);
    }
 } // ToNumber

static void UseRound(Connection con)
{
   try
   {
      float tnumber;                      
      
      /*****************************************************************/
      /* ROUND numeric value                                           */
      /*****************************************************************/

      // Select average salary
      System.out.println("\nSELECT AVG(SALARY) FROM employee\n");
      System.out.println("\n----------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT AVG(SALARY) FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      // Select average salary rounded 5 places to the right of the
      // decimal point
      System.out.println("\nSELECT ROUND((AVG(SALARY)), 5) "+
                   " FROM employee\n");
      System.out.println("\n-----------------------------------------\n");

      rs = stmt.executeQuery("SELECT ROUND((AVG(SALARY)), 5) "+
                   "FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      // Select average salary rounded 0 places to the right of the
      // decimal point
      System.out.println("\nSELECT ROUND((AVG(SALARY)), 0) FROM employee\n");
      System.out.println("\n----------------------------------------\n");

      rs = stmt.executeQuery("SELECT ROUND((AVG(SALARY)), 0) FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      // Select average salary rounded -2 places to the right of the
      // decimal point
      System.out.println("\nSELECT ROUND((AVG(SALARY)), -2) "+
                   " FROM employee\n");
      System.out.println("\n-----------------------------------------\n");

      rs = stmt.executeQuery("SELECT ROUND((AVG(SALARY)), -2) "+
                   "FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      rs.close();
      stmt.close();

           
      /*****************************************************************/
      /* ROUND datetime value                                          */
      /*****************************************************************/

      // Round DATE and TIME value on the basis of format string
      Date tdate;
      Time ttime;

      System.out.println("\nSELECT DATE(received) FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      Statement stmt0 = con.createStatement();
      ResultSet rs0 = stmt0.executeQuery("SELECT DATE(received) FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }
      
      
      System.out.println("\nSELECT ROUND(DATE(received), 'MON') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(DATE(received), 'MON') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }


      System.out.println("\nSELECT ROUND(DATE(received), 'D') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(DATE(received), 'D') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      System.out.println("\nSELECT ROUND(DATE(received), 'Y') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(DATE(received), 'Y') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      System.out.println("\nSELECT ROUND(DATE(received), 'WW') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(DATE(received), 'WW') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }    

      System.out.println("\nSELECT TIME(received) FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TIME(received) FROM in_tray");

      while (rs0.next())
      {
         ttime = rs0.getTime(1);
         System.out.println(ttime);
      }


      System.out.println("\nSELECT ROUND(TIME(received), 'HH') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(TIME(received), 'HH') FROM in_tray");

      while (rs0.next())
      {
         ttime = rs0.getTime(1);
         System.out.println(ttime);
      }


      System.out.println("\nSELECT ROUND(TIME(received), 'MI') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(TIME(received), 'MI') FROM in_tray");

      while (rs0.next())
      {
         ttime = rs0.getTime(1);
         System.out.println(ttime);
      }

      // ROUND DATE value on the basis of format string and locale

      System.out.println("\nSELECT ROUND(DATE(received), 'DAY', 'zh_CN') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(DATE(received), 'DAY', 'zh_CN') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      System.out.println("\nSELECT ROUND(DATE(received), 'D', 'fr_FR') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT ROUND(DATE(received), 'D', 'fr_FR') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      rs0.close();
      stmt0.close();


      /*****************************************************************/
      /* ROUND_TIMESTAMP datetime value                                */
      /*****************************************************************/

      // ROUND character string on the basis of format string
     
      Timestamp ttimestamp;
   
      System.out.println("\nVALUES ROUND_TIMESTAMP('1988-12-22-14.07.21.136421', 'HH')");
      System.out.println("\n------------------------------------\n");      

      Statement stmt1 = con.createStatement();
      ResultSet rs1 = stmt1.executeQuery("VALUES ROUND_TIMESTAMP('1988-12-22-14.07.21.136421', 'HH')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }
      
      
      System.out.println("\nVALUES ROUND_TIMESTAMP('1988-12-22-14.07.21.136421', 'MM')");
      System.out.println("\n------------------------------------\n");      

      rs1 = stmt1.executeQuery("VALUES ROUND_TIMESTAMP('1988-12-22-14.07.21.136421', 'MM')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }

      rs1.close();
      stmt1.close();

    }
    catch (SQLException sqle)
    {
       System.out.println("Error Msg: "+ sqle.getMessage());
       System.out.println("SQLState: "+sqle.getSQLState());
       System.out.println("SQLError: "+sqle.getErrorCode());
       System.out.println("Rollback the transaction and quit the program");
       System.out.println();
       try 
       { 
          con.rollback();
       }
       catch (SQLException sql)
       {
          System.out.println("Error Msg: "+ sql.getMessage());
          System.out.println("SQLState: "+sql.getSQLState());
          System.out.println("SQLError: "+sql.getErrorCode());
       }
       System.exit(1);
    }
 } // UseRound

static void UseTruncate(Connection con)
{
   try
   {
      float tnumber;                      
      
      /*****************************************************************/
      /* TRUNC or TRUNCATE numeric value                               */
      /*****************************************************************/

      // Select average salary from employee table
      System.out.println("\nSELECT AVG(SALARY) FROM employee\n");
      System.out.println("\n----------------------------------------\n");

      Statement stmt = con.createStatement();
      ResultSet rs = stmt.executeQuery("SELECT AVG(SALARY) FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      // Select average salary truncated 5 places to the right of the
      // decimal point
      System.out.println("\nSELECT TRUNCATE((AVG(SALARY)), 5) "+
                   " FROM employee\n");
      System.out.println("\n-----------------------------------------\n");

      rs = stmt.executeQuery("SELECT TRUNCATE((AVG(SALARY)), 5) "+
                   "FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      // Select average salary truncated 0 places to the right of the
      // decimal point
      System.out.println("\nSELECT TRUNCATE((AVG(SALARY)), 0) FROM employee\n");
      System.out.println("\n----------------------------------------\n");

      rs = stmt.executeQuery("SELECT TRUNCATE((AVG(SALARY))) FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      // Select average salary truncated -2 places to the right of the
      // decimal point
      System.out.println("\nSELECT TRUNCATE((AVG(SALARY)), -2) "+
                   " FROM employee\n");
      System.out.println("\n-----------------------------------------\n");

      rs = stmt.executeQuery("SELECT TRUNCATE((AVG(SALARY)), -2) "+
                   "FROM employee");

      while (rs.next())
      {
         tnumber = rs.getFloat(1);
         System.out.println(tnumber);
      }

      rs.close();
      stmt.close();

           
      /*****************************************************************/
      /* TRUNC or TRUNCATE datetime value                              */
      /*****************************************************************/

      // TRUNCATE DATE and TIME value on the basis of format string
      Date tdate;
      Time ttime;

      // Select rows from in_tray table
      System.out.println("\nSELECT received FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      Statement stmt0 = con.createStatement();
      ResultSet rs0 = stmt0.executeQuery("SELECT received FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }
      
      
      System.out.println("\nSELECT TRUNC(DATE(received), 'MONTH') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNC(DATE(received), 'MONTH') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }


      System.out.println("\nSELECT TRUNCATE(DATE(received), 'DAY') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNCATE(DATE(received), 'DAY') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      System.out.println("\nSELECT TRUNCATE(DATE(received), 'YEAR') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNCATE(DATE(received), 'YEAR') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      System.out.println("\nSELECT TRUNC(DATE(received), 'CC') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNC(DATE(received), 'CC') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }    

      System.out.println("\nSELECT TRUNC(DATE(received), 'Q') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNC(DATE(received), 'Q') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      System.out.println("\nSELECT TRUNCATE(DATE(received), 'I') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNCATE(DATE(received), 'I') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }    



      System.out.println("\nSELECT TRUNC(TIME(received), 'HH') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNC(TIME(received), 'HH') FROM in_tray");

      while (rs0.next())
      {
         ttime = rs0.getTime(1);
         System.out.println(ttime);
      }


      System.out.println("\nSELECT TRUNC(TIME(received), 'MI') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNC(TIME(received), 'MI') FROM in_tray");

      while (rs0.next())
      {
         ttime = rs0.getTime(1);
         System.out.println(ttime);
      }


      System.out.println("\nSELECT TRUNC(TIME(received), 'SS') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNC(TIME(received), 'SS') FROM in_tray");

      while (rs0.next())
      {
         ttime = rs0.getTime(1);
         System.out.println(ttime);
      }

      // TRUNCATE DATE value on the basis of format string and locale

      System.out.println("\nSELECT TRUNCATE(DATE(received), 'DAY', 'ja_JP') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNCATE(DATE(received), 'DAY', 'ja_JP') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      System.out.println("\nSELECT TRUNCATE(DATE(received), 'D', 'fr_FR') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs0 = stmt0.executeQuery("SELECT TRUNCATE(DATE(received), 'D', 'fr_FR') FROM in_tray");

      while (rs0.next())
      {
         tdate = rs0.getDate(1);
         System.out.println(tdate);
      }

      rs0.close();
      stmt0.close();


      /*****************************************************************/
      /* TRUNC_TIMESTAMP datetime value                                */
      /*****************************************************************/

      // Truncate character string on the basis of format string
     
      Timestamp ttimestamp;
   
      System.out.println("\nVALUES TRUNC_TIMESTAMP('1988-12-22-14.07.21.136421', 'MONTH')");
      System.out.println("\n------------------------------------\n");      

      Statement stmt1 = con.createStatement();
      ResultSet rs1 = stmt1.executeQuery("VALUES TRUNC_TIMESTAMP('1988-12-22-14.07.21.136421', 'MONTH')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }
      
      
      System.out.println("\nVALUES TRUNC_TIMESTAMP('1988-12-25-17.12.30.000000', 'YEAR')");
      System.out.println("\n------------------------------------\n");      

      rs1 = stmt1.executeQuery("VALUES TRUNC_TIMESTAMP('1988-12-25-17.12.30.000000', 'YEAR')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }

      System.out.println("\nSELECT TRUNC_TIMESTAMP(received, 'D') FROM in_tray");
      System.out.println("\n------------------------------------\n");      

      rs1 = stmt1.executeQuery("SELECT TRUNC_TIMESTAMP(received, 'D') FROM in_tray");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }
      
      
      System.out.println("\nVALUES TRUNC_TIMESTAMP('1988-12-25', 'CC')");
      System.out.println("\n------------------------------------\n");      

      rs1 = stmt1.executeQuery("VALUES TRUNC_TIMESTAMP('1988-12-25', 'CC')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }
      
      
      System.out.println("\nVALUES TRUNC_TIMESTAMP('1988-12-23', 'Q')");
      System.out.println("\n------------------------------------\n");      

      rs1 = stmt1.executeQuery("VALUES TRUNC_TIMESTAMP('1988-12-23', 'Q')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }
      
      
      System.out.println("\nVALUES TRUNC_TIMESTAMP('1988-12-25-17.12.30.000000', 'I')");
      System.out.println("\n------------------------------------\n");      

      rs1 = stmt1.executeQuery("VALUES TRUNC_TIMESTAMP('1988-12-25-17.12.30.000000', 'I')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }
      
      
      System.out.println("\nVALUES TRUNC_TIMESTAMP('1988-12-22-14.07.21.136421', 'DAY', 'es_ES')");
      System.out.println("\n------------------------------------\n");      

      rs1 = stmt1.executeQuery("VALUES TRUNC_TIMESTAMP('1988-12-22-14.07.21.136421', 'DAY', 'es_ES')");

      while (rs1.next())
      {
         ttimestamp = rs1.getTimestamp(1);
         System.out.println(ttimestamp);
      }

      rs1.close();
      stmt1.close();

    }
    catch (SQLException sqle)
    {
       System.out.println("Error Msg: "+ sqle.getMessage());
       System.out.println("SQLState: "+sqle.getSQLState());
       System.out.println("SQLError: "+sqle.getErrorCode());
       System.out.println("Rollback the transaction and quit the program");
       System.out.println();
       try 
       { 
          con.rollback();
       }
       catch (SQLException sql)
       {
          System.out.println("Error Msg: "+ sql.getMessage());
          System.out.println("SQLState: "+sql.getSQLState());
          System.out.println("SQLError: "+sql.getErrorCode());
       }
       System.exit(1);
    }
 } // UseTruncate

//Drop table temp_table

static void DropTable(Connection con)
{	
   try
   {
      String st="DROP TABLE temp_table";
      Statement stmt = con.createStatement();
      stmt.executeUpdate(st);
      System.out.println("\n\nDrop table temp_table; \n");
      con.commit();
      db.disconnect();
   }
   catch(Exception e)
   {
      System.out.println("Unable to drop table.....");
   }
 } //DropTable
 
} // ScalarFunctions

