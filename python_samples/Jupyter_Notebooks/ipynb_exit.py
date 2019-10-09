#-------------------------------------------------------------------------------------------------#
#  NAME:     ipynb_exit.py                                                                        #
#                                                                                                 #
#  PURPOSE:  This file contains classes and functions that allows "exit()" functionality to work  #
#            without raising an error or stopping the kernel when a Python application is         #
#            invoked from a Jupyter Notebook.                                                     #
#                                                                                                 #
#  USAGE:    Add the following line of code to the beginning of a Python program:                 #
#                                                                                                 #
#                 from ipynb_exit import exit                                                     #
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
import sys                        # Provides Information About Python Interpreter Constants,
                                  # Functions, & Methods
from io import StringIO           # Implements A File-Like Class That Reads And Writes A String
                                  # Buffer (i.e., A Memory File)
from IPython import get_ipython   # Simple Function To Call To Get The Current Interactive Shell
                                  # Instance

#-------------------------------------------------------------------------------------------------#
#  CLASS NAME:  ipynb_Exit()                                                                      #
#  PURPOSE:     This class contains attributes and methods that can be used to establish and      #
#               terminate a connection to a Db2 server or database.                               #
#-------------------------------------------------------------------------------------------------#
class ipynb_Exit(SystemExit):
    """Exit Exception for IPython. Exception temporarily redirects stderr to buffer."""

    #---------------------------------------------------------------------------------------------#
    #  FUNCTION NAME:  __init()__                                                                 #
    #  PURPOSE:        This method initializes an instance of the ipynb_Exit class.               #
    #---------------------------------------------------------------------------------------------#
    def __init__(self):
        sys.stderr = StringIO()        # Redirect sys.stderr to a StringIO (memory buffer) object.

    #---------------------------------------------------------------------------------------------#
    #  FUNCTION NAME:  __init()__                                                                 #
    #  PURPOSE:        This method cleans up when an instance of the ipynb_Exit class is          #
    #                  deleted.                                                                   #
    #---------------------------------------------------------------------------------------------#
    def __del__(self):
        sys.stderr = sys.__stderr__    # Restore sys.stderr to the original values it had at
                                       # the start of the program.

#-------------------------------------------------------------------------------------------------#
#  FUNCTION:  customExit()                                                                        #
#  PURPOSE:     This function contains attributes and methods that can be used to establish and   #
#               terminate a connection to a Db2 server or database.                               #
#-------------------------------------------------------------------------------------------------#
def customExit(returnCode=0):
    if returnCode is 0:
        ipynb_Exit()
    else:
        raise ipynb_Exit

#-------------------------------------------------------------------------------------------------#
# If An Application Running With IPython (i.e., A Jupyter Notebook) Calls The Exit Function,      #
# Call A Custom Exit Routine So The Jupyter Notebook Will Not Stop Running; Otherwise, Call The   #
# Default Exit Routine                                                                            #
#-------------------------------------------------------------------------------------------------#
if get_ipython():    
    exit = customExit                  # Rebind To The Custom Exit Function
else:
    exit = exit                        # Just Call The Exit Function
