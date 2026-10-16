/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.PublicKey;
import java.security.Signature;
import java.util.Arrays;

/**
 * TestTokenGen — unit tests for the signed apptoken generation logic.
 *
 * Tests both DemoCallbackGen (standalone jar) and
 * DemoEmbeddedConnect.TrustCallbackImpl (inline implementation) by
 * exercising getAppToken() directly through the AppTokenGenParam stub,
 * without requiring a database connection.
 *
 * Token format under test:
 *   PREFIX   : "TRUSTCALLBACK"  — 13 ASCII bytes
 *   NONCE    : raw nonce bytes  — nonceLen bytes
 *   EXPIRY   : Unix epoch (now + 60 s), big-endian int64  — 8 bytes
 *   SIGLEN   : byte count of SIG, big-endian uint16       — 2 bytes
 *   SIG      : RSA-2048/SHA-256 signature over
 *              (PREFIX || NONCE || EXPIRY)                — 256 bytes
 *
 * Build and run (from signedtoken/):
 *   make java_unit_test DB2JCC=$DB2JCC
 */
public class TestTokenGen {

    // Token field sizes (must match DemoCallbackGen and utilapptokensigner.c)
    private static final int PREFIX_LEN  = 13;
    private static final int EXPIRY_LEN  = 8;
    private static final int SIGLEN_LEN  = 2;
    private static final int SIG_LEN     = 256;  // RSA-2048

    private static final byte[] PREFIX =
        "TRUSTCALLBACK".getBytes(StandardCharsets.US_ASCII);

    // -----------------------------------------------------------------------
    // Testable AppTokenGenParam
    // -----------------------------------------------------------------------

    static class TestParam extends com.ibm.db2.jcc.DB2AppTokenGen.AppTokenGenParam {
        private byte[] data   = new byte[0];
        private int    length = 0;

        TestParam(byte[] nonce) {
            this.data   = nonce;
            this.length = nonce.length;
        }

        TestParam() {}

        @Override public byte[] getData()         { return data; }
        @Override public int    getLength()       { return length; }
        @Override public void   setData(byte[] d) { this.data   = d; }
        @Override public void   setLength(int l)  { this.length = l; }
    }

    // -----------------------------------------------------------------------
    // Minimal test harness
    // -----------------------------------------------------------------------

    private static int passed = 0;
    private static int failed = 0;

    static void check(String name, boolean condition) {
        if (condition) {
            System.out.println("  PASS: " + name);
            passed++;
        } else {
            System.out.println("  FAIL: " + name);
            failed++;
        }
    }

    // -----------------------------------------------------------------------
    // Helpers
    // -----------------------------------------------------------------------

    /**
     * Verifies the RS256 signature embedded in a token.
     * Layout: PREFIX(13) | NONCE(nonceLen) | EXPIRY(8) | SIGLEN(2) | SIG(256)
     */
    static boolean verifyTokenSig(byte[] token, int nonceLen) throws Exception {
        int expectedLen = PREFIX_LEN + nonceLen + EXPIRY_LEN + SIGLEN_LEN + SIG_LEN;
        if (token == null || token.length != expectedLen)
            return false;

        int sigOffset    = token.length - SIG_LEN;
        int siglenOffset = sigOffset - SIGLEN_LEN;
        int expiryOffset = siglenOffset - EXPIRY_LEN;

        int siglenVal = ((token[siglenOffset] & 0xFF) << 8) | (token[siglenOffset + 1] & 0xFF);
        if (siglenVal != SIG_LEN)
            return false;

        byte[] sig       = Arrays.copyOfRange(token, sigOffset,    token.length);
        byte[] expiryRaw = Arrays.copyOfRange(token, expiryOffset, expiryOffset + EXPIRY_LEN);
        byte[] nonce     = Arrays.copyOfRange(token, PREFIX_LEN,   PREFIX_LEN + nonceLen);

        ByteBuffer dts = ByteBuffer.allocate(PREFIX_LEN + nonceLen + EXPIRY_LEN);
        dts.put(PREFIX);
        dts.put(nonce);
        dts.put(expiryRaw);

        PublicKey pubKey = UtilAppTokenSigner.loadPublicKey();
        Signature verifier = Signature.getInstance("SHA256withRSA");
        verifier.initVerify(pubKey);
        verifier.update(dts.array());
        return verifier.verify(sig);
    }

    static long readExpiry(byte[] token, int nonceLen) {
        int expiryOffset = PREFIX_LEN + nonceLen;
        return ByteBuffer.wrap(token, expiryOffset, EXPIRY_LEN).getLong();
    }

    // -----------------------------------------------------------------------
    // Shared test cases — run against any DB2AppTokenGen implementation
    // -----------------------------------------------------------------------

    static void runTests(String label, com.ibm.db2.jcc.DB2AppTokenGen gen)
        throws Exception
    {
        System.out.println("\n[ " + label + " ]");

        // TC1: Normal case — 16-byte nonce
        {
            byte[] nonce    = {0x01,0x02,0x03,0x04,0x05,0x06,0x07,0x08,
                               0x09,0x0A,0x0B,0x0C,0x0D,0x0E,0x0F,0x10};
            TestParam nonceParam = new TestParam(nonce);
            TestParam tokenParam = new TestParam();
            int rc = gen.getAppToken(0, null, nonceParam, tokenParam);

            byte[] tok = tokenParam.getData();
            int expectedLen = PREFIX_LEN + 16 + EXPIRY_LEN + SIGLEN_LEN + SIG_LEN;

            check("TC1 return code is 0",                rc == 0);
            check("TC1 output length correct",           tokenParam.getLength() == expectedLen);
            check("TC1 starts with PREFIX",
                Arrays.equals(Arrays.copyOf(tok, PREFIX_LEN), PREFIX));
            check("TC1 nonce bytes at offset 13",
                Arrays.equals(Arrays.copyOfRange(tok, PREFIX_LEN, PREFIX_LEN + 16), nonce));
            check("TC1 SIGLEN field == 256",
                ((tok[PREFIX_LEN+16+EXPIRY_LEN] & 0xFF) << 8 |
                 (tok[PREFIX_LEN+16+EXPIRY_LEN+1] & 0xFF)) == SIG_LEN);
            check("TC1 signature verifies",             verifyTokenSig(tok, 16));
        }

        // TC2: Single-byte nonce — boundary case
        {
            byte[] nonce = {(byte) 0xAB};
            TestParam nonceParam = new TestParam(nonce);
            TestParam tokenParam = new TestParam();
            int rc = gen.getAppToken(0, null, nonceParam, tokenParam);

            byte[] tok = tokenParam.getData();
            int expectedLen = PREFIX_LEN + 1 + EXPIRY_LEN + SIGLEN_LEN + SIG_LEN;

            check("TC2 return code is 0",                rc == 0);
            check("TC2 output length correct",           tokenParam.getLength() == expectedLen);
            check("TC2 nonce byte at offset 13 = 0xAB", tok[PREFIX_LEN] == (byte) 0xAB);
            check("TC2 signature verifies",              verifyTokenSig(tok, 1));
        }

        // TC3: All-zero nonce bytes — must not be treated as empty
        {
            byte[] nonce = new byte[16];
            TestParam nonceParam = new TestParam(nonce);
            TestParam tokenParam = new TestParam();
            int rc = gen.getAppToken(0, null, nonceParam, tokenParam);

            byte[] tok = tokenParam.getData();
            check("TC3 return code is 0",    rc == 0);
            check("TC3 prefix correct",
                Arrays.equals(Arrays.copyOf(tok, PREFIX_LEN), PREFIX));
            check("TC3 nonce is 16 zero bytes",
                Arrays.equals(Arrays.copyOfRange(tok, PREFIX_LEN, PREFIX_LEN + 16), nonce));
            check("TC3 signature verifies",  verifyTokenSig(tok, 16));
        }

        // TC4: Expiry is in the future (within [1 s, 61 s] from now)
        {
            byte[] nonce = {0x01, 0x02, 0x03, 0x04};
            TestParam nonceParam = new TestParam(nonce);
            TestParam tokenParam = new TestParam();

            long before = System.currentTimeMillis() / 1000L;
            gen.getAppToken(0, null, nonceParam, tokenParam);
            long after  = System.currentTimeMillis() / 1000L;

            byte[] tok  = tokenParam.getData();
            long expiry = readExpiry(tok, 4);

            check("TC4 expiry > current time",  after  < expiry);
            check("TC4 expiry <= now + 61 s",   expiry <= before + 61);
        }

        // TC5: Null nonce param — must return 0 and produce empty token
        {
            TestParam tokenParam = new TestParam();
            int rc = gen.getAppToken(0, null, null, tokenParam);

            check("TC5 return code is 0",     rc == 0);
            check("TC5 output length = 0",    tokenParam.getLength() == 0);
            check("TC5 output data is empty", tokenParam.getData().length == 0);
        }

        // TC6: Zero-length nonce — must behave same as null nonce
        {
            TestParam nonceParam = new TestParam(new byte[0]);
            TestParam tokenParam = new TestParam();
            int rc = gen.getAppToken(0, null, nonceParam, tokenParam);

            check("TC6 return code is 0",     rc == 0);
            check("TC6 output length = 0",    tokenParam.getLength() == 0);
            check("TC6 output data is empty", tokenParam.getData().length == 0);
        }

        // TC7: userData argument is ignored — must not crash or affect output
        {
            byte[] nonce = {0x42, 0x43, 0x44};
            TestParam nonceParam = new TestParam(nonce);
            TestParam tokenParam = new TestParam();
            int rc = gen.getAppToken(0, "unexpected-user-data", nonceParam, tokenParam);

            byte[] tok = tokenParam.getData();
            check("TC7 return code is 0",       rc == 0);
            check("TC7 signature verifies",     verifyTokenSig(tok, 3));
        }

        // TC8: High (>0x7F) nonce bytes — confirms no encoding transformation
        {
            byte[] nonce = {(byte)0x80, (byte)0xFF, (byte)0xC0, (byte)0xDE};
            TestParam nonceParam = new TestParam(nonce);
            TestParam tokenParam = new TestParam();
            gen.getAppToken(0, null, nonceParam, tokenParam);

            byte[] tok    = tokenParam.getData();
            byte[] actual = Arrays.copyOfRange(tok, PREFIX_LEN, PREFIX_LEN + 4);
            check("TC8 nonce bytes verbatim after prefix",
                Arrays.equals(actual, nonce));
            check("TC8 signature verifies", verifyTokenSig(tok, 4));
        }

        // TC9: Two consecutive tokens from the same nonce are both valid
        {
            byte[] nonce = {0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08};
            TestParam nonceParam1 = new TestParam(nonce);
            TestParam tokenParam1 = new TestParam();
            TestParam nonceParam2 = new TestParam(nonce);
            TestParam tokenParam2 = new TestParam();

            gen.getAppToken(0, null, nonceParam1, tokenParam1);
            gen.getAppToken(0, null, nonceParam2, tokenParam2);

            check("TC9 first token sig valid",  verifyTokenSig(tokenParam1.getData(), 8));
            check("TC9 second token sig valid", verifyTokenSig(tokenParam2.getData(), 8));
        }
    }

    // -----------------------------------------------------------------------
    // Entry point
    // -----------------------------------------------------------------------

    public static void main(String[] args) throws Exception {
        System.out.println("=== TestTokenGen ===");

        runTests("DemoCallbackGen", new DemoCallbackGen());
        runTests("DemoEmbeddedConnect.TrustCallbackImpl", new DemoEmbeddedConnect.TrustCallbackImpl());

        System.out.println("\n---");
        System.out.println("Results: " + passed + " passed, " + failed + " failed");
        if (failed > 0) System.exit(1);
    }
}
