-- Active Listings Query
declare @start date, @end date, @now as date
 
set @now	=	'2015-01-31'
set @start	=	dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 - 9 , 0)
set @end	=	dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

if object_id('tempdb..#Ancillary_Revenue') is not null drop table #Ancillary_Revenue
select * into #Ancillary_Revenue from ( 
	select
		Year, Month, cast(dateadd(d, -1 , dateadd(mm, (Year - 1900) * 12 + Month, 0)) as date) as Date ,
		'HA' as Vertical, 'Ancillary' as ProductType, 'USD' as Currency, 
		sum(Charge) Revenue
	from
	ETLStaging..PropertyPaidBilling billing
	where
		PlatformID in (3)
	group by
		Year, Month, cast(dateadd(d, -1 , dateadd(mm, (Year - 1900) * 12 + Month, 0)) as date)
	) src 
where Date between @start and @end
 
if object_id('tempdb..#HA_Analytics_HA') is not null drop table #HA_Analytics_HA
select 
	@end as Month, 'HA' as Vertical, ProductType,
	case when Txn_Count <= 3 then '1 - 3 txns' when Txn_Count > 3 and Txn_Count <= 6 then '4 - 6 txns' when Txn_Count > 6 then '7+ txns' end as Frequency_Type ,
	sum(TPV_USD) TPV_USD,sum(Revenue_USD) Revenue_USD,sum(Txn_Count) Txn_Count, sum(#of_Listings) #of_Listings
	into #HA_Analytics_HA
	from ( 
		select
			Product.ProductType , count(distinct(c.AccountId)) #of_Listings,  
			sum(txn.Amount)as TPV_USD,  sum(txn.AmtNetPropFee) as Revenue_USD, count(*) as Txn_Count
		from                                            
		   YapstoneDM.dbo.[Transaction] txn
		   inner join YapstoneDM.dbo.Company c		on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.CompanyId  
		   inner join ETLStaging..FinanceHAProductType Product			on txn.IdClassId = Product.IdClassId and txn.PlatformId = Product.PlatformId
		where txn.PostDate_R between @start and @end 
			and txn.TransactionCycleId in (1) and txn.PlatformId in (3) and txn.ProcessorId not in (14,16)
			-- and txn.PaymentTypeId in (1,2,3,11,12)
		group by Product.ProductType, c.AccountId
	) src
group by
	ProductType, case when Txn_Count <= 3 then '1 - 3 txns' when Txn_Count > 3 and Txn_Count <= 6 then '4 - 6 txns' when Txn_Count > 6 then '7+ txns' end

if object_id('tempdb..#HA_Analytics_HA_Report') is not null drop table #HA_Analytics_HA_Report
select
	HA.Month, HA.Vertical, HA.ProductType, HA.Frequency_Type,
	HA.TPV_USD, sum(HA.Revenue_USD + isnull(Anc.Revenue,0)) Revenue_USD, HA.Txn_Count, HA.[#of_Listings]
	into #HA_Analytics_HA_Report
from 
	#HA_Analytics_HA HA
	left join #Ancillary_Revenue Anc on --HA.Year = Anc.Year and HA.Month = Anc.Month 
		HA.ProductType = Anc.ProductType and HA.Vertical = Anc.Vertical
group by
	HA.Month, HA.Vertical, HA.ProductType, HA.Frequency_Type, 
	HA.TPV_USD, HA.Txn_Count, HA.[#of_Listings]


if object_id('tempdb..#HA_Analytics_GD1') is not null drop table #HA_Analytics_GD1
select @end as Month, 'HA-Intl' as Vertical, ProductType, case when Txn_Count <= 3 then '1 - 3 txns' when Txn_Count > 3 and Txn_Count <= 6 then '4 - 6 txns'when Txn_Count > 6 then '7+ txns' end as Frequency_Type ,  
	sum(TPV_USD) TPV_USD, sum(Revenue_USD) Revenue_USD, sum(Txn_Count) Txn_Count, sum(#of_Listings) #of_Merchants
	into #HA_Analytics_GD1 from (
		select 
			Product.ProductType , count(distinct(c.AccountId)) #of_Listings,  
			sum(txn.Amount * fx.Rate) as TPV_USD, sum(txn.AmtNetPropFee ) as Revenue_USD, count(*) as Txn_Count 
		from                                            
		   YapstoneDM.dbo.[Transaction] txn
		   inner join YapstoneDM.dbo.Company c on txn.PlatformId = c.PlatformId and txn.Ref_CompanyId = c.CompanyId  
		   inner join YapstoneDM.dbo.Currency	on txn.CurrencyId = Currency.CurrencyId
		   inner join ETLStaging..FinanceHAProductType Product	on txn.IdClassId = Product.IdClassId and txn.PlatformId = Product.PlatformId
		   inner join ETLStaging..FinanceFXRates fx on  txn.PostDate_R = fx.Date and txn.CurrencyId = fx.CurrencyId
		where             
			txn.PostDate_R between @start and @end 
			and txn.ProcessorId not in (14,16)
			and txn.PlatformId in (4)
			-- and txn.PaymentTypeId in (1,2,3,11,12)
			and txn.TransactionCycleId in (1)
		group by
		  Product.ProductType, c.AccountId 
	) src
group by
	ProductType, case when Txn_Count <= 3 then '1 - 3 txns' when Txn_Count > 3 and Txn_Count <= 6 then '4 - 6 txns'when Txn_Count > 6 then '7+ txns' end


select * 
from #HA_Analytics_HA_Report
union
select * 
from #HA_Analytics_GD1




