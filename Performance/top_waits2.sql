


WITH Waits AS
    (SELECT
        wait_type,
        wait_time_ms / 1000.0 AS WaitS,
        (wait_time_ms - signal_wait_time_ms) / 1000.0 AS ResourceS,
        signal_wait_time_ms / 1000.0 AS SignalS,
        waiting_tasks_count AS WaitCount,
        100.0 * wait_time_ms / SUM (wait_time_ms) OVER() AS WaitPercentage,
		case when wait_time_ms = 0 then 0 else (100.0 * signal_wait_time_ms / wait_time_ms) end as CPUWaitPercentage,
        ROW_NUMBER() OVER(ORDER BY wait_time_ms DESC) AS RowNum
    FROM sys.dm_os_wait_stats
    WHERE wait_type NOT IN (
        'CLR_SEMAPHORE', 'LAZYWRITER_SLEEP', 'RESOURCE_QUEUE', 'SLEEP_TASK',
        'SLEEP_SYSTEMTASK', 'SQLTRACE_BUFFER_FLUSH', 'WAITFOR', 'LOGMGR_QUEUE',
        'CHECKPOINT_QUEUE', 'REQUEST_FOR_DEADLOCK_SEARCH', 'XE_TIMER_EVENT', 'BROKER_TO_FLUSH',
        'BROKER_TASK_STOP', 'CLR_MANUAL_EVENT', 'CLR_AUTO_EVENT', 'DISPATCHER_QUEUE_SEMAPHORE',
        'FT_IFTS_SCHEDULER_IDLE_WAIT', 'XE_DISPATCHER_WAIT', 'XE_DISPATCHER_JOIN', 'BROKER_EVENTHANDLER',
        'TRACEWRITE', 'FT_IFTSHC_MUTEX', 'SQLTRACE_INCREMENTAL_FLUSH_SLEEP')
     )
SELECT
     W1.wait_type AS WaitType, 
     CAST (W1.WaitS AS DECIMAL(14, 2)) AS Wait_S,
     CAST (W1.ResourceS AS DECIMAL(14, 2)) AS Resource_S,
     CAST (W1.SignalS AS DECIMAL(14, 2)) AS Signal_S,
     W1.WaitCount AS WaitCount,
     CAST (W1.WaitPercentage AS DECIMAL(4, 2)) AS WaitPercentage,
     CAST (W1.CPUWaitPercentage AS DECIMAL(14, 2)) AS CPUWaitPercentage
FROM Waits AS W1
INNER JOIN Waits AS W2
     ON W2.RowNum <= W1.RowNum
GROUP BY W1.RowNum, W1.wait_type, W1.WaitS, W1.ResourceS, W1.SignalS, W1.WaitCount, W1.WaitPercentage, W1.CPUWaitPercentage
HAVING SUM (W2.WaitPercentage) - W1.WaitPercentage < 95; -- percentage threshold
GO




