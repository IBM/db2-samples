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

/**
 * DemoSimpleConnect — a plain JDBC application with no knowledge of apptokens or
 * trusted contexts.
 *
 * This file represents the "application we don't own" in Step 6 of the demo.
 * It makes a standard JDBC connection using only user and password, then queries
 * VALUES TRUSTED_CONTEXT to show whether the connection was granted trust.
 *
 * The apptoken generator (DemoCallbackGen) is injected entirely from outside:
 * the caller embeds "appTokenGenClassName=DemoCallbackGen" in the JDBC URL and
 * places democallbackgen.jar on the classpath.  No source changes to this file
 * are needed to enable trusted connections.
 *
 * Compare this approach with DemoEmbeddedConnect.java, where the callback is
 * implemented in the same file and registered programmatically via the
 * "appTokenGen" property.
 *
 * Compile (from signedtoken/):
 *   javac -cp $DB2JCC -d build src/client/java/DemoSimpleConnect.java
 *
 * Run — trusted (appTokenGenClassName embedded in URL):
 *   java -cp build:$DB2JCC:build/democallbackgen.jar DemoSimpleConnect \
 *       "jdbc:db2://host:port/db:appTokenGenClassName=DemoCallbackGen;" \
 *       <user> <password>
 *
 * Run — not trusted (plain URL, no apptoken):
 *   java -cp build:$DB2JCC DemoSimpleConnect \
 *       "jdbc:db2://host:port/db" \
 *       <user> <password>
 */
public class DemoSimpleConnect {

    public static void main(String[] args) throws Exception {
        if (args.length != 3) {
            System.err.println("Usage: java DemoSimpleConnect <url> <user> <password>");
            System.exit(1);
        }
        String url      = args[0];
        String user     = args[1];
        String password = args[2];

        // Explicitly load the Db2 JDBC driver class.  Not required on Java 6+
        // with service-loader, but included for clarity.
        Class.forName("com.ibm.db2.jcc.DB2Driver");

        // Standard connection properties — no apptoken knowledge here.
        // If the caller embedded "appTokenGenClassName=..." in the URL, the
        // driver parses it from there and loads the generator class itself.
        Properties props = new Properties();
        props.put("user",     user);
        props.put("password", password);

        System.out.println("Connecting: " + url + " as " + user);

        try (Connection con = DriverManager.getConnection(url, props);
             Statement  stmt = con.createStatement();
             ResultSet  rs   = stmt.executeQuery("VALUES TRUSTED_CONTEXT")) {

            rs.next();
            // TRUSTED_CONTEXT returns the name of the active trusted context,
            // or NULL if the connection is not trusted.
            String ctx = rs.getString(1);

            if ("DEMO_TRUSTCTX".equals(ctx)) {
                System.out.println("SUCCESS: Trusted connection established under context: " + ctx);
            } else {
                System.out.println("NOT TRUSTED: TRUSTED_CONTEXT = " + (ctx == null ? "NULL" : ctx));
            }
        }
    }
}
