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
# MAKEFILE for XML SQLj samples on Unix
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

all : \
	XmlSchema XmlIndex XmlConst \
	XmlInsert XmlUpDel \
	XmlRead XmlToTable \
	RelToXmlType RelToXmlDoc \
	XmlXslt XmlIntegrate

#****************************************************************************
#                  2b - make clean
#****************************************************************************

clean :
	$(ERASE) XmlSchema.java
	$(ERASE) XmlIndex.java 
	$(ERASE) XmlConst.java 
	$(ERASE) XmlInsert.java 
	$(ERASE) XmlUpDel.java 
	$(ERASE) XmlRead.java 
	$(ERASE) XmlToTable.java
	$(ERASE) RelToXmlDoc.java
	$(ERASE) RelToXmlType.java
	$(ERASE) XmlXslt.java
	$(ERASE) XmlIntegrate.java

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

XmlSchema : Util.class XmlSchema.sqlj 
	sqlj XmlSchema.sqlj 

XmlIndex : Util.class XmlIndex.sqlj
	sqlj XmlIndex.sqlj

XmlConst : Util.class XmlConst.sqlj
	sqlj XmlConst.sqlj 

XmlInsert : Util.class XmlInsert.sqlj
	XmlInsertScrpt
	bldsqlj XmlInsert $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)
 
XmlToTable : Util.class XmlToTable.sqlj
	XmlToTableScrpt
	bldsqlj XmlToTable $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

RelToXmlType : Util.class RelToXmlType.sqlj
	cp $(DB2PATH)/samples/xml/data/setupscript.db2 .
	cp $(DB2PATH)/samples/xml/data/cleanupscript.db2 .
	RelToXmlScrpt
	bldsqlj RelToXmlType $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

RelToXmlDoc : Util.class RelToXmlDoc.sqlj
	reltoxmlprocScrpt
	bldsqlj RelToXmlDoc $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

XmlUpDel : Util.class XmlUpDel.sqlj
	XmlUpDelScrpt
	bldsqlj XmlUpDel $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB) 

XmlXslt : Util.class XmlXslt.sqlj
	XmlXsltScrpt
	bldsqlj XmlXslt $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

XmlIntegrate : Util.class XmlIntegrate.sqlj
	XmlIntegrateScrpt
	bldsqlj XmlIntegrate $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

XmlRead : Util.class XmlRead.sqlj
	bldsqlj XmlRead $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

Util.class : Util.sqlj
	bldsqlj Util $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)
