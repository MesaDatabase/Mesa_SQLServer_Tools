declare @t1 table ([Timestamp] datetime, PreviousState varchar(200), CurrentState varchar(200), ErrorNum int, Message varchar(max))
insert into @t1
select 
  dateadd(mi,datediff(mi,getutcdate(), getdate()),cast(event_data as xml).value('(/event/@timestamp)[1]','datetime')) AS [timestamp],
  cast(event_data as xml).value ('(/event/data[@name=''previous_state'']/text)[1]', 'varchar(200)') as PreviousStateText,
  cast(event_data as xml).value ('(/event/data[@name=''current_state'']/text)[1]', 'varchar(200)') as CurrentStateText,
  cast(event_data as xml).value('(/event/data[@name=''error_number''])[1]','int') AS [error_number],
  cast(event_data as xml).value('(/event/data[@name=''message''])[1]','varchar(max)') AS [message]
FROM sys.fn_xe_file_target_read_file('D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)

--declare @i int
--select @i = count(1) 
select *
from @t1
where ErrorNum = 1480
  --and Message like '%SSISDB%'
  and [Timestamp] >= dateadd(dd,-10,getdate())
  