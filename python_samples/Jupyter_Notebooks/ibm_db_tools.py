#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db_tools.py                                                                      #
#                                                                                                 #
#  PURPOSE:  This file contains classes and functions that are used by many of the ibm_db sample  #
#            programs and Jupyter Notebooks.                                                      #
#                                                                                                 #
#            APIs used:                                                                           #
#                 ibm_db.connect()                                                                #
#                 ibm_db.conn_errormsg()                                                          #
#                 ibm_db.close()                                                                  #
#                 ibm_db.exec_immediate()                                                         #
#                 ibm_db.fetch_tuple()                                                            #
#                                                                                                 #
#  USAGE:    Add the following lines of code at the beginning of an ibm_db sample program:        #
#                                                                                                 #
#            from ibm_db_tools import Db2ConnectionMgr                                            #
#            from ibm_db_tools import get_row_count                                               #
#            from ibm_db_tools import query_sdb_dir (Use with Python sample programs only)        #
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
#  copy, modify, and distribute the Sample in any form without payment to IBM, for the purpose of #
#  assisting you in the creation of Python applications using the ibm_db library.                 #
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
import subprocess                 # Required To Execute A Shell Command
import socket                     # Provides Access To The BSD Low-Level Networking Interface 
import string                     # Privides APIs Needed To Work With Strings
from io import StringIO           # Implements A File-Like Class That Reads And Writes A String
                                  # Buffer (i.e., A Memory File)
from IPython import get_ipython   # Simple Function To Call To Get The Current Interactive Shell
                                  # Instance
import ibm_db                     # Contains The APIs Needed To Work With Db2 Databases

#-------------------------------------------------------------------------------------------------#
#  CLASS NAME:  Db2ConnectionMgr()                                                                #
#  PURPOSE:     This class contains attributes and methods that can be used to establish and      #
#               terminate a connection to a Db2 server or database.                               #
#-------------------------------------------------------------------------------------------------#
class Db2ConnectionMgr():
    """A simple class that manages a Db2 server or database connection."""

    #---------------------------------------------------------------------------------------------#
    #  FUNCTION NAME:  __init()__                                                                 #
    #  PURPOSE:        This method initializes all attributes used by an instance of the          #
    #                  Db2ConnectionMgr class.                                                    #
    #  PARAMETERS:     dbName   - Db2 server or database name                                     #
    #                  dsType   - Db2 server or database type ('DB' or 'SERVER')                  #
    #                  hostName - Db2 server host name or IP address                              #
    #                  portNum  - Port number Db2 uses at the specified server                    #
    #                  userID   - User authentication ID                                          #
    #                  passWord - User password                                                   #
    #---------------------------------------------------------------------------------------------#
    def __init__(self, dsType='', dbName=None, hostName='', portNum='', 
                 userID=None, passWord=None):
        """Initialize Db2 server or database name, user ID, and password attributes."""

        self.dsType = dsType
        self.dbName = dbName
        self.hostName = hostName
        self.portNum = portNum
        self.userID = userID
        self.passWord = passWord
        self.connectionID = None
        self.returnCode = False

        # If A Data Source Type Was Not Specified, Use 'DB' By Default
        if self.dsType is '':
            self.dsType = 'DB'

    #---------------------------------------------------------------------------------------------#
    #  FUNCTION NAME:  openConnection()                                                           #
    #  PURPOSE:        This method attempts to open the Db2 server or database connection         #
    #                  specified.                                                                 #
    #  PARAMETERS:     None                                                                       #
    #---------------------------------------------------------------------------------------------#
    def openConnection(self):
        """Attempt to establish a Db2 server or database connection."""

        # Define And Initialize The Appropriate Local Variables
        connString = "DRIVER={IBM DB2 ODBC DRIVER}"
        msgString = ""
        
        # If A Host Name Was Not Specified, Use The Name That Is Assigned To The Current Server
        if self.hostName is '':
            self.hostName = socket.gethostname()

        # If A Port Number Was Not Specified, Use Port Number 50000
        if self.portNum is '':
            self.portNum = '50000'

        # Display An Appropriate Status Message And Add The Correct "ATTACH" Value To The
        # Connection String Variable (connString)
        msgString = "\nConnecting to the "
        if self.dsType is 'LOCAL_SVR':
            print(msgString + "local server ... ", end="")
            if get_ipython():                             # If Running With IPython, ...
                connString += ";ATTACH=TRUE"              # Attach To A Server; Not A Database
            else:
                connString = "ATTACH=TRUE"                # Attach To A Server; Not A Database
        elif self.dsType is 'SERVER':
            print(msgString + self.hostName + " server ... ", end="")
            connString += ";ATTACH=TRUE"                  # Attach To A Server; Not A Database
        else:
            print(msgString + self.dbName + " database ... ", end="")
            connString += ";ATTACH=FALSE"                 # Attach To A Database; Not A Server

        # If Appropriate, Construct The Portion Of The Connection String That Will Be Used To
        # Establish A Connection To The Local Db2 Server
        if self.dsType is 'LOCAL_SVR':
            if get_ipython():                             # If Running With IPython, ...
                connString += ";HOSTNAME=" + socket.gethostname()
                connString += ";PORT=" + self.portNum
                connString += ";PROTOCOL=TCPIP"
                connString += ";UID=" + self.userID
                connString += ";PWD=" + self.passWord

        # Otherwise, Construct The Portion Of The Connection String That Will Be Used To 
        # Establish A Connection To A Remote Db2 Server Or A Db2 Database
        else:
            connString += ";DATABASE=" + self.dbName      # Only Used To Connect To A Database 
            connString += ";HOSTNAME=" + self.hostName    # Only Used To Connect To A Server
            connString += ";PORT=" + self.portNum         # Only Used To Connect To A Server
            connString += ";PROTOCOL=TCPIP"
            connString += ";UID=" + self.userID
            connString += ";PWD=" + self.passWord

        # Attempt To Establish A Connection To The Appropriate Db2 Server Or Database
        # If Running With IPython (i.e., Jupyter Notebook), ...
        if get_ipython():
            try:
                self.connectionID = ibm_db.connect(connString, '', '')
            except Exception:
                pass

        # If Running With Python, ...
        else:
            try:
                self.connectionID = ibm_db.connect(connString, self.userID, self.passWord)
            except Exception:
                pass

        # If A Connection Could Not Be Established, Display An Appropriate Error Message
        # And Set The Function Return Code Attribute To "False"
        if self.connectionID is None:
            msgString = "\nERROR: Unable to connect to the "
            if self.dsType is 'LOCAL_SVR':
                print(msgString + "local server ... ", end="")
            elif self.dsType is 'SERVER':
                print(msgString + self.hostName + " server.")
            else:
                print(msgString + self.dbName + " database.")
            msgString = ibm_db.conn_errormsg()
            print(msgString + "\n")
            print("Connection string used: " + connString + "\n")
            self.returnCode = False

        # If A Connection Could Be Established, Complete The Status Message And Set The
        # Return Code Attribute To "True"
        else:
            print("Done!\n")
            self.returnCode = True

    #---------------------------------------------------------------------------------------------#
    #  FUNCTION NAME:  closeConnection()                                                          #
    #  PURPOSE:        This method attempts to close the specified Db2 server or database         #
    #                  connection.                                                                #
    #  PARAMETERS:     None                                                                       #
    #---------------------------------------------------------------------------------------------#
    def closeConnection(self):
        """Attempt to close a Db2 server or database connection."""

        # Define And Initialize The Appropriate Local Variables
        msgString = ""
        returnCode = False
        
        # If A Db2 Server Or Database Connection Exists, ...
        if not self.connectionID is None:

            # Display An Appropriate Status Message
            msgString = "Disconnecting from the "
            if self.dsType is 'LOCAL_SVR':
                print(msgString + "local server ... ", end="")
            elif self.dsType is 'SERVER':
                print(msgString + self.hostName + " server ... ", end="")
            else:
                print(msgString + self.dbName + " database ... ", end="")

            # Attempt To Close A Db2 Server Or Database Connection That Was Opened Earlier
            try:
                returnCode = ibm_db.close(self.connectionID)
            except Exception:
                pass

            # If The Connection Could Not Be Closed, Display An Appropriate Error Message
            # And Set The Return Code Attribute To "False"
            if returnCode is False:
                msgString = "\nERROR: Unable to disconnect from the "
                if self.dsType is 'LOCAL_SVR':
                    print(msgString + "local server.")
                elif self.dsType is 'SERVER':
                    print(msgString + self.hostName + " server.")
                else:
                    print(msgString + self.dbName + " database.")
                msgString = ibm_db.conn_errormsg(self.connectionID)
                print(msgString + "\n")
                self.returnCode = False

            # If The Connection Could Be Closed, Complete The Status Message And Set The
            # Return Code Attribute To "True"
            else:
                print("Done!\n")
                self.returnCode = True


#-------------------------------------------------------------------------------------------------#
#  FUNCTION NAME:  get_row_count()                                                                #
#  PURPOSE:        This function queries the Db2 table specified and displays the number of rows  #
#                  (records) found in it.                                                         #
#  PARAMETERS:     dbConnection - A valid Db2 database connection                                 # 
#                  tableName    - Name of the table to be queried                                 #
#  RETURNS:        True         - A row count was obtained for the table specified                #
#                  False        - A row count could not be obtained for the table specified       #
#-------------------------------------------------------------------------------------------------#
def get_row_count(dbConnection, tableName):
    
    # Define And Initialize The Appropriate Local Variables
    resultSet = False
    dataRecord = False

    # Create The SQL Statement To Be Executed
    sqlStatement = "SELECT COUNT(*) FROM " + tableName + " WITH UR"

    # Execute The SQL Statement Just Defined
    try:
        resultSet = ibm_db.exec_immediate(dbConnection, sqlStatement)
    except Exception:
        pass

    # If The SQL Statement Could Not Be Executed, Display An Error Message And Return The
    # Value "False"
    if resultSet is False:
        print("\nERROR: Unable to execute the statement specified:")
        print("  " + sqlStatement + "\n")
        return False

    # Retrieve The Data Produced By The SQL Statement And Store It In A Python Tuple
    try:
        dataRecord = ibm_db.fetch_tuple(resultSet)
    except:
        pass

    # If The Data Could Not Be Retrieved, Display An Error Message And Return The Value "False"
    if dataRecord is False:
        print("\nERROR: Unable to retrieve the data produced by the SQL statement.")
        return False

    # If The Data Could Be Retrieved, Display It
    else:
        print("Number of records found in the " + tableName + " table: ", end="")
        print("{}\n" .format(dataRecord[0])) 
    
    # Return The Value "True" To The Calling Function
    return True


#-------------------------------------------------------------------------------------------------#
#  FUNCTION NAME:  query_sdb_dir()                                                                #
#  PURPOSE:        This function queries the Db2 System Database Directory and displays the       #
#                  information obtained.                                                          #
#  PARAMETERS:     dbName - Name of the database to retrieve information for                      # 
#  RETURNS:        True   - The Db2 System Database Directory was queried successfully            #
#                  False  - Information in Db2 System Database Directory could not be obtained    #
#-------------------------------------------------------------------------------------------------#
def query_sdb_dir(dbName):
    
    # Display An Appropriate Status Message
    print("Querying the system database directory ... ", end="")

    # Retrieve The Contents Of The Db2 System Database Directory
    result = subprocess.run(['db2', 'LIST DB DIRECTORY'], stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        universal_newlines=True)

    # If The Contents Of The System Database Directory Could Not Be Retrieved, Display An Error
    # Message And Return The Value "False"
    if result.returncode > 1:
        dirInfo = str("{}".format(result.stdout))
        if not 'SQL1057W' in dirInfo:
            print("\nERROR: {}".format(result.stdout))
        else:
            print("Done!\n")
            print("Information about the " + dbName + " database could not be found.\n")
        return False

    # Otherwise, Complete The Status Message And Store The Information Retrieved In A 
    # String Variable
    else:
        print("Done!\n")
        dirInfo = str("{}".format(result.stdout))

    # If A Record For The Database Specified Cannot Be Found In Information Obtained, Display
    # An Appropriate Message And Return The Value "False"
    tempName = dbName + "\n"
    if not tempName in dirInfo:
        print("Information about the " + dbName + " database could not be found.\n")
        return False

    # Otherwise, Extract The Record For The Database Specified From The System Database Directory
    # Information Retrieved
    else:

        # Display A Report Header
        print("System Database Directory")
        endingPos = dirInfo.find('Database 1 entry:')
        tempStr = dirInfo[30:int(endingPos - 2)]
        print(tempStr)
        print("__________________________________________________________")

        # Remove All Information Found In The String That Comes Before The Record For The
        # Database Specified
        dbName = dbName + "\n"
        startingPos = dirInfo.find(dbName)
        tempStr = dirInfo[int(startingPos - 59):]

        # Remove All Information Found In The String That Comes After The Record For The
        # Database Specified
        tempStr = tempStr.replace('entry:', 'entry&', 1)
        endingPos = tempStr.find('entry:')
        endingPos -= 10
        tempStr = tempStr[:endingPos]
        tempStr = tempStr.replace('entry&', 'entry:', 1)
        endingPos -= 1
        while not tempStr[endingPos] is '\n':
            endingPos -= 1
        dirInfo = tempStr[:endingPos]

        # Display The Record That Was Obtained For The Database Specified
        print(dirInfo + "\n")

    # Return The Value "True" To The Calling Function
    return True
