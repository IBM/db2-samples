/**********************************************************************
*
*  Source File Name = FencedFileServer.java
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
 * The FencedFileServer represents a server of the file wrapper.
 * The Server maps to the remote data source, but since we are dealing with flat text files,
 * fhe file server objects are responsible only for providing the user mapping, nickname and
 * remote connection objects.
 * The FencedFileServer is the "run-time" part of the server that DB2 uses to create remote
 * connections to the remote data source.
 */
public class FencedFileServer extends FencedGenericServer
{
  /**
   * Construct a server with the specified name for the specified wrapper.
   *
   * @param serverName              The server name.
   * @param wrapper                 The wrapper containing this server.
   *
   */
  public FencedFileServer(String serverName, FencedFileWrapper wrapper )
  {
    super(serverName, wrapper);
  }

  /**
   * Create a nickname object that maps to a data collection a the remote data source.
   * For the file wrapper, the data collection is a flat text file.
   *
   * @param schemaName              The local DB2 nickname schema name.
   * @param nickname                The local DB2 nickname name.
   *
   * @return                        A nickname instance.
   *
   */
  public Nickname createNickname(String schemaName, String nickname)
  {
    return new FencedFileNickname(schemaName, nickname, this);
  }

  /**
   * Create a remote connection to handle a connection between the wrapper and the remote data source.
   * For the file wrapper, the remote connection is a no-op.
   *
   * @param user                    The user mapping instance that the remote connection
   *                                will use for authorization at the remote data source.
   * @param kind                    A constant indicating whether the remote connection supports transactions or not.
   *                                Valid values for this constant are defined in the RemoteConnection class.
   *                                The wrapper specifies if the remote source supports transaction or not by 
   *                                overriding the FencedServer.getRemoteConnectionKind method.
   * @param id                      Reserved DB2 value. 
   *
   * @return                        A remote connection instance.
   *
   */
  public RemoteConnection createRemoteConnection(FencedRemoteUser user, int kind, long id)
  {
    return new FileConnection(this, user, kind, id);
  }
}
