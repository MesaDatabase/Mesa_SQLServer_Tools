USE [msdb]
GO

/****** Object:  Job [SQL Check]    Script Date: 11/01/2011 14:26:43 ******/
BEGIN TRANSACTION
DECLARE @ReturnCode INT
SELECT @ReturnCode = 0
/****** Object:  JobCategory Monitoring    Script Date: 11/01/2011 14:26:43 ******/
IF NOT EXISTS (SELECT name FROM msdb.dbo.syscategories WHERE name=N'Monitoring' AND category_class=1)
BEGIN
EXEC @ReturnCode = msdb.dbo.sp_add_category @class=N'JOB', @type=N'LOCAL', @name=N'Monitoring'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback

END

DECLARE @jobId BINARY(16)
EXEC @ReturnCode =  msdb.dbo.sp_add_job @job_name=N'SQL Check', 
		@enabled=1, 
		@notify_level_eventlog=2, 
		@notify_level_email=0, 
		@notify_level_netsend=0, 
		@notify_level_page=0, 
		@delete_level=0, 
		@description=N'This job perform some high level checks and sends out alerts based on results', 
		@category_name=N'Monitoring', 
		@owner_login_name=N'sa', @job_id = @jobId OUTPUT
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check SQL Error Log]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check SQL Error Log', 
		@step_id=1, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @Time_Start datetime;
declare @Time_End datetime;
set @Time_Start=getdate()-2;
set @Time_End=getdate();

create table #ErrorLog (logdate datetime
                      , processinfo varchar(255)
                      , Message varchar(500) )

insert #ErrorLog (logdate, processinfo, Message)
   EXEC master.dbo.xp_readerrorlog 0, 1, null, null , @Time_Start, @Time_End, N''desc'';

create table SQL_Log_Errors (
	[logdate] datetime,
    [Message] varchar (500) )

insert into SQL_Log_Errors 
  select LogDate, Message FROM #ErrorLog
   where (Message LIKE ''%error%'' OR Message LIKE ''%failed%'') 
     and processinfo NOT LIKE ''logon''
   order by logdate desc

drop table #ErrorLog

declare @cnt int  
select @cnt=COUNT(1) from SQL_Log_Errors
if (@cnt > 0)
begin

	declare @strsubject varchar(100)
	select @strsubject=''There are errors in the SQL Error Log on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>SQL Error Log Errors - '' + @@SERVERNAME + ''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>Log Date</th>'' +
		N''<th>Message</th></tr>'' +
		CAST ( ( SELECT td = [logdate], '''',
	                    td = [Message]
				  FROM SQL_Log_Errors
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	@from_address=''test@test.com'',
	@recipients=''test@test.com'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' ,
	@profile_name=''test profile''
end

drop table SQL_Log_Errors', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Failed Jobs]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Failed Jobs', 
		@step_id=2, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'create table Failed_Jobs (
	[Status] [varchar](6) NOT NULL,
	[Job Name] [varchar](100) NULL,
	[Step ID] [varchar](5) NULL,
	[Step Name] [varchar](30) NULL,
	[Start Date Time] [varchar](30) NULL,
	[Message] [nvarchar](4000) NULL)

insert into Failed_Jobs
select ''FAILED'' as Status, cast(sj.name as varchar(100)) as "Job Name",
       cast(sjs.step_id as varchar(5)) as "Step ID",
       cast(sjs.step_name as varchar(30)) as "Step Name",
       cast(REPLACE(CONVERT(varchar,convert(datetime,convert(varchar,sjh.run_date)),102),''.'',''-'')+'' ''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),1,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),3,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),5,2) as varchar(30)) ''Start Date Time'',
       sjh.message as "Message"
from sysjobs sj
join sysjobsteps sjs 
 on sj.job_id = sjs.job_id
join sysjobhistory sjh 
 on sj.job_id = sjh.job_id and sjs.step_id = sjh.step_id
where sjh.run_status <> 1
  and cast(sjh.run_date as float)*1000000+sjh.run_time > 
      cast(convert(varchar(8), getdate()-1, 112) as float)*1000000+70000 --yesterday at 7am
union
select ''FAILED'',cast(sj.name as varchar(100)) as "Job Name",
       ''MAIN'' as "Step ID",
       ''MAIN'' as "Step Name",
       cast(REPLACE(CONVERT(varchar,convert(datetime,convert(varchar,sjh.run_date)),102),''.'',''-'')+'' ''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),1,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),3,2)+'':''+SUBSTRING(RIGHT(''000000''+CONVERT(varchar,sjh.run_time),6),5,2) as varchar(30)) ''Start Date Time'',
       sjh.message as "Message"
from sysjobs sj
join sysjobhistory sjh 
 on sj.job_id = sjh.job_id
where sjh.run_status <> 1 and sjh.step_id=0
  and cast(sjh.run_date as float)*1000000+sjh.run_time >
      cast(convert(varchar(8), getdate()-1, 112) as float)*1000000+70000 --yesterday at

declare @cnt int  
select @cnt=COUNT(1) from Failed_Jobs    
if (@cnt > 0)
begin

	declare @strsubject varchar(100)
	select @strsubject=''Check the following failed jobs on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>Failed Jobs Listing - '' + @@SERVERNAME +''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>Status</th><th>Job Name</th>'' +
		N''<th>Step ID</th><th>Step Name</th><th>Start Date</th>'' +
		N''<th>Message</th></tr>'' +
		CAST ( ( SELECT td = [Status], '''',
	                    td = [Job Name], '''',
	                    td = [Step ID], '''',
	                    td = [Step Name], '''',
	                    td = [Start Date Time], '''',
	                    td = [Message]
				  FROM Failed_Jobs
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	@from_address=''test@test.com'',
	@recipients=''test@test.com'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' ,
	@profile_name=''test profile''
end

drop table Failed_Jobs', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Missing Backups]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Missing Backups', 
		@step_id=3, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'create table Missing_Backups (
	[DB Name] [varchar](100) NOT NULL,
	[Type] [varchar] (5) NOT NULL,
	[Last Backup] [varchar](100) NULL)

insert into Missing_Backups 
SELECT d.name AS "Database",''Full'' as "Type",
       ISNULL(CONVERT(VARCHAR,b.backupdate,120),''NEVER'') AS "Last Full Backup"
FROM sys.databases d
LEFT JOIN (SELECT database_name,type,MAX(backup_finish_date) backupdate FROM backupset
           WHERE type LIKE ''D''
           GROUP BY database_name,type) b on d.name=b.database_name
WHERE (backupdate IS NULL OR backupdate < getdate()-1)
  AND d.name <> ''tempdb''
UNION
SELECT d.name AS "Database",''Trn'' as "Type",
       ISNULL(CONVERT(VARCHAR,b.backupdate,120),''NEVER'') AS "Last Log Backup"
FROM sys.databases d
LEFT JOIN (SELECT database_name,type,MAX(backup_finish_date) backupdate FROM backupset
           WHERE type LIKE ''L''
           GROUP BY database_name,type) b on d.name=b.database_name
WHERE recovery_model = 1
  AND (backupdate IS NULL OR backupdate < getdate()-1)
  AND d.name <> ''tempdb''
  
declare @cnt int  
select @cnt=COUNT(1) from Missing_Backups    
if (@cnt > 0)
begin

	declare @strsubject varchar(100)
	select @strsubject=''Check for missing backups on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>Databases Missing Backups Listing - '' + @@SERVERNAME +''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>DB Name</th><th>Type</th>'' +
		N''<th>Last Backup</th></tr>'' +
		CAST ( ( SELECT td = [DB Name], '''',
	                    td = [Type], '''',
	                    td = [Last Backup]
				  FROM Missing_Backups
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	@from_address=''test@test.com'',
	@recipients=''test@test.com'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' ,
	@profile_name=''test profile''
end

drop table Missing_Backups', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Disk Space]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Disk Space', 
		@step_id=4, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'create table #DriveSpaceLeft (Drive varchar(10),
                              [MB Free] bigint )

insert #DriveSpaceLeft (Drive, [MB Free])
   EXEC master.dbo.xp_fixeddrives;

create table DrivesWithIssue (Drive varchar(10),
                              [MB Free] bigint )

insert into DrivesWithIssue 
  select Drive, [MB Free] from #DriveSpaceLeft
  where [MB Free] < 1000

drop table #DriveSpaceLeft

declare @cnt int  
select @cnt=COUNT(1) from DrivesWithIssue
if (@cnt > 0)
begin

	declare @strsubject varchar(100)
	select @strsubject=''Check drive space on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>Drives with less that 1GB Free  - '' + @@SERVERNAME + ''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>Drive</th>'' +
		N''<th>MB Free</th></tr>'' +
		CAST ( ( SELECT td = [Drive], '''',
	                    td = [MB Free]
				  FROM DrivesWithIssue
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	@from_address=''test@test.com'',
	@recipients=''test@test.com'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' ,
	@profile_name=''test profile''
end

drop table DrivesWithIssue', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Server Memory]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Server Memory', 
		@step_id=5, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'create table MemoryInfo (
	[Total Memory MB] bigint NOT NULL,
	[Available Memory MB] bigint NOT NULL,
	[% Memory Free] decimal(5,2) NOT NULL)

insert into MemoryInfo
SELECT total_physical_memory_kb/1024 as "Total Memory MB",
       available_physical_memory_kb/1024 as "Available Memory MB",
       available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS "% Memory Free"
FROM sys.dm_os_sys_memory

declare @memfree float  
select @memfree=[Available Memory MB] from MemoryInfo    
if (@memfree < 1000)
begin

	declare @strsubject varchar(100)
	select @strsubject=''Check memory usage on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>Server Memory Information - '' + @@SERVERNAME +''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>TotalMemory MB</th><th>Available Memory MB</th>'' +
		N''<th>% Memory Free</th></tr>'' +
		CAST ( ( SELECT td = [Total Memory MB], '''',
	                    td = [Available Memory MB], '''',
	                    td = [% Memory Free]
				  FROM MemoryInfo
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	@from_address=''test@test.com'',
	@recipients=''test@test.com'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' ,
	@profile_name=''test profile''
end

drop table MemoryInfo', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Connection Count]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Connection Count', 
		@step_id=6, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'create table ConnectionCount (
	[spid] bigint NOT NULL,
	[blocked] int NOT NULL,
	[dbname] varchar(250) NOT NULL,
	[open_tran] int NOT NULL,
	[status] varchar(250) NOT NULL,
	[hostname] varchar(250) NOT NULL,
	[cmd] varchar(250) NOT NULL,
	[login_time] varchar(250) NOT NULL,
	[loginame] varchar(250) NOT NULL,
	[net_library] varchar(250) NOT NULL )

insert into ConnectionCount
  select spid,blocked,d.name,open_tran,status,hostname,cmd,login_time,loginame,net_library
  from sys.sysprocesses p
  inner join sys.databases d on p.dbid=d.database_id
  where status not like ''background%''


declare @connectioncnt float  
select @connectioncnt=COUNT(1) from ConnectionCount    
if (@connectioncnt > 500)
begin

	declare @strsubject varchar(100)
	select @strsubject=''Check user connection count on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>Connection information - '' + @@SERVERNAME +''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>SPID</th><th>Blocked</th>'' +
		N''<th>DBName</th><th>Open_Tran</th>'' +		
		N''<th>Status</th><th>Hostname</th>'' +
		N''<th>cmd</th><th>Login_Time</th>'' +				
		N''<th>Login_Name</th><th>Net_Library</th></tr>'' +
		CAST ( ( SELECT td = [spid], '''',
	                    td = [blocked], '''',
	                    td = [dbname], '''',
	                    td = [open_tran], '''',
	                    td = [status], '''',
	                    td = [hostname], '''',
	                    td = [cmd], '''',
	                    td = [login_time], '''',
	                    td = [loginame], '''',
	                    td = [net_library]
				  FROM ConnectionCount
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	@from_address=''test@test.com'',
	@recipients=''test@test.com'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' ,
	@profile_name=''test profile''
end

drop table ConnectionCount', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Check Batch Requests-Sec]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Check Batch Requests-Sec', 
		@step_id=7, 
		@cmdexec_success_code=0, 
		@on_success_action=3, 
		@on_success_step_id=0, 
		@on_fail_action=3, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @inibrps bigint
declare @brps decimal(38,2)

select @inibrps=cntr_value 
from sys.dm_os_performance_counters
where counter_name LIKE ''Batch Requests/sec%''

waitfor delay ''000:00:10''

select @brps=(cntr_value-@inibrps)/10.0
from sys.dm_os_performance_counters
where counter_name like ''Batch Requests/sec%''

if (@brps > 1000)
begin

	declare @strsubject varchar(100)
	select @strsubject=''Check batch requests/sec on '' + @@SERVERNAME

	declare @tableHTML  nvarchar(max);
	set @tableHTML =
		N''<H1>Batch Request rate - '' + @@SERVERNAME +''</H1>'' +
		N''<table border="1">'' +
		N''<tr><th>Batch Reqests/sec</th></tr>'' +
		CAST ( ( SELECT td = @brps
				  FOR XML PATH(''tr''), TYPE 
		) AS NVARCHAR(MAX) ) +
		N''</table>'' ;

	EXEC msdb.dbo.sp_send_dbmail
	@from_address=''test@test.com'',
	@recipients=''test@test.com'',
	@subject = @strsubject,
	@body = @tableHTML,
	@body_format = ''HTML'' ,
	@profile_name=''test profile''
end

', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
/****** Object:  Step [Send Completed Email]    Script Date: 11/01/2011 14:26:43 ******/
EXEC @ReturnCode = msdb.dbo.sp_add_jobstep @job_id=@jobId, @step_name=N'Send Completed Email', 
		@step_id=8, 
		@cmdexec_success_code=0, 
		@on_success_action=1, 
		@on_success_step_id=0, 
		@on_fail_action=2, 
		@on_fail_step_id=0, 
		@retry_attempts=0, 
		@retry_interval=0, 
		@os_run_priority=0, @subsystem=N'TSQL', 
		@command=N'declare @strsubject varchar(100)
select @strsubject=''SQL check completed on '' + @@SERVERNAME

EXEC msdb.dbo.sp_send_dbmail
@from_address=''test@test.com'',
@recipients=''test@test.com'',
@subject = @strsubject,
@profile_name=''test profile''', 
		@database_name=N'master', 
		@flags=0
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_update_job @job_id = @jobId, @start_step_id = 1
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobschedule @job_id=@jobId, @name=N'Daily', 
		@enabled=1, 
		@freq_type=4, 
		@freq_interval=1, 
		@freq_subday_type=1, 
		@freq_subday_interval=0, 
		@freq_relative_interval=0, 
		@freq_recurrence_factor=0, 
		@active_start_date=20111101, 
		@active_end_date=99991231, 
		@active_start_time=60000, 
		@active_end_time=235959
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
EXEC @ReturnCode = msdb.dbo.sp_add_jobserver @job_id = @jobId, @server_name = N'(local)'
IF (@@ERROR <> 0 OR @ReturnCode <> 0) GOTO QuitWithRollback
COMMIT TRANSACTION
GOTO EndSave
QuitWithRollback:
    IF (@@TRANCOUNT > 0) ROLLBACK TRANSACTION
EndSave:

GO



