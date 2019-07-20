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
// SOURCE FILE NAME: DbMCon.java
//
// SAMPLE: How to use multiple databases
//
//         NOTE:
//         This sample program requires a second database
//         that has to be created as follows:
//           - locally:
//               db2 create db sample2
//           - remotely:
//               db2 attach to node_name
//               db2 create db sample2
//               db2 detach
//               db2 catalog db sample2 as sample2 at node node_name
//
//         In case another name is used for the second database,
//         it can be specified in the command line arguments as
//         follows:
//           java DbMCon "" "dbAlias2 [userid2 passwd2]"
//
//         The second database can be dropped as follows:
//           - locally:
//               db2 drop db sample2
//           - remotely:
//               db2 attach to node_name
//               db2 drop db sample2
//               db2 detach
//               db2 uncatalog db sample2
//
// SQL Statements USED:
//         CREATE TABLE
//         DROP TABLE
//         COMMIT
//
// Classes used from Util.java are:
//         Db
//
// Compile: the utility file and the source file with:
//		javac Util.java
//		javac <filename>.java
//
// Run: java <filename> [<db_name>] <username> <pwd>
//	or
//     java <filename> [<db_name>] <server_name> <port_num> <username> <pwd>
//
// OUTPUT FILE: DbMCon.out (available in the online documentation)
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

class DbMCon
{
  public static void main(String argv[])
  {
    Db db1 = new Db();
    Db db2 = new Db();

    try
    {
      setup( argv, db1, db2 );

      System.out.println();
      System.out.println(
        "THIS SAMPLE SHOWS HOW TO USE MULTIPLE DATABASES.");

      System.out.println("------------------------------------------------");
      db1.connect();
      createTable( db1.con );
      dropTable( db1.con );
      db1.disconnect();
      System.out.println("------------------------------------------------");

      db2.connect();
      createTable( db2.con );
      dropTable( db2.con );
      db2.disconnect();
      System.out.println("------------------------------------------------");
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // main


  private static void setup( String argv[], Db db1, Db db2 ) throws Exception
  {
    if( argv.length > 11 ||
        ( argv.length == 1 &&
          ( argv[0].equals( "?" )               ||
            argv[0].equals( "-?" )              ||
            argv[0].equals( "/?" )              ||
            argv[0].equalsIgnoreCase( "-h" )    ||
            argv[0].equalsIgnoreCase( "/h" )    ||
            argv[0].equalsIgnoreCase( "-help" ) ||
            argv[0].equalsIgnoreCase( "/help" ) ) ) )
    {
      throwUsageException();
    }

    // Initialize default database names
    db1.alias      = "sample";
    db1.server     = "";
    db1.portNumber = -1;
    db1.userId     = "";
    db1.password   = "";

    db2.alias      = "sample2";
    db2.server     = "";
    db2.portNumber = -1;
    db2.userId     = "";
    db2.password   = "";

    switch (argv.length) {
      case 0:	// Use type 2 driver
	break;
	
      case 1:
	db1.alias      = argv[0];
	break;
	
      case 2:
	// Use type 2 driver with userid/password specified
        db1.userId     = argv[0];
        db1.password   = argv[1];
	break;

      case 3:
	// Use type 2 driver with dbname/userid/password specified
	db1.alias      = argv[0];
        db1.userId     = argv[1];
	db1.password   = argv[2];
	break;
	
      case 11:
	// Universal type 4 driver
		
	db1.alias      = argv[1];
  	db1.server     = argv[2];
	db1.portNumber = Integer.valueOf( argv[3] ).intValue();
	db1.userId     = argv[4];
	db1.password   = argv[5];
		
	db2.alias      = argv[6];
        db2.server     = argv[7];
	db2.portNumber = Integer.valueOf( argv[8] ).intValue();
	db2.userId     = argv[9];
	db2.password   = argv[10];
	break;
	
      default:  //throw exception
     	throwUsageException();
	break;
    }		

  } // setup

  private static void throwUsageException() throws Exception
  {
    throw new Exception(
      "\n" +
      "Usage: prog_name [\"connection 1 information\" [\"connection 2 information\"]]\n" +
      "\n" +
      "  where \"connection N information\" is:\n" +
      "\n" +
      "    [dbAlias] [userId passwd] (use JDBC Universal type 2 driver)\n" +
      "    -u4 [dbAlias] server portNum userId passwd (use JDBC Universal type 4 driver)\n" +
      "\n" +
      "  dbAlias defaults to 'sample' for connection 1 and 'sample2' for connection 2" );
  }

  public static void createTable( Connection con )
  {
    System.out.println();
    System.out.println(
      "  CREATE TABLE books(title VARCHAR(21), price DECIMAL(7, 2))\n");

    try
    {
      Statement stmt = con.createStatement();
      stmt.executeUpdate("CREATE TABLE books(title VARCHAR(21), " +
                         "                    price DECIMAL(7, 2))");
      stmt.close();

      System.out.println("  COMMIT\n");
      con.commit();
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // createTable

  public static void dropTable( Connection con )
  {
    System.out.println("  DROP TABLE books\n");

    try
    {
      Statement stmt = con.createStatement();
      stmt.executeUpdate("DROP TABLE books");
      stmt.close();

      System.out.println("  COMMIT");
      con.commit();
    }
    catch (Exception e)
    {
      System.out.println(e);
    }
  } // dropTable
} // DbMCon
