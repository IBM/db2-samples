<%
/**
 * A Web Application Example based on Event Publishing
 *
 * (C) Copyright IBM Corporation 2004. All rights reserved.
 *
 * Application name: Stock Ticker
 *
 * Source file name: stockticker.jsp
 *
 * Purpose:
 *
 * This JSP page does the following tasks:
 * - Create a StockPriceListener object, if it does not exist;
 *   Invoke its startListen() methods and attached it to the 
 *   application object.
 * - Check whether the "Activate XML Publication" or "Deactivate
 *   XML Publication" have been selected. If so, then send an 
 *   Activate or Deactivate Subscription message will to the
 *   administration queue.
 * - Format stock price data kept in the map and display
 *   it together with the current state of the XML publication,
 *   the last time the web page is refreshed, 
 *   as well as two buttons for activating/deactivating 
 *   the XML publication.
 */
%>
<% // Java classes imports %>
<%@ page import="java.util.*" %>
<%@ page import="java.text.*" %>

<% // Xerces classes imports %>
<%@ page import="org.xml.sax.InputSource" %>

<% // MQ classes imports %>
<%@ page import="com.ibm.mq.*" %>

<% // Helper classes imports %>
<%@ page import="com.ibm.db2.samples.repl.publication.*" %>
<%@ page import="com.ibm.db2.tools.repl.publication.*" %>

<%
	try
  {
    //
  	// Get session object and retrieve all objects attached to it.
  	// The objects are required to build this web page containing stock price info.
  	// If they don't exist, then create and attch them to the session object.
  	//
  	
  	String qMgrName = "QMSAMP";
   	String qName = "Q1";
   	String adminqName = "ASN.ADMINQ";
		String xmlPubName = "STOCK_PRICES_SUB";
			
		// Get stock price listener from the application object.
    StockPriceListener stockPriceListener = (StockPriceListener) application.getAttribute("listener");
    if (stockPriceListener == null)
    {
    	// Object does not exist, create one and attach it to the session object.
      stockPriceListener = new StockPriceListener(qMgrName, qName);
			application.setAttribute("listener", stockPriceListener);
			
			// Start listen
			stockPriceListener.startListen();
		}
		
		//
		// Process command requested by users if any
		//
		// Activate and deactivate XML publication are the two commands that
		// can be specified by users by selecting the corresponding buttons on
		// the this web page.
		// The command value itself is represented by the hidden input field "cmd".
		// The value of this field is set through the selection of "Activate XML Publication"
		// and "Deactivate XML Publication" button.
		// Depending on the "cmd" value a corresponding control msg will be created and sent.
		//
		ControlMsg ctrlMsg = null;
		String cmd = request.getParameter("cmd");

    if (cmd != null)
    {		
			// Create control msg
			if (cmd.equals("activateSub"))
			{
				ctrlMsg = new ActivateSubscriptionMsg(xmlPubName);
			}
			else if (cmd.equals("deactivateSub"))
			{
				ctrlMsg = new DeactivateSubscriptionMsg(xmlPubName);
			}
		}
		
		// Send control msg
		if (ctrlMsg != null)
		{
			ctrlMsg.send(qMgrName, adminqName);	
		}
	
		//
		// Now generate the web page based on the StockPrice objects stored in the map
		// and XML publication object.
		//
		
		// Generate web page's header info.
		// The web page will automatically be refreshed every 5 seconds.
%>
<html>
	<head>
		<meta http-equiv="refresh" content="5">
		<title>Stock Ticker</title>
	</head>	
	<body>
		<center>
			<u><h2>Stock Ticker</h2></u>
<%
		// Retrieve each StockPrice object in the map and display it
		// 
		Set s = stockPriceListener.getStockPriceMap().entrySet();
		Iterator i = s.iterator();
		if (!i.hasNext())
		{
%>
			<h3>No stock price information found!</h3>
<%
		}
		else
		{
			// The StockPrice objects in the mapped are sorted by currency, stock symbol,
			// and trading date. For each currency generate a separate table.
			String lastCCY = null;
			boolean isNewCCY = true;
					
			while (i.hasNext())
			{
				Map.Entry me = (Map.Entry) i.next();
				StockPrice sp = (StockPrice) me.getValue();

				String spCCY = sp.getCCY();								
				if ((lastCCY == null) || !lastCCY.equals(spCCY))
				{
					isNewCCY = true;
					lastCCY = spCCY;
				}
				else
				{
					isNewCCY = false;
				}
				
				if (isNewCCY)
				{
					// Check if a StockPrice object with a new currency is being processed.
					if (isNewCCY)
					{
						// End previous <table> tag if any
						if (lastCCY != null)
						{
%>		
			</table><br>
<%
						}
%>
				<font size="4">
<%
						// Generate table title based on the currency
						if (spCCY.equals("CAD"))
						{
							out.println("TSX");
						}
						else if (spCCY.equals("USD"))
						{
							out.println("NYSE");
						}
						else if (spCCY.equals("EUR"))
						{
							out.println("Deutsche B&ouml;rse");
						}
						else
						{
							out.println("Unknown Stock Exchange");
						}
%>
				</font><font size="2">(<% out.print(spCCY); %>)</font><br><br>
<%
						
						// Write a new table header
%>
			<table border="4" cellpadding="2">
			<tr>
				<th>Symbol</th>
				<th align="right">Trading Date</th>
				<th align="right">Opening Price</th>
				<th align="right">Last Trading Price</th>
				<th align="right">Change</th>
				<th align="right">Change %</th>
				<th align="right">Last Trading Time</th>				
			</tr>
<%
					}
				} // if CCY change occurs
				
				// Write stock price info
     		NumberFormat numFormat = NumberFormat.getPercentInstance();
%>
			<tr>
				<td><% out.print(sp.getSymbol()); %></td>
				<td align="right"><% out.print(sp.getTradingDate()); %></td>
				<td align="right"><% out.print(sp.getOpeningPrice().toString()); %></td>
				<td align="right"><% out.print(sp.getTradingPrice().toString()); %></td>
				<td align="right"><% out.print(sp.getChange().toString()); %></td>
				<td align="right"><% out.print(numFormat.format(sp.getChange().divide(sp.getOpeningPrice(), 2).doubleValue())); %></td>
				<td align="right"><% out.print(sp.getTradingTime()); %></td>
			<tr>
<%				
			} // while
%>			
			</table>
<%		
		} // else
		
		// Create command buttons and display last refresh time as well as 
		// the current publication's state.
%>
			<form name="cmdMenu" action="stockticker.jsp" method="post">
				<input type="submit" value="Activate XML Publication" onClick="document.cmdMenu.cmd.value='activateSub'">
				<input type="submit" value="Deactivate XML Publication" onClick="document.cmdMenu.cmd.value='deactivateSub'">
				<input type="hidden" name="cmd">
			</form>
			<font size="3">
			<b>XML Publication's State: </b><% out.print(stockPriceListener.getXMLPubState()); %><br>
			<b>Last Refresh: </b><%= new java.util.Date() %>
			</font>
<%
	} // try
	catch (Exception e) 
	{
  	e.printStackTrace();
  }
%>
		</center>
	</body>
</html>
		