#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-foreign_keys.py                                                               #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.foreign_keys() API.     #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.tables()                                                                 #
#                 ibm_db.fetch_assoc()                                                            #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-foreign_keys.py                                                             #
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
schemaName = userID.upper()
tableName = "PROJECT"
resultSet = False
dataRecord = False
foreignKeyRules = {0 : "CASCADE", 1 : "RESTRICT", 2 : "SET_NULL", 3 : "NO_ACTION", 
                   4 : "SET_DEFAULT"}
deferability = {5 : "INITIALLY_DEFERRED", 6 : "INITIALLY_IMMEDIATE", 
                7 : "NOT_DEFERRABLE"}

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Database
conn = Db2ConnectionMgr('DB', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    dbConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

# Attempt To Retrieve Information About All Of The Tables In The Current User's Schema
print("Obtaining information about tables in the " + schemaName + " schema ... ", end="")
try:
    resultSet = ibm_db.tables(dbConnection, None, schemaName, None, 'TABLE')
except Exception:
    pass

# If The Information Desired Could Not Be Retrieved, Display An Error Message And Exit
if resultSet is False:
    print("\nERROR: Unable to obtain the information desired\n.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# As Long As There Are Records (That Were Produced By The ibm_db.tables API), ... 
tableList = []
noData = False
while noData is False:

    # Retrieve A Record And Store It In A Python Dictionary
    try:
        dataRecord = ibm_db.fetch_assoc(resultSet)
    except:
        pass

    # If The Data Could Not Be Retrieved Or There Was No Data To Retrieve, Set The
    # "No Data" Flag And Exit The Loop  
    if dataRecord is False:
        noData = True

    # Otherwise, Store The Table Name Retrieved In A Python List (This List Will Be Used
    # Later To Skip Records Associated With Aliases)
    else:
        tableList.append(dataRecord['TABLE_NAME'])

# Attempt To Retrieve Information About All Of The Foreign Keys That Have Been Defined For 
# The Table Specified
print("Obtaining information about foreign keys created for ", end="")
print("the " + schemaName + "." + tableName + " table ... ", end="")
resultSet = False
try:
    resultSet = ibm_db.foreign_keys(dbConnection, None, schemaName, tableName)
except Exception:
    pass

# If The Information Desired Could Not Be Retrieved, Display An Error Message And Exit
if resultSet is False:
    print("\nERROR: Unable to obtain the information desired\n.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# As Long As There Are Records (That Were Produced By The ibm_db.foreign_keys API), ...
noData = False
loopCounter = 1
while noData is False:

    # Retrieve A Record And Store It In A Python Dictionary
    try:
        dataRecord = ibm_db.fetch_assoc(resultSet)
    except:
        pass

    # If The Data Could Not Be Retrieved Or If There Was No Data To Retrieve, Set The
    # "No Data" Flag And Exit The Loop  
    if dataRecord is False:
        noData = True

    # Otherwise, Display The Data Retrieved (Skip Information For Aliases)
    else:

        # If The Current Data Record Is For A Table Alias, Ignore It
        if not dataRecord['FKTABLE_NAME'] in tableList:
            continue

        # Display Record Header Information
        print("Foreign key " + str(loopCounter) + " details:")
        print("______________________________________________")

        # Display The Information Stored In The Data Record Retrieved
        print("Primary key name    : {}" .format(dataRecord['PK_NAME']))
        print("  Table schema      : {}" .format(dataRecord['PKTABLE_SCHEM']))
        print("  Table name        : {}" .format(dataRecord['PKTABLE_NAME']))
        print("  Column name       : {}" .format(dataRecord['PKCOLUMN_NAME']))
        print("Foreign key name    : {}" .format(dataRecord['FK_NAME']))
        print("  Table schema      : {}" .format(dataRecord['FKTABLE_SCHEM']))
        print("  Table name        : {}" .format(dataRecord['FKTABLE_NAME']))
        print("  Column name       : {}" .format(dataRecord['FKCOLUMN_NAME']))
        print("  Column number     : {}" .format(dataRecord['KEY_SEQ']))
        print("  UPDATE rule used  : ", end="")
        print(foreignKeyRules.get(dataRecord['UPDATE_RULE']))
        print("  DELETE rule used  : ", end="")
        print(foreignKeyRules.get(dataRecord['DELETE_RULE']))
        print("  Deferability      : ", end="")
        print(deferability.get(dataRecord['DEFERRABILITY']))

        # Increment The loopCounter Variable And Print A Blank Line To Separate Foreign Key
        # Records From Each Other
        loopCounter += 1
        print()

# Close The Database Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
