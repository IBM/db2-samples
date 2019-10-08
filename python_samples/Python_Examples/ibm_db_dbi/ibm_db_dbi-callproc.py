#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db_dbi-callproc.py                                                               #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the .callproc() function of the    #
#            cursor object associated with the IBM_DBConnection object returned by the            #
#            ibm_db_dbi.connect() API.                                                            #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db_dbi-callproc.py                                                             #
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

# Define And Initialize The Appropriate Variables
dbName = "SAMPLE"        # The Alias For The Cataloged, Local Database
userID = "db2inst1"      # The Instance User ID At The Local Server
passWord = "Passw0rd"    # The Password For The Instance User ID At The Local Server
connectionID = None
spName = "SALARY_STATS"
returnCode = False
spParamValues = (0.0, 0.0, 0.0)
resultSet = None

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

# Define The SQL Statement That Is To Be Used To Create A New Stored Procedure
sqlStatement = "CREATE OR REPLACE PROCEDURE " + spName
sqlStatement += "  (OUT maxSalary DOUBLE, OUT minSalary DOUBLE, OUT avgSalary DOUBLE) "
sqlStatement += "LANGUAGE SQL "
sqlStatement += "DYNAMIC RESULT SETS 0 "
sqlStatement += "READS SQL DATA "
sqlStatement += "NO EXTERNAL ACTION "
sqlStatement += "BEGIN"
sqlStatement += "  SELECT MAX(salary) INTO maxSalary FROM employee; "
sqlStatement += "  SELECT MIN(salary) INTO minSalary FROM employee; "
sqlStatement += "  SELECT AVG(salary) INTO avgSalary FROM employee; "
sqlStatement += "END"

# Execute The SQL Statement Just Defined
print("Creating an SQL stored procedure named \"" + spName + "\" ... ", end="")
try:
    resultSet = cursorID.execute(sqlStatement)
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if resultSet is False:
    print("\nERROR: Unable to execute the SQL statement specified.\n")
    connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Execute The Stored Procedure Just Created
print("Executing the " + spName + " stored procedure ... ", end="")
try:
    resultSet = cursorID.callproc(spName, spParamValues)
except Exception:
    pass

# If The Stored Procedure Specified Could Not Be Executed, Display An Error Message And Exit 
if resultSet is None:
    print("\nERROR: Unable to execute the stored procedure specified.")
    connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message; Then Format And Display The Data Values Returned
else:
    print("Done!\n")

    # Display A Report Header
    print("Salary statistics:")
    print("______________________________")

    # Display The Data Values Returned By The Stored Procedure
    print("Highest salary   : ${:>10.2f}" .format(resultSet[0]))
    print("Lowest salary    : ${:>10.2f}" .format(resultSet[1]))
    print("Average salary   : ${:>10.2f}" .format(resultSet[2]))

# Add A Blank Line To The End Of The Report
print()

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
