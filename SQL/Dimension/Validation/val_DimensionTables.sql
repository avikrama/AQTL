
declare @now date, @start date, @end date

set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0)
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

if object_id('tempdb..#Txn') is not null drop table #Txn
select	count(*) Records	into #Txn
from	YapstoneDM..[Transaction] txn
where	txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)
 
if object_id('tempdb..#ParentTable') is not null drop table #ParentTable
select	count(*) Records	into #ParentTable
from	YapstoneDM..[Transaction] txn 
	inner join ETLStaging..FinanceParentTable c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
where
	txn.PostDate_R between @start and @end
	and txn.TransactionCycleId in (1,3,4,9,16)      

if object_id('tempdb..#FXRates') is not null drop table #FXRates
select	count(*) Records	into #FXRates
from	YapstoneDM..[Transaction] txn 
	inner join ETLStaging..FinanceFXRates fx on txn.CurrencyId = fx.CurrencyId and txn.PostDate_R = fx.Date
where	txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)


select * from (
	select 'Transaction Table' [Table], Records from #Txn union all
	select 'w/ Join ParentTable', Records from #ParentTable union all 
	select 'w/ Join FXRates', Records from #FXRates
) src


