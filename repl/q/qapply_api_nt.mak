###################################################################
# Makefile to make qapply_api.C on Windows NT.                    #
# Invocation format:                                              #
#   1.To make qapply_api.C:   make -f qapply_api_nt.mak           #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in ex:c:\sqllib\include\ .Make sure your sqllib drive is changed#
# in the CFLAGS and LIBFLAG variable.                             #
###################################################################
all: qapply_api.exe

# Change the c: to reflect your drive for sqllib.	 
CFLAGS=/c /I"c:\sqllib\include" 
LIBFLAG= /libpath:"c:\sqllib\lib"

qapply_api.obj:qapply_api.C
	cl $(CFLAGS) qapply_api.C

qapply_api.exe:qapply_api.obj
	link $(LIBFLAG) db2repl.lib qapply_api.obj
