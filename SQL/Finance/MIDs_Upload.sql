declare @now date, @start date, @end date

set @now = getdate()
set @start = dateadd(yy,-1,dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0))
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

if object_id('tempdb..#Mids') is not null drop table #Mids
select PlatformId, Vertical, ParentAccountId, ParentName, Processor, case when Processor in ('Vantiv') then '4445'+cast(ProcessorMid as varchar) else cast(ProcessorMid as varchar) end as ProcessorMid
	into #Mids 
from (
	select 1 as PlatformId, 
		c.Vertical , c.ParentAccountId, c.ParentName,-- c.ChildAccountId, c.ChildName ,	
		case when cct.processor in (8,9,11) then 'Paymentech' when cct.processor in (10) then 'TSYS' when cct.processor in (13,14) then 'Vantiv' else cast(cct.processor as varchar) end as Processor, 
		t.merchantid as ProcessorMid
	from 
		rpReports.rp.Transfer (nolock) t
		inner join rpReports.rp.creditCardTransfer cct on t.id = cct.id and t.classid = cct.classid
		inner join ETLStaging..FinanceParentTable c on c.PlatformId = 1 and c.ChildCompanyId = t.BusinessEntity_companyId
	where 
		cct.processor not in (10) -- Gateway Only
		and t.posted between @start and dateadd(s,-1,dateadd(d,1,cast(@end as datetime)))
		and cct.processor in (
			8,	-- Frame_relay
			9,	-- Direct_funding
			-- 10, -- Tsys
			11, -- Tampa
			13, -- Vantiv
			14	-- Vantiv_direct_funding
		)
	group by
		c.Vertical , c.ParentAccountId,c.ParentName,-- c.ChildAccountId, c.ChildName ,	
		case when cct.processor in (8,9,11) then 'Paymentech' when cct.processor in (10) then 'TSYS' when cct.processor in (13,14) then 'Vantiv' else cast(cct.processor as varchar) end , 
		t.merchantid 
		
	union

	select 2 as PlatformId, 
		c.Vertical , c.ParentAccountId,c.ParentName,-- c.ChildAccountId, c.ChildName ,	
		case when cct.processor in (8,9,11) then 'Paymentech' when cct.processor in (10) then 'TSYS' when cct.processor in (13,14) then 'Vantiv' else cast(cct.processor as varchar) end as Processor, 
		t.merchantid as ProcessorMid
	from 
		ipReports..Transfer (nolock) t
		inner join ipReports..creditCardTransfer cct on t.id = cct.id and t.classid = cct.classid
		inner join ETLStaging..FinanceParentTable c on c.PlatformId = 2 and c.ChildCompanyId = t.BusinessEntity_companyId
	where 
		cct.processor not in (10) -- Gateway Only
		and t.posted between @start and dateadd(s,-1,dateadd(d,1,cast(@end as datetime)))
		and cct.processor in (
			8,	-- Frame_relay
			9,	-- Direct_funding
			-- 10, -- Tsys
			11, -- Tampa
			13, -- Vantiv
			14	-- Vantiv_direct_funding
		)
	group by
		c.Vertical , c.ParentAccountId,c.ParentName,-- c.ChildAccountId, c.ChildName ,	
		case when cct.processor in (8,9,11) then 'Paymentech' when cct.processor in (10) then 'TSYS' when cct.processor in (13,14) then 'Vantiv' else cast(cct.processor as varchar) end , 
		t.merchantid 
		
	union

	select 3 as PlatformId, 
		c.Vertical , c.ParentAccountId,c.ParentName,-- c.ChildAccountId, c.ChildName ,	
		case when cct.processor in (8,9,11) then 'Paymentech' when cct.processor in (10) then 'TSYS' when cct.processor in (13,14) then 'Vantiv' else cast(cct.processor as varchar) end as Processor, 
		t.merchantid as ProcessorMid
	from 
		haReports..Transfer (nolock) t
		inner join haReports..creditCardTransfer cct on t.id = cct.id and t.classid = cct.classid
		inner join ETLStaging..FinanceParentTable c on c.PlatformId = 3 and c.ChildCompanyId = t.BusinessEntity_companyId
	where 
		cct.processor not in (10) -- Gateway Only
		and t.posted between @start and dateadd(s,-1,dateadd(d,1,cast(@end as datetime)))
		and cct.processor in (
			8,	-- Frame_relay
			9,	-- Direct_funding
			-- 10, -- Tsys
			11, -- Tampa
			13, -- Vantiv
			14	-- Vantiv_direct_funding
		)
	group by
		c.Vertical , c.ParentAccountId,c.ParentName,-- c.ChildAccountId, c.ChildName ,	
		case when cct.processor in (8,9,11) then 'Paymentech' when cct.processor in (10) then 'TSYS' when cct.processor in (13,14) then 'Vantiv' else cast(cct.processor as varchar) end , 
		t.merchantid 
) src

select * from #Mids 
