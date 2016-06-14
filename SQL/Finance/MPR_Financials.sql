with dates as (
	 select	(date_trunc('Month',current_date) - interval '1 day')::date endd 
)
select
	Vertical,
	sum(TPV_USD)::money as TPV_USD,
	sum(Revenue)::money as Revenue_Net_USD,
	sum(COGS_USD)::money as COGS_USD,
	round((sum(Revenue)-sum(COGS_USD))/sum(Revenue)*100,2)||'%' Accounting_Margin
from
	MPR
where date in ( select endd from dates )
	and vertical not in ('Intl')
group by
	Vertical
union all
select
	'Total',	
	sum(TPV_USD)::money as TPV_USD,
	sum(Revenue)::money as Revenue_Net_USD,
	sum(COGS_USD)::money as COGS_USD,
	round((sum(Revenue)-sum(COGS_USD))/sum(Revenue)*100,2)||'%' Accounting_Margin
from
	MPR
where date in ( select endd from dates )
	and vertical not in ('Intl')
;
