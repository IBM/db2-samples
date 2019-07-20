//***************************************************************************
// (c) Copyright IBM Corp. 2010 All rights reserved.
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
// SOURCE FILE NAME: UDFcsvReader.java
//
// SAMPLE: Provide UDFs to be called by UDFcli.java
//
//         Parameter Style used in this program is "DB2GENERAL".
//         Dependency: This Java file has been written to compile with
//                     JDK 5+ (version 1.5). Please make sure you have
//                     an appropriate java compiler (javac) in your path.
//
//         Steps to run the sample with command line window:
//
//             1. Compile the source file with:
//                  javac UDFcsvReader.java
//             2. Erase the existing library/class files (if exists),
//                UDFcsvReader.class from the following path,
//                $(DB2PATH)/function.
//             3. Copy the class file, UDFcsvReader.class, from the 
//                current directory to the $(DB2PATH)/function.
//             4. Drop any functions that are already created
//                db2 -tvf DropGTF.db2
//             5. Catalog the table functions:
//                db2 -tvf CreateGTF.db2
//             6. Change file path to sample.csv in GTFqueries.db2, and
//                Issue query:
//                db2 -tvf GTFqueries.db2 
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


import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.BufferedReader;
import java.sql.Date;
import java.sql.Time;
import java.sql.Timestamp;
import java.net.URL;
import java.net.URLEncoder;
import COM.ibm.db2.app.UDF;


// This class has several Java Generic Table Functions
public class UDFcsvReader extends UDF 
{

  public String[] outRow;  // row to output next (just a buffer)
  public String   tempString;

  private InputStream in;
        
  // holds output column types, if needed.
  public String[] outCols;
        
  // Which element of in are we actually looking at?
  private int pos = 0;
        
  // A file reader. For a more robust implementation, a csv reader
  // can be used (available as open source)
  private BufferedReader reader;
        
  /**
   * Close all InputStreams
   * @throws IOException 
   */
  public void disconnect() throws IOException {
    in.close();
  }
        
  /** 
   * A Simple CSV Reader table function that takes a comma delimited file
   * and returns rows.
   * @param filename
   **/
  public void csvReadString(String filename) throws Exception
  {
    int numInputs = 1;
    switch (getCallType()) {
    case SQLUDF_TF_OPEN:
      in = new FileInputStream(filename);
      reader = new BufferedReader(new InputStreamReader(in));
      break;
    case SQLUDF_TF_FETCH: // read next row
      tempString = reader.readLine();
      if(tempString != null)
      {
        outRow = (String[]) tempString.split(",");
        return_row_as_str(numInputs);
      }
      else
      {
        this.disconnect();
        setSQLstate("02000");
        return;
      }
      break;
    case SQLUDF_TF_CLOSE: // close
      this.disconnect();
      break;
    } // end switch
  } // end csvReadString

  /**
   *  Sets the return columns as strings, and let's 
   *  DB2 figure out the appropriate datatype and 
   *  attempt to cast. An error will be throw if 
   *  the cast cannot be done. This function allows
   *  the schema of the CSV to be omitted as input
   *  to the table function.
   * @param numInputs
   */
  public void return_row_as_str(int numInputs) throws Exception
  {
    // how many input parameters are there?
    int n = numInputs;
                
    for(String s : outRow)
    {
      n = n+1;
      set(n, s.trim());
    }
  }
        
  /**
   * Parse a comma delimited string of column types
   * @param colString
   */
  public void parseColString(String colString)
  {
    outCols = colString.split(",");

    int i = 0;

    for(String c: outCols) {
      outCols[i] = outCols[i].trim();
      outCols[i] = outCols[i].toUpperCase();
      i++;
    }
  }
        
  /** 
   * A Simple CSV Reader table function that takes a delimited file,
   * a comma delimited string of column types, and returns rows.
   * @param filename
   * @param colString
   **/
  public void csvRead(String filename,String colString) throws Exception
  {
    int numInputs = 2;
    switch (getCallType()) {
    case SQLUDF_TF_OPEN:
      in = new FileInputStream(filename);
      reader = new BufferedReader(new InputStreamReader(in));
      parseColString(colString);
      break;
    case SQLUDF_TF_FETCH: // read next row
      tempString = reader.readLine();
      if(tempString != null)
      {
        outRow = (String[]) tempString.split(",");
        return_row(numInputs);
      }
      else
      {
        this.disconnect();
        setSQLstate("02000");
        return;
      }
      break;
    case SQLUDF_TF_CLOSE: // close
      this.disconnect();
      break;
    } // end switch
  } // end csvRead

  /**
   * Return a row.
   */
  public void return_row(int numInputs) throws Exception
  {
    // Get next row from HDFS (input)
                
    // how many input parameters are there?
    int n = numInputs;

    // decimal, in case we need it
    java.math.BigDecimal decimal;
                
    // Convert each column and set output
    for (int i = 0; i < outCols.length; i++) {
      // Get metadata (column type)
      String db2type = outCols[i];
                        
      // parameter number to write back into in set()
      n = n + 1;

      // Cast data to expected type and call a set
      if (db2type.startsWith("SMALLINT")) {
        set(n, Short.parseShort(outRow[i].trim()));
      } else if (db2type.startsWith("INTEGER")) {
        set(n, Integer.parseInt(outRow[i].trim()));
      } else if (db2type.startsWith("BIGINT")) {
        set(n, Long.parseLong(outRow[i].trim()));
      } else if (db2type.startsWith("REAL")) {
        set(n, Float.parseFloat(outRow[i].trim()));
      } else if (db2type.startsWith("DOUBLE")) {
        set(n, Double.parseDouble(outRow[i].trim()));
      } else if (db2type.startsWith("DECIMAL")) {
        decimal = new java.math.BigDecimal(outRow[i].trim());
        set(n, decimal);
      } else if (db2type.startsWith("NUMERIC")) {
        decimal = new java.math.BigDecimal(outRow[i].trim());
        set(n, decimal);
      } else if (db2type.startsWith("CHAR") || db2type.startsWith("VARCHAR") || 
          db2type.startsWith("GRAPHIC") || db2type.startsWith("VARGRAPHIC")) {
        set(n, outRow[i].trim());
      } else if (db2type.startsWith("DATE")) {
        set(n, Date.parse(outRow[i].trim()));
      } else if (db2type.startsWith("TIME")) {
        set(n, Time.parse(outRow[i].trim()));
      } else if (db2type.startsWith("TIMESTAMP")) {
        set(n, Timestamp.parse(outRow[i].trim()));
      } else {
        // do something ... CLOB or so
        set(n, outRow[i]);
      }
    } // end for each output column
  } // end return_row

  /**
   * A Http CSV Reader table function that takes a hostname, port, and filename
   * and returns rows.
   * @param filename
   **/
  public void httpCsvReadString(String hostname, int port, String filename) throws Exception
  {
    int numInputs = 3;
    switch (getCallType()) {
    case SQLUDF_TF_OPEN:
      URL stream = new URL("http://" + hostname + ":" + port +  filename);
      in = stream.openStream();
      reader = new BufferedReader(new InputStreamReader(in));
      break;
    case SQLUDF_TF_FETCH: // read next row
      tempString = reader.readLine();
      if(tempString != null)
      {
        outRow = (String[]) tempString.split(",");
        return_row_as_str(numInputs);
      }
      else
      {
        this.disconnect();
        setSQLstate("02000");
        return;
      }
      break;
    case SQLUDF_TF_CLOSE: // close
      this.disconnect();
      break;
    } // end switch
  } // end httpCsvReadString

  /**
   * A hadoop CSV Reader table function that takes a hostname, port, and 
   * filename and returns rows.
   * @param filename
   **/
  public void hadoopCsvReadString(String hostname, int port, String filename) throws Exception
  {
    int numInputs = 3;
    switch (getCallType()) {
    case SQLUDF_TF_OPEN:
      URL stream = new URL("http://" + hostname + ":" + port + "/data" + filename);
      in = stream.openStream();
      reader = new BufferedReader(new InputStreamReader(in));
      break;
    case SQLUDF_TF_FETCH: // read next row
      tempString = reader.readLine();
      if(tempString != null)
      {
        outRow = (String[]) tempString.split(",");
        return_row_as_str(numInputs);
      }
      else
      {
        this.disconnect();
        setSQLstate("02000");
        return;
      }
      break;
    case SQLUDF_TF_CLOSE: // close
      this.disconnect();
      break;
    } // end switch
  } // end hadoopCsvReadString
} // end UDFcsvReader

