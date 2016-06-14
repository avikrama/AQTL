with TPV as (
--select * from get_crosstab_statement('analytics',ARRAY['date'],'PaymentTypeGroup','sum(tpv_usd)')  ;
select  
  r[1]::date AS date, "ACH", "AmEx", "Cash", "Credit", "Debit" 
from    crosstab ( '
  select ARRAY[date::text] AS r, 
    PaymentTypeGroup, 
    sum(tpv_usd)         
  from analytics  
  where
    Gateway not in (''GatewayOnly'')
  group by date, 
    PaymentTypeGroup         
  order by date'     , '
      select distinct PaymentTypeGroup         
      from analytics         
      order by PaymentTypeGroup'
  ) AS newtable (r varchar[], "ACH" numeric, "AmEx" numeric, "Cash" numeric, "Credit" numeric, "Debit" numeric)
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
  