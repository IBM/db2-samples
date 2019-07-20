package com.ibm.db2.tools.repl.publication;


/**
 * The QCapture program sends an ErrorReportMsg when it cannot perform the request of
 * a user application that was made through a control message.  For example, the Q Capture
 * programs send an error report message if it cannot activate or deactivate an XML Publication.
 *
 * @author tjacopi
 *
 */
public class ErrorReportMsg extends InformationalMsg {
	protected String subscriptionName = null;
	protected String srcOwner = null;
	protected String srcName = null;
	protected String msgText = null;

	/**
    * Returns the text of the error message.
	 * @return String  The text of the error message.
	 */
	public String getMsgText() {
		return msgText;
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
	 * @param string
	 */
	public void setMsgText(String string) {
		msgText = string;
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
