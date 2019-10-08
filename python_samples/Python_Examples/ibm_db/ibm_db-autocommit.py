#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-autocommit.py                                                                 #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.autocommit() API.       #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.connect()                                                                #
#                 ibm_db.close()                                                                  #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-autocommit.py                                                               #
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
dbName = "SAMPLE"
userID = "db2inst1"
passWord = "Passw0rd"
connOption = {ibm_db.SQL_ATTR_AUTOCOMMIT : ibm_db.SQL_AUTOCOMMIT_ON}
dbConnection = None

# Display A Status Message Indicating An Attempt To Establish A Connection To A Db2 Database
# Is About To Be Made
print("\nConnecting to the \'" + dbName + "\' database ... ", end="")

# Construct The String That Will Be Used To Establish A Db2 Database Connection
connString = "ATTACH=FALSE"              # Attach To A Database; Not A Server
connString += ";DATABASE=" + dbName      # Required To Connect To A Database     
connString += ";PROTOCOL=TCPIP"
connString += ";UID=" + userID
connString += ";PWD=" + passWord

# Attempt To Establish A Connection To The Database Specified
try:
    dbConnection = ibm_db.connect(connString, '', '', connOption)
except Exception:
    pass

# If A Db2 Database Connection Could Not Be Established, Display An Error Message And Exit
if dbConnection is None:
    print("\nERROR: Unable to connect to the \'" + dbName + "\' database.")
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Determine Whether Autocommit Behavior Is OFF or ON (Should Match The connOption Setting)
try:
    returnCode = ibm_db.autocommit(dbConnection)
except Exception:
    pass

# If Autocommit Behavior Is OFF, Turn It ON
if returnCode is 0:
    print("AUTOCOMMIT behavior is OFF; turning it ON ... ", end="")
    try:
        returnCode = ibm_db.autocommit(dbConnection, ibm_db.SQL_AUTOCOMMIT_ON)
    except Exception:
        pass
    
    # If AUTOCOMMIT Behavior Could Not Be Turned ON, Display An Error Message And Continue
    if returnCode is False:
        print("\nERROR: Unable to turn AUTOCOMMIT behavior ON.")

    # Otherwise, Complete The Status Message
    else:
        print("Done!\n")

# If Autocommit Behavior Is ON, Turn It OFF
elif returnCode is 1:
    print("AUTOCOMMIT behavior is ON; turning it OFF ... ", end="")
    try:
        returnCode = ibm_db.autocommit(dbConnection, ibm_db.SQL_AUTOCOMMIT_OFF)
    except Exception:
        pass

    # If AUTOCOMMIT Behavior Could Not Be Turned OFF, Display An Error Message And Continue
    if returnCode is False:
        print("\nERROR: Unable to turn AUTOCOMMIT behavior OFF.")

    # Otherwise, Complete The Status Message
    else:
        print("Done!\n")

# Check Autocommit Behavior Again And Display Its Status
try:
    returnCode = ibm_db.autocommit(dbConnection)
except Exception:
    pass

if returnCode is 0:
    print("AUTOCOMMIT behavior is now OFF.\n")
elif returnCode is 1:
    print("AUTOCOMMIT behavior is now ON.\n")

# Attempt To Close The Db2 Database Connection That Was Opened Earlier
if not dbConnection is None:
    print("Disconnecting from the \'" + dbName + "\' database ... ", end="")
    try:
        returnCode = ibm_db.close(dbConnection)
    except Exception:
        pass

    # If The Db2 Server Connection Was Not Closed, Display An Error Message And Exit
    if returnCode is False:
        print("\nERROR: Unable to disconnect from the " + dbName + " database.")
        exit(-1)

    # Otherwise, Complete The Status Message
    else:
        print("Done!\n")

# Return Control To The Operating System
exit()
