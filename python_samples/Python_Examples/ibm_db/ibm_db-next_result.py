#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-next_result.py                                                                #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.next_result() API.      #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.exec_immediate()                                                         #
#                 ibm_db.callproc()                                                               #
#                 ibm_db.fetch_tuple()                                                            #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-next_result.py                                                              #
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
spName = "HIGH_EARNERS"
returnCode = False
dataRecord = False

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Database
conn = Db2ConnectionMgr('DB', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    dbConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

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
    returnCode = ibm_db.exec_immediate(dbConnection, sqlStatement)
except Exception:
    pass

# If The SQL Statement Could Not Be Executed, Display An Error Message And Exit 
if returnCode is False:
    print("\nERROR: Unable to execute the SQL statement specified.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")

# Execute The Stored Procedure Just Created
resultSet_1 = None
print("Executing the " + spName + " procedure & retrieving the first ", end="")
print("result set produced ... ", end="")
try:
    resultSet_1 = ibm_db.callproc(dbConnection, spName)
except Exception:
    pass

# If The Stored Procedure Specified Could Not Be Executed, Display An Error Message And Exit 
if resultSet_1 is None:
    print("\nERROR: Unable to execute the stored procedure specified.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message; Then Format And Display The Data Values Returned
else:
    print("Done!\n")

# Retrieve The Second Result Set From The Stored Procedure Just Executed
print("Retrieving the second result set produced by the " + spName, end="")
print(" procedure ... ", end="")
resultSet_2 = False
try:
    resultSet_2 = ibm_db.next_result(resultSet_1)
except Exception:
    pass

# If The Second Result Set Could Not Be Retrieved, Display An Error Message And Exit 
if resultSet_2 is False:
    print("\nERROR: Unable to retrieve the second result set returned by the stored procedure.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message
else:
    print("Done!\n")  

# Retrieve The Third Result Set From The Stored Procedure Just Executed
print("Retrieving the third result set produced by the " + spName, end="")
print(" procedure ... ", end="")
resultSet_3 = False
try:
    resultSet_3 = ibm_db.next_result(resultSet_1)
except Exception:
    pass

# If The Third Result Set Could Not Be Retrieved, Display An Error Message And Exit 
if resultSet_3 is False:
    print("\nERROR: Unable to retrieve the third result set returned by the stored procedure.")
    conn.closeConnection()
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

    # Retrieve A Record From The Appropriate Result Set And Store It In A Python Tuple
    if loopCounter is 1:
        try:
            dataRecord = ibm_db.fetch_tuple(resultSet_1)
        except:
            pass
    elif loopCounter is 2:
        try:
            dataRecord = ibm_db.fetch_tuple(resultSet_2)
        except:
            pass
    elif loopCounter is 3:
        try:
            dataRecord = ibm_db.fetch_tuple(resultSet_3)
        except:
            pass

    # If The Record Could Not Be Retrieved Or If There Was No Data To Retrieve, Increment The
    # Loop Counter Variable And Set The Appropriate Variables To True 
    if dataRecord is False:
        loopCounter += 1
        printHeader = True
        dataRecord = True
        
        # If There Is No More Data To Retrieve, Set The "No Data" Flag And Exit The Loop  
        if loopCounter is 4:
            noData = True
        else:
            continue
        
    # Otherwise, Extract And Display The Information Stored In The Data Record Retrieved
    else:
        print("  {:<14}" .format(dataRecord[0]), end="")
        print("  {:<18}" .format(dataRecord[1]), end="")
        print("  ${:>9}" .format(dataRecord[2]), end="")
        print("  {:<10}" .format(dataRecord[3]))

# Add A Blank Line To The End Of The Report
print()

# Close The Database Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
