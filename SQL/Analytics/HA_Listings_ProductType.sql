declare @start as date, @end as date, @now as date
			
set @now	= getdate()			
set @start	= '2011-01-01'
set @end    = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  
					
select					
	year(txn.postdate_r) as Year,	
	txn.PlatformId , HAProd.ProductType,		
	count(distinct(c.accountId)) as ListingsCount 
from					
	YapstoneDM.dbo.[Transaction] txn				
	inner join YapstoneDM.dbo.Company c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.CompanyId			         					
	inner join ETLStaging..FinanceHAProductType HAProd on HAProd.IdClassId = txn.IdClassId and HAProd.PlatformId = txn.PlatformId 
where					
	txn.PostDate_R between @start and @end			
	and txn.PlatformId in (3,4)				
	and txn.ProcessorId not in (14,16)				
	and txn.TransactionCycleId in (1)				
group by					
	year(txn.postdate_r) , 
	txn.PlatformId , HAProd.ProductType		
order by 1, 2


