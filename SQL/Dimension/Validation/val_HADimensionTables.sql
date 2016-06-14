
declare @now date, @start date, @end date

set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0)
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

if object_id('tempdb..#Txn') is not null drop table #Txn
select      count(*) Records  into #Txn
from  YapstoneDM..[Transaction] txn
where txn.PlatformId in (3,4)
      and txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)
 
if object_id('tempdb..#ProductType') is not null drop table #ProductType
select      count(*) Records  into #ProductType
from  YapstoneDM..[Transaction] txn 
            inner join ETLStaging..FinanceHAProductType p on txn.PlatformId = p.PlatformId and txn.IdClassId = p.IdClassId
where txn.PlatformId in (3,4)
      and txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)      

if object_id('tempdb..#PropertyOwners') is not null drop table #PropertyOwners
select      count(*) Records  into #PropertyOwners
from  YapstoneDM..[Transaction] txn 
            inner join ETLStaging..FinanceHAPropertyOwners c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
where txn.PlatformId in (3,4)
      and txn.PostDate_R between @start and @end
      and txn.TransactionCycleId in (1,3,4,9,16)   

select * from (
      select 'Transaction Table' [Table], Records from #Txn union all
      select 'w/ Join HAProductType', Records from #ProductType union all
      select 'w/ Join HAPropertyOwners', Records from #PropertyOwners
) src


