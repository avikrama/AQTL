
if object_id('tempdb..#Software') is not null drop table #Software   
select  
	c.PlatformId ,
	(case  when c.platformid in (1) then case when c.typeid in (1,5,6,7,8,9,11,12,13,15,16,17,19,20,21,22,23,24,25,27,28,29,31,33,32,35,36,37,38,39,40,41) then 'Rent'                     
			when c.typeid in (14) then 'VRP'    when c.typeid in (30) then 'SRP'   when c.typeid in (18,42) then 'Inn'    when c.typeid in (3,4,26) then 'Dues'     when c.typeid in (10,34) then 'DNU'                 
	when c.typeid in (43) then 'NonProfit' else 'null' end    when c.PlatformId in (2) then 'VRP'    when c.PlatformId in (3) then 'HA'    when c.PlatformId in (4) then 'HA-Intl'end ) Vertical ,
	c.CompanyId  , case when c.Name in ('V12 Net Software', 'First Resort Software', 'Entech Software', 'Property Plus Software') then c.Name + '/InstantSoftware' when c.platformid in (4) then 'HomeAway' else c.Name end SoftwareName, c.AggregateId, c.AccountId
	into #Software
from  YapstoneDM.dbo.Company c  with (nolock)
where
	( case when c.PlatformId in (1) and c.AccountId in (
  '76-10063876', '85-98085185', '95-59779385', '34-97929656', '65-82484431', '15-31108138', '46-11791340', '86-11993328',       
  '26-13092009', '66-10606236', '96-11999891', '56-11999978', '55-75363959', '96-13679409', '75-80100275', '96-12970121',
  '75-84092624', '25-75364009', '35-78885816', '55-87534185', '45-80081810', '36-11581843', '25-76905166', '95-85445412', 
  '95-87145000', '95-87146377', '96-13138735', '95-86513730', '65-42527974', '36-11791161', '46-11791340', '86-11791218',
  '35-91825585', '56-11770937', '96-13703524', '46-13563598', '75-58164403', '85-87008214', '56-13899184', '86-13540564'
  --'84-97935418', '65-11294487','05-11485603' -- removed to change hirearchy 

	) then 1 when c.PlatformId in (2) and c.AccountId in (
		  '75-30209137','25-30191477','95-30211453','55-30212711'
	) then 1 when c.PlatformId in (3) and c.AccountId in (
		  'accountid'
	) then 1 when c.PlatformId in (4) and c.AccountId in (
		  '91-15748596' /* 45-91530167 = Bookt, 95-91531978 = LiveRez, 25-91822138 = Adventure Office, 25-94458684 = SuperControl, 76-10121677 = IVT  */
	)  then 1 else 0 end  ) = 1
group by
	c.PlatformId , 
	(case  when c.platformid in (1) then case when c.typeid in (1,5,6,7,8,9,11,12,13,15,16,17,19,20,21,22,23,24,25,27,28,29,31,33,32,35,36,37,38,39,40,41) then 'Rent'                     
			when c.typeid in (14) then 'VRP'    when c.typeid in (30) then 'SRP'   when c.typeid in (18,42) then 'Inn'    when c.typeid in (3,4,26) then 'Dues'     when c.typeid in (10,34) then 'DNU'                 
	when c.typeid in (43) then 'NonProfit' else 'null' end    when c.PlatformId in (2) then 'VRP'    when c.PlatformId in (3) then 'HA'    when c.PlatformId in (4) then 'HA-Intl'end ) ,
	c.CompanyId , c.Name , c.AggregateId, c.AccountId

	
if object_id('tempdb..#ParentTable') is not null drop table #ParentTable
-- Low Level #ParentTable
create table #ParentTable (platformid varchar(2), AccountId varchar(64), ParentName varchar(150), AggregateId varchar(150) , SoftwareName varchar(150), Vertical varchar(10) , DateFirstSeen date, DateLastSeen date  )           
insert into #ParentTable            
select  inner_query.PlatformId, inner_query.AccountId,  c.Name,  c.AggregateId,  Software.SoftwareName ,
      (case  when c.platformid in (1) then case when c.typeid in (1,5,6,7,8,9,11,12,13,15,16,17,19,20,21,22,23,24,25,27,28,29,31,33,32,35,36,37,38,39,40,41) then 'Rent'                     
                      when c.typeid in (14) then 'VRP'    when c.typeid in (30) then 'SRP'   when c.typeid in (18,42) then 'Inn'    when c.typeid in (3,4,26) then 'Dues'     when c.typeid in (10,34) then 'DNU'                 
             when c.typeid in (43) then 'NonProfit' else 'null' end    when c.PlatformId in (2) then 'VRP'    when c.PlatformId in (3) then 'HA'    when c.PlatformId in (4) then 'HA-Intl'end ) Vertical,     
      dateadd(mm, datediff(mm, -1, min(inner_query.date_first_seen) ) , 0) -1 as date_first_seen, 
      case when (dateadd(mm, datediff(mm, -1, max(inner_query.date_last_seen) ) , 0 ) -1 ) > @enddate then @enddate else dateadd(mm, datediff(mm, -1, max(inner_query.date_last_seen) ) , 0 ) -1 end as date_last_seen       
from (            
select            
       c.PlatformId,            
        (case   when c.PlatformId in (1) then     ( case                    
              when bc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then c.AccountID    -- Added in two new companyids                
              when cc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then bc.AccountID                   
              when dc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then cc.AccountID                   
              when ec.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then dc.AccountID                   
              when fc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then ec.AccountID                   
              when gc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then fc.AccountID                   
              else c.AccountID end )     when c.PlatformId in (2) then            ( case                   
              when bc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then c.AccountID           when cc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then bc.AccountID                  
              when dc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then cc.AccountID              when ec.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then dc.AccountID                  
              when fc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then ec.AccountID              when gc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then fc.AccountID    else c.AccountID end )                 
       when c.PlatformId in (3) then     ( case   when bc.CompanyId in (1 ) then c.AccountID               when cc.CompanyId in (1 ) then bc.AccountID                           
              when dc.CompanyId in (1 ) then cc.AccountID  when ec.CompanyId in (1 ) then dc.AccountID      when fc.CompanyId in (1 ) then ec.AccountID  when gc.CompanyId in (1 ) then fc.AccountID               
              else c.AccountID end )        when c.PlatformId in (4) then                
       ( case     when bc.CompanyId in (1 ) then c.AccountID      when cc.CompanyId in (1 ) then bc.AccountID     when dc.CompanyId in (1 ) then cc.AccountID     when ec.CompanyId in (1) then dc.AccountID                 
              when fc.CompanyId in (1 ) then ec.AccountID  when gc.CompanyId in (1 ) then fc.AccountID          
       else c.AccountID end ) end ) as AccountId , min( txn.PostDate_R) as date_first_seen , max( txn.PostDate_R) as date_last_seen            
from            
       YapstoneDM.dbo.Company c  with (nolock)            
       inner join YapstoneDM.dbo.[Transaction] txn with (nolock)  on c.PlatformId = txn.PlatformId and txn.Ref_CompanyId = c.CompanyId            
       left join YapstoneDM.dbo.Company bc  with (nolock) on c.parentCompanyId = bc.CompanyId and c.PlatformId = bc.PlatformId             left join YapstoneDM.dbo.Company cc  with (nolock) on bc.parentCompanyId = cc.CompanyId and bc.PlatformId = cc.PlatformId            
       left join YapstoneDM.dbo.Company dc  with (nolock) on cc.parentCompanyId = dc.CompanyId and cc.PlatformId = dc.PlatformId   left join YapstoneDM.dbo.Company ec  with (nolock) on dc.parentCompanyId = ec.CompanyId and dc.PlatformId = ec.PlatformId            
       left join YapstoneDM.dbo.Company fc  with (nolock) on ec.parentCompanyId = fc.CompanyId and ec.PlatformId = fc.PlatformId     left join YapstoneDM.dbo.Company gc  with (nolock) on fc.parentCompanyId = gc.CompanyId and fc.PlatformId = gc.PlatformId            
where txn.TransactionCycleId in (1)
  and (
         (c.PlatformId in (1) and c.CompanyId not in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) ) or
         (c.PlatformId in (2) and c.CompanyId not in ( 1, 30190, 30209, 30191, 30973, 30211, 30212  ) ) or
         (c.PlatformId in (3) and c.CompanyId not in ( 1 ) ) or
         (c.PlatformId in (4) and c.CompanyId not in ( 1 ) )
    )           
group by            
       c.PlatformId,            
       (case   when c.PlatformId in (1) then      ( case                 
              when bc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then c.AccountID                    
              when cc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then bc.AccountID                   
              when dc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then cc.AccountID                   
              when ec.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then dc.AccountID                   
              when fc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then ec.AccountID                   
              when gc.CompanyId in ( 1, 58164, 136794, 135405, 135406, 135407, 117709, 130920, 137035, 100638, 115818, 83219, 86513, 100638, 91825, 87145, 87146, 131387, 87144, 98085, 11294, 9793, 23782, 9792, 11485, 48562, 23782, 35802, 117910, 117911, 117912, 117913, 82484, 84092 , 75364, 77380 , 78885, 87534, 80100, 80081, 769051, 86901, 106062, 85445, 75363, 97811, 87008, 88672, 76905, 54415, 42535, 52354, 42535, 54425, 42077, 42527, 54456 , 59779 ,88792 ,86902 ) then fc.AccountID                   
              else c.AccountID end )     when c.PlatformId in (2) then            ( case               
              when bc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then c.AccountID       when cc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then bc.AccountID                  
              when dc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then cc.AccountID        when ec.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then dc.AccountID                  
              when fc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then ec.AccountID        when gc.CompanyId in (1, 30190, 30209, 30191, 30973, 30211, 30212 ) then fc.AccountID                  
              else c.AccountID end )        when c.PlatformId in (3) then    ( case                     
              when bc.CompanyId in (1 ) then c.AccountID               when cc.CompanyId in (1 ) then bc.AccountID                    
              when dc.CompanyId in (1 ) then cc.AccountID when ec.CompanyId in (1 ) then dc.AccountID                    
              when fc.CompanyId in (1 ) then ec.AccountID when gc.CompanyId in (1 ) then fc.AccountID                    
              else c.AccountID end )      when c.PlatformId in (4) then     ( case                     
              when bc.CompanyId in (1 ) then c.AccountID      when cc.CompanyId in (1 ) then bc.AccountID          
              when dc.CompanyId in (1 ) then cc.AccountID  when ec.CompanyId in (1 ) then dc.AccountID          
              when fc.CompanyId in (1 ) then ec.AccountID     when gc.CompanyId in (1 ) then fc.AccountID   else c.AccountID end ) end )  ) inner_query              
       inner join YapstoneDM.dbo.Company c with (nolock) on c.AccountId = inner_query.AccountId and c.PlatformId = inner_query.PlatformId        
       left join #Software Software on c.platformId = Software.Platformid and
       ( c.AggregateId = Software.AggregateId or c.AggregateId like Software.aggregateId + '|%' )      
group by  inner_query.PlatformId, inner_query.AccountId,  c.Name,   c.AggregateId,   Software.SoftwareName ,         
  (case  when c.platformid in (1) then case when c.typeid in (1,5,6,7,8,9,11,12,13,15,16,17,19,20,21,22,23,24,25,27,28,29,31,33,32,35,36,37,38,39,40,41) then 'Rent'                     
        when c.typeid in (14) then 'VRP'    when c.typeid in (30) then 'SRP'   when c.typeid in (18,42) then 'Inn'    when c.typeid in (3,4,26) then 'Dues'     when c.typeid in (10,34) then 'DNU'                 
   when c.typeid in (43) then 'NonProfit' else 'null' end    when c.PlatformId in (2) then 'VRP'    when c.PlatformId in (3) then 'HA'    when c.PlatformId in (4) then 'HA-Intl'end )                     
create index ix_ParentTable_01 on #ParentTable (aggregateId, platformId) include (accountId, ParentName, SoftwareName , Vertical , DateFirstSeen, DateLastSeen)   


if object_id('tempdb..#Company') is not null drop table #Company  
select
       c.PlatformId, c.CompanyId , c.AccountId ChildAcountId, c.Name ChildName , ParentTable.AccountId ParentAccountId , ParentTable.ParentName , ParentTable.SoftwareName , ParentTable.Vertical, ParentTable.DateFirstSeen , ParentTable.DateLastSeen
       into #Company
from 
       YapstoneDM.dbo.Company c
       inner join #ParentTable ParentTable on  ( c.AggregateId = ParentTable.AggregateId  or 
       ( c.AggregateId ) like ParentTable.aggregateId + '|%' ) and c.PlatformId = ParentTable.Platformid
group by
       c.PlatformId, c.CompanyId , c.AccountId , c.Name , ParentTable.AccountId, ParentTable.ParentName , ParentTable.SoftwareName  , ParentTable.Vertical, ParentTable.DateFirstSeen , ParentTable.DateLastSeen
