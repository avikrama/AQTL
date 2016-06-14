
--Query Helpers
declare @dates as nvarchar(max), @start date, @end as date, @yearAgo as nvarchar(max), @years as nvarchar(max), @months as nvarchar(max), @yearAgoYear as nvarchar(max),
@now as date, @cy as int, @py as int,
--Queries
@Present as nvarchar(max) ,@Then as nvarchar(max), @MerchantTable as nvarchar(max);

set @now = getdate()
set @cy = year(@now)
set @py = @cy - 1

select @dates = stuff((select ',' + quotename(colName) from (
       select distinct(cast([Date] as date)) as colName 
       from ETLStaging..FinanceTopData 
       where Year >= @py
       ) sub order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')

select @years = stuff((select ',' + quotename(colName) from (
       select distinct([Year]) as colName 
       from ETLStaging..FinanceTopData 
       where Year >= @py
       ) sub order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
       
select @months = stuff((select ',' + quotename(colName,'''') from (
       select distinct([Month]) as colName 
       from ETLStaging..FinanceTopData 
       where Year >= @cy
       ) sub order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
       
set @start		=	dateadd(d,1,dateadd(m,-1,substring(@dates,charindex(',',@dates)-11,10)))
set @end		=	cast(substring(@dates,len(@dates)-10,10) as date)
set @yearAgo	=	cast(dateadd(m,-12,substring(@dates,len(@dates)-10,10)) as date)

set @yearAgoYear	= year(@yearAgo);




set @Present = '
;with cte as (
select *  from (
select Year(txn.PostDate_r) Year ,
       Vertical , txn.PlatformId, ChildAccountId , ChildName, 
       sum(txn.Amount) TPV_USD
from   YapstoneDM..[Transaction] txn with (nolock)     
              join ETLStaging..FinanceParentTable c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
where 1 = 1
              and txn.ProcessorId not in (14,16) 
              and txn.PlatformId in (1,2,3,4)
              and txn.TransactionCycleId in (1)
              and month(txn.postdate_r) in ('+@months+')
              and txn.PostDate_R between '''+cast(@start as varchar)+''' and '''+cast(@end as varchar)+'''
group by Year(txn.PostDate_r) ,
       Vertical , txn.PlatformId, ChildAccountId , ChildName
       ) sub
pivot
(
       sum(TPV_USD)
       for [Year] in ('+@years+')
) as PivotTable
)
select
       Vertical, isnull(Lost,0) Lost, isnull(New,0) New, (isnull(Organic,0) + isnull(Deceleration,0) + isnull(New,0)) as ['+cast(@end as varchar)+']  
       into #Now
from (select 
       Tag, 
       Vertical, 
       count(distinct(cast(PlatformId as varchar)+cast(ChildAccountId as varchar))) #of_Merchants from (
                     select Vertical, PlatformId, ChildAccountId, 
						case when ( ['+cast(@py as varchar)+'] <	['+cast(@cy as varchar)+']	or		['+cast(@py as varchar)+'] = ['+cast(@cy as varchar)+'] ) and ( ['+cast(@py as varchar)+']  is not null and ['+cast(@py as varchar)+'] <> 0 ) then ''Organic''  /* <-- Good  */
									 when	['+cast(@py as varchar)+'] >	['+cast(@cy as varchar)+']	and (	['+cast(@cy as varchar)+'] is not null and ['+cast(@cy as varchar)+'] <> 0 ) then ''Deceleration''
									 when	['+cast(@cy as varchar)+'] is		null or ['+cast(@cy as varchar)+'] = 0 then ''Lost''	
									else ''New''
									end as Tag
                     from cte
                     where (['+cast(@py as varchar)+'] is not null or ['+cast(@cy as varchar)+'] is not null)
                     group by Vertical, PlatformId, ChildAccountId ,
						case when ( ['+cast(@py as varchar)+'] <	['+cast(@cy as varchar)+']	or		['+cast(@py as varchar)+'] = ['+cast(@cy as varchar)+'] ) and ( ['+cast(@py as varchar)+']  is not null and ['+cast(@py as varchar)+'] <> 0 ) then ''Organic''  /* <-- Good  */
									 when	['+cast(@py as varchar)+'] >	['+cast(@cy as varchar)+']	and (	['+cast(@cy as varchar)+'] is not null and ['+cast(@cy as varchar)+'] <> 0 ) then ''Deceleration''
									 when	['+cast(@cy as varchar)+'] is		null or ['+cast(@cy as varchar)+'] = 0 then ''Lost''	
									else ''New''
									end 
                     ) src
       group by 
       Tag, 
       Vertical
) src
pivot
(
       sum(#of_Merchants)
       for [Tag] in ([Lost],[New],[Organic],[Deceleration])
) as PivotTable'

set @Then = '
select * 
       into #Then
from (
select 
	Year(txn.PostDate_R) Year ,
       Vertical , 
       count(distinct(cast(c.PlatformId as varchar)+cast(ChildAccountId as varchar))) #of_Merchants
from   YapstoneDM..[Transaction] txn    
              join ETLStaging..FinanceParentTable c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.ChildCompanyId
where 1 = 1
              and txn.ProcessorId not in (14,16) 
              and txn.PlatformId in (1,2,3,4)
              and txn.TransactionCycleId in (1)
              and month(txn.postdate_r) in ('+@months+')
              and year(txn.postdate_r) in (year('''+cast(@start as varchar)+'''))
group by
	Year(txn.PostDate_R) ,
       Vertical  
       ) sub
pivot
(
       sum(#of_Merchants)
       for [Year] in (['+@yearAgoYear+'])
) as PivotTable'

set @MerchantTable = '
select 
       t.Vertical , t.['+cast(@yearAgoYear as varchar)+'], null Lost, null New, n.['+cast(@end as varchar)+']
from #Then t
       join #Now n on t.Vertical = n.Vertical'


exec(@Present+';'+@Then+';'+@MerchantTable)





