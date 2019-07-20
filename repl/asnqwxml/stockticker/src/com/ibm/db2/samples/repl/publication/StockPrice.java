/**
 * A Web Application Example based on Event Publishing
 *
 * (C) Copyright IBM Corporation 2004. All rights reserved.
 *
 * Application name: Stock Ticker
 *
 * Source file name: StockPrice.java
 *
 * Purpose:
 * This class encapsulates stock price information of a stock symbol
 * with its trading currency on a trading date. 
 */

package com.ibm.db2.samples.repl.publication;

import java.math.BigDecimal;

public class StockPrice 
{

    //
    // Data
    //

    /** Stock symbol */
    private String symbol;

    /** Currency */
    private String ccy;

    /** Trading date */
    private String tradingDate;

    /** Opening price */
    private BigDecimal openingPrice;

    /** Trading price */
    private BigDecimal tradingPrice;

    /** Trading time */
    private String tradingTime;

    //
    // Constructors
    //

    public StockPrice(String symbol, String ccy, String tradingDate,
                      BigDecimal openingPrice, BigDecimal tradingPrice, String tradingTime) 
    {
			this.symbol = symbol;
			this.ccy = ccy;
			this.tradingDate = tradingDate;
  	  this.openingPrice = openingPrice;
			this.tradingPrice = tradingPrice;
			this.tradingTime = tradingTime;
    } // stockPrice()
			
			
    //
    // Public methods
    //

    /** getSymbol */
    public String getSymbol ()
    {
    	return this.symbol;
    }


    /** getCCY */
    public String getCCY ()
    {
    	return this.ccy;
    }


    /** getTradingDate */
    public String getTradingDate ()
    {
    	return this.tradingDate;
    }


    /** getOpeningPrice */
    public BigDecimal getOpeningPrice ()
    {
    	return this.openingPrice;
    }


    /** getTradingPrice */
    public BigDecimal getTradingPrice ()
    {
    	return this.tradingPrice;
    }


    /** getTradingTime */
    public String getTradingTime ()
    {
    	return this.tradingTime;
    }

    /** getChange */
    public BigDecimal getChange ()
    {
    	return (this.tradingPrice.subtract(this.openingPrice));
    }

    /** setOpeningPrice */
    public void setOpeningPrice (BigDecimal openingPrice)
    {
    	if (openingPrice != null)
    	{
    		this.openingPrice = openingPrice;
    	}
    }

    /** setTradingPrice */
    public void setTradingPrice (BigDecimal tradingPrice)
    {
    	if (tradingPrice != null)
    	{
    		this.tradingPrice = tradingPrice;
    	}
    }

    /** setTradingTime */
    public void setTradingTime (String tradingTime)
    {
    	if (tradingTime != null)
    	{
    		this.tradingTime = tradingTime;
    	}
    }

    /** Print */
    public void print() 
    {
    	System.out.println("Symbol:        " + this.symbol);
    	System.out.println("CCY:           " + this.ccy);
    	System.out.println("Trading date:  " + this.tradingDate);
    	System.out.println("Trading time:  " + this.tradingTime);
    	System.out.println("Opening price: " + this.openingPrice.toString());
    	System.out.println("Trading price: " + this.tradingPrice.toString());
    	System.out.println("Change:        " + this.getChange().toString());
    } // print()

}
