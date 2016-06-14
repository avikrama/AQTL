with month as ( 
	select (date_trunc('Month',current_date) - interval '1 day')::DATE date 
)
select  	
	mids.Vertical, Network, Card_Type, Issuer_Type,     	
	sum(Txn_Count) txn_count, sum(Txn_Amount) txn_amount, sum(Interchange) interchange
from  vantiv   	
	inner join (  	
		select  Vertical, ProcessorMid  	
		from    mids  	
		where   Processor in ('Vantiv')  	
		group by Vertical, ProcessorMid    	
	) mids on mids.ProcessorMid = vantiv.Merchant_Id 
where  Month in ( select date from month )     	
	and Merchant_Descriptor not like 'PAY*PENDING%'
group by  	
	mids.Vertical, 	Network, Card_Type, Issuer_Type
order by 
	Vertical, Network, Card_Type, Issuer_Type

