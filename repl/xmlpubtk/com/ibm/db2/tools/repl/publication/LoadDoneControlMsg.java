package com.ibm.db2.tools.repl.publication;

import javax.jms.*;
import java.util.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;

/**
 * The LoadDoneControlMsg sends a message to QCapture informing it that the target table
 * is loaded.
 *
 * <p>
 * An example of sending a message:
 * <p>
 * <blockquote><pre>
 *   try {
 *     ControlMsg msg = new LoadDoneControlMsg("SubscriptionName");
 *     msg.send("QueueMgrName", "AdminQueueName");
 *   } catch (Exception e) {
 *     System.out.println("Message failed...error " + e);
 *   }
 * </pre></blockquote>
 * This will send a message on the "AdminQueueName" on queue manager "QueueMgrName" to
 * tell QCapture that the load is finished for the subscription.
 *
 * @author tjacopi
 *
 */
public class LoadDoneControlMsg extends ControlMsg {
  protected String subscriptionName = null;

  /**
   * Craste a new LoadDoneControlMsg.  The message is not sent until the send() message is called.
   * @param subscriptionName   The name of the subscription.
   */
  public LoadDoneControlMsg(String subscriptionName) {
    this.subscriptionName = subscriptionName;
  }

  /**
   * Get the subscription name.
   * @return String The name of the subscription.
   */
  public String getSubscriptionName() {
    return subscriptionName;
  }

  /**
   * Set the subscription name.
   * @param subscriptionName   The name of the subscription to activate.
   */
  public void setSubscriptionName(String subscriptionName) {
    this.subscriptionName = subscriptionName;
  }


  /**
   * This will valiadate that everything is present for the xml document to be created.  It
   * will throw an exception if something is not valid.
   */
  protected void validate() throws Exception {
    if (subscriptionName == null || subscriptionName.length() == 0 ) {                // Insure we have a queue name
      throw new Exception("A queue name must be specified for an LoadDoneControlMsg");
    };
  }

  /**
   * Actually create the xml.
   * @param xmlDocument   Generate the xml here.
   */
  protected void generateXML(StringBuffer xmlDocument) {
    xmlDocument.append("<loadDone subName=\"");
    xmlDocument.append(subscriptionName);
    xmlDocument.append("\"/>");
    super.generateXML(xmlDocument);                             // Have our parent do its stuff
  }

}
