with TPV as (
-- select * from get_crosstab_statement('analytics',ARRAY['date'],'vertical','sum(tpv_usd)')  ;
select  
  r[1]::date AS date, "Dues", "HA", "Intl", "Inn", "NonProfit", "Rent", "SRP", "VRP" 
from    crosstab ('
  select 
    ARRAY[date::text] AS r, 
    vertical, 
    sum(tpv_usd)         
  from analytics
  where Gateway not in (''GatewayOnly'')      
  group by date, 
    vertical         
  order by date' , '
    select distinct vertical         
    from analytics         
    order by vertical'     
  ) AS newtable (r varchar[],"Dues" numeric,"HA" numeric, "Inn" numeric, "Intl" numeric, "NonProfit" numeric, "Rent" numeric, "SRP" numeric, "VRP" numeric)
)
, GatewayOnly as (
  select 
    Date, sum(TPV_USD) GatewayOnly
  from 
    analytics
  where 
    Gateway in ('GatewayOnly')
  group by 
    Date
)
, ExternalGateway as (
  select 
    Date, sum(TPV) ExternalGateway
  from
    external_gateway
  group by
    Date
)
select 
  TPV.*, GatewayOnly.GatewayOnly as "GtwyOnly", ExternalGateway.ExternalGateway as "ExtrnlGtwy"
from 
    TPV 
  full outer join GatewayOnly on TPV.Date = GatewayOnly.Date
  full outer join ExternalGateway on TPV.Date = ExternalGateway.Date
  ;
  