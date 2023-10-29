--get AlwaysOn extended event file location
declare @agFileLoc varchar(500)
select 
  @agFileLoc = replace(master.dbo.fSplit('AlwaysOn',master.dbo.fSplit('=',t.target_data,5),1),'"','') + 'AlwaysOn*.xel'
from sys.dm_xe_sessions as s
  join sys.dm_xe_session_targets as t on s.address = t.event_session_address
where s.name = 'AlwaysOn_health'
  and t.target_name = 'event_file'

declare @t1 table ([Timestamp] datetime, PreviousState varchar(200), CurrentState varchar(200), ErrorNum int, Message varchar(max))
insert into @t1
select 
  dateadd(mi,datediff(mi,getutcdate(), getdate()),cast(event_data as xml).value('(/event/@timestamp)[1]','datetime')) AS [timestamp],
  cast(event_data as xml).value ('(/event/data[@name=''previous_state'']/text)[1]', 'varchar(200)') as PreviousStateText,
  cast(event_data as xml).value ('(/event/data[@name=''current_state'']/text)[1]', 'varchar(200)') as CurrentStateText,
  cast(event_data as xml).value('(/event/data[@name=''error_number''])[1]','int') AS [error_number],
  cast(event_data as xml).value('(/event/data[@name=''message''])[1]','varchar(max)') AS [message]
  --select top 10 event_data
FROM sys.fn_xe_file_target_read_file(@agFileLoc, null, null, null)

--select
--  @@servername as ServerName,ErrorNum,
--  cast(Timestamp as date) as [Date], datepart(hour,Timestamp) as [Hour], datepart(minute,Timestamp) as [Minute]
select *
from @t1
where ErrorNum is not null
  and ((ErrorNum = 1480 and Message like '%"PRIMARY" to "RESOLVING"%')
     or ErrorNum = 41049)
  --and Message like '%SSISDB%'
  --and [Timestamp] >= dateadd(day,-10,getdate())
--group by ErrorNum, cast(Timestamp as date), datepart(hour,Timestamp), datepart(minute,Timestamp)
--order by 3,4,5
order by [Timestamp] desc
