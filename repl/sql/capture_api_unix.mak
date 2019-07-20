###################################################################
# Makefile to make capture_api.c on UNIX.                         #
# Invocation format:                                              #
#   1.To make capture_api.c    :make -f capture_api_unix.mak      #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in sqllib\include.Make sure your sqllib path is changed in the  #
# CFLAGS and LIBPATH variable.                                    #
###################################################################
all: capture_api

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

capture_api:capture_api.o
	$(COMP) $(LIBPATH) -ldb2repl capture_api.o -o capture_api

capture_api.o:capture_api.c
	$(COMP) $(INCPATH) -c capture_api.c
