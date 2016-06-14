declare @now date, @start date, @end date, @Vertical as nvarchar(max) , @columns as nvarchar(max), @query as nvarchar(max)

set @now = getdate()
set @start = dateadd(yy,-1,dateadd(mm,(year(@now)- 1900) * 12 + month(@now) - 1 -1 , 0))
set @end   = dateadd(d,-1 , dateadd(mm,(year(@now)- 1900) * 12 + month(@now)- 1 , 0))  

if object_id('tempdb..#IssuerType') is not null drop table #IssuerType
select 
      cast(dateadd(d, -1 , dateadd(mm, (Year - 1900) * 12 + Month, 0)) as date) as Date ,
      c.Vertical , 
      Issuer.CardType ,
      sum(txn.Amount) as Txn_Amount --, count(*) as Txn_Count
      into #IssuerType
from                                            
   YapstoneDM.dbo.[Transaction] txn
   inner join ETLStaging.dbo.FinanceParentTable c on c.ChildCompanyId  = txn.Ref_CompanyId and c.PlatformId = txn.PlatformId
   inner join ETLStaging..FinanceIssuerType Issuer                on txn.IdClassId = Issuer.IdClassId and txn.PlatformId = Issuer.PlatformId
where
      txn.PostDate_R between @start and @end 
      and txn.PaymentTypeId in (1,2,3,11,12) 
      and txn.TransactionCycleId in (1)
      and txn.ProcessorId not in (14,16)
      and txn.PlatformId in (1,2,3)
      and c.Vertical in ('HA','VRP','Rent')
group by
      cast(dateadd(d, -1 , dateadd(mm, (Year - 1900) * 12 + Month, 0)) as date) ,
      c.Vertical , 
      Issuer.CardType 

select @Vertical = stuff((select ',' + quotename(colName) from (
      select  distinct(Vertical) as colName from #IssuerType 
) sub order by colName desc for xml path(''), type).value('.', 'nvarchar(max)'),1,1,'')

   
select @columns = stuff((
      select 
            distinct ',' + quotename(Vertical+'_'+c.col) 
      from #IssuerType
            cross apply ( 
                  select 'Domestic' col union all select 'Intl'  
            ) c
for xml path (''), type).value('.', 'nvarchar(max)'),1,1,'')
  
set @query = ' 
select * from (
select Date, Vertical+''_''+CardType [Column], Txn_Amount TPV from #IssuerType
) src
pivot (
      sum(TPV)
      for [Column] in ('+@columns+')
) pt
'

exec(@query)


