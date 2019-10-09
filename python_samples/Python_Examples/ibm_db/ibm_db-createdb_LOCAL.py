#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-createdb_LOCAL.py                                                             #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.createdb() API to       #
#            create a database on a local Db2 server.                                             #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.conn_errormsg()                                                          #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-createdb_LOCAL.py                                                           #
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
# Import The query_sdb_dir() Function That Has Been Defined In The File Named "ibm_db_tools.py";  #
# This Function Contains The Programming Logic Needed To See If Information About A Specific      #
# Database Can Be Found In The Db2 System Database Directory.                                     #
#-------------------------------------------------------------------------------------------------#
from ibm_db_tools import query_sdb_dir

#-------------------------------------------------------------------------------------------------#
# Import The ipynb_exit Class Definition, Attributes, And Methods That Have Been Defined In The   #
# File Named "ipynb_exit.py"; This Class Contains The Programming Logic Needed To Allow "exit()"  #
# Functionality To Work Without Raising An Error Or Stopping The Kernel If The Application Is     #
# Invoked In A Jupyter Notebook                                                                   #
#-------------------------------------------------------------------------------------------------#
from ipynb_exit import exit

# Define And Initialize The Appropriate Variables
userID = "db2inst1"           # User ID (Recognized By The Local Server)
passWord = "Passw0rd"         # User Password
svrConnection = None
dbName = "MY_DB"
returnCode = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To The Local Db2 Server
conn = Db2ConnectionMgr('LOCAL_SVR', '', '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    svrConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

# Attempt To Create A New Database At The Local Server
print("Creating a database named " + dbName + " at the local server. Please wait.")
try:
    returnCode = ibm_db.createdb(svrConnection, dbName)
except Exception:
    pass

# If The Database Could Not Be Created, Display An Error Message And Exit 
if returnCode is False:
    print("ERROR: Unable to create the " + dbName + " database.\n")
    errorMsg = ibm_db.conn_errormsg(svrConnection)
    print(errorMsg + "\n")
    conn.closeConnection()
    exit(-1)
    
# Otherwise, Display A Status Message 
else:
    print("\nThe database \"" + dbName + "\" has been created!\n")
    query_sdb_dir(dbName)

# Close The Db2 Server Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
