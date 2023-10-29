set nocount on

--all jobs
select 
@@servername as server, 
replace(j1.name,',','') as job_name, 
j1.job_id,
j1.enabled,  
case when s2.freq_type = 4 and s2.freq_interval = 1 then 'Everyday'
     when s2.freq_type = 8 and s2.freq_interval = 41 then 'Su/W/F'
     when s2.freq_type = 8 and s2.freq_interval = 64 then 'Sa'
     when s2.freq_type = 8 and s2.freq_interval = 82 then 'M/Th/Sa'
     when s2.freq_type = 8 and s2.freq_interval = 84 then 'Th/Sa'
     when s2.freq_type = 8 and s2.freq_interval = 126 then 'All but Su'
     when s2.freq_type = 8 and s2.freq_interval = 127 then 'Everyday'
else '' end as Days,
case when s2.freq_subday_type = 1 then 'Everyday at ' + cast(s2.active_start_time as varchar(10))
	 when s2.freq_subday_type = 2 then 'Every ' + cast(s2.freq_subday_interval as varchar(5)) + ' seconds'
	 when s2.freq_subday_type = 4 then 'Every ' + cast(s2.freq_subday_interval as varchar(5)) + ' minutes'
	 when s2.freq_subday_type = 8 then 'Every ' + cast(s2.freq_subday_interval as varchar(5)) + ' hours'
else '' end as Frequency,
s2.freq_type,
s2.freq_interval,
s2.freq_subday_type,
s2.freq_subday_interval,
active_start_time,
next_run_date,
next_run_time,
case when notify_level_email = 1 then 'Succeeds'
	 when notify_level_email = 2 then 'Fails'
	 when notify_level_email = 3 then 'Completes'
else NULL end as EmailNotification,
o1.email_address
--select top 10 *
from msdb.dbo.sysjobs j1 (nolock)
  left join msdb.dbo.syscategories c1 (nolock) on j1.category_id = c1.category_id
  left join msdb.dbo.sysjobschedules s1 (nolock) on j1.job_id = s1.job_id
  left join msdb.dbo.sysschedules s2 (nolock) on s1.schedule_id = s2.schedule_id
  left join msdb.dbo.sysoperators o1 (nolock) on j1.notify_email_operator_id = o1.id
where 1=1
order by job_name


