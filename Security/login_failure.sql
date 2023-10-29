set nocount on

declare @trc_file varchar(255)
set @trc_file = cast((select value from ::fn_trace_getinfo(1) where property=2) as varchar(255))

select 
  @@servername,
  te.name as [event],
  te.trace_event_id,
  e.textdata, 
  e.applicationname, 
  e.objectid,
  convert (varchar(20), object_name(e.objectid)) as object, 
  e.spid, 
  e.duration/1000 as [duration (ms)], 
  e.starttime, 
  e.endtime, 
  e.databasename, 
  e.filename, 
  e.loginname, 
  e.hostname, 
  e.clientprocessid
--select top 10 *
from fn_trace_gettable(@trc_file, default) e
  join sys.trace_events te on e.eventclass=te.trace_event_id
where 1=1
  and e.eventclass=20 --login failures
  --and databasename = 'tempdb'
  --and ISNULL(convert (varchar(20), object_name(e.objectid)),'') != ''
  --and e.starttime >= GETDATE() - 3
  --and applicationname = 'Listener'
  --and applicationname != 'Report Server'
  --and hostname like '%S3B%'
order by e.starttime

/*
sp_configure 'default trace enabled'

select * from sys.traces where is_default = 1
*/