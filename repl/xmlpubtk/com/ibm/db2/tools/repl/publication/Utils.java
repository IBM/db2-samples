package com.ibm.db2.tools.repl.publication;

import  java.lang.reflect.*;


/**
 * This class contains a bunch of static methods to help format an object as a readable
 * textual string.
 *
 * @author tjacopi
 */
public class Utils {
  protected static final String indent = "  ";
  protected static final String nl = "\n";
  protected static final String nlIndent = "\n  ";
  protected static int level = 0;

  /**
   * Format the object as a nice string.
   * @param  obj     The object to format.
   * @return String  The textual representation.
   */
  public static String formatAsString(Object obj) {
     level++;
     StringBuffer sb = new StringBuffer(500);
     sb.append(obj.getClass().getName());
     sb.append("@");
     sb.append( Integer.toHexString( obj.hashCode() ) );

     fieldsAsString(obj, sb);
     level--;
     return sb.toString();
   }

  /**
   * Format the object as a nice string.
   * @param  obj     The object to format.
   * @param  sb      Place the output into this StringBuffer.
   */
   public static void fieldsAsString(Object obj, StringBuffer sb) {
//   Field[] fields = getClass().getDeclaredFields();

     Class cls = obj.getClass();
     while (cls != null && !cls.getName().equals("java.lang.Object") ) {
       Field[] fields = cls.getDeclaredFields();
       for (int i=0; i<fields.length; i++) {
         sb.append(nl);
         doIndent(sb);
         Object value = "<not shown>";
         try {
           if (!fields[i].getName().equals("jmsMsg") ) {
             value = fields[i].get(obj);
           };
         } catch (Throwable t) {
           value = "<not accessible>";
         }
         sb.append(fields[i].getName());
         sb.append(" = ");
         if (value == null) {
           sb.append("null");
         } else {
           sb.append(value.toString() );
         }
       }

       cls = cls.getSuperclass();
     }
   }

   private static void doIndent(StringBuffer sb) {
     for (int i=0; i<level; i++ ) {
       sb.append(indent);
     }
   }
}
