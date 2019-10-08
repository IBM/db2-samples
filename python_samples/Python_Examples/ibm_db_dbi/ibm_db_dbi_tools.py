#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db_tools.py                                                                      #
#                                                                                                 #
#  PURPOSE:  This file contains classes and functions that are used by some of the ibm_db_dbi     #
#            sample programs.                                                                     #
#                                                                                                 #
#            Cursor functions used:                                                               #
#                 execute()                                                                       #
#                 fetchone()                                                                      #
#                                                                                                 #
#  USAGE:    Add the following line of code at the beginning of an ibm_db_dbi sample program:     #
#                                                                                                 #
#            from ibm_db_dbi_tools import get_row_count                                           #
#                                                                                                 #
#-------------------------------------------------------------------------------------------------#
#                      DISCLAIMER OF WARRANTIES AND LIMITATION OF LIABILITY                       #
#                                                                                                 #
#  (C) COPYRIGHT International Business Machines Corp. 2018, 2019 All Rights Reserved             #
#  Licensed Materials - Property of IBM                                                           #
#                                                                                                 #
#  US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP   #
#  Schedule Contract with IBM Corp.                                                               #
#                                                                                                 #
#  The following source code ("Sample") is owned by International Business Machines Corporation   #
#  or one of its subsidiaries ("IBM") and is copyrighted and licensed, not sold. You may use,     #
#  copy, modify, and distribute the Sample in any form without payment to IBM, for the purpose of #
#  assisting you in the creation of Python applications using the ibm_db_dbi library.             #
#                                                                                                 #
#  The Sample code is provided to you on an "AS IS" basis, without warranty of any kind. IBM      #
#  HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR IMPLIED, INCLUDING, BUT NOT       #
#  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.    #
#  Some jurisdictions do not allow for the exclusion or limitation of implied warranties, so the  #
#  above limitations or exclusions may not apply to you. IBM shall not be liable for any damages  #
#  you suffer as a result of using, copying, modifying or distributing the Sample, even if IBM    #
#  has been advised of the possibility of such damages.                                           #
#-------------------------------------------------------------------------------------------------#

# Load The Appropriate Python Modules
import sys         # Provides Information About Python Interpreter Constants, Functions, & Methods
import ibm_db_dbi  # Contains The APIs Needed To Work With Db2 Databases

#-------------------------------------------------------------------------------------------------#
#  FUNCTION NAME:  get_row_count()                                                                #
#  PURPOSE:        This function queries the Db2 table specified and displays the number of rows  #
#                  (records) found in it.                                                         #
#  PARAMETERS:     dbCursor   - A cursor object associated with a valid Db2 database connection   #
#                  tableName  - Name of the table to be queried                                   #
#  RETURNS:        True       - A row count was obtained for the table specified                  #
#                  False      - A row count could not be obtained for the table specified         #
#-------------------------------------------------------------------------------------------------#
def get_row_count(dbCursor, tableName):
    
    # Define And Initialize The Appropriate Local Variables
    resultSet = False

    # Create The SQL Statement To Be Executed
    sqlStatement = "SELECT COUNT(*) FROM " + tableName + " WITH UR"

    # Execute The SQL Statement Just Defined
    try:
        resultSet = dbCursor.execute(sqlStatement)
    except Exception:
        pass

    # If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
    if resultSet is False:
        print("\nERROR: Unable to execute the statement specified:")
        print("  " + sqlStatement + "\n")
        return False

    # Retrieve The Data Produced By The SQL Statement And Store It In A Python Tuple
    resultSet = None
    try:
        resultSet = dbCursor.fetchone()
    except:
        pass

    # If The Data Could Not Be Retrieved Or There Was No Data To Retrieve, Display An Error 
    # Message And Return The Value "False"
    if resultSet is None:
        print("\nERROR: Unable to retrieve the data produced by the SQL statement.")
        return False

    # Otherwise, Display The Data Retrieved
    else:
        print("Number of records found in the " + tableName + " table: ", end="")
        print("{}\n" .format(resultSet[0])) 
    
    # Return The Value "True" To The Calling Function
    return True
