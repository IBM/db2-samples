/**********************************************************************
 *
 *  Source File Name = UserMappingSetupLDAP.java
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
import java.util.Properties;
import com.ibm.ii.um.*;

/**
 * One time configuration setup for the LDAP plugin sample. 
 * It is a standalone Java program that can be invoked from command line. 
 */

public class UserMappingSetupLDAP 
{
  // set up the input stream
  BufferedReader bin;

  // set up the ouput stream
  private OutputStream configFile;

  // configuration file path default to current directory
  private String configFilePath = System.getProperty("user.dir");
  // configuration file name must match the plugin name with .cfg suffix
  private String configFileName = UserMappingRepositoryLDAP.class.getName() + ".cfg";

  // hostname of LDAP server
  private String hostname = null;
  // portnumber of LDAP server
  private String portnumber = null;
  // base DN in LDAP server's directory to start search
  private String baseDN = null;
  // userid and password to bind with LDAP server
  private String userid = null;
  private String password = null;

  // Is LDAP server SSL enabled?
  private String serverSSLEnabled = null;
  // keystore and password for LDAP server's CA certificate
  private String serverCAcertStore = null;
  private String serverCAcertStorePassword = null;

  // Is LDAP client/server mutual authentication required?
  private String mutualAuthRequired = null;
  // keystore and password for LDAP client's public/private keys and certificate
  private String clientKeystore = null;
  private String clientKeystorePassword = null;

  public UserMappingSetupLDAP() throws IOException {
    bin = new BufferedReader(new InputStreamReader(System.in));
    try {
      configFile = new FileOutputStream(configFilePath + 
                                        File.separatorChar +
                                        configFileName);
    }
    catch (IOException ioe){
      System.out.println("Exception while creating the config file");
      ioe.printStackTrace();
    }
  }

  public static void main(String args[]) throws Exception {
    UserMappingSetupLDAP mySetup = new UserMappingSetupLDAP();
    try {
      mySetup.printWelcome();
      mySetup.askHostname();
      mySetup.askPortnumber();
      mySetup.askBaseDN();
      mySetup.askUseridPassword();
      mySetup.askServerSSLEnabled();
      mySetup.askMutualAuthRequired(); 
      mySetup.writeToFile();      
      mySetup.printBye();
    }
    catch (Exception e)
    {
      System.out.println(e.getMessage());
      e.printStackTrace();            
    }
  }
  
  private void printWelcome()
  {
    System.out.println("");
    System.out.println("");
    System.out.println("====================================================");
    System.out.println("      WELCOME TO THE SETUP PROGRAM OF               ");
    System.out.println("     WS II USER MAPPING PLUG-IN LDAP SAMPLE         ");
    System.out.println("====================================================");
    System.out.println("");
    System.out.println("PURPOSE: Set up the required configuration parameters.");
    System.out.println("");
    System.out.println("USAGE: java UserMappingSetupLDAP");
    System.out.println("       Enter the value of the requested parameter");
    System.out.println("       To proceed to the next parameter, press ENTER.");
    System.out.println("       To quit at anytime, press Ctrl/C.");
    System.out.println("");
    System.out.println("       The config file path defaults to the current directory.");
    System.out.println("       The config file name matches the plugin name with suffix .cfg");
    System.out.println("       The config parameter values are written into the config file.");
    System.out.println("       Passwords are encrypted in the config file.");
    System.out.println("       To change config parameter values, run this setup program again.");
    System.out.println("");
    System.out.println("====================================================");
    System.out.println("        PLEASE INPUT THE SETUP PARAMETERS:          ");
    System.out.println("====================================================");
    System.out.println("");
  }
  
  private void printBye()
  {
    System.out.println("====================================================");
    System.out.println("        CONFIGURATION SETUP FINISHED SUCCESSFULLY!  ");
    System.out.println("====================================================");
  }
  
  /**
   * Requests the user to input the hostname and does syntax check on it. 
   * @throws IOException  If there is a problem with reading the user's 
   *                      input from the command line
   */
  private void askHostname() throws IOException {
    boolean ready      = false;
    String  tempString = null;
    try {
      while (!ready) {
        System.out.print("HOST NAME of LDAP server, e.g., daytona.svl.ibm.com --> ");
        if ((tempString = bin.readLine()) != null &&
             tempString.length() != 0 && 
            tempString.matches("[^\\s,<>\\?]+?\\.?[^\\s,<>\\?]+")) { 
          hostname = tempString;
          ready = true;        
        }
        else {
          System.out.println("-- Wrong host name syntax (DNS or IPv4 formats), try again --");
        }    
      } // end of while 
    }  
    catch (IOException ioe) {
      System.out.println("Exception while reading hostname.");
      throw(ioe);
    }
  }
  
  /**
   * Requests the user to input the port number and does syntax check on it.
   * @throws IOException  If there is a problem with reading the user's 
   *                      input from the command line
   */
  private void askPortnumber() throws IOException {
    boolean ready      = false;
    String  tempString = null;
    try {
      while (!ready) {
        System.out.print("PORT NUMBER of LDAP server, e.g., 389 --> ");
        if ((tempString = bin.readLine()) != null && 
             tempString.length() != 0 &&
            tempString.matches("[0-9]+")) { 
          portnumber = tempString;
          ready = true;
        }
        else {
          System.out.print("-- Wrong port number syntax (from 0 to 65535), try again -- ");
        }     
      } // end of while  
    }
    catch (IOException ioe) {
      System.out.println("Exception while reading port number.");
      throw(ioe);
    }
  }
    
  /**
   * Requests the user to input the baseDN. 
   * The baseDN represents the root of the LDAP subtree to start the search
   * @throws IOException  If there is a problem with reading the user's 
   *                      input from the command line
   */
  private void askBaseDN() throws IOException {
    boolean ready      = false;
    String  tempString = null;
    try {
      while (!ready) {
        System.out.print("BASE DN of LDAP subtree, e.g., ou=ii,o=ibm,c=us --> ");
        if ((tempString = bin.readLine()) != null &&
            tempString.length() != 0) {
          baseDN = tempString;
          ready = true;
        }
        else {
          System.out.println(" -- No BASE DN provided, try again! -- ");
        }  
      } // end of while    
    }  
    catch (IOException ioe) {
      System.out.println("Exception while reading base DN.");
      throw(ioe);
    }
  }     

  /**
   * Requests the user to input the userid and password to bind to LDAP server
   * @throws IOException  If there is a problem with reading the user's 
   *                      input from the command line
   */
  private void askUseridPassword() throws Exception {
    boolean ready                  = false;
    String  tempString             = null;
    UserMappingCryptoLDAP myCrypto = null; 

    try {
      while (!ready) {
        System.out.print("USERID to bind to LDAP Server, e.g., cn=root --> ");
        if ((tempString = bin.readLine()) != null &&
            tempString.length() != 0) {	
          userid = tempString;
          ready = true;
        }
        else {
          System.out.println(" -- No userid provided, try again -- ");
        }  
      } // end of while    
    }  
    catch (IOException ioe) {
      System.out.println("Exception while reading userid.");
      throw(ioe);
    }

    try {
      myCrypto = new UserMappingCryptoLDAP();
    }
    catch (Exception e) {
      System.out.println("Exception while getting crypto.");
      throw(e);
    }
       
    try {
      ready = false;
      tempString = null;
      while (!ready) {
        System.out.print("PASSWORD for the userid --> ");
        if ((tempString = bin.readLine()) != null &&
            tempString.length() != 0) { 
          password = myCrypto.encode(myCrypto.encrypt(myCrypto.getBytes(tempString.toCharArray())));
          ready = true;
        }
        else {
          System.out.print("-- No password provided, try again -- ");
        }
      } // end of while    
    }  
    catch (Exception e) {
      System.out.println("Exception while reading password.");
      throw(e);
    }
  }
    
  /**
   * Requests the user to input if SSL is enabled for the LDAP Server.
   * If SSL is enabled, all communication will be encrypted and the 
   * authentication during SSL handshake requires at least the server 
   * to present its CA certificate.
   * @throws IOException  If there is a problem with reading the user's 
   *                      input from the command line
   */
  private void askServerSSLEnabled() throws Exception {
    boolean ready      = false;
    String  tempString = null;
    UserMappingCryptoLDAP myCrypto = null;

    try {
      while (!ready) {
        System.out.print("Is LDAP server SSL enabled? y or n --> ");
        if ((tempString = bin.readLine()) != null && 
            tempString.length() != 0 &&
            tempString.matches("[yYnN]"))  {
          serverSSLEnabled = tempString; 
	  ready = true;
        }
        else {
          System.out.print(" -- No LDAP server SSL info provided, try again -- ");
        }                   
      } // end of while    
    }  
    catch (IOException ioe) {
      System.out.println("Exception while reading LDAP server SSL info.");
      throw(ioe);
    }
       
    if (serverSSLEnabled.matches("[yY]")) {
      try {
        ready = false;
        tempString = null;
        while (!ready) {
          System.out.print("KEYSTORE with LDAP server's CA certificate, e.g., /myhome/myjdk/jre/lib/security/cacerts   --> ");
          if ((tempString = bin.readLine()) != null &&
              tempString.length() != 0) {	
            serverCAcertStore = tempString;
            ready = true;
          }
          else {
            System.out.println(" -- No LDAP server CA certificate keystore provided, try again -- ");
          }  
        } // end of while    
      }  
      catch (IOException ioe) {
        System.out.println("Exception while reading LDAP server CA certificate keystore.");
        throw(ioe);
      }
    
      try {
        myCrypto = new UserMappingCryptoLDAP();
      }
      catch (Exception e) {
        System.out.println("Exception while getting crypto.");
        throw(e);
      }

      try {
        ready = false;
        tempString = null;
        while (!ready) {
          System.out.print("PASSWORD for the LDAP server CA certificate keystore --> ");
          if ((tempString = bin.readLine()) != null &&
              tempString.length() != 0) { 
            serverCAcertStorePassword = myCrypto.encode(myCrypto.encrypt(myCrypto.getBytes(tempString.toCharArray())));
            ready = true;
          }
          else {
            System.out.print("-- No LDAP server CA certificate keystore password provided, try again -- ");
          }
        } // end of while    
      }  
      catch (Exception e) {
        System.out.println("Exception while reading LDAP server CA certificate keystore password.");
        throw(e);
      }
    } // end of if
  }
    
  /**
   * Requests the user to input if mutual authentication is required
   * between LDAP client and LDAP server. This mutual authentication 
   * is valid only if the LDAP server is SSL enabled plus client 
   * authentication is required as well. It requires the LDAP client 
   * to present its keystore with public/private key pair and certificate.
   * @throws IOException  If there is a problem with reading the user's 
   *                      input from the command line
   */
  private void askMutualAuthRequired() throws Exception {
    boolean ready      = false;
    String  tempString = null;
    UserMappingCryptoLDAP myCrypto = null;

    if (serverSSLEnabled.matches("[yY]")) {
      try {
        while (!ready) {
          System.out.print("LDAP client/server mutual authentication required? y or n --> ");
          if ((tempString = bin.readLine()) != null && 
              tempString.length() != 0 &&
              tempString.matches("[yYnN]"))  {
            mutualAuthRequired = tempString; 
	    ready = true;
          }
          else {
            System.out.print(" -- No LDAP client/server mutual authentication info provided, try again -- ");
          }                   
        } // end of while    
      }  
      catch (IOException ioe) {
        System.out.println("Exception while reading LDAP client/server mutual authentication info.");
        throw(ioe);
      }

      if (mutualAuthRequired.matches("[yY]")) {
        try {
          ready = false;
          tempString = null;
          while (!ready) {
            System.out.print("KEYSTORE with LDAP client's public/private keys and certificate, e.g., /myhome/clientkey.jks   --> ");
            if ((tempString = bin.readLine()) != null &&
                tempString.length() != 0) {	
              clientKeystore = tempString;
              ready = true;
            }
            else {
              System.out.println(" -- No LDAP client keystore provided, try again -- ");
            }  
          } // end of while    
        }  
        catch (IOException ioe) {
          System.out.println("Exception while reading LDAP client keystore.");
          throw(ioe);
        }
    
        try {
          myCrypto = new UserMappingCryptoLDAP();
        }
        catch (Exception e) {
          System.out.println("Exception while getting crypto.");
          throw(e);
        }

        try {
          ready = false;
          tempString = null;
          while (!ready) {
            System.out.print("PASSWORD for LDAP client keystore --> ");
            if ((tempString = bin.readLine()) != null &&
                tempString.length() != 0) { 
              clientKeystorePassword = myCrypto.encode(myCrypto.encrypt(myCrypto.getBytes(tempString.toCharArray())));
              ready = true;
            }
            else {
              System.out.print("-- No LDAP client keystore password provided, try again -- ");
            }
          } // end of while    
        }  
        catch (Exception e) {
          System.out.println("Exception while reading LDAP client keystore password.");
          throw(e);
        }
      } // end of if mutualAuthRequired
    } // end of if serverSSLEnabled
  }
     
  private void writeToFile() throws Exception {
    try {
      Properties properties = new Properties();
      properties.setProperty("hostname", hostname);
      properties.setProperty("portnumber", portnumber);
      properties.setProperty("baseDN", baseDN);
      properties.setProperty("userid", userid);
      properties.setProperty("password", password);
      properties.setProperty("serverSSLEnabled", serverSSLEnabled);
      if (serverSSLEnabled.matches("[yY]")) {
        properties.setProperty("serverCAcertStore", serverCAcertStore);
        properties.setProperty("serverCAcertStorePassword", serverCAcertStorePassword);
        properties.setProperty("mutualAuthRequired", mutualAuthRequired);
        if (mutualAuthRequired.matches("[yY]")) {
          properties.setProperty("clientKeystore", clientKeystore);
          properties.setProperty("clientKeystorePassword", clientKeystorePassword);
        }
      }
      properties.store(configFile,null);     
      configFile.close();
    }
    catch (Exception e) {
      System.out.println("Exception while writing into the config file.");
      throw(e);
    }
  }
} 
