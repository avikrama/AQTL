with dates as (
	 select	(date_trunc('Month',current_date) - interval '1 day')::date endd 
)
select
	Vertical,
	sum(Convenience_Fee_Net_USD)::money as Convenience_Fee_Net,
	sum(Net_Settled_Fee_Net_USD)::money as Net_Settled_Fee_Net_USD,	
	sum(Property_Fee)::money as Monthly_Billing,	
	sum(Revenue_Net_USD)::money as Total_Revenue
from
	mpr_base
where date in ( select endd from dates )
	and vertical not in ('Intl')
group by
	Vertical
union all
select
	'Total', 	
	sum(Convenience_Fee_Net_USD)::money as Convenience_Fee_Net,
	sum(Net_Settled_Fee_Net_USD)::money as Net_Settled_Fee_Net_USD,	
	sum(Property_Fee)::money as Monthly_Billing,	
	sum(Revenue_Net_USD)::money as Total
from
	mpr_base
where date in ( select endd from dates )
	and vertical not in ('Intl')
;