set nocount on

select 
@@servername as server, 
t2.name, t1.step_name, t1.command, t2.enabled
--select *
from msdb.dbo.sysjobsteps t1
  join msdb.dbo.sysjobs t2 on t1.job_id = t2.job_id
--where step_name like '%error%'