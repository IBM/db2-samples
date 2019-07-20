package com.ibm.db2.tools.repl.publication;

import java.util.Vector;

/**
 * A RowOperationMsg contains one insert, update, or delete operation from the source table.
 *
 * @author tjacopi
 */
public class RowOperationMsg extends DataMsg {
	protected boolean isLast = false;
	protected String commitLSN = null;
	protected String commitTime = null;
	protected String authID    = null;
	protected String correlationID = null;
	protected String planName = null;
	protected Row row = null;

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
    * LOB messages are following, this is false.
    *
	 * @return boolean  True : This is the last message.  False : other messages (LOBMsg) are following.
	 */
	public boolean isLast() {
		return isLast;
	}

	/**
    * Get the updated row.
    *
	 * @return Row  The updated row.
	 */
	public Row getRow() {
		return row;
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
	 * @param string
	 */
	public void setCommitTime(String string) {
		commitTime = string;
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
	public void setRow(Row aRow) {
		row  = aRow;
	}

}
