/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
/**
 * DemoCallbackGen — standalone apptoken generator for the Db2 Trust Procedure demo.
 *
 * This is the Java equivalent of demolibapptokengen.so (Step 3).  It is compiled
 * into a separate jar (democallbackgen.jar) and loaded by the Db2 JDBC driver at
 * connection time — the connecting application (DemoSimpleConnect.java) requires no
 * modification of any kind.
 *
 * Token construction is delegated to UtilAppTokenSigner.buildToken().  See that class
 * for the token format and key-file locations.
 *
 * How the driver loads this class:
 *   1. Reads "appTokenGenClassName" from the JDBC URL or Properties
 *   2. Class.forName(name, true, Thread.currentThread().getContextClassLoader())
 *   3. DB2AppTokenGen.class.isAssignableFrom(loadedClass)
 *   4. loadedClass.newInstance()  — no-arg constructor required
 *   5. Casts to DB2AppTokenGen and calls getAppToken() during the auth handshake
 *
 * Build (from signedtoken/):
 *   make democallbackgen DB2JCC=$DB2JCC
 *
 * Run (via DemoSimpleConnect — no source changes to that application):
 *   java -cp build:$DB2JCC:build/democallbackgen.jar DemoSimpleConnect \
 *       "jdbc:db2://host:port/db:appTokenGenClassName=DemoCallbackGen;" \
 *       <user> <password>
 */
public class DemoCallbackGen implements com.ibm.db2.jcc.DB2AppTokenGen {

    /** No-arg constructor required by Class.newInstance(). */
    public DemoCallbackGen() {}

    @Override
    public int getAppToken(int versionNumber, Object userData,
                           com.ibm.db2.jcc.DB2AppTokenGen.AppTokenGenParam nonce,
                           com.ibm.db2.jcc.DB2AppTokenGen.AppTokenGenParam apptoken) {

        // If the server sent no nonce, send an empty token.
        // The trust procedure will deny trust but the connection is not failed.
        if (nonce == null || nonce.getLength() <= 0) {
            apptoken.setData(new byte[0]);
            apptoken.setLength(0);
            return 0;
        }

        byte[] token = UtilAppTokenSigner.buildToken(nonce.getData(), nonce.getLength());
        if (token == null) {
            apptoken.setData(new byte[0]);
            apptoken.setLength(0);
            return 0;
        }

        apptoken.setData(token);
        apptoken.setLength(token.length);
        return 0;
    }
}
