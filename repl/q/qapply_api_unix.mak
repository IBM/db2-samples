###################################################################
# Makefile to make qapply_api.C on UNIX.                          #
# Invocation format:                                              #
#   1.To make qapply_api.C    :make -f qapply_api_unix.mak        #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in sqllib\include.                                              #
###################################################################
all: qapply_api

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

qapply_api:qapply_api.o
	$(COMP) $(LIBPATH) $(MQLIBPATH) -ldb2repl qapply_api.o -o qapply_api

qapply_api.o:qapply_api.C
	$(COMP) $(INCPATH) -c qapply_api.C
