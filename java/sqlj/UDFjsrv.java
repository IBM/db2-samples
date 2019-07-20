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
// SOURCE FILE NAME: UDFjsrv.java
//
// SAMPLE: Provide UDFs to be called by UDFjcli.sqlj
//
//         Parameter Style used in this program is "JAVA".
//
//         Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system, 
//            do the following:
//            1. Update makefile with a valid (userid,) password and
//               an available port number.
//            2. Compile the server source file UDFjsrv.java (this will also 
//               compile the Utility file, Util.sqlj, erase the existing 
//               library/class file and copy the newly compiled class file,
//               UDFjsrv.class from the current directory to the 
//               $(DB2PATH)\function directory):
//                 nmake/make UDFjsrv
//            3. Compile the client source file UDFcli (this will also call
//               the script 'udfjcat' to create and catalog the UDFs):
//                 nmake/make UDFjcli
//            4. Run the client UDFjcli:
//                 java UDFjcli
//
//         II) If you don't have a compatible make/nmake program on your 
//             system, do the following:
//             1. Compile the server source file with the following command:
//                  javac UDFjsrv.java
//             2. Erase the existing library/class files (if exists), 
//                UDFsrv.class from the $(DB2PATH)\function directory.
//             3. copy the class files, UDFsrv.class from the current
//                directory to the $(DB2PATH)\function.
//             4. Register/catalog the UDFs with:
//                  udfjcat
//             5. Compile the utility file with the following command:
//                  sqlj Util.sqlj
//             6. Update bldsqljs and bldsqlj build files with a valid userid
//                and password.
//             7. Build the SQLj UDFs with with:
//                  bldsqlj UDFjcli
//             8. Run UDFcli with:
//                  java UDFjcli
//
// OUTPUT FILE: UDFjcli.out (available in the online documentation)
//***************************************************************************
//
// For more information on the sample programs, see the README file.
//
// For information on developing SQLJ applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//     http://www.software.ibm.com/data/db2/udb/ad
//**************************************************************************/

import java.lang.*; // for String class
import java.io.*; // for ...Stream classes

public class UDFjsrv
{
  // scalar UDF
  public static double scalarUDF(String inJob, double inSalary)
  throws Exception
  {
    double outNewSalary = 0.00;

    if (inJob.equals("Mgr  "))
    {
      outNewSalary = inSalary * 1.20;
    }
    else if (inJob.equals("Sales"))
    {
      outNewSalary = inSalary * 1.10;
    }
    else
    {
      // Job is clerk
      outNewSalary = inSalary * 1.05;
    }
    // set the output value
    return outNewSalary;
  }

}

