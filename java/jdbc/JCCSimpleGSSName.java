//***************************************************************************
// (c) Copyright IBM Corp. 2007 All rights reserved.
// 
// The following sample of source code ("Sample") is owned by International 
// Business Machines Corporation or one of its subsidiaries ("IBM") and is 
// copyrighted and licensed, not sold. You may use, copy, modify, and 
// distribute the Sample in any form without payment to IBM, for the purpose of 
// assisting you in the development of your applications.
// 
// The Sample code is provided to you on an "AS IS" basis, without warranty of 
// any kind. IBM HEREBY EXPRESSLY DISCLAIMS ALL WARRANTIES, EITHER EXPRESS OR 
// IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF 
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. Some jurisdictions do 
// not allow for the exclusion or limitation of implied warranties, so the above 
// limitations or exclusions may not apply to you. IBM shall not be liable for 
// any damages you suffer as a result of using, copying, modifying or 
// distributing the Sample, even if IBM has been advised of the possibility of 
// such damages.
//***************************************************************************
//
// SOURCE FILE NAME: JCCSimpleGSSName.java
//
// SAMPLE: This file is used by JCCSimpleGSSPlugin to implement a JCC
//         GSS-API plugin sample
//
// OUTPUT FILE: None
//***************************************************************************
//
// For more information on the sample programs, see the README file.
//
// For information on developing JDBC applications, see the Application
// Development Guide.
//
// For information on using SQL statements, see the SQL Reference.
//
// For the latest information on programming, compiling, and running DB2
// applications, visit the DB2 application development website at
//     http://www.software.ibm.com/data/db2/udb/ad
//**************************************************************************/

import java.io.InputStream;
import java.io.OutputStream;
import org.ietf.jgss.*;

public class JCCSimpleGSSName implements org.ietf.jgss.GSSName
{
  private String userid_;

  public JCCSimpleGSSName(String userid)
  {
    userid_ = userid;
  }

  public String getUserid()
  {
    return userid_;
  }

  public void setUserid(String user)
  {
    userid_ = user;
  }

  /**
   * Compares two <code>GSSName</code> objects to determine if they refer to the
   * same entity.
   *
   * @param another the <code>GSSName</code> to compare this name with
   * @return true if the two names contain at least one primitive element
   * in common. If either of the names represents an anonymous entity, the
   * method will return false.
   *
   * @throws GSSException when the names cannot be compared, containing the following
   * major error codes:
   *         {@link GSSException#BAD_NAMETYPE GSSException.BAD_NAMETYPE},
   *         {@link GSSException#FAILURE GSSException.FAILURE}
   */
  public boolean equals(GSSName another) throws GSSException
  {
    if(another instanceof JCCSimpleGSSName)
      return (userid_ == ((JCCSimpleGSSName)another).getUserid());
    else
      return false;
  }

 /**
  * Compares this <code>GSSName</code> object to another Object that might be a
  * <code>GSSName</code>. The behaviour is exactly the same as in {@link
  * #equals(GSSName) equals} except that no GSSException is thrown;
  * instead, false will be returned in the situation where an error
  * occurs.
  * @return true if the object to compare to is also a <code>GSSName</code> and the two
  * names refer to the same entity.
  * @param another the object to compare this name to
  * @see #equals(GSSName)
  */
 public boolean equals(Object another)
 {
   if(another instanceof JCCSimpleGSSName)
     return (userid_ == ((JCCSimpleGSSName)another).getUserid());
   else
     return false;

 }

 /**
  * Returns a hashcode value for this GSSName.
  *
  * @return a hashCode value
  */
 public int hashCode()
 {
   //not used by JCC, return 0
   return 0;
 }

 /**
  * Creates a name that is canonicalized for some
  * mechanism.
  *
  * @return a <code>GSSName</code> that contains just one primitive
  * element representing this name in a canonicalized form for the desired
  * mechanism.
  * @param mech the oid for the mechanism for which the canonical form of
  * the name is requested.
  *
  * @throws GSSException containing the following
  * major error codes:
  *         {@link GSSException#BAD_MECH GSSException.BAD_MECH},
  *         {@link GSSException#BAD_NAMETYPE GSSException.BAD_NAMETYPE},
  *         {@link GSSException#BAD_NAME GSSException.BAD_NAME},
  *         {@link GSSException#FAILURE GSSException.FAILURE}
  */
 public GSSName canonicalize(Oid mech) throws GSSException
 {
   throw new JCCSimpleGSSException(0,"canonicalize(Oid mech) is not implemented");
 }

 /**
  * Returns a canonical contiguous byte representation of a mechanism name
  * (MN), suitable for direct, byte by byte comparison by authorization
  * functions.  If the name is not an MN, implementations may throw a
  * GSSException with the NAME_NOT_MN status code.  If an implementation
  * chooses not to throw an exception, it should use some system specific
  * default mechanism to canonicalize the name and then export
  * it. Structurally, an exported name object consists of a header
  * containing an OID identifying the mechanism that authenticated the
  * name, and a trailer containing the name itself, where the syntax of
  * the trailer is defined by the individual mechanism specification. The
  * format of the header of the output buffer is specified in RFC 2743.<p>
  *
  * The exported name is useful when used in large access control lists
  * where the overhead of creating a <code>GSSName</code> object on each
  * name and invoking the equals method on each name from the ACL may be
  * prohibitive.<p>
  *
  * Exported names may be re-imported by using the byte array factory
  * method {@link GSSManager#createName(byte[], Oid)
  * GSSManager.createName} and specifying the NT_EXPORT_NAME as the name
  * type object identifier. The resulting <code>GSSName</code> name will
  * also be a MN.<p>
  * @return a byte[] containing the exported name. RFC 2743 defines the
  * "Mechanism-Independent Exported Name Object Format" for these bytes.
  *
  * @throws GSSException containing the following
  * major error codes:
  *         {@link GSSException#BAD_NAME GSSException.BAD_NAME},
  *         {@link GSSException#BAD_NAMETYPE GSSException.BAD_NAMETYPE},
  *         {@link GSSException#FAILURE GSSException.FAILURE}
  */
 public byte[] export() throws GSSException
 {
   throw new JCCSimpleGSSException(0,"export() is not implemented");
 }

 /**
  * Returns a textual representation of the <code>GSSName</code> object.  To retrieve
  * the printed name format, which determines the syntax of the returned
  * string, use the {@link #getStringNameType() getStringNameType}
  * method.
  *
  * @return a String representing this name in printable form.
  */
 public String toString()
 {
   return super.toString() + " "+ userid_;
 }

 /**
  * Returns the name type of the printable
  * representation of this name that can be obtained from the <code>
  * toString</code> method.
  *
  * @return an Oid representing the namespace of the name returned
  * from the toString method.
  *
  * @throws GSSException containing the following
  * major error codes:
  *         {@link GSSException#FAILURE GSSException.FAILURE}
  */
 public Oid getStringNameType() throws GSSException
 {
   throw new JCCSimpleGSSException(0,"getStringNameType() is not implemented");
 }

 /**
  * Tests if this name object represents an anonymous entity.
  *
  * @return true if this is an anonymous name, false otherwise.
  */
 public boolean isAnonymous()
 {
   return false;
 }

 /**
  * Tests if this name object represents a Mechanism Name (MN). An MN is
  * a GSSName the contains exactly one mechanism's primitive name
  * element.
  *
  * @return true if this is an MN, false otherwise.
  */
 public boolean isMN()
 {
   return false;
 }
}
