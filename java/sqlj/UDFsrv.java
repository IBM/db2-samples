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
// SOURCE FILE NAME: UDFsrv.java
//
// SAMPLE: Provide UDFs to be called by UDFcli.sqlj
//
//         Parameter Style used in this program is "DB2GENERAL".
//
//         Steps to run the sample with command line window:
//         I) If you have a compatible make/nmake program on your system, 
//            do the following:
//            1. Update makefile with a valid (userid,) password and 
//               an available port number.
//            2. Compile the server source file UDFsrv.java (this will also 
//               compile the Utility file, Util.sqlj, erase the existing 
//               library/class files and copy the newly compiled class files,
//               UDFsrv.class and Person.class from the current directory 
//               to the $(DB2PATH)\function directory):
//                 nmake/make UDFsrv
//            3. Compile the client source file UDFcli (this will also call
//               the script 'udfcat' to create and catalog the UDFs):
//                 nmake/make UDFcli
//            4. Run the client UDFcli:
//                 java UDFcli
//
//         II) If you don't have a compatible make/nmake program on your 
//             system, do the following:
//             1. Compile the server source file with the following command:
//                  javac UDFsrv.java
//             2. Erase the existing library/class files (if exists), 
//                UDFsrv.class and Person.class from the following path,
//                $(DB2PATH)\function. 
//             3. copy the class files, UDFsrv.class and Person.class from 
//                the current directory to the $(DB2PATH)\function.
//             4. Register/catalog the UDFs with:
//                  udfcat
//             5. Compile the utility file with the following command:
//                  sqlj Util.sqlj
//             6. Update bldsqljs and bldsqlj build files with a valid userid
//                and password.
//             7. Build the SQLj UDFs with with:
//                  bldsqlj UDFcli
//             8. Run UDFcli with:
//                  java UDFcli
//
// OUTPUT FILE: UDFcli.out (available in the online documentation)
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
import COM.ibm.db2.app.UDF; // UDF classes

// Java user-defined functions are in this class
public class UDFsrv extends UDF
{
  // SCRATCHPAD scalar UDF
  public void scratchpadScUDF(int outCounter) throws Exception
  {
    int intCounter = 0;
    byte[] scratchpad = getScratchpad();

    // variables to read from SCRATCHPAD area
    ByteArrayInputStream byteArrayIn = new ByteArrayInputStream(scratchpad);
    DataInputStream dataIn = new DataInputStream(byteArrayIn);

    // variables to write into SCRATCHPAD area
    byte[] byteArrayCounter;
    int i;
    ByteArrayOutputStream byteArrayOut = new ByteArrayOutputStream(10);
    DataOutputStream dataOut = new DataOutputStream(byteArrayOut);

    switch (getCallType())
    {
      case SQLUDF_FIRST_CALL:
        // initialize data
        intCounter = 1;
        // save data into SCRATCHPAD area
        dataOut.writeInt(intCounter);
        byteArrayCounter = byteArrayOut.toByteArray();
        for (i = 0; i < byteArrayCounter.length; i++)
        {
          scratchpad[i] = byteArrayCounter[i];
        }
        setScratchpad(scratchpad);
        break;
      case SQLUDF_NORMAL_CALL:
        // read data from SCRATCHPAD area
        intCounter = dataIn.readInt();
        // work with data
        intCounter = intCounter + 1;
        // save data into SCRATCHPAD area
        dataOut.writeInt(intCounter);
        byteArrayCounter = byteArrayOut.toByteArray();
        for (i = 0; i < byteArrayCounter.length; i++)
        {
          scratchpad[i] = byteArrayCounter[i];
        }
        setScratchpad(scratchpad);

        break;
    }
    // set the output value
    set(1, intCounter);

  } // scratchpadScUDF

  public void scUDFReturningErr(double inOperand1,
                                double inOperand2,
                                double outResult)
  throws Exception
  {
    if (inOperand2 == 0.00)
    {
      setSQLstate("38999");
      setSQLmessage("DIVIDE BY ZERO ERROR");
    }
    else
    {
      outResult = inOperand1 / inOperand2;
    }
    set(3, outResult);
  } // scUDFReturningErr

  // variable for tableUDF
  static final Person[] staff =
  {
    new Person("Pearce" , "Mgr" , 17300.00),
    new Person("Wagland", "Sales", 15000.00),
    new Person("Davis" , "Clerk", 10000.00)};

  // the table UDF
  public void tableUDF(double inSalaryFactor,
                       String outName,
                       String outJob,
                       double outNewSalary)
  throws Exception
  {
    int intRow = 0;
    byte[] scratchpad = getScratchpad();

    // variables to read from SCRATCHPAD area
    ByteArrayInputStream byteArrayIn = new ByteArrayInputStream(scratchpad);
    DataInputStream dataIn = new DataInputStream(byteArrayIn);

    // variables to write into SCRATCHPAD area
    byte[] byteArrayRow;
    int i;
    ByteArrayOutputStream byteArrayOut = new ByteArrayOutputStream(10);
    DataOutputStream dataOut = new DataOutputStream(byteArrayOut);

    switch (getCallType())
    {
      case SQLUDF_TF_FIRST:
        // do initialization for the whole statement
        // (the statement may invoke tableUDF more than once)
        break;
      case SQLUDF_TF_OPEN:
        // do initialization valid for this invokation of tableUDF
        intRow = 1;
        // save data in SCRATCHPAD area
        dataOut.writeInt(intRow);
        byteArrayRow = byteArrayOut.toByteArray();
        for (i = 0; i < byteArrayRow.length; i++)
        {
          scratchpad[i] = byteArrayRow[i];
        }
        setScratchpad(scratchpad);
        break;
      case SQLUDF_TF_FETCH:
        // get data from SCRATCHPAD area
        intRow = dataIn.readInt();

        // work with data
        if (intRow > staff.length)
        {
          // Set end-of-file signal and return
          setSQLstate("02000");
        }
        else
        {
          // Set the current output row and increment the row number
          set(2, staff[intRow - 1].getName());
          set(3, staff[intRow - 1].getJob());
          set(4, staff[intRow - 1].getSalary() * inSalaryFactor);
          intRow++;
        }

        // save data in SCRATCHPAD area
        dataOut.writeInt(intRow);
        byteArrayRow = byteArrayOut.toByteArray();
        for (i = 0; i < byteArrayRow.length; i++)
        {
          scratchpad[i] = byteArrayRow[i];
        }
        setScratchpad(scratchpad);
        break;
      case SQLUDF_TF_CLOSE:
        break;
      case SQLUDF_TF_FINAL:
        break;
    }
  } // tableUDF
} // UDFsrv class

// the class Person is used by the table UDF
class Person
{
  String name;
  String job;
  double salary;

  Person()
  {
    name = null;
    job = null;
    salary = 0.00;
  }

  Person(String n , String j, double s)
  {
    name = n;
    job = j;
    salary = s;
  }

  public String getName()
  {
    return name;
  }

  public String getJob()
  {
    return job;
  }

  public double getSalary()
  {
    return salary;
  }
} // Person class

