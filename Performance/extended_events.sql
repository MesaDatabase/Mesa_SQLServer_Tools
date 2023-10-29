select * from [System.Activities.DurableInstancing].[InstancesTable]

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
        WHERE s.name = 'AF_PERSISTENCE_SQL_TRACE' 
          AND t.target_name = 'ring_buffer' 
    ) AS sub 
    CROSS APPLY target_data.nodes('RingBufferTarget/event') AS q(n) 
) AS tab 

select * from @temp t1
where txt like '%InstancesTable%'


select * from sys.server_event_sessions --65553
select * from sys.server_event_session_actions where event_session_id = 65553
select * from sys.server_event_session_events  where event_session_id = 65553
select * from sys.server_event_session_fields  where event_session_id = 65553 --none

select * from sys.dm_xe_sessions


