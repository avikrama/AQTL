declare @now date, @start date, @end date

set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0)
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

if object_id('tempdb..#Txn') is not null drop table #Txn
select	count(*) Records	into #Txn
from	YapstoneDM..[Transaction] txn
where	txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)
      and txn.PlatformId in (1,2,3)

if object_id('tempdb..#SurchargeType') is not null drop table #SurchargeType
select  count(*) Records into #SurchargeType
from 	YapstoneDM..[Transaction] txn 
  inner join ETLStaging..FinanceSurchargeType c on txn.PlatformId = c.PlatformId and txn.IdClassId = c.IdClassId
where txn.PostDate_R between @start and @end
	and txn.TransactionCycleId in (1,3,4,9,16) 
	and txn.PlatformId in (1,2,3)     

select * from (
      select 'Transaction Table' [Table], Records from #txn union all
      select 'w/ Join SurchargeType', Records from #SurchargeType
) src
