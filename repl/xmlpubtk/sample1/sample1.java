import com.ibm.db2.tools.repl.publication.*;
import javax.jms.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;

public class sample1 implements PublicationMsgListener  {

  private int totalModifiedRows = 0;

  public static void main( String[] args ) {
    String qManager  = parseArgsFor("-qmgr", args);
    String qName = parseArgsFor("-queue", args);
    if (qName != null && qManager != null ) {
      sample1 test = new sample1();                 // Just create an instance...
      test.go(qManager, qName);
    } else {
      printHelp();
    }
    System.exit(0);
  }


  public void go(String qMgrName, String qName) {
    try {
      System.out.println("Connect to queue " + qName + " in queue manager " + qMgrName);

      // Build the JMS objects requried to listen to a queue
      MQQueueConnectionFactory  factory = new MQQueueConnectionFactory();
      factory.setQueueManager( qMgrName );
      QueueConnection connection = factory.createQueueConnection();
      connection.start();
      QueueSession session = connection.createQueueSession( false, Session.AUTO_ACKNOWLEDGE);
      Queue receiveQueue = session.createQueue( qName );
      QueueReceiver queueReceiver = session.createReceiver( receiveQueue, null );

      // Create the PublicationMsgProvider which will listen to the queue, parse the xml messages,
      // and dispatch them to us.
      PublicationMsgProvider msgProvider = PublicationMsgProviderFactory.createPublicationMsgProvider();
      msgProvider.addPublicationMsgListener(this);           // Notify us of any messages
      msgProvider.dispatchMsgs(queueReceiver, 60000, true);  // Start dispatching with a 60 sec timeout
                                                             //   true = ignore errors.
    } catch ( Exception caught ) {
      System.out.println("sample1 Caught " + caught);
      caught.printStackTrace();
    }
  }

  /**
   * This is called whenever a msg is received.
   */
  public void publicationMsg(Msg pubMsg) {
    System.out.println("Msg is " + pubMsg.getClass().getName() );
    if (pubMsg instanceof RowOperationMsg) {
      totalModifiedRows++;                      // RowOperationMsg only have one row changed
      System.out.println("** Total rows modified = " + totalModifiedRows );
    } else if (pubMsg instanceof TransactionMsg) {
      totalModifiedRows = totalModifiedRows + ((TransactionMsg) pubMsg).getRows().size();
      System.out.println("** Total rows modified = " + totalModifiedRows );
    }
  }

  protected static void printHelp() {
    System.out.println("Usage:  java sample1 -qmgr <queueManager> -queue <queue name>");
    System.out.println("  example:  java sample1 -qmgr DefaultQMGR -queue myPubQ");
  }

  protected static String parseArgsFor(String argName, String[] args) {
    String argValue = null;
    for (int i =0; i<args.length-1 && argValue == null; i++) {
      if (argName.equals(args[i]) ) {
        argValue = args[i+1];
      }
    }
    return argValue;
  }
}
