select * from msdb.dbo.sysjobs as j1a
  join msdb.dbo.sysjobschedules as j2a on j1a.job_id = j2a.job_id
where j2a.schedule_id in (
select j3.schedule_id from msdb.dbo.sysjobs as j1
  join msdb.dbo.sysjobschedules as j2 on j1.job_id = j2.job_id
  join msdb.dbo.sysschedules as j3 on j2.schedule_id = j3.schedule_id
where j1.name like '%Backup%Netbackup%')