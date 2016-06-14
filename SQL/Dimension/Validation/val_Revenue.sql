declare @now as date, @start as date, @end as date

set @now = getdate()
set @start = dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 - 12 , 0) 
set @end = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0)) 

if object_id('tempdb..#Billing') is not null drop table #Billing
select * into #Billing from (
select
      cast(dateadd(d, -1 , dateadd(mm, (billing.Year - 1900) * 12 + billing.Month, 0)) as date) as Date,
      sum(Charge) Revenue
from
      ETLStaging..PropertyPaidBilling billing
group by 
	cast(dateadd(d, -1 , dateadd(mm, (billing.Year - 1900) * 12 + billing.Month, 0)) as date) 
) src
where Date between @start and @end

if object_id('tempdb..#BaseMPR') is not null drop table #BaseMPR
select
      Date, sum(Property_Fee) Revenue
      into #BaseMPR
from
      ETLStaging..FinanceBaseMPR
where
      Date between @start and @end
group by
	  Date

select *, [PropertyPaidBillingTable]-[BaseMPR] Delta from (
select * from (
      select Date,	'PropertyPaidBillingTable' [Table], Revenue from #Billing union all
      select Date,	'BaseMPR',  Revenue from #BaseMPR
) src
pivot (
	sum(Revenue)
	for [Table] in ([PropertyPaidBillingTable],[BaseMPR])
) pt
) src