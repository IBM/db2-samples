##############################################################################
# Licensed Materials - Property of IBM
#
# Governed under the terms of the International
# License Agreement for Non-Warranted Sample Code.
#
# (C) COPYRIGHT International Business Machines Corp. 2004
# All Rights Reserved.
#
# US Government Users Restricted Rights - Use, duplication or
# disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
##############################################################################
#
# MAKEFILE for security samples on Linux
#
# Enter one of the following commands 
#
#   make <plugin>	   - Builds the plugin designated by <plugin>
#   make all		   - Builds all supplied sample plugins
#   make clean		   - Erases all intermediate files
#   make cleanall	   - Erases all files produced in the build process
#			     except the original source files
#
# The makefile contains the following sections:
#    1 -- VARIABLES
#    2 -- MAKE CATEGORIES
#    3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#
#
###########################################################################
#		   1 -- VARIABLES					  #
###########################################################################

# This file assumes the DB2 instance path is defined by the variable HOME.
# It also assumes DB2 is installed under the DB2 instance.
# If these statements are not correct, update the variable DB2PATH. 
DB2PATH = $(HOME)/sqllib

# shell script used to compile samples
BLDPLUGIN = bldplugin

# The combined, gssapi_simple and group_file samples all obtain their
# information about users and group from text files.  These variables
# define the location of those files.  For simplicity, the two
# authentication examples default to the same file.
COMBINED_USERFILE = $(DB2PATH)/USERS
GSSAPI_USERFILE = $(DB2PATH)/USERS
GROUP_FILE = $(DB2PATH)/GROUPS

# Plugin suffix for Linux
LIBSUFF = so

ERASE = rm -f

#############################################################################
#  2 -- MAKE CATEGORIES
#############################################################################

all : combined.$(LIBSUFF) gssapi_simple.$(LIBSUFF) group_file.$(LIBSUFF)

clean : 
	$(ERASE) *.o

cleanall :
	$(ERASE) *.o
	$(ERASE) combined.$(LIBSUFF) gssapi_simple.$(LIBSUFF) group_file.$(LIBSUFF)


#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#############################################################################

combined: combined.$(LIBSUFF)

combined.$(LIBSUFF): combined.c
	bldplugin combined -DUSER_FILENAME="\"$(COMBINED_USERFILE)\"" $(PLUGIN_CFLAGS)

gssapi_simple: gssapi_simple.$(LIBSUFF)

gssapi_simple.$(LIBSUFF): gssapi_simple.c
	bldplugin gssapi_simple -DUSER_FILENAME="\"$(GSSAPI_USERFILE)\"" $(PLUGIN_CFLAGS)

group_file: group_file.$(LIBSUFF)

group_file.$(LIBSUFF): group_file.c
	bldplugin group_file -DGROUP_FILENAME="\"$(GROUP_FILE)\"" $(PLUGIN_CFLAGS)
