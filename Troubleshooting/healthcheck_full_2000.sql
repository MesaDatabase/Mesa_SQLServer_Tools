-----------------------------------------------------------
--Health check (FULL)
--		MULTI-SERVER
-----------------------------------------------------------

--CHECK #1: Validate all databases are online and accessible
select
  @@servername, name, user_access_desc, is_read_only,
  state_desc, recovery_model_desc, page_verify_option_desc, DATABASEPROPERTYEX(name,'Status')
  --select *
from master.dbo.sysdatabases


--CHECK #2: Validate mirroring connections are connected
select @@servername, state_desc, login_state_desc from sys.dm_db_mirroring_connections

--CHECK #3: Validate that mirroring sessions are synchronized, check timeout value, validate metrics are within parameters

/*
LogGenerationKBPerSec: Amount of log generated since preceding update of the mirroring status of this database in kilobytes/sec.
UnsentLogKB: Size of the unsent log in the send queue on the principal in kilobytes.
SendRateKBPerSec: Send rate of log from the principal to the mirror in kilobytes/sec.
UnrestoredLogKB: Size of the redo queue on the mirror in kilobytes.
RecoveryRateKBPerSec: Redo rate on the mirror in kilobytes/sec.
TransactionDelayMs: Total delay for all transactions in milliseconds.
PrincipalTransactionsPerSec: Number of transactions that are occurring per second on the principal server instance.
AverageDelayPerTransaction: Average delay on the principal server instance for each transaction because of database mirroring. In high-performance mode (that is, when the SAFETY property is set to OFF), this value is generally 0.
TimeRecorded: Time at which the row was recorded by the database mirroring monitor. This is the system clock time of the principal.
TimeBehind: Approximate system-clock time of the principal to which the mirror database is currently caught up. This value is meaningful only on the principal server instance. 
*/

use master
go

set nocount on

declare @db varchar(500)
declare @sql varchar(500)

create table #t2 (DatabaseName varchar(100), Role bit, MirroringState int, WitnessStatus tinyint, LogGenerationKBPerSec bigint, UnsentLogKB bigint, SendRateKBPerSec bigint, UnrestoredLogKB bigint, RecoveryRateKBPerSec bigint, TransactionDelayMs bigint, PrincipalTransactionsPerSec bigint, AverageDelayPerTransaction bigint, TimeRecorded datetime, TimeBehind datetime, LocalTime datetime)

declare @t1 table (DbId int, DbName varchar(255))
insert into @t1
select database_id, DB_NAME(database_id)
from sys.database_mirroring
where database_id > 4
  and mirroring_guid is not null
order by DB_NAME(database_id)  

while exists (select * from @t1 t1)
begin
	set @db = (select top 1 DbName from @t1 t1)
	set @sql = 'exec msdb.dbo.sp_dbmmonitorresults @database_name = ''' + @db + ''';'
	
	insert into #t2
	exec(@sql)

	delete from @t1 where DbName = @db
end	

select 
  DatabaseName,
  case when Role = 1 then 'Principal' else 'Mirror' end as Role,
  case when MirroringState = 0 then 'Suspended'
	   when MirroringState = 1 then 'Disconnected'
	   when MirroringState = 2 then 'Synchronizing'
	   when MirroringState = 3 then 'Pending Failover'
	   when MirroringState = 4 then 'Synchronized' end as MirroringState,
  mirroring_safety_level_desc as SafetyLevel, 
  mirroring_connection_timeout as MirroringConnectionTimeout,
  LogGenerationKBPerSec,
  UnsentLogKB,
  SendRateKBPerSec,
  UnrestoredLogKB,
  RecoveryRateKBPerSec, 
  TransactionDelayMs, 
  PrincipalTransactionsPerSec, 
  AverageDelayPerTransaction, 
  TimeRecorded, 
  TimeBehind
from #t2 as t2
  join sys.database_mirroring as dm1 on t2.DatabaseName =DB_NAME(dm1.database_id)
drop table #t2


--CHECK #4: Check logs for errors/corruption
create table #temp (Text varchar(2000), ContinuationRow int)
insert into #temp
exec master.dbo.xp_readerrorlog

select @@servername, * from #temp t1
where 1=1
  --and LogDate >= GETDATE() - 1 --last day
  --and LogDate >= GETDATE() - .0013888 --last 2 minutes
  and (Text like '%error%' or Text like '%fail%' or Text like '%inaccessible%')
  and Text not like '%The error log has been reinitialized%'
  and Text not like '%Logging SQL Server messages in file%'
  and Text not like '%CHECKDB%'
  and Text not like '%ERRORLOG%'
  and Text not like '%Registry startup parameters%'
  and Text not like '%Login failed%'

drop table #temp
  
--CHECK #5: Failed jobs (last 24 hours)
SELECT DISTINCT T1.server AS [Server Name],

T1.step_id AS [Step_id],
T1.step_name AS [Step Name],
SUBSTRING(T2.name,1,140) AS [SQL Job Name],
CAST(CONVERT(DATETIME,CAST(run_date AS CHAR(8)),101) AS CHAR(11)) AS [Failure Date],
T1.run_date, T1.run_time,
T1.run_duration StepDuration,
CASE T1.run_status
WHEN 0 THEN 'Failed'
WHEN 1 THEN 'Succeeded'
WHEN 2 THEN 'Retry'
WHEN 3 THEN 'Cancelled'
WHEN 4 THEN 'In Progress'
END AS ExecutionStatus,
T1.message AS [Error Message]
--select *
FROM
msdb..sysjobhistory T1 INNER JOIN msdb..sysjobs T2 ON T1.job_id = T2.job_id
WHERE
T1.run_status NOT IN (1,2,4)
AND T1.step_id != 0
AND run_date >= CONVERT(CHAR(8), (SELECT DATEADD (DAY,(-7), GETDATE())), 112)

--CHECK #6: CPU Utilization History for last 256 minutes
DECLARE @ts_now bigint = (SELECT cpu_ticks/(cpu_ticks/ms_ticks) FROM sys.dm_os_sys_info WITH (NOLOCK)); 

SELECT TOP(256) SQLProcessUtilization AS [SQL Server Process CPU Utilization], 
               SystemIdle AS [System Idle Process], 
               100 - SystemIdle - SQLProcessUtilization AS [Other Process CPU Utilization], 
               DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS [Event Time] 
FROM (SELECT record.value('(./Record/@id)[1]', 'int') AS record_id, 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]', 'int') 
			AS [SystemIdle], 
			record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]', 'int') 
			AS [SQLProcessUtilization], [timestamp] 
	  FROM (SELECT [timestamp], CONVERT(xml, record) AS [record] 
			FROM sys.dm_os_ring_buffers WITH (NOLOCK)
			WHERE ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR' 
			AND record LIKE N'%<SystemHealth>%') AS x) AS y 
ORDER BY record_id DESC OPTION (RECOMPILE);

--CHECK #7: CPU utilization by database
create table #t1 (SPID int, Status varchar(25), Login varchar(50), HostName varchar(50), BlkBy varchar(10), DbName varchar(255), Command varchar(255), CPUTime bigint, DiskIO bigint, LastBatch varchar(50), ProgramName varchar(2000), SPID2 int)
insert into #t1
exec sp_who2

select DbName, sum(CPUTime)
from #t1
where DbName is not null
group by DbName

drop table #t1

--CHECK #8: Memory info
-- You want to see "Available physical memory is high"
create table #SVer(ID int,  Name  sysname, Internal_Value int, Value nvarchar(512))
insert #SVer exec master.dbo.xp_msver
                
SELECT *
FROM #SVer
WHere Name = 'PhysicalMemory'
GO

drop table #SVer

--CHECK #9: Page Life Expectancy (PLE) value for each NUMA node
--SELECT @@SERVERNAME AS [Server Name], [object_name], instance_name, cntr_value AS [Page Life Expectancy]
--FROM sys.dm_os_performance_counters WITH (NOLOCK)
--WHERE [object_name] LIKE N'%Buffer Node%' -- Handles named instances
--AND counter_name = N'Page life expectancy' OPTION (RECOMPILE);

--CHECK #10: Memory Grants Pending value for current instance (Memory Grants Pending)
--SELECT @@SERVERNAME AS [Server Name], [object_name], cntr_value AS [Memory Grants Pending]                                                                                                       
--FROM sys.dm_os_performance_counters WITH (NOLOCK)
--WHERE [object_name] LIKE N'%Memory Manager%' -- Handles named instances
--AND counter_name = N'Memory Grants Pending' OPTION (RECOMPILE);


--CHECK #11: Disk Latency
set nocount on

declare @dbid int
declare @fileid int
declare @sql varchar(1000)
  
declare @t1 table (DbId int, DatabaseName varchar(255), FileId int)
insert into @t1
SELECT s1.dbid, s2.name, s2.fileid
--select *
from master.dbo.sysdatabases as s1
  join sysaltfiles as s2 on s1.dbid = s2.dbid
where DATABASEPROPERTYEX(s1.name,'Status') not in ('OFFLINE','RESTORING')

create table #t2 (DbId int, FileId int, TimeStamp int, NumberReads bigint, NumberWrites bigint, BytesRead bigint, BytesWritten bigint, IoStallMS bigint)

while exists (select top 1 * from @t1)
begin
  set @dbid = (select top 1 DbId from @t1)
  set @fileid = (select top 1 FileId from @t1 where DbId = @dbid)
  set @sql = 'insert into #t2 select * from :: fn_virtualfilestats(' + cast(@dbid as varchar(3)) + ',' + cast(@fileid as varchar(3)) + ')'
  exec(@sql)
  delete from @t1 where DbId = @dbid and FileId = @fileid
end

select left(s1.filename,1) as Drive, 
sum(NumberReads) as Reads,
sum(NumberWrites) as Writes,
sum(BytesRead) as BytesRead,
sum(BytesWritten) as BytesWritten,
sum(IOStallMS) as IOStallMs
from #t2 as t2
  join sysaltfiles as s1 on t2.DbId = s1.dbid
group by left(s1.filename,1)

drop table #t2

--CHECK #12: I/O warnings
create table #temp (Text varchar(2000), ContinuationRow int)
insert into #temp
exec master.dbo.xp_readerrorlog

select @@servername, * from #temp t1
where 1=1
  --and LogDate >= GETDATE() - 1 --last day
  --and LogDate >= GETDATE() - .0013888 --last 2 minutes
  and Text like '%taking longer than 15 seconds%'

drop table #temp

--CHECK #13: IO Stalls by File
SELECT DB_NAME(fs.database_id) AS [Database Name], CAST(fs.io_stall_read_ms/(1.0 + fs.num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],
CAST(fs.io_stall_write_ms/(1.0 + fs.num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
CAST((fs.io_stall_read_ms + fs.io_stall_write_ms)/(1.0 + fs.num_of_reads + fs.num_of_writes) AS NUMERIC(10,1)) AS [avg_io_stall_ms],
CONVERT(DECIMAL(18,2), mf.size/128.0) AS [File Size (MB)], mf.physical_name, mf.type_desc, fs.io_stall_read_ms, fs.num_of_reads, 
fs.io_stall_write_ms, fs.num_of_writes, fs.io_stall_read_ms + fs.io_stall_write_ms AS [io_stalls], fs.num_of_reads + fs.num_of_writes AS [total_io]
FROM sys.dm_io_virtual_file_stats(null,null) AS fs
INNER JOIN sys.master_files AS mf WITH (NOLOCK)
ON fs.database_id = mf.database_id
AND fs.[file_id] = mf.[file_id]
ORDER BY avg_io_stall_ms DESC OPTION (RECOMPILE);

--CHECK #14: Blocking
-- The results will change from second to second on a busy system
-- You should run this query multiple times when you see signs of blocking
select distinct 
  es.session_id as BlkdProc,
  er.blocking_session_id as BlkdBy,
  db_name(tl.resource_database_id) as [Database],
  tl.resource_type as LockType,
  tl.resource_associated_entity_id as ObjectId,
  object_name(tl.resource_associated_entity_id) as ObjectName,
  es2.login_name as BlockingLoginName,
  cast(es2.host_name as varchar(100)) as BlockingHostName, 
  cast(es2.program_name as varchar(100)) as BlockingProgramName,
  er2.command as BlockingCommand
--select *
from msdb.sys.dm_exec_sessions es
  left join msdb.sys.dm_exec_requests er on es.session_id = er.session_id
  left join msdb.sys.dm_exec_sessions es2 on er.blocking_session_id = es2.session_id
  left join msdb.sys.dm_exec_requests er2 on es2.session_id = er2.session_id
  left join msdb.sys.dm_tran_locks tl on er.blocking_session_id = tl.request_session_id
where er.blocking_session_id != 0 
	and er.wait_type not like '%LATCH%'
	and er.wait_time != 0
	and es.session_id != er.blocking_session_id	
	and tl.resource_type = 'OBJECT'
order by er.blocking_session_id

--CHECK #15: Top Waits
WITH [Waits] 
AS (SELECT wait_type, wait_time_ms/ 1000.0 AS [WaitS],
          (wait_time_ms - signal_wait_time_ms) / 1000.0 AS [ResourceS],
           signal_wait_time_ms / 1000.0 AS [SignalS],
           waiting_tasks_count AS [WaitCount],
           100.0 *  wait_time_ms / SUM (wait_time_ms) OVER() AS [Percentage],
           ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats WITH (NOLOCK)
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR', N'BROKER_TASK_STOP',
		N'BROKER_TO_FLUSH', N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
        N'CHKPT', N'CLR_AUTO_EVENT', N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE', N'DBMIRROR_WORKER_QUEUE',
		N'DBMIRRORING_CMD', N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC', N'FSAGENT', N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION', N'HADR_LOGCAPTURE_WAIT', 
		N'HADR_NOTIFICATION_DEQUEUE', N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP', N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED', N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP', N'REQUEST_FOR_DEADLOCK_SEARCH',
		N'RESOURCE_QUEUE', N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH', N'SLEEP_DBSTARTUP',
		N'SLEEP_DCOMSTARTUP', N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP', N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT', N'SP_SERVER_DIAGNOSTICS_SLEEP',
		N'SQLTRACE_BUFFER_FLUSH', N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP', N'SQLTRACE_WAIT_ENTRIES',
		N'WAIT_FOR_RESULTS', N'WAITFOR', N'WAITFOR_TASKSHUTDOWN', N'WAIT_XTP_HOST_WAIT',
		N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG', N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
    AND waiting_tasks_count > 0)
SELECT
    MAX (W1.wait_type) AS [WaitType],
    CAST (MAX (W1.WaitS) AS DECIMAL (16,2)) AS [Wait_Sec],
    CAST (MAX (W1.ResourceS) AS DECIMAL (16,2)) AS [Resource_Sec],
    CAST (MAX (W1.SignalS) AS DECIMAL (16,2)) AS [Signal_Sec],
    MAX (W1.WaitCount) AS [Wait Count],
    CAST (MAX (W1.Percentage) AS DECIMAL (5,2)) AS [Wait Percentage],
    CAST ((MAX (W1.WaitS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgWait_Sec],
    CAST ((MAX (W1.ResourceS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgRes_Sec],
    CAST ((MAX (W1.SignalS) / MAX (W1.WaitCount)) AS DECIMAL (16,4)) AS [AvgSig_Sec]
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.RowNum <= W1.RowNum
GROUP BY W1.RowNum
HAVING SUM (W2.Percentage) - MAX (W1.Percentage) < 99 -- percentage threshold
OPTION (RECOMPILE);

--CHECK #16: Authentication mode is mixed
select @@servername, 
	   case SERVERPROPERTY('IsIntegratedSecurityOnly')   
		when 1 then 'Windows Authentication'   
		when 0 then 'Windows and SQL Server Authentication'   
	   end as AuthMode 
  
--CHECK #17: Last Statistics Update
SELECT SCHEMA_NAME(o.Schema_ID) + N'.' + o.NAME AS [Object Name], o.type_desc AS [Object Type],
      i.name AS [Index Name], STATS_DATE(i.[object_id], i.index_id) AS [Statistics Date], 
      s.auto_created, s.no_recompute, s.user_created,
	  st.row_count, st.used_page_count
FROM sys.objects AS o WITH (NOLOCK)
INNER JOIN sys.indexes AS i WITH (NOLOCK)
ON o.[object_id] = i.[object_id]
INNER JOIN sys.stats AS s WITH (NOLOCK)
ON i.[object_id] = s.[object_id] 
AND i.index_id = s.stats_id
INNER JOIN sys.dm_db_partition_stats AS st WITH (NOLOCK)
ON o.[object_id] = st.[object_id]
AND i.[index_id] = st.[index_id]
WHERE o.[type] IN ('U', 'V')
AND st.row_count > 0
ORDER BY STATS_DATE(i.[object_id], i.index_id) DESC OPTION (RECOMPILE);  

--CHECK #18: VLF counts
set nocount on

declare @t1 table (DatabaseName varchar(50))
insert into @t1
select name from master.dbo.sysdatabases 
where name not in ('master','model','msdb','DellDBA','PSDBA','DBA','DellDBAUtility')

create table #t2 (FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))
create table #t3 (DatabaseName varchar(50), FileId int, FileSize bigint, StartOffset bigint, FSeqNo bigint, Status int, Parity int, CreateLSN varchar(50))
create table #t4 (DatabaseName varchar(50), FileId int, Status int, Row int)

declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
set @SQL='DBCC LOGINFO (' + @dbname + ') WITH TABLERESULTS, NO_INFOMSGS'

insert into #t2
exec(@SQL)
insert into #t3 select @dbname, * from #t2

insert into #t4
select @dbname, FileId, Status, ROW_NUMBER() over(order by @dbname, StartOffset) from #t2

delete from @t1 where DatabaseName = @dbname
delete from #t2
end 

select @@SERVERNAME, #t4.DatabaseName, #t4.FileId, a.vlf_count, b.last_stat2_row from #t4 
  join (select DatabaseName, COUNT(1) as vlf_count from #t3 group by DatabaseName) a on #t4.DatabaseName = a.DatabaseName
  join (select DatabaseName, MAX(Row) as last_stat2_row from #t4 where Status = 2 group by DatabaseName) b on #t4.DatabaseName = b.DatabaseName and #t4.Row = b.last_stat2_row
where Status = 2

drop table #t2
drop table #t3
drop table #t4
  
--CHECK #19: Tlog utilization
DBCC SQLPERF(LOGSPACE)

--CHECK #20: Disk utilization
SELECT DISTINCT vs.volume_mount_point, vs.file_system_type, 
vs.logical_volume_name, CONVERT(DECIMAL(18,2),vs.total_bytes/1073741824.0) AS [Total Size (GB)],
CONVERT(DECIMAL(18,2),vs.available_bytes/1073741824.0) AS [Available Size (GB)],  
CAST(CAST(vs.available_bytes AS FLOAT)/ CAST(vs.total_bytes AS FLOAT) AS DECIMAL(18,2)) * 100 AS [Space Free %] 
FROM sys.master_files AS f WITH (NOLOCK)
CROSS APPLY sys.dm_os_volume_stats(f.database_id, f.[file_id]) AS vs OPTION (RECOMPILE);

--CHECK #21: Global trace flags enabled
DBCC TRACESTATUS (-1);

--CHECK #22: Windows error log manual check
