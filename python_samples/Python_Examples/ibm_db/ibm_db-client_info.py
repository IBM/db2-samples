#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-client_info.py                                                                #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.client_info() API.      #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-client_info.py                                                              #
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
svrConnection = None
clientInfo = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Server
conn = Db2ConnectionMgr('SERVER', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    svrConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

# Attempt To Obtain Information About The Db2 Client Being Used
print("Obtaining information about the Db2 client ... ", end="")
try:
    clientInfo = ibm_db.client_info(svrConnection)
except Exception:
    pass

# If Information About The Client Could Not Be Obtained, Display An Error Message 
if clientInfo is False:
    print("\nERROR: Unable to obtain Db2 client information.\n")

# Otherwise, Complete The Status Message; Then Format And Display The Data Retrieved
else:
    print("Done!\n")

    # Display A Report Header
    print("Client details:")
    print("____________________________________________________________________")

    # Display The Client Data
    print("Application code page        : {}" .format(clientInfo.APPL_CODEPAGE))
    print("Current connection code page : {}" .format(clientInfo.CONN_CODEPAGE))
    print("Data source name (DSN)       : {}" .format(clientInfo.DATA_SOURCE_NAME))
    print("Driver name                  : {}" .format(clientInfo.DRIVER_NAME))
    print("Driver version               : {}" .format(clientInfo.DRIVER_VER))
    print("ODBC version supported       : {}" .format(clientInfo.DRIVER_ODBC_VER))
    print("ODBC SQL conformance level   : ", end="")
    if clientInfo.ODBC_SQL_CONFORMANCE == 'MINIMAL':
        print("Supports the minimum ODBC SQL grammar\n")
    elif clientInfo.ODBC_SQL_CONFORMANCE == 'CORE':
        print("Supports the core ODBC SQL grammar\n")
    elif clientInfo.ODBC_SQL_CONFORMANCE == 'EXTENDED':
        print("Supports extended ODBC SQL grammar\n")

# Close The Server Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
