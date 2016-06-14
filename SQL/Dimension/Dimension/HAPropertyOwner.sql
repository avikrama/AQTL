-- HAPropertyOwner table
declare @start as date = '2011-01-01' , @end as date = getdate() 

if object_id('tempdb..#Platform') is not null drop table #Platform
select 4 as PlatformId , 'HA-Intl' as Vertical, case when ct.AggregateId like '1|87645%' then 'HomeAway' else 'Non-HomeAway' end as Merchant ,
	ct.AccountId , c.Name PlatformName, ct.AggregateId 
	into #Platform from (
		select case when bc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then c.id  when cc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then bc.id  
			when dc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then cc.id  when ec.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then dc.id 
			when fc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then ec.id  when gc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then fc.id else c.id end as Id
		from                                            
			Gd1ReportsTemp.dbo.Community ct 
			join Gd1ReportsTemp.dbo.Company c on c.Id = ct.id and c.classId = ct.classId
			join Gd1ReportsTemp.dbo.company bc on c.parentCompanyId = bc.id      		left join Gd1ReportsTemp.dbo.company cc on bc.parentCompanyId = cc.id  left join Gd1ReportsTemp.dbo.company dc on cc.parentCompanyId = dc.id               
			left join Gd1ReportsTemp.dbo.company ec on dc.parentCompanyId = ec.id  	left join Gd1ReportsTemp.dbo.company fc on ec.parentCompanyId = fc.id  left join Gd1ReportsTemp.dbo.company gc on fc.parentCompanyId = gc.id   
			left join Gd1ReportsTemp.dbo.company hc on gc.parentCompanyId = hc.id   
		group by case  when bc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then c.id  when cc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then bc.id  
			when dc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then cc.id  when ec.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then dc.id 
			when fc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then ec.id  when gc.id in (1, 87645, 111105, 176740, 176739, 176738, 91530, 94458, 220840, 223343 ) then fc.id  else c.id end 
	) inner_query
	inner join Gd1ReportsTemp.dbo.Community ct    on inner_query.id = ct.id and 19 = ct.classId
	inner join Gd1ReportsTemp.dbo.Company c       on c.id = ct.id and c.classId = ct.classId
group by 
	case when ct.AggregateId like '1|87645%' then 'HomeAway' else 'Non-HomeAway' end, ct.accountId, c.Name, ct.aggregateId

/* get platformid 3,4 base data */
if object_id('tempdb..#base34') is not null drop table #base34
select * into #base34 from (
	select c.PlatformId, case  when bc.CompanyId in (1,2,1001,1008,125214,223735 ) then c.CompanyId when cc.CompanyId in (1,2,1001,1008,125214,223735 ) then bc.CompanyId when dc.CompanyId in (1,2,1001,1008,125214,223735 ) then cc.CompanyId  
		when ec.CompanyId in (1,2,1001,1008,125214,223735 ) then dc.CompanyId when fc.CompanyId in (1,2,1001,1008,125214,223735 ) then ec.CompanyId  when gc.CompanyId in (1,2,1001,1008,125214,223735 ) then fc.CompanyId else c.CompanyId  end  CompanyId,
		min(txn.PostDate_R) as date_first_seen,
		max(txn.PostDate_R) as date_last_seen    
	from YapstoneDM.dbo.Company c  (nolock)
		join YapstoneDM.dbo.[Transaction] txn  (nolock) on c.PlatformId = txn.PlatformId and c.CompanyId = txn.Ref_CompanyId     		left join YapstoneDM.dbo.Company bc   (nolock) on c.parentCompanyId = bc.CompanyId and c.PlatformId = bc.PlatformId             
				 left join YapstoneDM.dbo.Company cc   (nolock) on bc.parentCompanyId = cc.CompanyId and bc.PlatformId = cc.PlatformId  left join YapstoneDM.dbo.Company dc   (nolock) on cc.parentCompanyId = dc.CompanyId and cc.PlatformId = dc.PlatformId   
				 left join YapstoneDM.dbo.Company ec   (nolock) on dc.parentCompanyId = ec.CompanyId and dc.PlatformId = ec.PlatformId  left join YapstoneDM.dbo.Company fc   (nolock) on ec.parentCompanyId = fc.CompanyId and ec.PlatformId = fc.PlatformId     
				 left join YapstoneDM.dbo.Company gc   (nolock) on fc.parentCompanyId = gc.CompanyId and fc.PlatformId = gc.PlatformId                  
	where  c.PlatformId = 3 and c.CompanyId not in ( 1,2,1001,1008,125214,223735 )
	group by c.PlatformId, case  when bc.CompanyId in (1,2,1001,1008,125214,223735 ) then c.CompanyId  when cc.CompanyId in (1,2,1001,1008,125214,223735 ) then bc.CompanyId when dc.CompanyId in (1,2,1001,1008,125214,223735 ) then cc.CompanyId  
					when ec.CompanyId in (1,2,1001,1008,125214,223735 ) then dc.CompanyId   when fc.CompanyId in (1,2,1001,1008,125214,223735 ) then ec.CompanyId  when gc.CompanyId in (1,2,1001,1008,125214,223735 ) then fc.CompanyId  else c.CompanyId  end 
	union
	select  c.PlatformId, case  when bc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then c.CompanyId   when cc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then bc.CompanyId      
		when dc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then cc.CompanyId  when ec.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930) then dc.CompanyId                  
		when fc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then ec.CompanyId  when gc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then fc.CompanyId    else c.CompanyId end CompanyId,
		min( txn.PostDate_R) as date_first_seen,
		max( txn.PostDate_R) as date_last_seen   
	from    YapstoneDM.dbo.Company c  with (nolock)
			 join YapstoneDM.dbo.[Transaction] txn with (nolock) on c.PlatformId = txn.PlatformId and c.CompanyId = txn.Ref_CompanyId  left join YapstoneDM.dbo.Company bc  with (nolock) on c.parentCompanyId = bc.CompanyId and c.PlatformId = bc.PlatformId             
			 left join YapstoneDM.dbo.Company cc  with (nolock) on bc.parentCompanyId = cc.CompanyId and bc.PlatformId = cc.PlatformId left join YapstoneDM.dbo.Company dc  with (nolock) on cc.parentCompanyId = dc.CompanyId and cc.PlatformId = dc.PlatformId   
			 left join YapstoneDM.dbo.Company ec  with (nolock) on dc.parentCompanyId = ec.CompanyId and dc.PlatformId = ec.PlatformId  left join YapstoneDM.dbo.Company fc  with (nolock) on ec.parentCompanyId = fc.CompanyId and ec.PlatformId = fc.PlatformId     
			 left join YapstoneDM.dbo.Company gc  with (nolock) on fc.parentCompanyId = gc.CompanyId and fc.PlatformId = gc.PlatformId                  
	where  c.PlatformId in (4) and c.CompanyId not in ( 101216,111105,87690,92713,87695,92714,87696,300930)  
	group by c.PlatformId,  case  when bc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then c.CompanyId  when cc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then bc.CompanyId      
		when dc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then cc.CompanyId  when ec.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930) then dc.CompanyId                  
		when fc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then ec.CompanyId  when gc.CompanyId in (101216,111105,87690,92713,87695,92714,87696,300930 ) then fc.CompanyId  else c.CompanyID end  
) src

if object_id('tempdb..#InnerQuery') is not null drop table #InnerQuery
select b.PlatformId,c.AccountId,b.date_first_seen,b.date_last_seen
	into #InnerQuery
from 
	#base34 b 
	join YapstoneDM..Company(nolock) c on b.PlatformId = c.PlatformId and b.Companyid = c.companyid

if object_id('tempdb..#PropertyOwner') is not null drop table #PropertyOwner   
select  
	inner_query.PlatformId, 	case  when c.PlatformId in (3) then 'HA'  when c.PlatformId in (4) then 'HA-Intl'end Vertical, isnull(Platform.Merchant,'Homeaway') Merchant , isnull(Platform.PlatformName,'Homeaway') PlatformName,
	c.CompanyId PropertyOwnerCompanyId, inner_query.AccountId PropertyOwnerAccountId, c.Name as PropertyOwnerName, c.AggregateId PropertyOwnerAggregateId,
	cast(dateadd(mm, datediff(mm, -1, min(inner_query.date_first_seen) ) , 0) -1 as date) as DateFirstSeen,
	cast(case when (dateadd(mm, datediff(mm, -1, max(inner_query.date_last_seen) ) , 0 ) -1 ) > @end then @end else dateadd(mm, datediff(mm, -1, max(inner_query.date_last_seen) ) , 0 ) -1 end as date) as DateLastSeen 
	into #PropertyOwner  
from #innerquery inner_query
	inner join YapstoneDM.dbo.Company c (nolock) on c.AccountId = inner_query.AccountId and c.PlatformId = inner_query.PlatformId     
	left join #Platform Platform  on  (c.aggregateId = Platform.AggregateId or c.aggregateId like Platform.AggregateId + '|%') and 4 = Platform.PlatformId      
group by  inner_query.PlatformId, case  when c.PlatformId in (3) then 'HA'  when c.PlatformId in (4) then 'HA-Intl'end , isnull(Platform.Merchant,'Homeaway'), isnull(Platform.PlatformName,'Homeaway') , 
	c.CompanyId, inner_query.AccountId, c.Name , c.AggregateId 

/**  lifted from usp_CreateParentChildTable to pull children....cannot 'like' join on text field */
begin if object_id('tempdb.dbo.#acct_hierarchyC') is not null begin drop table #acct_hierarchyC end
select c.PlatformId ,c.CompanyId ParentCompanyid
	c2.CompanyId  as Child2, c3.CompanyId  as Child3,
	c4.CompanyId  as Child4, c5.CompanyId  as Child5,
	c6.CompanyId  as Child6, c7.CompanyId  as Dhild7
	into #acct_hierarchyC
from YapstoneDM..Company (nolock) c join #PropertyOwner (nolock) p on c.platformid = p.platformid and  c.CompanyId = p.PropertyOwnerCompanyId
		left join YapstoneDM..Company (nolock) c2 on c.companyid = c2.parentcompanyid and c.platformid = c2.platformid
		left join YapstoneDM..Company (nolock) c3 on c2.companyid = c3.parentcompanyid and c2.platformid = c3.platformid
		left join YapstoneDM..Company (nolock) c4 on c3.companyid = c4.parentcompanyid and c3.platformid = c4.platformid
		left join YapstoneDM..Company (nolock) c5 on c4.companyid = c5.parentcompanyid and c4.platformid = c5.platformid
		left join YapstoneDM..Company (nolock) c6 on c5.companyid = c6.parentcompanyid and c5.platformid = c6.platformid
		left join YapstoneDM..Company (nolock) c7 on c6.companyid = c7.parentcompanyid and c6.platformid = c7.platformid
group by  c.PlatformId ,c.CompanyID,
	c2.CompanyID  ,c3.CompanyID,
	c4.CompanyID  ,c5.CompanyID
	c6.CompanyID,	c7.CompanyID

begin if OBJECT_ID('tempdb.dbo.#hierarchyC') is not null begin drop table #hierarchyC end
select * into #hierarchyC from (
 select distinct
	PlatformId, ParentCompanyid PropertyOwnerCompanyId,
	ParentCompanyId ChildCompanyId, cast(0 as integer) as lvl
	from #acct_hierarchyC 
union 
	select PlatformId, ParentCompanyId, Child2, cast(1 as integer) as lvl
	from #acct_hierarchyC
	where Child2 is not null
union
	select PlatformId, ParentCompanyId, Child3, cast(2 as integer) as lvl
	from #acct_hierarchyC 
	where Child3 is not null 
union
	select PlatformId, ParentCompanyId, Child4, cast(3 as integer) as lvl
	from #acct_hierarchyC 
	where Child4 is not null 
union
	select PlatformId, ParentCompanyid,	Child5, cast(4 as integer) as lvl
	from #acct_hierarchyC
	where Child5 is not null 
union
	select PlatformId, ParentCompanyid, Child6, cast(5 as integer) as lvl
	from #acct_hierarchyC 
	where Child6 is not null 
union
	select PlatformId,ParentCompanyid,	Child7, cast(6 as integer) as lvl
	from #acct_hierarchyC
	where Child7 is not null 
) src

drop table #acct_hierarchyC
/*end child pull */

if object_id('tempdb..#Company') is not null drop table #Company  
select ch.lvl,c.PlatformId , PropertyOwner.Vertical,  PropertyOwner.Merchant, PropertyOwner.PlatformName, 
	c.CompanyId ChildCompanyId , c.AccountId ChildAcountId, c.Name ChildName,
	PropertyOwner.PropertyOwnerAccountId , PropertyOwner.PropertyOwnerName
	into #Company
from YapstoneDM.dbo.Company c 
	join #hierarchyC ch on c.PlatformId = ch.PlatformId and ch.ChildCompanyId = c.CompanyId
	join #PropertyOwner PropertyOwner  on ch.PlatformId = PropertyOwner.PlatformId and ch.PropertyOwnerCompanyId = PropertyOwner.PropertyOwnerCompanyId
group by ch.lvl,c.PlatformId , PropertyOwner.Vertical,  PropertyOwner.Merchant, PropertyOwner.PlatformName, 
	c.CompanyId ChildCompanyId , c.AccountId ChildAcountId, c.Name ChildName,
	PropertyOwner.PropertyOwnerAccountId , PropertyOwner.PropertyOwnerName

select 
	* 
from 
	#Company 
where 
	lvl != 0  ---this lines takes out the parent record, do you want? obviously will kill lvl field in prod table
order by 
	PlatformId, PropertyOwnerName, lvl














