--
--Scenario
--
-- The source table is a kind of inventory list that holds
-- the name of different products together with it's price
-- and the currency.
-- The stored procs task is it to get the exchange rate by
-- querying a special table using it and transform all the prices
-- for the arriving rows to dollar prices.
--
-- ------------            Source table:        ---------------
--     CREATE TABLE  SRC_LIST ( item      varchar(30) NOT NULL,
--                              price     real        NOT NULL,
--                              currency  char(3)     NOT NULL,
--                              PRIMARY KEY(item))
--                              DATA CAPTURE CHANGES
--
--
-- ------------           Target table:         ---------------
-- The targ_list table will hold the rows from the source table
-- The price column will be transformed to the American currency.
-- The stored proc will use the currency value to get the current
-- exchange rate from the table currency
-- and use that value to calculate the actual price in dollar.
--
-- CREATE TABLE  targ_list ( item      varchar(30) NOT NULL,
--                           price     real        NOT NULL,
--                           PRIMARY KEY(item) )
--
--
-- --- Currency table used to query by the stored proc: ------
-- CREATE TABLE  country_rate ( country      char(3) NOT NULL,
--                              rate         real    NOT NULL,
--                              PRIMARY KEY(country))
--
--
-- ------------------ sample workload ------------------------
--
-- Sample data for table 'currency':
-- INSERT INTO country_rate VALUES('EUR',0.812)
-- INSERT INTO country_rate VALUES('GBP',0.572)
-- INSERT INTO country_rate VALUES('JPY',107.492)
-- INSERT INTO country_rate VALUES('CHF',1.26)
--
--
-- Sample data for the src table:
-- INSERT INTO SRC_LIST VALUES('chair',100,'EUR')
-- INSERT INTO SRC_LIST VALUES('table',50,'CHF')
-- INSERT INTO SRC_LIST VALUES('laptop',100000,'JPY')
-- INSERT INTO SRC_LIST VALUES('LCD display',500,'GBP')
-- INSERT INTO SRC_LIST VALUES('cellphone',65,'EUR')
-- INSERT INTO SRC_LIST VALUES('antyhing',65,'JPY')
-- INSERT INTO SRC_LIST VALUES('house',65000,'GBP')
--
-- DELETE FROM SRC_LIST WHERE price = 65
-- UPDATE SRC_LIST SET ITEM='phone' where ITEM='chair'
-- UPDATE SRC_LIST SET PRICE=10000,CURRENCY='JPY' where ITEM='phone'
--
--
--
--

--////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////
--
--
-- INPUT:
-- - 4 mandatory parms:
--           + OPERATION (INOUT)
--             that parm can have the values:
--             16 = INSERT,
--             32 = UPDATE,
--             128= KEY UPDATE,
--             64 = DELETE
--           + SUPPRESSION (IN)
--             the suppression index is an array that holds
--             for each non mandatory parameter (starting with
--             the 5th stored proc parm) a character saying '0'
--             if there is a value send for the correspdonding
--             parm or having a '1' saying that the value for
--             that parm was suppressed.
--           + LSN (IN)
--           + COMMITTIME (IN)
--
-- - 4 non madatory parms:
--                     + B_item   ( before key parameter)
--                     + item     ( key parameter)
--                                ( must be mapped in
--                                  ibmqrep_trg_cols table)
--                     + price    ( non key parameter)
--                                ( must be mapped in
--                                  ibmqrep_trg_cols table)
--                     + currency ( non key parameter)
--                                ( must be mapped in
--                                  ibmqrep_trg_cols table)
--
--
-- OUTPUT:
-- - 1 output parm: + OPERATION (INOUT)
--                    The operation parm is used the pass back the SQL
--                    return code
--
--////////////////////////////////////////////////////////////////////
--////////////////////////////////////////////////////////////////////



--DROP PROCEDURE ASNQSPS%

CREATE PROCEDURE ASNQSPS (
                 INOUT operation       integer,
                 IN    suppression_ind VARCHAR(90) ,
                 IN    SRC_COMMIT_LSN  char(10) for bit data ,
                 IN    SRC_TRANS_TIME  timestamp,
                 IN    XITEM           VARCHAR(30),
                 IN    ITEM            VARCHAR(30) ,
                 IN    PRICE           REAL,
                 IN    CURRENCY        CHAR(3)
                          )
        LANGUAGE SQL
        WLM ENVIRONMENT WLMENV1
	       EXTERNAL NAME ASNQSPS
	       RUN OPTIONS 'TRAP(OFF)'
	       SECURITY USER
	       PROGRAM TYPE MAIN
	       MODIFIES SQL DATA
	       COMMIT ON RETURN NO
        BEGIN NOT ATOMIC

            -- build variable
            DECLARE SQLCODE INT ;
            DECLARE old_item varchar(30) ;
            DECLARE new_item varchar(30) ;
            DECLARE new_price real;
            DECLARE current_country char(3);
            DECLARE exchangerate real;
            DECLARE suppressid varchar(90) ;
            DECLARE EXIT HANDLER FOR SQLEXCEPTION
	           SET OPERATION = SQLCODE;
	           DECLARE EXIT HANDLER FOR SQLWARNING
	           SET OPERATION = SQLCODE;
	           DECLARE EXIT HANDLER FOR NOT FOUND
	           SET OPERATION = SQLCODE;
            set suppressid = suppression_ind;
            set old_item = XITEM ;
            set new_item = ITEM;
            set new_price= PRICE;
            set current_country  = CURRENCY;

--insert into log values
--(operation , suppression_ind  ,XITEM ,ITEM ,PRICE ,CURRENCY);
--SET OPERATION=SQLCODE;

  --Insert
   IF (OPERATION=16 AND SUBSTR(suppressid,1,4)='1000' ) THEN
      SELECT rate INTO exchangerate FROM country_rate
		      WHERE country= current_country;
      INSERT INTO TARG_LIST VALUES
		      (new_item,REAL(new_price/exchangerate));
         SET OPERATION = SQLCODE;
         END IF ;

  --Update
  -- You must have CHANGED_COLS_ONLY='N' in IBMQREP_SUBS
  -- table for this sample
  --
   IF (OPERATION=32 AND SUBSTR(suppressid,1,4)='1000' ) THEN
       SELECT rate INTO exchangerate FROM country_rate
		       WHERE country= current_country;
       UPDATE TARG_LIST SET PRICE=REAL(new_price/exchangerate)
		        WHERE TARG_LIST.ITEM=new_item;
       SET OPERATION = SQLCODE;
    END IF ;

  --Delete
     IF (OPERATION=64 AND SUBSTR(suppressid,1,4)='0111' ) THEN
         DELETE FROM TARG_LIST WHERE TARG_LIST.ITEM=old_item;
         SET OPERATION = SQLCODE;
     END IF ;

  --Key Update
     IF (OPERATION=128 AND SUBSTR(suppressid,1,4)='0011' )  THEN
         UPDATE TARG_LIST SET ITEM=new_item WHERE
         TARG_LIST.ITEM=old_item;
         SET OPERATION = SQLCODE;
     END IF ;

     IF (OPERATION=128 AND SUBSTR(suppressid,1,4)='0000' )  THEN
        SELECT rate INTO exchangerate FROM country_rate
		      WHERE country= current_country;
        UPDATE TARG_LIST SET ITEM=new_item,
		      PRICE=REAL(new_price/exchangerate) WHERE
        TARG_LIST.ITEM=old_item;
        SET OPERATION = SQLCODE;
     END IF;
       END


