with Date as (
   select (date_trunc('Month',current_date) - interval '1 day')::DATE as StartDate
			-- select '2016-03-31'::date as StartDate
), Analytics as (
			select /*PlatformId,*/ sum(TPV_USD) TPV_USD, sum(Card_Volume_USD) Card_Volume_USD, 0 Revenue_USD, 0 Revenue_Net_USD
			from  Analytics
			where Date = ( select StartDate from Date )
						and Gateway in ('YapProcessing')
						and PlatformId in (1,2,3)
						and Vertical not in ('Intl')
			--group by  PlatformId order by 1
), TopData as (
			select /*PlatformId,*/ sum(TPV_USD) TPV_USD, sum(Card_Volume_USD) Card_Volume_USD, sum(Revenue_USD) Revenue_USD, 0 Revenue_Net_USD
			from  Top_Data
			where Date = ( select StartDate from Date )
						and Gateway in ('YapProcessing')
						and PlatformId in (1,2,3)
						and Vertical not in ('Intl')
			--group by  PlatformId order by 1
), MPR_Base as (
			select /*PlatformId,*/ sum(TPV_USD) TPV_USD, sum(Card_Volume_USD) Card_Volume_USD, sum(Revenue_USD) Revenue_USD, sum(Revenue_Net_USD) Revenue_Net_USD
			from  MPR_Base
			where Date = ( select StartDate from Date )
						and Gateway in ('YapProcessing')
						and PlatformId in (1,2,3)
						and Vertical not in ('Intl')
			--group by  PlatformId order by 1
), MPR as (
			select /*PlatformId,*/ sum(TPV_USD) TPV_USD, sum(case when PaymentTypeGroup in ('Card','AmEx-Processing') then TPV_USD else 0 end) Card_Volume_USD, 0 Revenue_USD, sum(Revenue) Revenue_Net_USD
			from  MPR
			where Date = ( select StartDate from Date )
						and Gateway in ('YapProcessing')
						and PlatformId in (1,2,3)
						and Vertical not in ('Intl')
			--group by  PlatformId order by 1
)
select * from (
			select 'Analytics' as "Table", *    from Analytics union all
			select 'TopData', *                 from TopData union all
			select 'MPR_Base', *                from MPR_Base union all
			select 'MPR', *                     from MPR 
) src

			


