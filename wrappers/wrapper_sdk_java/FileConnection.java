/**********************************************************************
*
*  Source File Name = FileConnection.java
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
 * The FileConnection represents a connection between the file wrapper and the remote data source.
 * But since we are dealing with flat text files, there is no need to implement a connection
 * mechanism and this class has only to provide the RemoteQuery objects that represent the run-time
 * objects used by DB2 to retrieve data from the remote data source.
 */
public class FileConnection extends RemoteConnection
{
  /**
   * Construct a connection for the specified server with the user authorization and transaction type as indicated.
   *
   * @param remoteServer       The server that contains the connection.
   * @param remoteUser         The user object that is used for authentication.
   * @param connectionKind     The kind of connection; specifies what kind of transactions are supported.
   * @param id                 Reserved for DB2 use.
   *
   * 
   */
  public FileConnection(FencedServer remoteServer, FencedRemoteUser remoteUser, int connectionKind, long id)
  {
    super(remoteServer, remoteUser, connectionKind, id);
  }

  /**
   * Create a FileQuery object for executing SQL statements.
   *
   * @param id               Reserved for DB2 use.
   *
   * @return                 A FileQuery instance.
   */
  public RemoteQuery createRemoteQuery(long id)
  {
    return new FileQuery(this, id);
  }

}
