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
# MAKEFILE for C++ samples on Linux
#
# Enter one of the following commands
#
#   make <app_name>	   - Builds the program designated by <app_name>
#   make all		   - Builds all supplied sample programs
#   make srv		   - Builds all programs that that run on the server
#			      including routines (stored procedures and UDFs)
#   make rtn		   - Builds all routines (stored procedures and UDFs)
#   make all_client	   - Builds all client programs (all programs in the
#			      call_rtn and client_run categories)
#   make call_rtn	   - Builds all client programs that call routines
#   make client_run	   - Builds all programs that run completely on the
#			      client (not ones that call routines)
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
#############################################################################
#		   1 -- VARIABLES				      
#############################################################################

# This file assumes the DB2 instance path is defined by the variable HOME.
# It also assumes DB2 is installed under the DB2 instance.
# If these statements are not correct, update the variable DB2PATH.
DB2PATH = $(HOME)/sqllib

BLDAPP=bldapp
BLDRTN=bldrtn
BLDMC=bldmc
BLDMT=bldmt

# To connect to a remote SAMPLE database cataloged on the client machine
# with another name, update the ALIAS variable.
ALIAS=sample
# Set UID and PWD if neccesary
UID=
PWD=

# To connect to a remote SAMPLE2 database cataloged on the client machine
# with another name, update the ALIAS2 variable.
ALIAS2=sample2
# Set UID2 and PWD2 if neccesary
UID2=$(UID)
PWD2=$(PWD)

ERASE=rm -f

#############################################################################
#  2 -- MAKE CATEGORIES
#	       2a - make all (srv + all_client)
#	       2b - make srv
#	       2c - make rtn
#	       2d - make all_client (call_rtn + client_run)
#	       2e - make call_rtn
#	       2f - make client_run
#	       2g - make clean
#	       2h - make cleanall
#############################################################################

#****************************************************************************
#		   2a - make all (srv + all_client)
#****************************************************************************

all : \
	srv \
	all_client

#****************************************************************************
#		   2b - make srv
#****************************************************************************

srv : \
	rtn \
	dbcfg \
	instart

#****************************************************************************
#		   2c - make rtn
#****************************************************************************

rtn : \
	spserver \
	udfsrv \
	udfemsrv

#****************************************************************************
#		   2d - make all_client (call_rtn + client_run)
#****************************************************************************

all_client : \
	call_rtn \
	client_run

#****************************************************************************
#		   2e - make call_rtn
#****************************************************************************

call_rtn : \
	spclient \
	udfcli \
	udfemcli

#****************************************************************************
#		   2f - make client_run
#****************************************************************************

client_run : \
	cli_info clisnap clisnapnew \
	dbauth dbconn dbcreate dbhistfile dbinfo dbinline dbinspec \
	dblogconn \
	dbupgrade dbpkg dbrestore dbrollfwd \
	dbsample dbsnap dbsnapnew dtformat dbthrds dbuse \
	dtlob dtstruct dtudt \
	evm \
	fnuse \
	inattach inauth ininfo insnap insnapnew \
	tbast tbcompress tbconstr tbcreate tbident tbinfo tbintrig \
	tbloadcursor tbmerge tbmod tbmove tbonlineinx tbpriv tbread tbreorg \
	tbrunstats tbsavept tbsel tbtemp \
	tbtrig tbumqt tbunion tscreate tsinfo

#****************************************************************************
#		   2g - make clean
#****************************************************************************

clean :
	$(ERASE) *.o
	$(ERASE) *.DEL *.TXT *.MSG
	$(ERASE) dbauth.C dbcfg.C dbconn.C dbhistfile.C
	$(ERASE) dbinline.C dbinspec.C
	$(ERASE) dblogconn.C
	$(ERASE) dbpkg.C dbrestore.C dbrollfwd.C
	$(ERASE) dbsample.C dbthrds.C dbuse.C
	$(ERASE) dtformat.C dtlob.C dtstruct.C
	$(ERASE) dtudt.C 
	$(ERASE) evm.C fnuse.C
	$(ERASE) inauth.C
	$(ERASE) spclient.C spserver.C
	$(ERASE) tbast.C tbcompress.C tbconstr.C tbcreate.C tbident.C 
	$(ERASE) tbinfo.C tbintrig.C tbloadcursor.C tbmerge.C tbmod.C
	$(ERASE) tbmove.C tbonlineinx.C tbpriv.C tbread.C tbreorg.C
	$(ERASE) tbrunstats.C tbsavept.C tbsel.C tbtemp.C tbtrig.C
	$(ERASE) tbumqt.C tbunion.C 
	$(ERASE) tscreate.C 
	$(ERASE) udfcli.C udfemcli.C utilemb.C

#****************************************************************************
#		   2h - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) *.bnd
	$(ERASE) cli_info clisnap clisnapnew
	$(ERASE) dbauth dbcfg dbconn dbcreate dbhistfile
	$(ERASE) dbinline dbinfo dbinspec
	$(ERASE) dblogconn
	$(ERASE) dbupgrade dbpkg dbrestore dbrollfwd
	$(ERASE) dbsample dbsnap dbsnapnew dbthrds dbuse
	$(ERASE) dtformat dtlob dtstruct dtudt
	$(ERASE) evm
	$(ERASE) fnuse
	$(ERASE) inattach inauth ininfo insnap insnapnew instart
	$(ERASE) spclient spserver
	$(ERASE) tbast tbcompress tbconstr tbcreate tbident tbinfo 
	$(ERASE) tbintrig tbloadcursor tbmerge tbmod tbmove tbonlineinx
	$(ERASE) tbpriv tbread tbreorg tbrunstats tbsavept tbsel tbtemp  
	$(ERASE) tbtrig tbumqt tbunion 
	$(ERASE) tscreate 
	$(ERASE) udfcli udfsrv
	$(ERASE) udfemcli udfemsrv
	$(ERASE) $(DB2PATH)/function/udfsrv
	$(ERASE) $(DB2PATH)/function/udfemsrv
	$(ERASE) $(DB2PATH)/function/spserver


#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#		   3a -  regular samples, non-embedded SQL
#		   3b -  regular samples, embedded SQL
#		   3c -  client/server samples
#		   3d -  multi-connection samples
#		   3e -  multi-threaded samples
#############################################################################

#****************************************************************************
#		   3a -  regular samples, non-embedded SQL
#****************************************************************************

cli_info :
	$(BLDAPP) cli_info
clisnap :
	$(BLDAPP) clisnap
clisnapnew :
	$(BLDAPP) clisnapnew
dbcreate :
	$(BLDAPP) dbcreate
dbinfo :
	$(BLDAPP) dbinfo
dbupgrade :
	$(BLDAPP) dbupgrade
dbsnap :
	$(BLDAPP) dbsnap
dbsnapnew :
	$(BLDAPP) dbsnapnew
inattach :
	$(BLDAPP) inattach
ininfo :
	$(BLDAPP) ininfo
insnap :
	$(BLDAPP) insnap
insnapnew :
	$(BLDAPP) insnapnew
instart :
	$(BLDAPP) instart



#****************************************************************************
#		   3b -  regular samples, embedded SQL
#****************************************************************************

dbauth :
	$(BLDAPP) dbauth $(ALIAS) $(UID) $(PWD)
dbcfg :
	$(BLDAPP) dbcfg $(ALIAS) $(UID) $(PWD)
dbconn :
	$(BLDAPP) dbconn $(ALIAS) $(UID) $(PWD)
dbhistfile:
	$(BLDAPP) dbhistfile $(ALIAS) $(UID) $(PWD)
dbinline:
	$(BLDAPP) dbinline $(ALIAS) $(UID) $(PWD)
dbinspec:
	$(BLDAPP) dbinspec $(ALIAS) $(UID) $(PWD)
dblogconn:
	$(BLDAPP) dblogconn $(ALIAS) $(UID) $(PWD)
dbpkg :
	$(BLDAPP) dbpkg $(ALIAS) $(UID) $(PWD)
dbrestore:
	$(BLDAPP) dbrestore $(ALIAS) $(UID) $(PWD)
dbrollfwd:
	$(BLDAPP) dbrollfwd $(ALIAS) $(UID) $(PWD)
dbsample :
	$(BLDAPP) dbsample $(ALIAS) $(UID) $(PWD)
dbuse :
	$(BLDAPP) dbuse $(ALIAS) $(UID) $(PWD)
dtlob :
	$(BLDAPP) dtlob $(ALIAS) $(UID) $(PWD)
dtformat :
	$(BLDAPP) dtformat $(ALIAS) $(UID) $(PWD)
dtstruct :
	$(BLDAPP) dtstruct $(ALIAS) $(UID) $(PWD)
dtudt :
	$(BLDAPP) dtudt $(ALIAS) $(UID) $(PWD)
evm :
	$(BLDAPP) evm $(ALIAS) $(UID) $(PWD)
fnuse :
	$(BLDAPP) fnuse $(ALIAS) $(UID) $(PWD)
inauth :
	$(BLDAPP) inauth $(ALIAS) $(UID) $(PWD)
tbast :
	$(BLDAPP) tbast $(ALIAS) $(UID) $(PWD)
tbcompress :
	$(BLDAPP) tbcompress $(ALIAS) $(UID) $(PWD)
tbconstr :
	$(BLDAPP) tbconstr $(ALIAS) $(UID) $(PWD)
tbcreate :
	$(BLDAPP) tbcreate $(ALIAS) $(UID) $(PWD)
tbident :
	$(BLDAPP) tbident $(ALIAS) $(UID) $(PWD)
tbinfo :
	$(BLDAPP) tbinfo $(ALIAS) $(UID) $(PWD)
tbintrig :
	$(BLDAPP) tbintrig $(ALIAS) $(UID) $(PWD)
tbloadcursor :
	$(BLDAPP) tbloadcursor $(ALIAS) $(UID) $(PWD)
tbmerge :
	$(BLDAPP) tbmerge $(ALIAS) $(UID) $(PWD)
tbmod :
	$(BLDAPP) tbmod $(ALIAS) $(UID) $(PWD)
tbmove :
	$(BLDAPP) tbmove $(ALIAS) $(UID) $(PWD)
tbonlineinx :
	$(BLDAPP) tbonlineinx $(ALIAS) $(UID) $(PWD)
tbpriv :
	$(BLDAPP) tbpriv $(ALIAS) $(UID) $(PWD)
tbread :
	$(BLDAPP) tbread $(ALIAS) $(UID) $(PWD)
tbreorg :
	$(BLDAPP) tbreorg $(ALIAS) $(UID) $(PWD)
tbrunstats :
	$(BLDAPP) tbrunstats $(ALIAS) $(UID) $(PWD)
tbsavept :
	$(BLDAPP) tbsavept $(ALIAS) $(UID) $(PWD)
tbsel :
	tbselinit
	$(BLDAPP) tbsel $(ALIAS) $(UID) $(PWD)
tbtemp :
	$(BLDAPP) tbtemp $(ALIAS) $(UID) $(PWD)
tbtrig :
	$(BLDAPP) tbtrig $(ALIAS) $(UID) $(PWD)
tbumqt :
	$(BLDAPP) tbumqt $(ALIAS) $(UID) $(PWD)
tbunion :
	$(BLDAPP) tbunion $(ALIAS) $(UID) $(PWD)
tscreate :
	$(BLDAPP) tscreate $(ALIAS) $(UID) $(PWD)

#****************************************************************************
#		   3c - client/server samples
#****************************************************************************


spclient :
	$(BLDAPP) spclient $(ALIAS) $(UID) $(PWD)
spserver :
	$(BLDRTN) spserver $(ALIAS)
	spcat

udfcli :
	$(BLDAPP) udfcli $(ALIAS) $(UID) $(PWD)
udfsrv :
	$(BLDRTN) udfsrv

udfemcli :
	$(BLDAPP) udfemcli $(ALIAS) $(UID) $(PWD)
udfemsrv :
	$(BLDRTN) udfemsrv 


#****************************************************************************
#		   3e -  multi-threaded samples
#****************************************************************************


dbthrds :
	$(BLDMT)  dbthrds $(ALIAS) $(UID) $(PWD)
