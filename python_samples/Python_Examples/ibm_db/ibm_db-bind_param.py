#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-bind_param.py                                                                 #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.bind_param() API.       #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.prepare()                                                                #
#                 ibm_db.execute()                                                                #
#                 ibm_db.fetch_tuple()                                                            #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-bind_param.py                                                               #
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
preparedStmt = None
deptID = ['B01', 'C01', 'D01', 'E01']
returnCode = False
dataRecord = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Database
conn = Db2ConnectionMgr('DB', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    dbConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

# Define The SQL Statement That Is To Be Executed - Include A Parameter Marker
sqlStatement = "SELECT projname FROM project WHERE deptno = ?"

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

# For Every Value Specified In The deptID List, ...
for loopCounter in range(0, 4):

    # Display A Message That Identifies The Query Being Executed
    print("Processing query " + str(loopCounter + 1) + ":")

    # Assign A Value To The Application Variable That Is To Be Bound To The SQL Statement
    paramValue = deptID[loopCounter]

    # Bind The Application Variable To The Parameter Marker Used In The SQL Statement 
    print("  Binding the appropriate variable to the parameter marker used ... ", end="")
    try:
        returnCode = ibm_db.bind_param(preparedStmt, 1, paramValue, ibm_db.SQL_PARAM_INPUT,
                         ibm_db.SQL_CHAR)
    except Exception:
        pass
    
    # If The Application Variable Was Not Bound Successfully, Display An Error Message And Exit
    if returnCode is False:
        print("\nERROR: Unable to bind the variable to the parameter marker specified.")
        conn.closeConnection()
        exit(-1)

    # Otherwise, Complete The Status Message
    else:
        print("Done!")

    # Execute The Prepared SQL Statement (Using The New Parameter Marker Value)
    print("  Executing the prepared SQL statement ", end="")
    print("(with the value \'" + paramValue + "\') ... ", end="")
    try:
        returnCode = ibm_db.execute(preparedStmt)
    except Exception:
        pass
   
    # If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
    if returnCode is False:
        print("\nERROR: Unable to execute the SQL statement.")
        conn.closeConnection()
        exit(-1)

    # Otherwise, Complete The Status Message
    else:
        print("Done!")

    # Display A Report Header
    print("Results:\n")
    print("DEPTNO  PROJNAME")
    print("______  _____________________")

    # As Long As There Are Records, ...
    noData = False
    while noData is False:

        # Retrieve A Record And Store It In A Python Tuple
        try:
            dataRecord = ibm_db.fetch_tuple(preparedStmt)
        except:
            pass

        # If The Data Could Not Be Retrieved Or There Was No Data To Retrieve, Set The
        # "No Data" Flag And Continue 
        if dataRecord is False:
            noData = True

        # Otherwise, Format And Display The Data Retrieved
        else:
            print("{:<6}  {}" .format(paramValue, dataRecord[0])) 

    # Add A Blank Line To The End Of The Report
    print()

# Close The Database Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
