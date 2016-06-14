declare @now as date, @start as date, @end as date
 
set @now = getdate()
set @start = '2015-01-01'
set @end = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0)) 
   

if object_id('tempdb..#Capacity') is not null drop table #Capacity
select 
	c1.AccountId as AccountId,c1.PlatformId as PlatformId,
    c1.Capacity as Capacity
    into #Capacity
from  
	YapstoneDM..Company c1
where 
	c1.PlatformId = 1

select 
	Year(txn.postdate_r) Year, Month(txn.postdate_r) Month,
    txn.PlatformId PlatformId,   c.Vertical ,  
    c.ParentAccountId,c.ParentName,
    count(distinct(cast(c.PlatformId as varchar)+cast(c.ChildAccountId as varchar))) #of_Child_Props,
    capacity.Capacity, 
    sum(case when txn.PaymentTypeId in (1,2,3) then txn.amount 
		when txn.PaymentTypeId in(10) and txn.processorid in (22) and txn.Ref_BatchTypeId in(1) then txn.amount else 0 end) CC_Volume,
    sum(case when txn.PaymentTypeId in (11,12) then txn.amount else 0 end) Debit_Volume,
    sum(case when txn.PaymentTypeId in (4,5) then txn.amount else 0 end) ACH_Volume,
    sum(case when txn.PaymentTypeId in (1,2,3) then txn.AmtNetConvFee 
		when txn.PaymentTypeId in(10) and txn.processorid in (22) and txn.Ref_BatchTypeId in(1) then txn.AmtNetConvFee else 0 end) CC_Revenue,
    sum(case when txn.PaymentTypeId in (11,12) then txn.AmtNetConvFee else 0 end) Debit_Revenue,
    sum(case when txn.PaymentTypeId in (4,5) then txn.AmtNetConvFee else 0 end) ACH_Revenue,
    sum(case when txn.PaymentTypeId in (1,2,3) then 1 
		when txn.PaymentTypeId in(10) and txn.processorid in (22) and txn.Ref_BatchTypeId in(1) then 1 else 0 end) CC_Count,
    sum(case when txn.PaymentTypeId in (11,12) then 1 else 0 end) Debit_Count,
    sum(case when txn.PaymentTypeId in (4,5) then 1 else 0 end) ACH_Count
from  
	YapstoneDM.dbo.[Transaction] txn with (nolock)   
    inner join ETLStaging.dbo.FinanceParentTable c with (nolock) on c.PlatformId = txn.PlatformId and c.ChildCompanyId = txn.Ref_CompanyId
    inner join #Capacity capacity on Capacity.platformid = c.PlatformId and c.ParentAccountId = Capacity.accountid
where
	txn.ProcessorId not in (14,16)
	and txn.TransactionCycleId in (1)     
	and txn.PlatformId in (1) 
	and txn.PostDate_R between  @start and @end
	and txn.PaymentTypeId in (1,2,3,4,5,10,11,12) 
	and c.Vertical = 'Rent'
	and txn.AmtNetConvFee <>0
group by  
	YEAR(txn.postdate_r) , Month(txn.postdate_r),    
    txn.PlatformId, c.Vertical, 
    c.ParentAccountId,c.ParentName,capacity.Capacity
order by 
	1,2





