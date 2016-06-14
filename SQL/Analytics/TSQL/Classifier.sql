declare @Verticals as nvarchar(max), @Vertical as nvarchar(max), @Months as nvarchar(max), @Query as nvarchar(max),
@now as date, @cy as int, @py as int

set @now = getdate()
set @cy = year(@now)
set @py = @cy - 1

set @Vertical = 'Rent'

set @Verticals = stuff((select ',' + quotename(colName,'''') from (
   select 'Rent' as colName union all
   select 'Dues'
   ) sub_query order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
   
set @Months = stuff((select ',' + quotename(convert(varchar(10),colName),'''') from (
       select distinct(Month) as colName from ETLStaging..FinanceTopData where Year >= @cy
   ) sub_query order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
   
-- Magic

-- Board Organic/New Adds/Decelaration/Lost TPV
set @Query = '
;with cte as (
select *  from (
select Year ,
	Vertical , ParentName ,
	sum(TPV_USD) TPV_USD
from   ETLStaging..FinanceTopData
where Gateway in (''YapProcessing'')
	and Month in ('+@Months+')
group by Year ,
	Vertical , ParentName  
	) sub
pivot
(
	sum(TPV_USD)
	for [Year] in (['+cast(@cy as varchar)+'],['+cast(@py as varchar)+'])
) as PivotTable
) 
select Vertical, 
	case when ( ['+cast(@py as varchar)+'] <	['+cast(@cy as varchar)+']	or		['+cast(@py as varchar)+'] = ['+cast(@cy as varchar)+'] ) and ( ['+cast(@py as varchar)+']  is not null and ['+cast(@py as varchar)+'] <> 0 ) then ''Organic''  /* <-- Good  */
		 when	['+cast(@py as varchar)+'] >	['+cast(@cy as varchar)+']	and (	['+cast(@cy as varchar)+'] is not null and ['+cast(@cy as varchar)+'] <> 0 ) then ''Deceleration''
		 when	['+cast(@cy as varchar)+'] is		null or ['+cast(@cy as varchar)+'] = 0 then ''Lost''	
		else ''New''
		end as Tag, 
		sum(['+cast(@py as varchar)+']) as ['+cast(@py as varchar)+'], sum(['+cast(@cy as varchar)+']) as ['+cast(@cy as varchar)+'] 
from (
select Vertical, ParentName, sum(isnull(['+cast(@py as varchar)+'],0)) as ['+cast(@py as varchar)+'], sum(isnull(['+cast(@cy as varchar)+'],0)) ['+cast(@cy as varchar)+']
from cte
group by Vertical, ParentName
) as sub 
group by Vertical,
	case when ( ['+cast(@py as varchar)+'] <	['+cast(@cy as varchar)+']	or		['+cast(@py as varchar)+'] = ['+cast(@cy as varchar)+'] ) and ( ['+cast(@py as varchar)+']  is not null and ['+cast(@py as varchar)+'] <> 0 ) then ''Organic''  /* <-- Good  */
		 when	['+cast(@py as varchar)+'] >	['+cast(@cy as varchar)+']	and (	['+cast(@cy as varchar)+'] is not null and ['+cast(@cy as varchar)+'] <> 0 ) then ''Deceleration''
		 when	['+cast(@cy as varchar)+'] is		null or ['+cast(@cy as varchar)+'] = 0 then ''Lost''	
		else ''New''
		end'

exec(@Query)


