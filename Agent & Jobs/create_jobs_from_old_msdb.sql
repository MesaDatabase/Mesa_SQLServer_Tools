--create jobs
declare @job_name sysname
declare @enabled tinyint
declare @description nvarchar(512)
declare @start_step_id int
declare @category_id int
declare @owner_login_name varchar(500)
declare @notify_level_eventlog int
declare @notify_level_email int
declare @notify_level_netsend int
declare @notify_level_page int
declare @notify_email_operator_name varchar(500)
declare @notify_netsend_operator_name varchar(500)
declare @notify_page_operator_name varchar(500)
declare @delete_level int
declare @job_id uniqueidentifier
     
declare @temp table (
	[job_id] [uniqueidentifier] NOT NULL,
	[originating_server] [nvarchar](30) NOT NULL,
	[name] [sysname] NOT NULL,
	[enabled] [tinyint] NOT NULL,
	[description] [nvarchar](512) NULL,
	[start_step_id] [int] NOT NULL,
	[category_id] [int] NOT NULL,
	[owner_sid] [varbinary](85) NOT NULL,
	[notify_level_eventlog] [int] NOT NULL,
	[notify_level_email] [int] NOT NULL,
	[notify_level_netsend] [int] NOT NULL,
	[notify_level_page] [int] NOT NULL,
	[notify_email_operator_id] [int] NOT NULL,
	[notify_netsend_operator_id] [int] NOT NULL,
	[notify_page_operator_id] [int] NOT NULL,
	[delete_level] [int] NOT NULL,
	[date_created] [datetime] NOT NULL,
	[date_modified] [datetime] NOT NULL,
	[version_number] [int] NOT NULL)

insert into @temp
select top 1 j1.* from msdb_orig.dbo.sysjobs as j1
  left join msdb.dbo.sysjobs as j2 on j1.name = j2.name
where j1.name not like '%PSDBA%'
  and j2.name is null

--while exists (select top 1 * from @temp t1)
--begin
  select @job_name = t1.name,
	@enabled = t1.enabled,
	@description = t1.description,
	@start_step_id = t1.start_step_id,
	@category_id = t1.category_id,
	@owner_login_name = s1.name, 
	@notify_level_eventlog = t1.notify_level_eventlog,
	@notify_level_email = t1.notify_level_email,
	@notify_level_netsend = t1.notify_level_netsend,
	@notify_level_page = t1.notify_level_page,
	@notify_email_operator_name = NULL, 
	@notify_netsend_operator_name = NULL, 
	@notify_page_operator_name = NULL,
	--@notify_email_operator_name = s2.name, 
	--@notify_netsend_operator_name = s3.name, 
	--@notify_page_operator_name = s4.name,
	@delete_level = t1.delete_level
	--select t1.*, s2.name, s3.name, s4.name
  from @temp t1
  left join master.sys.server_principals as s1 on t1.owner_sid = s1.sid
  left join msdb_orig.dbo.sysoperators as s2 on t1.notify_email_operator_id = s2.id
  left join msdb_orig.dbo.sysoperators as s3 on t1.notify_netsend_operator_id = s2.id
  left join msdb_orig.dbo.sysoperators as s4 on t1.notify_page_operator_id = s2.id

  exec msdb.dbo.sp_add_job @job_name = @job_name, @enabled = @enabled, @description = @description, 
	@start_step_id = @start_step_id, @category_id = @category_id, @owner_login_name = @owner_login_name, 
    @notify_level_eventlog = @notify_level_eventlog, @notify_level_email = @notify_level_email, 
    @notify_level_netsend = @notify_level_netsend, @notify_level_page = @notify_level_page, 
    @notify_email_operator_name = @notify_email_operator_name, @notify_netsend_operator_name = @notify_netsend_operator_name,
    @notify_page_operator_name = @notify_page_operator_name, @delete_level = @delete_level, 
    @job_id = @job_id OUTPUT

--  delete from @temp where name = @job_name
--end  

  
--add job steps
declare @job_id uniqueidentifier
declare @job_name nvarchar(128)
declare @step_id int
declare @step_name nvarchar(128)
declare @subsystem nvarchar(40)
declare @command nvarchar(max)
declare @cmdexec_success_code int
declare @on_success_action tinyint
declare @on_success_step_id int
declare @on_fail_action tinyint
declare @on_fail_step_id int
declare @database_name nvarchar(128)
declare @database_user_name nvarchar(128)
declare @retry_attempts int
declare @retry_interval int
declare @os_run_priority int
declare @output_file_name nvarchar(200)
declare @flags int

declare @temp2 table (
	job_id_new uniqueidentifier NOT NULL,
	job_id uniqueidentifier NOT NULL,
	step_id int NOT NULL,
	step_name sysname NOT NULL,
	subsystem nvarchar(40) NOT NULL,
	command nvarchar(3200) NULL,
	flags int NOT NULL,
	cmdexec_success_code int NOT NULL,
	on_success_action tinyint NOT NULL,
	on_success_step_id int NOT NULL,
	on_fail_action tinyint NOT NULL,
	on_fail_step_id int NOT NULL,
	database_name sysname NULL,
	database_user_name sysname NULL,
	retry_attempts int NOT NULL,
	retry_interval int NOT NULL,
	os_run_priority int NOT NULL,
	output_file_name nvarchar(200) NULL)

insert into @temp2
select top 1 j2.job_id,
	j3.job_id, j3.step_id, j3.step_name, j3.subsystem, j3.command, j3.flags, j3.cmdexec_success_code, 
	j3.on_success_action, j3.on_success_step_id, j3.on_fail_action, j3.on_fail_step_id, j3.database_name, j3.database_user_name, 
	j3.retry_attempts, j3.retry_interval, j3.os_run_priority, j3.output_file_name
from msdb_orig.dbo.sysjobs as j1
  join msdb.dbo.sysjobs as j2 on j1.name = j2.name
  join msdb_orig.dbo.sysjobsteps as j3 on j1.job_id = j3.job_id
  left join msdb.dbo.sysjobsteps as j4 on j2.job_id = j4.job_id and j3.step_id = j4.step_id and j3.step_name = j4.step_name
where j1.name not like '%PSUser%'
  and j4.step_name is null
order by j2.name, j3.step_id

select
	@job_id = job_id_new, @step_id = step_id, @step_name = step_name, @subsystem = subsystem, 
	@command = command, @cmdexec_success_code = cmdexec_success_code, @on_success_action = on_success_action, 
	@on_success_step_id = on_success_step_id, @on_fail_action = on_fail_action, @on_fail_step_id = on_fail_step_id, 
	@database_name = database_name, @database_user_name = database_user_name, @retry_attempts = retry_attempts, 
	@retry_interval = retry_interval, @os_run_priority = os_run_priority, @output_file_name = output_file_name, @flags = flags
from @temp2 t2

exec msdb.dbo.sp_add_jobstep @job_id = @job_id, @step_id = @step_id, @step_name = @step_name, @subsystem = @subsystem, 
	@command = @command, @cmdexec_success_code = @cmdexec_success_code, @on_success_action = @on_success_action, 
	@on_success_step_id = @on_success_step_id, @on_fail_action = @on_fail_action, @on_fail_step_id = @on_fail_step_id, 
	@database_name = @database_name, @database_user_name = @database_user_name, @retry_attempts = @retry_attempts, 
	@retry_interval = @retry_interval, @os_run_priority = @os_run_priority, @output_file_name = @output_file_name, @flags = @flags
	

--add job schedules
declare @job_id uniqueidentifier
declare @name nvarchar(128)
declare @enabled tinyint
declare @freq_type int
declare @freq_interval int
declare @freq_subday_type int
declare @freq_subday_interval int
declare @freq_relative_interval int
declare @freq_recurrence_factor int
declare @active_start_date int
declare @active_end_date int
declare @active_start_time int
declare @active_end_time int

declare @temp3 table (
	job_id_new uniqueidentifier NOT NULL,
	job_id uniqueidentifier NOT NULL, 
	name sysname NOT NULL,
	enabled int NOT NULL,
	freq_type int NOT NULL,
	freq_interval int NOT NULL,
	freq_subday_type int NOT NULL,
	freq_subday_interval int NOT NULL,
	freq_relative_interval int NOT NULL,
	freq_recurrence_factor int NOT NULL,
	active_start_date int NOT NULL,
	active_end_date int NOT NULL,
	active_start_time int NOT NULL,
	active_end_time int NOT NULL)

insert into @temp3
select top 1 j2.job_id, j1.job_id, j3.name, j3.enabled, j3.freq_type, j3.freq_interval, 
	j3.freq_subday_type, j3.freq_subday_interval, j3.freq_relative_interval, j3.freq_recurrence_factor, 
	j3.active_start_date, j3.active_end_date, j3.active_start_time, j3.active_end_time
	--select *
from msdb_orig.dbo.sysjobs as j1
  join msdb.dbo.sysjobs as j2 on j1.name = j2.name
  join msdb_orig.dbo.sysjobschedules as j3 on j1.job_id = j3.job_id
  left join (select a1.job_id, a2.schedule_id, a2.name from msdb.dbo.sysjobschedules as a1 
				left join msdb.dbo.sysschedules as a2 on a1.schedule_id = a2.schedule_id) as q1
			on j2.job_id = q1.job_id and j3.name = q1.name
where j1.name not like '%PSUser%'
  and q1.name is null
order by j2.name, j3.schedule_id

select * from @temp3 t3 

select
	@job_id = t3.job_id_new, @name = t3.name, @enabled = t3.enabled, @freq_type = t3.freq_type, 
	@freq_interval = t3.freq_interval, @freq_subday_type = t3.freq_subday_type, 
	@freq_subday_interval = t3.freq_subday_interval, @freq_relative_interval = t3.freq_relative_interval, 
	@freq_recurrence_factor = t3.freq_recurrence_factor, @active_start_date = t3.active_start_date, 
	@active_end_date = t3.active_end_date, @active_start_time = t3.active_start_time, @active_end_time = t3.active_end_time
from @temp3 t3

exec msdb.dbo.sp_add_jobschedule 
		@job_id = @job_id, @name = @name, @enabled = @enabled, @freq_type = @freq_type, 
		@freq_interval = @freq_interval, @freq_subday_type = @freq_subday_type, 
		@freq_subday_interval = @freq_subday_interval, @freq_relative_interval = @freq_relative_interval, 
		@freq_recurrence_factor = @freq_recurrence_factor, @active_start_date = @active_start_date, 
		@active_end_date = @active_end_date, @active_start_time = @active_start_time, 
		@active_end_time = @active_end_time
