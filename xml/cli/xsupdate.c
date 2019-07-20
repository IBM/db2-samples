/***************************************************************************
**   (c) Copyright IBM Corp. 2007 All rights reserved.
**   
**   The following sample of source code ("Sample") is owned by International 
**   Business Machines Corporation or one of its subsidiaries ("IBM") and is 
**   copyrighted and licensed, not sold. You may use, copy, modify, and 
**   distribute the Sample in any form without payment to IBM, for the purpose of 
**   assisting you in the development of your applications.
**   
**   The Sample code is provided to you on an "AS IS" basis, without warranty of 
**   any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
**   IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
**   MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
**   not allow for the exclusion or limitation of implied warranties, so the above 
**   limitations or exclusions may not apply to you. IBM shall not be liable for 
**   any damages you suffer as a result of using, copying, modifying or 
**   distributing the Sample, even if IBM has been advised of the possibility of 
**   such damages.
** *************************************************************************
**                                                                          
**  SAMPLE FILE NAME: xsupdate.c                                          
**                                                                          
**  PURPOSE:  To demonstrate how to update an existing XML schema with
**            a new schema that is compatible with the original schema
**                                                                          
**  USAGE SCENARIO: A store manager maintains product details in an XML     
**                  document that conforms to an XML schema. The product     
**                  details are: Name, SKU and Price. The store manager      
**                  wants to add a product description for each of the         
**                  products along with the existing product details.                     
**                                                                          
**  PREREQUISITE: The original schema and the new schema should be     
**                present in the same directory as the sample.             
**                Copy prod.xsd, newprod.xsd from directory    
**                <install_path>/xml/data to the working directory.                           
**                                                                          
**  EXECUTION:    i)  bldapp xsupdate  ( build and compile the sample)
**                ii) xsupdate         ( run the sample)
**                                                                          
**  INPUTS:       NONE
**                                                                          
**  OUTPUTS:      Updated schema and successful insertion of the XML documents 
**                with the new product descriptions.                                              
**                                                                          
**  OUTPUT FILE:  xsupdate.out (available in the online documentation)      
**                                     
**  SQL STATEMENTS USED:        
**         CREATE  
**         INSERT
**         DROP
**                                                                          
**  SQL PROCEDURES USED: 
**         XSR_REGISTER
**         XSR_COMPLETE
**         XSR_UPDATE                                                        
**                                                                         
**  SQL/XML FUNCTIONS USED:                                                  
**         XMLVALIDATE                                                       
**         XMLPARSE
**
** CLI FUNCTIONS USED:
**         SQLAllocHandle -- Allocate Handle
**         SQLBindCol     -- Bind a Column to an Application Variable or
**                           LOB locator
**         SQLConnect     -- Connect to a Data Source
**         SQLDisconnect  -- Disconnect from a Data Source
**         SQLEndTran     -- End Transactions of a Connection
**         SQLExecDirect  -- Execute a Statement Directly
**         SQLFreeHandle  -- Free Handle Resources
**  
** *************************************************************************
**
** For more information on the sample programs, see the README file.
**
** For information on developing CLI applications, see the CLI Guide
** and Reference.
**
** For information on using SQL statements, see the SQL Reference.
**
** For the latest information on programming, building, and running DB2 
** applications, visit the DB2 application development website: 
**     http://www.software.ibm.com/data/db2/udb/ad                          
** *************************************************************************
**
**  SAMPLE DESCRIPTION                                                      
**
** *************************************************************************
**  1. Register the original schema with product details:Name, SKU and Price.
**  2. Register the new schema containing the product description element 
**     along with the existing product details.
**  3. Call the XSR_UPDATE stored procedure to update the original schema.
**  4. Insert an XML document containing the product description elements.      
** *************************************************************************/

#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sqlcli1.h>
#include "utilcli.h" /* Header file for CLI sample code */

// function to register an XML schema
int registerxmlschema(SQLHANDLE hdbc, 
                      char p_rschema[129],
                      char p_name[129],
                      char p_schemalocation[1001],
                      unsigned char filename[1000],
                      SQLSMALLINT filenameLength,
                      SQLUINTEGER fileoptions, 
                      int shred);

// function to update an XML schema
int updatexmlschema(SQLHANDLE hdbc,
                    char p_rschemaOld[129],
                    char p_nameOld[129],
                    char p_rschemaNew[129],
                    char p_nameNew[129],
                    int dropnew);

// function to drop the objects created 
int cleanup(SQLHANDLE hdbc);

int main(int argc, char *argv[])
{
  SQLRETURN rc = SQL_SUCCESS;
  SQLHANDLE henv; /* environment handle */
  SQLHANDLE hdbc; /* connection handle */
  SQLHANDLE hstmt; /* statement handle */
  char dbAlias[SQL_MAX_DSN_LENGTH + 1];
  char user[MAX_UID_LENGTH + 1];
  char pswd[MAX_PWD_LENGTH + 1];
  SQLCHAR *stmt = (SQLCHAR *) "CREATE TABLE store.products(id INT GENERATED ALWAYS AS IDENTITY,details XML)";
  char p_rschema[129];  /* variables used in register schema */
  char p_name[129];
  char p_schemalocation[1001];
  unsigned char filename[1000];
  SQLSMALLINT filenameLength;
  SQLUINTEGER fileoptions = SQL_FILE_READ;
  int shred = 0;
  char p_rschemaOld[129];  /* variables used in update schema */
  char p_nameOld[129];
  char p_rschemaNew[129];
  char p_nameNew[129];
  int dropnew = 1;
  char insstmt[2500];   
  
  /****************************************************************************
  **    SETUP                                                                 
  ** **************************************************************************/

  /* check the command line arguments */
  rc = CmdLineArgsCheck1(argc, argv, dbAlias, user, pswd);
  if (rc != 0)
  {
    return rc;
  }
  
  printf("\nThis sample will show \n 1. How to register an XML schema to the database \n");
  printf(" 2. How to insert an XML document validating against the registered schema  \n");
  printf(" 3. How to update an XML schema with a compatible schema  \n");
 
  /* initialize the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppInit(dbAlias,
                  user,
                  pswd,
                  &henv,
                  &hdbc,
                  (SQLPOINTER)SQL_AUTOCOMMIT_ON);
    if (rc != 0)
   {
     return rc;
   }

   printf("\nCreating the table products \n\n");
   /* allocate the statement handle */
   rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstmt);
   STMT_HANDLE_CHECK(hstmt, hdbc, rc);
   /* execute create table statement */
   rc = SQLExecDirect(hstmt, stmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, rc);
                 
   /****************************************************************************
   ** 1. Register the original schema with product details: Name, SKU and Price.
   ** *************************************************************************/

   /* register the schema STORE.PROD */
   printf("Registering the schema STORE.PROD\n");
   strcpy(p_rschema,"STORE");
   strcpy(p_name,"PROD");
   strcpy(p_schemalocation,"www.prod.com/prod.xsd");
   strcpy((char *)filename,"prod.xsd");
   filenameLength = strlen((char *)filename);
   /* call the function to register the schema */
   registerxmlschema(hdbc,p_rschema,p_name,p_schemalocation,filename,filenameLength,fileoptions,shred);

   /* Insert an XML document into the products table validating 
      against the schema STORE.PROD */
   printf("Insert XML document validating against the schema STORE.PROD \n\n");
   strcpy(insstmt, "INSERT INTO store.products(details) VALUES(XMLVALIDATE( XMLPARSE( DOCUMENT '<products> <product color=\"green\" weight=\"20\"> <name>Ice Scraper, Windshield 4 inch</name> <sku>stores</sku> <price>999</price> </product> <product color=\"blue\" weight=\"40\"> <name>Ice Scraper, Windshield 8 inch</name> <sku>stores</sku> <price>1999</price> </product> <product color=\"green\" weight=\"26\"> <name>Ice Scraper, Windshield 5 inch</name> <sku>stores</sku> <price>1299</price> </product> </products>') ACCORDING TO XMLSCHEMA ID STORE.PROD))");
   /* Execute the statement */
   rc = SQLExecDirect(hstmt, (SQLCHAR *)insstmt, SQL_NTS);
   STMT_HANDLE_CHECK(hstmt, hdbc, rc);

   /*****************************************************************************
   **  2. Register the new schema containing the product description element 
   **     along with the existing product details.                                     
   *****************************************************************************/

   /* register the schema STORE.NEWPROD */
   printf("Registering the schema STORE.NEWPROD\n");

  strcpy(p_rschema,"STORE");
  strcpy(p_name,"NEWPROD" );
  strcpy(p_schemalocation,"www.newprod.com/newprod.xsd");
  strcpy((char *)filename,"newprod.xsd");
  filenameLength = strlen((char *)filename);
  /* call the function to register the schema */
  registerxmlschema(hdbc,p_rschema,p_name,p_schemalocation,filename,filenameLength,fileoptions,shred);

  /****************************************************************************
  **  3. Call the XSR_UPDATE stored procedure to update the original schema.
  *****************************************************************************/

  /* Update schema STORE.PROD with STORE.NEWPROD */
  strcpy(p_rschemaOld,"STORE");
  strcpy(p_nameOld,"PROD");
  strcpy(p_rschemaNew,"STORE");
  strcpy(p_nameNew,"NEWPROD");
  /* call the function to update the schema */
  updatexmlschema(hdbc,p_rschemaOld,p_nameOld,p_rschemaNew,p_nameNew,dropnew);

  /****************************************************************************
  **  4. Insert an XML document containing the product description elements.
  *****************************************************************************/

  /* Insert an XML document into the products table validating
     against the updated schema STORE.PROD */
  strcpy(insstmt, "INSERT INTO store.products(details) VALUES(XMLVALIDATE( XMLPARSE( DOCUMENT '<products> <product color=\"green\" weight=\"20\"> <name>Ice Scraper, Windshield 4 inch</name> <sku>stores</sku> <price>999</price> <description>A new prod</description> </product> <product color=\"blue\" weight=\"40\"> <name>Ice Scraper, Windshield 8 inch</name> <sku>stores</sku> <price>1999</price> <description>A new prod</description> </product> <product color=\"green\" weight=\"26\"> <name>Ice Scraper, Windshield 5 inch</name> <sku>stores</sku> <price>1299</price> </product> </products>') ACCORDING TO XMLSCHEMA ID STORE.PROD))");
  /* Execute the statement */
  rc = SQLExecDirect(hstmt, (SQLCHAR *)insstmt, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);
  
  /* Drop the objects created by calling the function cleanup */
  cleanup(hdbc);

  /* Free the allocated handles */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

  /* terminate the CLI application by calling a helper
     utility function defined in utilcli.c */
  rc = CLIAppTerm(&henv, &hdbc, dbAlias);
  return rc;
}

/* Function to register an XML schema */
int registerxmlschema(SQLHANDLE hdbc,
                      char p_rschema[129],
                      char p_name[129],
                      char p_schemalocation[1001],
                      unsigned char filename[1000],
                      SQLSMALLINT filenameLength,
                      SQLUINTEGER fileoptions,
                      int shred)
{
  int rc = 0;
  SQLHANDLE hstproc=SQL_NULL_HANDLE ;
  char storedproc[100] ;
  SQLINTEGER blob_indicator = 0 ;
  SQLINTEGER name_ind = 0 ;

  name_ind = strlen(p_name);

  /* Register the XML schema */
  /* ****************** */
  rc = SQLAllocHandle(SQL_HANDLE_STMT , hdbc , &hstproc );
  strcpy(storedproc,"CALL SYSPROC.XSR_REGISTER(?,?,?,?,NULL)");
  rc = SQLPrepare(hstproc,(SQLCHAR *)storedproc,SQL_NTS);
  /* bind variables to the parameters */
  rc = SQLBindParameter(hstproc,1,SQL_PARAM_INPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_rschema,
                   strlen(p_rschema),NULL);
  rc = SQLBindParameter(hstproc,2,SQL_PARAM_INPUT_OUTPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_name,
                   (strlen(p_name)+1),&name_ind);
  rc = SQLBindParameter(hstproc,3,SQL_PARAM_INPUT,SQL_C_CHAR,
                   SQL_VARCHAR,1000,0,(SQLPOINTER)p_schemalocation,
                   strlen(p_schemalocation),NULL);
  rc = SQLBindFileToParam(hstproc,4,SQL_BLOB,
                   filename,&filenameLength,&fileoptions,
                   strlen((char *)filename),&blob_indicator);
  printf("Registering the XML Schema... \n");
  rc = SQLExecute(hstproc);
  STMT_HANDLE_CHECK(hstproc, hdbc, rc);
  printf("Registered XML Schema successfully \n");

  /* Complete the XML schema */
  /* ****************** */
  SQLFreeHandle( SQL_HANDLE_STMT , hstproc );
  rc = SQLAllocHandle(SQL_HANDLE_STMT, hdbc, &hstproc);
  strcpy(storedproc,"CALL SYSPROC.XSR_COMPLETE(?,?,NULL,?)");
  rc = SQLPrepare(hstproc,(SQLCHAR *)storedproc,SQL_NTS);
  /* bind variables to the parameters */
  rc = SQLBindParameter(hstproc,1,SQL_PARAM_INPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_rschema,
                   strlen(p_rschema),NULL);
  rc = SQLBindParameter(hstproc,2,SQL_PARAM_INPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_name,
                   strlen(p_name),NULL);
  rc = SQLBindParameter(hstproc,3,SQL_PARAM_INPUT,SQL_C_LONG,
                   SQL_INTEGER,0,0,(SQLPOINTER)&shred,0,NULL);
  printf("completing the XML Schema... \n");
  rc = SQLExecute(hstproc);
  STMT_HANDLE_CHECK(hstproc, hdbc, rc);
  printf("Completed XML Schema successfully \n\n");
   
  /* Free the allocated handles */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstproc);
  STMT_HANDLE_CHECK(hstproc, hdbc, rc);

return 1;
} // registerxmlschema

/* function to update an XML schema */
int updatexmlschema(SQLHANDLE hdbc,
                    char p_rschemaOld[129],
                    char p_nameOld[129],
                    char p_rschemaNew[129],
                    char p_nameNew[129], int dropnew)
{

  int rc = 0;
  SQLHANDLE hstproc = SQL_NULL_HANDLE ;
  char storedproc[100] ;
  SQLINTEGER name_ind1 = 0 ;
  SQLINTEGER name_ind2 = 0 ;

  name_ind1 = strlen(p_nameOld);
  name_ind2 = strlen(p_nameNew);
  
  /* Allocate the handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT , hdbc , &hstproc );
  
  printf("Updating the schema... \n");
  strcpy(storedproc,"CALL SYSPROC.XSR_UPDATE(?,?,?,?,?)");
  rc = SQLPrepare(hstproc,(SQLCHAR *)storedproc,SQL_NTS);
  /* Bind the variables to the parameters */
  rc = SQLBindParameter(hstproc,1,SQL_PARAM_INPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_rschemaOld,
                   strlen(p_rschemaOld),NULL);
  rc = SQLBindParameter(hstproc,2,SQL_PARAM_INPUT_OUTPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_nameOld,
                   sizeof(p_nameOld),&name_ind1);
  rc = SQLBindParameter(hstproc,3,SQL_PARAM_INPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_rschemaNew,
                   strlen(p_rschemaNew),NULL);
  rc = SQLBindParameter(hstproc,4,SQL_PARAM_INPUT_OUTPUT,SQL_C_CHAR,
                   SQL_VARCHAR,128,0,(SQLPOINTER)p_nameNew,
                   sizeof(p_nameNew),&name_ind2);
  rc = SQLBindParameter(hstproc,5,SQL_PARAM_INPUT,SQL_C_LONG,
                   SQL_INTEGER,0,0,(SQLPOINTER)&dropnew,0,NULL);

  /* this stored procedure will update the original schema with the new schema
     if the new schema is compatible with the original one.
     the last parameter is set to a non zero value to drop the schema used to 
     update the original schema, if it is set to zero then the new schema will
     continue to reside in XSR. */
  rc = SQLExecute(hstproc);
  STMT_HANDLE_CHECK(hstproc, hdbc, rc);
  printf("Schema updated successfully \n\n");

  /* Free the allocated handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstproc);
  STMT_HANDLE_CHECK(hstproc, hdbc, rc);

return 1;
} // updatexmlschema

/* function to drop the created objects */
int cleanup(SQLHANDLE hdbc)
{
  int rc = 0;
  SQLHANDLE hstmt=SQL_NULL_HANDLE ;
  char clean[200];

  /* Allocate the handle */
  rc = SQLAllocHandle(SQL_HANDLE_STMT , hdbc , &hstmt );

  printf("cleaning up.... \n");
  
  strcpy(clean,"DROP TABLE store.products");
  printf("%s \n",clean);
  /* Execute the statement */
  rc = SQLExecDirect(hstmt, (SQLCHAR *)clean, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);
  strcpy(clean,"DROP XSROBJECT STORE.PROD");
  printf("%s \n",clean);
  rc = SQLExecDirect(hstmt, (SQLCHAR *)clean, SQL_NTS);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);
  
  /* Free the allocated handle */
  rc = SQLFreeHandle(SQL_HANDLE_STMT, hstmt);
  STMT_HANDLE_CHECK(hstmt, hdbc, rc);

return 1;
} // cleanup
