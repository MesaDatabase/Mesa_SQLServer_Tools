

--top wait events excluding expected system waits
SELECT TOP 10
wait_type ,
max_wait_time_ms wait_time_ms ,
signal_wait_time_ms ,
wait_time_ms - signal_wait_time_ms AS resource_wait_time_ms ,
100.0 * wait_time_ms / SUM(wait_time_ms) OVER ( )
AS percent_total_waits ,
100.0 * signal_wait_time_ms / SUM(signal_wait_time_ms) OVER ( )
AS percent_total_signal_waits ,
100.0 * ( wait_time_ms - signal_wait_time_ms )
/ SUM(wait_time_ms) OVER ( ) AS percent_total_resource_waits
FROM sys.dm_os_wait_stats
WHERE wait_time_ms > 0 -- remove zero wait_time
AND wait_type NOT IN -- filter out additional irrelevant waits
( 'SLEEP_TASK', 'BROKER_TASK_STOP', 'BROKER_TO_FLUSH',
'SQLTRACE_BUFFER_FLUSH','CLR_AUTO_EVENT', 'CLR_MANUAL_EVENT',
'LAZYWRITER_SLEEP', 'SLEEP_SYSTEMTASK', 'SLEEP_BPOOL_FLUSH',
'BROKER_EVENTHANDLER', 'XE_DISPATCHER_WAIT', 'FT_IFTSHC_MUTEX',
'CHECKPOINT_QUEUE', 'FT_IFTS_SCHEDULER_IDLE_WAIT',
'BROKER_TRANSMITTER', 'FT_IFTSHC_MUTEX', 'KSOURCE_WAKEUP',
'LOGMGR_QUEUE', 'ONDEMAND_TASK_QUEUE',
'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BAD_PAGE_PROCESS',
'DBMIRROR_EVENTS_QUEUE', 'BROKER_RECEIVE_WAITFOR',
'PREEMPTIVE_OS_GETPROCADDRESS', 'PREEMPTIVE_OS_AUTHENTICATIONOPS',
'WAITFOR', 'DISPATCHER_QUEUE_SEMAPHORE', 'XE_DISPATCHER_JOIN',
'RESOURCE_QUEUE' )
ORDER BY wait_time_ms DESC


--virtual file stats
SELECT DB_NAME(vfs.database_id) AS database_name ,
vfs.database_id ,
vfs.FILE_ID ,
io_stall_read_ms / NULLIF(num_of_reads, 0) AS avg_read_latency ,
io_stall_write_ms / NULLIF(num_of_writes, 0)
AS avg_write_latency ,
io_stall / NULLIF(num_of_reads + num_of_writes, 0)
AS avg_total_latency ,
num_of_bytes_read / NULLIF(num_of_reads, 0)
AS avg_bytes_per_read ,
num_of_bytes_written / NULLIF(num_of_writes, 0)
AS avg_bytes_per_write ,
vfs.io_stall ,
vfs.num_of_reads ,
vfs.num_of_bytes_read ,
vfs.io_stall_read_ms ,
vfs.num_of_writes ,
vfs.num_of_bytes_written ,
vfs.io_stall_write_ms ,
size_on_disk_bytes / 1024 / 1024. AS size_on_disk_mbytes ,
physical_name
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
JOIN sys.master_files AS mf ON vfs.database_id = mf.database_id
AND vfs.FILE_ID = mf.FILE_ID
ORDER BY avg_total_latency DESC


--perfmon counters
DECLARE @CounterPrefix NVARCHAR(30)
SET @CounterPrefix = CASE WHEN @@SERVICENAME = 'MSSQLSERVER'
THEN 'SQLServer:'
ELSE 'MSSQL$' + @@SERVICENAME + ':'
END ;
-- Capture the first counter set
SELECT CAST(1 AS INT) AS collection_instance ,
[OBJECT_NAME] ,
counter_name ,
instance_name ,
cntr_value ,
cntr_type ,
CURRENT_TIMESTAMP AS collection_time
INTO #perf_counters_init
FROM sys.dm_os_performance_counters
WHERE ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
AND counter_name = 'Full Scans/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
AND counter_name = 'Index Searches/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
AND counter_name = 'Lazy Writes/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
AND counter_name = 'Page life expectancy'
)
OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
AND counter_name = 'Processes Blocked'
)
OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
AND counter_name = 'User Connections'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
AND counter_name = 'Lock Waits/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
AND counter_name = 'Lock Wait Time (ms)'
)
OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
AND counter_name = 'SQL Re-Compilations/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Memory Manager'
AND counter_name = 'Memory Grants Pending'
)
OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
AND counter_name = 'Batch Requests/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
AND counter_name = 'SQL Compilations/sec'
)
-- Wait on Second between data collection
WAITFOR DELAY '00:00:01'
-- Capture the second counter set
SELECT CAST(2 AS INT) AS collection_instance ,
OBJECT_NAME ,
counter_name ,
instance_name ,
cntr_value ,
cntr_type ,
CURRENT_TIMESTAMP AS collection_time
INTO #perf_counters_second
FROM sys.dm_os_performance_counters
WHERE ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
AND counter_name = 'Full Scans/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Access Methods'
AND counter_name = 'Index Searches/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
AND counter_name = 'Lazy Writes/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Buffer Manager'
AND counter_name = 'Page life expectancy'
)
OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
AND counter_name = 'Processes Blocked'
)
OR ( OBJECT_NAME = @CounterPrefix + 'General Statistics'
AND counter_name = 'User Connections'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
AND counter_name = 'Lock Waits/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Locks'
AND counter_name = 'Lock Wait Time (ms)'
)
OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
AND counter_name = 'SQL Re-Compilations/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'Memory Manager'
AND counter_name = 'Memory Grants Pending'
)
OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
AND counter_name = 'Batch Requests/sec'
)
OR ( OBJECT_NAME = @CounterPrefix + 'SQL Statistics'
AND counter_name = 'SQL Compilations/sec'
)
-- Calculate the cumulative counter values
SELECT i.OBJECT_NAME ,
i.counter_name ,
i.instance_name ,
CASE WHEN i.cntr_type = 272696576
THEN s.cntr_value - i.cntr_value
WHEN i.cntr_type = 65792 THEN s.cntr_value
END AS cntr_value
FROM #perf_counters_init AS i
JOIN #perf_counters_second AS s
ON i.collection_instance + 1 = s.collection_instance
AND i.OBJECT_NAME = s.OBJECT_NAME
AND i.counter_name = s.counter_name
AND i.instance_name = s.instance_name
ORDER BY OBJECT_NAME
-- Cleanup tables
DROP TABLE #perf_counters_init
DROP TABLE #perf_counters_second


--execution statistics
SELECT TOP 10
execution_count ,
statement_start_offset AS stmt_start_offset ,
sql_handle ,
plan_handle ,
total_logical_reads / execution_count AS avg_logical_reads ,
total_logical_writes / execution_count AS avg_logical_writes ,
total_physical_reads / execution_count AS avg_physical_reads ,
t.text
FROM sys.dm_exec_query_stats AS s
CROSS APPLY sys.dm_exec_sql_text(s.sql_handle) AS t
ORDER BY avg_physical_reads DESC


