#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db_dbi-commit.py                                                                 #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the .commit() function of the      #
#            IBM_DBConnection object that is returned by the ibm_db_dbi.connect() API.            #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db_dbi-rollback.py                                                             #
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
#  of assisting you in the creation of Python applications using the ibm_db_dbi library.          #
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
import ibm_db_dbi  # Contains The APIs Needed To Work With Db2 Databases

#-------------------------------------------------------------------------------------------------#
# Import The get_row_count() Function That Has Been Defined In The File Named                     #
# "ibm_db_dbi_tools.py"; This Function Contains The Programming Logic Needed To Obtain And        #
# Display The Number Of Rows (Records) Found In A Db2 Database Table.                             #
#-------------------------------------------------------------------------------------------------#
from ibm_db_dbi_tools import get_row_count

# Define And Initialize The Appropriate Variables
dbName = "SAMPLE"        # The Alias For The Cataloged, Local Database
userID = "db2inst1"      # The Instance User ID At The Local Server
passWord = "Passw0rd"    # The Password For The Instance User ID At The Local Server
connectionID = None
resultSet = False
returnCode = False

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
    connectionID = ibm_db_dbi.connect(connString, '', '')
except Exception:
    pass

# If A Db2 Database Connection Could Not Be Established, Display An Error Message And Exit
if connectionID is None:
    print("\nERROR: Unable to connect to the \'" + dbName + "\' database.")
    print("Connection string used: " + connString + "\n")
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Retrieve The Cursor Object That Was Created For The Connection Object
if not connectionID is None:
    cursorID = connectionID.cursor()

# Display The Number Of Rows That Currently Exist In The DEPARTMENT Table
returnCode = get_row_count(cursorID, 'DEPARTMENT')
if returnCode is False:
    if not connectionID is None:
        connectionID.close()
    exit(-1)

# Define The INSERT Statement That Is To Be Used To Add Data To The DEPARTMENT Table
sqlStatement = "INSERT INTO department VALUES('K01', 'SALES', '000130', 'K01', NULL)"

# Execute The SQL Statement Just Defined
print("Inserting a record into the DEPARTMENT table ... ", end="")
try:
    resultSet = cursorID.execute(sqlStatement)
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if resultSet is False:
    print("\nERROR: Unable to execute the INSERT statement specified.")
    if not connectionID is None:
        connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Display The Number Of Rows That Exist In The DEPARTMENT Table Now
# (The Number Returned Should Change)
returnCode = get_row_count(cursorID, 'DEPARTMENT')
if returnCode is False:
    if not connectionID is None:
        connectionID.close()
    exit(-1)

# Commit The Changes Just Made To The Database
print("Commiting changes made to the database ... ", end="")
resultSet = False
try:
    resultSet = connectionID.commit()
except Exception:
    pass

# If The Commit Operation Could Not Be Performed, Display An Error Message And Exit 
if resultSet is False:
    print("\nERROR: Unable to roll back the previous operation.")
    if not connectionID is None:
        connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Display The Number Of Rows That Exist In The DEPARTMENT Table Now
# (The Number Should Not Change)
returnCode = get_row_count(cursorID, 'DEPARTMENT')
if returnCode is False:
    if not connectionID is None:
        connectionID.close()
    exit(-1)

# Attempt To Close The Db2 Database Connection That Was Opened Earlier
if not connectionID is None:
    print("Disconnecting from the \'" + dbName + "\' database ... ", end="")
    try:
        returnCode = connectionID.close()
    except Exception:
        pass

    # If The Db2 Database Connection Was Not Closed, Display An Error Message And Exit
    if returnCode is False:
        print("\nERROR: Unable to disconnect from the " + dbName + " database.")
        exit(-1)

    # Otherwise, Complete The Status Message
    else:
        print("Done!\n")

# Return Control To The Operating System
exit()
