set nocount on

--all jobs
select  
j1.job_id,
replace(j1.name,',','') as job_name, 
j1.enabled
--select top 10 *
from msdb.dbo.sysjobs j1 (nolock)
where name like 'Log backup%'
order by enabled, job_name

