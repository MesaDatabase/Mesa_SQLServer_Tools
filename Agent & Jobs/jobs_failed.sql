set nocount on

--one row for each executed step
select 
@@servername as server, 
replace(jobs.name, ',','') as JobName,
hist.run_date, hist.run_time, replace(hist.message,',','')
--select top 10 *
 from msdb.dbo.sysjobs jobs
  join msdb.dbo.sysjobhistory hist (nolock) on jobs.job_id = hist.job_id
where 1=1
  and jobs.enabled = 1
--  and step_id = 1
  and run_status = 0
  --and jobs.name = '- All Databases Restore from Prod_2'
  and run_date = (select max(run_date) from msdb.dbo.sysjobhistory where job_id = jobs.job_id and run_status = 0)
  and run_time = (select max(run_time) from msdb.dbo.sysjobhistory jobs2 where jobs2.job_id = jobs.job_id and run_status = 0 and run_date = (select max(run_date) from msdb.dbo.sysjobhistory where job_id = jobs.job_id))
  and hist.step_id > 0
--  and jobs.job_id = '2009E9A3-3A53-4EEB-9903-5ED46B60F6D8'
--  and run_date = 20101226
order by 2
