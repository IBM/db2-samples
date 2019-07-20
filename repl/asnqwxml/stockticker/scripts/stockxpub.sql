--=============================================================================
--
-- Transaction Publishing Sample Initialization Script
--
--=============================================================================
DELETE FROM ASN.IBMQREP_CAPPARMS;
DELETE FROM ASN.IBMQREP_SUBS;
DELETE FROM ASN.IBMQREP_SRC_COLS;
DELETE FROM ASN.IBMQREP_SENDQUEUES;
DELETE FROM ASN.IBMQREP_SIGNAL;
DELETE FROM ASN.IBMQREP_CAPTRACE;
DELETE FROM ASN.IBMQREP_CAPMON;
DELETE FROM ASN.IBMQREP_ADMINMSG;

--========================================================================
-- Define a send queue first
--========================================================================
INSERT INTO ASN.IBMQREP_SENDQUEUES  
(
  PUBQMAPNAME,
  SENDQ, 
  MESSAGE_FORMAT, 
  MSG_CONTENT_TYPE,
  STATE,
  ERROR_ACTION, 
  HEARTBEAT_INTERVAL, 
  MAX_MESSAGE_SIZE
)
VALUES 
(
  'PUBQ1', 
  'Q1', 
  'X', 
  'T',
  'A',
  'S', 
  0,
  64
);

--========================================================================
-- Define a subscription
--========================================================================

--
-- Subscribe to ASN.STOCK_PRICES on Q1
--
INSERT INTO ASN.IBMQREP_SUBS 
(
  SUBNAME,
  SOURCE_OWNER, SOURCE_NAME,
  SENDQ,
  SEARCH_CONDITION,
  SUBTYPE, 
  ALL_CHANGED_ROWS, BEFORE_VALUES, CHANGED_COLS_ONLY, 
  HAS_LOADPHASE,
  STATE
)
VALUES 
(
  'STOCK_PRICES_SUB',
  'ASN', 'STOCK_PRICES',
  'Q1',
  'WHERE abs(:OPENING_PRICE - :TRADING_PRICE) > 1',
  'U', 
  'N', 'N', 'Y', 
  'N',
  'I'
);

--
-- Subscribe ASN.STOCK_PRICES' columns
--
INSERT INTO ASN.IBMQREP_SRC_COLS
  (SUBNAME, SRC_COLNAME, IS_KEY)
VALUES
  ('STOCK_PRICES_SUB', 'SYMBOL', 1 ),
  ('STOCK_PRICES_SUB', 'CCY', 1 ),
  ('STOCK_PRICES_SUB', 'TRADING_DATE', 1 ),
  ('STOCK_PRICES_SUB', 'OPENING_PRICE', 0 ),
  ('STOCK_PRICES_SUB', 'TRADING_PRICE', 0 ),
  ('STOCK_PRICES_SUB', 'TRADING_TIME', 0 );
