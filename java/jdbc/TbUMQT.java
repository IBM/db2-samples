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
// SOURCE FILE NAME: TbUMQT.java
//
// SAMPLE: How to use user materialized query tables (summary tables).
//
//         This sample:
//         1. Query Table (UMQT) for the 'employee' table.
//         2. Shows the usage and update mechanisms for non-partitioned UMQTs.
//         3. Creates a new partitioned Maintained Materialized
//            Query Table (MQT).
//         4. Shows the availability of partitioned MQTs during SET INTEGRITY
//            after add/detach of a partition via ALTER ADD PARTITION and
//            ALTER DETACH PARTITION.
//
// SQL Statements USED:
//         ALTER TABLE
//         CREATE TABLE
//         EXECUTE IMMEDIATE
//         DROP
//         INSERT
//         SELECT
//         SET CURRENT
//         SET INTEGRITY
//         REFRESH TABLE
//
// JAVA 2 CLASSES USED:
//         Statement
//         ResultSet
//
// Classes used from Util.java are:
//         Db
//         Data
//         JdbcException
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: TbUMQT.out (available in the online documentation)
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
//**************************************************************************

import java.lang.*;
import java.sql.*;

class TbUMQT
{
  public static void main(String argv[])
  {
    try
    {
      Db db = new Db(argv);

      System.out.println(
        "\nTHIS SAMPLE SHOWS THE USAGE OF USER MAINTAINED MATERIALIZED.\n" +
        "    QUERY TABLES(MQTs).\n");

      // connect to the 'sample' database
      db.connect();
      
      // create summary tables
      createMQT(db.con);
      
      // bring the summary tables out of check-pending state
      setIntegrity(db.con);
      
      // populate the base table and update contents of the summary tables
      updateUserMQT(db.con);
      
      // set registers to optimize query processing by routing queries to
      // UMQT
      setRegisters(db.con);
      
      // issue a select statement that is routed to the summary tables
      showTableContents(db.con);
      
      // drop summary tables
      dropTables(db.con);  

      // creates regular DMS tablespaces       
      dms_tspaceaceCreate(db.con);

      // creates a partitioned table 
      partitionedTbCreate(db.con); 

     // create MQT on a paartitioned table
     createMQT_on_Partitionedtb(db.con);

     // create partitione MQT on a partitioned table
     createPartitioned_MQT(db.con);

     // drop tablespaces
     tablespacesDrop(db.con); 
       
      // disconnect from the 'sample' database
      db.disconnect();                
      
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e);
      jdbcExc.handle();
    }
   
  } // main

  // Create summary tables.
  static void createMQT(Connection con)
  {
    Statement stmt;

    System.out.println(
      "\n----------------------------------------------------------\n" +
      "Creating UMQT on EMPLOYEE table...\n");
    try
    {
      System.out.println(
        "USE THE SQL STATEMENT:\n" +
        "  CREATE SUMMARY TABLE \n" +
        "TO CREATE A UMQT WITH DEFERRED REFRESH\n\n" +
        "Execute the statement:\n" +
        "CREATE SUMMARY TABLE umqt_employee AS \n" +
        "  (SELECT workdept, count(*) AS no_of_employees \n" +
        "    FROM employee GROUP BY workdept)\n" +
        "  DATA INITIALLY DEFERRED REFRESH DEFERRED\n" +
        "  MAINTAINED BY USER\n");
      
      stmt = con.createStatement();      
      stmt.executeUpdate(
        "  CREATE SUMMARY TABLE umqt_employee AS" +
        "    (SELECT workdept, count(*) AS no_of_employees" +
        "      FROM employee GROUP BY workdept)" +
        "    DATA INITIALLY DEFERRED REFRESH DEFERRED" +
        "    MAINTAINED BY USER");
     
      // commit the transaction
      con.commit();  

      stmt.close();         
    }

    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }  
    
    // creating a UMQT with immediate refresh option is not supported
    try
    {
      System.out.println(
        "\nCREATE SUMMARY TABLE to create a UMQT with immediate\n" +
        "refresh option is not supported\n\n" +
        "Execute the statement:\n" +
        "CREATE SUMMARY TABLE aimdusr AS \n" +
        "  (SELECT workdept, count(*) AS no_of_employees \n" +
        "    FROM employee GROUP BY workdept)\n" +
        "  DATA INITIALLY DEFERRED REFRESH IMMEDIATE\n" +
        "  MAINTAINED BY USER\n");
      
      stmt = con.createStatement();        
      stmt.executeUpdate(
        "  CREATE SUMMARY TABLE aimdusr AS" +
        "    (SELECT workdept, count(*) AS no_of_employees" +
        "      FROM employee GROUP BY workdept)" +
        "    DATA INITIALLY DEFERRED REFRESH IMMEDIATE" +
        "    MAINTAINED BY USER");

      // commit the transaction
      System.out.println("\n  COMMIT");
      con.commit();
      
      stmt.close();        
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handleExpectedErr();
    }
       
   } // createMQT 
   
  // Bring the summary tables out of check-pending state. 
  static void setIntegrity(Connection con)
  {
    System.out.println(
      "\n-----------------------------------------------------------");
    System.out.println(
      "USE THE SQL STATEMENT:\n" +
      "  SET INTEGRITY \n" +
      "To bring the MQTs out of check pending state\n");
    try
    {
      System.out.println(
        "Execute the statement:\n" +
        "SET INTEGRITY FOR umqt_employee ALL IMMEDIATE UNCHECKED\n");
   
      Statement stmt = con.createStatement();
      stmt.executeUpdate(
        "SET INTEGRITY FOR umqt_employee ALL IMMEDIATE UNCHECKED");     
   
      // commit the transaction
      con.commit();         
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
    
  } // setIntegrity 

  // Populate the base table and update the contents of the summary tables.
  static void updateUserMQT(Connection con)
  {
    System.out.println(
      "\n-----------------------------------------------------------\n" +
      "\nUMQT_EMPLOYEE must be updated manually by the user\n\n" +
      "USE THE SQL STATEMENT:\n" +
      "  INSERT\n" +
      "To update the UMQT\n ");
    try
    {
      System.out.println(   
        "Execute the statement:\n" + 
        "INSERT INTO umqt_employee \n" +
        "  (SELECT workdept, count(*) AS no_of_employees\n" +
        "  FROM employee GROUP BY workdept)\n");

      Statement stmt = con.createStatement(); 
      stmt.executeUpdate(
        "INSERT INTO umqt_employee "+
        "  (SELECT workdept, count(*) AS no_of_employees " +
        "    FROM employee GROUP BY workdept)");

      // commit the transaction
      con.commit();
      stmt.close();   
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
   
  } // updateUserMQT 

  // Set registers to optimize query processing by routing queries to UMQT. 
  static void setRegisters(Connection con)
  {
    // the CURRENT REFRESH AGE special register must be set to a value other
    // than zero for the specified table types to be considered when 
    // optimizing the processing of dynamic SQL queries. 

    System.out.println(
      "\n-----------------------------------------------------------\n" +
      "The following registers must be set to route queries to UMQT\n");
    
    try
    {  
      System.out.println(  
        "\n  SET CURRENT REFRESH AGE ANY\n" +
        "\nIndicates that any table types specified by CURRENT MAINTAINED" +
        "\nTABLE TYPES FOR OPTIMIZATION, and MQTs defined with REFRESH \n" +
        "IMMEDIATE option, can be used to optimize the \n" +
        "processing of a query. \n\n");

      Statement stmt = con.createStatement(); 
      stmt.executeUpdate("SET CURRENT REFRESH AGE ANY");
  
      System.out.println(
        "  SET CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION USER \n\n" +
        "Specifies that user-maintained refresh-deferred materialized \n" +
        "query tables can be considered to optimize the processing of \n" +
        "dynamic SQL queries. \n");

      stmt.executeUpdate(  
        "SET CURRENT MAINTAINED TABLE TYPES FOR OPTIMIZATION USER");
     
      // commit the transaction
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }  
  } // setRegisters 

  // Issue a select statement that is routed to the summary tables.
  static void showTableContents(Connection con)
  {
    String workDept = null;
    int countWorkDept = 0;
    
    System.out.println(
      "\n-----------------------------------------------------------\n" +
      "USE THE SQL STATEMENT:\n" +
      "  SELECT\n" +
      "On EMPLOYEE table. This is routed to the UMQT umqt_employee\n");
    
    try
    {
      Statement stmt = con.createStatement();
      ResultSet rs;     

      System.out.println(
        "  SELECT workdept, count(*) AS no_of_employees \n" +
        "    FROM employee GROUP BY workdept\n");
      System.out.println(
        "  DEPT CODE   NO. OF EMPLOYEES     \n" +
        "  ----------  ----------------");        

      // perform a SELECT against the "employee" table in the sample database
      rs = stmt.executeQuery(
             "SELECT workdept, count(*) AS no_of_employees " +
             "FROM employee GROUP BY workdept");
 
      // retrieve and display the result from the SELECT statement
      while (rs.next())
      {
        workDept = rs.getString("workdept");
        countWorkDept = rs.getInt("no_of_employees");
        
        System.out.println(
          "    " +
          Data.format(workDept, 7) + " " + 
          Data.format(countWorkDept, 17));
      }
      rs.close();
      
      System.out.println(
        "\nA SELECT query on umqt_employee yields similar results\n\n" +
        "  SELECT * FROM umqt_employee \n");
      System.out.println(  
        "  DEPT CODE   NO. OF EMPLOYEES     \n" +
        "  ----------  ----------------\n");

      // perform a SELECT against umqt_employee query table
      rs = stmt.executeQuery(" SELECT * FROM umqt_employee");  
      
      // retrieve and display the result from the SELECT statement
      while (rs.next())
      {
        workDept = rs.getString("workdept");
        countWorkDept = rs.getInt("no_of_employees");
        
        System.out.println(
          "    " +
          Data.format(workDept, 7) + " " + 
          Data.format(countWorkDept, 17));
      }
      rs.close();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }  
  } // showTableContents 

  // drop tables.
  static void dropTables(Connection con)
  {
    System.out.println(
      "\nDropping tables...\n\n" +
      "USE THE SQL STATEMENT:\n" +
      "  DROP\n" +
      "To drop the UMQT umqt_employee\n");

    try
    {
      System.out.println(
        "Execute the statement:\n" + 
        "DROP TABLE umqt_employee\n");
      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE umqt_employee");
  
      // commit the transaction
      con.commit();
      
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // dropTables 

  // creates regular DMS tablespaces. 
  static void dms_tspaceaceCreate(Connection con) throws SQLException
  {
    try
    {
      System.out.println(
        "\n-----------------------------------------------------------" +
        "\nUSE THE SQL STATEMENT:\n" +
        "  CREATE REGULAR TABLESPACE \n" +
        "TO CREATE A REGULAR DMS TABLESPACES \n" +
        "\nExecute the statement:\n" +
        "  CREATE REGULAR TABLESPACE dms_tspace"); 

      // create regular DMS table space 'dms_tspace'
      Statement stmt = con.createStatement();
      String str = "";
      str = "CREATE REGULAR TABLESPACE dms_tspace";
      stmt.executeUpdate(str);

      System.out.println(
        "\nExecute the statement:\n" +
        "  CREATE REGULAR TABLESPACE dms_tspace1");

      // create regular DMS table space 'dms_tspace1'
      str = "CREATE REGULAR TABLESPACE dms_tspace1";
      stmt.executeUpdate(str);

      System.out.println(
        "\nExecute the statement:\n" +
        "  CREATE REGULAR TABLESPACE dms_tspace2");

      // create regular DMS table space 'dms_tspace2'
      str = "CREATE REGULAR TABLESPACE dms_tspace2";
      stmt.executeUpdate(str);

      System.out.println(
        "\nExecute the statement:\n" +
        "  CREATE REGULAR TABLESPACE dms_tspace3");

      // create regular DMS table space 'dms_tspace3'
      str = "CREATE REGULAR TABLESPACE dms_tspace3";
      stmt.executeUpdate(str);

      System.out.println(
        "\n-----------------------------------------------------------");
      con.commit();
      stmt.close();

    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } //dms_tspaceaceCreate

  // create a partitioned table in regular DMS tablespaces i.e; 'part1' is
  // placed in 'dms_tspace1', 'part2' is placed in 'dms_tspace2' and
  // 'part3' in 'dms_tspace3' and inserts data into it.
  static void partitionedTbCreate(Connection con) throws SQLException
  {
    try
    {
      System.out.println(
        "\nUSE THE SQL STATEMENT:\n" +
        "  CREATE TABLE \n" +
        "TO CREATE A TABLE \n" +
        "\nExecute the statement:\n" +
        "  CREATE TABLE fact_table (max SMALLINT NOT NULL,\n" +
        "                           CONSTRAINT CC CHECK (max>0))\n" +  
        "    PARTITION BY RANGE (max)\n "+
        "     (PART  part1 STARTING FROM (1) ENDING (3) IN dms_tspace1,\n" +
        "      PART part2 STARTING FROM (4) ENDING (6) IN dms_tspace2,\n" +
        "      PART part3 STARTING FROM (7) ENDING (9) IN dms_tspace3)");

      Statement stmt = con.createStatement();
      String str = "";

      str = str + "CREATE TABLE fact_table ";
      str = str + "(max SMALLINT NOT NULL, CONSTRAINT CC CHECK (max>0))";
      str = str + " PARTITION BY RANGE (max) ";
      str = str + "(PART  part1 STARTING FROM (1) ENDING (3) ";
      str = str + "IN dms_tspace1, PART part2 STARTING FROM (4) ENDING (6) ";
      str = str + "IN dms_tspace2, PART part3 STARTING FROM (7) ENDING (9) ";
      str = str + "IN dms_tspace3)";
    
      stmt.executeUpdate(str);                  
      con.commit();
      stmt.close();

     }
     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }
 
    try
    {
      System.out.println(
        "\n-----------------------------------------------------------" +
        "\nUSE THE SQL STATEMENT:\n" +
        "  INSERT INTO \n" +
        "TOINSERT DATA IN A TABLE \n" +
        "\nExecute the statement:\n" +
        "  INSERT INTO fact_table VALUES (1), (2), (3),\n" + 
        "                                (4), (5), (6),\n" +
        "                                (7), (8), (9)");

      // insert data into the table
      Statement stmt = con.createStatement();
      String str = "";

      str = "INSERT INTO fact_table VALUES (1), (2), (3), (4),";
      str = str + " (5), (6), (7), (8), (9)";
      stmt.executeUpdate(str);

      con.commit();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  } // partitionedTbCreate

  // creates MQT on a partitioned table. Performs SET INTEGRITY on MQT to 
  // bring MQT out of check pending state and to get changes reflected.
  static void createMQT_on_Partitionedtb (Connection con) throws SQLException
  {
    try
    {
      System.out.println(
        "\nUSE THE SQL STATEMENT:\n" +
        "  CREATE TABLE \n" +
        "TO CREATE A TABLE \n" +
        "\nExecute the statement:\n" +
        "  CREATE TABLE mqt_fact_table AS\n" +
        "    (SELECT max, COUNT (*) AS no_of_rows FROM fact_table)\n" +
        "     GROUP BY max) DATA INITIALLY DEFERRED REFRESH IMMEDIATE");

      Statement stmt = con.createStatement();
      String str = "";
      str = str + "CREATE TABLE mqt_fact_table  AS";
      str = str + "(SELECT max, COUNT (*) AS no_of_rows FROM fact_table ";
      str = str + " GROUP BY max) DATA INITIALLY DEFERRED REFRESH IMMEDIATE";
 
      stmt.executeUpdate(str);                  
      con.commit();
      stmt.close();
     }
     catch (Exception e)
     {
       JdbcException jdbcExc = new JdbcException(e, con);
       jdbcExc.handle();
     }

    try
    {
      System.out.println(
      "\nUSE THE SQL STATEMENT:" +
      "\n  SET INTEGRITY " +
      "\nTO PERFORM SET INTEGRITY ON A TABLE\n" +
      "\nExecute the statement:" +
      "\n  SET INTEGRITY FOR mqt_fact_table IMMEDIATE CHECKED");

      Statement stmt = con.createStatement();
      String str = "";

      str = str + "SET INTEGRITY FOR mqt_fact_table IMMEDIATE CHECKED";
    
      stmt.executeUpdate(str);                  
      con.commit();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }
  
    // display the contents of a table 
    displaytbData(con);

    System.out.println(
      "\nUSE THE SQL STATEMENT:\n" +
      "  DROP\n" +
      "TO DROP A TABLE.\n" +

      "\nExecute the statements:" +
      "\n  DROP TABLE mqt_fact_table" +
      "\n  DROP TABLE fact_table");      

    Statement stmt = con.createStatement();
    String str = "";

    str = str + "DROP TABLE mqt_fact_table";
    
    stmt.executeUpdate(str);                  
    con.commit();
    stmt.close();

    stmt = con.createStatement();
    str = "";

    str = str + "DROP TABLE fact_table";
    
    stmt.executeUpdate(str);                  
    con.commit();
    stmt.close();
  } // createMQT_on_Partitionedtb
 
  // creates a partitioned MQT on a partitioned table whose range is less
  // then that of the base table. Partition is added to MQT and 
  // REFRESH TABLE is performed on MQT to bring MQT out of check pending 
  // state and to get changes reflected to MQT.
  static void createPartitioned_MQT(Connection con) throws SQLException
  {
    // creates a partitioned table
    partitionedTbCreate(con);
 
    try
    {
      System.out.println(
        "\n-----------------------------------------------------------" +
        "\nUSE THE SQL STATEMENT:\n" +
        "  CREATE\n" +
        "TO CREATE A PARTITIONED MQT ON A PARTITIONED TABLE .\n" +

        "\nExecute the statement:" +
        "\n  CREATE TABLE mqt_fact_table AS" +
        "\n    (SELECT max, COUNT (*) AS no_of_rows FROM fact_table \n" +
        "\n      GROUP BY max) DATA INITIALLY DEFERRED REFRESH IMMEDIATE\n" +
        "          PARTITION BY RANGE (max)\n" +
        "            (STARTING 0 ENDING 6 EVERY 3)\n");

      Statement stmt = con.createStatement();
      String str = "";
      str = str + "CREATE TABLE mqt_fact_table  AS" ;
      str = str + "(SELECT max, COUNT (*) AS no_of_rows FROM fact_table ";
      str = str + "  GROUP BY max) DATA INITIALLY DEFERRED REFRESH IMMEDIATE";
      str = str + "  PARTITION BY RANGE (max)";
      str = str + "  (STARTING 0 ENDING 6 EVERY 3)";

      stmt.executeUpdate(str); 
      con.commit();
      stmt.close();
   }
   catch (Exception e)
   {
     JdbcException jdbcExc = new JdbcException(e, con);
     jdbcExc.handle();
   }
   
   try
   {
     System.out.println(
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENT:\n" +
       "  ALTER TABLE \n" +
       "TO ADD PARTITION TO MQT\n" + 
       "\nExecute the statement:" +
       "\n  ALTER TABLE mqt_fact_table ADD PARTITION part4\n " +
       "      STARTING (7) ENDING (9)\n");

      Statement stmt = con.createStatement();
      String str = "";
      str = str + "ALTER TABLE mqt_fact_table ADD PARTITION part4 ";
      str = str + "STARTING (7) ENDING (9)";

      stmt.executeUpdate(str);                  
      con.commit();
      stmt.close();
       
      System.out.println(
        "\nUSE THE SQL STATEMENT:\n" +
        "  REFRESH\n" +
        "TO REFRESH TABLE\n" +
        "\nExecute the statement:" +
        "\n  REFRESH TABLE mqt_fact_table");
 
      stmt = con.createStatement();
      str = "";
      str = str + "REFRESH TABLE mqt_fact_table";
      stmt.executeUpdate(str); 
      con.commit();
      stmt.close();
    }
    catch (Exception e)
    {
      JdbcException jdbcExc = new JdbcException(e, con);
      jdbcExc.handle();
    }

    // display the contents of a table.
    displaytbData(con);

    // detach partition from a table.
    Detach_Partitiontb(con);
  } // createPartitioned_MQT

  // detach a partition from 'fact_table'. 
  // SET INTEGRITY is performed on MQT to bring it out of 
  // check pending state. Later, a partition is detached form 
  // 'mqt_fact_table'. REFRESH TABLE is performed on MQT to bring it out of
  // check pending state and to get changes reflected into MQT.
  static void Detach_Partitiontb(Connection con) throws SQLException
  {
    try
    {
      System.out.println(
        "\nUSE THE SQL STATEMENT:\n" +
        "  ALTER TABLE \n" +
        "TO DETACH A PARTITION FROM A TABLE\n" +
  
        "\nExecute the statement\n" +
        "  ALTER TABLE fact_table DETACH PARTITION part2 INTO \n" +
	"    TABLE detach_part1");
    
      Statement stmt = con.createStatement();
      String str = "";
      str = str + "ALTER TABLE fact_table DETACH PARTITION part2 ";
      str = str + "  INTO TABLE detach_part1";

      stmt.executeUpdate(str);
      con.commit();
      stmt.close();
   }
   catch (Exception e)
   {
     JdbcException jdbcExc = new JdbcException(e, con);
     jdbcExc.handle();
   }
 
   System.out.println(
     "\nUSE THE SQL STATEMENT:" +
     "\n  SET INTEGRITY \n" +
     "TO BRING THE MQTs OUT OF CHECK PENDING STATE\n" +

     "\nExecute the statement:" +
     "\nSET INTEGRITY FOR mqt_fact_table IMMEDIATE CHECKED");
 
   Statement stmt = con.createStatement();
   String str = "";

   str = str + "SET INTEGRITY FOR mqt_fact_table IMMEDIATE CHECKED";
   stmt.executeUpdate(str);
   con.commit();
   stmt.close();
  
   System.out.println(
     "\nExecute the statement:\n" +
     "  ALTER TABLE mqt_fact_table DETACH PARTITION part2\n " +
     "    INTO TABLE detach_part2");
   
   stmt = con.createStatement();
   str = "";
   str = str + "ALTER TABLE mqt_fact_table DETACH PARTITION part2 ";
   str = str + " INTO TABLE detach_part2";
   stmt.executeUpdate(str);
   con.commit();
   stmt.close();

   System.out.println(
     "\nUSE THE SQL STATEMENT:" +
     "\n  REFRESH\n" +
     "TO GET CHANGES REFLECTED\n" +

     "\nExecute the statement:" +
     "\n  REFRESH TABLE mqt_fact_table");

   stmt = con.createStatement();
   str = "";
   str = str + "REFRESH TABLE mqt_fact_table";
   stmt.executeUpdate(str);
   con.commit();
   stmt.close();
   
   // display the contents of a table 
   displaytbData(con);
 } // Detach_Partitiontb    
  
 // display the contents of a table.
 static void displaytbData(Connection con) throws SQLException
 {
   System.out.println(
     "\n-----------------------------------------------------------");
   try
   {
     int max = 0;

     System.out.println();
     System.out.println("SELECT * FROM fact_table");
     System.out.println(
       "     MAX\n" +
       "    ------");

     Statement stmt = con.createStatement();
     // perform a SELECT against the "fact_table" table.
     ResultSet rs1 = stmt.executeQuery("SELECT * FROM fact_table");

     // retrieve and display the result from the SELECT statement
     while (rs1.next())
     {
       max = rs1.getInt(1);

       System.out.println(
         "    " +
         Data.format(max, 3));
     }
     rs1.close();
     stmt.close();
   }
   catch (Exception e)
   {
     JdbcException jdbcExc = new JdbcException(e, con);
     jdbcExc.handle();
   }

   try
   {
     int max = 0;
     int no_of_rows = 0;
     System.out.println();
     System.out.println("SELECT * FROM mqt_fact_table");
     System.out.println(
       "     MAX    NO_OF_ROWS\n" +
       "    ------ ------------");
     Statement stmt = con.createStatement();
     // perform a SELECT against the "mqt_fact_table" table.
     ResultSet rs = stmt.executeQuery("SELECT * FROM mqt_fact_table");

     // retrieve and display the result from the SELECT statement
     while (rs.next())
     {
       max = rs.getInt(1);
       no_of_rows = rs.getInt(2);
       System.out.println(
         "    " +
         Data.format(max, 3)+ " " +
         Data.format(no_of_rows, 8));
     }
     rs.close();
     stmt.close();
     System.out.println(
       "\n-----------------------------------------------------------");
   }
   catch (Exception e)
   {
     JdbcException jdbcExc = new JdbcException(e, con);
     jdbcExc.handle();
   }
 } // displaytbData

 // drop tables.
 static void cleanup(Connection con) throws SQLException
 {
   try
   {
     System.out.println(
       "\nUSE THE SQL STATEMENT:\n" +
       "  DROP \n" +
       "TO DROP THE TABLES  \n" +
       "\nExecute the statements:\n" +
       "  DROP TABLE fact_table\n" +
       "  DROP TABLE mqt_fact_table\n" +
       "  DROP TABLE detach_part1\n" +
       "  DROP TABLE detach_part2");

     // drop the tables
     Statement stmt = con.createStatement();
     stmt.executeUpdate("DROP TABLE mqt_fact_table");
     stmt.executeUpdate("DROP TABLE fact_table");
     stmt.executeUpdate("DROP TABLE detach_part1");
     stmt.executeUpdate("DROP TABLE detach_part2");
     con.commit();
     stmt.close();
   }
   catch (Exception e)
   {
     JdbcException jdbcExc = new JdbcException(e, con);
     jdbcExc.handle();
   }
 } // cleanup 

 // drop tablespaces.
 static void tablespacesDrop(Connection con) throws SQLException
 {
   // drop tables.
   cleanup(con);

   try
   {
     System.out.println(
       "\n-----------------------------------------------------------" +
       "\nUSE THE SQL STATEMENT:\n" +
       "  DROP \n" +
       "TO DROP THE TABLESPACES  \n" +
       "\nExecute the statements:\n" +
       "  DROP TABLESPACE dms_tspace\n" +
       "  DROP TABLESPACE dms_tspace1\n" +
       "  DROP TABLESPACE dms_tspace2\n" +
       "  DROP TABLESPACE dms_tspace3");

     // drop the tablespaces
     Statement stmt = con.createStatement();
     stmt.executeUpdate("DROP TABLESPACE dms_tspace");
     stmt.executeUpdate("DROP TABLESPACE dms_tspace1");
     stmt.executeUpdate("DROP TABLESPACE dms_tspace2");
     stmt.executeUpdate("DROP TABLESPACE dms_tspace3");

     con.commit();
     stmt.close();
   }
   catch (Exception e)
   {
     JdbcException jdbcExc = new JdbcException(e, con);
     jdbcExc.handle();
   }
 } // tablespacesDrop
} // TbUMQT  
   
