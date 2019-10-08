#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-server_info.py                                                                #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.server_info() API.      #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-server_info.py                                                              #
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
serverInfo = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Server
conn = Db2ConnectionMgr('SERVER', '', '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    svrConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

# Attempt To Obtain Information About The Db2 Server Being Used
print("Obtaining information about the server ... ", end="")
try:
    serverInfo = ibm_db.server_info(svrConnection)
except Exception:
    pass

# If Information About The Server Could Not Be Obtained, Display An Error Message 
if serverInfo is False:
    print("\nERROR: Unable to obtain server information.\n")

# Otherwise, Complete The Status Message; Then Format And Display The Data Retrieved
else:
    print("Done!\n")

    # Display A Report Header
    print("Server details:")
    print("_____________________________________________________________________________")
    
    # Display The Server Data
    print("Db2 database server name                 : {}" .format(serverInfo.DBMS_NAME))
    print("Db2 software version                     : {}" .format(serverInfo.DBMS_VER))
    print("Db2 instance name                        : {}" .format(serverInfo.INST_NAME))
    print("Database codepage used                   : {}" .format(serverInfo.DB_CODEPAGE))
    print("Database name                            : {}" .format(serverInfo.DB_NAME))

    print("Isolation levels supported               : ", end="")
    for loopCounter in range(0, len(serverInfo.ISOLATION_OPTION)):
        if serverInfo.ISOLATION_OPTION[loopCounter] == 'UR':
            print("Uncommitted Read (UR)", end="")
        elif serverInfo.ISOLATION_OPTION[loopCounter] == 'CS':
            print("Cursor Stability (CS)", end="")
        elif serverInfo.ISOLATION_OPTION[loopCounter] == 'RS':
            print("Read Stability (RS)", end="")
        elif serverInfo.ISOLATION_OPTION[loopCounter] == 'RR':
            print("Repeatable Read (RR)", end="")
        elif serverInfo.ISOLATION_OPTION[loopCounter] == 'NC':
            print("No Commit", end="")
        if loopCounter < len(serverInfo.ISOLATION_OPTION) - 1:
            print("\n" + " " * 43, end="")
    print()

    print("Default isolation level used             : ", end="")
    if serverInfo.DFT_ISOLATION == 'NC':
        print("No Commit")
    else:
        print("{}" .format(serverInfo.DFT_ISOLATION))

    print("Identifier delimiter character           : ", end="")
    print("{}" .format(serverInfo.IDENTIFIER_QUOTE_CHAR))

    print("Use of % and _ as wildcards supported    : ", end="")
    if serverInfo.LIKE_ESCAPE_CLAUSE == True:
        print("Yes")
    else:
        print("No")

    print("Maximum column name length               : ", end="")
    print("{:<7} bytes" .format(serverInfo.MAX_COL_NAME_LEN))
    print("Maximum SQL identifier length            : ", end="")
    print("{:<7} characters" .format(serverInfo.MAX_IDENTIFIER_LEN))
    print("Maximum index size (combined columns)    : ", end="")
    print("{:<7} bytes" .format(serverInfo.MAX_INDEX_SIZE))
    print("Maximum procedure name length            : ", end="")
    print("{:<7} bytes" .format(serverInfo.MAX_PROC_NAME_LEN))
    print("Maximum row size                         : ", end="")
    print("{:<7} bytes" .format(serverInfo.MAX_ROW_SIZE))
    print("Maximum schema name length               : ", end="")
    print("{:<7} bytes" .format(serverInfo.MAX_SCHEMA_NAME_LEN))
    print("Maximum SQL statement length             : ", end="")
    print("{:<7} bytes" .format(serverInfo.MAX_STATEMENT_LEN))
    print("Maximum table name length                : ", end="")
    print("{:<7} bytes" .format(serverInfo.MAX_TABLE_NAME_LEN))

    print("NOT NULL columns supported               : ", end="")
    if serverInfo.NON_NULLABLE_COLUMNS == True:
        print("Yes")
    else:
        print("No")
    print("CALL statement supported                 : ", end="")
    if serverInfo.PROCEDURES == True:
        print("Yes")
    else:
        print("No")

    print("Characters supported in identifier names : A-Z, 0-9, _, ", end="")
    tempString = (", ".join(serverInfo.SPECIAL_CHARS))
    endingPos = tempString.find(tempString[-1])
    tempString = tempString[:int(endingPos)]
    tempString += "and " + serverInfo.SPECIAL_CHARS[-1]
    print(tempString)

    print("ANSI/ISO SQL-92 conformance level        : ", end="")
    if serverInfo.SQL_CONFORMANCE == 'ENTRY':
        print("Entry-level compliance\n")
    elif serverInfo.SQL_CONFORMANCE == 'INTERMEDIATE':
        print("Intermediate-level compliance\n")
    elif serverInfo.SQL_CONFORMANCE == 'FULL':
        print("Full compliance\n")
    elif serverInfo.SQL_CONFORMANCE == 'FIPS127':
        print("FIPS-127-2 transitional compliance\n")

    # Display Another Header, Followed By A Five-Column List Of Reserved Keywords
    print("Reserved keywords:")
    print('_' * 92 + "\n")
    loopCounter = 0
    while loopCounter < len(serverInfo.KEYWORDS):
        colNumber = 0
        while colNumber < 5:
            print("{:<19}".format(serverInfo.KEYWORDS[loopCounter]), end="")
            colNumber += 1
            loopCounter += 1
            if colNumber is 5:
                print()
            if loopCounter is len(serverInfo.KEYWORDS):
                break

# End The Last Row And Add A Blank Line To The End Of The Report
print("\n")

# Close The Server Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
