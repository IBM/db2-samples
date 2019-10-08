#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-get_option_STATEMENT.py                                                       #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.get_option() API to     #
#            assign a value to one of the statement options available.                            #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.exec_immediate()                                                         #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-get_option_STATEMENT.py                                                     #
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
resultSet = False
cursorType = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Database
conn = Db2ConnectionMgr('DB', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    dbConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

# Create A Dictionary That Contains Values For All Of The Statement Options That Can Be Set 
stmtOptions = {ibm_db.SQL_ATTR_CURSOR_TYPE : ibm_db.SQL_CURSOR_STATIC,
    ibm_db.SQL_ATTR_ROWCOUNT_PREFETCH : ibm_db.SQL_ROWCOUNT_PREFETCH_ON,
    ibm_db.SQL_ATTR_QUERY_TIMEOUT : 10}

# Define The SQL Statement That Is To Be Executed
sqlStatement = "SELECT * FROM employee WHERE edlevel > 17"

# Execute The SQL Statement Just Defined
print("Executing the SQL statement \"" + sqlStatement + "\" ... ", end="")
try:
    resultSet = ibm_db.exec_immediate(dbConnection, sqlStatement, stmtOptions)
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if resultSet is False:
    print("\nERROR: Unable to execute the SQL statement specified.\n")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Verify That The Type Of Cursor Being Used Is Type Of Cursor That Was Specified
print("Obtaining information about the type of cursor being used ... ", end="")
try:
    cursorType = ibm_db.get_option(resultSet, ibm_db.SQL_ATTR_CURSOR_TYPE, 0)
except Exception:
    pass

# If Information About The Cursor Could Not Be Obtained, Display An Error Message And Exit 
if cursorType is False:
    print("\nERROR: Unable to obtain the information desired.\n")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Verify That The Type Of Cursor Being Used Is Type Of Cursor That Was Specified
print("Type of cursor specified : Static (SQL_CURSOR_STATIC)")
print("Type of cursor being used: ", end="")

if cursorType == ibm_db.SQL_CURSOR_FORWARD_ONLY:
    print("Forward only (SQL_CURSOR_FORWARD_ONLY)\n")
elif cursorType == ibm_db.SQL_CURSOR_KEYSET_DRIVEN:
    print("Keyset driven (SQL_CURSOR_KEYSET_DRIVEN)\n")
elif cursorType == ibm_db.SQL_CURSOR_DYNAMIC:
    print("Dynamic (SQL_CURSOR_DYNAMIC)\n")
elif cursorType == ibm_db.SQL_CURSOR_STATIC:
    print("Static (SQL_CURSOR_STATIC)\n")
else:
    print("Unknown\n")

# Close The Database Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
