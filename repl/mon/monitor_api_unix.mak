###################################################################
# Makefile to make monitor_api.c on UNIX.                         #
# Invocation format:                                              #
#   1.To make monitor_api.c    :make -f monitor_api_unix.mak      #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in sqllib\include.Make sure your sqllib path is changed in the  #
# CFLAGS and LIBPATH variable.                                    #
###################################################################
all: monitor_api

# Change the xxxxx to reflect your path to sqllib
LIBPATH=-L/xxxxx/sqllib/lib
INCPATH=-I/xxxxx/sqllib/include

# Switch Compiler on different platform
# On AIX:
#  COMP=xlC
# On HP:
#  COMP=aCC
# On SUN:
#  COMP=CC
# On LINUX:
#  COMP=gcc

monitor_api:monitor_api.o
	$(COMP) $(LIBPATH) -ldb2repl monitor_api.o -o monitor_api

monitor_api.o:monitor_api.c
	$(COMP) $(INCPATH) -c monitor_api.c
