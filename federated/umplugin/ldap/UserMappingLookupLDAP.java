/**********************************************************************
 *
 *  Source File Name = UserMappingLookupLDAP.java
 *
 *  (C) COPYRIGHT International Business Machines Corp. 2003, 2004, 2005
 *  All Rights Reserved
 *  Licensed Materials - Property of IBM
 *
 *  US Government Users Restricted Rights - Use, duplication or
 *  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 *
 *  Operating System = all
 *
 ***********************************************************************/
import java.io.*;

import com.ibm.ii.um.*;

/**
 * This simple UserMappingLookupLDAP class is used to test if the
 * UserMappingRepositoryLDAP is implemented correctly.
 */
public class UserMappingLookupLDAP {
	
  private static String configFilePath = System.getProperty("user.dir");

  private static String iiInstanceName = null;
  private static String iiDatabaseName = null;
  private static String iiRemoteServerName = null;
  private static String iiAuthID = null;

  /**
   * The main function gets input parameters,
   * looks up the user mapping entry, and print them out.
   */
  public static void main(String[] args) {
    // Lookup
    if (args.length == 0) {
      printUsage();
      System.exit(-1);
    }

    // Lookup -h
    if (args[0].equalsIgnoreCase("-h")) {
      printUsage();
      System.exit(-1);
    }

    // Lookup -server <IIRemoteServerName> -authid <IIAuthid>
    // Mandatory parameter -server
    if (!args[0].equalsIgnoreCase("-server")) {          
        System.out.println("Error: Parameter -server is missing");
      printUsage();
      System.exit(-1);
    }    
    else 
    if (args.length > 1 && 
        args[1] != null) {
      iiRemoteServerName = args[1];
    } 
    else {
      System.out.println("Error: Parameter <IIRemoteServerName> is missing");
      printUsage();
      System.exit(-1);
    }
        
    // Mandatory parameter -authid
    if (!(args.length > 2 &&
          args[2].equalsIgnoreCase("-authid"))) {
      System.out.println("Error: Parameter -authid is missing");
      printUsage();
      System.exit(-1);
    }    
    else 
    if (args.length > 3  && 
        args[3] != null) {
      iiAuthID = (String) args[3];
    }
    else {
      System.out.println("Error: Parameter <IIAuthid> is missing");
      printUsage();
      System.exit(-1);
    }
    
    // Optional paramter -instance
    if (args.length > 4 ) {
      if (!args[4].equalsIgnoreCase("-instance")) {
        System.out.println("Error: Invalid parameter" + args[4]);
        printUsage();
        System.exit(-1);
      }
      else 
      if (args.length > 5 &&
          args[5] != null) {
        iiInstanceName = (String) args[5];
      }   
      else {
        System.out.println("Error: Parameter <IIInstanceName> is missing.");
        printUsage();
        System.exit(-1);
      }
        	
      if (args.length > 6) {
        if (!args[6].equalsIgnoreCase("-database")) {
          System.out.println("Error: Invalid parameter" + args[6]);
          printUsage();
          System.exit(-1);
        }
        else
        if (args.length > 7 &&
            args[7] != null) {
          iiDatabaseName = (String) args[7];
        }
        else {
          System.out.println("Error: Parameter <IIDatabaseName> is missing.");
          printUsage();
          System.exit(-1);
        }
      }
    }

    System.out.println("IIInstance=" + iiInstanceName);
    System.out.println("IIDatabase=" + iiDatabaseName);
    System.out.println("IIRemoteServerName=" + iiRemoteServerName);
    System.out.println("IIAuthID=" + iiAuthID);
        
    UserMappingRepository myLDAP = null;
    UserMappingEntry myUM = null;

    try {
      // initialize UserMappingRepository subclass
      myLDAP = new UserMappingRepositoryLDAP(configFilePath);
    }
    catch (UserMappingException e) {
      System.out.println("ErrorNumber: " + e.getErrorNumber());   
      System.out.println("ErrorMessage: " + e.getErrorMessage());
      System.exit(-1);
    }
 
    try {
      // call the same lookupUM that II is going to call
      myUM = myLDAP.lookupUM(myLDAP,
                             iiInstanceName,
                             iiDatabaseName,
                             iiRemoteServerName,
                             iiAuthID);
    }
    catch (UserMappingException e) {
      System.out.println("ErrorNumber: " + e.getErrorNumber());   
      System.out.println("ErrorMessage: " + e.getErrorMessage());
      System.exit(-1);
    }

    // extract the options that II is going to extract     
    UserMappingOption option = myUM.getFirstOption();
    while (option != null) {
      System.out.println(option.getName() + "=" + option.getValue());
      option = option.getNextOption();
    }  
  }   
     
  /**
   * Print command usage of UserMappingLookupLDAP
   */
  private static void printUsage() {
  	System.out.println("================================================");
  	System.out.println("    UserMappingLookupLDAP Usage                 ");
  	System.out.println("================================================");
  	System.out.println("UserMappingLookupLDAP -h");
  	System.out.println(">> Display help information.");
  	System.out.println("");
  
  	System.out.println("UserMappingLookupLDAP -server <IIRemoteServerName> ");
  	System.out.println("                      -authID <IIAuthID>");
  	System.out.println("                     [-instance <IIInstanceName>]");
  	System.out.println("                     [-database <IIDatabaseName>]");
  	System.out.println(">> Displays a specific user mapping, ");
  	System.out.println(">> -server and -authid are mandatory paramters.");
  	}
}
