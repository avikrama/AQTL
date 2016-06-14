
with Dates as (
	select 
	(date_trunc('Month',current_date) - interval '1 day')::date now,
	date_part('Year',(date_trunc('Month',current_date) - interval '1 day + 1 year')::date) as PriorYear,
	date_part('year',(date_trunc('Month',current_date) - interval '1 day')::date) as CurrentYear,
	date_part('month',(date_trunc('Month',current_date) - interval '1 day')::date) as CurrentMonth
)
, Parents as (
	select 
		Year, Vertical, ParentAccountId, ParentName, sum(TPV_USD) TPV_USD
	from
		top_data
	where
		Gateway in ('YapProcessing')
		and Year between ( select PriorYear from Dates ) and ( select CurrentYear from Dates )
		and Month between (1) and ( select CurrentMonth from Dates )
	group by
		Year, Vertical, ParentAccountId, ParentName
), ParentYear as (
	select Vertical, ParentAccountId, ParentName, 
		sum(case when Year in (select PriorYear from Dates) then TPV_USD else 0 end) as PriorYear,
		sum(case when Year in (select CurrentYear from Dates) then TPV_USD else 0 end) as CurrentYear
	from
		Parents
	group by Vertical, ParentAccountId, ParentName
), Classifier as (
	select 
		Vertical, ParentAccountId, ParentName ,
		case when ( PriorYear < CurrentYear or PriorYear = CurrentYear ) and PriorYear <> 0 then 'Organic'
			when PriorYear > CurrentYear and CurrentYear <> 0 then 'Deceleration'
			when CurrentYear = 0 then 'Lost'
			else 'New' end as Tag,
		sum(PriorYear) as PriorYear, sum(CurrentYear) as CurrentYear
	from
		ParentYear
	group by
		Vertical, ParentAccountId , ParentName,
		case when ( PriorYear < CurrentYear or PriorYear = CurrentYear ) and PriorYear <> 0 then 'Organic'
			when PriorYear > CurrentYear and CurrentYear <> 0 then 'Deceleration'
			when CurrentYear = 0 then 'Lost'
			else 'New' end 
)
select 
	Vertical, 	
				count(distinct(case when PriorYear <> 0 then ParentAccountId else '' end)) PriorYear, 
				null as Lost, null as New ,
				count(distinct(case when CurrentYear <> 0 then ParentAccountId else '' end)) CurrentYear
from 
	Classifier
group by Vertical
order by Vertical



