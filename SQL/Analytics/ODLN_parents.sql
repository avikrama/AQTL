with Dates as (
	select 
	(date_trunc('Month',current_date) - interval '1 day')::date now,
	date_part('Year',(date_trunc('Month',current_date) - interval '1 day + 1 year')::date) as PriorYear,
	date_part('year',(date_trunc('Month',current_date) - interval '1 day')::date) as CurrentYear,
	date_part('month',(date_trunc('Month',current_date) - interval '1 day')::date) as CurrentMonth
)
, Filter as (
	select 'Rent'::text as Vertical,
	'Organic'::text as Tag
)
, Parents as (
	select 
		Year, Vertical, SoftwareName, ParentName, sum(TPV_USD) TPV_USD
	from
		top_data
	where
		Gateway in ('YapProcessing')
		and Year between ( select PriorYear from Dates ) and ( select CurrentYear from Dates )
		and Month between (1) and ( select CurrentMonth from Dates )
	group by
		Year, Vertical, SoftwareName, ParentName
), ParentYear as (
	select Vertical, SoftwareName, ParentName, 
		sum(case when Year in (select PriorYear from Dates) then TPV_USD else 0 end) as PriorYear,
		sum(case when Year in (select CurrentYear from Dates) then TPV_USD else 0 end) as CurrentYear
	from
		Parents
	group by Vertical, SoftwareName, ParentName
), Classifier as (
	select 
		Vertical, 
		case when ( PriorYear < CurrentYear or PriorYear = CurrentYear ) and PriorYear <> 0 then 'Organic'
			when PriorYear > CurrentYear and CurrentYear <> 0 then 'Deceleration'
			when CurrentYear = 0 then 'Lost'
			else 'New' end as Tag,
		SoftwareName, ParentName ,
		sum(PriorYear) as PriorYear, sum(CurrentYear) as CurrentYear, sum(CurrentYear) - sum(PriorYear) as Delta
	from
		ParentYear
	group by
		Vertical, ParentName, SoftwareName,
		case when ( PriorYear < CurrentYear or PriorYear = CurrentYear ) and PriorYear <> 0 then 'Organic'
			when PriorYear > CurrentYear and CurrentYear <> 0 then 'Deceleration'
			when CurrentYear = 0 then 'Lost'
			else 'New' end 
)
select 
	*
from 
	Classifier
--where 
--		Vertical in ( select Vertical from Filter )
--		and Tag in ( select Tag from Filter )
order by Delta desc
