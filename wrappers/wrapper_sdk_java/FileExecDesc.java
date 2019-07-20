/**********************************************************************
*
*  Source File Name = FileExecDesc.java
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
import java.math.BigDecimal;

/**
 * The FileExecDesc class represents the wrapper specific execution descriptor class.
 * During query planning, the wrapper builds an execution descriptor and attaches it 
 * to the Reply sent back to DB2. DB2 will store the execution descriptor until the
 * query is executed and it will pass it back to the wrapper at that time.
 * The stored information is wrapper specific and it has to allow the wrapper to
 * execute the query at the remote data source.
 * The only restriction imposed by DB2 on the execution descriptor is o be
 * serializable.
 * <br>
 * For simplicity and better understanding, the class methods don't validate the
 * input data. Instead, if there are any dependencies, they are noted in the method
 * description.
 * <br>
 * The class has two types of methods: <ul>
 * <li>the "set" methods are used during query planning, the phase when the execution
 *     descriptor is built and the information is added to it.
 * <li>The "get" methods are used during query execution, the phase when the wrapper
 *     is retrieving the information from the execution descriptor.
 * </ul>
 */
public class FileExecDesc implements java.io.Serializable
{

  /**
   * Set the number of columns of the nickname involved in the query.
   * This method is called during query planning.
   *
   * @param number                  The number of columns.
   */
  public void setNumberOfColumns(int number)
  {
    _nicknameColumns = number;
  }

  /**
   * Set the number of the columns from the SELECT clause of the query.
   * This method is called during query planning and it should be called
   * before {@link #setOutputColumn}.
   *
   * @param number                  The number of selected columns.
   */
  public void setNumberOfOutputColumns(int number)
  {
    _outputColumns = new int[number];
  }

  /**
   * Specify which nickname column is in the SELECT clause of the query
   * at the given index. The nickname column is indicated by its position.
   * This method is called during query planning.
   * {@link #setNumberOfOutputColumns} should have been called in advance.
   *
   * @param outputIndex             The index of the column in SELECT clause.
   * @param columnIndex             The position of the column in the nickname.
   */
  public void setOutputColumn(int outputIndex, int columnIndex)
  {
    if( _outputColumns != null )
    {
      _outputColumns[outputIndex] = columnIndex;
    }
  }

  /**
   * Set the path to the flat text file for the nickname involved in the query.
   * This method is called during query planning.
   * 
   * @param filePath                The file path as retrieved from the nickname catalog information.
   */
  public void setFilePath(String filePath)
  {
    _filePath = filePath;
  }
  
  /**
   * Set the predicate. It can be FileExecDesc.EQUAL or FileExecDesc.ALLROW
   * This method is called during query planning.
   * 
   * @param predicate             The predicate for the SELECT clause
   */
  public void setPredicate(int predicate)
  {
    _predicateType = predicate;
  }
  
  /**
   * Set the keycolumn. It is the column no of the column = 'cst' or 'cst' = column
   * This method is called during query planning.
   * 
   * @param keyColumn             The column no of the column
   */
  public void setKeyColumn(int keyColumn)
  {
    _keyColumn = keyColumn;
  }
  
  /**
   * Set the bind index of unbound. It is the index no of the column = unbound or unbound = column
   * This method is called during query planning.
   * 
   * @param bindIndex             The bind index no of the unbound
   */
  public void setBindIndex(int bindIndex)
  {
    _bindIndex = bindIndex;
  }
  
  /**
   * Set the data type. It is the constant data type of the column = 'cst' or 'cst' = column
   * It can be RuntimeData.CHAR, RuntimeData.VARCHAR, RuntimeData.INT, RuntimeData.DOUBLE,
   * RuntimeData.FLOAT, or RuntimeData.DECIMAL.
   * This method is called during query planning.
   * 
   * @param type             The data type of the constant
   */
  public void setDataType(short type)
  {
    _dataType = type;
  }
  
  /**
   * If the data type is RuntimeData.CHAR or RuntimeData.VARCHAR, set the string constant value.
   * This method is called during query planning.
   * 
   * @param value     The string value with data type of RuntimeData.CHAR or RuntimeData.VARCHAR
   */
  public void setConstString(String value)
  {
    _valueString = value;
  }
  
  /**
   * If the data type is RuntimeData.INT, set the int constant value.
   * This method is called during query planning.
   * 
   * @param value     The int value with data type of RuntimeData.INT
   */
  public void setConstInt(int value)
  {
    _valueInt = value;
  }
  
  /**
   * If the data type is RuntimeData.DOUBLE, set the double constant value.
   * This method is called during query planning.
   * 
   * @param value     The double value with data type of RuntimeData.DOUBLE
   */
  public void setConstDouble(double value)
  {
    _valueDouble = value;
  }
  
   /**
   * If the data type is RuntimeData.FLOAT, set the float constant value.
   * This method is called during query planning.
   * 
   * @param value     The float value with data type of RuntimeData.FLOAT
   */
  public void setConstFloat(float value)
  {
    _valueFloat = value;
  }
  
   /**
   * If the data type is RuntimeData.DECIMAL, set the BigDecimal constant value.
   * This method is called during query planning.
   * 
   * @param value     The BigDecimal value with data type of RuntimeData.DECIMAL
   */
  public void setConstDecimal(BigDecimal value)
  {
    _valueDecimal = value;
  }
  
  /**
   * If the data type is RuntimeData.DECIMAL, set the scale of the decimal.
   * This method is called during query planning.
   * 
   * @param scale     The scale of the decimal
   */
  public void setScale(short scale)
  {
    _scale = scale;
  }
  
  /**
   * Retrieve the number of columns of the nickname involved in the query.
   * This method is called during query execution.
   *
   * @return                        The number of columns.
   */
  public int getNumberOfColumns()
  {
    return _nicknameColumns;
  }
  
  /**
   * Retrieve the array that describes the columns from the SELECT clause of the query.
   * The columns are described by their position in the nickname.
   * This method is called during query execution.
   *
   * @return                        An array containing the position of each selected column
   *                                in the nickname.
   */
  public int[] getOutputColumns()
  {
    return _outputColumns;
  }

  /**
   * Retrieve the number of the columns from the SELECT clause of the query.
   * This method is called during query execution.
   *
   * @return                        The number of selected columns.
   */
  public int getNumberOfOutputColumns()
  {
    return (_outputColumns == null ? 0: _outputColumns.length);
  }
  
  /**
   * Retrieve the position of the column in the nickname for the given column index from 
   * the SELECT clause of the query.
   * This method is called during query execution.
   *
   * @param index                   The index of the column in SELECT clause.
   * 
   * @return                        The position of the column in the nickname.
   */
  public int getOutputColumn(int index)
  {
    return (_outputColumns == null || index >= _outputColumns.length ? -1: _outputColumns[index] );
  }
  
  /**
   * Retrieve the path to the flat text file for the nickname involved in the query.
   * This method is called during query execution.
   * 
   * @return                        The file path that was stored in the execution descriptor.
   */
  public String getFilePath()
  {
    return _filePath;
  }
  
  /**
   * Retrieve the predicate. It can be FileExecDesc.EQUAL or FileExecDesc.ALLROW
   * This method is called during query execution.
   * 
   * @return                The predicate for the SELECT clause.
   */
  public int getPredicate()
  {
    return _predicateType;
  }
  
  /**
   * Retrieve the keycolumn. It is the column no of the column = 'cst' or 'cst' = column
   * This method is called during query execution.
   * 
   * @return                The column no of the column.
   */
  public int getKeyColumn()
  {
    return _keyColumn;
  }
  
  /**
   * Retrieve the bind index of unbound. It is the index no of the column = unbound or unbound = column
   * This method is called during query execution.
   * 
   * @return              The bind index no of the unbound
   */
  public int getBindIndex()
  {
    return _bindIndex;
  }
  
  /**
   * Retrieve the data type. It is the constant data type of the column = 'cst' or 'cst' = column
   * It can be RuntimeData.CHAR, RuntimeData.VARCHAR, RuntimeData.INT, RuntimeData.DOUBLE,
   * RuntimeData.FLOAT, or RuntimeData.DECIMAL.
   * This method is called during query execution.
   * 
   * @return             The data type of the constant
   */
  public short getDataType()
  {
    return _dataType;
  }
  
  /**
   * If the data type is RuntimeData.CHAR or RuntimeData.VARCHAR, retrieve the string constant value.
   * This method is called during query execution.
   * 
   * @return         The string value with data type of RuntimeData.CHAR or RuntimeData.VARCHAR
   */
  public String getConstString()
  {
    return _valueString;
  }
  
  /**
   * If the data type is RuntimeData.INT, retrieve the int constant value.
   * This method is called during query execution.
   * 
   * @return     The int value with data type of RuntimeData.INT
   */
  public int getConstInt()
  {
    return _valueInt;
  }
  
  /**
   * If the data type is RuntimeData.DOUBLE, retrieve the double constant value.
   * This method is called during query execution.
   * 
   * @return     The double value with data type of RuntimeData.DOUBLE
   */
  public double getConstDouble()
  {
    return _valueDouble;
  }
  
  /**
   * If the data type is RuntimeData.FLOAT, retrieve the float constant value.
   * This method is called during query execution.
   * 
   * @return     The float value with data type of RuntimeData.FLOAT
   */
  public float getConstFloat()
  {
    return _valueFloat;
  }
  
  /**
   * If the data type is RuntimeData.DECIMAL, retrieve the BigDecimal constant value.
   * This method is called during query execution.
   * 
   * @return        The BigDecimal value with data type of RuntimeData.DECIMAL
   */
  public BigDecimal getConstDecimal()
  {
    return _valueDecimal;
  }
  
  /**
   * If the data type is RuntimeData.DECIMAL, retrieve the scale of the decimal.
   * This method is called during query execution.
   * 
   * @return         The scale of the decimal
   */
  public short getScale()
  {
    return _scale;
  }
  
  /**
   * It means get all the rows out.
   */
  public static final int ALLROW          = 0;
  /**
   * It means get rows, which meet column = 'cst' or 'cst' = column.
   */
  public static final int EQUAL          = 1;

  /**
   * The path to the file that corresponds to the nickname involved in the query.
   */
  private String _filePath = null;

  /**
   * The number of columns for the nickname involved in the query.
   */
  private int _nicknameColumns = 0;

  /**
   * An array with the column positions in the nickname for each column from the
   * SELECT clause of the query.
   */
  private int[] _outputColumns = null;
  
  /**
   * Predicate for the SELECT clause. It can be FileExecDesc.EQUAL or FileExecDesc.ALLROW
   */
  private int _predicateType;
  
  /**
   * Column no of the column for the predicate
   */
  private int _keyColumn = 0;
  
  /**
   * Bind index no of the unbound
   */
  private int _bindIndex = -1;
  
  /**
   * Value of the constant, if the data type is RuntimeData.CHAR or RuntimeData.VARCHAR
   */
  private String _valueString;
  
  /**
   * Value of the constant, if the data type is RuntimeData.INT
   */
  private int _valueInt;
  
  /**
   * Value of the constant, if the data type is RuntimeData.DOUBLE
   */
  private double _valueDouble;
  
  /**
   * Value of the constant, if the data type is RuntimeData.FLOAT
   */
  private float _valueFloat;
  
  /**
   * Value of the constant, if the data type is RuntimeData.DECIMAL
   */
  private BigDecimal _valueDecimal;
  
  /**
   * Scale of decimal, if the data type is RuntimeData.DECIMAL
   */
  private short _scale;
  
  /**
   * Data type of the constant. It can be RuntimeData.CHAR, RuntimeData.VARCHAR, 
   * RuntimeData.INT, RuntimeData.DOUBLE, RuntimeData.FLOAT, or RuntimeData.DECIMAL.
   */
  private short _dataType;
}
