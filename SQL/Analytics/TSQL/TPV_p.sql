declare @maxYear as nvarchar(max) , 
---- Query Helpers
@paymentTypes as nvarchar(max), @allVerticals as nvarchar(max), @PaymentTypeGroup as nvarchar(max), @months as nvarchar(max),
---- Queries
@VerticalTPV as nvarchar(max), @averageTicket as nvarchar(max);

select @paymentTypes = stuff((select ',' + quotename(colName) from (
   select distinct(PaymentTypeGroup) as colName 
   from ETLStaging..FinanceAnalytics
       ) sub order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
       
select @allVerticals = stuff((select ',' + quotename(colName,'''') from (
   select distinct(Vertical) as colName 
   from ETLStaging..FinanceAnalytics
       ) sub order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')
       
select @months = stuff((select ',' + quotename(colName,'') from (
   select distinct(Month) as colName 
   from ETLStaging..FinanceAnalytics
       ) sub order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')


set @VerticalTPV = '
with TPV as (
select *  from (
select /* td.Vertical , */
       Year, Month, PaymentTypeGroup,
       sum(TPV_USD) TPV_USD
from   ETLStaging..FinanceAnalytics
where 1 =1 
	and Vertical in ('+@allVerticals+')
	and Gateway in (''YapProcessing'')
group by /* td.Vertical , */
	Year, Month, PaymentTypeGroup
) sub
pivot
(
       sum(TPV_USD)
       for [Month] in ('+@months+')
) as PivotTable
)
select Year, PaymentTypeGroup, '+@months+'
from TPV
order by Year'

     

exec sp_executesql @VerticalTPV
--exec sp_executesql @averageTicket




