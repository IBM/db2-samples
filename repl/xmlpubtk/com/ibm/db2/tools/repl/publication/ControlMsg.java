package com.ibm.db2.tools.repl.publication;

import javax.jms.*;
import java.util.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;

/**
 * The ControlMsg class represents a message that is sent to a QCapture program.
 * The message is a request for QCapture to perform a certain operation.
 *
 * @author tjacopi
 *
 */
public abstract class ControlMsg {

   /**  This will send the msg to the
   *    the specified messageProducer (MQ queue).  Nothing is done to the MessageProducer other
   *    than sending the message.  An exception is thrown if there is an error.
   *    This is the preferred way of sending a message, since it lets the caller manage the
   *    queue and session.
   * @param   session      The session that was used to create the MessageProducer.  Used to create a new
   *                         text message.
   * @param   msgProducer  The message is sent here.
   */
   public void send(Session session, MessageProducer msgProducer) throws Exception {
     validate();                                            // Insure everything is specified
     String xmlMsg = getXML();                              // Then get the xml document
     if (xmlMsg != null) {
       TextMessage msg = session.createTextMessage(xmlMsg); // Make a JMS text message around the document
//     System.out.println("Text of message to send is: ");
//     System.out.println(xmlMsg);
       if (msgProducer instanceof QueueSender) {
         ((QueueSender) msgProducer).send(msg);
       } else {
         ((TopicPublisher) msgProducer).publish(msg);
       }
     } else {
       throw new Exception("No xml was created by the ControlMsg");
     }
   }


   /**  This will send the msg to the specified queue manager and queue.
   *    A connection to the queue is created, the message sent, and the connection destroyed.
   *    This is very inefficient if there are many control messages to be sent.
   *    An exception is thrown if there is an error.
   * @param   session      The session that was used to create the MessageProducer.  Used to create a new
   *                         text message.
   * @param   msgProducer  The message is sent here.
   */
   public void send(String qMgrName, String qName) throws Exception {
     Exception error = null;
     MQQueueConnectionFactory  factory = new MQQueueConnectionFactory();
     factory.setQueueManager( qMgrName );
     QueueConnection connection = factory.createQueueConnection();
     connection.start();
     QueueSession qsession = connection.createQueueSession( false, Session.AUTO_ACKNOWLEDGE);
     Queue queue  = qsession.createQueue( qName );
     QueueSender   queueSender = qsession.createSender( queue );
     try {                                    // Enclose in try/catch so we can close the connection
       send(qsession, queueSender);           // Send the actual message
     } catch(Exception e) {
       error = e;
     }
     connection.close();                       // Close it now that we are done

     if (error != null) {                      // Now...if we had an error
       throw error;                            // ..we can throw it again since the connection is closed.
     }

   }


   /**
    * This will valiadate that everything is present for the xml document to be created.  It
    * will throw an exception if something is not valid.
    */
   protected void validate() throws Exception {
     ;   // No validation required
   }


   /**
    * This will create the xml document and return it
    * @return String  The xml document for the message.
    */
   protected String getXML() {
     StringBuffer sb  = new StringBuffer(200);
     generateXML(sb);
     return sb.toString();
   }

   /**
    * Actually create the xml.
    * @param xmlDocument   Generate the xml here.
    */
   protected void generateXML(StringBuffer xmlDocument) {
     xmlDocument.insert(0, "<?xml version=\"1.0\" encoding=\"UTF-8\" ?> \n <msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"  xsi:noNamespaceSchemaLocation=\"mqsub.xsd\" version=\"1.0.0\"> ");
     xmlDocument.append("</msg>");
   }


   /**  Override so we can print the values in a nice textual format.
    * @return String  Formatted output of all the instance variables.
    */
   public String toString() {
     return Utils.formatAsString(this);
   }


}
