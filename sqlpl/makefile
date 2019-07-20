##############################################################################
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
##############################################################################
#
# MAKEFILE for SQL Procedures samples for Linux
#
# Enter one of the following commands 
#
#   make <app_name>        - Builds the program designated by <app_name>
#
#   make all               - Builds the all the supplied sample programs
#
#   make clean             - Erases intermediate files
#   make cleanall          - Erases all files produced in the build process,
#                            except the original source files
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

BLDAPP=bldapp

# To connect to a remote SAMPLE database cataloged on the client machine
# with another name, update the DB variable.
DB=sample
# Set UID and PWD if neccesary  
UID=
PWD=

COPY=cp
ERASE=rm -f

#############################################################################
#  2 -- MAKE CATEGORIES
#              2a - make all
#              2g - make clean
#              2h - make cleanall
#############################################################################


#****************************************************************************
#                  2a - make all
#****************************************************************************

all : \
        basecase baseif \
        dynamic \
        iterate \
        leave \
        loop \
        nestcase nestif \
        repeat rsultset \
	tbsel \
        whiles \
	NestedSP

#****************************************************************************
#                  2b - make clean
#****************************************************************************

clean :	\
	cleangen \
	cleanemb
 
cleangen :
	$(ERASE) *.class *.o *.map message.*

cleanemb :
	$(ERASE) basecase.c baseif.c
	$(ERASE) dynamic.c
	$(ERASE) iterate.c
	$(ERASE) leave.c loop.c
	$(ERASE) nestcase.c nestif.c
	$(ERASE) repeat.c
	$(ERASE) tbsel.c
	$(ERASE) utilemb.c
	$(ERASE) whiles.c


#****************************************************************************
#                  2h - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) *.bnd
	$(ERASE) basecase baseif
	$(ERASE) dynamic
	$(ERASE) iterate
	$(ERASE) leave loop
	$(ERASE) nestcase nestif
	$(ERASE) repeat rsultset
	$(ERASE) tbsel
	$(ERASE) whiles


#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#                  3a -  embedded SQL client samples
#                  3b -  CLI client sample
#                  3c -  JDBC client sample
#############################################################################

#****************************************************************************
#                  3a -  embedded SQL client samples
#****************************************************************************

basecase :
	$(BLDAPP) basecase $(DB) $(UID) $(PWD)

baseif :
	$(BLDAPP) baseif $(DB) $(UID) $(PWD)

dynamic :
	$(BLDAPP) dynamic $(DB) $(UID) $(PWD)

iterate :
	$(BLDAPP) iterate $(DB) $(UID) $(PWD)

leave :
	$(BLDAPP) leave $(DB) $(UID) $(PWD)

loop :
	$(BLDAPP) loop $(DB) $(UID) $(PWD)

nestif :
	$(BLDAPP) nestif $(DB) $(UID) $(PWD)

nestcase :
	$(BLDAPP) nestcase $(DB) $(UID) $(PWD)

repeat :
	$(BLDAPP) repeat $(DB) $(UID) $(PWD)

tbsel :
	$(BLDAPP) tbsel $(DB) $(UID) $(PWD)

whiles :
	$(BLDAPP) whiles $(DB) $(UID) $(PWD)


#****************************************************************************
#                  3b -  CLI client sample
#****************************************************************************

rsultset :
	$(BLDAPP) rsultset

#****************************************************************************
#                 3c - JDBC client samples 
#****************************************************************************

NestedSP : NestedSP.java
	javac Util.java
	javac NestedSP.java

