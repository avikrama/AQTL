select crosstabcode('globalpayments','month','currency','cast(sum(total_fees)/sum(txn_amount)*100 as decimal(48,2))','text');

select * from crosstab (  'select month,currency,cast(sum(total_fees)/sum(txn_amount)*100 as decimal(48,2)) from globalpayments group by 1,2 order by 1,2',  'select distinct currency from globalpayments order by 1'  )  as ct (  month varchar,CAD text,EUR text,GBP text,USD text  );



select * from crosstab(
'select
	month, currency,
	cast(sum(total_fees)/sum(txn_amount)*100 as decimal(48,2)) as perfee
from
	globalpayments
where
	Transaction_Type in (''Gross'')
group by
	month, currency
order by 
	month'
,'select distinct currency from globalpayments order by 1')
as ct("Month"text,"EUR"text,"GBP"text,"USD"text,"CAD"text);
