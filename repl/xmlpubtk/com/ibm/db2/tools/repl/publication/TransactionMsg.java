package com.ibm.db2.tools.repl.publication;

import java.util.Vector;

/**
 * A TransactionMsg contains one or more insert, update, or delete row operations on the source table.
 * The TransactionMsg also contains information about the time theat the transaction was committed at the source
 * database, and a time based log sequence number.
 *
 * @author tjacopi
 *
 */
public class TransactionMsg extends DataMsg {
	protected boolean isLast = false;
	protected int segmentNumber = 0;
	protected String commitLSN = null;
	protected String commitTime = null;
	protected String authID    = null;
	protected String correlationID = null;
	protected String planName = null;
	protected Vector rows = null;

	/**
    * The Commit Logical Sequence Number of the transaction.
	 * @return String  The LSN of the transaction.
	 */
	public String getCommitLSN() {
		return commitLSN;
	}

	/**
    * The timestamp of the commit statement using GMT.
	 * @return String The commit timestamp.
	 */
	public String getCommitTime() {
		return commitTime;
	}

	/**
    * Get the authorization id that caused the database modification.  This
    * may be null if not avaiable from the datasource.
	 * @return String The authorization ID, or null if not available.
	 */
	public String getAuthID() {
		return authID;
	}

	/**
    * Get the correlation id that caused the database modification (DB2 z/OS only).  This
    * may be null if not avaiable from the datasource.
	 * @return String The correlation ID, or null if not available.
	 */
	public String getCorrelationID() {
		return correlationID;
	}

	/**
    * Get the plan name that caused the database modification (DB2 z/OS only).  This
    * may be null if not avaiable from the datasource.
	 * @return String The plan name, or null if not available.
	 */
	public String getPlanName() {
		return planName;
	}

	/**
    * A boolean value that indicates if this message is the last message in the transaction.  If
    * any LOB messages or other TransactionMsgs are following, this is false.
    *
	 * @return boolean  True : This is the last message.  False : other messages are following.
	 */
	public boolean isLast() {
		return isLast;
	}

	/**
    * Get the modified rows.
	 * @return Vector  A list of the modified Row objects.
	 */
	public Vector getRows() {
		return rows;
	}

	/**
    * A positive integer that indicates the message's segment number in a divided transaction message.
	 * @return int  The segment number.
	 */
	public int getSegmentNumber() {
		return segmentNumber;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setCommitLSN(String string) {
		commitLSN = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setCommitTime(String string) {
		commitTime = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setAuthID(String string) {
		authID = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setCorrelationID(String string) {
		correlationID = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setPlanName(String string) {
		planName = string;
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
	 * @param vector
	 */
	public void setRows(Vector vector) {
		rows = vector;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param i
	 */
	public void setSegmentNumber(int i) {
		segmentNumber = i;
	}

}
