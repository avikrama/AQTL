
declare @start as date = '2014-01-01', @now as date, @end as date ;

set @now = getdate()
set @end = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

select
	cast(dateadd(d,  0, dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_r) - 1900) * 12 + month(txn.PostDate_r) , 0))) as date) as Month , 
	isnull(c.SoftwareName,'Non-Affiliated') SoftwareName, sum(txn.Amount) TPV, count(*) as Txn_Count, count(distinct(c.ChildAccountId)) as #of_Merchants
from
	YapstoneDM..[Transaction] txn
	join ETLStaging..FinanceParentTable c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
where
	txn.PostDate_R between @start and @end
	and txn.ProcessorId not in (14,16)
	and txn.TransactionCycleId in (1)
	and c.Vertical in ('NonProfit')
group by
cast(dateadd(d,  0, dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_r) - 1900) * 12 + month(txn.PostDate_r) , 0))) as date) , 
	isnull(c.SoftwareName,'Non-Affiliated') 









