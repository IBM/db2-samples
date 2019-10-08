#! /usr/bin/python3
#-------------------------------------------------------------------------------------------------#
#  NAME:     ibm_db-callproc.py                                                                   #
#                                                                                                 #
#  PURPOSE:  This program is designed to illustrate how to use the ibm_db.callproc() API.         #
#                                                                                                 #
#            Additional APIs used:                                                                #
#                 ibm_db.exec_immediate()                                                         #
#                                                                                                 #
#  USAGE:    Log in as a Db2 database instance user (for example, db2inst1) and issue the         #
#            following command from a terminal window:                                            #
#                                                                                                 #
#            ./ibm_db-callproc.py                                                                 #
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
spName = "SALARY_STATS"
returnCode = False
spParamValues = (0.0, 0.0, 0.0)
resultSet = None

# Create An Instance Of The Db2ConnectionMgr Class And Use It To Connect To A Db2 Database
conn = Db2ConnectionMgr('DB', dbName, '', '', userID, passWord)
conn.openConnection()
if conn.returnCode is True:
    dbConnection = conn.connectionID
else:
    conn.closeConnection()
    exit(-1)

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
print("Executing the " + spName + " stored procedure ... ", end="")
try:
    resultSet = ibm_db.callproc(dbConnection, spName, spParamValues)
except Exception:
    pass

# If The Stored Procedure Specified Could Not Be Executed, Display An Error Message And Exit 
if resultSet is None:
    print("\nERROR: Unable to execute the stored procedure specified.")
    conn.closeConnection()
    exit(-1)

# Otherwise, Complete The Status Message; Then Format And Display The Data Values Returned
else:
    print("Done!\n")

    # Display A Report Header
    print("Salary statistics:")
    print("______________________________")

    # Display The Data Values Returned By The Stored Procedure
    print("Highest salary   : ${:>10.2f}" .format(resultSet[1]))
    print("Lowest salary    : ${:>10.2f}" .format(resultSet[2]))
    print("Average salary   : ${:>10.2f}" .format(resultSet[3]))

# Add A Blank Line To The End Of The Report
print()

# Close The Database Connection That Was Opened Earlier
conn.closeConnection()

# Return Control To The Operating System
exit()
