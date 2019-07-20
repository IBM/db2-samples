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
// SOURCE FILE NAME: JCCKerberosPlugin.java
//
// This set of sample shows:
//
// 1. How to implement a JCC plugin which does Kerberos authentication
// 2. How to use this sample plugin to get a Connection.
//
// In order to implement a JCC plugin, user needs to extend com.ibm.db2.jcc.DB2JCCPlugin
// and implement the following method:
// public abstract byte[] getTicket (String username, String password, 
//                                   byte[] returnedToken) throws org.ietf.jgss.GSSException;
//
// Plugin users also need to implement some JGSS APIs. The following is a list of JGSS APIs
// required for Java Security Plugin interface.
//
// GSSContext.requestMutualAuth(boolean state)
// GSSContext.getMutualAuthState()
// GSSContext.requestCredDeleg(boolean state)
// GSSContext.getCredDelegState()
// GSSContext.initSecContext (byte[] inputBuf, int offset, int len)
// GSSContext.dispose()
// GSSCredential.dispose()
//
// The APIs should follow the Generic Security Service Application Program Interface, 
// Version 2 (IETF RFC2743) and Generic Security Service 
// API Version 2: Java-Bindings (IETF RFC2853) specifications.
// For Kerberos, the implementations are already available through the default instance
// of the GSSManager class.
//
// This set of sample implements a plugin that does kerberos authentication.
// It uses Kerberos implementation in jgss package
// It corresponds to the c sample plugin IBMkrb5 in sqllib\samples\securtiy\plugins\
//
// This set of sample contains the following 3 files:
//
// JCCKerberosPluginTest.java
// This file uses sample plugin JCCKerberosPlugin to get a Connection from DB2 server
//
// JCCKerberosPlugin.java
// This file implements the sample JCCKerberosPlugin.
//
// JCCSimpleGSSException.java
// This file is used by JCCKerberosPlugin for Exception handling
//
// How to run this JCCKerberosPlugin sample:
//
//   Compile the above 3 files using: javac *.java
//   Run JCCKerberosPluginTest using
//   java JCCKerberosPluginTest server port dbname userid password serverPrincipalName
//
// Note: To run this sample, server side plugin IBMkrb5 needs to be installed in
//       the server plug-in directory on the  server. Database manager configuration
//       parameters SRVCON_GSS_PLUGIN_LIST and SRVCON_AUTH need to set correctly
//
// OUTPUT FILE: None
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

import org.ietf.jgss.*;

public class JCCKerberosPlugin  extends com.ibm.db2.jcc.DB2JCCPlugin implements java.security.PrivilegedExceptionAction
{
  private org.ietf.jgss.GSSManager manager_ = org.ietf.jgss.GSSManager.getInstance();
  private org.ietf.jgss.GSSName serverGSSName_ ;
  private byte[] ticket = null;
  private byte[] returnedToken_ = null;

  public JCCKerberosPlugin()
  {}

  public JCCKerberosPlugin ( String serverPrincipalName)
  {
    serverPrincipalName_ = serverPrincipalName;
  }


  /**
   * Convert text service principal name into the GSS-API internal format for use with the other APIs
   * @parm  serverPrincipalName String
   * @return  GSSName  server principal name in GSSName format
   * @throws GSSException  if an error occurs.
   */
  public org.ietf.jgss.GSSName processServerPrincipalName(String serverPrincipalName) throws org.ietf.jgss.GSSException
  {
    org.ietf.jgss.Oid krb5Oid = new org.ietf.jgss.Oid("1.2.840.113554.1.2.2");
    if (serverPrincipalName != null)
      return manager_.createName (serverPrincipalName_,
                                  null,
                                  krb5Oid);

    else
      throw new JCCSimpleGSSException(0,"plugin bad principal name.");
  }


  /**
   *  This method will generate the security context information for the username/password pair.
   *  The security context information will be used to get the connection
   * @param username String
   * @param password String
   * @param returnedByte byte[]  the token returned by DB2 server
   * @throws SQLException if an error occurs.
   * @return byte[]  the security context information for this username/password pair
   */

  public byte[] getTicket(String username, String password, byte[] returnedByte) throws java.sql.SQLException

  {
       returnedToken_ = returnedByte;

       if (username == null) {
         setUseSubjectCredsOnly(false);
         try{
           getTicketX();
         }
         catch(org.ietf.jgss.GSSException e)
         {
           throw new java.sql.SQLException(e.getMessage());
         }
       }
       else {
         setUseSubjectCredsOnly (true);
         try {
           com.ibm.db2.jcc.am.Krb5JAASCallbackHandler handler =
             new com.ibm.db2.jcc.am.Krb5JAASCallbackHandler();

           handler.setUser(username);
           handler.setPassword(password);

           javax.security.auth.login.LoginContext loginCtxt =
             new javax.security.auth.login.LoginContext("JaasClient", handler);

           loginCtxt.login();
           javax.security.auth.Subject subject = loginCtxt.getSubject();

           javax.security.auth.Subject.doAsPrivileged(subject, this, null);
         }

         catch (javax.security.auth.login.LoginException e) {
           throw new java.sql.SQLException("javax.security.auth.login.LoginException happened");
         }
         catch (java.security.PrivilegedActionException e) {
           throw new java.sql.SQLException("java.security.PrivilegedActionException happened.");
         }

       }
      return ticket;
  }

  /**
   * This method will generate the security context information.
   * It is called by getTicket(String username, String password, byte[] returnedByte)
   * @throws GSSException if an error occurs
   */
  public void getTicketX() throws org.ietf.jgss.GSSException
  {
      if(returnedToken_ == null) {
        /*
         * Create a GSSName out of the server's name.
         */
         serverGSSName_ = processServerPrincipalName(serverPrincipalName_);

        /*
         * Create a GSSContext for mutual authentication with the
         * server.
         */
        org.ietf.jgss.Oid defaultMech = null;
        context_ = manager_.createContext(serverGSSName_,
            defaultMech,
            gssCredential_,
            org.ietf.jgss.GSSContext.INDEFINITE_LIFETIME);

        context_.requestMutualAuth(true); // Mutual authentication

        returnedToken_ = new byte[0];
      }

     int tokenLength = 0;
     if (returnedToken_ != null)
       tokenLength = returnedToken_.length;

     ticket = context_.initSecContext(returnedToken_, 0, tokenLength);
  }


  /**
   * It sets the JAVA variable javax.security.auth.useSubjectCredsOnly
   * to useSubjectCredsOnly
   * If useSubjectCredsOnly is false, JGSS will not acquire credentials
   * through JAAS and Kinit will be used to get the initial credentials
   * If useSubjectCredsOnly is true, JGSS will acquire credentials
   * through JAAS
   * @param useSubjectCredsOnly boolean
   */
  public void setUseSubjectCredsOnly (boolean useSubjectCredsOnly)
  {
    final String subjectOnly = useSubjectCredsOnly ? "true" : "false";
    final String property = "javax.security.auth.useSubjectCredsOnly";

    String temp = (String) java.security.AccessController.doPrivileged (
      new sun.security.action.GetPropertyAction (property));

    // Property not set. Set it to the specified value.
    if(temp == null)
      java.security.AccessController.doPrivileged (
        new java.security.PrivilegedAction() {
          public Object run()
          {
            System.setProperty (property, subjectOnly);
            return null;
          }
        }
      );
  }

  public Object run () throws org.ietf.jgss.GSSException
  {
    getTicketX();
    return null;
  }

}
