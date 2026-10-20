/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.Properties;

import com.ibm.db2.jcc.DB2AppTokenGen;

/**
 * DemoEmbeddedConnect — self-contained demonstration of the Db2 Trust Procedure feature.
 *
 * Mirrors DemoSimpleConnect exactly, except that TrustCallbackImpl is registered
 * programmatically via the "appTokenGen" Properties key.  The only source-level
 * difference between the two programs is the addition of that one property.
 *
 * Token construction is delegated to UtilAppTokenSigner.buildToken().  See that class
 * for the token format and key-file locations.
 *
 * Compare with DemoSimpleConnect.java + DemoCallbackGen.java, where the callback is
 * supplied entirely from outside via the JDBC URL — no source changes to the app.
 *
 * Build (from signedtoken/):
 *   make java_embedded DB2JCC=$DB2JCC
 *
 * Run:
 *   java -cp build:$DB2JCC DemoEmbeddedConnect \
 *       "jdbc:db2://host:port/db" <user> <password>
 */
public class DemoEmbeddedConnect {

    // -----------------------------------------------------------------------
    // Apptoken callback implementation
    // -----------------------------------------------------------------------

    /**
     * TrustCallbackImpl is the inline apptoken generator registered with the
     * JDBC driver.  Token construction is delegated to UtilAppTokenSigner.
     */
    static class TrustCallbackImpl implements DB2AppTokenGen {

        @Override
        public int getAppToken(int versionNumber, Object userData,
                               DB2AppTokenGen.AppTokenGenParam nonce,
                               DB2AppTokenGen.AppTokenGenParam apptoken) {

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

    // -----------------------------------------------------------------------
    // Main — connect and verify
    // -----------------------------------------------------------------------

    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            System.err.println("Usage: java DemoEmbeddedConnect <url> <user> <password>");
            System.exit(1);
        }

        String url      = args[0];
        String user     = args[1];
        String password = args[2];

        Class.forName("com.ibm.db2.jcc.DB2Driver");

        Properties props = new Properties();
        props.put("appTokenGen", new TrustCallbackImpl());
        props.put("user",        user);
        props.put("password",    password);

        System.out.println("Connecting: " + url + " as " + user);

        try (Connection con = DriverManager.getConnection(url, props);
             Statement  stmt = con.createStatement();
             ResultSet  rs   = stmt.executeQuery("VALUES TRUSTED_CONTEXT")) {

            rs.next();
            String ctx = rs.getString(1);

            if ("DEMO_TRUSTCTX".equals(ctx)) {
                System.out.println("SUCCESS: Trusted connection established under context: " + ctx);
            } else {
                System.out.println("NOT TRUSTED: TRUSTED_CONTEXT = " + (ctx == null ? "NULL" : ctx));
            }
        }
    }
}
