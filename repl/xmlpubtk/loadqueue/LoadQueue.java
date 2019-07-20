import com.ibm.db2.tools.repl.publication.*;
import com.ibm.db2.tools.repl.publication.support.*;
import java.util.*;
import javax.jms.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;
import com.ibm.mq.jms.MQTopicConnectionFactory;



/**
 * A simple program to put a set of random XML Publication transaction messages on the queue.
 * The advantage of this is that you dont need to run replication just to develope & test your
 * toolkit application.
 *
 * @author tjacopi
 *
 */
public class LoadQueue  {

   public void go(String qMgrName, String qName, String topicName) {
      try {
        Random rand = new Random();

        MessageProducer messageProducer = null;
        Session session = null;

        if (qName != null) {
          System.out.println("Connect to queue " + qName + " in queue manager " + qMgrName);
          MQQueueConnectionFactory  factory = new MQQueueConnectionFactory();
          factory.setQueueManager( qMgrName );
          QueueConnection connection = factory.createQueueConnection();
          connection.start();
          QueueSession qsession = connection.createQueueSession( false, Session.AUTO_ACKNOWLEDGE);
          Queue queue  = qsession.createQueue( qName );
          QueueSender   queueSender = qsession.createSender( queue );
          messageProducer = queueSender;
          session = qsession;
          // Create the JMS MQ objects to read from the queue
        } else {
          System.out.println("Connect to topic " + topicName + " in queue manager " + qMgrName);
          MQTopicConnectionFactory  factory = new MQTopicConnectionFactory();
          factory.setQueueManager( qMgrName );
          TopicConnection connection = factory.createTopicConnection();
          connection.start();
          TopicSession tsession = connection.createTopicSession( false, Session.AUTO_ACKNOWLEDGE);
          Topic topic  = tsession.createTopic( topicName );
          TopicPublisher  topicPublisher = tsession.createPublisher( topic);
          messageProducer = topicPublisher;
          session = tsession;
        }

        TextMessage[] msg = new TextMessage[27];
        msg[0]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"JSINNOTT\" srcName=\"ADAM\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[1]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"TJACOPI\" srcName=\"STAFF\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[2]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"TJACOPI\" srcName=\"ORG\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[3]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"PICS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[4]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"CASH\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[5]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"CARS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[6]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"TERRIE\" srcName=\"CUBE1\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[7]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"TERRIE\" srcName=\"CUBE2\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[8]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <insertRow subName=\"ADAM0004\" srcOwner=\"KIRAN\" srcName=\"GROUPS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </insertRow>  </trans></msg>");
        msg[9]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"JSINNOTT\" srcName=\"ADAM\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[10]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"TJACOPI\" srcName=\"STAFF\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[11]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"TJACOPI\" srcName=\"ORG\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[12]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"PICS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[13]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"CASH\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[14]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"CARS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[15]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"TERRIE\" srcName=\"CUBE1\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[16]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"TERRIE\" srcName=\"CUBE2\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[17]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <updateRow subName=\"ADAM0004\" srcOwner=\"KIRAN\" srcName=\"GROUPS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </updateRow>  </trans></msg>");
        msg[18]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"JSINNOTT\" srcName=\"ADAM\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[19]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"TJACOPI\" srcName=\"STAFF\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[20]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"GREEN\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"TJACOPI\" srcName=\"ORG\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[21]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"PICS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[22]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"CASH\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[23]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"RED\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"MARTIN\" srcName=\"CARS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[24]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"TERRIE\" srcName=\"CUBE1\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[25]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"TERRIE\" srcName=\"CUBE2\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");
        msg[26]                 = session.createTextMessage("<?xml version=\"1.0\" encoding=\"UTF-8\" ?><msg xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\" xsi:noNamespaceSchemaLocation=\"mqcap.xsd\" version=\"1.0.0\" dbName=\"BLUE\">  <trans isLast=\"1\" segmentNum=\"1\" cmitLSN=\"0000:0000:0000:0986:7dbd\" cmitTime=\"2004-03-10T18:43:15.000001\">    <deleteRow subName=\"ADAM0004\" srcOwner=\"KIRAN\" srcName=\"GROUPS\">      <col name=\"KEY\" isKey=\"1\">        <integer>1</integer>      </col>      <col name=\"UPDATE\">        <varchar>first</varchar>      </col>      <col name=\"VALUE01\">        <integer>2</integer>      </col>      <col name=\"VALUE02\">        <integer>3</integer>      </col>    </deleteRow>  </trans></msg>");

        while (true) {
          int numMsgs = rand.nextInt(5);
          for (int i=0; i<numMsgs; i++ ) {
            int msgIndex = rand.nextInt(27);
            if (messageProducer instanceof QueueSender) {
              ((QueueSender) messageProducer).send(msg[msgIndex]);
            } else {
              ((TopicPublisher) messageProducer).publish(msg[msgIndex]);
            }
          }
          System.out.println("Placed " + numMsgs + " messages on the queue");
          try {
            Thread.currentThread().sleep(2000);
          } catch(Throwable t) {}
        }

      } catch ( Exception caught ) {
        System.out.println("load Caught " + caught);
        caught.printStackTrace();
      }
    }

  public static void main( String[] args )   {


    // Get the arguments the user passed in
    String qManager  = parseArgsFor("-qmgr", args);
    String qName = parseArgsFor("-queue", args);
    String topicName = parseArgsFor("-topic", args);

    // Insure qManager and either qName or topicName was specified
    if (qManager != null && (qName != null || topicName != null)  ) {
      LoadQueue test = new LoadQueue();
      test.go(qManager, qName, topicName);          // ...and invoke it
    } else {
      printHelp();
    }
    System.exit(0);
  }


  protected static void printHelp() {
    System.out.println("Usage:  java LoadQueue -qmgr <queueManager> (-queue <queue name> | -topic <topic name>) ");
    System.out.println("  example:  java LoadQueue -qmgr DefaultQMGR -queue myPubQ");
    System.out.println("          - or -       ");
    System.out.println("  example:  java LoadQueue -qmgr DefaultQMGR -topic myTopic");
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
