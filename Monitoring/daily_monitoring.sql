--services running
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'MSSQLServer'
exec master.dbo.xp_servicecontrol 'QUERYSTATE', 'SQLServerAgent'

--failed jobs
select
replace(jobs.name, ',',''),
hist.run_date, hist.run_time, replace(hist.message,',','')
--select top 10 *
 from msdb.dbo.sysjobs jobs
  join msdb.dbo.sysjobhistory hist (nolock) on jobs.job_id = hist.job_id
where 1=1
  and jobs.enabled = 1
  and run_status = 0
  and run_date = (select max(run_date) from msdb.dbo.sysjobhistory where job_id = jobs.job_id)
  and run_time = (select max(run_time) from msdb.dbo.sysjobhistory jobs2 where jobs2.job_id = jobs.job_id and run_date = (select max(run_date) from msdb.dbo.sysjobhistory where job_id = jobs.job_id))
  and hist.step_id > 0

--good backup
declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 
--where name = 'tempdb'
--where dbid>4

create table #t2 (database_name varchar(100), name varchar(100), user_name varchar(255), backup_start_date datetime, backup_finish_date datetime)

declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
insert into #t2
select top 1 database_name, name, USER_NAME, backup_start_date, backup_finish_date from msdb.dbo.backupset
where database_name = @dbname
  and type = 'D'
order by backup_start_date desc

delete from @t1 where DatabaseName = @dbname
end 

select * from #t2
drop table #t2

--sql server log errors
declare @Time_Start datetime;
declare @Time_End datetime;
set @Time_Start=getdate()-2;
set @Time_End=getdate();

declare @ErrorLog table  (logdate datetime
                      , processinfo varchar(255)
                      , Message varchar(500))

insert into @ErrorLog (logdate, processinfo, Message)
exec master.dbo.xp_readerrorlog 0, 1, null, null , @Time_Start, @Time_End, N'desc';

select LogDate, Message 
from @ErrorLog e1
where (Message like '%error%' or Message like '%failed%') 
  and processinfo not like 'logon'
  and Message not like 'DBCC CHECKDB%found 0 errors and repaired 0 errors%'
order by logdate desc

--disk space
exec master.dbo.xp_fixeddrives

--memory
select 
  available_physical_memory_kb/1024 as 'Total Memory MB',
  available_physical_memory_kb/(total_physical_memory_kb*1.0)*100 AS '% Memory Free'
from sys.dm_os_sys_memory

--sql statements in the cache that could use tuning
select top 10 
  text as "SQL Statement",
  last_execution_time as "Last Execution Time",
  (total_logical_reads+total_physical_reads+total_logical_writes)/execution_count as [Average IO],
  (total_worker_time/execution_count)/1000000.0 as [Average CPU Time (sec)],
  (total_elapsed_time/execution_count)/1000000.0 as [Average Elapsed Time (sec)],
  execution_count as "Execution Count",
  qp.query_plan as "Query Plan"
from sys.dm_exec_query_stats qs
  cross apply sys.dm_exec_sql_text(qs.plan_handle) st
  cross apply sys.dm_exec_query_plan(qs.plan_handle) qp
order by total_elapsed_time/execution_count desc

--number of connections
select 
  spid, kpid, blocked, d.name, open_tran, [status], hostname, cmd, login_time, loginame, net_library
from sys.sysprocesses p
  join sys.databases d on p.dbid=d.database_id

--requests being processed
declare @value1 bigint
declare @value2 bigint

set @value1 = (select cntr_value from sys.dm_os_performance_counters (nolock)
			   where object_name = 'SQLServer:SQL Statistics'
				 and counter_name = 'Batch Requests/sec')
				 
waitfor delay '00:00:05'

set @value2 = (select cntr_value from sys.dm_os_performance_counters (nolock)
			   where object_name = 'SQLServer:SQL Statistics'
				 and counter_name = 'Batch Requests/sec')

select cast((@value2-@value1) as decimal(17,2))/5 as 'BatchRequestsPerSec'