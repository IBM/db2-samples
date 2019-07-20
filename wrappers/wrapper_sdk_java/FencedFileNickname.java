/**********************************************************************
*
*  Source File Name = FencedFileNickname.java
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
 * The FencedFileNickname represents a nickname of the file wrapper.
 * In this case the nickname maps one to one with a flat text file containing the data.
 * This class is responsible for validating information from the CREATE NICKNAME statement.
 * The FencedFileNickname is the "run-time" part of the nickname that can retrieve the
 * active remote connection from the parent server object and use it to obtain the
 * nickname information from the remote data source.
 * Since this sample deals with flat text files, the remote connection is a "no-op" and the
 * nickname validates the information by itself.
 */
public class FencedFileNickname extends FencedGenericNickname
{
  /**
   * Construct a nickname with the specified schema and name for the specified server.
   *
   * @param schema                  The local DB2 nickname schema name.
   * @param name                    The local DB2 nickname name.
   * @param server                  The server containing this nickname.
   *
   */
  public FencedFileNickname(String schema, String name, FencedFileServer server)
  {
    super(schema, name, server);
  }

  /**
   * Perform necessary nickname initialization.
   * This method is called by the DB2 engine after the nickname is created or after the options are changed.
   * This method is implemented by the wrapper to perform the nickname-specific initialization.
   * The current implementation saves the file path into a class field.
   * 
   * @param nicknameInfo            The nickname catalog information.
   *
   * @exception WrapperException    The DB2 error 1883 is thrown if the FILE_PATH option is not present.
   */
  protected void initializeMyNickname(NicknameInfo nicknameInfo) throws WrapperException
  {

    // save the file path from NicknameInfo into a class field
    CatalogOption option = nicknameInfo.getOption("FILE_PATH");

    // be sure the option is present
    if( option != null )
    {
      _filePath = option.getValue();
    }
    else
    {
      throw new WrapperException(-1883, "FFNVR", new String[] {"FILE_PATH", "Nickname", nicknameInfo.getNickname() });
    }

  }

  /**
   * Function to verify the nickname information that is specified in CREATE NICKNAME statement.
   * The current implementation accepts only the reserved nickname options and the FILE_PATH option.
   * It also verifies the column data types and the column options.
   *
   * @param nicknameInfo            The nickname information specified in CREATE NICKNAME statement.
   *
   * @return                        Additional information that the wrapper wants to store in the DB2 UDB catalog.
   *                                The current implementation returns null.
   *
   * @exception WrapperException    The DB2 errors 1881, 1883 and 1823 are thrown if the verification fails.
   * 
   */
  protected NicknameInfo verifyMyRegisterNicknameInfo(NicknameInfo nicknameInfo) throws WrapperException
  {
    // accept all reserved nickname options, FILE_PATH and READ_ONLY option
    boolean foundFilePath = false;
    NicknameInfo deltaInfo = null;

    CatalogOption option = nicknameInfo.getFirstOption();
    while( option != null )
    {
      if( ! option.isReserved() )
      {
        String optionName = option.getName();

        if( optionName.equals("FILE_PATH") )
        {
          foundFilePath = true;
        }
        else
        {
          // invalid option
          throw new WrapperException(-1881, "FFNVR", new String[] {optionName, "Nickname", nicknameInfo.getNickname() });
        }
      }

      option = nicknameInfo.getNextOption(option);
    }

    // FILE_PATH is a required option; if not present, throw an error
    if( ! foundFilePath )
    {
      throw new WrapperException(-1883, "FFNVR", new String[] {"FILE_PATH", "Nickname", nicknameInfo.getNickname() });
    }

    // ensure READ_ONLY is set to "Y"
    if ((option = nicknameInfo.getOption("READ_ONLY")) != null)
    {
    	// user did already provide the option -> check value
    	if (option.getValue().compareTo("Y") != 0)
    	{
    		throw new WrapperException(-1882, "FFNVR", new String[] {"Nickname", "READ_ONLY", option.getValue(), nicknameInfo.getNickname() });
    	}
    }
    else
    {
        // user did not provide READ_ONLY option -> so force the option from within the code
        if (deltaInfo == null)
        {
	       deltaInfo = new NicknameInfo();
	}
        deltaInfo.addOption("READ_ONLY", "Y", CatalogOption.ADD);
    }

    // check column types & options
    verifyColumns(nicknameInfo);
    
    return deltaInfo;
  }

  /**
   * Function to verify the column information that is specified in CREATE NICKNAME statement.
   * The current implementation accepts only a subset of column types and the reserved colun options.
   *
   * @param nicknameInfo            The nickname information specified in CREATE NICKNAME statement.
   *                                The nicknameInfo object contains the column information too.
   *
   * @exception WrapperException    The DB2 errors 1881 and 1823 are thrown if the verification fails.
   * 
   */
  protected void verifyColumns(NicknameInfo nicknameInfo) throws WrapperException
  {
    ColumnInfo columnInfo = nicknameInfo.getFirstColumn();
    
    while( columnInfo != null )
    {
      String type = columnInfo.getTypeName();
      
      if( ! type.equals("VARCHAR") &&
          ! type.equals("CHARACTER") &&
          ! type.equals("INTEGER") &&
          ! type.equals("DOUBLE") &&
          ! type.equals("DECIMAL") )
      {
        throw new WrapperException(-1823, "FFNVC", new String[] { type, getServer().getName() } );
      }

      // accept only the reserved columns options
      CatalogOption option = columnInfo.getFirstOption();
      while( option != null )
      {
        if( ! option.isReserved() )
        {
          throw new WrapperException(-1881, "FFNVC", new String[] {option.getName(), "Column", nicknameInfo.getNickname() });
        }
        option = columnInfo.getNextOption(option);
      }
    
      columnInfo = nicknameInfo.getNextColumn(columnInfo);
    }
  }

  /**
   * Retrieve the file path.
   *
   * @return                        The file path as extracted from the nickname catalog information.
   *
   */
  public String getFilePath()
  {
    return _filePath;
  }

  /**
   * The file path as extracted from the nickname catalog information.
   */
  private String _filePath = null;
}
