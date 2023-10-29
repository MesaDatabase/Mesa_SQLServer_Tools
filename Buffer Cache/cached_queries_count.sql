select usecounts, cacheobjtype, objtype, text 
from sys.dm_exec_cached_plans 
cross apply sys.dm_exec_sql_text(plan_handle) 
where usecounts > 1 
order by usecounts desc