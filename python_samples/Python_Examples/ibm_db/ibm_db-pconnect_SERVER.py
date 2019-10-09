#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-pconnect_SERVER.py                                                            #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.pconnect() API to       #
#            create a pool of connections to a remote Db2 server.                                 #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.createdbNX()                                                             #
#                 ibm_db.close()                                                                  #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-pconnect_SERVER.py                                                          #
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
hostName = "197.126.80.22"    # IP Address Of Remote Server
portNum = "50000"             # Port Number That Receives Db2 Connections On The Remote Server 
userID = "db2inst2"           # The Instance User ID At The Remote Server
passWord = "ibmdb2"           # The Password For The Instance User ID At The Remote Server
svrConnection = list(range(10))
dbName = "MY_DB"
returnCode = None

# Construct The String That Will Be Used To Establish A Db2 Server Connection
connString = "DRIVER={IBM DB2 ODBC DRIVER}"
connString += ";ATTACH=TRUE"             # Attach To A Server; Not A Database
connString += ";DATABASE="               # Ignored When Connecting To A Server
connString += ";HOSTNAME=" + hostName    # Required To Connect To A Server
connString += ";PORT=" + portNum         # Required To Connect To A Server
connString += ";PROTOCOL=TCPIP"          # Required To Connect To A Server
connString += ";UID=" + userID
connString += ";PWD=" + passWord

# Display A Status Message Indicating An Attempt To Establish Ten Connections To A Remote 
# Db2 Server Is About To Be Made
print("\nEstablishing 10 connections to the \'" + hostName + "\' server ... \n")

# Establish Ten Connections To The Db2 Server Specified
for loopCounter in range(10):

    # Attempt To Establish A Db2 Server Connection 
    try:
        svrConnection[loopCounter] = ibm_db.pconnect(connString, '', '')
    except Exception:
        pass

    # If A Connection Could Not Be Established, Display An Error Message And Continue
    if svrConnection[loopCounter] is None:
        print("\nERROR: Unable to connect to the \'" + hostName + "\' server.")
        continue

    # Otherwise, Display A "Connection Ready" Status Message
    else:
        print("  Connection {:>2} ready!" .format(loopCounter + 1))

# Add A Blank Line To The End Of The List Of Connections Created
print()

# Attempt To Create A New Database At The Remote Server Using Connection Number Five
if not svrConnection[5] is None:
    print("Creating a database named " + dbName + " using Connection 5.  Please wait.")
    currentConnection = svrConnection[5]
    try:
        returnCode = ibm_db.createdbNX(currentConnection, dbName)
    except Exception:
        pass

    # If The Database Could Not Be Created, Display An Error Message And Exit 
    if returnCode is None:
        print("ERROR: Unable to create the " + dbName + " database.\n")
        errorMsg = ibm_db.conn_errormsg(svrConnection)
        print(errorMsg + "\n")

    # Otherwise, Display A Status Message Indicating The Database Was Created 
    else:
        print("\nThe database \"" + dbName + "\" has been created!\n")

    # Attempt To Close The Db2 Server Connection (Connection 5)
    print("Closing Db2 server Connection 5 ... ", end="")
    try:
        returnCode = ibm_db.close(currentConnection)
    except Exception:
        pass

    # If The Connection Was Not Closed, Display An Error Message
    if returnCode is False:
        print("\nERROR: Unable to disconnect from the " + hostName + " server.")
        
    # Otherwise, Complete The Status Message
    else:
        print("Done!")
        print("(Connection 5 has been returned the pool of connections opened earlier.)\n")

# Display A Status Message Indicating An Attempt To Close The Remaining Db2 Server
# Connections Is About To Be Made
print("Closing all remaining connections to the \'" + hostName + "\' server ... \n")

# Attempt To Close All Of The Remaining Db2 Server Connections That Were Opened Earlier
for loopCounter in range(10):
    
    # If The Specified Connection Is Open, Attempt To Close It
    if not svrConnection[loopCounter] is None:
        try:
            returnCode = ibm_db.close(svrConnection[loopCounter])
        except Exception:
            pass

        # If The Connection Could Not Be Closed, Display An Error Message And Continue
        if returnCode is False:
            print("\nERROR: Unable to disconnect from the " + hostName + " server.")
            continue

        # Otherwise, Display A "Connection Closed" Status Message
        else:
            print("  Connection {:>2} closed!" .format(loopCounter + 1))

# Display A Status Message Indicating All Db2 Server Connections Have Been Returned To The
# Connection Pool
print("\nAll Db2 server connections have been returned the pool of connections opened earlier.\n")

# Return Control To The Operating System
exit()
