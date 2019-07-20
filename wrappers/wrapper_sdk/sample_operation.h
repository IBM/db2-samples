/**********************************************************************
*
*  Source File Name = sample_operation.h
*
*  (C) COPYRIGHT International Business Machines Corp. 2003,2004
*  All Rights Reserved
*  Licensed Materials - Property of IBM
*
*  US Government Users Restricted Rights - Use, duplication or
*  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
*
*  Function = Include File defining: sample operation related classes
*
*  Operating System = All
*
***********************************************************************/
#ifndef __SAMPLE_OPERATION_H__
#define __SAMPLE_OPERATION_H__

#include "sample_typedefs.h"

#include "sqlqg_operation.h"
#include "sqlqg_utils.h"
#include "sqlqg_catalog.h"
#include "sqlcodes.h"
#include "sqlcli.h"
#include <float.h>
#include <stdio.h>
#include <ctype.h>
#include <math.h>

//////////////////////////////////////////////////////////////////////////////
// Sample_Query subclass
//////////////////////////////////////////////////////////////////////////////
enum  result  {NO_MATCH,MATCH};

class Sample_Query : public Remote_Query {
public:
  // Constructor.
  Sample_Query(Remote_Connection *active_connection,
               Runtime_Operation *runtime_query,
               sqlint32 *rc);
  
  // Destructor.
  virtual ~Sample_Query();
  
  // Runtime routines.
  virtual sqlint32 open();                           // opens a query.
  virtual sqlint32 reopen(sqlint16 status);          // reopens a query.
  virtual sqlint32 fetch();                          // fetches a row.
  virtual sqlint32 close(sqlint16 status);           // closes a query. 
  
protected:
   
  ////////////////
  // Data.
  ////////////////
  int              *mColumnVector;  // Pointer to an array of integers
                                    // that contain the offset to the 
                                    // selected data elements
  columnData        *mData;         // Pointer to an array of columnData structures.
  FILE              *mFile;         // File pointer for flat file
  int               mNumColumns;    // Number of columns in the table
  myboolean         mFinished;      // Used to signal the end of the search
  char              **mTokens;      // Array to hold the tokenized column data
  char              *mBuffer;       // Buffer hold a line of data.
  void*             mExecDesc;      // To keep a copy of exec descriptor at open
  
  char              *mSearchTerm;   // Used to hold the predicate term
  char              mSearchTermBind[MAX_VARCHAR_LENGTH];   //Buffer to hold predicate term for unbound
  relOperator       mPredOperator;  // Predicate operator '='
  int               mKeyVector;     // To record the column number
  char*             mFilePath;      // Indicate the path of the file data
  int               mBindIndex;      // To record the unbound index   
  result            mResult;        // Result of the search comparison.
  

  ////////////////
  // Methods.
  ////////////////
  sqlint32   build_data_area(int mNumColumns, columnData *mData);
  sqlint32   table_scan();
  sqlint32   do_compare();
  sqlint32   compare(int);
  sqlint32   compare(short);
  sqlint32   compare(float);
  sqlint32   compare(double);
  sqlint32   compare(char *);
  sqlint32   compare(char *,int,int);
  sqlint32   save(char *, int);
  sqlint32   build_decimal_string(char **, char *, int, int, int *);
  sqlint32   get_data();
  sqlint32   pack(char *, char **);
  sqlint32   format_packed_decimal(int,int,int);
  sqlint32   tokenize(sqluint8 *buffer, int colCount, sqluint8 **tokens);

};

//////////////////////////////////////////////////////////////////////////////
// Sample_Passthru subclass
//////////////////////////////////////////////////////////////////////////////

class Sample_Passthru : public Remote_Passthru {
public:
  // Constructor.
  Sample_Passthru(Remote_Connection *active_connection,
                  Runtime_Operation* runtime_passthru, sqlint32 *rc);
  // Destructor.
  virtual ~Sample_Passthru();

  // Runtime routines.
  sqlint32 prepare(Runtime_Data_Desc_List*);     // prepares a passthru
                                                 // session at a remote source.
  sqlint32 describe(Runtime_Data_Desc_List *);   // describes result set of a
                                                 // statement executed via a
                                                 // passthru session.
  sqlint32 execute();                            // executes a statement
                                                 // via a passthru session.
  sqlint32 open();                               // opens a cursor for
                                                 // a passthru session.
  sqlint32 fetch();                              // fetches a row from a
                                                 // passthru cursor.
  sqlint32 close();                              // closes a passthru cursor.
  
protected:

  ////////////////
  // Data.
  ////////////////
};



#endif
