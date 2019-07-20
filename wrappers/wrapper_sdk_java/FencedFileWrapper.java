/**********************************************************************
*
*  Source File Name = FencedFileWrapper.java
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
 * The FencedFileWrapper represents a wrapper to access flat text files.
 */
public class FencedFileWrapper extends FencedGenericWrapper
{
  /**
   * Construct a new wrapper object.
   *
   */
  public FencedFileWrapper()
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
    return  new FencedFileServer(serverName, this);
  }
}
