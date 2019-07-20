# Makefile for the Sample Wrapper Discovery
#
#
# To build this wrapper discovery routine, issue the following command:
# On Windows : nmake -if makefile
# On AIX     : gnumake 
#
# Variables:	(Change as appropriate)
#
# INSTHOME:	Absolute path of the DB2 Instance (WARNING: NO WHITESPACES ALLOWED)
#           
# JAVAHOME:	Absolute path of the jdk bin directory
#

INSTHOME = "c:\Sqllib\"

JAVAHOME = "c:\sqllib\java\jdk\bin\"

#
# Steps:
# compile java class for the concrete discovery
# create the sampleSP.jar and put the java class inside
# move the sampleSP.jar to SQLLIB/tools
#

all: 
	$(JAVAHOME)javac sample.java
	$(JAVAHOME)jar cf sampleSP.jar sample.class	
	copy sampleSP.jar $(INSTHOME)tools


	