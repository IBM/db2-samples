#############################################################################
# (c) Copyright IBM Corp. 2009 All rights reserved.
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
# MAKEFILE for DB2CI samples on Linux
#
# Enter one of the following commands
#
#   make <app_name>	   - Builds the program designated by <app_name>
#   make all		   - Builds all supplied sample programs
#   make clean		   - Erases all intermediate files produced in the
#			      build process
#   make cleanall	   - Erases all files produced in the build process
#			      (all files except the original source files)
#
# The makefile contains the following sections:
#    1 -- VARIABLES
#    2 -- MAKE CATEGORIES
#    3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#
#
##############################################################################
#		   1 -- VARIABLES				
##############################################################################

# This file assumes the DB2 instance path is defined by the variable HOME.
# It also assumes DB2 is installed under the DB2 instance.
# If these statements are not correct, update the variable DB2PATH.
DB2PATH = $(HOME)/sqllib


BLDAPP=bldapp


# To connect to a remote SAMPLE database cataloged on the client machine
# with another name, update the ALIAS variable.
ALIAS=sample
# Set UID and PWD if neccesary
UID=
PWD=

COPY=cp
ERASE=rm -f

#############################################################################
#  2 -- MAKE CATEGORIES
#	       2a - make all
#	       2f - make clean
#	       2g - make cleanall
#############################################################################


#****************************************************************************
#		   2a - make all
#****************************************************************************

all : \
	client_run

client_run : \
	tbmod \
	cihandl \
	dbuse \
	ilinfo \
	tbcompress \
	tbcreate \
	tbread

#****************************************************************************
#		   2f - make clean
#****************************************************************************

clean :
	$(ERASE) *.o *.map *.TXT *.BMP *.GIF *.XWD

#****************************************************************************
#		   2g - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) tbmod cihandl dbuse ilinfo tbcompress tbcreate tbread


#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#		   3a -  regular samples
#############################################################################


#****************************************************************************
#		   3a -  regular samples
#****************************************************************************

tbmod :
	$(BLDAPP) tbmod

cihandl :
	$(BLDAPP) cihandl

dbuse   :
	$(BLDAPP) dbuse

ilinfo  :
	$(BLDAPP) ilinfo

tbcompress :
	$(BLDAPP) tbcompress

tbcreate   :
	$(BLDAPP) tbcreate

tbread     :
	$(BLDAPP) tbread


