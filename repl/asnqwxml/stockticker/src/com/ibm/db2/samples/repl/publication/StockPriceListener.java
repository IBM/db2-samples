/**
 * A Web Application Example based on Event Publishing
 *
 * (C) Copyright IBM Corporation 2004. All rights reserved.
 *
 * Application name: Stock Ticker
 *
 * Source file name: StockPriceListener.java
 *
 * Purpose:
 * This class owns the method that listens to incoming
 * messages from Q Capture on the specified queue and queue
 * manager and processes those messages. Stock price data 
 * will be extracted from transaction or row operation messages
 * and corresponding StockPrice objects will be created.
 * This class also maintains the status of the XML publication
 * based on the incoming message type.
 */

package com.ibm.db2.samples.repl.publication;

import java.util.*;
import java.math.BigDecimal;
import com.ibm.db2.tools.repl.publication.*;
import javax.jms.*;
import com.ibm.mq.jms.MQQueueConnectionFactory;

public class StockPriceListener implements PublicationMsgListener  
{

  //
  // Public static data
  //

  /** ACTIVE */
  public static String ACTIVE = "Active";

  /** INACTIVE */
  public static String INACTIVE = "Inactive";

  //
  // Private data
  //

  /** XML Publication State */
  protected volatile String xmlPubState = StockPriceListener.INACTIVE;;
    
  /** Stock Price Map */
  protected volatile Map stockPriceMap = new TreeMap();

  /** Latch object */
  protected volatile Object latch = new Object();

  /** stopped */
  protected volatile boolean stopped = true;

  /** qMgrName */
  protected String qMgrName = null;

  /** qName */
  protected String qName = null;

  /** topicName */
  protected String topicName = null;

  //
  // Public methods
  //

  /** main */
  public static void main( String[] args ) 
  {
  	StockPriceListener spListener = new StockPriceListener("QMSAMP", "Q1");
  	spListener.startListen();
  }


  /** Constructor */
  public StockPriceListener(String qMgrName, String qName)
  {
  	this.qMgrName = qMgrName;
  	this.qName = qName;
  	this.stopped = true;
  } // StockPriceListener()
			
			
	/** startListen
 	  *
    * Start listening to the queue.  This will create a new thread to do
    * the listening, and return after the thread starts.
	 */
  public void startListen() 
  {		
 		if (this.stopped)
  	{
     	this.stopped = false;
     	QListenerThread thread = new QListenerThread();
     	thread.start();
    }
  } // startListen()

	/** stopListen
	  *
    * Stop listening to the queue.  This will set a stop flag and just return.  The
    * listener thread will stop within 10 seconds.
	 */
  public void stopListen() 
  {
    this.stopped = true;
  } // stopListen


  /** publicationMsg
   *
   * This is called whenever a msg is received.
   * Set XML pub state to ACTIVE if the received message type is SubscriptionSchemaMsg,
   * TransactionMsg, or RowOperationMsg. Set the state to INACTIVE is the received
   * message type is SubscriptionDeactivatedMsg.
   * When a transaction or row operation message has been received, extract the row
   * operation type and stock price data for each row.
   * If it's an INSERT operation, then create a new StockPrice object and attach it
   * to the stock price map that holds all the stock price information to be displayed
   * on the web page.
   * If it's an UPDATE operation, then get the corresponding StockPrice object from 
   * the stock price map and update the stock price information.
   * If it's a DELETE operation, then remove the corresponding StockPrice object from
   * the stock price map.
   */
  public void publicationMsg(Msg pubMsg)
  {
    System.out.println("Msg received of type " + pubMsg.getClass().getName());
  	
    if (pubMsg instanceof SubscriptionSchemaMsg) 
    {
    	// Set XML Pub state
    	this.xmlPubState = StockPriceListener.ACTIVE;

    } // SubscriptionSchemaMsg
    else if (pubMsg instanceof TransactionMsg) 
    {
    	// Set XML Pub state
    	this.xmlPubState = StockPriceListener.ACTIVE;

			// Process trans msg
    	TransactionMsg transMsg = (TransactionMsg) pubMsg;

    	// Process rows
    	Vector rows = transMsg.getRows();

      synchronized(latch) 
      {
        for (int i=0; i<rows.size(); i++) 
        {
          Row row = (Row) rows.elementAt(i);
          this.processRow(row);
        }
      }	

    } // TransactionMsg
    else if (pubMsg instanceof RowOperationMsg) 
    {
    	// Set XML Pub state
    	this.xmlPubState = StockPriceListener.ACTIVE;

			// Process trans msg
    	RowOperationMsg rowOpMsg = (RowOperationMsg) pubMsg;
    	
    	// Process row
      synchronized(latch) 
      {
        this.processRow(rowOpMsg.getRow());
      }
      	
    } // RowOperationMsg
    else if (pubMsg instanceof SubscriptionDeactivatedMsg) 
    {
    	// Set XML Pub state
    	this.xmlPubState = StockPriceListener.INACTIVE;

    } // SubscriptionDeactivatedMsg

  } // publicationMsg


  /** processRow */
	protected void processRow(Row row)
	{
    String symbol = null, ccy = null, tradingDate = null, tradingTime = null;
    BigDecimal openingPrice = null, tradingPrice = null;
    
		int rowOp = row.getRowOperation();
		Vector cols = row.getColumns();

		// Process columns
    for (int i=0; i<cols.size(); i++) 
    {
      Column col = (Column) cols.elementAt(i);
      String colName = col.getName();

   		// Prepare values for StockPrice
			if (colName.equals("SYMBOL"))
			{
				symbol = (String) col.getValue();
			}
			else if (colName.equals("CCY"))
			{
				ccy = (String) col.getValue();
			}
			else if (colName.equals("TRADING_DATE"))
			{
				tradingDate = (String) col.getValue();
			}
			else if (colName.equals("OPENING_PRICE"))
			{
				openingPrice = (BigDecimal) col.getValue();
			}
			else if (colName.equals("TRADING_PRICE"))
			{
				tradingPrice = (BigDecimal) col.getValue();
			}
			else if (colName.equals("TRADING_TIME"))
			{
				tradingTime = (String) col.getValue();
			}
			
    } // for each col

   	// Build map key
   	String mapKey = ccy + symbol + tradingDate;

   	// Update hash table
		if (rowOp == Row.InsertOperation)
		{
			// Add stock price info into the hash table
			StockPrice stockPrice = new StockPrice(symbol, ccy, tradingDate, openingPrice, tradingPrice, tradingTime);
			this.stockPriceMap.put(mapKey, stockPrice);  
		}
		else if (rowOp == Row.UpdateOperation)
		{
			// Update stock price info into the hash table
			StockPrice stockPrice = (StockPrice) stockPriceMap.get(mapKey);
			if (stockPrice != null)
			{
				stockPrice.setOpeningPrice(openingPrice);
				stockPrice.setTradingPrice(tradingPrice);
				stockPrice.setTradingTime(tradingTime);
  			this.stockPriceMap.put(mapKey, stockPrice);  
			}  
		}
		else if (rowOp == Row.DeleteOperation)
		{
			// Delete stock price info from the hash table 
			this.stockPriceMap.remove(mapKey);
		}
		  		 
	} // processRow()
		

  /** getXMLPubState */
	public String getXMLPubState()
	{
		return this.xmlPubState;
	} // getXMLPubState()
		
  /** getStockPriceMap */
	public Map getStockPriceMap()
	{
		return this.stockPriceMap;
	} // getStockPriceMap()
	

  /** printStockPriceMap */
	public Map printStockPriceMap()
	{
		return this.stockPriceMap;
	} // printStockPriceMap()
	

  /** class QListenerThread */
  class QListenerThread extends Thread 
  {
    public void run() 
    {
      try {
        MessageConsumer messageConsumer = null;

        if (qName != null) {
          System.out.println("Connect to queue " + qName + 
          									 " in queue manager " + qMgrName);
          // Create the JMS MQ objects to read from the queue
          MQQueueConnectionFactory factory = new MQQueueConnectionFactory();
          factory.setQueueManager(qMgrName );
          QueueConnection connection = factory.createQueueConnection();
          connection.start();
          QueueSession session = connection.createQueueSession( false, Session.AUTO_ACKNOWLEDGE);
          Queue receiveQueue = session.createQueue(qName);
          QueueReceiver queueReceiver = session.createReceiver( receiveQueue, null );
          messageConsumer = queueReceiver;
        } 

        // Create the PublicationMsgProvider which will listen to the queue, parse the xml messages,
        // and dispatch them to us.
        PublicationMsgProvider msgProvider = PublicationMsgProviderFactory.createPublicationMsgProvider();
        msgProvider.addPublicationMsgListener(StockPriceListener.this);  // Notify us of any messages
        while (!stopped) 
        {
          msgProvider.dispatchMsgs(messageConsumer, 10000, true);         // Dispatch with a 10 sec timeout
        }                                                                 //   true = ignore errors.

      } 
      catch ( Exception caught ) 
      {
        System.out.println("QListenerThread caught " + caught);
        caught.printStackTrace();
      }
    } // run
  } // class QListenerThread

		
} // class StockPriceListener
