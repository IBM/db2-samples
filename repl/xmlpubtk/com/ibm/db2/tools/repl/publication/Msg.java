package com.ibm.db2.tools.repl.publication;

import javax.jms.*;
import java.util.*;

/**
 * The Msg class is the base class for the hierarchy of XML publication messages.
 * All messages are a subclass of this class.  Generally, you need to cast the
 * object to the correct subclass.
 *
 * @author tjacopi
 *
 */
public abstract class Msg {

   protected static final String topicHeader = "topic://";
   protected String dbName = null;
   protected Message jmsMsg = null;

   /**  This allows access to the dbName attribute of the xml message
   * @return String   The database name
   */
   public String getDbName() {
     return dbName;
   }

   /**  Access the name of the topic that was specified during the definition of the xml publication.
   *    Note that the topic name in JMS has a header attached.  If you want to see the topic string
   *    exactly as it was given when defining the publication, you need to pass "true" so the header
   *    is removed.
   * @param   stripHeader   True: Remove the "topic://" header.  False:  Return complete JMS topic name
   * @return  String   The name of the topic.  Null if not specified.
   */
   public String getTopic(boolean stripHeader) {
     String topicName = null;
     if (jmsMsg != null) {
       try {
         Destination dest = jmsMsg.getJMSDestination();
         if (dest != null  && dest instanceof Topic) {
           topicName = ((Topic) dest).getTopicName();
           if (stripHeader && topicName.startsWith(topicHeader) ) {    // If the name starts with this header
             topicName = topicName.substring( topicHeader.length() );  // ..remove it (the caller can always get the JMS msg if they want)
           };
         }
       } catch(Throwable t) {
         System.out.println("Caught " + t + " when trying to access topic");
         t.printStackTrace();
       }
     };

     return topicName;
   }

   /** Access all the property names that are in the native MQ message.
   * @return Eumeration   A set of all the valid property names.
   */
   public Enumeration getPropertyNames() {
     Enumeration enum = null;
     try {
       if (jmsMsg != null) {
         enum = jmsMsg.getPropertyNames();
       };
     } catch(Throwable t) {}

     return enum;
   }

   /** Access a specific property in the native MQ message.
   * @return Object  The value of the property, or null if not defined.
   */
   public Object getObjectProperty(String propertyName) {
     Object property = null;
     try {
       if (jmsMsg != null) {
         property = jmsMsg.getObjectProperty(propertyName);
       };
     } catch(Throwable t) {}

     return property;
   }

   /** Access the navite JMS MQ message.
   * @return Message  The message
   */
   public Message getJMSMessage() {
     return jmsMsg;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param dbName  The name of the db
    */
   public void setDbName(String dbName) {
     this.dbName = dbName;
   }

   /**
    * This method has no effect when used by a PublicationListener.
    * @param m  The JMS message
    */
   public void setJMSMessage(Message m) {
     jmsMsg = m;
   }

   /**  Override so we can print the values in a nice textual format.
    * @return String  Formatted output of all the instance variables.
    */
   public String toString() {
     return Utils.formatAsString(this);
   }

}
