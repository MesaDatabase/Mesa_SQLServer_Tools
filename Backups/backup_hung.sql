set nocount on

/*
select * from db.bo.backup_log
where end_time is null
*/


select
  @@servername as server, 
  replace(jobs.name, ',',''),
  act.run_requested_date,
  getdate(),
  datediff(hh, act.run_requested_date, getdate())
-- select *
from msdb.dbo.sysjobs jobs
  join msdb.dbo.sysjobactivity act on jobs.job_id = act.job_id
where 1=1
  and jobs.enabled = 1
  and (name like 'Full backup job for database%' or name like 'Log backup job for database%')
  and isnull(run_requested_date,'') != ''
  and isnull(stop_execution_date,'') = ''
  and isnull(run_requested_date,'') = (select max(isnull(run_requested_date,0)) from msdb.dbo.sysjobactivity act2 where act2.job_id = jobs.job_id)
  and datediff(hh, act.run_requested_date, getdate()) >= 5
--  and datediff(mi, act.run_requested_date, getdate()) >= 1




