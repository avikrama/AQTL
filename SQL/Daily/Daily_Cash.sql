declare @now as date ,@start as date

set @now = getdate()
set @start  = dateadd(d,-1,@now)  -- Yesterday

if object_id('tempdb..#JE5') is not null drop table #JE5
select 
	txn.postdate_r,
	case when txn.transactioncycleid =1 and txn.PlatformId in (1,2) and txn.Ref_BatchTypeId = 1 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end as 'Bucket_Fees',
	case when txn.transactioncycleid in (9) and txn.PlatformId in (1,2) and txn.Ref_BatchTypeId = 1 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end as 'Bucket_Refunds',
	case when txn.TransactionCycleId in (3,4) and txn.PaymentTypeId = 4 and txn.platformid in (1,2) and txn.Ref_BatchTypeId = 1 then sum(txn.amtnetconvfee) end as 'Conv_Fee_Reversal',
	case when txn.transactioncycleid =1 and txn.PlatformId in (3) and txn.Ref_BatchTypeId = 1 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end as 'HA_Fees',
	case when txn.transactioncycleid in (9,3,4) and txn.PlatformId in (3) and txn.Ref_BatchTypeId = 1 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end as 'HA_Refunds_Reversals',
	case when txn.transactioncycleid =1 and txn.PlatformId in (1,2) and txn.Ref_BatchTypeId = 2 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end as 'DF_Fees'
into #JE5
from 
	YapstoneDM..[transaction]txn
where 
	txn.postdate_r = @start
group by 
	txn.postdate_r,
	txn.PlatformId,
	txn.TransactionCycleId,
	txn.PaymentTypeId,
	txn.Ref_BatchTypeId
having 
	case when txn.transactioncycleid =1 and txn.PlatformId in (1,2) then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end is not null
	or case when txn.transactioncycleid =9 and txn.PlatformId in (1,2) then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end  is not null
	or case when txn.TransactionCycleId in (3,4) and txn.PaymentTypeId = 4 and txn.platformid in (1,2) then sum(txn.amtnetconvfee) end is not null
	or case when txn.transactioncycleid =1 and txn.PlatformId in (3) and txn.Ref_BatchTypeId = 1 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end is not null
	or case when txn.transactioncycleid in (9,3,4) and txn.PlatformId in (3) and txn.Ref_BatchTypeId = 1 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end is not null
	or case when txn.transactioncycleid =1 and txn.PlatformId in (1,2) and txn.Ref_BatchTypeId = 2 then sum(txn.amtnetpropfee)+sum(txn.amtnetconvfee) end is not null

select 
	postdate_r,
	sum(Bucket_Fees)+sum(Bucket_Refunds) as 'Bucket_Conv_Fees',
	sum(Conv_Fee_Reversal) as 'Conv_Fee_Reversal',
	sum(HA_Fees)+sum(HA_Refunds_Reversals) as 'HA_Prop_Fees',
	sum(DF_Fees) as 'DF_Conv_Fees'
from #JE5
group by 
	postdate_r
order by 1
