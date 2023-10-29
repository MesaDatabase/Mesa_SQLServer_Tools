--BATCH REQUESTS PER SECOND
declare @value1 bigint
declare @value2 bigint

set @value1 = (select cntr_value from sys.dm_os_performance_counters (nolock)
			   where object_name = 'SQLServer:SQL Statistics'
				 and counter_name = 'Batch Requests/sec')
				 
waitfor delay '00:00:05'

set @value2 = (select cntr_value from sys.dm_os_performance_counters (nolock)
			   where object_name = 'SQLServer:SQL Statistics'
				 and counter_name = 'Batch Requests/sec')

select cast((@value2-@value1) as decimal(17,2))/5


--BLOCKING, CONNECTIONS and WAITS
select * from msdb.sys.dm_exec_sessions --active user connections and internal tasks
select * from msdb.sys.dm_exec_connections --established connections
select * from msdb.sys.dm_exec_requests --each executing request
		--wait_type = type of resource that the connection is waiting on, NULL then the SPID is not currently waiting on any resource
		--last_wait_type = the last waittype that the SPID experienced unless currently experiencing
		--wait_time = number of milliseconds that the SPID has been waiting with the current waittype
select * from msdb.sys.dm_tran_locks --Each row represents a currently active request to the lock manager for a lock that has been granted or is waiting to be granted

--CURRENT WAIT TYPES
select distinct wait_type 
from msdb.sys.dm_exec_requests
where wait_type is not null
order by wait_type
	
--BLOCKING SESSIONS and THEIR SQL
select blocking_session_id, wait_duration_ms, session_id 
from sys.dm_os_waiting_tasks
where blocking_session_id is not null

declare @sessionid int

declare @t1 table (BlockingSessionId int)
insert into @t1
select blocking_session_id from sys.dm_os_waiting_tasks where blocking_session_id is not null

while exists (select top 1 BlockingSessionId from @t1 t1)
begin
  set @sessionid = (select top 1 BlockingSessionId from @t1 t1)
  dbcc INPUTBUFFER(@sessionid)
  delete from @t1 where BlockingSessionId = @sessionid
end

--BLOCKING SESSIONS and WHAT THEY ARE BLOCKING
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


--CPU
--CACHED PLANS WITH HIGHEST CPU USAGE
select 
  total_cpu_time, 
  total_execution_count,
  number_of_statements,
  s2.text
from (select top 50 
        sum(qs.total_worker_time) as total_cpu_time, 
        sum(qs.execution_count) as total_execution_count,
        count(1) as number_of_statements, 
        qs.sql_handle
       from sys.dm_exec_query_stats qs
       group by qs.sql_handle
       order by sum(qs.total_worker_time) desc) as stats
  cross apply sys.dm_exec_sql_text(stats.sql_handle) as s2 

--TOP 50 SQL STATEMENTS WITH HIGH AVERAGE CPU CONSUMPTION
select top 50
  total_worker_time/execution_count as AvgCpuTime,
  (select substring(text,statement_start_offset/2,(case when statement_end_offset = -1 then len(convert(nvarchar(max), text)) * 2 
													 else statement_end_offset 
												   end -statement_start_offset)/2) 
   from sys.dm_exec_sql_text(sql_handle)) as query_text, 
  *
from sys.dm_exec_query_stats 
order by AvgCpuTime desc

--OPERATORS THAT MAY BE CPU INTENSIVE
select *
from sys.dm_exec_cached_plans
  cross apply sys.dm_exec_query_plan(plan_handle)
where 1=1
  and (cast(query_plan as nvarchar(max)) like '%Sort%'
       or cast(query_plan as nvarchar(max)) like '%Hash Match%')

--CPU BY DATABASE
with DB_CPU_Stats
as
(select
   DatabaseID,
   db_name(DatabaseID) as DatabaseName,
   sum(total_worker_time) as CpuTimeMs
 from sys.dm_exec_query_stats as qs
   cross apply (select convert(int, value) as DatabaseID
				from sys.dm_exec_plan_attributes(qs.plan_handle)
				where attribute = N'dbid') as F_DB
 group by DatabaseID)

select
  row_number() over(order by CpuTimeMs desc) as RowNum,
  DatabaseName,
  CpuTimeMs,
  cast(CpuTimeMs * 1.0 / sum(CpuTimeMs) over() * 100.0 as decimal(5, 2)) as CpuPercent
from DB_CPU_Stats
where (DatabaseID > 4) AND (DatabaseID <> 32767)
order by RowNum

--CPU BY OBJECT
DECLARE @Count INT
SET @Count = 25;

WITH DB_CPU_Stats
AS
(SELECT
   ROW_NUMBER() OVER(ORDER BY SUM(total_worker_time) DESC) AS rn,
   DatabaseID,
   plan_handle,
   db_name(DatabaseID) AS [DatabaseName],
   SUM(total_worker_time) AS [CPU_Time_Ms]
 FROM sys.dm_exec_query_stats AS qs
   CROSS APPLY (SELECT CONVERT(INT, value) AS [DatabaseID]
				FROM sys.dm_exec_plan_attributes(qs.plan_handle)
				WHERE attribute = N'dbid') AS F_DB
 GROUP BY DatabaseID, plan_handle), 
PlanHandleQuery AS (SELECT
					  ROW_NUMBER() OVER(ORDER BY [CPU_Time_Ms] DESC) AS [row_num],
					  DatabaseName,
					  t2.query_plan,
					  OBJECT_NAME(objectid) AS ObjectName,
					  [CPU_Time_Ms],
					  CAST([CPU_Time_Ms] * 1.0 / SUM([CPU_Time_Ms]) OVER() * 100.0 AS DECIMAL(5, 2)) AS [CPUPercent]
					FROM DB_CPU_Stats
					  CROSS APPLY sys.dm_exec_query_plan(plan_handle) t2
					WHERE (DatabaseID > 4) AND (DatabaseID <> 32767)
					  AND rn <= @Count)

SELECT DatabaseName, query_plan, ObjectName, CPU_Time_Ms, CPUPercent
FROM PlanHandleQuery
WHERE row_num <= @Count
ORDER BY row_num

--You can now click on the link in the query_plan column, and the cached execution plan will open. In this execution plan you can right click and choose “Edit Query Text”:

--CPU BY QUERY
select 
  highest_cpu_queries.plan_handle, 
  highest_cpu_queries.total_worker_time,
  q.dbid,
  q.objectid,
  q.number,
  q.encrypted,
  q.[text]
from (select top 50 
        qs.plan_handle, 
        qs.total_worker_time
      from sys.dm_exec_query_stats qs
      order by qs.total_worker_time desc) as highest_cpu_queries
  cross apply sys.dm_exec_sql_text(plan_handle) as q
order by highest_cpu_queries.total_worker_time desc


--DB FILE USAGE and SIZE
SELECT 
  db_name(mf.database_id) AS databaseName,
  mf.physical_name,
  num_of_reads,
  num_of_bytes_read,
  num_of_writes,
  num_of_bytes_written,
  size_on_disk_bytes
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS divfs
  JOIN sys.master_files AS mf ON mf.database_id = divfs.database_id AND mf.file_id = divfs.file_id
--WHERE DB_NAME(mf.database_id) = 'tempdb'
ORDER BY 1, 3 DESC


--EXCESSIVE COMPILES and RECOMPILES
select * from sys.dm_exec_query_optimizer_info
where (counter = 'optimizations'
      or counter = 'elapsed time')

--TOP 25 STORED PROCS THAT HAVE BEEN RECOMPILED
--The plan_generation_num indicates the number of times the query has recompiled
SELECT TOP 25
  sql_text.text,
  sql_handle,
  plan_generation_num,
  execution_count,
  dbid,
  objectid 
FROM sys.dm_exec_query_stats a
  CROSS APPLY sys.dm_exec_sql_text(sql_handle) AS sql_text
WHERE plan_generation_num > 1
ORDER BY plan_generation_num DESC


--EXTENDED EVENTS
select * from sys.server_event_sessions --all xe sessions
select * from sys.server_event_session_events 
select * from sys.server_event_session_actions
select * from sys.server_event_session_fields 

select * from sys.dm_xe_sessions --active xe sessions
select * from sys.dm_xe_session_targets --where session events are being stored
select * from sys.dm_xe_map_values
select * from sys.dm_xe_object_columns
select * from sys.dm_xe_objects
select * from sys.dm_xe_packages
select * from sys.dm_xe_session_event_actions
select * from sys.dm_xe_session_events
select * from sys.dm_xe_session_object_columns

--EVENTS IN BUFFER BY SPECIFIED EXTENDED EVENT SESSION
declare @temp table (Event_Name varchar(255), [timestamp] datetime, txt varchar(4000), sql_txt varchar(4000))
insert into @temp
SELECT 
    event.value('(event/@name)[1]', 'varchar(50)') AS event_name, 
    DATEADD(hh, 
            DATEDIFF(hh, GETUTCDATE(), CURRENT_TIMESTAMP), 
            event.value('(event/@timestamp)[1]', 'datetime2')) AS [timestamp], 
    ISNULL(event.value('(event/data[@name="statement"]/value)[1]', 'nvarchar(max)'), 
            event.value('(event/data[@name="batch_text"]/value)[1]', 'nvarchar(max)')) AS [stmt_btch_txt], 
    event.value('(event/action[@name="sql_text"]/value)[1]', 'nvarchar(max)') as [sql_text] 
FROM 
(   SELECT n.query('.') as event 
    FROM 
    ( 
        SELECT CAST(target_data AS XML) AS target_data 
        FROM sys.dm_xe_sessions AS s    
        JOIN sys.dm_xe_session_targets AS t 
            ON s.address = t.event_session_address 
        WHERE 1=1
		  AND s.name = 'system_health' 
          AND t.target_name = 'ring_buffer' 
    ) AS sub 
    CROSS APPLY target_data.nodes('RingBufferTarget/event') AS q(n) 
) AS tab 

select * from @temp t1



--HEAP TABLES
SELECT 
  SCHEMA_NAME(o.schema_id) AS [schema],
  object_name(i.object_id ) AS [table],
  p.rows,
  user_seeks,
  user_scans,
  user_lookups, 
  user_updates,
  last_user_seek, 
  last_user_scan,
  last_user_lookup 
--select *
FROM sys.indexes i      
 INNER JOIN sys.objects o ON i.object_id = o.object_id
 INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id 
 LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id 
WHERE i.type_desc = 'HEAP'
  AND last_user_scan IS NOT NULL
ORDER BY rows DESC


--HINT COUNTS
SELECT * FROM sys.dm_exec_query_optimizer_info
WHERE counter IN ('order hint','join hint')
   AND occurrence > 1


--IO
select * from sys.dm_io_backup_tapes (nolock)
select * from sys.dm_io_pending_io_requests (nolock)
select * from sys.dm_io_cluster_shared_drives (nolock)

--I/O
SELECT a.io_stall, a.io_stall_read_ms, a.io_stall_write_ms, a.num_of_reads, 
a.num_of_writes, 
--a.sample_ms, a.num_of_bytes_read, a.num_of_bytes_written, a.io_stall_write_ms, 
( ( a.size_on_disk_bytes / 1024 ) / 1024.0 ) AS size_on_disk_mb, 
db_name(a.database_id) AS dbname, 
b.name, a.file_id, 
db_file_type = CASE 
                   WHEN a.file_id = 2 THEN 'Log' 
                   ELSE 'Data' 
                   END, 
UPPER(SUBSTRING(b.physical_name, 1, 2)) AS disk_location 
FROM sys.dm_io_virtual_file_stats (NULL, NULL) a 
JOIN sys.master_files b ON a.file_id = b.file_id 
AND a.database_id = b.database_id 
ORDER BY a.io_stall DESC 


-- Isolate top waits for server instance since last restart or statistics clear
WITH Waits AS
(SELECT wait_type, wait_time_ms / 1000. AS wait_time_s,
100. * wait_time_ms / SUM(wait_time_ms) OVER() AS pct,
ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS rn
FROM sys.dm_os_wait_stats
WHERE wait_type NOT IN ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK'
,'SLEEP_SYSTEMTASK','SQLTRACE_BUFFER_FLUSH','WAITFOR', 'LOGMGR_QUEUE','CHECKPOINT_QUEUE'
,'REQUEST_FOR_DEADLOCK_SEARCH','XE_TIMER_EVENT','BROKER_TO_FLUSH','BROKER_TASK_STOP','CLR_MANUAL_EVENT'
,'CLR_AUTO_EVENT','DISPATCHER_QUEUE_SEMAPHORE', 'FT_IFTS_SCHEDULER_IDLE_WAIT'
,'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN',N'QDS_ASYNC_QUEUE',N'XTP_PREEMPTIVE_TASK'))
SELECT W1.wait_type,
CAST(W1.wait_time_s AS DECIMAL(12, 2)) AS wait_time_s,
CAST(W1.pct AS DECIMAL(12, 2)) AS pct,
CAST(SUM(W2.pct) AS DECIMAL(12, 2)) AS running_pct
FROM Waits AS W1
INNER JOIN Waits AS W2
ON W2.rn <= W1.rn
GROUP BY W1.rn, W1.wait_type, W1.wait_time_s, W1.pct
HAVING SUM(W2.pct) - W1.pct < 95; -- percentage threshold


--I/O latch waits
--Identify an I/O problem if your waiting_task_counts and wait_time_ms change significantly from what you see normally.
select wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms, wait_time_ms / waiting_tasks_count
from sys.dm_os_wait_stats  
where wait_type like 'PAGEIOLATCH%'  and waiting_tasks_count > 0
order by wait_type


-- Common Significant I/O Wait types with BOL explanations

-- *** I/O Related Waits ***
-- ASYNC_IO_COMPLETION  Occurs when a task is waiting for I/Os to finish
-- IO_COMPLETION        Occurs while waiting for I/O operations to complete.
--                      This wait type generally represents non-data page I/Os. Data page I/O completion waits appear
--                      as PAGEIOLATCH_* waits
-- PAGEIOLATCH_SH        Occurs when a task is waiting on a latch for a buffer that is in an I/O request.
--                      The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.
-- PAGEIOLATCH_EX        Occurs when a task is waiting on a latch for a buffer that is in an I/O request.
--                      The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.
-- WRITELOG             Occurs while waiting for a log flush to complete.
--                      Common operations that cause log flushes are checkpoints and transaction commits.
-- PAGELATCH_EX            Occurs when a task is waiting on a latch for a buffer that is not in an I/O request.
--                      The latch request is in Exclusive mode.
-- BACKUPIO                Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data 

-- Always look at Avg Disk Sec/Read and Avg Disk Sec/Write in PerfMon for each Physical Disk 

-- Check for IO Bottlenecks (run multiple times, look for values above zero)
SELECT cpu_id, pending_disk_io_count
FROM sys.dm_os_schedulers
WHERE [status] = 'VISIBLE ONLINE';

-- Look at average for all schedulers (run multiple times, look for values above zero)
SELECT AVG(pending_disk_io_count) AS [AvgPendingDiskIOCount]
FROM sys.dm_os_schedulers
WHERE [status] = 'VISIBLE ONLINE';

-- High Latch waits (SH and EX) indicates the I/O subsystem is too busy
-- the wait time indicates time waiting for disk
SELECT wait_type, waiting_tasks_count, wait_time_ms, signal_wait_time_ms,
       wait_time_ms - signal_wait_time_ms AS [io_wait_time_ms]
FROM sys.dm_os_wait_stats
WHERE wait_type IN('PAGEIOLATCH_EX', 'PAGEIOLATCH_SH', 'PAGEIOLATCH_UP')
ORDER BY wait_type;

-- Analyze Database I/O, ranked by IO Stall%
WITH DBIO AS
(SELECT DB_NAME(IVFS.database_id) AS db,
 CASE WHEN MF.type = 1 THEN 'log' ELSE 'data' END AS file_type,
 SUM(IVFS.num_of_bytes_read + IVFS.num_of_bytes_written) AS io,
 SUM(IVFS.io_stall) AS io_stall
 FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS IVFS
 INNER JOIN sys.master_files AS MF
 ON IVFS.database_id = MF.database_id
 AND IVFS.file_id = MF.file_id
 GROUP BY DB_NAME(IVFS.database_id), MF.[type])
SELECT db, file_type,
  CAST(1. * io / (1024 * 1024) AS DECIMAL(12, 2)) AS io_mb,
  CAST(io_stall / 1000. AS DECIMAL(12, 2)) AS io_stall_s,
  CAST(100. * io_stall / SUM(io_stall) OVER()
       AS DECIMAL(10, 2)) AS io_stall_pct,
  ROW_NUMBER() OVER(ORDER BY io_stall DESC) AS rn
FROM DBIO
ORDER BY io_stall DESC;

-- Average stalls per read, write and total
SELECT DB_NAME(database_id) AS [Database Name], file_id, io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0+num_of_reads) AS numeric(10,1)) AS [avg_read_stall_ms],
io_stall_write_ms, num_of_writes,
CAST(io_stall_write_ms/(1.0+num_of_writes) AS numeric(10,1)) AS [avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS io_stalls,
num_of_reads + num_of_writes AS total_io,
CAST((io_stall_read_ms+io_stall_write_ms)/(1.0+num_of_reads + num_of_writes)
AS numeric(10,1)) AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null)
ORDER BY avg_io_stall_ms DESC;

-- Calculates average stalls per read, per write, and per total input/output for each database file.
SELECT DB_NAME(database_id) AS [Database Name], file_id ,io_stall_read_ms, num_of_reads,
CAST(io_stall_read_ms/(1.0 + num_of_reads) AS NUMERIC(10,1)) AS [avg_read_stall_ms],io_stall_write_ms,
num_of_writes,CAST(io_stall_write_ms/(1.0+num_of_writes) AS NUMERIC(10,1)) AS [avg_write_stall_ms],
io_stall_read_ms + io_stall_write_ms AS [io_stalls], num_of_reads + num_of_writes AS [total_io],
CAST((io_stall_read_ms + io_stall_write_ms)/(1.0 + num_of_reads + num_of_writes) AS NUMERIC(10,1))
AS [avg_io_stall_ms]
FROM sys.dm_io_virtual_file_stats(null,null)
ORDER BY avg_io_stall_ms DESC;

-- Which queries are causing the most IO operations (can take a few seconds)
SELECT TOP (20) total_logical_reads/execution_count AS [avg_logical_reads],
    total_logical_writes/execution_count AS [avg_logical_writes],
    total_worker_time/execution_count AS [avg_cpu_cost], execution_count,
    total_worker_time, total_logical_reads, total_logical_writes,
    (SELECT DB_NAME(dbid) + ISNULL('..' + OBJECT_NAME(objectid), '')
     FROM sys.dm_exec_sql_text([sql_handle])) AS query_database,
    (SELECT SUBSTRING(est.[text], statement_start_offset/2 + 1,
        (CASE WHEN statement_end_offset = -1
            THEN LEN(CONVERT(nvarchar(max), est.[text])) * 2
            ELSE statement_end_offset
            END - statement_start_offset
        ) / 2)
        FROM sys.dm_exec_sql_text(sql_handle) AS est) AS query_text,
    last_logical_reads, min_logical_reads, max_logical_reads,
    last_logical_writes, min_logical_writes, max_logical_writes,
    total_physical_reads, last_physical_reads, min_physical_reads, max_physical_reads,
    (total_logical_reads + (total_logical_writes * 5))/execution_count AS io_weighting,
    plan_generation_num, qp.query_plan
FROM sys.dm_exec_query_stats
OUTER APPLY sys.dm_exec_query_plan([plan_handle]) AS qp
WHERE [dbid] >= 5 AND (total_worker_time/execution_count) > 100
ORDER BY io_weighting DESC;

-- Top Cached SPs By Total Physical Reads (SQL 2008). Physical reads relate to disk I/O pressure
SELECT TOP(25) p.name AS [SP Name],
qs.total_physical_reads AS [TotalPhysicalReads], qs.total_physical_reads/qs.execution_count AS [AvgPhysicalReads],
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_logical_reads AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.execution_count,
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_physical_reads DESC;

-- Top Cached SPs By Total Logical Writes (SQL 2008). Logical writes relate to both memory and disk I/O pressure
SELECT TOP(25) p.name AS [SP Name],
qs.total_logical_writes AS [TotalLogicalWrites], qs.total_logical_writes/qs.execution_count AS [AvgLogicalWrites],
ISNULL(qs.execution_count/DATEDIFF(Second, qs.cached_time, GETDATE()), 0) AS [Calls/Second],
qs.total_logical_reads AS [TotalLogicalReads], qs.total_logical_reads/qs.execution_count AS [AvgLogicalReads],
qs.total_worker_time AS [TotalWorkerTime], qs.total_worker_time/qs.execution_count AS [AvgWorkerTime],
qs.execution_count,
qs.total_elapsed_time, qs.total_elapsed_time/qs.execution_count AS [avg_elapsed_time], qs.last_elapsed_time,
qs.cached_time
FROM sys.procedures AS p
INNER JOIN sys.dm_exec_procedure_stats AS qs
ON p.[object_id] = qs.[object_id]
WHERE qs.database_id = DB_ID()
ORDER BY qs.total_logical_writes DESC;

--currently pending I/O requests
--Execute this query periodically to check the health of I/O subsystem and to isolate physical disk(s) that are involved in the I/O bottlenecks.
--returns nothing in normal situation
select 
    database_id, 
    file_id, 
    io_stall,
    io_pending_ms_ticks,
    scheduler_address 
from  sys.dm_io_virtual_file_stats(NULL, NULL)t1,
        sys.dm_io_pending_io_requests as t2
where t1.file_handle = t2.io_handle

--I/O bound queries
select top 5 (total_logical_reads/execution_count) as avg_logical_reads,
                   (total_logical_writes/execution_count) as avg_logical_writes,
           (total_physical_reads/execution_count) as avg_physical_reads,
           Execution_count, statement_start_offset, p.query_plan, q.text
from sys.dm_exec_query_stats
      cross apply sys.dm_exec_query_plan(plan_handle) p
      cross apply sys.dm_exec_sql_text(plan_handle) as q
order by (total_logical_reads + total_logical_writes)/execution_count Desc

--find what batches/requests are generating the most I/O
select top 5 
    (total_logical_reads/execution_count) as avg_logical_reads,
    (total_logical_writes/execution_count) as avg_logical_writes,
    (total_physical_reads/execution_count) as avg_phys_reads,
     Execution_count, 
    statement_start_offset as stmt_start_offset, 
    sql_handle, 
    plan_handle
from sys.dm_exec_query_stats  
order by  (total_logical_reads + total_logical_writes) Desc


--memory
sys.dm_os_sys_info
sys.dm_exec_query_memory_grants
sys.dm_exec_requests
sys.dm_exec_query_plan
sys.dm_exec_sql_text

--check memory configs
sp_configure 'awe_enabled'
go
sp_configure 'min server memory'
go
sp_configure 'max server memory'
go
sp_configure 'min memory per query'
go
sp_configure 'query wait'
go

--see cpu, scheduler memory and buffer pool information
select 
cpu_count,
hyperthread_ratio,
scheduler_count,
physical_memory_in_bytes / 1024 / 1024 as physical_memory_mb,
virtual_memory_in_bytes / 1024 / 1024 as virtual_memory_mb,
bpool_committed * 8 / 1024 as bpool_committed_mb,
bpool_commit_target * 8 / 1024 as bpool_target_mb,
bpool_visible * 8 / 1024 as bpool_visible_mb
from sys.dm_os_sys_info


--?
select 
	type,
	sum(virtual_memory_reserved_kb) as [VM Reserved],
	sum(virtual_memory_committed_kb) as [VM Committed],
	sum(awe_allocated_kb) as [AWE Allocated],
	sum(shared_memory_reserved_kb) as [SM Reserved], 
	sum(shared_memory_committed_kb) as [SM Committed],
	sum(multi_pages_kb) as [MultiPage Allocator],
	sum(single_pages_kb) as [SinlgePage Allocator]
from sys.dm_os_memory_clerks 
group by type
order by 8 desc



--Internal memory distribution
dbcc memorystatus

--To find out how much memory has been allocated through AWE mechanism

SELECT Sum(awe_allocated_kb)/1024 as ‘AWE allocated, MB’
FROM sys.dm_os_memory_clerks

--amount of mem allocated though multipage allocator interface

select sum(multi_pages_kb) /1024 as ‘MultiPage allocated, MB’
from sys.dm_os_memory_clerks
--broken down in Detail
select type, sum(multi_pages_kb)/1024 as ‘MultiPage allocated, MB’
from sys.dm_os_memory_clerks
where multi_pages_kb != 0
group by type

--amount of memory consumed by components outside the Buffer pool
select
  sum(multi_pages_kb + virtual_memory_committed_kb + shared_memory_committed_kb)/1024 as [Overall used w/o BPool, MB]
from sys.dm_os_memory_clerks
where type <> ‘MEMORYCLERK_SQLBUFFERPOOL’

--amount of memory consumed by BPool
--note that currenlty only BPool uses AWE
select
  sum(multi_pages_kb
  + virtual_memory_committed_kb
  + shared_memory_committed_kb
  + awe_allocated_kb)/1024 as [Used by BPool with AWE, MB]
from sys.dm_os_memory_clerks
where type = ‘MEMORYCLERK_SQLBUFFERPOOL’

--top 10 consumers of memory from BPool
select top 10 type, sum(single_pages_kb)/1024 as [SPA Mem, MB]
from sys.dm_os_memory_clerks
group by type
order by sum(single_pages_kb) desc

--Info about clock hand movements – Increasing rounds count indicate memory pressure

select *
from
  sys.dm_os_memory_cache_clock_hands
where
  rounds_count > 0
  and removed_all_rounds_count > 0

--Detailed
  select
  distinct cc.cache_address,
  cc.name,
  cc.type,
  cc.single_pages_kb + cc.multi_pages_kb as total_kb,
  cc.single_pages_in_use_kb + cc.multi_pages_in_use_kb as total_in_use_kb,
  cc.entries_count,
  cc.entries_in_use_count,
  ch.removed_all_rounds_count,
  ch.removed_last_round_count
from
  sys.dm_os_memory_cache_counters cc
  join sys.dm_os_memory_cache_clock_hands ch on (cc.cache_address = ch.cache_address)
order by total_kb desc



--memory consumption by database
SELECT
    DB_NAME(database_id) AS [Database Name],
    COUNT(*) * 8/1024.0 AS [Buffer Size (MB)]
--select *
FROM sys.dm_os_buffer_descriptors
WHERE (database_id > 4) AND (database_id <> 32767)
GROUP BY DB_NAME(database_id)
ORDER BY 2 DESC


--memory usage by object for specified db
declare @dbname varchar(50)
set @dbname = 'ReportingUS5'

SELECT
    OBJECT_NAME(t3.object_id) AS 'ObjectName',
    t3.object_id,
    COUNT(*) * 8/1024.0 AS '[Buffer Size (MB)]',
    COUNT(*) AS 'buffer_count'
FROM sys.allocation_units t1
INNER JOIN sys.dm_os_buffer_descriptors t2 ON (t1.allocation_unit_id = t2.allocation_unit_id)
INNER JOIN sys.partitions t3 ON (t1.container_id = t3.hobt_id)
INNER JOIN sys.objects t4 ON (t3.object_id = t4.object_id)
WHERE (t2.database_id = db_id(@dbname)) 
  AND (t4.type = 'U')
GROUP BY t3.object_id
ORDER BY 3 DESC;



--os
select * from sys.dm_os_wait_stats (nolock)
select * from sys.dm_os_threads (nolock)


--page latch
--show page latch and is it is on allocation page
--can be expensive for dbs with lots of pages in buffer pool
--resource description in form <database ID>:<file ID>:<page number>
SELECT session_id,
wait_type,
wait_duration_ms,
blocking_session_id,
resource_description,
ResourceType = CASE
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 1 % 8088 = 0 THEN 'Is PFS Page'
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 2 % 511232 = 0 THEN 'Is GAM Page'
                WHEN Cast(RIGHT(resource_description, Len(resource_description) - Charindex(':', resource_description, LEN(resource_description)-CHARINDEX(':', REVERSE(resource_description), 1))) AS NVARCHAR) - 3 % 511232 = 0 THEN 'Is SGAM Page'
                ELSE 'Is Not PFS, GAM, or SGAM page'
              END
FROM sys.dm_os_waiting_tasks
WHERE wait_type LIKE 'PAGE%LATCH_%'
AND resource_description LIKE '2:%' 



--query stats

select  
  st.dbid,
  st.[text] as Batch_Object, 
  substring(st.[text], (qs.statement_start_offset/2) + 1, 
  ((case qs.statement_end_offset 
    when -1 then datalength(st.[text]) else qs.statement_end_offset end 
    - qs.statement_start_offset)/2) + 1) as SQL_Statement,
  qp.query_plan,
  qs.execution_count,
  qs.total_physical_reads, 
  (qs.total_physical_reads / qs.execution_count) as average_physical_reads, 
  qs.total_logical_writes, 
  (qs.total_logical_writes / qs.execution_count) as average_logical_writes, 
  qs.total_logical_reads, 
  (qs.total_logical_reads / qs.execution_count) as average_logical_lReads, 
  qs.total_clr_time, 
  (qs.total_clr_time / qs.execution_count) as average_CLRTime, 
  qs.total_elapsed_time, 
  (qs.total_elapsed_time / qs.execution_count) as average_elapsed_time, 
  qs.last_execution_time, 
  qs.creation_time  
from sys.dm_exec_query_stats as qs 
       CROSS apply sys.dm_exec_sql_text(qs.sql_handle) as st 
       CROSS apply sys.dm_exec_query_plan(qs.plan_handle) as qp 
where  qs.last_execution_time > dateadd(hh,-2,getdate())  
  and (st.dbid = (select db_id('eSmart')) or st.dbid is null)
  --and (substring(st.[text], (qs.statement_start_offset/2) + 1, 
  --((case qs.statement_end_offset 
  --  when -1 then datalength(st.[text]) else qs.statement_end_offset end 
  --  - qs.statement_start_offset)/2) + 1)) like '%datUsers%' 
order by execution_count desc 



--slow reads by file
--sample_ms: num of ms since computer was started
--num_of_reads: num of reads issued on the file
--num_of_bytes_read: total num of bytes read on the file
--io_stall_read_ms: total time in ms that users waited for writes to be completed on the file
--num_of_writes: num of writes made on the file
--num_of_bytes_written: total number of bytes written to the file
--io_stall_write_ms: total time in ms that users waited for writes to be completed on the file
--io_stall: total time in ms that users waited for I/O to be completed on the file
--size_on_disk_bytes: num of bytes used on the disk for this file

--reads averaging longer than 50ms
select 
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(NULL, NULL)
where (io_stall_read_ms/(1.0+num_of_reads)) > 50


--writes averaging longer than 20ms
select
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(NULL, NULL)
where (io_stall_write_ms/(1.0+num_of_writes)) > 20

--look at all file stats
select 
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(NULL, NULL)

--look at all file stats for specified db
--select * from sys.database_files
select 
  @@servername as server,
  getdate() as QueryDate,
  (select sqlserver_start_time from sys.dm_os_sys_info) as ServerStartTime,
  db_name(database_id),
  cast((io_stall_read_ms/(1.0+num_of_reads)) as int) as avg_read_ms, 
  cast((io_stall_write_ms/(1.0+num_of_writes)) as int) as avg_write_ms, 
  *
from sys.dm_io_virtual_file_stats(2, NULL)


--sp_server_diagnostics
USE tempdb 

--drop TABLE dbo.tmp_sp_server_diagnostics 
CREATE TABLE dbo.tmp_sp_server_diagnostics 
               ([create_time] datetime, 
                [component_type] nvarchar(50), 
                [component_name] nvarchar(20), 
				[state] int, 
                [state_desc] nvarchar(20), 
                [data] xml) 

INSERT dbo.tmp_sp_server_diagnostics 

EXEC sys.sp_server_diagnostics 

SELECT create_time, component_name, state, state_desc, data 
FROM dbo.tmp_sp_server_diagnostics 



--statistics
--How are statistics created?
--Statistics are automatically created for each index key you create.
--If the database setting autocreate stats is on, then SQL Server will automatically create statistics for non-indexed columns that are used in queries.
--Or you can manually create statistics
	CREATE STATISTICS <stat_name>
	ON <table_name>(<column_name>)
	WITH FULLSCAN;

--How can I see what statistics look like?
 --- through ssms
 --- tsql
	DBCC SHOW_STATISTICS('mapDevice2SoftwareProducts','IDX_DeviceSoftwareProducts_ITAssetObjectID')
	WITH HISTOGRAM

--How are statistics updated?
The default settings in SQL Server are to autocreate and autoupdate statistics.
	Auto Update Statistics basically means, if there is an incoming query but statistics are stale, SQL Server will update statistics first before it generates an execution plan.
	Auto Update Statistics Asynchronously on the other hand means, if there is an incoming query but statistics are stale, SQL Server uses the stale statistics to generate the execution plan, then updates the statistics afterwards.
Manually update statistics, you can use either 
	sp_updatestats or 
	UPDATE STATISTICS <statistics name>

--How do we know statistics are being used?
One good check you can do is when you generate execution plans for your queries:
	check out your “Actual Number of Rows” and “Estimated Number of Rows”. 
If these numbers are (consistently) fairly close, then most likely your statistics are up-to-date and used by the optimizer for the query. If not, time for you to re-check your statistics create/update frequency.


--When are statistics updated?
If the table has no rows, statistics is updated when there is a single change in table.
If the number of rows in a table is less than 500, statistics is updated for every 500 changes in table.
If the number of rows in table is more than 500, statistics is updated for every 500+20% of rows changes in table.




--sites to read more
http://msdn.microsoft.com/en-us/library/dd535534.aspx
http://sqlblog.com/blogs/elisabeth_redei/archive/2009/03/01/lies-damned-lies-and-statistics-part-i.aspx
http://sqlblog.com/blogs/elisabeth_redei/archive/2009/08/10/lies-damned-lies-and-statistics-part-ii.aspx
http://sqlblog.com/blogs/elisabeth_redei/archive/2009/12/17/lies-damned-lies-and-statistics-part-iii-sql-server-2008.aspx


--statistics trace flag 2371
/* The sysindexes.rowmodctr column maintains a running total of all modifications to a table that, over time, can adversely affect the query 
processor's decision making process. This counter is updated each time any of the following events occurs:
 * A single row insert is made
 * A single row delete is made
 * An update to an indexed column is made
 * TRUNCATE TABLE does not update rowmodctr

The basic algorithm for auto update statistics is:
 * If the cardinality for a table is less than six and the table is in the tempdb database, auto update with every six modifications to the table. 
 * If the cardinality for a table is greater than 6, but less than or equal to 500, update status every 500 modifications. 
 * If the cardinality for a table is greater than 500, update statistics when (500 + 20 percent of the table) changes have occurred. 
 * For table variables, cardinality changes do not trigger auto update statistics. 

Trace flag 2371 enabled:
  * The higher the number of rows in a table, the lower the threshold will become to trigger an update of the statistics.

Returns properties of statistics for the specified database object (2008 R2 SP2 and 2012 SP1)
SELECT
    sp.stats_id, name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter 
FROM sys.stats AS stat 
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
WHERE stat.object_id = object_id('mapITAsset2ExecutablesUsage');

SELECT DISTINCT
	tablename=object_name(i.object_id)
	, o.type_desc
	,index_name=i.[name]
    , statistics_update_date = STATS_DATE(i.object_id, i.index_id)
	, si.rowmodctr
FROM sys.indexes i (nolock)
JOIN sys.objects o (nolock) on
	i.object_id=o.object_id
JOIN sys.sysindexes si (nolock) on
	i.object_id=si.id
	and i.index_id=si.indid
where
	o.type != 'S'  --ignore system objects
	and STATS_DATE(i.object_id, i.index_id) is not null
order by si.rowmodctr desc


--waits
--SQL waits analysis and top 10 resources waited on
select top 10 *
from sys.dm_os_wait_stats
--where wait_type not in ('CLR_SEMAPHORE','LAZYWRITER_SLEEP','RESOURCE_QUEUE','SLEEP_TASK','SLEEP_SYSTEMTASK','WAITFOR')
order by wait_time_ms desc














