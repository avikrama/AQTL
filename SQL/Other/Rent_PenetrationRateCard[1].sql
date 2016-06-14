declare @start as date, @end as date, @dates as nvarchar(max), @query as nvarchar(max), @lastMonth as date;

set @start           = '2015-01-01'
set @end             =  cast(dateadd(ss, -1, dateadd(month, datediff(month, 0, getdate()), 0)) as date)

if object_id('tempdb..#Capacity_Children') is not null drop table #Capacity_Children
select year(txn.postdate_r) Year, month(txn.postdate_r) Month , cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) as date) as Date ,
       c.PlatformId ,  c.ParentAccountId, c.ParentName , yc.Capacity
       into #Capacity_Children
from
       YapstoneDM..[Transaction] txn
       inner join ETLStaging..FinanceParentTable c on c.PlatformId = txn.PlatformId and c.ChildCompanyId = txn.Ref_CompanyId 
       inner join YapstoneDM..Company yc on c.PlatformId = yc.PlatformId and c.ChildAccountId = yc.AccountId
where
       txn.postdate_r between @start and @end
       and c.PlatformId in (1)
       and txn.TransactionCycleId in (1)
       and c.Vertical in ('Rent','Dues')
       and yc.isActive = 1
group by year(txn.postdate_r) , month(txn.postdate_r)  , cast(dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) as date) ,
       c.PlatformId ,  c.ParentAccountId, c.ParentName, yc.Capacity
       
if object_id('tempdb..#Capacity') is not null drop table #Capacity
select Year, Month, Date, PlatformId, ParentAccountId, ParentName, sum(Capacity) Capacity
       into #Capacity
from
       #Capacity_Children
group by Year, Month, Date, PlatformId, ParentAccountId, ParentName

if object_id('tempdb..#Capacity_LastMonth') is not null drop table #Capacity_LastMonth
select * into #Capacity_LastMonth from (
  select * from #Capacity where Date in (@end)
) src

if object_id('tempdb..#Report') is not null drop table #Report
select   year(txn.postdate_r) Year, month(txn.postdate_r) Month, 
  dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) as Date ,
  txn.PlatformId ,
    c.Vertical,  c.ParentAccountId, c.ParentName ,   isnull(Capacity.Capacity,0) Capacity , isnull(clm.Capacity,0) CapacityLastMonth ,
    count(distinct(txn.Ref_PersonId)) as PeopleTransacting ,                      
   case when pt.Name in ('Visa','Master Card','Discover','Visa Debit','MC Debit') then 'Card' when pt.Name in ('eCheck','Scan')        then 'ACH' else 'Other' end PaymentType ,
    sum(txn.amount) Txn_Amount, count(*) as Txn_Count
    into #Report
from                       
    YapstoneDM.dbo.[Transaction] txn with (nolock)                         
    inner join ETLStaging..FinanceParentTable c with (nolock) on c.PlatformId = txn.PlatformId and c.ChildCompanyId = txn.Ref_CompanyId                        
    inner join #Capacity Capacity on c.PlatformId = Capacity.PlatformId and c.ParentAccountId = Capacity.ParentAccountId and Capacity.Year = year(txn.PostDate_r) and Capacity.Month = month(txn.PostDate_r)
    left join #Capacity_LastMonth clm on c.PlatformId = clm.PlatformId and c.ParentAccountId = clm.ParentAccountId 
    inner join YapstoneDM..PaymentType pt on txn.PaymentTypeId = pt.PaymentTypeId
where    1 = 1                  
    and txn.PostDate_R between @start and @end             
    and txn.ProcessorId not in (14,16)                     
    and txn.TransactionCycleId in (1)               
    and txn.PlatformId in (1)                
    and c.Vertical in ('Rent','Dues') 
    and (case when txn.paymenttypeid in (1, 2, 3, 11, 12, /* <-- regular cards */ /* pre 2012 debit networks --> */  6,7,8,9) then 1 
      when txn.PaymentTypeId in (10) and txn.ProcessorId in (22) and txn.Ref_BatchTypeId in (1) /* Amex , Bucket , Vantiv = Processing */ then 1
      else 0 end) = 1
group by      
    year(txn.postdate_r) , month(txn.postdate_r) , 
    dateadd(d, -1 , dateadd(mm, (year(txn.PostDate_R) - 1900) * 12 + month(txn.PostDate_R), 0)) ,
    txn.PlatformId , c.Vertical,                       
    c.ParentAccountId,     c.ParentName , isnull(Capacity.Capacity,0), isnull(clm.Capacity,0) ,
       case when pt.Name in ('Visa','Master Card','Discover','Visa Debit','MC Debit') then 'Card' when pt.Name in ('eCheck','Scan')        then 'ACH' else 'Other' end
      
if object_id('tempdb..#Parents') is not null drop table #Parents
select 
  cast(Date as date) Date ,
  Vertical, ParentName, CapacityLastMonth  ,
  isnull(Capacity,0) Capacity ,
  sum(PeopleTransacting) TotalPeople
  into #Parents
from #Report
where  1 =1
       and Vertical in ('Rent','Dues')
group by  Date, Vertical , ParentName, isnull(Capacity,0), CapacityLastMonth

select @dates = stuff((select ',' + quotename(colName) from (
       select distinct(Date) as colName 
       from #Parents
       ) sub order by colName for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')

set @query = '
select * from (
select Date,Vertical,ParentName,CapacityLastMonth,[%] from (
select *
        ,convert(decimal(10,2),case when Capacity <> 0 and TotalPeople <> 0 then cast(TotalPeople as decimal(10,2))/ cast(Capacity as decimal(10,2)) * 100 else 0 end) as [%] 
from #Parents
where Vertical in (''Rent'')
) src
group by Date, Vertical,ParentName,CapacityLastMonth,[%]
) src
pivot ( 
  sum([%])
  for [Date] in ('+@dates+')
) pt
order by CapacityLastMonth desc
'

exec sp_executesql @query

