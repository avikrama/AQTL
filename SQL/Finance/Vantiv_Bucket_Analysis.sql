declare @now as date, @start as date, @end as date

set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0)
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

select 
       c.Vertical, sum(case when txn.ProcessorId in (6) then txn.Amount else 0 end) as Paymentech, sum(case when txn.ProcessorId in (22) then txn.Amount else 0 end) as Vantiv 
       -- case when convert(varchar,cast(sum(txn.Amount) as money),1) TPV
from 
       YapstoneDM..[Transaction] txn 
       inner join ETLStaging..FinanceParentTable c on c.PlatformId = txn.PlatformId and c.ChildCompanyId = txn.Ref_CompanyId
where 
       c.Vertical in ('Rent', 'Dues','Inn','VRP','SRP','NonProfit','HA')
       and txn.ProcessorId not in (14,16)
       and txn.PlatformId in (1,2,3)
       and txn.TransactionCycleId in (1) 
       and txn.ProcessorId in (6,22)
       and txn.PaymentTypeId in (1,2,3,11,12)
       and txn.Ref_BatchTypeId in (1,2)
       and txn.PostDate_R  between @start and @end
group by
       c.Vertical
