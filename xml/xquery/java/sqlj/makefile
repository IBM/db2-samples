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
# MAKEFILE for SQLj samples on Unix
#
# Enter one of the following commands
#
#   make <app_name>        - Builds the program designated by <app_name>.
#
#   make all               - Builds all supplied sample programs.
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
############################################################################
#                  1 -- VARIABLES
############################################################################

# This file assumes the DB2 instance path is defined by the variable HOME.
# It also assumes DB2 is installed under the DB2 instance.
# If these statements are not correct, update the variable DB2PATH.
DB2PATH = $(HOME)/sqllib

# To connect to a remote SAMPLE database cataloged on the client machine
# with another name, update the DB variable.
DB=sample
# Set UID, PWD, SERVER_NAME and PORT_NUMBER
# You need to hardcode at least the password in the makefile
# Update the PORT_NUMBER in case the default value is not correct
UID=$(USER)
PWD=
SERVER_NAME=$(HOSTNAME)
PORT_NUMBER=50000

COPY=cp
ERASE=rm -f

#############################################################################
#  2 -- MAKE CATEGORIES
#              2a - make all 
#              2b - make clean
#              2c - make cleanall
#############################################################################

#****************************************************************************
#                  2a - make all 
#****************************************************************************

all : XPath XQuery Flwor  SqlXQuery


#****************************************************************************
#                  2b - make clean
#****************************************************************************

clean :
	$(ERASE) XPath.java
	$(ERASE) XQuery.java
	$(ERASE) SqlXQuery.java
	$(ERASE) Flwor.java

#****************************************************************************
#                  2c - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) *.class *.ser

#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#                  3a -  standalone applications
#############################################################################
#***************************************************************************
#                  3a -  standalone applications
#***************************************************************************


XPath :  
	bldsqlj XPath $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

XQuery : 
	bldsqlj XQuery $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

Flwor: 
	bldsqlj Flwor $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

SqlXQuery: 
	bldsqlj SqlXQuery $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

