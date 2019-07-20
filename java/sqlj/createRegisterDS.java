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
// SOURCE FILE NAME: createRegisterDS.java
//
// SAMPLE: Create & Register DataSources as specfied by the property files
//
//         The DataSources will be created in the temp directory.
//         It uses File System SPI - Creates a .bindings file in
//         temp directory C:/temp  (as defined in jndi.properties)
//
//         Use this & one of the 3 property files to create :
//         DS1.prop: jdbc/defaultDataSource 
//         DS2.prop: jdbc/DB2SimpleDataSource_ds1  
//         DS3.prop: jdbc/DB2SimpleDataSource_ds2 
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

import java.sql.*;
import com.ibm.db2.jcc.DB2SimpleDataSource;
import javax.naming.*;
import java.util.*;
import java.io.*;

public class createRegisterDS
{
  public static void main (String args[]) 
  {
    if (args.length != 1)
    {
         System.out.println( "Usage: createRegisterDS <name of Datasource Property File> ");
         return;
    }
    createRegisterDS crds = new  createRegisterDS();
		System.out.println ("");

    crds.runThis(args[0]);
    System.out.println(">>>Registering DataSource using Property File: " + args[0] );
    System.out.println(">>>Done Register");
		System.out.println ("");
  }
  private void runThis(String args) 
  {
    try
    {
         
      registerDS( args, new InitialContext());
    }
    catch (Exception e)
    {
      System.err.println ("Problem with registration: " + e.getMessage());
      e.printStackTrace();
      return;
    }
  }
  private void registerDS( String DSname, Context registry) 
          throws Exception
  {
        DB2SimpleDataSource dataSource = new DB2SimpleDataSource();
        Properties prop = new  Properties();
        FileInputStream dsPropFile = null;
        try
        {
          dsPropFile = new FileInputStream( DSname);
        }
        catch (FileNotFoundException fe)
        {
           System.out.println (fe.getMessage());
           throw fe;
        }
        prop.load( dsPropFile );

        dataSource.setServerName (prop.getProperty("serverName"));

        String portNum = prop.getProperty("portNumber");
        int portNo = (new Integer(portNum)).intValue() ;
        dataSource.setPortNumber (portNo);


        dataSource.setDatabaseName (prop.getProperty("databaseName"));
        dataSource.setUser (prop.getProperty("userName"));
        dataSource.setPassword (prop.getProperty("password"));
        String DSName =  prop.getProperty("dataSourceName");
        dataSource.setDataSourceName (DSName);
        String dType = prop.getProperty("driverType");
        int drType = (new Integer(dType)).intValue() ;
        dataSource.setDriverType(drType);

        String sMech = prop.getProperty("securityMechanism");
        short secMech =  (new Integer(sMech)).shortValue();
        dataSource.setSecurityMechanism (secMech);

        dataSource.setKerberosServerPrincipal (
             prop.getProperty("kerberosPrincipal"));

        registry.rebind(DSName, dataSource);
  }
}
