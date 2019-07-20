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

   protected volatile Hashtable updates = new Hashtable();
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
    * @return Hashtable  All the updates.  Key = fully qualified table name, Value = Count structure of updates.
	 */
   public Hashtable getUpdates() {
     Hashtable oldUpdates = null;
     synchronized(latch) {                            // Lock to keep out any new publicationMsg notifications
       oldUpdates = updates;                          // ..get old updates...
       updates = new Hashtable();                     // ..and reset for new updates
     }
     return oldUpdates;
   }


	/**
    * This is called by the publicationListener whenever a new publication msg is received.
    * @param  pubMsg  The publiction message.
	 */
   public void publicationMsg(Msg pubMsg) {
     System.out.println("msg received of type " + pubMsg.getClass().getName());

     // Check to see what kind of message we have
     if (pubMsg instanceof TransactionMsg) {
       TransactionMsg tm = (TransactionMsg) pubMsg;
       Vector rows = tm.getRows();                     // Get the changed rows
       synchronized(latch) {                           // Lock to keep the getUpdates() caller out
         for (int i=0; i<rows.size(); i++ ) {          // For each changed row...
           Row row = (Row) rows.elementAt(i);          // ..get it...
           processRow(row, tm.getDbName() );           // ..and save its changes...
         }
       }

     } else if (pubMsg instanceof RowOperationMsg) {
       RowOperationMsg rm = (RowOperationMsg) pubMsg;  // RowMessages only have one changed row.
       synchronized(latch) {                           // Lock to keep the getUpdates() caller out
         processRow(rm.getRow(), rm.getDbName() );     // Get the updated row, and save its changes
       }
     };
   }

	/**
    * This will take all the updates for the Row and add them to our saved values.
    * @param  r       The Row that has the updates.
    * @param  dbName  The database that the row is from.  Note that the Row object has the owner & table name.
	 */
   protected void  processRow(Row r, String dbName) {
     String id = dbName + "." + r.getSrcOwner() + "." + r.getSrcName();  // Build the qualified name
     Count count = (Count) updates.get(id);            // Look up its changes
     if (count == null) {                              // If no saved changes for this name...
       count = new Count();                            // ..then create a new entry
       updates.put(id, count);                         // ..and save it
     };
     int rowOperation = r.getRowOperation();                       // Get how the row is used...
     if (rowOperation == Row.UpdateOperation) {                    // ..and update the correct field.
       count.rowsUpdated++;
     } else if (rowOperation == Row.DeleteOperation) {
       count.rowsDeleted++;
     } else if (rowOperation == Row.InsertOperation) {
       count.rowsInserted++;
     }

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
        msgProvider.addPublicationMsgListener(PublicationListener.this);  // Notify us of any messages
        while (!bStop) {
          msgProvider.dispatchMsgs(messageConsumer, 10000, true);         // Dispatch with a 10 sec timeout
        }                                                                 //   true = ignore errors.

      } catch ( Exception caught ) {
        System.out.println("QListenerThread Caught " + caught);
        caught.printStackTrace();
      }
    }
  }
}
