
declare @now as date, @start as date, @end as date
 
set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0)
set @end = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0)) 
 
if object_id('tempdb..#Ancillary_Revenue') is not null drop table #Ancillary_Revenue
select * into #Ancillary_Revenue from (
       select
               Year, Month, cast(dateadd(d, -1 , dateadd(mm, (Year - 1900) * 12 + Month, 0)) as date) as Date ,
               'HA' as Vertical, 'Ancillary' as ProductType, 'USD' as Currency,
               sum(Charge) Revenue
       from
       ETLStaging..PropertyPaidBilling billing
       where
               PlatformID in (3)
       group by
               Year, Month, cast(dateadd(d, -1 , dateadd(mm, (Year - 1900) * 12 + Month, 0)) as date)
       ) src
where Date between @start and @end
if object_id('tempdb..#HA_Analytics_HA') is not null drop table #HA_Analytics_HA
select year(txn.PostDate_R) Year , month(txn.PostDate_R) Month , cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R) , 0)) as date) Date ,
       'HA' as Vertical, 'USD' as CharCode , Product.ProductType ,
       case when txn.PaymentTypeId in (1,2,3,11,12) then 'Card' when txn.PaymentTypeId in (10) then 'Amex' when txn.PaymentTypeId in (4,5) then 'ACH' else cast(txn.PaymentTypeId as nvarchar(max)) end as PaymentType ,
       sum(txn.Amount) as TPV_USD,  sum(txn.AmtNetPropFee) as Revenue_USD,
       count(*) as Txn_Count,        count(distinct(c.AccountId)) #of_Merchants
       into #HA_Analytics_HA
from                                           
   YapstoneDM.dbo.[Transaction] txn
   inner join YapstoneDM.dbo.Company c              on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.CompanyId 
   inner join ETLStaging..FinanceHAProductType Product                      on txn.IdClassId = Product.IdClassId and txn.PlatformId = Product.PlatformId
where txn.PostDate_R between @start and @end
       and txn.TransactionCycleId in (1) and txn.PlatformId in (3) and txn.ProcessorId not in (14,16)
       -- and txn.PaymentTypeId in (1,2,3,11,12)
group by year(txn.PostDate_R) , month(txn.PostDate_R) , cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R) , 0)) as date),  Product.ProductType ,
       case when txn.PaymentTypeId in (1,2,3,11,12) then 'Card' when txn.PaymentTypeId in (10) then 'Amex' when txn.PaymentTypeId in (4,5) then 'ACH' else cast(txn.PaymentTypeId as nvarchar(max)) end
order by  Year , Month, cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R) , 0)) as date)
 
if object_id('tempdb..#HA_Analytics_HA_Report') is not null drop table #HA_Analytics_HA_Report
select
       HA.Year, HA.Month, HA.Date, HA.Vertical, HA.CharCode, HA.ProductType, HA.PaymentType, 
       HA.TPV_USD, sum(HA.Revenue_USD + isnull(Anc.Revenue,0)) Revenue_USD, HA.Txn_Count ,  HA.#of_Merchants
       into #HA_Analytics_HA_Report
from
       #HA_Analytics_HA HA
       left join #Ancillary_Revenue Anc on HA.Year = Anc.Year and HA.Month = Anc.Month
               and HA.ProductType = Anc.ProductType and HA.PaymentType = 'Card' and HA.Vertical = Anc.Vertical
group by
       HA.Year, HA.Month, HA.Date, HA.Vertical, HA.CharCode, HA.ProductType, HA.PaymentType,  HA.TPV_USD, 
       HA.Txn_Count ,  HA.#of_Merchants
 
 
if object_id('tempdb..#HA_Analytics_GD1') is not null drop table #HA_Analytics_GD1
select year(txn.PostDate_R) Year , month(txn.PostDate_R) Month , cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R) , 0)) as date) Date ,
       'HA-Intl' as Vertical, Currency.CharCode ,Product.ProductType ,
               case when txn.PaymentTypeId in (1,2,3,11,12) then 'Card' when txn.PaymentTypeId in (10) then 'Amex' when txn.PaymentTypeId in (4,5) then 'ACH' else cast(txn.PaymentTypeId as nvarchar(max)) end as PaymentType ,
       sum(txn.Amount * fx.Rate) as TPV_USD, sum(txn.AmtNetPropFee * fx.Rate ) as Revenue_USD,
       count(*) as Txn_Count ,        count(distinct(c.AccountId)) #of_Merchants
       into #HA_Analytics_GD1
from                                           
   YapstoneDM.dbo.[Transaction] txn
   inner join YapstoneDM.dbo.Company c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.CompanyId 
   inner join YapstoneDM.dbo.Currency       on txn.CurrencyId = Currency.CurrencyId
   inner join ETLStaging..FinanceHAProductType Product       on txn.IdClassId = Product.IdClassId and txn.PlatformId = Product.PlatformId
   inner join ETLStaging..FinanceFXRates fx on  txn.PostDate_R = fx.Date and txn.CurrencyId = fx.CurrencyId
where            
       txn.PostDate_R between @start and @end
       and txn.ProcessorId not in (14,16)
       and txn.PlatformId in (4)
       -- and txn.PaymentTypeId in (1,2,3,11,12)
       and txn.TransactionCycleId in (1)
group by year(txn.PostDate_R) , month(txn.PostDate_R) ,  cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R) , 0)) as date) , Currency.CharCode ,
       Product.ProductType ,
               case when txn.PaymentTypeId in (1,2,3,11,12) then 'Card' when txn.PaymentTypeId in (10) then 'Amex' when txn.PaymentTypeId in (4,5) then 'ACH' else cast(txn.PaymentTypeId as nvarchar(max)) end
order by  Year , Month
 
select *
from #HA_Analytics_HA_Report
union
select *
from #HA_Analytics_GD1
 
 
 