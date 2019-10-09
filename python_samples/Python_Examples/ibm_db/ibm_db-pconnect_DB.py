#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-pconnect_DB.py                                                                #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.pconnect() API to       #
#            create a pool of connections to a local Db2 database.                                #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.exec_immediate()                                                         #
#                 ibm_db.num_rows()                                                               #
#                 ibm_db.close()                                                                  #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-pconnect_DB.py                                                              #
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
# Import The ipynb_exit Class Definition, Attributes, And Methods That Have Been Defined In The   #
# File Named "ipynb_exit.py"; This Class Contains The Programming Logic Needed To Allow "exit()"  #
# Functionality To Work Without Raising An Error Or Stopping The Kernel If The Application Is     #
# Invoked In A Jupyter Notebook                                                                   #
#-------------------------------------------------------------------------------------------------#
from ipynb_exit import exit

# Define And Initialize The Appropriate Variables
dbName = "SAMPLE"        # The Alias For The Cataloged, Local Database
userID = "db2inst1"      # The Instance User ID At The Local Server
passWord = "Passw0rd"    # The Password For The Instance User ID At The Local Server
dbConnection = list(range(10))
resultSet = False
returnCode = False

# Construct The String That Will Be Used To Establish A Db2 Database Connection
connString = "ATTACH=FALSE"              # Attach To A Database; Not A Server
connString += ";DATABASE=" + dbName      # Required To Connect To A Database     
connString += ";PROTOCOL=TCPIP"
connString += ";UID=" + userID
connString += ";PWD=" + passWord

# Display A Status Message Indicating An Attempt To Establish Ten Connections To A Db2 
# Database Is About To Be Made
print("\nEstablishing 10 connections to the \'" + dbName + "\' database ... \n")

# Establish Ten Connections To The Local Db2 Database Specified
for loopCounter in range(10):

    # Attempt To Establish A Database Connection 
    try:
        dbConnection[loopCounter] = ibm_db.pconnect(connString, '', '')
    except Exception:
        pass

    # If A Connection Could Not Be Established, Display An Error Message And Continue
    if dbConnection[loopCounter] is None:
        print("\nERROR: Unable to connect to the \'" + dbName + "\' database.")
        continue

    # Otherwise, Display A "Connection Ready" Status Message
    else:
        print("  Connection {:>2} ready!" .format(loopCounter + 1))

# Add A Blank Line To The End Of The List Of Connections Created
print()

# Retrieve Data From The Database Using Connection Number Five
if not dbConnection[5] is None:

    # Define The SQL Statement That Is To Be Executed 
    sqlStatement = "SELECT * FROM department"

    # Set The Statement Option That Is To be Used When the Statement Is Executed
    stmtOption = {ibm_db.SQL_ATTR_ROWCOUNT_PREFETCH : ibm_db.SQL_ROWCOUNT_PREFETCH_ON}

    # Execute The SQL Statement Just Defined (Using The Desired Option)
    print("Executing the SQL statement \"" + sqlStatement + "\" from Connection 5 ... ", end="")
    currentConnection = dbConnection[5]
    try:
        resultSet = ibm_db.exec_immediate(currentConnection, sqlStatement, stmtOption)
    except Exception:
        pass

    # If The SQL Statement Could Not Be Executed, Display An Error Message And Continue
    if resultSet is False:
        print("\nERROR: Unable to execute the SQL statement specified.\n")

    # Otherwise, Complete The Status Message
    else:
        print("Done!\n")

    # Try To Find Out How Many Rows Are In Result Set That Was Produced By The Query Just
    # Executed (There Should Be 14 Rows)
    try:
        numRows = ibm_db.num_rows(resultSet)
    except Exception:
        pass
 
    # Display An Appropriate Message, Based On The Information Returned
    if numRows <= 0:
        print("Unable to obtain information about the number of rows returned.\n")
    else:
        print("Number of rows returned by the query: " + str(numRows) + "\n")

    # Attempt To Close The Database Connection (Connection 5)
    print("Closing database Connection 5 ... ", end="")
    try:
        returnCode = ibm_db.close(currentConnection)
    except Exception:
        pass

    # If The Connection Was Not Closed, Display An Error Message
    if returnCode is False:
        print("\nERROR: Unable to disconnect from the " + dbName + " database.")
        
    # Otherwise, Complete The Status Message
    else:
        print("Done!")
        print("(Connection 5 has been returned the pool of connections opened earlier.)\n")

# Display A Status Message Indicating An Attempt To Close The Remaining Db2 Database 
# Connections Is About To Be Made
print("Closing all remaining connections to the \'" + dbName + "\' database ... \n")

# Attempt To Close All Of The Db2 Database Connections That Were Opened Earlier
for loopCounter in range(10):
    
    # If The Specified Connection Is Open, Attempt To Close It
    if not dbConnection[loopCounter] is None:
        try:
            returnCode = ibm_db.close(dbConnection[loopCounter])
        except Exception:
            pass

        # If The Connection Could Not Be Closed, Display An Error Message And Continue
        if returnCode is False:
            print("\nERROR: Unable to disconnect from the " + dbName + " database.")
            continue

        # Otherwise, Display A "Connection Closed" Status Message
        else:
            print("  Connection {:>2} closed!" .format(loopCounter + 1))

# Display A Status Message Indicating All Database Connections Have Been Returned To The
# Connection Pool
print("\nAll database connections have been returned the pool of connections opened earlier.\n")

# Return Control To The Operating System
exit()
