
declare @start as date = '2015-01-01', @end as date = '2015-12-31', @stateFilter as nvarchar(max)

set @stateFilter = 'CA'

if object_id('tempdb..##Person') is not null drop table ##Person
if object_id('tempdb..#Incoming') is not null drop table #Incoming
if object_id('tempdb..#Refunds') is not null drop table #Refunds
if object_id('tempdb..#Outgoing') is not null drop table #Outgoing
if object_id('tempdb..#Report') is not null drop table #Report


if object_id('tempdb..#DesiredParents') is not null drop table #DesiredParents

select
	c.PlatformId, c.ParentAccountId, c.ParentName
	into #DesiredParents
from
	ETLStaging..FinanceParentTable c
where
	(	c.Vertical in ('Rent')
		and c.ParentAccountId in (
		'36-13477290'	-- RadPad
			)
	) or 
	c.Vertical in ('NonProfit') 
group by
	c.PlatformId, c.ParentAccountId, c.ParentName
	


select * into ##Person from (
	select 1 as PlatformId, BusinessEntity_companyId as CompanyId, id as PersonId, State
	from  rpReportsTemp.rp.Person
	where state in (@stateFilter) and country in ('US')
	group by BusinessEntity_companyId , id , State
	union all
	select 2 as PlatformId, BusinessEntity_companyId as CompanyId, id as PersonId, State
	from  ipReportsTemp..Person ip
	where state in (@stateFilter) and country in ('US')
	group by BusinessEntity_companyId , id , State	
	union all
	select 3 as PlatformId, BusinessEntity_companyId as CompanyId, id as PersonId, State
	from  haReportsTemp..Person ha 
	where state in (@stateFilter) and country in ('US')
	group by BusinessEntity_companyId , id , State
	union all
	select 4 as PlatformId, BusinessEntity_companyId as CompanyId, id as PersonId, State
	from  GD1ReportsTemp..Person gd1 
	where state in (@stateFilter) and country in ('US')
	group by BusinessEntity_companyId , id , State	
) src 
       
-- Incoming payment made by person from California
select
	txn.PostDate_R Date ,	sum(txn.Amount - txn.AmtNetConvFee -txn.AmtNetPropFee) Incoming , count(*) Incoming_Count
	into #Incoming
from
	YapstoneDM..[Transaction] txn
	join ETLStaging..FinanceParentTable c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
	join #DesiredParents d on c.PlatformId = d.PlatformId and c.ParentAccountId = d.ParentAccountId
	join ##Person Person on  txn.PlatformId = Person.PlatformId and Person.CompanyId = c.ChildCompanyId and Person.PersonId = txn.Ref_PersonId
where
	txn.TransactionCycleId in (1)
	and txn.PostDate_R between @start and @end
	and txn.ProcessorId not in (14,16)
	and txn.Ref_BatchTypeId in (1)
group by 
	txn.PostDate_R
	
-- Refund made by person from California
select
	txn.PostDate_R Date,	sum(txn.Amount) Refunds , count(*) Refunds_Count
	into #Refunds
from
	YapstoneDM..[Transaction] txn
	join ETLStaging..FinanceParentTable c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
	join #DesiredParents d on c.PlatformId = d.PlatformId and c.ParentAccountId = d.ParentAccountId
	join ##Person Person on  txn.PlatformId = Person.PlatformId and Person.CompanyId = c.ChildCompanyId and Person.PersonId = txn.Ref_PersonId
where
	txn.TransactionCycleId in (9)
	and txn.PostDate_R between @start and @end
	and txn.ProcessorId not in (14,16)
	and txn.Ref_BatchTypeId in (1)
group by 
	txn.PostDate_R
	

-- Disbursement to child merchant in California
select
	txn.PostDate_R Date,	sum(txn.Amount) Outgoing , count(*) Outgoing_Count
	into #Outgoing
from
	YapstoneDM..[Transaction] txn
	join ETLStaging..FinanceParentTable c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
	join YapstoneDM..Company cc on txn.PlatformId = cc.PlatformId and txn.Ref_CompanyId = cc.CompanyId
	join #DesiredParents d on c.PlatformId = d.PlatformId and c.ParentAccountId = d.ParentAccountId
where
	txn.TransactionCycleId in (2)
	and txn.PostDate_R between @start and @end
	and txn.ProcessorId not in (14,16)
	and txn.Ref_BatchTypeId in (1)
	and cc.Address_StateProvince in (@stateFilter) and cc.Address_CountryId in ('US')
group by 
	txn.PostDate_R
	
	
select
	coalesce(i.Date,r.Date,o.Date) Date , 
	sum(i.Incoming) Incoming, sum(r.Refunds) Refunds, sum(o.Outgoing) Outgoing
	into #Report
from
	#Incoming i
	full outer join #Refunds r on i.Date = r.Date
	full outer join #Outgoing o on o.Date = i.Date
group by 
	coalesce(i.Date,r.Date,o.Date) 

