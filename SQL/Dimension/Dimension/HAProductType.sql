USE [ETLStaging]
GO
/****** Object:  StoredProcedure [dbo].[usp_CREATE_FinanceAnalytics]    Script Date: 12/09/2015 11:12:16 ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE  [dbo].[usp_CREATE_FinanceHAProductType]
AS

BEGIN
declare @start date, @end date
set @start       = dateadd(mm,(year(getdate())- 1900) * 12 + month(getdate()) - 1 -1 , 0) 
set @end         = dateadd(d,-1 , dateadd(mm,(year(getdate())- 1900) * 12 + month(getdate())- 1 , 0))  

--==========================HA=============================
--Get PPB MasterReferencIDs 
if object_id('tempdb..#HA_PPBMasterInvoice') is not null drop table #HA_PPBMasterInvoice
select  
	mri.masterReferenceId, mri.masterReferenceClassId
	into #HA_PPBMasterInvoice
from 
	haReportsTemp..Invoice i (nolock)
	join HAReportsTemp..MasterReferenceInvoice mri (nolock) on mri.invoiceId = i.id and mri.invoiceClassId = i.classId
	join haReportsTemp..LineItem li (nolock) on i.id=li.invoiceId and i.classId=li.invoiceClassId
	join HAReportsTemp..LineItemCategory  lc  (nolock) on lc.id = li.categoryId and lc.classId = li.categoryClassId 
where 
	lc.name = 'PayPerBooking'
	and i.status not in (0, 3, 4, 6)

--HA PPB IDs
if object_id('tempdb..#HA_PPB') is not null drop table #HA_PPB
select '3' as PlatformId, cast(t.id as varchar) + ':' + cast(t.classId as varchar) as IdClassId, 'PPB' as ProductType
	into #HA_PPB       
from 
	#HA_PPBMasterInvoice PPB
	join HAReportsTemp..MasterReferenceInvoice mri (nolock) on PPB.masterReferenceId=mri.masterReferenceId and PPB.masterReferenceClassId = mri.masterReferenceClassId
	join haReportsTemp..Invoice i (nolock) on i.id = mri.invoiceId and i.classId = mri.invoiceClassId
	join haReportsTemp..[transfer] t (nolock) on t.invoiceId = i.id and t.invoiceClassId = i.classId
where 
	t.posted between @start and   dateadd(s,-1,dateadd(d,1,cast(@end as datetime)))
	and i.status not in (0, 3, 4, 6)

--HA Ancillary
if object_id('tempdb..#HA_Ancillary') is not null drop table #HA_Ancillary
select '3' as PlatformId, cast(t.id as varchar) + ':' + cast(t.classId as varchar) as IdClassId, 'Ancillary' as ProductType 
	into #HA_Ancillary
from 
	HAReportsTemp..[Transfer] t (nolock)                                                                                                                                                                                
	join HAReportsTemp..Invoice i on t.invoiceID = i.Id and t.invoiceClassID = i.classId                        
	join HAReportsTemp..Community ct on ct.id = t.BusinessEntity_companyId and ct.classId = t.BusinessEntity_companyClassId        
where
	t.posted between @start and   dateadd(s,-1,dateadd(d,1,cast(@end as datetime)))
	and ct.aggregateId like '1|2|1008|%'
	and i.status not in (0, 3, 4, 6)
		
--Delete Aincillarys from PPB
delete from #HA_PPB where IdClassId in (select IdClassId from #HA_Ancillary)
--==========================GD1=============================
if object_id('tempdb..#GD1_PPBMasterInvoice') is not null drop table #GD1_PPBMasterInvoice

--Get PPB MasterReferencIDs 
select  mri.masterReferenceId, mri.masterReferenceClassId
	into #GD1_PPBMasterInvoice
from GD1ReportsTemp..Invoice i (nolock)
	join GD1ReportsTemp..MasterReferenceInvoice mri (nolock) on mri.invoiceId = i.id and mri.invoiceClassId = i.classId
	join GD1ReportsTemp..LineItem li (nolock) on i.id=li.invoiceId and i.classId=li.invoiceClassId
	join GD1ReportsTemp..LineItemCategory  lc  (nolock) on lc.id = li.categoryId and lc.classId = li.categoryClassId 
where 
	lc.name = 'PayPerBooking'
	and i.status not in (4, 6)

--GD1 PPB IDs
if object_id('tempdb..#GD1_PPB') is not null drop table #GD1_PPB
select distinct
	'4' as PlatformId, cast(t.id as varchar) + ':' + cast(t.classId as varchar) as IdClassId, 'PPB' as ProductType
	into #GD1_PPB       
from 
	#GD1_PPBMasterInvoice PPB
	join GD1ReportsTemp..MasterReferenceInvoice mri (nolock) on PPB.masterReferenceId=mri.masterReferenceId and PPB.masterReferenceClassId = mri.masterReferenceClassId
	join GD1ReportsTemp..Invoice I (nolock) on i.id = mri.invoiceId and i.classId = mri.invoiceClassId
	join GD1ReportsTemp..PropertyFee pf (nolock) on pf.invoiceId=i.id and pf.invoiceClassId=i.classId and pf.propertyFeeCategoryId <> 6 --Excluding Value Added Tax Transactions
	join GD1ReportsTemp..Community cm (nolock) on i.BusinessEntity_companyId = cm.id
	join GD1ReportsTemp..[transfer] t (nolock) on t.invoiceId = i.id and t.invoiceClassId=i.classId
where 
	t.posted between @start and   dateadd(s,-1,dateadd(d,1,cast(@end as datetime)))
	and i.status not in (0, 3, 4, 6)
	and i.BusinessEntity_companyId not in (87868, 87739) -- Test Properties

--Final Table
if object_id('tempdb..#FinanceHAProductType') is not null drop table #FinanceHAProductType
select txn.PlatformId, txn.IdClassId,  isnull(a.ProductType,'PPS') as ProductType,txn.PostDate_R,  year(txn.PostDate_r) Year, month(txn.PostDate_r) Month
	into #FinanceHAProductType
from 
	YapstoneDM..[Transaction] txn
	left join (	select * from #HA_PPB
		union all 
			select * from #HA_Ancillary
		union all
			select * from #GD1_PPB
		) a on txn.PlatformId = a.PlatformId and txn.IdClassId = a.IdClassId
where 
	txn.PlatformId in (3,4)
	and txn.TransactionCycleId in (1,3,4,9,16)
	and txn.PostDate_R between @start and dateadd(s,-1,dateadd(d,1,cast(@end as datetime)))

--Jusr Last month's data
delete from ETLStaging.dbo.FinanceHAProductType where YEAR = YEAR(@start) and MONTH = MONTH(@start)

insert ETLStaging.dbo.FinanceHAProductType
		 ([Year]
		 ,[Month]
		 ,[Date]
		 ,[PlatformId]
		 ,[IdClassId]
		 ,[Product_Type])
select [Year]
		 ,[Month]
		 ,[Date]
		 ,[PlatformId]
		 ,[IdClassId]
		 ,[Product_Type]
from #FinanceHAProductType

END

GO



