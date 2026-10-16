#!/bin/bash
# (c) Copyright IBM Corp. 2026 All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0

# test_integration.sh — integration tests for the Db2 Trust Procedure demo.
# shellcheck disable=SC2312  # db2 CLP exits non-zero for warnings; we check output directly
#
# Runs each demo app as a subprocess and checks its output.  No logic from
# the demo apps is duplicated here.
#
#   IT1  CLP connect via demolibapptokengen.so (TCP, $TCPDB)       → TRUSTED
#   IT2  CLP connect via IPC ($DB, trust procedure never fires)    → NOT TRUSTED
#   IT3  ./build/demoembeddedconnect  (inline C callback)          → TRUSTED
#   IT4  java DemoEmbeddedConnect                                  → TRUSTED
#   IT5  java DemoSimpleConnect + appTokenGenClassName in URL       → TRUSTED
#   IT6  java DemoSimpleConnect plain URL                          → NOT TRUSTED
#
# Prerequisites (must be completed before running):
#   Step 0  key pair generated in $HOME/trustproc_keys/
#   Step 1  trust_proc built and installed in $DB2DIR/function[/unfenced]/
#   Step 2  database objects created (DEMO.TRUST_PROC, DEMO_TRUSTCTX)
#   Step 3  apptokengen.so installed and APPTOKENGEN=ON configured for $TCPDB
#   Step 4  demoembeddedconnect binary built (build/demoembeddedconnect)
#   Step 5  DemoEmbeddedConnect.class and DemoSimpleConnect.class present in build/
#   Step 6  build/democallbackgen.jar and build/DemoSimpleConnect.class present
#
# Usage (from security/trust_procedures/signedtoken/):
#   bash test/integration/test_integration.sh [options]
#
# Options:
#   --host HOST      TCP/IP hostname    (default: localhost)
#   --port PORT      TCP/IP port        (default: 60006)
#   --tcpdb ALIAS    TCP/IP DB alias    (default: testloc)
#   --ipcdb  ALIAS   IPC DB alias       (default: testdb)
#   --authid USER    Authid             (default: boss)
#   --password PASS  Password           (required, or set IT_PASSWORD env var)
#   --db2dir DIR     Db2 install home   (default: $HOME/sqllib)
#   --db2jcc JAR     db2jcc4.jar path   (default: $DB2DIR/java/db2jcc4.jar)
#
# Exit code: 0 if all tests pass, 1 if any fail.

set -uo pipefail

# ---------------------------------------------------------------------------
# Defaults (overridden by CLI flags or environment)
# ---------------------------------------------------------------------------
IT_HOST="${IT_HOST:-localhost}"
IT_PORT="${IT_PORT:-60006}"
IT_TCPDB="${IT_TCPDB:-testloc}"
IT_IPCDB="${IT_IPCDB:-testdb}"
IT_AUTHID="${IT_AUTHID:-boss}"
IT_PASSWORD="${IT_PASSWORD:-}"
IT_DB2DIR="${IT_DB2DIR:-$HOME/sqllib}"
IT_DB2JCC="${IT_DB2JCC:-}"

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        --host)     IT_HOST="$2";     shift 2 ;;
        --port)     IT_PORT="$2";     shift 2 ;;
        --tcpdb)    IT_TCPDB="$2";    shift 2 ;;
        --ipcdb)    IT_IPCDB="$2";    shift 2 ;;
        --authid)   IT_AUTHID="$2";   shift 2 ;;
        --password) IT_PASSWORD="$2"; shift 2 ;;
        --db2dir)   IT_DB2DIR="$2";   shift 2 ;;
        --db2jcc)   IT_DB2JCC="$2";   shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

if [[ -z "$IT_PASSWORD" ]]; then
    echo "ERROR: password required. Use --password or set IT_PASSWORD." >&2
    exit 1
fi

IT_DB2JCC="${IT_DB2JCC:-$IT_DB2DIR/java/db2jcc4.jar}"
JDBC_URL="jdbc:db2://${IT_HOST}:${IT_PORT}/${IT_TCPDB}"

# ---------------------------------------------------------------------------
# Test harness
# ---------------------------------------------------------------------------
PASSED=0
FAILED=0

pass() { echo "  PASS: $1"; (( PASSED++ )); }
fail() { echo "  FAIL: $1"; (( FAILED++ )); }

check_trusted() {
    local label="$1" output="$2"
    if echo "$output" | grep -q "SUCCESS: Trusted connection established under context: DEMO_TRUSTCTX"; then
        pass "$label"
    else
        fail "$label (expected SUCCESS with DEMO_TRUSTCTX, got: $(echo "$output" | tail -1))"
    fi
}

check_not_trusted() {
    local label="$1" output="$2"
    if echo "$output" | grep -q "NOT TRUSTED: TRUSTED_CONTEXT = NULL"; then
        pass "$label"
    else
        fail "$label (expected NOT TRUSTED / NULL, got: $(echo "$output" | tail -1))"
    fi
}

# ---------------------------------------------------------------------------
# Pre-flight checks
# ---------------------------------------------------------------------------
echo "=== test_integration ==="
echo ""
echo "Host:    $IT_HOST:$IT_PORT"
echo "TCP DB:  $IT_TCPDB"
echo "IPC DB:  $IT_IPCDB"
echo "Authid:  $IT_AUTHID"
echo "DB2DIR:  $IT_DB2DIR"
echo "DB2JCC:  $IT_DB2JCC"
echo ""

PREREQ_FAIL=0
check_prereq() {
    if [[ ! -e "$1" ]]; then
        echo "  MISSING prereq: $1" >&2
        PREREQ_FAIL=1
    fi
}

check_prereq "$HOME/trustproc_keys/private.pem"
check_prereq "$HOME/trustproc_keys/public.pem"
check_prereq "$IT_DB2DIR/function/unfenced/trust_proc"
check_prereq "$IT_DB2DIR/security64/apptoken/apptokengen.so"
check_prereq "$IT_DB2JCC"
check_prereq "build/demoembeddedconnect"
check_prereq "build/DemoEmbeddedConnect.class"
check_prereq "build/DemoSimpleConnect.class"
check_prereq "build/democallbackgen.jar"

if [[ $PREREQ_FAIL -ne 0 ]]; then
    echo "" >&2
    echo "ERROR: One or more prerequisites are missing. Complete README Steps 0–6 first." >&2
    exit 1
fi

# ---------------------------------------------------------------------------
# clp_query_trusted_ctx — connect, run VALUES TRUSTED_CONTEXT, disconnect.
#
# All three statements must run in the same db2 process (connection state
# is not shared between separate db2 subprocess calls).  Uses a temp SQL
# file passed to db2 -tvf.
#
# Prints the context name, or "-" for SQL NULL.
# ---------------------------------------------------------------------------
clp_query_trusted_ctx() {
    local db="$1" user="$2" pass="$3"
    local tmpf out
    tmpf=$(mktemp /tmp/it_clp_XXXXXX.sql)
    printf 'connect to %s user %s using %s;\nVALUES TRUSTED_CONTEXT;\nconnect reset;\n' \
        "$db" "$user" "$pass" > "$tmpf"
    out=$(db2 -tvf "$tmpf" 2>&1)
    rm -f "$tmpf"
    # Value is on the line immediately after the column-header separator ("---...")
    echo "$out" | grep -A1 "^-\{10\}" | tail -1 | tr -d ' '
}

# ---------------------------------------------------------------------------
# IT1: CLP TCP connect via demolibapptokengen.so — expected: TRUSTED
# ---------------------------------------------------------------------------
echo "[ IT1: CLP TCP connect via demolibapptokengen.so ]"
CTX=$(clp_query_trusted_ctx "$IT_TCPDB" "$IT_AUTHID" "$IT_PASSWORD")
if [[ "$CTX" == "DEMO_TRUSTCTX" ]]; then
    pass "CLP TRUSTED_CONTEXT = DEMO_TRUSTCTX"
else
    fail "CLP TRUSTED_CONTEXT expected DEMO_TRUSTCTX, got: '$CTX'"
fi

# ---------------------------------------------------------------------------
# IT2: CLP IPC connect — trust procedure never fires — expected: NOT TRUSTED
#
# README: "The trust procedure fires on TCP/IP connects only —
#          IPC (db2 connect to \$DB) bypasses it by design."
# ---------------------------------------------------------------------------
echo ""
echo "[ IT2: CLP IPC connect — trust procedure bypassed ]"
CTX=$(clp_query_trusted_ctx "$IT_IPCDB" "$IT_AUTHID" "$IT_PASSWORD")
# CLP renders SQL NULL as a single dash padded with spaces; tr -d ' ' gives "-"
if [[ "$CTX" == "-" ]]; then
    pass "CLP IPC TRUSTED_CONTEXT = NULL (trust procedure bypassed)"
else
    fail "CLP IPC TRUSTED_CONTEXT expected NULL (-), got: '$CTX'"
fi

# ---------------------------------------------------------------------------
# IT3: ./demoembeddedconnect — expected: TRUSTED
#
# APPTOKENGEN is disabled for the alias so the injected .so does not
# intercept the connection before the inline callback can run.
# ---------------------------------------------------------------------------
echo ""
echo "[ IT3: ./build/demoembeddedconnect (inline SQL_ATTR_APP_TOKEN_GEN_CALLBACK) ]"
db2 "UPDATE CLI CFG FOR SECTION $IT_TCPDB USING APPTOKENGEN OFF" > /dev/null 2>&1
OUT=$(./build/demoembeddedconnect "$IT_TCPDB" "$IT_AUTHID" "$IT_PASSWORD" 2>&1)
db2 "UPDATE CLI CFG FOR SECTION $IT_TCPDB USING APPTOKENGEN ON"  > /dev/null 2>&1
check_trusted "demoembeddedconnect → DEMO_TRUSTCTX" "$OUT"

# ---------------------------------------------------------------------------
# IT4: java DemoEmbeddedConnect — expected: TRUSTED
# ---------------------------------------------------------------------------
echo ""
echo "[ IT4: java DemoEmbeddedConnect (inline appTokenGen property) ]"
OUT=$(java -cp "build:$IT_DB2JCC" DemoEmbeddedConnect \
    "$JDBC_URL" "$IT_AUTHID" "$IT_PASSWORD" 2>&1)
check_trusted "DemoEmbeddedConnect → DEMO_TRUSTCTX" "$OUT"

# ---------------------------------------------------------------------------
# IT5: java DemoSimpleConnect + appTokenGenClassName in URL — expected: TRUSTED
# ---------------------------------------------------------------------------
echo ""
echo "[ IT5: java DemoSimpleConnect (appTokenGenClassName=DemoCallbackGen in URL) ]"
OUT=$(java -cp "build:$IT_DB2JCC:build/democallbackgen.jar" DemoSimpleConnect \
    "${JDBC_URL}:appTokenGenClassName=DemoCallbackGen;" \
    "$IT_AUTHID" "$IT_PASSWORD" 2>&1)
check_trusted "DemoSimpleConnect (trusted URL) → DEMO_TRUSTCTX" "$OUT"

# ---------------------------------------------------------------------------
# IT6: java DemoSimpleConnect plain URL — expected: NOT TRUSTED
# ---------------------------------------------------------------------------
echo ""
echo "[ IT6: java DemoSimpleConnect (plain URL, no apptoken) ]"
OUT=$(java -cp "build:$IT_DB2JCC:build/democallbackgen.jar" DemoSimpleConnect \
    "$JDBC_URL" "$IT_AUTHID" "$IT_PASSWORD" 2>&1)
check_not_trusted "DemoSimpleConnect (plain URL) → NOT TRUSTED" "$OUT"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo ""
echo "---"
echo "Results: $PASSED passed, $FAILED failed"
[[ $FAILED -eq 0 ]]
