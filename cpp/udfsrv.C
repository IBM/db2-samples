/****************************************************************************
** (c) Copyright IBM Corp. 2007 All rights reserved.
** 
** The following sample of source code ("Sample") is owned by International 
** Business Machines Corporation or one of its subsidiaries ("IBM") and is 
** copyrighted and licensed, not sold. You may use, copy, modify, and 
** distribute the Sample in any form without payment to IBM, for the purpose of 
** assisting you in the development of your applications.
** 
** The Sample code is provided to you on an "AS IS" basis, without warranty of 
** any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
** IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
** MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
** not allow for the exclusion or limitation of implied warranties, so the above 
** limitations or exclusions may not apply to you. IBM shall not be liable for 
** any damages you suffer as a result of using, copying, modifying or 
** distributing the Sample, even if IBM has been advised of the possibility of 
** such damages.
*****************************************************************************
**
** SOURCE FILE NAME: udfsrv.C
**
** SAMPLE: Defines a variety of types of user-defined functions
**          
**         This file contains the user defined functions called by udfcli.sqC
**
** OUTPUT FILE: udfcli.out (available in the online documentation)
*****************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing C++ applications, see the Application
** Development Guide.
**
** For the latest information on programming, compiling, and running DB2
** applications, visit the DB2 application development website at
**     http://www.software.ibm.com/data/db2/udb/ad
****************************************************************************/
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlca.h>
#include <sqludf.h>

#if(defined(DB2NT))
  #define PATH_SEP "\\"
  // Required include for WINDOWS version of TblUDFClobFromFile   
  #include "io.h"
  #include "windows.h"
  #include <errno.h>
#else // UNIX 
  #define PATH_SEP "/"
  // Required include for UNIX version of TblUDFClobFromFile 
  #include <sys/types.h>
  #include <dirent.h>
#endif


#ifdef __cplusplus
extern "C"
#endif
void SQL_API_FN ScalarUDF(SQLUDF_CHAR *inJob,
                          SQLUDF_DOUBLE *inSalary,
                          SQLUDF_DOUBLE *outNewSalary,
                          SQLUDF_SMALLINT *jobNullInd,
                          SQLUDF_SMALLINT *salaryNullInd,
                          SQLUDF_SMALLINT *newSalaryNullInd,
                          SQLUDF_TRAIL_ARGS)
{
  if (*jobNullInd == -1 || *salaryNullInd == -1)
  {
    *newSalaryNullInd = -1;
  }
  else
  {
    if (strcmp(inJob, "Mgr  ") == 0)
    {
      *outNewSalary = *inSalary * 1.20;
    }
    else if (strcmp(inJob, "Sales") == 0)
    {
      *outNewSalary = *inSalary * 1.10;
    }
    else // it is a clerk
    {
      *outNewSalary = *inSalary * 1.05;
    }
    *newSalaryNullInd = 0;
  }
} //ScalarUDF

struct scalar_scratchpad_data
{
  int counter;
};

#ifdef __cplusplus
extern "C"
#endif
void SQL_API_FN ScratchpadScUDF(SQLUDF_INTEGER *outCounter,
                                SQLUDF_SMALLINT *counterNullInd,
                                SQLUDF_TRAIL_ARGS_ALL)
{
  struct scalar_scratchpad_data *pScratData;

  // SQLUDF_CALLT and SQLUDF_SCRAT are
  // parts of SQLUDF_TRAIL_ARGS_ALL

  pScratData = (struct scalar_scratchpad_data *)SQLUDF_SCRAT->data;
  switch (SQLUDF_CALLT)
  {
    case SQLUDF_FIRST_CALL:
      pScratData->counter = 1;
      break;
    case SQLUDF_NORMAL_CALL:
      pScratData->counter = pScratData->counter + 1;
      break;
    case SQLUDF_FINAL_CALL:
      break;
  }

  *outCounter = pScratData->counter;
  *counterNullInd = 0;
} //ScratchpadScUDF

#ifdef __cplusplus
extern "C"
#endif
void SQL_API_FN ClobScalarUDF(SQLUDF_CLOB *inClob,
                              SQLUDF_INTEGER *outNumWords,
                              SQLUDF_SMALLINT *clobNullInd,
                              SQLUDF_SMALLINT *numWordsNullInd,
                              SQLUDF_TRAIL_ARGS)
{
  SQLUDF_INTEGER i;

  *outNumWords = 0;

  // skip the first spaces
  for (i = 0; i < inClob->length && inClob->data[i] == ' '; i++);

  while (i < inClob->length)
  {
    *outNumWords = *outNumWords + 1;

    // reach the end of the word
    for (; inClob->data[i] != ' ' && i < inClob->length; i++);

    // skip the next spaces
    for (; inClob->data[i] == ' ' && i < inClob->length; i++);
  }
  *numWordsNullInd = 0;
} //ClobScalarUDF

#ifdef __cplusplus
extern "C"
#endif
void SQL_API_FN ScUDFReturningErr(SQLUDF_DOUBLE *inOperand1,
                                  SQLUDF_DOUBLE *inOperand2,
                                  SQLUDF_DOUBLE *outResult,
                                  SQLUDF_SMALLINT *operand1NullInd,
                                  SQLUDF_SMALLINT *operand2NullInd,
                                  SQLUDF_SMALLINT *resultNullInd,
                                  SQLUDF_TRAIL_ARGS)
{
  // SQLUDF_STATE and SQLUDF_MSGTX are parts of SQLUDF_TRAIL_ARGS
  if (*inOperand2 == 0.00)
  {
    strcpy(SQLUDF_STATE, "38999");
    strcpy(SQLUDF_MSGTX, "DIVIDE BY ZERO ERROR");
  }
  else
  {
    *outResult = *inOperand1 / *inOperand2;
    *resultNullInd = 0;
  }
} //ScUDFReturningErr

// Scratchpad data structure
struct scratch_area
{
  int file_pos;
};

struct person
{
  char *name;
  char *job;
  char *salary;
};

// Following is the data buffer for this example.
// You may keep the data in a separate text file.
// See "Application Development Guide" on how to work with
// a data file instead of a data buffer.
struct person staff[] =
{
  {"Pearce", "Mgr", "17300.00"},
  {"Wagland", "Sales", "15000.00"},
  {"Davis", "Clerk", "10000.00"},
  // Do not forget a null terminator
  {(char *)0, (char *)0, (char *)0}
};

#ifdef __cplusplus
extern "C"
#endif
void SQL_API_FN TableUDF(// Return row fields
                         SQLUDF_DOUBLE *inSalaryFactor,
                         SQLUDF_CHAR *outName,
                         SQLUDF_CHAR *outJob, SQLUDF_DOUBLE *outSalary,
                         // Return row field null indicators
                         SQLUDF_SMALLINT *salaryFactorNullInd,
                         SQLUDF_SMALLINT *nameNullInd,
                         SQLUDF_SMALLINT *jobNullInd,
                         SQLUDF_SMALLINT *salaryNullInd,
                         SQLUDF_TRAIL_ARGS_ALL)
{
  struct scratch_area *pScratArea;
  pScratArea = (struct scratch_area *)SQLUDF_SCRAT->data;

  // SQLUDF_CALLT, SQLUDF_SCRAT, SQLUDF_STATE and SQLUDF_MSGTX are
  // parts of SQLUDF_TRAIL_ARGS_ALL
  switch (SQLUDF_CALLT)
  {
    case SQLUDF_TF_OPEN:
      pScratArea->file_pos = 0;
      break;
    case SQLUDF_TF_FETCH:
      // Normal call UDF: Fetch next row
      if (staff[pScratArea->file_pos].name == (char *)0)
      {
        // SQLUDF_STATE is part of SQLUDF_TRAIL_ARGS_ALL
        strcpy(SQLUDF_STATE, "02000");
        break;
      }
      strcpy(outName, staff[pScratArea->file_pos].name);
      strcpy(outJob, staff[pScratArea->file_pos].job);
      *nameNullInd = 0;
      *jobNullInd = 0;

      if (staff[pScratArea->file_pos].salary != (char *)0)
      {
        *outSalary = (*inSalaryFactor) *
          atof(staff[pScratArea->file_pos].salary);
        *salaryNullInd = 0;
      }

      // Next row of data
      pScratArea->file_pos++;
      break;
    case SQLUDF_TF_CLOSE:
      break;
    case SQLUDF_TF_FINAL:
      // close the file
      pScratArea->file_pos = 0;
      break;
  }
} //TableUDF


/****************************************************************************************
  NOTE:
        VERSIONS:
        There are 2 versions of the following table function -  one is defined for
        Windows (98, Me, NT, 2000, XP), the other for UNIX.  The UNIX (POSIX standard)
        version follows just below the Windows version.  Look for #else below.
        The Windows version uses _findfirst, _findnext and _findclose methods
        for accessing filesystem directory entries, whereas the UNIX version
        uses opendir, readdir, closedir methods.

        INPUTS/OUTPUTS:
        This table function takes as input a fully qualified path directory name.
        It returns a table conisting of a varchar column for the name of the directory
        entry and a clob containing its contents if it is a file; if it is a subdirectory
        a NULL clob is returned.  If the file cannot be accessed for reading, or if the
        contents of the file exceeds the clob size specified in the catalog registration
        of the function SQL warnings will be raised.  An empty table may be the result of
        an invalid directory path name input. Verify that the directory exists on your
        system.

        SECURITY TIP:
        Because this table function reads files residing on the database server, it is
        advisable that caution be taken when granting execute priviliges of this function
        to database users.

 ****************************************************************************************/
#if(defined(DB2NT))

// ** WINDOWS VERSION of TBLUDFCLOBFROMFILE SAMPLE **

// Scratchpad data structure for ClobFromFile 
struct SCRATCHDATA 
{
  long maxClobSize;            // Max length of data output clob can contain 
  long *hFile;                 // Array of handles 
  short level;                 // Handle level (index) 
  struct _finddata_t fileinfo; // Stores file-attribute information returned by
                               // _findfirst and _findnext 
  int done;                    // Flag indicating completion 
  char *tmp;                   // Directory path name 
};


#ifdef __cplusplus
extern "C"
#endif
void SQL_API_FN TblUDFClobFromFile (SQLUDF_VARCHAR        *inDir,
                                    SQLUDF_VARCHAR        *outFileName,
                                    SQLUDF_CLOB           *outClobFile,
                                    SQLUDF_SMALLINT       *dirNullInd,
                                    SQLUDF_SMALLINT       *FileNameNullInd, 
                                    SQLUDF_SMALLINT       *ClobFileNullInd,
                                    SQLUDF_TRAIL_ARGS_ALL)
{ 
  FILE *f;          // File to make into clob          
  char tmp2[256];   // Working directory or file name   
  char *pchr;       // Pointer to "/" char in a string  
  short hdir;       // Flag if directory is "." or ".." 
  long len;         // Get dir pathname length
  
  struct SCRATCHDATA *sp;
  sp = (struct SCRATCHDATA *) SQLUDF_SCRAT->data;
  
  switch (SQLUDF_CALLT) 
  {
    case SQLUDF_TF_FIRST:
    {
      // Initialize Scratchpad 
      sp->hFile = (long *)malloc(50 * sizeof(long)); 
      sp->tmp = (char*)malloc(256);
      sp->level = 0;
      sp->maxClobSize=outClobFile->length;
      break;
    }

    case SQLUDF_TF_OPEN:
    {
      // Copy input directory name into scratchpad space
      strcpy (sp->tmp, inDir);
	
      /* Ensure directory name ends in "/" char  */
      len = strlen(sp->tmp) -1;	 
      if (sp->tmp[len] != '/')
      {
        sp->tmp[len+1] = '/';
        sp->tmp[len+2] = '\0';
      }

      // Copy the input directory name, and append a  "*" (wildcard) 
      // symbol to copy - to be used as search condition in call to _findfirst
      strcpy(tmp2, sp->tmp);
      len = strlen(tmp2);
      tmp2[len] = '*';
      tmp2[len+1] = '\0';
            
      // Get a search handle on the file or group of files that satisfy the search condition (in tmp2) 
      // The first found file's name & attributes are stored in the scratchpad fileinfo struct.        
      // The search handle offset is also stored to be used in subsequuent calls to _findnext or _findclose    
      sp->hFile[sp->level] = _findfirst (tmp2, &(sp->fileinfo));
      if (sp->hFile[sp->level] == 0)
        sp->done = 1;       // empty dir 
      else
        sp->done = 0;       // entries found 
      break;
    }
      
    case SQLUDF_TF_FETCH:
    {
      // If done transforming files (if any) in current directory 
      if (sp->done)
      {
        // While open search handles remain and done with files in this dir 
        while ((sp->level > 0) && (sp->done))
        {
          // Close the specified search handle and decrement search handle level 
          _findclose (sp->hFile[sp->level]);
          sp->level--;
          
          // Truncate lowest level dir name from directory path (ie. working way back up from sub-directories) 
          strcpy (&sp->tmp[strlen(sp->tmp)-1], "\0");
          pchr = strrchr (sp->tmp, '/') + 1;
          *pchr = '\0';
          
          // Look for the next unvisted file or directory using current search handle 
          sp->done = _findnext (sp->hFile[sp->level], &(sp->fileinfo)); 
        }
        
        if (sp->done)
        {
          // No more files or sub-directories - exit FETCH mode 
          strcpy( SQLUDF_STATE, "02000");
          break;
        }
      }	    
      
      // File found - set the output filename 
      strcpy (outFileName, sp->tmp);
      strcpy (&outFileName[strlen(outFileName)], sp->fileinfo.name);
      *FileNameNullInd = 0;
      
      // If the current file is a sub-directory 	
      if (sp->fileinfo.attrib & _A_SUBDIR)
      {
        // Return a NULL column value for file contents 
        *ClobFileNullInd = -1;
        
        // Set the new dir search path using this sub-directory 
        sp->level++;
        strcpy (&sp->tmp[strlen(sp->tmp)], sp->fileinfo.name);
        strcpy (&sp->tmp[strlen(sp->tmp)], "/");
        
        // Set the dir search condition - use "*" wildcard 
        strcpy (tmp2, sp->tmp);
        len = strlen(tmp2);
        tmp2[len] = '*';
        tmp2[len+1] = '\0';
      
        // Set flag if filename is a relative dir  
        if (!strcmp(sp->fileinfo.name, ".") ||
            !strcmp(sp->fileinfo.name, ".."))
          hdir = 1;
        else
          hdir = 0;
        
        // Look for files in the subdirectory 
        sp->hFile[sp->level] = _findfirst (tmp2, &(sp->fileinfo));
        if (sp->hFile[sp->level] == 0)
        {
          sp->done = 1;       // empty - no files 
        }
        else
        {
          sp->done = 0;       // File found 
          if (hdir)           // If it was a relative dir (. or ..) 
          {
            sp->done = 1;     // ignore this file 
          }
        }
      }
      else  // we have a regular file 
      {
        // Open the file for buffered read 
        f = fopen (outFileName, "rb");
        
        if (f == NULL)
        {
          // Unable to open file for buffered read 
          strcpy( SQLUDF_STATE, SQLUDF_STATE_WARN);
          strcpy( SQLUDF_MSGTX, "Open failed");
          *ClobFileNullInd = -1;
        } 
        else 
        {
          // Check if file contents are larger than max space allowed for scratchpad 
          if (sp->fileinfo.size > sp->maxClobSize)
          {
            // File size too big to assign to putput parameter outClobFile 
            strcpy( SQLUDF_STATE, SQLUDF_STATE_WARN);
            sprintf (tmp2, "%s size %d bytes", sp->fileinfo.name, sp->fileinfo.size); 
            strcpy( SQLUDF_MSGTX, tmp2);
          }
          
          // Copy file contents into output clob, and set clob length 
          outClobFile->length = fread (outClobFile->data, 1, sp->maxClobSize, f);
          fclose (f);
        }
        
        // Set flag if we are done by checking for any next files to process 
        sp->done = _findnext (sp->hFile[sp->level], &(sp->fileinfo)); 
      }          
      break;
    }

    case SQLUDF_TF_CLOSE:
    {
      // close handles, free resources used by _find* functions 
      _findclose (sp->hFile[sp->level]);
      break;
    }        
    
    case SQLUDF_TF_FINAL:
    {
      break;
    }
  }
  return;
} //TblUDFClobFromFile - Windows Version

#else

// ** UNIX VERSION OF TBLUDFCLOBFROMFILE SAMPLE **


// Scratchpad data structure for ClobFromFile
struct SCRATCHDATA 
{
  DIR *d;                   // Open directory     
  struct dirent *dirEntry;  // Directory entry    
  long maxClobSize;         // Limit of Clob Size 
  char dirpath[256];        // Directory path     
};


#ifdef __cplusplus
extern "C"
#endif
void SQL_API_FN TblUDFClobFromFile (SQLUDF_VARCHAR    *inDir,     
                                    SQLUDF_VARCHAR    *outFileName,
                                    SQLUDF_CLOB       *outClobFile,
                                    SQLUDF_SMALLINT   *DirNullInd, 
                                    SQLUDF_SMALLINT   *FileNameNullInd, 
                                    SQLUDF_SMALLINT   *ClobFileNullInd,
                                    SQLUDF_TRAIL_ARGS_ALL)
{ 
  char fnamepath[256];   // File path name 
  DIR *isDir;            // Dir to check if entry is a dir 
  FILE *f;               // File to copy data from 
  char errMsg[256];      // Error message buffer 
  long lSize = 0;        // Size of file data 
  long len;              // To get pathname length 
  
  struct SCRATCHDATA *sp;
  sp = (struct SCRATCHDATA *) SQLUDF_SCRAT->data;
  
  switch (SQLUDF_CALLT) 
  {
    case SQLUDF_TF_FIRST:
      // Initialize Scratchpad 
      sp->maxClobSize = outClobFile->length;
      break;
      
    case SQLUDF_TF_OPEN:
      // Copy input directory name to scratchpad 
      strcpy (sp->dirpath, inDir);
      
      /* Ensure directory name ends in "/" char  */
      len = strlen(sp->dirpath) -1;      
      if (sp->dirpath[len] != '/')
      {
        sp->dirpath[len+1] = '/';
        sp->dirpath[len+2] = '\0';
      }

      // Open the directory 
      if ((sp->d = opendir(sp->dirpath)) == NULL)
      {
        strcpy( SQLUDF_STATE, SQLUDF_STATE_WARN);
        sprintf (errMsg, "Open failed for directory %s", sp->dirpath);
        strcpy( SQLUDF_MSGTX, errMsg);
        break;
      }
      break;
      
    case SQLUDF_TF_FETCH:
      // When there are no more directory entries, return done 
      if ((sp->dirEntry = readdir(sp->d)) == NULL)
      { 
        strcpy( SQLUDF_STATE, "02000");
        break;
      }
      else // Process directory entries 
      {
        // Build up file path name 
        strcpy(fnamepath, sp->dirpath);
        strcat(fnamepath, sp->dirEntry->d_name);

        // Set outFileName for this directory entry 
        strcpy(outFileName, fnamepath);
        *FileNameNullInd = 0;

        // Check for/Skip the "." and ".." directory entries 
        if ((strcmp(sp->dirEntry->d_name, ".") == 0) &&
            (strcmp(sp->dirEntry->d_name,"..") == 0))
        {
          *ClobFileNullInd = -1;
        }
        // Test if it is a directory - if not, presume it is a file 
        else if ((isDir = opendir(fnamepath)) != NULL)
        {
          *ClobFileNullInd = -1;
          closedir(isDir);
        }
        else // NOT a directory 
        {
          // Open the file 
          f = fopen (fnamepath, "rb");
          
          if (f == NULL)
          {
            *ClobFileNullInd = -1;
            // Unable to open file for buffered read 
            strcpy( SQLUDF_STATE, SQLUDF_STATE_WARN);
            sprintf (errMsg, "Open failed for file %s ", fnamepath); 
            strcpy( SQLUDF_MSGTX, errMsg);
          }
          else
          {
            // Obtain file size 
            fseek (f , 0 , SEEK_END);
            lSize = ftell (f);
            rewind (f);
            
            // Check if file contents are larger than max space allowed for scratchpad 
            if (lSize > sp->maxClobSize)
            {
              *ClobFileNullInd = -1;
              strcpy( SQLUDF_STATE, SQLUDF_STATE_WARN);
              sprintf (errMsg, "File %s size exceeds max clob size: %d", fnamepath, sp->maxClobSize); 
              strcpy( SQLUDF_MSGTX, errMsg);
            }
            else
            {
              // Copy file contents into output parameter outClobFile, and set the clob length 
              fread (outClobFile->data, 1, lSize, f);
              outClobFile->length = lSize;
              *ClobFileNullInd = 0;
            }
          }
          fclose (f);
        }
      }
      break;
      
    case SQLUDF_TF_CLOSE:
     if (closedir(sp->d) == -1)
     {
       strcpy( SQLUDF_STATE, SQLUDF_STATE_WARN);
       sprintf (errMsg, "Close of directory %s failed\n", sp->dirpath);
       strcpy( SQLUDF_MSGTX, errMsg);
     }
     break;
     
    case SQLUDF_TF_FINAL:
     break;
  }
}//TblUDFClobFromFile - UNIX Version



#endif
