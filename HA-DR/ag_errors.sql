

--READ AG EVENT LOG
declare @t1 table ([Timestamp] datetime, PreviousState varchar(200), CurrentState varchar(200), ErrorNum int, Message varchar(max))
insert into @t1
select 
  dateadd(mi,datediff(mi,getutcdate(), getdate()),cast(event_data as xml).value('(/event/@timestamp)[1]','datetime')) AS [timestamp],
  cast(event_data as xml).value ('(/event/data[@name=''previous_state'']/text)[1]', 'varchar(200)') as PreviousStateText,
  cast(event_data as xml).value ('(/event/data[@name=''current_state'']/text)[1]', 'varchar(200)') as CurrentStateText,
  cast(event_data as xml).value('(/event/data[@name=''error_number''])[1]','int') AS [error_number],
  cast(event_data as xml).value('(/event/data[@name=''message''])[1]','varchar(max)') AS [message]
FROM sys.fn_xe_file_target_read_file('C:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)

select 
  cast([Timestamp] as date) as [Date],
  datepart(hour,[Timestamp]) as [Hour],
  datepart(minute,[Timestamp]) as [Minute],
  ErrorNum,
  count(1)
from @t1
--where ErrorNum in (1480,35201,35206)
  --and Message like '%MemberIdentity%'
  --and [Timestamp] >= dateadd(mi,-10,getdate())
group by
  cast([Timestamp] as date),
  datepart(hour,[Timestamp]),
  datepart(minute,[Timestamp]),
  ErrorNum
order by 1,2,3    

