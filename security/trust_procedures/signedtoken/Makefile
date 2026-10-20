#############################################################################
# (c) Copyright IBM Corp. 2026 All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#############################################################################
# Makefile — Trust Procedure Demo
#
# Wraps bldapp, bldrtn, and javac/jar into named targets so each component
# can be built with a single command.  All compiled output lands in build/.
#
# Configuration (override on the command line or via environment):
#
#   DB2DIR   — Db2 install / instance home  (default: ~/sqllib)
#   DB2JCC   — db2jcc4.jar path             (default: $(DB2DIR)/java/db2jcc4.jar)
#   DB       — Database alias for IPC connect (needed for trust_proc bind step)
#
# Variables for running demos and integration tests:
#
#   HOST     — TCP/IP hostname
#   PORT     — TCP/IP port
#   TCPDB    — Database alias for TCP/IP connect
#   AUTHID   — Connecting user
#   PASSWORD — Password for AUTHID
#
# Common targets:
#
#   make all              Build everything (C + Java)
#   make trust_proc       Build + install the trust procedure (Step 1)
#   make apptoken_lib     Build the injected C .so             (Step 3)
#   make demoembeddedconnect  Build the inline C callback app  (Step 4)
#   make java_embedded    Build DemoEmbeddedConnect.class      (Step 5)
#   make democallbackgen  Build democallbackgen.jar            (Step 6)
#   make java_simple      Build DemoSimpleConnect.class        (Step 6)
#   make c_unit_test      Build + run C unit tests
#   make java_unit_test   Build + run Java unit tests
#   make integration_test Run integration tests (live DB required)
#   make clean            Remove build/
#############################################################################

DB2DIR  ?= $(HOME)/sqllib
DB2JCC  ?= $(DB2DIR)/java/db2jcc4.jar

JAVAC = javac
JAR   = jar
JAVA  = java

JAVA_SRC   = src/client/java
JAVA_STUBS = $(JAVA_SRC)/stubs

# Stubs are compiled to build/stubs/ so they never appear on the runtime
# classpath (build/).  The real DB2AppTokenGen comes from db2jcc4.jar at runtime.
# db2jcc4.jar ships AppTokenGenParam as a separate class file without the
# InnerClasses attribute, so javac cannot resolve "DB2AppTokenGen.AppTokenGenParam"
# from the jar alone.  The pre-compiled stub provides the missing inner-class
# declaration for the compiler.
# Unit tests use stubs first on -cp so TestParam can subclass stub AppTokenGenParam.
STUBS_DIR = build/stubs
STUBS_CLASS = $(STUBS_DIR)/com/ibm/db2/jcc/DB2AppTokenGen.class

# Javac flags shared across all targets
JAVAC_FLAGS      = -cp $(DB2JCC) -d build
# Demo builds: stubs first so AppTokenGenParam inner-class declaration is visible,
# then real driver for everything else.  Stub classes written to build/com/ are
# removed immediately after compilation (rm -rf build/com in each recipe).
JAVAC_STUB_FLAGS = -cp $(STUBS_DIR):$(DB2JCC) -d build

# Source lists
UTIL_SRC     = $(JAVA_SRC)/UtilAppTokenSigner.java
CALLBACK_SRC = $(JAVA_SRC)/DemoCallbackGen.java
EMBEDDED_SRC = $(JAVA_SRC)/DemoEmbeddedConnect.java
SIMPLE_SRC   = $(JAVA_SRC)/DemoSimpleConnect.java
TEST_SRC     = test/java/TestTokenGen.java

# Build output sentinels (make tracks these file timestamps)
UTIL_CLASS     = build/UtilAppTokenSigner.class
CALLBACK_CLASS = build/DemoCallbackGen.class
EMBEDDED_CLASS = build/DemoEmbeddedConnect.class
SIMPLE_CLASS   = build/DemoSimpleConnect.class
TEST_CLASS     = build/test/TestTokenGen.class
CALLBACK_JAR   = build/democallbackgen.jar

.PHONY: all clean \
        trust_proc apptoken_lib demoembeddedconnect \
        java_embedded democallbackgen java_simple \
        c_unit_test java_unit_test integration_test

# ---------------------------------------------------------------------------
# Default target
# ---------------------------------------------------------------------------
all: trust_proc apptoken_lib demoembeddedconnect \
     java_embedded democallbackgen java_simple

# ---------------------------------------------------------------------------
# Stubs — compile-time only, output to build/stubs/ (never on runtime classpath)
# ---------------------------------------------------------------------------
$(STUBS_DIR)/com/ibm/db2/jcc/DB2AppTokenGen.class: $(JAVA_STUBS)/com/ibm/db2/jcc/DB2AppTokenGen.java
	mkdir -p $(STUBS_DIR)
	$(JAVAC) -d $(STUBS_DIR) $<

# ---------------------------------------------------------------------------
# Step 1 — Trust procedure (server-side stored procedure)
# ---------------------------------------------------------------------------
trust_proc: build/trust_proc

build/trust_proc: src/server/trust_proc.sqc
	./bldrtn trust_proc $(DB) -l "-lssl -lcrypto" -u

# ---------------------------------------------------------------------------
# Step 3 — Injected C apptoken shared library
# ---------------------------------------------------------------------------
apptoken_lib: build/demolibapptokengen

build/demolibapptokengen: src/client/c/demolibapptokengen.c \
                           src/client/c/utilapptokensigner.c \
                           src/client/c/utilapptokensigner.h
	./bldrtn demolibapptokengen "" \
	    -s "src/client/c/utilapptokensigner.c" \
	    -l "-lssl -lcrypto"

# ---------------------------------------------------------------------------
# Step 4 — Inline C callback demo application
# ---------------------------------------------------------------------------
demoembeddedconnect: build/demoembeddedconnect

build/demoembeddedconnect: src/client/c/demoembeddedconnect.c \
                            src/client/c/utilapptokensigner.c \
                            src/client/c/utilapptokensigner.h
	./bldapp demoembeddedconnect "" "" "" \
	    -s "src/client/c/utilapptokensigner.c" \
	    -l "-lssl -lcrypto"

# ---------------------------------------------------------------------------
# Step 5 — Self-contained Java demo (inline callback)
# ---------------------------------------------------------------------------
java_embedded: $(EMBEDDED_CLASS)

$(EMBEDDED_CLASS): $(UTIL_SRC) $(EMBEDDED_SRC) $(STUBS_CLASS)
	mkdir -p build
	$(JAVAC) $(JAVAC_STUB_FLAGS) $(UTIL_SRC) $(EMBEDDED_SRC)
	rm -rf build/com

# ---------------------------------------------------------------------------
# Step 6 — Zero-source-change Java demo (jar + simple app)
# ---------------------------------------------------------------------------
democallbackgen: $(CALLBACK_JAR)

$(CALLBACK_JAR): $(UTIL_SRC) $(CALLBACK_SRC) $(STUBS_CLASS)
	mkdir -p build
	$(JAVAC) $(JAVAC_STUB_FLAGS) $(UTIL_SRC) $(CALLBACK_SRC)
	rm -rf build/com
	$(JAR) cf $@ -C build DemoCallbackGen.class -C build UtilAppTokenSigner.class

java_simple: $(SIMPLE_CLASS)

$(SIMPLE_CLASS): $(SIMPLE_SRC)
	mkdir -p build
	$(JAVAC) $(JAVAC_FLAGS) $<

# ---------------------------------------------------------------------------
# C unit tests (no database required)
# ---------------------------------------------------------------------------
c_unit_test: build/test_apptokengen
	./build/test_apptokengen

build/test_apptokengen: test/c/test_apptokengen.c \
                         src/client/c/utilapptokensigner.c \
                         src/client/c/utilapptokensigner.h
	./bldapp test_apptokengen "" "" "" \
	    -s "src/client/c/utilapptokensigner.c" \
	    -l "-lssl -lcrypto"

# ---------------------------------------------------------------------------
# Java unit tests (no database required)
#
# Unit tests compile and run against the stub DB2AppTokenGen (no driver needed).
# The stub is on the classpath ahead of db2jcc4.jar so TestParam can subclass
# AppTokenGenParam without needing the real driver's package-private fields.
# ---------------------------------------------------------------------------
java_unit_test: $(TEST_CLASS)
	$(JAVA) -cp build/stubs:build/test:$(DB2JCC) TestTokenGen

$(TEST_CLASS): $(UTIL_SRC) $(CALLBACK_SRC) $(EMBEDDED_SRC) $(TEST_SRC) \
               $(STUBS_DIR)/com/ibm/db2/jcc/DB2AppTokenGen.class
	mkdir -p build/test
	$(JAVAC) -cp $(STUBS_DIR):$(DB2JCC) -d build/test \
	    $(UTIL_SRC) $(CALLBACK_SRC) $(EMBEDDED_SRC) $(TEST_SRC)

# ---------------------------------------------------------------------------
# Integration tests (live database required — complete Steps 0-6 first)
# ---------------------------------------------------------------------------
# The password is handed to the script via the IT_PASSWORD environment variable
# (from $$PASSWORD) so it is never echoed in make output or logs.
integration_test:
	IT_PASSWORD="$$PASSWORD" bash test/integration/test_integration.sh \
	    --host $(HOST) --port $(PORT) \
	    --tcpdb $(TCPDB) --ipcdb $(DB) \
	    --authid $(AUTHID)

# ---------------------------------------------------------------------------
# Clean
# ---------------------------------------------------------------------------
clean:
	rm -rf build
