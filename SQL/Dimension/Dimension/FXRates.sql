-- FX Rates
declare @start as date, @end as date

set @start           = '2010-01-01'
set @end             =  cast(getdate() as date)

if object_id('tempdb..#CurrencyCodes') is not null drop table #CurrencyCodes
select 
  Currency.CharCode, Currency.CurrencyId 
  into #CurrencyCodes
from 
  YapstoneDM..Currency
group by 
  Currency.CharCode, Currency.CurrencyId 
  
if object_id('tempdb..#Dates') is not null drop table #Dates
select * into #Dates from (
  select  
    txn.PostDate_R Date, c.CharCode, c.CurrencyId  
  from  
    YapstoneDM..[Transaction] txn
  cross join ( 
    select Currency.CharCode, Currency.CurrencyId 
    from YapstoneDM..Currency
    group by Currency.CharCode, Currency.CurrencyId 
  ) c
  where 
    txn.PostDate_R between @start and @end
  group by 
    txn.PostDate_R, c.CharCode, c.CurrencyId
) src


if object_id('tempdb..#EURUSD') is not null drop table #EURUSD
select 
  fx.Date, fx.ExchangeRate           
  into #EURUSD                 
from 
  YapstoneDM..CurrencyExchangeRate fx
where  
  BaseCurrencyId in (1) and fx.CounterCurrencyId in (3)
  and fx.Date between @start and @end
group by 
  fx.Date, fx.ExchangeRate
 
if object_id('tempdb..#RatesPREPROCESSED') is not null drop table #RatesPREPROCESSED
select * into #RatesPREPROCESSED from (
  select 
    isnull(fx.Date,d.Date) Date, isnull(Currency.CharCode,d.CharCode) CharCode, isnull(Currency.CurrencyId,d.CurrencyId) CurrencyId,
    1 / ( fx.ExchangeRate / usd.ExchangeRate ) Rate
  from 
    #Dates d 
    left join YapstoneDM..CurrencyExchangeRate fx  on d.Date = fx.Date
    left join YapstoneDM..Currency on fx.CounterCurrencyId = Currency.CurrencyId
    left join #EURUSD usd on fx.Date = usd.Date
  where 
    d.Date between @start and @end
  group by  
    isnull(fx.Date,d.Date), isnull(Currency.CharCode,d.CharCode), isnull(Currency.CurrencyId,d.CurrencyId), 
    1 / ( fx.ExchangeRate / usd.ExchangeRate )
  union
  select  
    isnull(fx.Date,d.Date) Date, d.CharCode, d.CurrencyId,
    fx.ExchangeRate                      
  from  
    #Dates d 
    left join YapstoneDM..CurrencyExchangeRate fx  on d.Date = fx.Date and d.CurrencyId = fx.BaseCurrencyId and BaseCurrencyId in (1) and fx.CounterCurrencyId in (3)
    left join YapstoneDM..Currency on fx.CounterCurrencyId = Currency.CurrencyId
  where  
    d.CurrencyId in (1) 
    and  d.Date between @start and @end
  group by 
    isnull(fx.Date,d.Date), d.CharCode, d.CurrencyId,
    fx.ExchangeRate
) src
order by Date asc


if object_id('tempdb..#FallbackRates') is not null drop table #FallBackRates
select * into #FallbackRates from (
  select 'EUR' CharCode, 1.35 as Rate union 
  select 'GBP', 1.6 union 
  select 'CAD', 0.9 union 
  select 'USD', 1
) src

if object_id('tempdb..#Rates') is not null drop table #Rates
select 
  Date,src.CharCode,CurrencyId,
  isnull(src.Rate,fallback.Rate) Rate  
  into #Rates from (
    select 
      Date,CharCode,CurrencyId,
    ( select  top 1 Rate
      from  #RatesPREPROCESSED r1
      where r1.Date <= r.Date
        and r1.Rate is not null
        and r1.CharCode = r.CharCode
      order by r1.Date desc
    ) Rate
from #RatesPREPROCESSED r
) src left join #FallBackRates fallback on fallback.CharCode = src.CharCode

select * from #Rates 
