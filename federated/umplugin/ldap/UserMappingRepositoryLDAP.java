/**********************************************************************
*
*  Source File Name = UserMappingRepositoryLDAP.java
*
*  (C) COPYRIGHT International Business Machines Corp. 2003, 2004
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
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.StringWriter;
import java.lang.Exception;
import java.util.Hashtable;
import java.util.Properties;
import javax.naming.*;
import javax.naming.directory.*;
import com.ibm.ii.um.*;

/*
 * Sample subclass of UserMappingRepository that uses an LDAP directory
 * as the repository for storing and retrieving user mapping entries.
 */

public class UserMappingRepositoryLDAP extends UserMappingRepository {
    
  // ==================
  // CONFIGURATION FILE
  // ==================  
  // configuration file name default to this class name with suffix .cfg
  private String configFileName = UserMappingRepositoryLDAP.class.getName() + ".cfg";  

  // ========================
  // CONFIGURATION PARAMETERS
  // ========================
  private String hostname   = null;
  private String portnumber = null;
  private String baseDN     = null;
  private String userid     = null;
  private String password   = null;

  private String serverSSLEnabled          = null;
  private String serverCAcertStore         = null;
  private String serverCAcertStorePassword = null;

  private String mutualAuthRequired     = null;
  private String clientKeystore         = null;
  private String clientKeystorePassword = null;     
   
  // ============================
  // LDAP CONTEXT AND ENVIRONMENT
  // ============================
  private DirContext ctx = null;
  private Hashtable  env = null;
  
  // =======================
  // LDAP OBJECT CLASS NAMES
  // =======================
  // LDAP object class name that represents a user entry. 
  private String UserObjectClassName = "inetOrgPerson"; 
  
  // LDAP object class name that represents a user mapping entry. 
  private String UserMappingObjectClassName = "IIUserMapping";   
  
  // =========================
  // LDAP ATTRIBUTE TYPE NAMES
  // =========================  
  // LDAP attribute name that represents the II Authorization ID.
  private String UserAuthIDAttrName = "uid";
  
  // LDAP attribute type names that represent II user mapping properties.
  private String IIRemoteServerAttrName   = "IIRemoteServerName";
  private String IIInstanceAttrName       = "IIInstanceName";
  private String IIDatabaseAttrName       = "IIDatabaseName";
  private String IIRemoteAuthIDAttrName   = "uid";
  private String IIRemotePasswordAttrName = "IIRemotePassword";   

  /*
   * Instantiates the repository: 
   *   Instantiate the crypto, and read the configuration parameters. 
   * @throws UserMappingException If anything failed.
   */
  public UserMappingRepositoryLDAP(String configFilePath) throws UserMappingException {
    try {
      // Instantiate the crypto
      crypto = new UserMappingCryptoLDAP();	
       
      // Read properties file.
      Properties properties = new Properties();
      properties.load(new FileInputStream(configFilePath + 
                                          File.separatorChar +
                                          configFileName));

      // Get configuration parameter values 
      hostname   = properties.getProperty("hostname");        
      portnumber = properties.getProperty("portnumber");        
      baseDN     = properties.getProperty("baseDN");        
      userid     = properties.getProperty("userid");         
      password   = properties.getProperty("password");    
      serverSSLEnabled  = properties.getProperty("serverSSLEnabled");
      if (serverSSLEnabled.matches("[yY]")) {
        serverCAcertStore         = properties.getProperty("serverCAcertStore");
        serverCAcertStorePassword = properties.getProperty("serverCAcertStorePassword");
        mutualAuthRequired        = properties.getProperty("mutualAuthRequired"); 
        if (mutualAuthRequired.matches("[yY]")) {
          clientKeystore         = properties.getProperty("clientKeystore");
          clientKeystorePassword = properties.getProperty("clientKeystorePassword");
        }
      }
    }
    catch (Exception e) {
        throw new UserMappingException(UserMappingException.INITIALIZE_ERROR);
    }
  }
  
  /*
   * Connects to the repository
   * @throws UserMappingException If the connection or authentication failed. 
   */
  public void connect() throws UserMappingException {

    String LDAPURL = new String("ldap://" + 
                                hostname + ":" + 
                                portnumber + "/" +  
                                baseDN); 
    try {
      // retrieve required connection parameters
      env = new Hashtable();
      env.put(Context.INITIAL_CONTEXT_FACTORY, 
              "com.sun.jndi.ldap.LdapCtxFactory");
      env.put(Context.PROVIDER_URL, 
              LDAPURL);                        
      env.put(Context.SECURITY_AUTHENTICATION, 
              "simple");
      env.put(Context.SECURITY_PRINCIPAL, 
              userid);
      env.put(Context.SECURITY_CREDENTIALS, 
              new String(crypto.getChars(crypto.decrypt(crypto.decode(password)))));
        	
      if (serverSSLEnabled.matches("[yY]")) {
        env.put(Context.SECURITY_PROTOCOL, 
                "ssl");
        System.setProperty("javax.net.ssl.trustStore", 
                           serverCAcertStore);
        System.setProperty("javax.net.ssl.trustStorePassword", 
                           new String(crypto.getChars(crypto.decrypt(crypto.decode(serverCAcertStorePassword)))));

        if (mutualAuthRequired.matches("[yY]")) {
          env.put(Context.SECURITY_AUTHENTICATION,
                  "EXTERNAL");   
          System.setProperty("javax.net.ssl.keyStore", 
                             clientKeystore);
          System.setProperty("javax.net.ssl.keyStorePassword", 
                             new String(crypto.getChars(crypto.decrypt(crypto.decode(clientKeystorePassword)))));
        }
      }
            
      // connect and authenticate to LDAP server
      ctx = new InitialDirContext(env);
    }  
    catch (AuthenticationException e) {
      throw new UserMappingException(UserMappingException.AUTHENTICATION_ERROR);
    }
    catch (Exception e) {
      throw new UserMappingException(UserMappingException.CONNECTION_ERROR);
    }
  }

  /*
   * Disonnects from the repository.
   */
  public void disconnect() {
    try {
      ctx.close();
    }
    catch (NamingException e){}
  }
    
  /*
   * Fetches a user mapping from the repository. 
   * The um parameter contains detailed query information to determine 
   * which user mapping should be fetched. 
   * UserMappingOption will be created/added to contain the fetch result. 
   * @throws UserMappingException If no match found.
   */
  public void fetchUM(UserMappingEntry um) throws UserMappingException {
    
    String filter = null;
    SearchControls ctls = new SearchControls();

    NamingEnumeration userEntry = null;  
    NamingEnumeration userMappingEntry = null;  
    	
    try {
      // FIRST SEARCH: user entry
      String iiAuthID = um.getIIAuthID();

      // filter for correct user
      if (iiAuthID != null) {
        filter = ("(&("+ UserAuthIDAttrName + "=" + iiAuthID + ")(objectclass=" + UserObjectClassName + "))");
      }
      else {
        throw new UserMappingException(UserMappingException.INVALID_PARAMETER_ERROR);
      }

      // set search controls      	        
      ctls.setSearchScope(SearchControls.SUBTREE_SCOPE);
      String [] returnAttr1 = {UserAuthIDAttrName}; 
      ctls.setReturningAttributes(returnAttr1);

      // search
      try {
        userEntry = ctx.search("", filter, ctls);
      } 
      catch (SizeLimitExceededException e) {
      }
    
      String userEntryDN = ((SearchResult)userEntry.next()).getName();

      // SECOND SEARCH: find user mapping entry
      String iiRemoteServerName = um.getIIRemoteServerName();
      String iiInstanceName     = um.getIIInstanceName();
      String iiDatabaseName     = um.getIIDatabaseName();
        
      // filter for correct user mapping
      filter = null;
      if (iiRemoteServerName != null) {
        filter = ("(&("+ IIRemoteServerAttrName + "=" + iiRemoteServerName+")");
      }  
      else { 
        throw new UserMappingException(UserMappingException.INVALID_PARAMETER_ERROR);
      }  
      if (iiInstanceName != null) {
        filter = (filter + 
                 "(" + IIInstanceAttrName + "=" + iiInstanceName+ ")");
      }  
      if (iiDatabaseName != null) {
        filter = (filter + 
                 "(" + IIDatabaseAttrName + "=" + iiDatabaseName+ ")");
      }  
      filter = (filter + 
               "(objectclass=" + UserMappingObjectClassName + "))");

      // set search controls      	        
      ctls.setSearchScope(SearchControls.ONELEVEL_SCOPE);
      String [] returnAttr2 = {IIRemoteAuthIDAttrName, IIRemotePasswordAttrName};
      ctls.setReturningAttributes(returnAttr2);
      	
      try {
        userMappingEntry = ctx.search(userEntryDN, filter, ctls);
      } 
      catch (SizeLimitExceededException e) {
      }
      	      	
      // parse the result
      Attributes userMappingAttrs = ((SearchResult)userMappingEntry.next()).getAttributes();
      String iiRemoteAuthID = (String)userMappingAttrs.get(IIRemoteAuthIDAttrName).get(0);
      String iiRemotePassword = (String)userMappingAttrs.get(IIRemotePasswordAttrName).get(0);
      	
      if (iiRemoteAuthID != null) {
        StringOption authIDOption = new StringOption(um);
        authIDOption.setName(StringOption.REMOTE_AUTHID_OPTION);
        authIDOption.setValue(iiRemoteAuthID);
        um.addOption(authIDOption);
      }
      else { 
        throw new UserMappingException(UserMappingException.LOOKUP_ERROR);
      }  	
    
      if (iiRemotePassword != null) {
        StringOption pwdOption = new StringOption(um);
        pwdOption.setName(StringOption.REMOTE_PASSWORD_OPTION);
        pwdOption.setValue(new String(crypto.getChars(crypto.decrypt(crypto.decode(iiRemotePassword)))));
        um.addOption(pwdOption);
      }  
      else {
        throw new UserMappingException(UserMappingException.LOOKUP_ERROR);
      }
    }
    catch (Exception e) {
      throw new UserMappingException(UserMappingException.LOOKUP_ERROR); 
    } 
  }
}
