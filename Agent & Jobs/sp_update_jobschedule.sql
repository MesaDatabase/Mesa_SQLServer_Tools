set nocount on

declare @t1 table (myjob_id varchar(100), mysched_name varchar(255))
insert into @t1
select j1.job_id, j3.name
--select *
from msdb.dbo.sysjobs j1 (nolock)
  join msdb.dbo.sysjobschedules j2 (nolock) on j1.job_id = j2.job_id
  join msdb.dbo.sysschedules j3 (nolock) on j2.schedule_id = j3.schedule_id
where j1.name like 'Full backup%'
  and j1.name not like '%Dell_Maint%'

declare @myjob_id varchar(50), @mysched_name varchar(255)
declare 
  @myfreq_type int,
  @myfreq_interval int,
  @myfreq_subday_type int,
  @myfreq_subday_interval int,
  @myactive_start_time int
set @myfreq_type = 8
set @myfreq_interval = 41
set @myfreq_subday_type = 1
set @myfreq_subday_interval = 0
set @myactive_start_time = 210000
  
while exists (select top 1 * from @t1 t1)
begin
  set @myjob_id = (select top 1 myjob_id from @t1 t1)
  set @mysched_name = (select top 1 mysched_name from @t1 t1 where myjob_id = @myjob_id)
  --select @myjob_id, @mysched_name
  EXEC msdb.dbo.sp_update_jobschedule @job_id = @myjob_id, @name = @mysched_name, @freq_type = @myfreq_type, @freq_interval = @myfreq_interval, @freq_subday_type = @myfreq_subday_type, @freq_subday_interval = @myfreq_subday_interval, @active_start_time = @myactive_start_time
  delete from @t1 where myjob_id = @myjob_id
end 

--select * from msdb.dbo.sysjobschedules
--select * from msdb.dbo.sysschedules