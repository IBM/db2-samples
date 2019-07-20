/*
 * Created on Mar 25, 2004
 *
 * To change the template for this generated file go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
package com.ibm.db2.tools.repl.publication;

/**
 * @author tjacopi
 *
 * To change the template for this generated type comment go to
 * Window&gt;Preferences&gt;Java&gt;Code Generation&gt;Code and Comments
 */
public class LOBMsg extends DataMsg {
   protected String subscriptionName = null;
	protected boolean isLast = false;
	protected String srcOwner = null;
	protected String srcName = null;
	protected int    rowNumber = 0;
	protected String columnName = null;
	protected int    totalDataLength = 0;
	protected int    segmentLength = 0;
	protected Object value = null;
	protected String lobType = null;
	
	/**
    *  The name of the LOB column.
	 * @return The name of the column.
	 */
	public String getColumnName() {
		return columnName;
	}

	/**
    * If this is the last LOB message, then this is true.
	 * @return True: The last LOB message.  False : more LOB messages are coming.
	 */
	public boolean isLast() {
		return isLast;
	}

	/**
    * The datatype of the LOB.
	 * @return String   One of "blob", "clob", or "dbclob".
	 */
	public String getLobType() {
		return lobType;
	}

	/**
    * The value of the LOB.
	 * @return Object  The LOB data.
	 */
	public Object getValue() {
		return value;
	}

	/**
    * Within the database transaction, the position number of the row operation that contains the LOB value.
	 * @return int  The position number.
	 */
	public int getRowNumber() {
		return rowNumber;
	}

	/**
    * The length of the LOB value contained in a single message, in bytes.
	 * @return int  The number of LOB bytes in just this message.
	 */
	public int getSegmentLength() {
		return segmentLength;
	}

	/**
    * Returns the name of the source db object (table, view, etc...).
	 * @return String  The source name.
	 */
	public String getSrcName() {
		return srcName;
	}

	/**
    * Returns the owner of the source db object (table, view, etc...).
	 * @return String  The owner name.
	 */
	public String getSrcOwner() {
		return srcOwner;
	}

	/**
    * The length of the total LOB value contained in the source table, in bytes.
	 * @return int  The number of bytes of the LOB value.
	 */
	public int getTotalDataLength() {
		return totalDataLength;
	}

  /**
    * Returns the name of the XML Publication.
	 * @return String  The publication name.
   */
  public String getSubscriptionName() {
    return subscriptionName;
  }

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setColumnName(String string) {
		columnName = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param b
	 */
	public void setLast(boolean b) {
		isLast = b;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param i
	 */
	public void setLobType(String strLobType) {
		lobType = strLobType;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param bs
	 */
	public void setValue(Object obj) {
		value = obj;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param i
	 */
	public void setRowNumber(int i) {
		rowNumber = i;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param i
	 */
	public void setSegmentLength(int i) {
		segmentLength = i;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setSrcName(String string) {
		srcName = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setSrcOwner(String string) {
		srcOwner = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param i
	 */
	public void setTotalDataLength(int i) {
		totalDataLength = i;
	}

   /**
    * This method has no effect when used by a PublicationListener.
    * @param string
    */
   public void setSubscriptionName(String string) {
     subscriptionName = string;
   }

}
