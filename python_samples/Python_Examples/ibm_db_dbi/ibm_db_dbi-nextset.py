#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db_dbi-nextset.py                                                                #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the .nextset() function of the     #
#            cursor object associated with the IBM_DBConnection object returned by the            #
#            ibm_db_dbi.connect() API.                                                            #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db_dbi-nextset.py                                                              #
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
spName = "HIGH_EARNERS"
returnCode = False
dataRecords = None

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

# Define The SQL Statement That Is To Be Used To Create A New Stored Procedure That
# Returns Three Result Sets
sqlStatement = "CREATE OR REPLACE PROCEDURE " + spName + " "
sqlStatement += "LANGUAGE SQL "
sqlStatement += "DYNAMIC RESULT SETS 3 "
sqlStatement += "READS SQL DATA "
sqlStatement += "NO EXTERNAL ACTION "
sqlStatement += "BEGIN "
sqlStatement += "  DECLARE avgSalary INT DEFAULT 0; "
sqlStatement += "  DECLARE c1 CURSOR WITH RETURN FOR "
sqlStatement += "    SELECT firstnme, lastname, salary, job FROM employee "
sqlStatement += "    WHERE job = 'DESIGNER' AND "
sqlStatement += "    salary > avgSalary "
sqlStatement += "    ORDER BY salary DESC; "
sqlStatement += "  DECLARE c2 CURSOR WITH RETURN FOR "
sqlStatement += "    SELECT firstnme, lastname, salary, job FROM employee "
sqlStatement += "    WHERE job = 'ANALYST' AND "
sqlStatement += "    salary > avgSalary "
sqlStatement += "    ORDER BY salary DESC; "
sqlStatement += "  DECLARE c3 CURSOR WITH RETURN FOR "
sqlStatement += "    SELECT firstnme, lastname, salary, job FROM employee "
sqlStatement += "    WHERE job = 'SALESREP' AND "
sqlStatement += "    salary > avgSalary "
sqlStatement += "    ORDER BY salary DESC; "
sqlStatement += "  SELECT INT(AVG(salary)) INTO avgSalary FROM employee; "
sqlStatement += "  OPEN c1; "
sqlStatement += "  OPEN c2; "
sqlStatement += "  OPEN c3; "
sqlStatement += "END"

# Execute The SQL Statement Just Defined
print("Creating an SQL stored procedure named \"" + spName + "\" ... ", end="")
try:
    resultSet = cursorID.execute(sqlStatement)
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if resultSet is None:
    print("\nERROR: Unable to execute the SQL statement specified.\n")
    connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Execute The Stored Procedure Just Created
print("Executing the " + spName + " stored procedure ... ", end="")
try:
    cursorID.callproc(spName, None)

# If The Stored Procedure Specified Could Not Be Executed, Display An Error Message And Exit 
except Exception:
    print("\nERROR: Unable to execute the stored procedure specified.")
    connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
print("Done!\n")

# Retrieve The First Result Set From The Stored Procedure Just Executed
print("Retrieving the first result set produced by the " + spName, end="")
print(" procedure ... ", end="")
resultSet_1 = None
try:
    resultSet_1 = cursorID.fetchall()
except Exception:
    pass

# If The First Result Set Could Not Be Retrieved, Display An Error Message And Exit 
if resultSet_1 is None:
    print("\nERROR: Unable to retrieve the first result set returned by the stored procedure.")
    connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")  

# Retrieve The Second Result Set From The Stored Procedure Just Executed
print("Retrieving the second result set produced by the " + spName, end="")
print(" procedure ... ", end="")
resultSet_2 = None
cursorID.nextset()
try:
    resultSet_2 = cursorID.fetchall()
except Exception:
    pass

# If The Second Result Set Could Not Be Retrieved, Display An Error Message And Exit 
if resultSet_2 is None:
    print("\nERROR: Unable to retrieve the second result set returned by the stored procedure.")
    connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")  

# Retrieve The Third Result Set From The Stored Procedure Just Executed
print("Retrieving the third result set produced by the " + spName, end="")
print(" procedure ... ", end="")
resultSet_3 = None
cursorID.nextset()
try:
    resultSet_3 = cursorID.fetchall()
except Exception:
    pass

# If The Third Result Set Could Not Be Retrieved, Display An Error Message And Exit 
if resultSet_3 is False:
    print("\nERROR: Unable to retrieve the third result set returned by the stored procedure.")
    connectionID.close()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Display A Report Header
print("Information retrieved:")

# As Long As There Are Records To Retrieve, ... 
noData = False
loopCounter = 1
printHeader = True
dataRecord = True
while noData is False:

    # Display Record Header Information
    if printHeader is True:
        print("\n  Result set " + str(loopCounter) + " details:\n")
        print("  FIRSTNME        LASTNAME            SALARY      JOB")
        print("  ______________  __________________  __________  ________")
        printHeader = False

    # Print The Records In The Appropriate Result Set
    if loopCounter is 1:
        for dataRecord in resultSet_1:
            print("  {:<14}" .format(dataRecord[0]), end="")
            print("  {:<18}" .format(dataRecord[1]), end="")
            print("  ${:>9}" .format(dataRecord[2]), end="")
            print("  {:<10}" .format(dataRecord[3]))
    elif loopCounter is 2:
        for dataRecord in resultSet_2:
            print("  {:<14}" .format(dataRecord[0]), end="")
            print("  {:<18}" .format(dataRecord[1]), end="")
            print("  ${:>9}" .format(dataRecord[2]), end="")
            print("  {:<10}" .format(dataRecord[3]))
    elif loopCounter is 3:
        for dataRecord in resultSet_3:
            print("  {:<14}" .format(dataRecord[0]), end="")
            print("  {:<18}" .format(dataRecord[1]), end="")
            print("  ${:>9}" .format(dataRecord[2]), end="")
            print("  {:<10}" .format(dataRecord[3]))

    # Increment The Loop Counter Variable And Set The Appropriate Variables To True 
    loopCounter += 1
    printHeader = True
    dataRecord = True
        
    # If There Is No More Data To Retrieve, Set The "No Data" Flag And Exit The Loop  
    if loopCounter is 4:
        noData = True
    else:
        continue

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
