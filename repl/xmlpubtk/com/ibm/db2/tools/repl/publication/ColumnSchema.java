package com.ibm.db2.tools.repl.publication;
import  java.sql.*;

/**
 * The ColumnSchema class reprenents a column defintion in a table.  These objects are used in the
 * SubscriptionSchemaMsg and the AddColumnSchemaMsg.
 *
 * @author tjacopi
 *
 */
public class ColumnSchema {
	protected String name = null;
	protected String type = null;
	protected int length = 0;
	protected int precision = 0;
	protected int scale = 0;
	protected int codepage = 0;
	protected boolean key = false;
	
	/**
    * Returns the codepage of the column.  If the column does not have a codepage, like an
    * integer column, this returns 0.
	 * @return int The codepage of the column, or 0 if not valid.
	 */
	public int getCodepage() {
		return codepage;
	}

	/**
    * Returns true if the column is a key column.
	 * @return boolean  True:  The column is a key column.  False:  The column is not part of a key.
	 */
	public boolean isKey() {
		return key;
	}

	/**
    * Returns the length of the column.  If the column does not have a length, like an
    * integer column, this returns 0.
	 * @return int The length of the column, or 0 if not valid.
	 */
	public int getLength() {
		return length;
	}

	/**
    * Returns the name of the column.
	 * @return String The column name.
	 */
	public String getName() {
		return name;
	}

	/**
    * Returns the precision of the column.  If the column does not have a precision, like an
    * integer column, this returns 0.
	 * @return int  The precision of the column, or 0 if not valid.
	 */
	public int getPrecision() {
		return precision;
	}

	/**
    * Returns the scale of the column.  If the column does not have a scale, like an
    * integer column, this returns 0.
	 * @return int The scale of the column, or 0 if not valid.
	 */
	public int getScale() {
		return scale;
	}

	/**
    * Returns the datatype of the column.
	 * @return String The datatype of the column.
	 */
	public String getType() {
		return type;
	}

	/**
    * Returns the datatype of the column as a JDBC type.
	 * @return int   The JDBC datatype of the column.
	 */
	public int getJDBCType() {
     int jdbcType = -1;
     if ("smallint".equals(type) ) {
       jdbcType = java.sql.Types.SMALLINT;
     } else if ("integer".equals(type) ) {
       jdbcType = java.sql.Types.INTEGER;
     } else if ("bigint".equals(type) ) {
       jdbcType = java.sql.Types.BIGINT;
     } else if ("float".equals(type) ) {
       jdbcType = java.sql.Types.FLOAT;
     } else if ("real".equals(type) ) {
       jdbcType = java.sql.Types.REAL;
     } else if ("double".equals(type) ) {
       jdbcType = java.sql.Types.DOUBLE;
     } else if ("decimal".equals(type) ) {
       jdbcType = java.sql.Types.DECIMAL;
     } else if ("char".equals(type) ) {
       jdbcType = java.sql.Types.CHAR;
     } else if ("varchar".equals(type) ) {
       jdbcType = java.sql.Types.VARCHAR;
     } else if ("longvarchar".equals(type) ) {
       jdbcType = java.sql.Types.LONGVARCHAR;
     } else if ("bitchar".equals(type) ) {
       jdbcType = java.sql.Types.BINARY;
     } else if ("bitvarchar".equals(type) ) {
       jdbcType = java.sql.Types.VARBINARY;
     } else if ("bitlongvarchar".equals(type) ) {
       jdbcType = java.sql.Types.LONGVARBINARY;
     } else if ("graphic".equals(type) ) {
       jdbcType = java.sql.Types.BINARY;
     } else if ("vargraphic".equals(type) ) {
       jdbcType = java.sql.Types.VARBINARY;
     } else if ("longvargraphic".equals(type) ) {
       jdbcType = java.sql.Types.LONGVARBINARY;
     } else if ("time".equals(type) ) {
       jdbcType = java.sql.Types.TIME;
     } else if ("timestamp".equals(type) ) {
       jdbcType = java.sql.Types.TIMESTAMP;
     } else if ("date".equals(type) ) {
       jdbcType = java.sql.Types.DATE;
     } else if ("rowid".equals(type) ) {
       jdbcType = java.sql.Types.INTEGER;
     } else if ("blob".equals(type) ) {
       jdbcType = java.sql.Types.BLOB;
     } else if ("clob".equals(type) ) {
       jdbcType = java.sql.Types.CLOB;
     } else if ("dbclob".equals(type) ) {
       jdbcType = java.sql.Types.LONGVARBINARY;
     }
	  return jdbcType;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param i
	 */
	public void setCodepage(int i) {
		codepage = i;
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
	 * @param i
	 */
	public void setLength(int i) {
		length = i;
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
	 * @param i
	 */
	public void setPrecision(int i) {
		precision = i;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param i
	 */
	public void setScale(int i) {
		scale = i;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setType(String string) {
		type = string;
	}

   /**  Override so we can print the values in a nice textual format.
    * @return String  Formatted output of all the instance variables.
    */
   public String toString() {
     return Utils.formatAsString(this);
   }

}
