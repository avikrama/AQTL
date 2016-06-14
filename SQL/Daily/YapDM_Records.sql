declare @now as date, @start as date, @end as date, @query as nvarchar(max) ;

set @now = getdate()
set @end = @now
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0)  -- Yesterday minus one

select Date, [1] as RP, [2] as IP, [3] as HA, [4] as GD1 from (
select
	txn.PostDate_R Date, txn.PlatformId, count(*) Records
from
	YapstoneDM..[Transaction] txn
where
	txn.TransactionCycleId in (1)
	and txn.PostDate_R between @start and @end 
group by
	txn.PostDate_R, txn.PlatformId
) src
pivot (
	sum(Records)
	for [PlatformId] in ([1],[2],[3],[4])
) pt
order by Date asc