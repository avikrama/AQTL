with TPV as (
-- select * from get_crosstab_statement('analytics',ARRAY['date'],'vertical','sum(card_volume_usd)')  ;
select  
  r[1]::date AS date, "Dues", "HA", "Intl", "Inn", "NonProfit", "Rent", "SRP", "VRP" 
from    crosstab ('
  select 
    ARRAY[date::text] AS r, 
    vertical, 
    sum(card_volume_usd)         
  from analytics
  where Gateway not in (''GatewayOnly'')      
  group by date, 
    vertical         
  order by date' , '
    select distinct vertical         
    from analytics         
    order by vertical'     
  ) AS newtable (r varchar[],"Dues" numeric,"Intl" numeric, "HA" numeric, "Inn" numeric, "NonProfit" numeric, "Rent" numeric, "SRP" numeric, "VRP" numeric)
)
select TPV.*
from 
  TPV 
  ;