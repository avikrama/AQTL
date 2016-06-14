declare @maxYear as nvarchar(max) , 
---- Query Helpers
@paymentTypes as nvarchar(max), @allVerticals as nvarchar(max), @PaymentTypeGroup as nvarchar(max), @months as nvarchar(max), @years as nvarchar(max),
---- Queries
@txnCount as nvarchar(max), @tpv as nvarchar(max), @averageTicket as nvarchar(max), @averageTicketYear as nvarchar(max);

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

select @years = stuff((
       select ',' + quotename(colName) from
       (
       select distinct(Year) as colName
       from ETLStaging..FinanceTopData
       where Year > 2011
       ) sub
       order by colName
       for xml path(''), type
       ).value('.', 'nvarchar(max)'),1,1,'')

set @tpv = '
with TPV as (
select *  from (
select /* td.Vertical , */
       Year, Month, Gateway,
       sum(Card_Volume_USD) Card_Volume_USD
from   ETLStaging..FinanceAnalytics
where 1 =1 
	and Vertical in ('+@allVerticals+')
	and Gateway in (''YapProcessing'')
group by /* td.Vertical , */
	Year, Month, Gateway
) sub
pivot
(
       sum(Card_Volume_USD)
       for [Month] in ('+@months+')
) as PivotTable
)
select Year, '+@months+'
from TPV
order by Year'

     
set @txnCount = '
with Txn_Count as (
select *  from (
select /* td.Vertical , */
       Year, Month, Gateway,
       sum(Card_Txn_Count) Card_Txn_Count
from   ETLStaging..FinanceAnalytics
where 1 =1 
	and Vertical in ('+@allVerticals+')
	and Gateway in (''YapProcessing'')
group by /* td.Vertical , */
	Year, Month, Gateway
) sub
pivot
(
       sum(Card_Txn_Count)
       for [Month] in ('+@months+')
) as PivotTable
)
select Year, '+@months+'
from Txn_Count
order by Year' 



set @averageTicket = '
with Average_Ticket as (
select *  from (
select /* td.Vertical , */
       Year, Month, sum(Card_Volume_USD)/sum(Card_Txn_Count) Average_Ticket
from   ETLStaging..FinanceAnalytics
where 1 = 1 
	and Vertical in ('+@allVerticals+')
	and Gateway in (''YapProcessing'')
group by /* td.Vertical , */
	Year, Month
) sub
pivot
(
       sum(Average_Ticket)
       for [Month] in ('+@months+')
) as PivotTable
--order by Year, Month
)
select Year , '+@months+'
from Average_Ticket' 



set @averageTicketYear = '
with Average_Ticket as (
select *  from (
select /* td.Vertical , */
       Year, Vertical, sum(Card_Volume_USD)/sum(Card_Txn_Count) Average_Ticket
from   ETLStaging..FinanceAnalytics
where 1 = 1 
	and Vertical in ('+@allVerticals+')
	and Gateway in (''YapProcessing'')
group by /* td.Vertical , */
	Year , Vertical
) sub
pivot
(
       sum(Average_Ticket)
       for [Year] in ('+@years+')
) as PivotTable
--order by Year, Month
)
select Vertical , '+@years+'
from Average_Ticket' 





--exec sp_executesql @tpv
--exec sp_executesql @txnCount
exec sp_executesql @averageTicket

