package com.ibm.db2.tools.repl.publication;

import javax.jms.*;
import java.util.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;

/**
 * The InvalidateSendQueueMsg sends a message to QCapture asking it to invalidate the send
 * queue and perform the error action specified in the publication.
 *
 * <p>
 * An example of sending a message:
 * <p>
 * <blockquote><pre>
 *   try {
 *     ControlMsg msg = new InvalidateSendQueueMsg("SendQueueName");
 *     msg.send("QueueMgrName", "AdminQueueName");
 *   } catch (Exception e) {
 *     System.out.println("Message failed...error " + e);
 *   }
 * </pre></blockquote>
 * This will send a message on the "AdminQueueName" on queue manager "QueueMgrName" to
 * invalidate the "SendQueueName" at the QCapture program.
 *
 * @author tjacopi
 *
 */
public class InvalidateSendQueueMsg extends ControlMsg {
  protected String qName = null;

  /**
   * Craste a new InvalidateSendQueueMsg.  The message is not sent until the send() message is called.
   * @param qName   The name of the send queue to invalidate.
   */
  public InvalidateSendQueueMsg(String qName) {
    this.qName = qName;
  }

  /**
   * Get the send queue name.
   * @return String The name of the send queue to invalidate.
   */
  public String getQueueName() {
    return qName;
  }

  /**
   * Set the send queue name.
   * @param qName   The name of the send queue to invalidate.
   */
  public void setQueueName(String qName) {
    this.qName = qName;
  }


  /**
   * This will valiadate that everything is present for the xml document to be created.  It
   * will throw an exception if something is not valid.
   */
  protected void validate() throws Exception {
    if (qName == null || qName.length() == 0 ) {                // Insure we have a queue name
      throw new Exception("A queue name must be specified for an InvalidateSendQueueMsg");
    };
  }

  /**
   * Actually create the xml.
   * @param xmlDocument   Generate the xml here.
   */
  protected void generateXML(StringBuffer xmlDocument) {
    xmlDocument.append("<invalidateSendQ sendQName=\"");
    xmlDocument.append(qName);
    xmlDocument.append("\"/>");
    super.generateXML(xmlDocument);                             // Have our parent do its stuff
  }

}
