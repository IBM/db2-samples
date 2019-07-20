# NOTE:
# 1. This is a gnumake makefile.
# 2. Use a g++ version 3.2 or newer when building the wrapper
#

#
# Location of UDB instance.  Change as appropriate.
#
INSTHOME = /home/${DB2INSTANCE}

#
# Wrapper library definitions.  Change these as appropriate
#

# Object files that make up the sample wrapper
UNFENCED_WRAPPER_OBJ_FILES = sample_wrapper.o \
                             sample_server.o \
                             sample_user.o \
                             sample_nickname.o \
                             sample_utilities.o

FENCED_WRAPPER_OBJ_FILES   = sample_connection.o \
                             sample_operation.o \
                             sample_fenced_wrapper.o \
                             sample_fenced_server.o \
                             sample_fenced_nickname.o \
                             sample_utilities.o

# Name of wrapper library to be created. Change name as appropriate
WRAPPER_ARCHIVE_NAME          = libsample

# These macros shouldn't be changed
WRAPPER_ARCHIVE_LIB          = $(WRAPPER_ARCHIVE_NAME).$(SHARED_LIB_EXT)
FENCED_WRAPPER_ARCHIVE_LIB   = $(WRAPPER_ARCHIVE_NAME)F.$(SHARED_LIB_EXT)
UNFENCED_WRAPPER_ARCHIVE_LIB = $(WRAPPER_ARCHIVE_NAME)U.$(SHARED_LIB_EXT)

# 
# Tools and Macros. These are platform specific.
# The following is for Linux

SHARED_LIB_EXT               = so
CCC = g++
CCC_LIB = g++
COPTS = -c -D SQLLinux -D SQLUNIX -g -mpentiumpro -fcheck-new -D_XOPEN_SOURCE=500 -D_BSD_SOURCE -DNO_64K_MSGS -D__NO_MATH_INLINES -DSIGPRE=SIGURG -D__STDC_LIMIT_MACROS -D_LARGEFILE_SOURCE -D_LARGEFILE64_SOURCE -D_FILE_OFFSET_BITS=64 -D_REENTRANT -fpic
LDFLAGS =  -shared -g -lpthread -lm -lc


#
# UDB definitions.  These should not need to be changed.
#

# Location of the wrapper include files and public include files
UDB_INCLUDE_DIR = ${INSTHOME}/sqllib/include


### Start 64-bit settings ###

# Use the following if building on a 64-bit system

# Location of the DB2 UDB libraries
UDB_LIB_DIR = ${INSTHOME}/sqllib/lib64

### End 64-bit settings ###


### Start 32-bit settings ###

# Use the following if building on a 32-bit system

# Location of the DB2 UDB libraries
# UDB_LIB_DIR = ${INSTHOME}/sqllib/lib32

# Enforce INT32 to INT mapping
# UDB_FLAGS = -DDB2_FORCE_INT32_TYPES_TO_INT

#### End 32-bit settings ###


all: ${UNFENCED_WRAPPER_ARCHIVE_LIB}  ${FENCED_WRAPPER_ARCHIVE_LIB}  move

$(UNFENCED_WRAPPER_ARCHIVE_LIB): $(UNFENCED_WRAPPER_OBJ_FILES)
	$(CCC_LIB) \
                -eUnfencedWrapper_Hook \
                $(filter %.o, $^) \
                ${LDFLAGS} \
                -o $@
        
${FENCED_WRAPPER_ARCHIVE_LIB}: ${FENCED_WRAPPER_OBJ_FILES} ${UDB_EXPORTS}
	${CCC_LIB} \
                -eFencedWrapper_Hook \
                $(filter %.o, $^) \
                $(LDFLAGS) \
                -o $@
        
move:
	 -rm -f ${UDB_LIB_DIR}/${UNFENCED_WRAPPER_ARCHIVE_LIB}
	 -rm -f ${UDB_LIB_DIR}/${FENCED_WRAPPER_ARCHIVE_LIB}
	 cp ${UNFENCED_WRAPPER_ARCHIVE_LIB} ${UDB_LIB_DIR}    
	 cp ${FENCED_WRAPPER_ARCHIVE_LIB} ${UDB_LIB_DIR}    
	 cp ${UDB_LIB_DIR}/libdb2sqqgtop.$(SHARED_LIB_EXT) ${UDB_LIB_DIR}/$(WRAPPER_ARCHIVE_LIB)

#
# Pattern rules
#
%.o : %.C 
	${CCC} ${COPTS} ${UDB_FLAGS} -I${UDB_INCLUDE_DIR} -c $<

#
# Useful targets
#
depend: $(wildcard *.u)
	-cat $^ /dev/null | egrep -v "/usr/" > $@

clean:
	rm -f *.o *.u *.map depend ${UNFENCED_WRAPPER_ARCHIVE_LIB}  ${FENCED_WRAPPER_ARCHIVE_LIB}

include depend
