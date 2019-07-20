/**********************************************************************
 *
 *  Source File Name = UserMappingCryptoLDAP.java
 *
 *  (C) COPYRIGHT International Business Machines Corp. 2003, 2004, 2005
 *  All Rights Reserved
 *  Licensed Materials - Property of IBM
 *
 *  US Government Users Restricted Rights - Use, duplication or
 *  disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
 *
 *  Operating System = all
 *
 ***********************************************************************/
import javax.crypto.*;
import javax.crypto.spec.*;

import sun.misc.BASE64Decoder;
import sun.misc.BASE64Encoder;

import com.ibm.ii.um.UserMappingCrypto;
import com.ibm.ii.um.UserMappingException;

/**
 * This class implements encryption and decryption of bytes 
 * and is used by the user mapping plugin Java sample. 
 * It is stronly recommended that you customize this class 
 * to fit your security needs. 
 */
public class UserMappingCryptoLDAP extends UserMappingCrypto {

  public UserMappingCryptoLDAP() throws UserMappingException {
    try {
      // algorithm used to encrypt user mappings on the LDAP server
      cipher = Cipher.getInstance("DESede/ECB/PKCS5Padding");
      // key used to encrypt user mappings on the LDAP server
      key = getKey();
    }
    catch (Exception e) {
      throw new UserMappingException(UserMappingException.DECRYPTION_ERROR);
    }	
  }
	 
  /**
   * Encrypt the plainValue parameter.
   */
  public byte[] encrypt(byte[] plainValue) throws Exception {
      byte[] result = null;
      cipher.init(Cipher.ENCRYPT_MODE, key);
      result = cipher.doFinal(plainValue);
      return result;
  }

  /**
   * Decrypt the encryptedValue parameter.
   */
  public byte[] decrypt(byte[] encryptedValue) throws Exception {
      byte[] result = null;
      cipher.init(Cipher.DECRYPT_MODE, key);
      result = cipher.doFinal(encryptedValue);
      return result;
  }
    
  /**
   * Return the key used for encryption/decryption
   */
  private SecretKey getKey() throws Exception {
      SecretKey result = null;
      // raw key material, 24 byte = 192 bit
      byte[] rawKey = {
        (byte)0xc7, (byte)0x73, (byte)0x21, (byte)0x8c,
        (byte)0x7e, (byte)0xc8, (byte)0xee, (byte)0x99,
        (byte)0xa7, (byte)0xf3, (byte)0x48, (byte)0x1e,
        (byte)0x62, (byte)0xc1, (byte)0xd7, (byte)0xaa,
        (byte)0xba, (byte)0x22, (byte)0xf5, (byte)0x74,
        (byte)0xcf, (byte)0x98, (byte)0xac, (byte)0xe2
      };
      DESedeKeySpec myKeySpec = new DESedeKeySpec(rawKey);
      SecretKeyFactory factory = SecretKeyFactory.getInstance("DESede");
      result = factory.generateSecret(myKeySpec);	  
      return result;
  }  

  /**
   * Uses the Base64Decoder to decode String to bytes.
   */
  public byte[] decode(String string) throws Exception {
      byte[] result = new BASE64Decoder().decodeBuffer(string);
      return result;
  }

  /**
   * Uses the Base64Encoder to encode byte array into Sring.
   */
  public String encode(byte[] bytes) throws Exception {
    String result = new BASE64Encoder().encode(bytes);
    return result;
  }
}
