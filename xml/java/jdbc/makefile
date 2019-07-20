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
# MAKEFILE for XML JDBC samples on Unix
#
# Enter one of the following commands 
#
#   make <app_name>        - Builds the program designated by <app_name>.
#
#   make all               - Builds all supplied sample programs except GSS API
#                            plugin samples. 
#
#   make srv               - Builds samples that can only be run on the server,
#                            includes stored procedures.
#
#   make call_srv          - Builds all client programs that call stored 
#                            procedures. 
#
#   make all_client        - Builds all client samples (all programs in the
#                             'call_srv' and 'client_run' categories).
#
#   make client_run        - Builds all programs that run completely on the
#                            client (not ones that call stored procedures).
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
#              2b - make all_client
#              2c - make srv
#              2d - make call_srv
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
#                  2b - make all_client (call_srv + client_run)
#****************************************************************************

all_client : \
        call_srv \
        client_run 

#****************************************************************************
#                  2c - make srv
#****************************************************************************

srv : \
        Simple_XmlProc

#****************************************************************************
#                  2d - make call_srv
#****************************************************************************

call_srv : \
        Simple_XmlProc_Client 

#****************************************************************************
#                  2e - make client_run
#****************************************************************************

client_run : \
	XmlSchema XmlRunstats XmlIndex XmlConst XmlInsert XmlUpDel \
	XmlRead RelToXmlDoc RelToXmlType XmlToTable \
	XmlDecomposition  XsUpdate RecXmlDecomp XmlCheckConstraint \
	XmlTrig XmlUdfs XmlMdc 

#****************************************************************************
#                  2f - make clean
#****************************************************************************

clean :
	$(ERASE) *.class 

#****************************************************************************
#                  2g - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) $(DB2PATH)/function/Simple_XmlProc.class

#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#                  3a -  standalone applications
#                  3b -  client/server applications
#############################################################################


#****************************************************************************
#                  3a -  standalone applications
#****************************************************************************

XmlSchema : XmlSchema.class

XmlRunstats : Util.class XmlRunstats.class 

XmlIndex : Util.class XmlIndex.class

XmlConst : Util.class XmlConst.class

XmlInsert : Util.class XmlInsert.class 

XmlUpDel : Util.class XmlUpDel.class

XmlToTable : Util.class XmlToTable.class

XmlRead : Util.class XmlRead.class

RelToXmlDoc : Util.class RelToXmlDoc.class

RelToXmlType : Util.class RelToXmlType.class

XmlDecomposition : Util.class XmlDecomposition.class 

XsUpdate : Util.class XsUpdate.class

RecXmlDecomp : Util.class RecXmlDecomp.class

XmlCheckConstraint : Util.class XmlCheckConstraint.class

XmlTrig : Util.class XmlTrig.class

XmlUdfs: Util.class XmlUdfs.class

XmlMdc: Util.class XmlMdc.class

#****************************************************************************
#                  3b -  client/server applications
#****************************************************************************

#-----------------Simple_XmlProc_Client / Simple_XmlProc--------------------------#
# Note: before you execute Simple_XmlProc_Client for the first time, you must call the
# Simple_XmlProc_Create.db2 CLP script to catalog the methods in Simple_XmlProc as stored
# procedures. Call Simple_XmlProc_Drop.db2 to uncatalog the methods in Simple_XmlProc.

SpCat :
	spcat_xml

Simple_XmlProc_Client : Util.class Simple_XmlProc_Client.class

Simple_XmlProc : Simple_XmlProc.class
	$(ERASE) $(DB2PATH)/function/Simple_XmlProc.class
	$(COPY) Simple_XmlProc.class $(DB2PATH)/function
	spcat_xml

