#############################################################################
# (c) Copyright IBM Corp. 2007 All rights reserved.
# 
# The following sample of source code ("Sample") is owned by International 
# Business Machines Corporation or one of its subsidiaries ("IBM") and is 
# copyrighted and licensed, not sold. You may use, copy, modify, and 
# distribute the Sample in any form without payment to IBM, for the purpose of 
# assisting you in the development of your applications.
# 
# The Sample code is provided to you on an "AS IS" basis, without warranty of 
# any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
# IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
# not allow for the exclusion or limitation of implied warranties, so the above 
# limitations or exclusions may not apply to you. IBM shall not be liable for 
# any damages you suffer as a result of using, copying, modifying or 
# distributing the Sample, even if IBM has been advised of the possibility of 
# such damages.
#############################################################################
#
# MAKEFILE for JDBC XQUERY samples on UNIX 
#
# Enter one of the following commands 
#
#   make <app_name>        - Builds the program designated by <app_name>.
#
#   make all               - Builds all supplied sample programs 
#
#   make srv               - Builds sample that can only be run on the server,
#                            (stored procedure)
#
#   make all_client        - Builds all client samples (all programs in the
#                            'call_rtn' and 'client_run' categories).
#
#   make call_rtn          - Builds client programs that call stored procedure 
#
#   make client_run        - Builds all programs that run completely on the 
#                            client (not ones that call stored procedure) 
#
#   make clean             - Erases all intermediate files produced in the 
#                            build process.
#
#   make cleanall          - Erases all files produced in the build process
#                            (all files except the original source files).
#
# The makefile contains the following sections:
#    1 -- VARIABLES
#    2 -- MAKE CATEGORIES
#    3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#
#
##############################################################################
#                  1 -- VARIABLES                                     
##############################################################################

# This file assumes the DB2 instance path is defined by the variable HOME.
# It also assumes DB2 is installed under the DB2 instance.
# If these statements are not correct, update the variable DB2PATH. 
DB2PATH = $(HOME)/sqllib

COPY=cp
ERASE=rm -f

#############################################################################
#  Generic rule to make a class from a java source file
#############################################################################

.SUFFIXES : .class .java

.java.class :
	javac $<

#############################################################################
#  2 -- MAKE CATEGORIES
#              2a - make all (srv + all_client)
#              2b - make srv
#              2c - make all_client (call_rtn + client_run + java_beans)
#              2d - make call_rtn
#              2e - make client_run
#              2f - make clean
#              2g - make cleanall
#############################################################################

#****************************************************************************
#                  2a - make all (srv + all_client)
#****************************************************************************

all : \
        srv \
        all_client

#****************************************************************************
#                  2b - make srv
#****************************************************************************

srv : \
        Xquery_XmlProc

#****************************************************************************
#                  2c - make all_client (call_rtn + client_run + java_beans)
#****************************************************************************

all_client : \
	call_rtn \
	client_run

#****************************************************************************
#                  2d - make call_rtn
#****************************************************************************

call_rtn : \
           Xquery_XmlProc_Client
#****************************************************************************
#                  2e - make client_run
#****************************************************************************

client_run : \
             XPath Flwor SqlXQuery XQuery XQueryParam XUpdate
#****************************************************************************
#                  2f - make clean
#****************************************************************************

clean : 

#****************************************************************************
#                  2g - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) *.class
	$(ERASE) $(DB2PATH)/function/Xquery_XmlProc.class

#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#                  3a -  standalone applications
#                  3b -  client/server applications
#############################################################################


#****************************************************************************
#                  3a -  standalone applications
#****************************************************************************

XPath : XPath.class

Flwor : Flwor.class

SqlXQuery : SqlXQuery.class 

XQuery : XQuery.class

XQueryParam : XQueryParam.class

XUpdate : XUpdate.class

#****************************************************************************
#                  3b -  client/server applications
#****************************************************************************

#--------------------SpClient / SpServer------------------------------------#
# Note: before you execute SpClient for the first time, you must call the
# SpCreate.db2 CLP script to catalog the methods in SpServer as stored
# procedures. Call SpDrop.db2 to uncatalog the methods in SpServer.

Xquery_XmlProc_Client : Xquery_XmlProc_Client.class

Xquery_XmlProc : Xquery_XmlProc.class
	$(ERASE) $(DB2PATH)/function/Xquery_XmlProc.class
	$(COPY) Xquery_XmlProc.class $(DB2PATH)/function
	spcat_xquery
