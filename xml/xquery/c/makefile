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
# MAKEFILE for XML XQUERY C samples on UNIX 
#
# Enter one of the following commands 
#
#   make <app_name>	   - Builds the program designated by <app_name>
#   make all		   - Builds all supplied sample programs
#   make srv		   - Builds sample that run on the server
#			     (stored procedure)
#   make all_client	   - Builds all client samples (all programs in the
#			      call_rtn and client_run categories)
#   make call_rtn	   - Builds  client programs that call stored procedure 
#   make client_run	   - Builds all programs that run completely on the
#			      client (not ones that call stored procedure) 
#   make clean		   - Erases intermediate files
#   make cleanall	   - Erases all files produced in the build process
#			     except the original source files
#
# The makefile contains the following sections:
#    1 -- VARIABLES
#    2 -- MAKE CATEGORIES
#    3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#
#
##############################################################################
#		   1 --  VARIABLES				       
##############################################################################

# This file assumes the DB2 instance path is defined by the variable HOME.
# It also assumes DB2 is installed under the DB2 instance.
# If these statements are not correct, update the variable DB2PATH.
DB2PATH = $(HOME)/sqllib

BLDAPP=bldapp
BLDRTN=bldrtn

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
#	       2a - make all (srv + all_client)
#	       2b - make srv
#	       2c - make all_client (call_rtn + client_run)
#	       2d - make call_rtn
#	       2e - make client_run
#	       2f - make clean
#	       2g - make cleanall
#############################################################################

#****************************************************************************
#		   2a - make all
#****************************************************************************

all : \
	srv \
	all_client

#****************************************************************************
#		   2b - make srv
#****************************************************************************

srv : \
     xquery_xmlproc
     
#****************************************************************************
#		   2c - make all_client (call_rtn + client_run)
#****************************************************************************

all_client : \
	  call_rtn \
          client_run

#****************************************************************************
#                  2d - make call_rtn
#****************************************************************************

call_rtn : \
	client_xquery_xmlproc

#****************************************************************************
#		   2e - make client_run
#****************************************************************************

client_run : \
            xpath flwor sqlxquery xquery  xqueryparam xupdate

#****************************************************************************
#		   2f - make clean
#****************************************************************************

clean : 
	$(ERASE) *.o
	$(ERASE) *.DEL *.TXT *.MSG
	$(ERASE) xpath.c flwor.c sqlxquery.c xquery.c xquery_xmlproc_client.c \
                 xquery_xmlproc.c utilemb.c xqueryparam.c xupdate.c

#****************************************************************************
#		   2g - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) *.bnd
	$(ERASE) xpath flwor sqlxquery xquery client_xquery_xmlproc xquery_xmlproc 
	$(ERASE) xqueryparam xupdate
	$(ERASE) $(DB2PATH)/function/xquery_xmlproc

#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#		   3a -  regular samples, embedded SQL
#		   3b -  client/server samples
#############################################################################

#****************************************************************************
#		   3a -  regular samples, embedded SQL
#****************************************************************************

xpath :
	$(BLDAPP) xpath $(ALIAS) $(UID) $(PWD) 
flwor :
	$(BLDAPP) flwor $(ALIAS) $(UID) $(PWD) 
sqlxquery :
	$(BLDAPP) sqlxquery $(ALIAS) $(UID) $(PWD) 
xquery :
	$(BLDAPP) xquery $(ALIAS) $(UID) $(PWD) 
xqueryparam :
	$(BLDAPP) xqueryparam $(ALIAS) $(UID) $(PWD)
xupdate :
	$(BLDAPP) xupdate $(ALIAS) $(UID) $(PWD)


#****************************************************************************
#		   3b - client/server samples   
#****************************************************************************

client_xquery_xmlproc :
	$(BLDAPP) client_xquery_xmlproc
xquery_xmlproc :
	$(BLDRTN) xquery_xmlproc
	spcat_xquery
