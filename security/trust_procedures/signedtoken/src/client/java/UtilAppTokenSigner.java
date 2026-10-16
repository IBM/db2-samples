/*
 * (c) Copyright IBM Corp. 2026 All Rights Reserved.
 *
 * SPDX-License-Identifier: Apache-2.0
 */
import java.io.FileInputStream;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.security.KeyFactory;
import java.security.PrivateKey;
import java.security.PublicKey;
import java.security.Signature;
import java.security.spec.PKCS8EncodedKeySpec;
import java.security.spec.X509EncodedKeySpec;

/**
 * UtilAppTokenSigner — shared signing utility for the Db2 Trust Procedure demo.
 *
 * Contains the token-building and key-loading logic used by both demo approaches:
 *   - DemoEmbeddedConnect.java  (inline callback, programmatic registration)
 *   - DemoCallbackGen.java      (standalone jar, URL-based registration)
 *
 * Neither demo file references the other; both depend only on this class.
 *
 * Token format produced by buildToken() (all fields concatenated, no padding):
 *   PREFIX   : "TRUSTCALLBACK"  — 13 ASCII bytes
 *   NONCE    : raw nonce bytes  — nonceLen bytes
 *   EXPIRY   : Unix epoch (now + 60 s), big-endian int64  — 8 bytes
 *   SIGLEN   : byte count of SIG, big-endian uint16       — 2 bytes
 *   SIG      : RSA-2048/SHA-256 (RS256) signature over
 *              (PREFIX || NONCE || EXPIRY)                — 256 bytes
 *
 * Key locations:
 *   Private key : $HOME/trustproc_keys/private.pem  (PKCS#8 PEM)
 *   Public key  : $HOME/trustproc_keys/public.pem   (SubjectPublicKeyInfo PEM)
 */
class UtilAppTokenSigner {

    private static final byte[] PREFIX =
        "TRUSTCALLBACK".getBytes(StandardCharsets.US_ASCII);

    private static final int TOKEN_LIFETIME_SECONDS = 60;

    /**
     * Builds a signed apptoken from the given nonce bytes.
     *
     * @param nonceData  raw nonce bytes received from the server
     * @param nonceLen   number of valid bytes in nonceData
     * @return signed token bytes, or null if signing fails (e.g. key not found)
     */
    static byte[] buildToken(byte[] nonceData, int nonceLen) {
        try {
            PrivateKey privateKey = loadPrivateKey();

            // Expiry: current Unix time + 60 seconds, big-endian int64
            long expiry = (System.currentTimeMillis() / 1000L) + TOKEN_LIFETIME_SECONDS;
            byte[] expiryBytes = ByteBuffer.allocate(8).putLong(expiry).array();

            // Data to sign: PREFIX || NONCE || EXPIRY
            byte[] dataToSign = new byte[PREFIX.length + nonceLen + expiryBytes.length];
            System.arraycopy(PREFIX,      0, dataToSign, 0,                        PREFIX.length);
            System.arraycopy(nonceData,   0, dataToSign, PREFIX.length,            nonceLen);
            System.arraycopy(expiryBytes, 0, dataToSign, PREFIX.length + nonceLen, expiryBytes.length);

            // Sign with SHA256withRSA (RS256)
            Signature signer = Signature.getInstance("SHA256withRSA");
            signer.initSign(privateKey);
            signer.update(dataToSign);
            byte[] sig = signer.sign();

            // Assemble output: PREFIX | NONCE | EXPIRY | SIGLEN(2 BE) | SIG
            ByteBuffer buf = ByteBuffer.allocate(
                PREFIX.length + nonceLen + expiryBytes.length + 2 + sig.length);
            buf.put(PREFIX);
            buf.put(nonceData, 0, nonceLen);
            buf.put(expiryBytes);
            buf.putShort((short) sig.length);
            buf.put(sig);
            return buf.array();

        } catch (Exception e) {
            System.err.println("[UtilAppTokenSigner] ERROR building token: " + e.getMessage());
            return null;
        }
    }

    /**
     * Loads the RSA private key from $HOME/trustproc_keys/private.pem.
     * The file must be in PKCS#8 PEM format (the default from openssl genpkey).
     */
    static PrivateKey loadPrivateKey() throws Exception {
        String path = keyPath("private.pem");
        byte[] pem  = readFile(path);

        String b64 = new String(pem, StandardCharsets.US_ASCII)
            .replace("-----BEGIN PRIVATE KEY-----", "")
            .replace("-----END PRIVATE KEY-----", "")
            .replaceAll("\\s+", "");
        byte[] der = java.util.Base64.getDecoder().decode(b64);

        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePrivate(new PKCS8EncodedKeySpec(der));
    }

    /**
     * Loads the RSA public key from $HOME/trustproc_keys/public.pem.
     * Used by the test harness to verify tokens without a database.
     */
    static PublicKey loadPublicKey() throws Exception {
        String path = keyPath("public.pem");
        byte[] pem  = readFile(path);

        String b64 = new String(pem, StandardCharsets.US_ASCII)
            .replace("-----BEGIN PUBLIC KEY-----", "")
            .replace("-----END PUBLIC KEY-----", "")
            .replaceAll("\\s+", "");
        byte[] der = java.util.Base64.getDecoder().decode(b64);

        KeyFactory kf = KeyFactory.getInstance("RSA");
        return kf.generatePublic(new X509EncodedKeySpec(der));
    }

    private static String keyPath(String filename) throws IOException {
        String home = System.getProperty("user.home");
        if (home == null || home.isEmpty())
            throw new IOException("user.home system property is not set");
        return home + "/trustproc_keys/" + filename;
    }

    private static byte[] readFile(String path) throws IOException {
        try (FileInputStream fis = new FileInputStream(path)) {
            return fis.readAllBytes();
        }
    }
}
