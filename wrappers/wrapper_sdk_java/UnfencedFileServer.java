/**********************************************************************
*
*  Source File Name = UnfencedFileServer.java
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

import java.io.IOException;

import com.ibm.db2.wrapper.*;
/**
 * The UnfencedFileServer represents a server of the file wrapper.
 * The Server maps to the remote data source, but since we are dealing with flat text files,
 * the file server objects are responsible only for validating the CREATE SERVER and ALTER
 * SERVER statements and to provide the user mapping and nickname objects.
 */
public class UnfencedFileServer extends UnfencedGenericServer
{
  /**
   * Construct a server with the specified name for the specified wrapper.
   *
   * @param serverName              The server name.
   * @param wrapper                 The wrapper containing this server.
   *
   */
  public UnfencedFileServer(String serverName, UnfencedFileWrapper wrapper )
  {
    super(serverName, wrapper);
  }

  /**
   * Create a nickname object that maps to a data collection at the remote data source.
   * For the file wrapper, the data collection is a flat text file.
   *
   * @param schemaName              The local DB2 nickname schema name.
   * @param nickname                The local DB2 nickname name.
   *
   * @return                        A nickname instance.
   *
   */
  protected Nickname createNickname(String schemaName, String nickname)
  {
    return new UnfencedFileNickname(schemaName, nickname, this);
  }

  /**
   * Analyze a proposed plan and determine what portion, if any,
   * can be pushed down to the remote data source.
   * The file wrapper accepts query fragments that contain only one
   * nickname and it can only support one predicate. And the predicate 
   * should be column = 'cst' or 'cst' = column or column = unbound or
   * unbound = column.
   * The function constructs a Reply that describes the query
   * fragment that the wrapper is able to execute/push down to the
   * remote data source. It also constructs an execution descriptor
   * object that DB2 will pass back to the wrapper at run-time and
   * that is used internally by the wrapper during the query execution.
   * 
   *
   * @param request                 The Request object that contains the query to be planned.
   *
   * @return                        The Reply object that describes the query fragment that the
   *                                wrapper is able to push down to the remote data source.
   *
   * @exception Exception           if the processing fails.
   *
   */
  public Reply planRequest(Request request) throws Exception
  {
    // accept only one nickname in the query fragment
    // the wrapper can't handle joins
    if( request.getNumberOfQuantifiers() == 1 )
    {
      Reply reply = createReply(request);
      FileExecDesc execDesc = new FileExecDesc();

      UnfencedFileNickname nick = null;
      
      // add the Quantifier handle to reply object
      // by this we signal DB2 that the wrapper will handle this nickname
      reply.addQuantifier( request.getQuantifier(1) );
      
      // add the file path to the execution descriptor
      // we do that because at runtime we don't have access to the nickname
      nick = (UnfencedFileNickname) request.getQuantifier(1).getNickname();
      if( nick != null )
      {
        execDesc.setFilePath( nick.getFilePath() );
      }
      else
      {
        throw new Exception("Unknown nickname!");
      }
      
      // add the number of nickname columns to the execution descriptor
      NicknameInfo nicknameInfo = nick.getInfo();
      execDesc.setNumberOfColumns( nicknameInfo.getNumColumns() );

      // add the number of output columns to the execution descriptor
      int n = request.getNumberOfHeadExp();
      execDesc.setNumberOfOutputColumns(n);
      
      // add the head expressions to the reply
      // the wrapper has to provide the values for them at runtime
      for(int i = 1; i <= n; i++)
      {
        RequestExp column = request.getHeadExp(i);
        reply.addHeadExp( column );

        execDesc.setOutputColumn(i-1, nick.getColumnIndex( column.getColumnName() ) ); // 0-based index
      }
      
      //begin deal with predicate, firstly set it to be FileExecDesc.ALLROW
      int predicate = FileExecDesc.ALLROW;
      int number = request.getNumberOfPredicates();
      
      //We only support one predicate, choose one that is valid for our conditions from all predicates
      for(int i = 1; i <= number; i++)
      {
      	//Get the predicate
      	RequestExp expression = request.getPredicate(i);
      	int kind = expression.getKind();
      	
      	//We like only predicates that have an operator and 2 children
      	if(kind == RequestExp.OPERATOR && expression.getNumberOfChildren() == 2)
      	{
      	   String token = expression.getToken();
      	   //We only support predicate '='
      	   if( token.length() != 1 || token.charAt(0) == '=' )                                                                
           {
              RequestExp firstChild = expression.getFirstChild();
              RequestExp secondChild = firstChild.getNextChild();
      	      //We only support column = 'cst' or 'cst' = column or column = unbound or unbound = column
      	      if(firstChild.getKind() == RequestExp.CONSTANT && secondChild.getKind() == RequestExp.COLUMN ||
      	         firstChild.getKind() == RequestExp.COLUMN && secondChild.getKind() == RequestExp.CONSTANT ||
      	         firstChild.getKind() == RequestExp.UNBOUND && secondChild.getKind() == RequestExp.COLUMN ||
      	         firstChild.getKind() == RequestExp.COLUMN && secondChild.getKind() == RequestExp.UNBOUND)
      	      {
      	         RequestConstant value = null;
      	         String keyColumnName;
      	         int bindIndex = -1;
      	         
      	         //form column = 'cst' or column = unbound
      	         if(firstChild.getKind() == RequestExp.COLUMN)
      	         {
      	            // form column = 'cst'
      	            if(secondChild.getKind() == RequestExp.CONSTANT)
      	            {
      	               value = secondChild.getValue();
      	               
      	               //whether constant is null
      	               if(value.isDataNull())
      	               {
      	                  throw new WrapperException( "Constant is Null!");
      	               }
      	            }   
      	            else   // form column = unbound
      	            {
      	                bindIndex++;
      	            }
      	            keyColumnName = firstChild.getColumnName();
      	         }
      	         else  //form 'cst' = column or unbound = column
      	         {
      	            //form 'cst' = column
      	            if(firstChild.getKind() == RequestExp.CONSTANT)
      	            {
      	               value = firstChild.getValue();
      	               //whether constant is null
      	               if(value.isDataNull())
      	               {
      	                  throw new WrapperException( "Constant is Null!");
      	               }
      	            }
      	            else   //form unbound = column
      	            {
      	                bindIndex++;
      	            }
      	            keyColumnName = secondChild.getColumnName();
      	         }
      	         
      	         //Get the column no for the column
      	         ColumnInfo columnInfo = nicknameInfo.getColumn(keyColumnName);
                 
                 if (columnInfo == null)
                 {
                    throw new WrapperException( "Key column not found");
                 }
                 
                 execDesc.setKeyColumn(columnInfo.getColumnID());
                 //Set unbound index
                 execDesc.setBindIndex(bindIndex);
      	         //Set the data type for the form of column = 'cst' or 'cst' = column
      	         if(bindIndex == -1)
      	         {
      	            execDesc.setDataType(value.getDataType());
      	         
      	            //Set different kinds of value following the data type
      	            switch(value.getDataType())
                    {
                      case RuntimeData.CHAR:
                      case RuntimeData.VARCHAR:
                        {
                          execDesc.setConstString(value.getString());
                          break;
                        }
                      case RuntimeData.INT:
                        {
                          execDesc.setConstInt(value.getInt());
                          break;
                        }
                      case RuntimeData.DOUBLE:
                        {
                          execDesc.setConstDouble(value.getDouble());
                          break;
                        }
                      case RuntimeData.FLOAT:
                        {
                          execDesc.setConstFloat(value.getFloat());
                          break;
                        }
                      case RuntimeData.DECIMAL:
                        {
                          //Get scale for decimal
                          short scale = columnInfo.getOrgScale();
                          execDesc.setConstDecimal(value.getBigDecimal());
                          execDesc.setScale(scale);
                          break;
                        }
                      
                      default:
                        {
                          throw new WrapperException("Fetch: Unknown data type!");
                        }
      	            }
      	         }
      	         else  //Set scale for the form of column = unbound or unbound = column
      	         {
      	            short scale = columnInfo.getOrgScale();
                    execDesc.setScale(scale);
      	         }
                 
                 //Change the predicate to FileExecDesc.EQUAL
                 predicate = FileExecDesc.EQUAL;
      	         reply.addPredicate(expression);
      	         break;
      	      }
      	   }
      	}
      }
      
      //Set the predicate
      execDesc.setPredicate(predicate);
      //Set exec descriptor
      reply.setExecDesc(execDesc);
      //print the request for debugging & tracing
      printRequest(request);

      return reply;
    }
    else // numberOfQuantifies > 1
    {
      // for more than one quantifier we can't return any plan
      // return a null reply
      return null;
    }
  }

  /**
   * Print the Request object that contains the query fragment to be printed.
   * This function is used for debugging/tracing purposes.
   *
   * @param request                 The Request object that contains the query to be printed.
   *
   * @exception Exception           if the procesing fails.
   */
  private void printRequest(Request request) throws Exception
  {
    StringBuffer sBuffer = new StringBuffer();
    int n = request.getNumberOfHeadExp();

    sBuffer.append("\nSELECT ");

    for(int i = 1; i <= n; i++)
    {
      RequestExp e = request.getHeadExp(i);
      sBuffer.append("(");
      printRequestExp(e, sBuffer);
      sBuffer.append(")");
      if( i < n )
      {
        sBuffer.append(", ");
      }
    }
    sBuffer.append("\nFROM ");

    n = request.getNumberOfQuantifiers();
    for(int i = 1; i <= n; i++)
    {
      UnfencedGenericNickname nick = request.getQuantifier(i).getNickname();
      sBuffer.append(nick.getLocalSchema() + "." + nick.getLocalName());
      if( i < n )
      {
        sBuffer.append(", ");
      }
    }

    sBuffer.append("\n");

    n = request.getNumberOfPredicates();
    if( n > 0 )
    {
      sBuffer.append("WHERE ");
      for(int i = 1; i <= n; i++)
      {
        RequestExp e = request.getPredicate(i);
        sBuffer.append("(");
        printRequestExp(e, sBuffer);
        sBuffer.append(")");
        if( i < n )
        {
          sBuffer.append(", ");
        }
      }

      sBuffer.append("\n");
    }

    WrapperUtilities.traceFunctionData(0, "printRequest", 1, sBuffer.toString());
  }

  /**
   * Print the RequestExp object that contains an expression, part of the query to be planned.
   * This function is used for debugging/tracing purposes.
   *
   * @param expression              The RequestExp object that contains the expression to be printed.
   * @param sBuffer                 The string buffer where the expression is printed to.
   *
   * @exception Exception           if the procesing fails.
   */
  private void printRequestExp(RequestExp expression, StringBuffer sBuffer) throws Exception
  {
    int kind = expression.getKind();

    switch(kind)
    {
      case RequestExp.BADKIND:
        sBuffer.append("[<bad kind>]");
        break;
      case RequestExp.COLUMN:
        sBuffer.append("[<column kind>");
        sBuffer.append( expression.getColumnName());
        sBuffer.append("]");
        break;
      case RequestExp.CONSTANT:
        sBuffer.append("[<constant kind>");
        sBuffer.append( expression.getValue().getObject().toString() );
        sBuffer.append("]");
        break;
      case RequestExp.OPERATOR:
        sBuffer.append("[<operator kind>");
        sBuffer.append( expression.getToken());
        int n = expression.getNumberOfChildren();
        RequestExp e = null;
        for(int i = 1; i <= n; i++ )
        {
          e = i == 1? expression.getFirstChild() : e.getNextChild();
          printRequestExp(e, sBuffer);
        }
        sBuffer.append("]");
        break;
      case RequestExp.UNBOUND:
        sBuffer.append("[<unbound kind>]");
        break;
      default:
        sBuffer.append("[<unknown kind>]");
    }
  }
}
