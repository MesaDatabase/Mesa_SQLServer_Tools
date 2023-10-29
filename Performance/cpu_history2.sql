
/***************************************************************************************************************
Description: This script will display CPU usage on the server.  The data comes from 
	dm_os_ring_buffers which only stored data for the past 4 HOURS.  Within the ring buffers, data is averaged 
	at the minute level.  There are variables limit the results to a smaller time window and for hiding the 
	details.

Sources:
	http://www.sqlservercentral.com/Forums/Topic611107-146-2.aspx
	http://social.msdn.microsoft.com/Forums/en-US/sqldatabaseengine/thread/abbf67ab-fc8b-4567-b6d4-1c605bc9866c/
***************************************************************************************************************/

/* Variables */
DECLARE 
	@StartTime DATETIME = '01/01/1900 00:00:00'
	,@EndTime DATETIME = '01/01/2100 23:59:59'
	,@ShowDetails BIT = 1 -- 1 = True, 0 = False




/* Script Begin */
/* Be careful modifying anything below */


-- Find the timestamp for current server time
DECLARE @ts_now BIGINT
SELECT @ts_now = cpu_ticks / (cpu_ticks / ms_ticks)
FROM sys.dm_os_sys_info;

DECLARE @Results TABLE
	(record_ID BIGINT NOT NULL
	,EventTime datetime NOT NULL
	,SQLProcessUtilization tinyint NOT NULL
	,SystemIdle tinyint NOT NULL
	,OtherProcessUtilization tinyint NOT NULL
  )  

INSERT INTO 
	@Results
(	
	record_ID
	,EventTime
	,SQLProcessUtilization
	,SystemIdle
	,OtherProcessUtilization
)  
SELECT
    record_id
   ,DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) AS EventTime
   ,SQLProcessUtilization
   ,SystemIdle
   ,100 - SystemIdle - SQLProcessUtilization AS OtherProcessUtilization
FROM
    (
     SELECT
        record.value('(./Record/@id)[1]', 'int') AS record_id
       ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/SystemIdle)[1]',
                     'int') AS SystemIdle
       ,record.value('(./Record/SchedulerMonitorEvent/SystemHealth/ProcessUtilization)[1]',
                     'int') AS SQLProcessUtilization
       ,TIMESTAMP
     FROM
        (
         SELECT
            TIMESTAMP
           ,CONVERT(XML, record) AS record
         FROM
            sys.dm_os_ring_buffers
         WHERE
            ring_buffer_type = N'RING_BUFFER_SCHEDULER_MONITOR'
            AND record LIKE '% %'
			AND DATEADD(ms, -1 * (@ts_now - [timestamp]), GETDATE()) BETWEEN @StartTime AND @EndTime
        ) AS x
    ) AS y


--Return details
IF @ShowDetails = 1
BEGIN
	SELECT     
		record_ID
	   ,EventTime
	   ,SQLProcessUtilization
	   ,SystemIdle
	   ,OtherProcessUtilization
	FROM @Results
	order by 2 desc
END


--Return average
SELECT
	AVG(SQLProcessUtilization)
	,MIN(EVENTTIME) StartTime
	,MAX(EVENTTIME) EndTime
FROM
	@Results		

