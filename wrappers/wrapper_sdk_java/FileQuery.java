/**********************************************************************
*
*  Source File Name = FileQuery.java
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

import java.io.BufferedReader;
import java.io.FileReader;
import java.io.FileInputStream;
import java.io.InputStreamReader;
import java.io.IOException;
import java.math.BigDecimal;
import java.util.StringTokenizer;
/**
 * The FileQuery class represents the mechanism by which DB2 retrieves data
 * from the remote data source.
 * The mechanism used is of type open-fetch-close.
 */
public class FileQuery extends RemoteQuery
{
  /**
   * Construct a new FileQuery object for the specified connection.
   *
   * @param activeConnection        The active connection that this FileQuery object will use
   *                                to access the remote data source.
   * @param id                      Reserved for DB2 use.
   * 
   */
  public FileQuery(RemoteConnection activeConnection, long id)
  {
    super(activeConnection, id);
  }
  
  /**
   * Allow the wrapper to prepare the data source to return the first result row for the query.
   * The file wrapper retrieves here the execution descriptor object that it constructed
   * during query planning and opens an input stream for the file that needs to be read.
   *
   * @exception Exception           if the processing fails.
   */
  public void open() throws Exception
  {
    // retrieve the execution descriptor and set up a file reader
    execDesc = (FileExecDesc) getExecDesc();
    
    fileReader = new BufferedReader(new FileReader( execDesc.getFilePath() ));
    
    // report query status to DB2
    setStatus(OPEN);
  }

  /**
   * Reset a previously opened result stream and prepares the data source to return more results.
   * The file wrapper re-opens an input stream for the file that needs to be read.
   *
   * @param action                  The flag to indicate the action needed in reopen.
   *
   * @exception Exception           if the processing fails.
   */
  public void reopen(short action) throws Exception
  {
    // re-initialize the file reader
    fileReader = new BufferedReader(new FileReader( execDesc.getFilePath() ));

    // report query status to DB2
    setStatus(OPEN);
  }

  /**
   * Method that allows the wrapper and the data source to clean up after executing a query.
   * The file wrapper closes the input stream previously opened for the file that needs to
   * be read.
   *
   * @param status                  The flag that indicates the status of the operation.
   *
   * @exception Exception           if the processing fails.
   */
  public void close(short status) throws Exception
  {
    // close the file reader
    if( fileReader != null )
    {
      fileReader.close();
      fileReader = null;
    }
    
    // report query status to DB2
    if( status == CLOSE_EOS || status == CLOSE_EOA )
    {
      setStatus(UNREADY);
    }
    else
    {
      setStatus(READY);
    }
  }

  /**
   * Convert a string into an array of tokens considering comma as separator.
   * The string represents a line read from the file.
   * 
   * @param line                    The string to be parsed into tokens.
   * @param tokenCount              The number of tokens that should be in the string.
   *                                This value is used by the tokenizer to do a minimal
   *                                validation of the string.
   *
   * @return                        The array of tokens.
   *
   * @exception WrapperException    if the actual number of tokens is different than the
   *                                expected token count.
   */
  public String[] tokenize(String line, int tokenCount) throws WrapperException
  {
    String[] tokens = new String[tokenCount];
    StringTokenizer tokenizer = new StringTokenizer(line, ",");
    int index = 0;
    
    while( tokenizer.hasMoreTokens() )
    {
      if( index < tokenCount )
      {
        tokens[index++] = tokenizer.nextToken();
      }
      else
      {
        throw new WrapperException("Invalid line read from file. Too many columns!");
      }
    }
    if( index < tokenCount )
    {
      throw new WrapperException("Invalid line read from file. Not enough columns!");
    }

    return tokens;
  }

  /**
   * Method that copies a single result row from the data source into the output RuntimeDataList.
   * The file wrapper reads the file line by line, converts the line into an array of tokens and
   * puts these tokens into the output RuntimeDataList object. If there is predicate, it will 
   * judge whether the value meets the predicate. Only the matched lines will be put into 
   * the output RuntimeDataList object.
   * If there are no more lines to be read from the file, the fetch method calls reportEof to
   * flag DB2 that data fetching is done.
   *
   * @exception Exception           if the processing fails.
   */
  public void fetch() throws Exception
  {
    if( fileReader == null || execDesc == null)
    {
      throw new WrapperException( "Query not initialized!");
    }
    String line = null;
    
    while(true)
    {
       // read one line from the file
       line = fileReader.readLine();
       
       // if there are no more line, report Eof condition to DB2
       if( line == null )
       {
         reportEof();
         break;
       }
       else
       {
         // split the line into columns
         String[] tokens = tokenize(line, execDesc.getNumberOfColumns());

         boolean match = true;
         //If predicate is FileExecDesc.ALLROW, the line will be matched. 
         //Else it will jump into the logic to judge whether the line meet the predicate.
         if(execDesc.getPredicate() != FileExecDesc.ALLROW)
         {
            match = false;
            //Get the column's value to compare it with the constant specified 
            //in the equality predicate. To obtain the column value use its index
            // that was stored in the Execution Descriptor at query planning.            
            int keyColumn = execDesc.getKeyColumn();
            String keyValue = new String(tokens[keyColumn]);
            int bindIndex = execDesc.getBindIndex();
            //form column = 'cst' or 'cst' = column
            if(bindIndex == -1)
            {
               switch(execDesc.getDataType())
               {
                 case RuntimeData.CHAR:
                 case RuntimeData.VARCHAR:
                   {
                     if(keyValue.equals(execDesc.getConstString()))
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.INT:
                   {
                     if(Integer.parseInt(keyValue) == execDesc.getConstInt())
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.DOUBLE:
                   {
                     if(Double.parseDouble(keyValue) == execDesc.getConstDouble())
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.FLOAT:
                   {
                     if(Float.parseFloat(keyValue) == execDesc.getConstFloat())
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.DECIMAL:
                   {
                     //The comparison of decimal values requires them to have the same scale. 
                     //Use the scale that was stored in the Execution Descriptor at query planning.
                     short scale = execDesc.getScale();
                     BigDecimal value1 = execDesc.getConstDecimal();
                     value1 = value1.setScale(scale,java.math.BigDecimal.ROUND_HALF_UP);
                     BigDecimal value2 = new BigDecimal(keyValue);
                     value2 = value2.setScale(scale,java.math.BigDecimal.ROUND_HALF_UP);
                     
                     if(value1.compareTo(value2) == 0)
                     {
                        match = true;
                     }
                     break;
                   }
                 
                 default:
                   {
                     throw new WrapperException("Fetch: Unknown data type!");
                   }
               }
            }
            else  //form column = unbound or unbound = column
            {
               RuntimeDataList dataList = getInputData(); 
               RuntimeData data = dataList.getValue(bindIndex);
               if(data == null)
               {
               	  throw new WrapperException("Fetch: runtimedata is null!");
               }
               switch(data.getDataType())
               {
                 case RuntimeData.CHAR:
                 case RuntimeData.VARCHAR:
                   {
                     if(keyValue.equals(data.getString()))
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.INT:
                   {
                     if(Integer.parseInt(keyValue) == data.getInt())
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.DOUBLE:
                   {
                     if(Double.parseDouble(keyValue) == data.getDouble())
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.FLOAT:
                   {
                     if(Float.parseFloat(keyValue) == data.getFloat())
                     {
                        match = true;
                     }
                     break;
                   }
                 case RuntimeData.DECIMAL:
                   {
                     //The comparison of decimal values requires them to have the same scale. 
                     //Use the scale that was stored in the Execution Descriptor at query planning.
                     short scale = execDesc.getScale();
                     BigDecimal value1 = data.getBigDecimal();
                     value1 = value1.setScale(scale,java.math.BigDecimal.ROUND_HALF_UP);
                     BigDecimal value2 = new BigDecimal(keyValue);
                     value2 = value2.setScale(scale,java.math.BigDecimal.ROUND_HALF_UP);
                     
                     if(value1.compareTo(value2) == 0)
                     {
                        match = true;
                     }
                     break;
                   }
                 
                 default:
                   {
                     throw new WrapperException("Fetch: Unknown data type!");
                   }
               }
            }
         }
         
         //Found the wanted row
         if(match == true)
         {
           RuntimeDataList outputDataList = getOutputData();
           int valuesCount = outputDataList.getNumberOfValues();
           // save the column values into the output data object
           for( int i = 0; i < valuesCount; i++ )
           {
             RuntimeData data = outputDataList.getValue(i);
             int columnIndex = execDesc.getOutputColumn(i);
             switch( data.getDataType() )
             {
               case RuntimeData.CHAR:
               case RuntimeData.VARCHAR:
                 {
                   data.setString( tokens[columnIndex] );
                   break;
                 }
               case RuntimeData.INT:
                 {
                   data.setInt( Integer.parseInt( tokens[columnIndex]) );
                   break;
                 }
               case RuntimeData.DOUBLE:
                 {
                   data.setDouble( Double.parseDouble( tokens[columnIndex]) );
                   break;
                 }
               case RuntimeData.FLOAT:
                 {
                   data.setFloat( Float.parseFloat( tokens[columnIndex]) );
                   break;
                 }
               case RuntimeData.DECIMAL:
                 {
                   data.setBigDecimal( new BigDecimal( tokens[columnIndex]) );
                   break;
                 }
           
               default:
                 {
                   throw new WrapperException("Fetch: Unknown data type!");
                 }
             } // end switch
           } // end for
           
           //Get the wanted row and break
           break;
         } //end else
       } // end else if line == null
    } // end while(true)
  } // end fetch

  /**
   * The execution descriptor object.
   */
  private FileExecDesc execDesc = null;

  /**
   * The input stream that is used to retrieve data from the file.
   */
  private BufferedReader fileReader = null;

} // end class
