package com.ibm.db2.tools.repl.publication;

import javax.jms.*;
import java.util.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;

/**
 * The DeactivateSubscriptionMsg sends a message to QCapture asking it to invalidate the send
 * queue and perform the error action specified in the publication.
 *
 * <p>
 * An example of sending a message:
 * <p>
 * <blockquote><pre>
 *   try {
 *     ControlMsg msg = new DeactivateSubscriptionMsg("SubscriptionName");
 *     msg.send("QueueMgrName", "AdminQueueName");
 *   } catch (Exception e) {
 *     System.out.println("Message failed...error " + e);
 *   }
 * </pre></blockquote>
 * This will send a message on the "AdminQueueName" on queue manager "QueueMgrName" to
 * deactivate the subscription "SubscriptionName" at the QCapture program.
 *
 * @author tjacopi
 *
 */
public class DeactivateSubscriptionMsg extends ControlMsg {
  protected String subscriptionName = null;

  /**
   * Create a new DeactivateSubscriptionMsg.  The message is not sent until the send() message is called.
   * @param subscriptionName   The name of the subscription.
   */
  public DeactivateSubscriptionMsg(String subscriptionName) {
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
      throw new Exception("A queue name must be specified for an DeactivateSubscriptionMsg");
    };
  }

  /**
   * Actually create the xml.
   * @param xmlDocument   Generate the xml here.
   */
  protected void generateXML(StringBuffer xmlDocument) {
    xmlDocument.append("<deactivateSub subName=\"");
    xmlDocument.append(subscriptionName);
    xmlDocument.append("\"/>");
    super.generateXML(xmlDocument);                             // Have our parent do its stuff
  }

}
