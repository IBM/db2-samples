/**********************************************************************
*
*  Source File Name = UnfencedFileWrapper.java
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

import com.ibm.db2.wrapper.*;

/**
 * The UnfencedFileWrapper represents a wrapper to access flat text files.
 */
public class UnfencedFileWrapper extends UnfencedGenericWrapper
{
  /**
   * Construct a new wrapper object.
   *
   */
  public UnfencedFileWrapper()
  {
    super();
  }
  
  /**
   * Create a server object that represents a remote data source.
   *
   * @param serverName              The name of the server object.
   *
   * @return                        A new server instance.
   *
   */
  protected Server createServer(String serverName)
  {
    Server s = new UnfencedFileServer(serverName, this);
    return s;
  }

  /**
   * Function to verify the wrapper information that is specified in CREATE WRAPPER statement.
   * The current implementation accepts only the reserved wrapper options and it sets the
   * fenced wrapper class.
   *
   * @param wrapperInfo             The wrapper information specified in CREATE WRAPPER statement.
   *
   * @return                        Additional information that the wrapper wants to store in the DB2 UDB catalog.
   *                                The current implementation sets the fenced wrapper class.
   *
   * @exception WrapperException    if the verification fails.
   * 
   */
  protected WrapperInfo verifyMyRegisterWrapperInfo(WrapperInfo wrapperInfo) throws Exception
  {
    // check options
    // accept only reserved wrapper options
    // call the method on the base class to verify that
    WrapperInfo wi = super.verifyMyRegisterWrapperInfo(wrapperInfo);
    
    // add FENCED_WRAPPER_CLASS option
    // first, check whether the previous call returned a WrapperInfo object
    // or we need to create a new one
    if( wi == null )
    {
      wi = new WrapperInfo();
    }
    setFencedWrapperClass(wi, "FencedFileWrapper");
    
    // return the newly created WrapperInfo object
    // DB2 will merge the returned information with the catalog information
    return wi;
  }
}
