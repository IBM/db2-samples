package com.ibm.db2.tools.repl.publication;

/**
 * This message is sent whenever QCapture deactivates an XML Publication.
 *
 * @author tjacopi
 */
public class SubscriptionDeactivatedMsg extends InformationalMsg {
   protected String subscriptionName = null;
   protected String srcOwner = null;
   protected String srcName = null;
   protected String stateInformation = null;

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
    * Additional information regarding the state of the XML publication.  This may contain an ASN message number.
    * @return String  Additional information.
    */
   public String getStateInformation() {
      return stateInformation;
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
   public void setStateInformation(String string) {
      stateInformation = string;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param string
    */
   public void setSubscriptionName(String string) {
      subscriptionName = string;
   }

}

