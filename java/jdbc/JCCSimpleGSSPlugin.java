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
// SOURCE FILE NAME: JCCSimpleGSSPlugin.java
//
// SAMPLE: Implement a JCC GSS-API plugin sample which does a 
//         userid and password check
//
// This set of sample shows
//
// 1. How to implement a JCC GSS-API plugin sample which does a userid and password check
// 2. How to use this sample plugin to get a Connection
//
// In order to implement a JCC plugin in, user needs to extend com.ibm.db2.jcc.DB2JCCPlugin
// and implement the following method:
// public abstract byte[] getTicket (String username, String password, 
//                                   byte[] returnedToken) throws org.ietf.jgss.GSSException;
//
// Plugin users also need to implement some JGSS APIs. The following is a list of JGSS-APIs
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
//
// This JCCSimpleGSSPlugin implements a sample that does a simple GSS-API plugin
// that performs userid and password checking. It corresponds to the c sample plugin
// gssapi_simple in sqllib\samples\securtiy\plugins\
//
// The implementation of this JCCSimpleGSSPlugin contains the following 5 files:
//
// JCCSimpleGSSPlugin.java
// This file implements the sample JCCSimpleGSSPlugin.
//
// JCCSimpleGSSContext.java
// This file is used by JCCSimpleGSSPlugin.java to implement the plugin sample.
//
// JCCSimpleGSSCredential.java
// This file is used by JCCSimpleGSSPlugin.java to implement the plugin sample.
//
// JCCSimpleGSSException.java
// This file is used by JCCSimpleGSSPlugin.java to handle Exceptions.
//
// JCCSimpleGSSName.java
// This file is used by JCCSimpleGSSPlugin.java to implement the plugin sample.
//
// how to run this JCCSimpleGSSPlugin sample
//
// compile the above 5 files and JCCSimpleGSSPluginTest.java using javac *.java
// Run JCCSimpleGSSPluginTest using
// java JCCSimpleGSSPluginTest server port dbname userid password
//
// Note: To run this sample, server side plugin gssapi_simple needs to be installed in
//       the server plug-in directory on the  server. Database manager configuration
//       parameters SRVCON_GSSPLUGIN_LIST and SRVCON_AUTH need to set correctly
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

public class JCCSimpleGSSPlugin extends com.ibm.db2.jcc.DB2JCCPlugin
{

  protected org.ietf.jgss.GSSName serverGSSName_ ;

  public JCCSimpleGSSPlugin()
  {
    serverPrincipalName_ = "GSSAPI_SIMPLE";
  }
  /**
   * convert text service principal name into the GSS-API internal format for use with the other APIs
   * @param serverPrincipalName String
   * @throws GSSException
   * @return GSSName
   */

  public org.ietf.jgss.GSSName processServerPrincipalName(String serverPrincipalName) throws org.ietf.jgss.GSSException
  {
    if (serverPrincipalName != null)
      return new JCCSimpleGSSName(serverPrincipalName);
    else
      throw new JCCSimpleGSSException(0,"plugin bad principal name.");
  }

  /**
   * Generate the initial credentials based on the provided username/password pair and return the
   * GSS-API credential
   * @param username String
   * @param password String
   * @throws GSSException
   * @return GSSCredential
   */
  public org.ietf.jgss.GSSCredential generateInitialCred(String username, String password) throws org.ietf.jgss.GSSException
  {
    return new JCCSimpleGSSCredential(username, password);
  }

  /**
   *  This method will generate the security context information for the username/password pair.
   *  The security context information will be used to get the connection
   *  @param userid String
   *  @param password String
   *  @param returnedToken byte[]   the token returned by DB2 server
   *  @throws GSSException
   *  @return byte[]
   */
  public byte[] getTicket(String userid, String password, byte[] returnedToken) throws java.sql.SQLException
  {
    try {
      if (context_ == null ||
          ( (JCCSimpleGSSContext) context_).getctxCount() == 0) {
        serverGSSName_ = (JCCSimpleGSSName) processServerPrincipalName(
            serverPrincipalName_);
        gssCredential_ = (JCCSimpleGSSCredential) generateInitialCred(userid,
            password);
        context_ = new JCCSimpleGSSContext( (JCCSimpleGSSCredential) gssCredential_,
                                            (JCCSimpleGSSName) serverGSSName_, 0);
      }
      int length = 0;
      if (returnedToken != null)
        length = returnedToken.length;
      context_.requestMutualAuth(true);
      byte[] ticket = context_.initSecContext(returnedToken, 0, length);
      return ticket;
    }
    catch (org.ietf.jgss.GSSException e)
    {
      throw new java.sql.SQLException(e.getMessage());
    }

  }
}
