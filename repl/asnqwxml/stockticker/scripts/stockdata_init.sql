set current schema ASN;

--============================================================================
-- Currency data
--============================================================================
delete from currencies;
insert into currencies values ('USD', 'US dollar');
insert into currencies values ('CAD', 'Canadian dollar');
insert into currencies values ('EUR', 'Euro');

--============================================================================
-- Stock data
--============================================================================
delete from stocks;
insert into stocks values('IBM', 'International Business Machines Corporation');
insert into stocks values('ORCL', 'Oracle Corporation');
insert into stocks values('MSFT', 'Microsoft Corporation');

--============================================================================
-- Stock price data
--============================================================================
delete from stock_prices;
