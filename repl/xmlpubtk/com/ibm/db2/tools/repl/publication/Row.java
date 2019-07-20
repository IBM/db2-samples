package com.ibm.db2.tools.repl.publication;

import java.util.Vector;

/**
 * The Row class reprenents one row that was published.  The getOperation() method on the row allows
 * the caller to find out what happened to the row (Insert, Update, or Delete).  The all the
 * actual data values are stored in the columns, which are retrieved via the "getColumns()" method.
 *
 * @author tjacopi
 *
 */
public class Row {
  public static final int InsertOperation = 1;       // Row was used in an insert
  public static final int DeleteOperation = 2;       // Row was used in a delete
  public static final int UpdateOperation = 3;       // Row was used in an update

  protected String  srcOwner = null;
  protected String  srcName = null;
  protected String  subscriptionName = null;
  protected int     rowNumber = 0;
  protected boolean hasLOBColumns = false;
  protected Vector  columns = null;
  protected int     rowOperation   = InsertOperation;


  /**
   * Fetch all the columns that are a part of this row.
   *
   * @return Vector A vector of Column objects.
   */
  public Vector getColumns() {
    return columns;
  }

  /**
   * Does this row have any LOB columns?
   *
   * @return boolean  true:  has lob columns.  false:  does not.
   */
  public boolean hasLOBColumns() {
  	 return hasLOBColumns;
  }

  /**
   * Return the row number.
   *
   * @return int  The row number.
   */
  public int getRowNumber() {
    return rowNumber;
  }

  /**
   * This is how the row was used in the transaction.
   *
   * @return int One of the following values: InsertOperation, DeleteOperation, UpdateOperation.
   */
  public int getRowOperation() {
     return rowOperation;
  }

  /**
   * The name of the source table.
   *
   * @return String Source table name
   */
  public String getSrcName() {
     return srcName;
  }

  /**
   * The owner name of the source table.
   *
   * @return String Source owner name
   */
  public String getSrcOwner() {
     return srcOwner;
  }

  /**
   * The subscription name.
   *
   * @return String Subscription name
   */
  public String getSubscriptionName() {
    return subscriptionName;
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
   * @param b
   */
  public void setHasLOBColumns(boolean b) {
     this.hasLOBColumns = b;
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
  public void setRowOperation(int i) {
     rowOperation = i;
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

  /**  Override so we can print the values in a nice textual format.
   * @return String  Formatted output of all the instance variables.
   */
  public String toString() {
    return Utils.formatAsString(this);
  }

}
