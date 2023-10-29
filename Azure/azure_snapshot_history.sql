
--view last snapshot start
select   top 1 *
from     sys.pdw_loader_backup_runs
order by run_id desc

