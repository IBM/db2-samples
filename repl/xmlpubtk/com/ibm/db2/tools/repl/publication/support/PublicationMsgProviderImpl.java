package com.ibm.db2.tools.repl.publication.support;
import java.io.*;
import java.util.*;

import org.xml.sax.*;
import org.xml.sax.helpers.DefaultHandler;

import javax.xml.parsers.SAXParserFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.parsers.SAXParser;
import com.ibm.db2.tools.repl.publication.*;

import javax.jms.BytesMessage;
import javax.jms.JMSException;
import javax.jms.Message;
import javax.jms.TextMessage;
import javax.jms.MessageEOFException;
import javax.jms.MessageConsumer;

/**
 * This class provides a concrete subclass of PublicationMsgProvider that will parse messages
 * and dispatch them.
 *
 * @author tjacopi
 */
public class PublicationMsgProviderImpl implements PublicationMsgProvider   {

   protected Vector listeners = new Vector();
   protected volatile boolean keepDispatching = true;
   protected PublicationParser parser = null;

   /**
    * Create a concrete subclass of PublicationMsgProvider that will parse messages and dispatch them.
    */
   public PublicationMsgProviderImpl() throws ParserConfigurationException, SAXException  {
     parser = new PublicationParser();
   }


   /**
    * This will start the messages to be dispatched to any listeners.  The thread that calls this
    * function will not return until some other thread calls stopMsgDispatching() or the timeout value
    * is reached.
    *   @param  messageConsumer  This is the JMS object that represents the queue that we will read from.
    *   @param  timeout    The time in milliseconds before the thread returns and stops dispatching msgs.
    *   @param  ignoreErrors  True:  Ingore any errors when dispatching & formatting msgs.  Any msg
    *                                that contains an error will be thrown away.
    *                         False: Throw exception on any msg errors.
    */
   public void dispatchMsgs(MessageConsumer messageConsumer, int timeout, boolean ignoreErrors) throws Exception {
     keepDispatching = true;

     while( keepDispatching ) {
        try {
           Message message = messageConsumer.receive( timeout );
           if ( message == null && timeout>0 ) {
             keepDispatching = false;
            } else {
              if (message instanceof TextMessage) {
                TextMessage textMessage = (TextMessage) message;
                Enumeration enumeration = textMessage.getPropertyNames();
                parseAndDispatchMsg(textMessage);
              };
            }
        } catch ( Exception caught ) {
          System.out.println("Caught " + caught);
          caught.printStackTrace();
          if (!ignoreErrors) {
            throw caught;
          } else {
            System.out.println("Ignoring exception " );
          }
        }
     }
   }

   /**
    * Now that we have a message, parse its xml, and notify all listeners about it.
    *   @param  jmsTextMessage  The message from MQ via JMS.
    */
   protected void parseAndDispatchMsg(TextMessage jmsTextMessage) throws Exception {
     String xmlMsg = jmsTextMessage.getText();
     if (xmlMsg != null) {
       Msg msg = parser.parse(xmlMsg);                  // Parse xml to create java objects
       if (msg != null) {                               // If we got a java object
         msg.setJMSMessage(jmsTextMessage);             // ..then dispatch it
         for (int i=0; i<listeners.size(); i++) {
           PublicationMsgListener listener = (PublicationMsgListener) listeners.elementAt(i);
           listener.publicationMsg(msg);
         }
       }
     } else {
       System.out.println("JMS text message has null body, ignoring it.");
     }
   }

   /**
    * This will stop the dispatching of messages, and cause the thread to return from dispatchMsgs().
    * The thread will stop after the next message, or if it timeouts.  Note that a thread that has
    * no timeout and never gets any messages will never stop (ie, this call does not stop the
    * thread from waiting in MQ).
    */
   public void stopMsgDispatching() {
     keepDispatching = false;
   }

   /**
    * Add a listener to get the messages.
    *   @param  listener  The listener will be notified of all msgs.
    */
   public void addPublicationMsgListener(PublicationMsgListener listener) {
     listeners.add(listener);
   }

   /**
    * Remove a listener.
    *   @param  listener  The listener to remove.
    */
   public void removePublicationMsgListener(PublicationMsgListener listener) {
     listeners.remove(listener);
   }

}
