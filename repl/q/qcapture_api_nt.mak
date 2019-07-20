###################################################################
# Makefile to make qcapture_api.C on Windows NT.                  #
# Invocation format:                                              #
#   1.To make qcapture_api.C:   make -f qcapture_api_nt.mak       #
#                                                                 #
# The include file "asn.h" required for the application is located#
# in ex:c:\sqllib\include\ .Make sure your sqllib drive is changed#
# in the CFLAGS and LIBFLAG variable.                             #
###################################################################
all: qcapture_api.exe

# Change the c: to reflect your drive for sqllib.	 
CFLAGS=/c /I"c:\sqllib\include" 
LIBFLAG= /libpath:"c:\sqllib\lib"

qcapture_api.obj:qcapture_api.C
	cl $(CFLAGS) qcapture_api.C

qcapture_api.exe:qcapture_api.obj
	link $(LIBFLAG) db2repl.lib qcapture_api.obj
