package com.ibm.db2.tools.repl.publication;

/**
 * The Column class represents an actual value of a column for a specific row.  The Column
 * contains the value after the update, and may optionally also contain the pre-update value (called
 * the "before" value).
 *
 * @author tjacopi
 */
public class Column {
   protected String  name = null;
   protected boolean key = false;
   protected boolean beforeValuePresent = false;
   protected Object  value = null;
   protected Object  beforeValue = null;

   /**
    * Returns the name of the column.
	 * @return String The column name.
    */
   public String getName() {
      return name;
   }

   /**
    * Returns true if the column is a key column.
	 * @return boolean  True:  The column is a key column.  False:  The column is not part of a key.
    */
   public boolean isKey() {
      return key;
   }

   /**
    * Returns the original value of the column, before it was updated.  This is optional when
    * the publication is defined.
    * @return Object  The original value of the column.  Null if not available.
    */
   public Object getBeforeValue() {
     return beforeValue;
   }

   /**
    * Returns true if the original value of the column is present.  This is optional when
    * the publication is defined.
    * @return boolean  True:  The original value is present.
    */
   public boolean isBeforeValuePresent() {
      return beforeValuePresent;
   }

   /**
    * Returns the value of the column.
    * @return Object  The column value.
    */
   public Object getValue() {
      return value;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param b
    */
   public void setKey(boolean b) {
      key = b;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param string
    */
   public void setName(String string) {
      name = string;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param object
    */
   public void setBeforeValue(Object object) {
      beforeValue = object;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param b
    */
   public void setBeforeValuePresent(boolean b) {
      beforeValuePresent = b;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param object
    */
   public void setValue(Object object) {
      value = object;
   }

   public String toString() {
     return Utils.formatAsString(this);
   }


}
