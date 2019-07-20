###------------------------------------------------------------------------
### THIS IS AN OBSOLETE MAKEFILE FOR THE AIX PLATFORM
###
###  ==> To build the "runGseDemo" program for all Unix platforms you now
###      run the shell script:  bldDemo.sh
###
###------------------------------------------------------------------------

#  (C) COPYRIGHT International Business Machines Corp. 1996, 2002
#  All Rights Reserved.
#
#  US Government Users Restricted Rights - Use, duplication or
#  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.


# Makefile for DB2 Universal Database Version 81
# SQL procedure sample programs -- AIX operating system
                         

# Enter one of the following commands 
#
#   make <app_name>        - Builds the program designated by <app_name>
#
#   make all               - Builds the all the supplied sample programs
#
#   make clean             - Erases intermediate files
#   make cleanall          - Erases all files produced in the build process,
#                             except the original source files

# The makefile contains the following sections:
#    1 -- COMPILERS + VARIABLES
#    2 -- MAKE CATEGORIES
#    3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES


##################################################################################
#                  1 -- COMPILERS + VARIABLES                                     
##################################################################################

# This file assumes the DB2 instance path is defined by the variable HOME.
# It also assumes DB2 is installed under the DB2 instance.
# If these statements are not correct, update the variable DB2PATH. 
DB2PATH = $(HOME)/sqllib

# Use the xlc compiler
CC= xlc
# Use xlc_r for multi-threaded programs
CM=xlc_r
# For multi-threaded programs on AIX 4.3 or later, use:
# CM=xlc_r7

DB2INSTANCEPATH = /home/$(DB2INSTANCE)
CFLAGS= -I$(DB2INSTANCEPATH)/sqllib/include -g -qcpluscmt
LIBES= -L$(DB2INSTANCEPATH)/sqllib/lib -ldb2 -lc

# The required libraries 
LIBS= -L$(DB2PATH)/lib -ldb2 
LIBS1= -L$(DB2PATH)/lib -ldb2 -ldb2apie

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
#              2a - make all(= all samples)
#              2b - make clean
#              2a - make cleanall
#############################################################################


#****************************************************************************
#                  2a - make all
#****************************************************************************

all : \
	runGseDemo

#****************************************************************************
#                  2b - make clean
#****************************************************************************

 
clean : \
	cleangen 

cleangen :
	$(ERASE) *.o *.map message.*

#****************************************************************************
#                  2c - make cleanall
#****************************************************************************

cleanall : \
	clean
	$(ERASE) runGseDemo

#############################################################################
#  3 -- COMMANDS TO MAKE INDIVIDUAL SAMPLES
#                  3a -  Spatial extender sample
#############################################################################

#****************************************************************************
#                 3a - Spatial extender samples
#****************************************************************************

###------------------------------------------------------------------------
### THIS IS AN OBSOLETE MAKEFILE FOR AIX 32bit INSTANCES 
###
###  ==> To build the "runGseDemo" program for all Unix platforms you now
###      run the shell script:  bldDemo.sh
###
###------------------------------------------------------------------------
# samputil contains common utility functions
samputil.o : samputil.c samputil.h

runGseDemo : runGseDemo.o samputil.o ;
	echo "==>"
	echo "This makefile is obsolete.  Please use bldDemo.sh instead."
	echo "==>"
	xlc -o runGseDemo runGseDemo.o samputil.o $(LIBES) -bloadmap:runGseDemo.map
