package com.ibm.db2.tools.repl.publication;

/**
 * The AddColumnMsg is sent when the Q Capture programs add a column to an existing XML Publication.
 *
 * @author tjacopi
 */
public class AddColumnMsg extends InformationalMsg {
	protected String subscriptionName = null;
	protected String srcOwner = null;
	protected String srcName = null;
	protected ColumnSchema column = null;

	/**
    * Returns the column that was added to the publication.
    * @return ColumnSchema  The column that was added to the publication.
	 */
	public ColumnSchema getColumn() {
		return column;
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
	 * @param column
	 */
	public void setColumn(ColumnSchema column) {
		this.column = column;
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
