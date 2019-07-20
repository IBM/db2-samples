###################################################################
# Makefile to make qcapture_api.C on UNIX.                        #
# Invocation format:                                              #
#   1.To make qcapture_api.C    :make -f qcapture_api_unix.mak    #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in sqllib\include.                                              #
###################################################################
all: qcapture_api

# Change the xxxxx to reflect your path to sqllib
LIBPATH=-Lxxxxx/sqllib/lib
INCPATH=-Ixxxxx/sqllib/include
# Path for DLLs
# Change the xxxxx to reflect your path to sqllib
# Change the yyyyy to reflect your path to MQ lib
# For gcc:
# MQLIBPATH=-Wl,-rpath,yyyyyy/lib
# For xlC:
# MQLIBPATH=-blibpath:xxxxx/sqllib/lib

# Switch Compiler on different platform
# On AIX:
# COMP=xlC
# On HP:
#  COMP=aCC
# On SUN:
#  COMP=CC
# On LINUX:
#  COMP=gcc

qcapture_api:qcapture_api.o
	$(COMP) $(LIBPATH) $(MQLIBPATH) -ldb2repl qcapture_api.o -o qcapture_api

qcapture_api.o:qcapture_api.C
	$(COMP) $(INCPATH) -c qcapture_api.C
