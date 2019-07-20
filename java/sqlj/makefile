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
#   make srv               - Builds samples that can only be run on the server,
#                            including routines, stored procedures and UDFs.
#
#   make rtn               - Builds all routines, stored procedures and UDFs.
#
#   make all_client        - Builds all client samples (all programs in the
#                            'call_rtn' and 'client_run' categories).
#
#   make call_rtn          - Builds all client programs that call routines,
#                            stored procedures and UDFs.
#
#   make client_run        - Builds all programs that run completely on the
#                            client (not ones that call routines, stored
#                            procedures or UDFs).
#
#   make java_beans        - Builds all Java Beans samples.
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
UID=$(USER)
PWD=
SERVER_NAME=$(HOSTNAME)
PORT_NUMBER=50000

COPY=cp
ERASE=rm -f

#############################################################################
#  2 -- MAKE CATEGORIES
#              2a - make all (srv + all_client)
#              2b - make srv
#              2c - make rtn
#              2d - make all_client (call_rtn + client_run + java_beans)
#              2e - make call_rtn
#              2f - make client_run
#              2g - make java_beans
#              2h - make clean
#              2i - make cleanall
#############################################################################

#****************************************************************************
#                  2a - make all (srv + all_client)
#****************************************************************************

all : \
	srv \
	all_client \
	sqljds

#****************************************************************************
#                  2b - make srv
#****************************************************************************

srv : \
	rtn

#****************************************************************************
#                  2c - make rtn
#****************************************************************************

rtn : \
	SpServer \
	UDFsrv \
	UDFjsrv

#****************************************************************************
#                  2d - make all_client (call_rtn + client_run + java_beans)
#****************************************************************************

all_client : \
	call_rtn \
	client_run \
	sqljds \
	java_beans

#****************************************************************************
#                  2e - make call_rtn
#****************************************************************************

call_rtn : \
	SpClient \
	UDFcli \
	UDFjcli

#****************************************************************************
#                  2f - make client_run
#****************************************************************************

client_run : \
	Applt \
	DbAuth DbConn DbMCon DbUse \
	DtUdt \
	LargeRid SetIntegrity \
	TbAST TbCompress TbConstr TbCreate TbIdent TbInfo TbMod TbOnlineInx \
	TbPriv TbRead TbRowcompress TbRunstats TbSel TbTemp TbTrig TbUMQT \

#****************************************************************************
#                  2g - make java_beans
#****************************************************************************

java_beans : \
	CreateEmployee \
	GeneratePayroll

#****************************************************************************
#                  2h - make clean
#****************************************************************************

clean :
	$(ERASE) Applt.java
	$(ERASE) CreateEmployee.java
	$(ERASE) DbAuth.java
	$(ERASE) DbConn.java
	$(ERASE) DbMCon.java
	$(ERASE) DbUse.java
	$(ERASE) DtUdt.java
	$(ERASE) GeneratePayroll.java
	$(ERASE) LargeRid.java
	$(ERASE) SetIntegrity.java
	$(ERASE) TbAST.java
	$(ERASE) TbCompress.java
	$(ERASE) TbConstr.java
	$(ERASE) TbCreate.java
	$(ERASE) TbIdent.java
	$(ERASE) TbInfo.java
	$(ERASE) TbMod.java
	$(ERASE) TbOnlineInx.java
	$(ERASE) TbPriv.java
	$(ERASE) TbRead.java
	$(ERASE) TbRowcompress.java
	$(ERASE) TbRunstats.java
	$(ERASE) TbSel.java
	$(ERASE) TbTemp.java
	$(ERASE) TbTrig.java
	$(ERASE) TbUMQT.java
	$(ERASE) SpClient.java
	$(ERASE) SpIterat.java
	$(ERASE) SpServer.java
	$(ERASE) UDFcli.java
	$(ERASE) UDFjcli.java
	$(ERASE) Util.java
	$(ERASE) Batch1Demo.java
	$(ERASE) Batch2Demo.java
	$(ERASE) Batch3Demo.java
	$(ERASE) BlobClobDemo.java
	$(ERASE) CreateDemoSchema.java
	$(ERASE) DbConnDataSource.java
	$(ERASE) DbConMDataSources.java
	$(ERASE) ScrollIterDemo.java

#****************************************************************************
#                  2i - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) *.class *.ser
	$(ERASE) $(DB2PATH)/function/SpContext.class
	$(ERASE) $(DB2PATH)/function/SpIterat.class
	$(ERASE) $(DB2PATH)/function/SpServer.class
	$(ERASE) $(DB2PATH)/function/SpServerEmployees.class
	$(ERASE) $(DB2PATH)/function/SpServerSalary.class
	$(ERASE) $(DB2PATH)/function/SpServer_SJProfileKeys.class
	$(ERASE) $(DB2PATH)/function/SpServer_SJProfile0.ser
	$(ERASE) $(DB2PATH)/function/Person.class
	$(ERASE) $(DB2PATH)/function/UDFsrv.class
	$(ERASE) $(DB2PATH)/function/UDFjsrv.class


#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#                  3b -  applet
#                  3c -  standalone applications
#                  3d -  client/server applications
#                  3e -  Java Beans applications
#############################################################################

#***************************************************************************
#                  3b -  applet
#***************************************************************************
Applt : Applt.sqlj
	bldsqlj Applt $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

#***************************************************************************
#                  3c -  standalone applications
#***************************************************************************
DbAuth : Util.class DbAuth.sqlj
	bldsqlj DbAuth $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

DbConn : Util.class DbConn.sqlj
	bldsqlj DbConn $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

DbMCon : Util.class DbMCon.sqlj
# Re-catalog sample database as sample2,
# ignore errors since it may be cataloged already
	-db2 catalog db $(DB) as sample2
	bldsqlj DbMCon $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)
	java com.ibm.db2.jcc.sqlj.Binder \
		-url  jdbc:db2://$(SERVER_NAME):$(PORT_NUMBER)/sample2 \
		-user $(UID) -password $(PWD) $@_SJProfile0.ser

DbUse : Util.class DbUse.sqlj
	bldsqlj DbUse $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

DtUdt : Util.class DtUdt.sqlj
	bldsqlj DtUdt $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

LargeRid : Util.class LargeRid.sqlj
	LargeRidScrpt
	bldsqlj LargeRid $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB) 

SetIntegrity: Util.class SetIntegrity.sqlj
	SetIntegrityScrpt
	bldsqlj SetIntegrity $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)
 
TbAST : Util.class TbAST.sqlj
	TbASTScrpt
	bldsqlj TbAST $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbCompress : Util.class TbCompress.sqlj
	bldsqlj TbCompress $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbConstr : Util.class TbConstr.sqlj
	sqlj TbConstr.sqlj

TbCreate : Util.class TbCreate.sqlj
	bldsqlj TbCreate $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbIdent : Util.class TbIdent.sqlj
	bldsqlj TbIdent $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbInfo : Util.class TbInfo.sqlj
	bldsqlj TbInfo $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbMod : Util.class TbMod.sqlj
	bldsqlj TbMod $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbOnlineInx : Util.class TbOnlineInx.sqlj
	bldsqlj TbOnlineInx $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbPriv : Util.class TbPriv.sqlj
	bldsqlj TbPriv $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbRead : Util.class TbRead.sqlj
	bldsqlj TbRead $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbRowcompress : Util.class TbRowcompress.sqlj
	TbRowcompressScrpt	
	bldsqlj TbRowcompress $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbRunstats : Util.class TbRunstats.sqlj
	bldsqlj TbRunstats $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbSel  : Util.class TbSel.sqlj
	bldsqlj TbSel $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbTemp : Util.class TbTemp.sqlj
	sqlj TbTemp.sqlj

TbTrig : Util.class TbTrig.sqlj
	bldsqlj TbTrig $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

TbUMQT : Util.class TbUMQT.sqlj
	sqlj TbUMQT.sqlj

Util.class : Util.sqlj
	bldsqlj Util $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

#***************************************************************************
#                  3d -  client/server applications
#***************************************************************************

#--------------------SpClient / SpServer------------------------------------#
# Note: before you execute SpClient for the first time, you must call the
# SpCreate.db2 CLP script to catalog the methods in SpServer as stored
# procedures

SpCat :
	spcat

SpClient : Util.class SpClient.sqlj
	bldsqlj SpClient $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

SpIterat.class : SpIterat.sqlj
	sqlj SpIterat.sqlj

SpServer : SpIterat.class SpServer.sqlj
	bldsqlj SpServer $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)
	$(ERASE) $(DB2PATH)/function/SpContext.class
	$(ERASE) $(DB2PATH)/function/SpIterat.class
	$(ERASE) $(DB2PATH)/function/SpServer.class
	$(ERASE) $(DB2PATH)/function/SpServerEmployees.class
	$(ERASE) $(DB2PATH)/function/SpServerSalary.class
	$(ERASE) $(DB2PATH)/function/SpServer_SJProfileKeys.class
	$(ERASE) $(DB2PATH)/function/SpServer_SJProfile0.ser
	$(COPY) SpContext.class $(DB2PATH)/function
	$(COPY) SpIterat.class $(DB2PATH)/function
	$(COPY) SpServer.class $(DB2PATH)/function
	$(COPY) SpServerEmployees.class $(DB2PATH)/function
	$(COPY) SpServerSalary.class $(DB2PATH)/function
	$(COPY) SpServer_SJProfileKeys.class $(DB2PATH)/function
	$(COPY) SpServer_SJProfile0.ser $(DB2PATH)/function
	spcat

#--------------------UDFcli / UDFsrv------------------------------#
# Note: before you execute UDFcli for the first time, you must call the
# UDFCreate.db2 CLP script to register the functions in UDFsrv as
# User Defined Functions (UDFs).

UDFcat :
	udfcat

UDFcli : UDFcat Util.class UDFcli.sqlj
	bldsqlj UDFcli $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

UDFsrv : UDFsrv.java
	javac UDFsrv.java
	$(ERASE) $(DB2PATH)/function/UDFsrv.class
	$(ERASE) $(DB2PATH)/function/Person.class
	$(COPY) UDFsrv.class $(DB2PATH)/function
	$(COPY) Person.class $(DB2PATH)/function

#-------------------- UDFjcli / UDFjsrv ------------------------------#
# Note: before you execute UDFjcli for the first time, you must call the
# UDFjCreate.db2 CLP script to register the functions in UDFjsrv as
# User Defined Functions (UDFs).

UDFjcat :
	udfjcat

UDFjcli : UDFjcat Util.class UDFjcli.sqlj
	bldsqlj UDFjcli $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

UDFjsrv : UDFjsrv.java
	javac UDFjsrv.java
	$(ERASE) $(DB2PATH)/function/UDFjsrv.class
	$(COPY) UDFjsrv.class $(DB2PATH)/function

#***************************************************************************
#                  3e -  Java Beans applications
#***************************************************************************

CreateEmployee : Util.class CreateEmployee.sqlj
	bldsqlj CreateEmployee $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

GeneratePayroll : Util.class GeneratePayroll.sqlj
	bldsqlj GeneratePayroll $(UID) $(PWD) $(SERVER_NAME) $(PORT_NUMBER) $(DB)

#***************************************************************************
#                  3f -  Data Source sample application
#***************************************************************************

Batch1Demo : 
	bldsqljds Batch1Demo
	
Batch2Demo : 
	bldsqljds Batch2Demo
	
Batch3Demo : 
	bldsqljds Batch3Demo
	
BlobClobDemo : 
	bldsqljds BlobClobDemo
	
DbConnDataSource : 
	bldsqljds DbConnDataSource
	
DbConMDataSources : 
	bldsqljds DbConMDataSources
	
ScrollIterDemo : 
	bldsqljds ScrollIterDemo

#***************************************************************************
#                  3g -  Data Source sample applications
#***************************************************************************

sqljdssetup :
	javac createRegisterDS.java
	java createRegisterDS DS1.prop
	java createRegisterDS DS2.prop
	java createRegisterDS DS3.prop
	sqlj CreateDemoSchema.sqlj
	java CreateDemoSchema	
		
sqljds : sqljdssetup Batch1Demo Batch2Demo Batch3Demo BlobClobDemo \
	DbConnDataSource DbConMDataSources ScrollIterDemo 
	
