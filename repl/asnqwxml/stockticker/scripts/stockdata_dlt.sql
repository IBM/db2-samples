set current schema ASN;

update command options using c off;

--
-- 1st trans
--
delete from stock_prices where symbol='ORCL';

commit;

--
-- 2nd trans
--
delete from stock_prices where symbol='MSFT';

commit;
