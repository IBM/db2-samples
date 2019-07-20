set current schema ASN;

update command options using c off;

--
-- 1st trans
--
insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('IBM', 'CAD', '04-01-2004', 120.54, 122.02);

insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('MSFT', 'CAD', '04-01-2004', 61.24, 58.02);

insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('ORCL', 'CAD', '04-01-2004', 94.62, 91.42);

commit;

--
-- 2nd trans
--
insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('IBM', 'EUR', '04-01-2004', 82.20, 81.00);

insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('MSFT', 'EUR', '04-01-2004', 40.11, 38.00);

insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('ORCL', 'EUR', '04-01-2004', 61.37, 60.25);

commit;

--
-- 3rd trans
--
insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('IBM', 'USD', '04-01-2004', 80.10, 82.13);

insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('MSFT', 'USD', '04-01-2004', 40.09, 41.13);

insert into stock_prices (symbol, ccy, trading_date, opening_price, trading_price)
	values('ORCL', 'USD', '04-01-2004', 60.17, 63.25);

commit;
