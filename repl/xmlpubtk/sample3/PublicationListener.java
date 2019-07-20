import com.ibm.db2.tools.repl.publication.*;
import com.ibm.db2.tools.repl.publication.support.*;
import javax.jms.*;
import java.util.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.mq.jms.MQTopicConnectionFactory;


/**
 * The PublicationListener class sets up access to MQ and listens for messages via the XML Publication toolkit.
 *
 * @author tjacopi
 *
 */
public class PublicationListener implements PublicationMsgListener  {

   protected volatile PublicationDataModel updates = new PublicationDataModel();
   protected volatile Object latch = new Object();
   protected volatile boolean bStop = false;

   protected String qMgrName = null;
   protected String qName = null;
   protected String topicName = null;


   public PublicationListener(String aQueueMgrName, String aQueueName, String aTopicName) {
     qMgrName = aQueueMgrName;
     qName = aQueueName;
     topicName = aTopicName;
   }


	/**
    * Start listening to the queue.  This will create a new thread to do
    * the listening, and return after the thread starts.
	 */
   public void start() {
     bStop = false;
     QListenerThread thread = new QListenerThread();
     thread.start();
   }

	/**
    * Stop listening to the queue.  This will set a stop flag and just return.  The
    * listener thread will stop within 10 seconds.
	 */
   public void stop() {
     bStop = true;
   }


	/**
    * Get all the current updates.  This will retrieve all the updates since the last getUpdates()
    * call, and reset the updates.  The method is threadsafe, and can be called from any thread.
    * @return PublicationDataModel   All the updates.
	 */
   public PublicationDataModel getUpdates() {
     PublicationDataModel dm = null;
     synchronized(latch) {                             // Lock to keep out any new publicationMsg notifications
       dm = updates;                                   // ..get old updates...
       updates = new PublicationDataModel();           // ..and reset for new updates
     }
     return dm;
   }

	/**
    * This is called by the publicationListener whenever a new publication msg is received.
    * @param  pubMsg  The publiction message.
	 */
   public void publicationMsg(Msg pubMsg) {
     System.out.println("msg received of type " + pubMsg.getClass().getName());

     if (pubMsg instanceof TransactionMsg) {
       TransactionMsg tm = (TransactionMsg) pubMsg;
       synchronized(latch) {                           // Lock to keep out getUpdates() call
         updates.add(tm);                              // Add the values in the msg to our stored updates
       }

     } else if (pubMsg instanceof RowOperationMsg) {
       RowOperationMsg rm = (RowOperationMsg) pubMsg;
       synchronized(latch) {                           // Lock to keep out getUpdates() call
         updates.add(rm);                              // Add the values in the msg to our stored updates
       }
     };

   }


   class QListenerThread extends Thread {
     public void run() {
      try {
        MessageConsumer messageConsumer = null;

        if (qName != null) {
          System.out.println("Connect to queue " + qName + " in queue manager " + qMgrName);
          // Create the JMS MQ objects to read from the queue
          MQQueueConnectionFactory factory = new MQQueueConnectionFactory();
          factory.setQueueManager( qMgrName );
          QueueConnection connection = factory.createQueueConnection();
          connection.start();
          QueueSession session = connection.createQueueSession( false, Session.AUTO_ACKNOWLEDGE);
          Queue receiveQueue = session.createQueue( qName);
          QueueReceiver queueReceiver = session.createReceiver( receiveQueue, null );
          messageConsumer = queueReceiver;
        } else {
          System.out.println("Connect to topic " + topicName + " in queue manager " + qMgrName);
          // Create the JMS MQ objects to read from the queue
          MQTopicConnectionFactory  factory = new MQTopicConnectionFactory();
          factory.setQueueManager( qMgrName );
          TopicConnection connection = factory.createTopicConnection();
          connection.start();
          TopicSession session = connection.createTopicSession( false, Session.AUTO_ACKNOWLEDGE);
          Topic topic        = session.createTopic( topicName );
          TopicSubscriber topicSubscriber = session.createSubscriber( topic);
          messageConsumer = topicSubscriber;
        }

        // Create the PublicationMsgProvider which will listen to the queue, parse the xml messages,
        // and dispatch them to us.
        PublicationMsgProvider msgProvider = PublicationMsgProviderFactory.createPublicationMsgProvider();
        msgProvider.addPublicationMsgListener(PublicationListener.this);   // Notify us of any messages
        while (!bStop) {
          msgProvider.dispatchMsgs(messageConsumer, 10000, true);          // Dispatch with a 10 sec timeout
        }                                                                  //   true = ignore errors.

      } catch ( Exception caught ) {
        System.out.println("QListenerThread Caught " + caught);
        caught.printStackTrace();
      }
    }
  }
}
