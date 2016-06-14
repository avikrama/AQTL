declare @now as date, @start as date, @end as date

set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0)
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  


if object_id('tempdb..#YapDM') is not null drop table #YapDM
select      /*PlatformId,*/ sum(txn.amount * fx.Rate) TPV_USD,    sum(case when txn.paymenttypeid in (1, 2, 3, 11, 12, /* <-- regular cards */ /* pre 2012 debit networks --> */  6,7,8,9) and txn.TransactionCycleId in (1) then txn.Amount when txn.PaymentTypeId in (10) and txn.ProcessorId in (22) and txn.Ref_BatchTypeId in (1) /* Amex , Bucket , Vantiv = Processing */ and txn.TransactionCycleId in (1) then txn.Amount else 0 end
      * fx.Rate ) as Card_Volume_USD, null Revenue_USD
      into #YapDM
from
      YapstoneDM..[transaction] txn
      inner join ETLStaging..FinanceFXRates fx on txn.PostDate_R = fx.Date and txn.CurrencyId = fx.CurrencyId
where
      txn.PostDate_r between @start and @end
      and txn.ProcessorId not in (14,16)
      and txn.TransactionCycleId in (1)
      and txn.PlatformId in (1,2,3)
-- group by PlatformId order by PlatformId   
  

if object_id('tempdb..#Analytics') is not null drop table #Analytics
select      /*PlatformId,*/ sum(TPV_USD) TPV_USD, sum(Card_Volume_USD) Card_Volume_USD, null Revenue_USD
      into #Analytics
from  ETLStaging..FinanceAnalytics
where Date = @end
      and Gateway in ('YapProcessing')
      and PlatformId in (1,2,3)
--group by  PlatformId order by 1
      
if object_id('tempdb..#TopData') is not null drop table #TopData
select      /*PlatformId,*/ sum(TPV_USD) TPV_USD, sum(Card_Volume_USD) Card_Volume_USD, sum(Revenue_USD) Revenue_USD
      into #TopData
from  ETLStaging..FinanceTopData
where Date = @end
      and Gateway in ('YapProcessing')
      and PlatformId in (1,2,3)
--group by  PlatformId order by 1

if object_id('tempdb..#MPR') is not null drop table #MPR
select      /*PlatformId,*/ sum(TPV_USD) TPV_USD, sum(Card_Volume_USD) Card_Volume_USD, sum(Revenue_USD) Revenue_USD
      into #MPR
from  ETLStaging..FinanceBaseMPR
where Date = @end
      and Gateway in ('YapProcessing')
      and PlatformId in (1,2,3)
--group by  PlatformId order by 1


select * from (
      select 'YapDM' [Table], *     from #YapDM union all
      select 'Analytics', *         from #Analytics union all
      select 'TopData', *                 from #TopData union all
      select 'MPR', *                     from #MPR
) src

      


