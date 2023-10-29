/***********************************************************
-- Description  : Get SSIS execution error messages
-- Notes	: Only works for SSISDB catalog
-- Modified	: 20190415
***********************************************************/

USE SSISDB

DECLARE @start datetime
DECLARE @end datetime

--SET @start = dateadd(minute,-60,getdate())
--SET @end = getdate()

--utc
SET @start = dateadd(minute,-60,getutcdate())
SET @end = getutcdate()

select @start, @end

SELECT
  ex.execution_id,
  CASE WHEN LEN(ex.executable_name) <= 1024 THEN ex.executable_name ELSE LEFT(ex.executable_name, 1024) + '...' END AS executable_name,
  CASE WHEN LEN(es.execution_path) <= 1024 THEN es.execution_path ELSE LEFT(es.execution_path, 1024) + '...' END AS execution_path,
  ex.package_name,
 CONVERT(FLOAT,es.execution_duration)/1000 AS execution_duration_sec,  
  es.execution_result,
  es.start_time,
  es.end_time,
  m.message,
  m.message_time,
  m.message_type
--select *
FROM catalog.executable_statistics AS es
  LEFT JOIN catalog.executables AS ex ON es.execution_id = ex.execution_id AND es.executable_id = ex.executable_id
  LEFT JOIN catalog.executions as e ON ex.execution_id  = e.execution_id
  LEFT JOIN catalog.event_messages as m ON ex.execution_id  = m.operation_id and ex.package_name = m.package_name and ex.executable_name = m.message_source_name
WHERE 1=1
  AND es.execution_result <> 0 -- 0=success / 1=failure / 2=completion / 3=cancelled
  AND e.start_time >= @start
  AND e.start_time < @end
  and m.message_type = 120
  --and ex.execution_id = 734101
  --and executable_name = 'Load Accounts to Staging'
ORDER BY es.start_time desc