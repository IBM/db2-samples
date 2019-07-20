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
# MAKEFILE for JDBC samples on Unix
#
# Enter one of the following commands 
#
#   make <app_name>        - Builds the program designated by <app_name>.
#
#   make all               - Builds all supplied sample programs except GSS API
#                            plugin samples. 
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
#   make java_beans        - Builds all Java Beans samples
#
#   make jcc_plugins       - Builds all Java GSS-API Plugins samples (this requires
#                            IBM DB2 Universal Driver to be installed in the CLASSPATH)
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
#              2c - make rtn
#              2d - make all_client (call_rtn + client_run + java_beans)
#              2e - make call_rtn
#              2f - make client_run
#              2g - make java_beans
#              2h - make jcc_plugins
#              2i - make clean
#              2j - make cleanall
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
        rtn 

#****************************************************************************
#                  2c - make rtn
#****************************************************************************

rtn : \
        SpServer \
        UDFsrv \
	UDFsqlsv \
	UDFjsrv

#****************************************************************************
#                  2d - make all_client (call_rtn + client_run + java_beans)
#****************************************************************************

all_client : \
	call_rtn \
	client_run \
	java_beans

#****************************************************************************
#                  2e - make call_rtn
#****************************************************************************

call_rtn : \
        SpClient \
        UDFcli \
	UDFsqlcl \
	UDFjcli

#****************************************************************************
#                  2f - make client_run
#****************************************************************************

client_run : \
	AdmCmdAutoCfg AdmCmdContacts AdmCmdDescribe \
	AdmCmdExport AdmCmdImport AdmCmdOnlineBackup AdmCmdQuiesce \
	AdmCmdUpdateCfg Applt \
	DbAuth DbConn DbInfo DbMCon DbNative DbSeq DbUse \
	DtInfo DtLob DtUdt \
	GetDBCfgParams GetDBMCfgParams GetLogs GetMessage LargeRid IlInfo \
	SetIntegrity TbAST TbCompress TbConstr TbCreate TbGenCol TbIdent TbInfo \
	TbInTrig TbMerge TbMod TbOnlineInx Temporal \
	TbPriv TbRead TbRowcompress TbRunstats TbSel TbTemp TbTrig TbUMQT \
	TbUnion Array_Stack Arrays_Sqlpl \
	TrustedContext ScalarFunctions ImplicitCasting Cgtt

#****************************************************************************
#                  2g - make java_beans
#****************************************************************************

java_beans : \
	CreateEmployee \
	GeneratePayroll

#****************************************************************************
#                  2h - make jcc_plugins
#****************************************************************************

jcc_plugins : \
	JCCKerberosPluginTest \
	JCCSimpleGSSPluginTest

#****************************************************************************
#                  2i - make clean
#****************************************************************************

clean : 

#****************************************************************************
#                  2j - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) *.class
	$(ERASE) $(DB2PATH)/function/SpServer.class
	$(ERASE) $(DB2PATH)/function/UDFsrv.class
	$(ERASE) $(DB2PATH)/function/Person.class
	$(ERASE) $(DB2PATH)/function/UDFjsrv.class
	$(ERASE) $(DB2PATH)/function/UDFsqlsv.class

#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#                  3b -  applet
#                  3c -  standalone applications
#                  3d -  client/server applications
#                  3e -  Java Beans applications
#                  3f -  Java GSS-API Plugin applications
#############################################################################

#****************************************************************************
#                  3b -  applet
#****************************************************************************

Applt : Applt.class

#****************************************************************************
#                  3c -  standalone applications
#****************************************************************************

AdmCmdAutoCfg : Util.class AdmCmdAutoCfg.class

AdmCmdContacts : Util.class AdmCmdContacts.class

AdmCmdDescribe : Util.class AdmCmdDescribe.class 

AdmCmdExport : Util.class AdmCmdExport.class

AdmCmdImport : Util.class AdmCmdImport.class

AdmCmdOnlineBackup : Util.class AdmCmdOnlineBackup.class

AdmCmdQuiesce : Util.class AdmCmdQuiesce.class

AdmCmdUpdateCfg : Util.class AdmCmdUpdateCfg.class

DbAuth : Util.class DbAuth.class

DbConn : Util.class DbConn.class

DbInfo : Util.class DbInfo.class

DbMCon : Util.class DbMCon.class
# Re-catalog sample database as sample2, 
# ignore errors since it may be cataloged already 
	-db2 catalog db sample as sample2

DbNative : Util.class DbNative.class

DbRsHold : Util.class DbRsHold.class
# Sample DbRsHold.java requires jdk/jre 1.4

DbSeq : Util.class DbSeq.class

DbUse : Util.class DbUse.class

DtInfo : Util.class DtInfo.class

DtLob : Util.class DtLob.class

DtUdt : Util.class DtUdt.class

GetDBCfgParams : Util.class GetDBCfgParams.class

GetDBMCfgParams : Util.class GetDBMCfgParams.class

GetLogs : Util.class GetLogs.class

GetMessage : Util.class GetMessage.class

IlInfo : Util.class IlInfo.class

LargeRid : Util.class LargeRid.class

SetIntegrity : Util.class SetIntegrity.class

TbAST : Util.class TbAST.class

TbCompress : Util.class TbCompress.class

TbConstr : Util.class TbConstr.class

TbCreate : Util.class TbCreate.class

TbGenCol : Util.class TbGenCol.class

TbIdent : Util.class TbIdent.class

TbInfo : Util.class TbInfo.class

TbInTrig : Util.class TbInTrig.class

TbMerge : Util.class TbMerge.class

TbMod : Util.class TbMod.class

TbOnlineInx : Util.class TbOnlineInx.class

TbPriv : Util.class TbPriv.class

TbRead : Util.class TbRead.class

TbRowcompress : Util.class TbRowcompress.class

TbRunstats : Util.class TbRunstats.class

TbSel  : Util.class TbSel.class
	
TbTemp : Util.class TbTemp.class

TbTrig : Util.class TbTrig.class

TbUMQT : Util.class TbUMQT.class

TbUnion : Util.class TbUnion.class

Temporal : Util.class Temporal.class

Arrays_Sqlpl : Util.class Arrays_Sqlpl.class

Array_Stack : Util.class Array_Stack.class

TrustedContext : Util.class TrustedContext.class

ScalarFunctions : Util.class ScalarFunctions.class

ImplicitCasting : Util.class ImplicitCasting.class

Cgtt : Cgtt.class

#****************************************************************************
#                  3d -  client/server applications
#****************************************************************************

#--------------------SpClient / SpServer------------------------------------#
# Note: before you execute SpClient for the first time, you must call the
# SpCreate.db2 CLP script to catalog the methods in SpServer as stored
# procedures. Call SpDrop.db2 to uncatalog the methods in SpServer.

SpCat :
	spcat

SpClient : Util.class SpClient.class

SpServer : SpServer.class
	$(ERASE) $(DB2PATH)/function/SpServer.class
	$(COPY) SpServer.class $(DB2PATH)/function
	spcat

#--------------------UDFcli  / UDFsrv---------------------------------------#
# Note: before you execute UDFcli for the first time, you must call the
# UDFCreate.db2 CLP script to register the functions in UDFsrv as 
# User Defined Functions (UDFs).

UDFcat :
	udfcat

UDFcli : UDFcat Util.class UDFcli.class

UDFsrv : UDFsrv.class
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

UDFjcli : UDFjcat Util.class UDFjcli.class

UDFjsrv : UDFjsrv.class
	$(ERASE) $(DB2PATH)/function/UDFjsrv.class
	$(COPY) UDFjsrv.class $(DB2PATH)/function


#-------------------- UDFjcli / UDFjsrv ------------------------------#
# Note: before you execute UDFsqlcl for the first time, you must call the
# UDFsCreate.db2 CLP script to register the functions in UDFsqlsv as 
# User Defined Functions (UDFs). 

UDFsqlcl : Util.class UDFsqlcl.class

UDFsqlsv : UDFsqlsv.class
	$(ERASE) $(DB2PATH)/function/UDFsqlsv.class
	$(ERASE) $(DB2PATH)/function/Person.class
	$(COPY) UDFsqlsv.class $(DB2PATH)/function
	$(COPY) Person.class $(DB2PATH)/function

#****************************************************************************
#                  3e -  Java Beans applications
#****************************************************************************

CreateEmployee : Util.class CreateEmployee.class

GeneratePayroll : Util.class GeneratePayroll.class

#****************************************************************************
#                  3f -  JCC Plugins applications
#****************************************************************************

JCCKerberosPluginTest : JCCKerberosPluginTest.class JCCKerberosPlugin.class \
	JCCSimpleGSSException.class

JCCSimpleGSSPluginTest: JCCSimpleGSSContext.class JCCSimpleGSSCredential.class \
	JCCSimpleGSSException.class JCCSimpleGSSName.class \
	JCCSimpleGSSPlugin.class JCCSimpleGSSPluginTest.class 
