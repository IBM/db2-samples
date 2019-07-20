###################################################################
# Makefile to make apply_api.c on UNIX.                         #
# Invocation format:                                              #
#   1.To make apply_api.c    :make -f apply_api_unix.mak      #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in sqllib\include.Make sure your sqllib path is changed in the  #
# CFLAGS and LIBPATH variable.                                    #
###################################################################
all: apply_api

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

apply_api:apply_api.o
	$(COMP) $(LIBPATH) -ldb2repl apply_api.o -o apply_api

apply_api.o:apply_api.c
	$(COMP) $(INCPATH) -c apply_api.c
