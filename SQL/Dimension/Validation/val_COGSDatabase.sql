
drop table t_amex;
select month, count(*) amex_records
	into t_amex
from amex
group by month
order by month desc;

drop table t_vantiv;
select month, count(*) vantiv_records
	into t_vantiv
from	vantiv
group by month
;

drop table t_gp;
select month, count(*) gp_records
	into t_gp
from	globalpayments
group by month
;

select coalesce(a.month,v.month,gp.month) "month", a.amex_records,v.vantiv_records,gp.gp_records
from 
	t_amex a
	full outer join t_vantiv v on a.month = v.month
	full outer join t_gp gp on v.month = gp.month
order by month desc