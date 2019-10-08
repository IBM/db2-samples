#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-num_rows.py                                                                   #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db-num_rows() API.         #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.autocommit()                                                             #
#                 ibm_db.prepare()                                                                #
#                 ibm_db.exec_many()                                                              #
#                 ibm_db.exec_rollback()                                                          #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-num_rows.py                                                                 #
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
returnCode = False
preparedStmt = False
numRows = False
resultSet = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Database
conn = Db2ConnectionMgr('DB', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    dbConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)
    
# Turn Autocommit Behavior OFF
print("Turning AUTOCOMMIT behavior OFF ... ", end="")
returnCode = ibm_db.autocommit(dbConnection, 0)
if returnCode is False:
    print("\nERROR: Unable to turn off AUTOCOMMIT behavior.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")
    
# Define The INSERT Statement (With Parameter Markers) That Is To Be Used To Add Data
# To The DEPARTMENT Table
sqlStatement = "INSERT INTO department VALUES(?, ?, ?, 'E01', NULL)"

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

# Create A List Of Data Values That Are To Be Supplied For The Parameter Markers Coded
# In The INSERT Statement Specified
pmValues = (('K22', 'SALES', '000110'), 
            ('L22', 'FINANCE', '000120'), 
            ('M22', 'HUMAN RESOURCES', '000130'))

# Execute The SQL Statement Just Prepared
print("Executing the prepared SQL statement ... ", end="")
try:
    returnCode = ibm_db.execute_many(preparedStmt, pmValues) 
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if returnCode is False:
    print("\nERROR: Unable to execute the SQL statement specified.\n")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message And Display The Number Of Records Added
else:
    print("Done!\n")

# Find Out How Many Rows Were Affected By The INSERT Operation
try:
    numRows = ibm_db.num_rows(preparedStmt)
except Exception:
    pass
 
# If Information About The Number Rows Affected Could Not Be Obtained, Display An Error
# Message And Exit 
if numRows is False:
    print("\nERROR: Unable to obtain information about the number of rows affected.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Display The Information Obtained
else:
    print("Number of rows affected by the INSERT operation: " + str(numRows) + "\n")

# Back Out The Changes Just Made To The Database
print("Backing out changes made to the database ... ", end="")
try:
    resultSet = ibm_db.rollback(dbConnection)
except Exception:
    pass

# If The Rollback Operation Could Not Be Performed, Display An Error Message And Exit 
if resultSet is False:
    print("\nERROR: Unable to roll back the previous operation.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")
    
# Close The Database Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
