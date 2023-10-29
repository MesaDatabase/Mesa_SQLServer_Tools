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



