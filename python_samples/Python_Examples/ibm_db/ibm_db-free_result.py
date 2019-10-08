#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-free_result.py                                                                #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.free_result() API to    #
#            free system resources associated with a prepared SQL statement.                      #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.prepare()                                                                #
#                 ibm_db.execute()                                                                #
#                 ibm_db.num_rows()                                                               #
#                 ibm_db.set_option()                                                             #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-free_result.py                                                              #
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
#  copy, modify, and distribute the Sample in any form without payment to IBM, for the purpose    #
#  of assisting you in the creation of Python applications using the ibm_db library.              #
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
import ibm_db      # Contains The APIs Needed To Work With Db2 Databases

#-------------------------------------------------------------------------------------------------#
# Import The Db2ConnectionMgr Class Definition, Attributes, And Methods That Have Been Defined    #
# In The File Named "ibm_db_tools.py"; This Class Contains The Programming Logic Needed To        #
# Establish And Terminate A Connection To A Db2 Server Or Database                                #
#-------------------------------------------------------------------------------------------------#
from ibm_db_tools import Db2ConnectionMgr

#-------------------------------------------------------------------------------------------------#
# Import The ipynb_exit Class Definition, Attributes, And Methods That Have Been Defined In The   #
# File Named "ipynb_exit.py"; This Class Contains The Programming Logic Needed To Allow "exit()"  #
# Functionality To Work Without Raising An Error Or Stopping The Kernel If The Application Is     #
# Invoked In A Jupyter Notebook                                                                   #
#-------------------------------------------------------------------------------------------------#
from ipynb_exit import exit

# Define And Initialize The Appropriate Variables
dbName = "SAMPLE"
userID = "db2inst1"
passWord = "Passw0rd"
dbConnection = None
preparedStmt = False
resultSet = False
returnCode = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Database
conn = Db2ConnectionMgr('DB', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    dbConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

# Define The SQL Statement That Is To Be Executed
sqlStatement = "SELECT * FROM employee WHERE edlevel > 17"

# Prepare The SQL Statement Just Defined
print("Preparing the SQL statement \"" + sqlStatement + "\" ... ", end="")
try:
    preparedStmt = ibm_db.prepare(dbConnection, sqlStatement)
except Exception:
    pass

# If The SQL Statement Could Not Be Prepared By Db2, Display An Error Message And Exit
if preparedStmt is False:
    print("\nERROR: Unable to prepare the SQL statement specified.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Execute The SQL Statement Just Prepared
print("Executing the prepared SQL statement ... ", end="")
try:
    resultSet = ibm_db.execute(preparedStmt)
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if resultSet is False:
    print("\nERROR: Unable to execute the SQL statement specified.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Try To Find Out How Many Rows Are In Result Set That Was Produced By The Query Just Executed
# (This Information Should Not Be Available)
try:
    numRows = ibm_db.num_rows(preparedStmt)
except Exception:
    pass
 
# Display An Appropriate Message, Based On The Information Returned
if numRows <= 0:
    print("Unable to obtain information about the number of rows returned.\n")
else:
    print("Number of rows returned by the query: " + str(numRows) + "\n")

# Free System Resources That Are Associated With The Prepared Statement And Result Set Produced
print("Freeing system resources associated with the prepared statement ... ", end="")
try:
    returnCode = ibm_db.free_result(preparedStmt)
except Exception:
    pass

# If The Appropriate System Resources Could Not Be Freed, Display An Error Message And Exit 
if returnCode is False:
    print("\nERROR: Unable to free the appropriate system resources.\n")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Create A Dictionary That Contains The Value Needed To Turn Row Prefetch Behavior On;
# This Enables Db2 To Determine The Number Of Rows That Are Returned By A Query (So The
# Entire Result Set Can Be Prefetched Into Memory, When Possible) 
stmtOption = {ibm_db.SQL_ATTR_ROWCOUNT_PREFETCH : ibm_db.SQL_ROWCOUNT_PREFETCH_ON}

# Attempt To Set The Statement Option Specified
print("Turning SQL_ATTR_ROWCOUNT_PREFETCH behavior ON ... ", end="")
try:
    returnCode = ibm_db.set_option(preparedStmt, stmtOption, 0)
except Exception:
    pass

# If The Statement Option Could Not Be Set, Display An Error Message And Exit 
if returnCode is False:
    print("\nERROR: Unable to set the statement option specified.\n")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Execute The Prepared SQL Statement Again
print("Executing the prepared SQL statement again ... ", end="")
try:
    resultSet = ibm_db.execute(preparedStmt)
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if resultSet is False:
    print("\nERROR: Unable to execute the SQL statement specified.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Try To Find Out How Many Rows Are In Result Set That Was Produced By The Query Again
# (This Time, The Information Should Be Available)
try:
    numRows = ibm_db.num_rows(preparedStmt)
except Exception:
    pass

# Display An Appropriate Message, Based On The New Information Returned
if numRows <= 0:
    print("Unable to obtain information about the number of rows returned.\n")
else:
    print("Number of rows returned by the query: " + str(numRows) + "\n")

# Close The Database Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
