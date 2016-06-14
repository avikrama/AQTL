

-- HA-Intl Commissions
declare @now as date, @start as date, @end as date, @currencies as nvarchar(max), @columns as nvarchar(max), @PPS_query as nvarchar(max), @PPB_query as nvarchar(max)
set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 - 1, 0)
set @end = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0)) 

if object_id('tempdb..#Report') is not null drop table #Report
select *, (Txn_Amount - Traveller_Fee_Volume) as Volume_after_TF, (Revenue - Traveller_Fee_Revenue) as Revenue_after_TF into #Report from (
select 
	c.Software,
	cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) as date) as Date , 
	Currency.CharCode Currency, Product.ProductType ,
	sum(txn.Amount) as Txn_Amount, 
	sum(case when right(txn.IdClassId, (len(txn.idclassid) - charindex(':', txn.IdClassId) + 1))  in (':TF') then txn.Amount else 0 end) Traveller_Fee_Volume, 
	sum(txn.AmtNetPropFee) as Revenue,
	sum(case when right(txn.IdClassId, (len(txn.idclassid) - charindex(':', txn.IdClassId) + 1))  in (':TF') then txn.AmtNetPropFee else 0 end) Traveller_Fee_Revenue, 	
	sum(case when Product.ProductType in ('PPB') and c.ChildAggregateId like '1|87645|111105%' then txn.Amount - txn.AmtNetPropFee else 0 end) HA_Commission,
	sum(case when right(txn.IdClassId, (len(txn.idclassid) - charindex(':', txn.IdClassId) + 1))  in (':TF',':PB') then 0 else 1 end) as Txn_Count  
from                                             
	YapstoneDM.dbo.[Transaction] txn
	inner join ETLStaging..FinanceHAPropertyOwners c 		on c.PlatformId = txn.PlatformId and c.ChildCompanyId = txn.Ref_CompanyId
	inner join YapstoneDM.dbo.Currency                  	on txn.CurrencyId = Currency.CurrencyId
	inner join ETLStaging..FinanceHAProductType Product 	on Product.PlatformId = txn.PlatformId and Product.IdClassId = txn.IdClassId
where            
	txn.PostDate_R between @start and @end
	and txn.PlatformId in (4)
	and txn.TransactionCycleId in (1,3,4,9,16) 	-- Net
	and c.Merchant in ('Homeaway Inc')
group by
	c.Software,
	cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) as date), 
	Currency.CharCode , Product.ProductType 
) src
     
select @currencies = stuff((select ',' + quotename(colName) from (
      select  distinct(Currency) as colName from #Report 
) sub order by colName desc for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')

select @columns = stuff((
	select col from (
		select 
			distinct ',' + quotename(Currency+'_'+c.col) col, Currency, src_Sort_Order 
		from #Report
			cross apply ( 
				  select 'HA_Commission' col,	1 src_Sort_Order union all
				  select 'Txn_Amount' ,			2 union all 
				  select 'Volume_after_TF',		3 union all 
				  select 'Revenue',				4 union all 
				  select 'Revenue_after_TF',	5 
			) c
		) src
	order by Currency, src_Sort_Order
for xml path (''), type).value('.', 'nvarchar(max)'),1,1,'')

set @PPB_query = '
select * from (
	select Software, Date, Currency+''_''+col col, Value from (
		select Software, Date, Currency, Txn_Amount, Volume_after_TF, Revenue, Revenue_after_TF , HA_Commission
		from #Report
		where ProductType in (''PPB'')
	) src
	unpivot (
		value
		for col in (Txn_Amount, Volume_after_TF, Revenue, Revenue_after_TF, HA_Commission)
	) up
) src
pivot (
	sum(value)
	for col in ('+@columns+')
) pt
'

exec(@PPB_query)
