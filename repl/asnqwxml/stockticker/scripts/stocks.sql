set current schema ASN;

--============================================================================
-- Source table definition
--============================================================================
drop table currencies;
create table currencies(
  symbol         varchar(3) not null primary key,
  name           varchar(30) not null
  );

drop table stocks;
create table stocks (
  symbol         varchar(8) not null primary key,
  name           varchar(50) not null
  );

drop table stock_prices;
create table stock_prices (
  symbol        varchar(8) not null,
  ccy           varchar(3) not null,
  trading_date  date not null default current date,
  opening_price decimal(5,2) not null default 0,
  trading_price decimal(5,2) not null,
  trading_time  time not null default current time,
  misc_info     varchar(100) default null,
  primary key (symbol, ccy, trading_date) 
  ) data capture changes;

alter table stock_prices
  add constraint fk_sprice_to_stck
    foreign key (symbol) references stocks (symbol)
      on delete cascade
;

alter table stock_prices
  add constraint fk_sprice_to_ccy
    foreign key (ccy) references currencies(symbol)
      on delete cascade
;
