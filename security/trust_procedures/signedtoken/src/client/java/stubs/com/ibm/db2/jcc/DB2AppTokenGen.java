/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
package com.ibm.db2.jcc;

/**
 * Compile-time stub for com.ibm.db2.jcc.DB2AppTokenGen.
 *
 * PURPOSE
 *   db2jcc4.jar ships DB2AppTokenGen$AppTokenGenParam as a separate class file
 *   but does not declare it in the InnerClasses attribute of DB2AppTokenGen.class.
 *   This missing metadata means javac cannot resolve "DB2AppTokenGen.AppTokenGenParam"
 *   as a nested type when compiling against the real jar.  This stub re-declares
 *   the interface with a proper inner class declaration so that the compiler
 *   accepts references to AppTokenGenParam in source code.
 *
 * USAGE
 *   Pre-compile this stub to a separate directory, then put that directory on
 *   the javac classpath BEFORE db2jcc4.jar:
 *     javac -d build/stubs stubs/com/ibm/db2/jcc/DB2AppTokenGen.java
 *     javac -cp build/stubs:db2jcc4.jar -d build YourAppTokenGen.java
 *
 *   The Makefile handles this automatically — use the make targets rather than
 *   invoking javac directly.
 *
 *   WARNING — do NOT use "-sourcepath stubs -d build": that causes javac to
 *   write the compiled stub classes into build/, which will shadow the real
 *   db2jcc4.jar classes at runtime and break the nonce passing mechanism.
 *
 * IMPORTANT — DO NOT DEPLOY
 *   Never package the compiled stub class into your application jar and never
 *   include build/stubs/ on the runtime classpath.  At runtime, db2jcc4.jar
 *   must provide the real DB2AppTokenGen and AppTokenGenParam classes.
 *
 * METHOD BODIES
 *   The method bodies below are placeholders that satisfy the compiler.  They
 *   are never executed — at runtime the real AppTokenGenParam from db2jcc4.jar
 *   is used, which has its own correct implementations.
 */
public interface DB2AppTokenGen {

    /**
     * Carries the nonce (input) and the generated token (output) between the
     * JDBC driver and the getAppToken() implementation.
     *
     * As input (nonce parameter):
     *   getData()   — returns the raw nonce bytes sent by the server
     *   getLength() — returns the number of significant bytes in getData()
     *
     * As output (apptoken parameter):
     *   setData(byte[]) — supply the generated token bytes
     *   setLength(int)  — supply the token byte count
     */
    class AppTokenGenParam {
        public byte[] getData()          { return null; }  // stub body — never called at runtime
        public int    getLength()        { return 0; }     // stub body — never called at runtime
        public void   setData(byte[] d)  {}                // stub body — never called at runtime
        public void   setLength(int l)   {}                // stub body — never called at runtime
    }

    /**
     * Called by the Db2 JDBC driver during the authentication handshake.
     * Implementations must build the apptoken from the nonce and write it
     * into the apptoken output parameter.  Return 0 on success.
     *
     * See DemoCallbackGen.java for a full worked example.
     */
    int getAppToken(int versionNumber, Object userData,
                    AppTokenGenParam nonce,
                    AppTokenGenParam apptoken);
}
