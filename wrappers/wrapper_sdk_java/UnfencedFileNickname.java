/**********************************************************************
*
*  Source File Name = UnfencedFileNickname.java
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
 * The UnfencedFileNickname represents a nickname of the file wrapper.
 * In this case the nickname maps one to one with a flat text file containing the data.
 * This class is responsible for validating information from the CREATE NICKNAME and ALTER NICKNAME statements.
 * The UnfencedFileNickname is also instantiated and used in the query planning phase.
 */
public class UnfencedFileNickname extends UnfencedGenericNickname
{
  /**
   * Construct a nickname with the specified schema and name for the specified server.
   *
   * @param schema                  The local DB2 nickname schema name.
   * @param name                    The local DB2 nickname name.
   * @param server                  The server containing this nickname.
   *
   */
  public UnfencedFileNickname(String schema, String name, UnfencedGenericServer server)
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
   * Function to verify the nickname information that is specified in CREATE NICKNAME statements.
   * In this case, the function is a no-op because the nickname validation is done by the
   * FencedFileNickname instance.
   *
   * @param nicknameInfo            The nickname information specified in CREATE NICKNAME statement.
   *
   * @return                        Additional information that the wrapper wants to store in the DB2 UDB catalog.
   *                                The current implementation returns null.
   */
  protected NicknameInfo verifyMyRegisterNicknameInfo(NicknameInfo nicknameInfo)
  {
    // all verifications are on the fenced side.
    // Here accept anything.
    // Don't use default implementation because it will get upset about non-standard options.
    return null;
  }

  /**
   * Function to verify the nickname information that is specified in ALTER NICKNAME statement.
   * The current implementation accepts only the reserved nickname options and the FILE_PATH option.
   * It also verifies the column data types and the column options.
   *
   * @param nicknameInfo            The nickname information specified in ALTER NICKNAME statement.
   *
   * @return                        Additional information that the wrapper wants to store in the DB2 UDB catalog.
   *                                The current implementation returns null.
   *
   * @exception WrapperException    The DB2 errors 1881, 1883 and 1823 are thrown if the verification fails.
   * 
   */
  protected NicknameInfo verifyMyAlterNicknameInfo(NicknameInfo nicknameInfo) throws WrapperException
  {
    // Walk through the list of options supplied in the DDL to :
    // 1. Check to see if the user is not trying to drop the FILE_PATH option
    // 2. Check to see if the user is not trying to alter an unknown option
    boolean foundFilePath = false;

    CatalogOption option = nicknameInfo.getFirstOption();
    while( option != null )
    {
      if( ! option.isReserved() )
      {
        String optionName = option.getName();

        if( optionName.equals("FILE_PATH") )
        {
          if( option.getAction() == CatalogOption.DROP )
          {
            throw new WrapperException(-1883, "FFNVA", new String[] {optionName, "Nickname", nicknameInfo.getNickname() });
          }
        }
        else
        {
          throw new WrapperException(-1881, "FFNVA", new String[] {optionName, "Nickname", nicknameInfo.getNickname() });
        }
      }

      option = nicknameInfo.getNextOption(option);
    }

    // check column types & options
    verifyColumns(nicknameInfo);
    
    return null;
  }

  /**
   * Function to verify the column information that is specified in ALTER NICKNAME statement.
   * The current implementation accepts only a subset of column types and the reserved colun options.
   *
   * @param nicknameInfo            The nickname information specified in ALTER NICKNAME statement.
   *                                The nicknameInfo object contains the column information too.
   *
   * @exception WrapperException    The DB2 errors 1881 and 1823 are thrown if the verification fails.
   * 
   */
  public void verifyColumns(NicknameInfo nicknameInfo) throws WrapperException
  {
    ColumnInfo columnInfo = nicknameInfo.getFirstColumn();
    while( columnInfo != null )
    {
      String type = columnInfo.getTypeName();
      if( type != null &&
          ! type.equals("VARCHAR") &&
          ! type.equals("CHARACTER") &&
          ! type.equals("INTEGER") &&
          ! type.equals("DOUBLE") &&
          ! type.equals("DECIMAL") )
      {
        throw new WrapperException(-1823, "FFNVC", new String[] { type, getServer().getName() } );
      }

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
   * Retrieve the index (position) of the column specified by its name.
   *
   * @param columnName              The name of the column.
   * 
   * @return                        The index(position) of the column with the given name.
   *
   * @exception Exception           if the column with the given name cannot be found.
   *
   */
  public int getColumnIndex(String columnName) throws Exception
  {
    ColumnInfo column = getInfo().getColumn(columnName);
    if( column == null )
    {
      throw new Exception("The column " + columnName + " cannot be found.");
    }
    return column.getColumnID();
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
