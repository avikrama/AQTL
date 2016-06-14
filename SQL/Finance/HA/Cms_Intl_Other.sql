

-- NonHA-Intl Commissions
declare @now as date, @start as date, @end as date, @currencies as nvarchar(max), @columns as nvarchar(max), @query as nvarchar(max)
set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 - 1, 0)
set @end = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0)) 

if object_id('tempdb..#Report') is not null drop table #Report
select 
   c.Merchant, c.Software,
   cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) as date) as Date , 
   Currency.CharCode Currency,
   sum(txn.Amount) as Txn_Amount, 
   sum(txn.AmtNetPropFee) as Revenue,
   count(*) as Txn_Count
   into #Report    
from                                             
   YapstoneDM.dbo.[Transaction] txn
   inner join ETLStaging..FinanceHAPropertyOwners c      on c.PlatformId = txn.PlatformId and c.ChildCompanyId = txn.Ref_CompanyId
   inner join YapstoneDM.dbo.Currency                    on txn.CurrencyId = Currency.CurrencyId
   inner join ETLStaging..FinanceHAProductType Product   on Product.PlatformId = txn.PlatformId and Product.IdClassId = txn.IdClassId
where            
   txn.PostDate_R between @start and @end
   and txn.PlatformId in (4)
   and txn.TransactionCycleId in (1,3,4,9,16)   -- Net
   and c.Merchant not in ('Homeaway Inc','IVT')
group by
   c.Merchant,c.Software,
   cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) as date), 
   Currency.CharCode 
     
select @currencies = stuff((select ',' + quotename(colName) from (
      select  distinct(Currency) as colName from #Report 
) sub order by colName desc for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')

select @columns = stuff((
   select col from (
      select 
         distinct ',' + quotename(Currency+'_'+c.col) col, Currency, src_Sort_Order 
      from #Report
         cross apply ( 
              select 'Txn_Amount' col, 2 src_Sort_Order union all select 'Revenue', 3  union all select 'Txn_Count', 1 
         ) c
      ) src
   order by Currency, src_Sort_Order
for xml path (''), type).value('.', 'nvarchar(max)'),1,1,'')

set @query = '
select * from (
   select Merchant, Software, Date, Currency+''_''+col col, Value from (
      select Merchant, Software, Date, Currency, Txn_Amount, Revenue, cast(Txn_Count as decimal(38,4)) Txn_Count
      from #Report
   ) src
   unpivot (
      value
      for col in (Txn_Amount, Revenue, Txn_Count)
   ) up
) src
pivot (
   sum(value)
   for col in ('+@columns+')
) pt
'

exec(@query)
