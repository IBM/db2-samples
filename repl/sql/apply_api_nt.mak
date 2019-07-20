###################################################################
# Makefile to make apply_api.c on Windows NT.                     #
# Invocation format:                                              #
#   1.To make apply_api.c:   make -f apply_api_nt.mak             #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in ex:c:\sqllib\include\ .Make sure your sqllib drive is changed#
# in the CFLAGS and LIBFLAG variable.                             #
###################################################################
all: apply_api.exe

# Change the c: to reflect your drive for sqllib.	 
CFLAGS=/c /I"c:\sqllib\include" 
LIBFLAG= /libpath:"c:\sqllib\lib"

apply_api.obj:apply_api.c
	cl $(CFLAGS) apply_api.c

apply_api.exe:apply_api.obj
	link $(LIBFLAG) db2repl.lib apply_api.obj
