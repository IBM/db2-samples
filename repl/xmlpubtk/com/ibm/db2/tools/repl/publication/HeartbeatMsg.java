package com.ibm.db2.tools.repl.publication;

/**
 * The HeartbeatMsg is sent by the QCapture program to tell that QCapture is still running.  The
 * HeartbeatMsg is optional, and is specified when the capture control tables are defined.
 * The QCaptupre program puts this msg on the queue when the heartbeat interval is reached, and
 * no other messages have been put on the queue.
 *
 * @author tjacopi
 */
public class HeartbeatMsg extends InformationalMsg {
  protected String sendQueueName = null;
  protected String lastCommitTime = null;

  /**
    * The timestamp (in GMT) of the last committed transaction.  May be null if no committed transactions.
	 * @return String The timestamp of the last committed transaction (or null if none).
   */
  public String getLastCommitTime() {
     return lastCommitTime;
  }

  /**
    * Returns the name of the send queue (the name of the queue on the capture server) that this
    * msg was placed.
	 * @return String  The send queue name.
   */
  public String getSendQueueName() {
     return sendQueueName;
  }

  /**
    * This method has no effect when used by a PublicationListener.
   * @param string
   */
  public void setLastCommitTime(String string) {
     lastCommitTime = string;
  }

  /**
    * This method has no effect when used by a PublicationListener.
   * @param string
   */
  public void setSendQueueName(String string) {
     sendQueueName = string;
  }

}
