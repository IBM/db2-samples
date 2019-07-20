###################################################################
# Makefile to make capture_api.c on Windows NT.                   #
# Invocation format:                                              #
#   1.To make capture_api.c:   make -f capture_api_nt.mak         #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in ex:c:\sqllib\include\ .Make sure your sqllib drive is changed#
# in the CFLAGS and LIBFLAG variable.                             #
###################################################################
all: capture_api.exe

# Change the c: to reflect your drive for sqllib.	 
CFLAGS=/c /I"c:\sqllib\include" 
LIBFLAG= /libpath:"c:\sqllib\lib"

capture_api.obj:capture_api.c
	cl $(CFLAGS) capture_api.c

capture_api.exe:capture_api.obj
	link $(LIBFLAG) db2repl.lib capture_api.obj
