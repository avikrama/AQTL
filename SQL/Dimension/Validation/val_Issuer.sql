
declare @now date, @start date, @end date

set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0)
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

if object_id('tempdb..#Txn') is not null drop table #Txn
select      count(*) Records  into #Txn
from  YapstoneDM..[Transaction] txn
where txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)
      and txn.PlatformId in (1,2,3)
      and txn.PaymentTypeId in (1,2,3,6,7,8,9,10,11,12)
 
if object_id('tempdb..#IssuerType') is not null drop table #IssuerType
select      count(*) Records into #IssuerType
from  YapstoneDM..[Transaction] txn 
      inner join ETLStaging..FinanceIssuerType i on txn.PlatformId = i.PlatformId  and txn.IdClassId = i.IdClassId
where txn.PlatformId in (1,2,3)
      and txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)      

select * from (
      select 'Transaction Table' [Table], Records from #Txn union all
      select 'w/ Join IssuerType', Records from #IssuerType
) src


