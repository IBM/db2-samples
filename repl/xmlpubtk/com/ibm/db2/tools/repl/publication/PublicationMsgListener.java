package com.ibm.db2.tools.repl.publication;

/**
 * A PublicationMsgListener is how a PublicationMsgProvider notifies when a message is received.
 *
 * @author tjacopi
 */
public interface PublicationMsgListener {

   /**
    * Notify the caller of a publication message.
    *   @param  pubMsg    The message.
    */
   public void publicationMsg(Msg pubMsg);

}
