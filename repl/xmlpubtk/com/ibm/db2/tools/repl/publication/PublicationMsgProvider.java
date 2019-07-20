package com.ibm.db2.tools.repl.publication;

import javax.jms.MessageConsumer;

/**
 * A PublicationMsgProvider is the interface that defines how messages are created and produced.
 * The caller creates an instance of a PublicationMsgProvider by using the PublicationMsgProviderFactory
 * class.  Once you have an instance, then add a listener to the provider and call dispatchMsgs.
 * Note that dispatchMsgs is a synchronous call, so you might want to create a new thread
 * to call dispatchMsgs.
 *
 * @author tjacopi
 *
 */
public interface PublicationMsgProvider {

   /**
    * This will start the messages to be dispatched to any listeners.  The thread that calls this
    * function will not return until some other thread calls stopMsgDispatching() or the timeout value
    * is reached.
    *   @param  messageConsumer   Dispatch messages from this JMS message queue.
    *   @param  timeout    The time in milliseconds before the thread returns and stops dispatching msgs.
    *   @param  ignoreErrors  True:  Ingore any errors when dispatching & formatting msgs.  Any msg
    *                                that contains an error will be thrown away.
    *                         False: Throw exception on any msg errors.
    */
   public void dispatchMsgs(MessageConsumer messageConsumer, int timeout, boolean ignoreErrors) throws Exception;

   /**
    * This will stop the dispatching of messages, and cause the thread to return from dispatchMsgs().
    */
   public void stopMsgDispatching();

   /**
    * Add a listener to get the messages.
    *   @param  listener  The listener will be notified of all msgs.
    */
   public void addPublicationMsgListener(PublicationMsgListener listener);

   /**
    * Remove a listener.
    *   @param  listener  The listener to remove.
    */
   public void removePublicationMsgListener(PublicationMsgListener listener);


}
