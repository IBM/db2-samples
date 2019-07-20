package com.ibm.db2.tools.repl.publication;

import java.util.Vector;

/**
 * The SubscriptionSchemaMsg is sent whenever QCapture activates
 * or reinitializes an XML publication.
 *
 * @author tjacopi
 */
public class SubscriptionSchemaMsg extends InformationalMsg {
	protected String  subscriptionName = null;
	protected String  srcOwner = null;
	protected String  srcName = null;
	protected String  sendQueueName = null;
	protected boolean allChangedRows = false;
	protected boolean beforeValues = false;
	protected boolean onlyChangedCols = false;
	protected String  loadPhase = null;
	protected String  db2ServerType = null;
	protected String  db2ReleaseLevel = null;
	protected String  db2InstanceName = null;
	protected String  qCaptureReleaseLevel = null;
	protected Vector  columns = null;
	
	/**
    * Indicates if the ALL_CHANGED_ROWS option was specified in the XML Publication definition.
	 * @return  True : The ALL_CHANGED_ROWS option was specified.  False : it was not.
	 */
	public boolean isAllChangedRows() {
		return allChangedRows;
	}

	/**
    * Indicates if the BEFORE_VALUES option was specified in the XML Publication definition.
	 * @return  True : The BEFORE_VALUES option was specified.  False : it was not.
	 */
	public boolean isBeforeValues() {
		return beforeValues;
	}

	/**
    * Returns a list of ColumnSchema objects that describe the columns of the source table.
	 * @return Vector  A vector of ColumnSchema objects.
	 */
	public Vector getColumns() {
		return columns;
	}

	/**
    * Returns the name of the DB2 instance.
	 * @return String  The DB2 instance name.
	 */
	public String getDb2InstanceName() {
		return db2InstanceName;
	}

	/**
    * Returns the type of the DB2 server (QDB2, QDB2/6000, etc..)
	 * @return String  The DB2 server type.
	 */
	public String getDb2ServerType() {
		return db2ServerType;
	}

	/**
    * Returns the current release level of the DB2 server (8.2, etc..)
	 * @return String  The DB2 server release level.
	 */
	public String getDb2ReleaseLevel() {
		return db2ReleaseLevel;
	}

	/**
    * Returns the load phase option.  One of the following ("none", "external")
	 * @return String  The load phase.
	 */
	public String getLoadPhase() {
		return loadPhase;
	}

	/**
    * Indicates if the CHANGED_COLS_ONLY option was specified in the XML Publication definition.
	 * @return  True : The CHANGED_COLS_ONLY option was specified.  False : it was not.
	 */
	public boolean isOnlyChangedCols() {
		return onlyChangedCols;
	}

	/**
    * Returns the current release level of the QCapture program (8.2, etc..)
	 * @return String  The QCapture release level.
	 */
	public String getQCaptureReleaseLevel() {
		return qCaptureReleaseLevel;
	}

	/**
    * Returns the name of the send queue (the name of the queue on the capture server).
	 * @return String  The send queue name.
	 */
	public String getSendQueueName() {
		return sendQueueName;
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
    * Returns the name of the XML Publication.
	 * @return String  The publication name.
	 */
	public String getSubscriptionName() {
		return subscriptionName;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param b
	 */
	public void setAllChangedRows(boolean b) {
		allChangedRows = b;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param b
	 */
	public void setBeforeValues(boolean b) {
		beforeValues = b;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param vector
	 */
	public void setColumns(Vector vector) {
		columns = vector;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setDb2InstanceName(String string) {
		db2InstanceName = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setDb2ReleaseLevel(String string) {
		db2ReleaseLevel = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setDb2ServerType(String string) {
		db2ServerType = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setLoadPhase(String string) {
		loadPhase = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param b
	 */
	public void setOnlyChangedCols(boolean b) {
		onlyChangedCols = b;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setQCaptureReleaseLevel(String string) {
		qCaptureReleaseLevel = string;
	}

	/**
    * This method has no effect when used by a PublicationListener.
	 * @param string
	 */
	public void setSendQueueName(String string) {
		sendQueueName = string;
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
	 * @param string
	 */
	public void setSubscriptionName(String string) {
		subscriptionName = string;
	}

}
