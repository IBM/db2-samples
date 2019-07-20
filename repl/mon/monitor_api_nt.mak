###################################################################
# Makefile to make monitor_api.c on Windows NT.                   #
# Invocation format:                                              #
#   1.To make monitor_api.c:   make -f monitor_api_nt.mak         #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in ex:c:\sqllib\include\ .Make sure your sqllib drive is changed#
# in the CFLAGS and LIBFLAG variable.                             #
###################################################################
all: monitor_api.exe

# Change the c: to reflect your drive for sqllib.	 
CFLAGS=/c /I"c:\sqllib\include" 
LIBFLAG= /libpath:"c:\sqllib\lib"

monitor_api.obj:monitor_api.c
	cl $(CFLAGS) monitor_api.c

monitor_api.exe:monitor_api.obj
	link $(LIBFLAG) db2repl.lib monitor_api.obj
