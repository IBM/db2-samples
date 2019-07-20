set current schema ASN;

update command options using c off;

--
-- 1st trans
--
update stock_prices set (trading_price, trading_time) = (124.15, current time) 
        where symbol='IBM' and ccy='CAD' and trading_date='04-01-2004';

update stock_prices set (trading_price, trading_time) = (59.01, current time) 
        where symbol='MSFT' and ccy='CAD' and trading_date='04-01-2004';

update stock_prices set (trading_price, trading_time) = (93.75, current time) 
        where symbol='ORCL' and ccy='CAD' and trading_date='04-01-2004';

commit;

--
-- 2nd trans
--
update stock_prices set (trading_price, trading_time) = (84.33, current time) 
        where symbol='IBM' and ccy='EUR' and trading_date='04-01-2004';

update stock_prices set (trading_price, trading_time) = (40.88, current time) 
        where symbol='MSFT' and ccy='EUR' and trading_date='04-01-2004';

update stock_prices set (trading_price, trading_time) = (50.11, current time) 
        where symbol='ORCL' and ccy='EUR' and trading_date='04-01-2004';

commit;

--
-- 3rd trans
--
update stock_prices set (trading_price, trading_time) = (94.33, current time) 
        where symbol='IBM' and ccy='USD' and trading_date='04-01-2004';

update stock_prices set (trading_price, trading_time) = (45.01, current time) 
        where symbol='MSFT' and ccy='USD' and trading_date='04-01-2004';

update stock_prices set (trading_price, trading_time) = (64.85, current time) 
        where symbol='ORCL' and ccy='USD' and trading_date='04-01-2004';

commit;
