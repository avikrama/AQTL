USE [ETLStaging]
GO

/****** Object:  StoredProcedure [dbo].[usp_CREATE_FinanceIssuerType]    Script Date: 02/11/2016 16:19:31 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

/**********************************************
Notes:       This will be run every day (inserts last 4 days of data each time - sometimes YapDM doesn't run for couple of days)
				
--**********************************************/

CREATE PROCEDURE  [dbo].[usp_CREATE_FinanceIssuerType]
AS

BEGIN


declare @start date, @end date
set @start       = convert(date,DateAdd(DD,-5,GETDATE() ))
set @end         = convert(date,DateAdd(DD,-2,GETDATE() ))


/*
declare @start as date, @end as date
 
set @start	= '2010-01-01'
set @end	= '2016-01-26'  
*/

select
	1 as platformid,txn.IdClassId,
	case when (cb.country in (840,0) or cb.country is null) then 'Domestic' else 'Intl' end as CardType,
	txn.PostDate_R,  year(txn.PostDate_r) Year, month(txn.PostDate_r) Month
into #IssuerType	
from   
	YapstoneDM..[Transaction] txn (nolock)
	join rpReportsTemp.rp.[Transfer] t (nolock) on cast( t.Id as varchar(10) ) + ':' + cast( t.ClassId as varchar(5)) = txn.IdClassId and txn.PlatformId = 1
	left join rpReportsTemp.rp.CardBin cb (nolock) on left(t.uiAccountNumber,6)= cb.bin and cb.source= 'Bin_DB' and txn.PlatformId = 1
where 
	txn.TransactionCycleId in (1,3,4,9,16)
	and txn.PaymentTypeId in (1,2,3,6,7,8,9,10,11,12)
	and txn.PostDate_R between @start and @end
	and txn.PlatformId = 1
group by      
	txn.IdClassId,
	case when (cb.country in (840,0) or cb.country is null) then 'Domestic' else 'Intl' end, 
	txn.PostDate_R
	
union all

select
	2 as platformid,txn.IdClassId,
	case when (cb.country in (840,0) or cb.country is null) then 'Domestic' else 'Intl' end as CardType,
	txn.PostDate_R,  year(txn.PostDate_r) Year, month(txn.PostDate_r) Month
from   
	YapstoneDM..[Transaction] txn (nolock)
	join ipReportsTemp..[Transfer] t (nolock) on cast( t.Id as varchar(10) ) + ':' + cast( t.ClassId as varchar(5)) = txn.IdClassId and txn.PlatformId = 2
	left join ipReportsTemp..CardBin cb (nolock) on left(t.uiAccountNumber,6)= cb.bin and cb.source= 'Bin_DB' and txn.PlatformId = 2
where 
	txn.TransactionCycleId in (1,3,4,9,16)
	and txn.PaymentTypeId in (1,2,3,6,7,8,9,10,11,12)
	and txn.PostDate_R between @start and @end
	and txn.PlatformId = 2
group by      
	txn.IdClassId,
	case when (cb.country in (840,0) or cb.country is null) then 'Domestic' else 'Intl' end,
	txn.PostDate_R
	
union all

select
	3 as platformid,txn.IdClassId,
	case when (cb.country in (840,0) or cb.country is null) then 'Domestic' else 'Intl' end as CardType,
	txn.PostDate_R,  year(txn.PostDate_r) Year, month(txn.PostDate_r) Month
from   
	YapstoneDM..[Transaction] txn (nolock)
	join haReportsTemp..[Transfer] t (nolock) on cast( t.Id as varchar(10) ) + ':' + cast( t.ClassId as varchar(5)) = txn.IdClassId and txn.PlatformId = 3
	left join haReportsTemp..CardBin cb (nolock) on left(t.uiAccountNumber,6)= cb.bin and cb.source= 'Bin_DB' and txn.PlatformId = 3
where 
	txn.TransactionCycleId in (1,3,4,9,16)
	and txn.PaymentTypeId in (1,2,3,6,7,8,9,10,11,12)
	and txn.PostDate_R between @start and @end
	and txn.PlatformId = 3
group by      
	txn.IdClassId,
	case when (cb.country in (840,0) or cb.country is null) then 'Domestic' else 'Intl' end,
	txn.PostDate_R
	
	

--Just 4 days of data
delete from ETLStaging.dbo.FinanceIssuerType
where postdate_r>=@start

insert ETLStaging.dbo.FinanceIssuerType
     ([PlatformId]
     ,[IdClassId]
     ,[CardType]
     ,[Year]
     ,[Month]
     ,[PostDate_R])
select [PlatformId]
     ,[IdClassId]
     ,[CardType]
     ,[Year]
     ,[Month]
     ,[PostDate_R]
from #IssuerType
order by [PostDate_R] DESC

END


/*
--Manually Insert Missing Data

insert [ETLStaging].[dbo].[FinanceIssuer]
(platformId, IdClassId, CardType)
select 1,'235900:43','Domestic'
union
select 1,'120405:43','Domestic'
union
select 1,'114589:43','Domestic'
union
select 1,'118008:43','Domestic'
union
select 1,'8937139:40.old','Domestic'
union
select 1,'4','Domestic'
union
select 1,'206392:43','Domestic'

*/
GO


