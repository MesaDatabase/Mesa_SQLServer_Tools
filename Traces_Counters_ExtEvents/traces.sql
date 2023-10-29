--trace tables
select * from msdb.sys.traces
select * from msdb.sys.trace_events
select * from msdb.sys.trace_columns
select * from msdb.sys.trace_categories
select * from msdb.sys.trace_event_bindings
select * from msdb.sys.trace_subclass_values

--trace configurations
select * from msdb.sys.fn_trace_getinfo(1)
--sql 2000
select * from :: fn_trace_getinfo(default)
----1= Trace options 2 = TRACE_FILE_ROLLOVER
----2 = File name 
----3 = Max size MB
----4 = Stop time 
----5 = Current trace status. 0 = stopped. 1 = running

--stop trace
sp_trace_setstatus @traceid = 2 , @status = 0

--delete trace from server
sp_trace_setstatus @traceid = 2 , @status = 2

--all events and columns
select * from msdb.sys.fn_trace_geteventinfo(1) a 
  join msdb.sys.trace_events b on a.eventid = b.trace_event_id
  join msdb.sys.trace_columns c on a.columnid = c.trace_column_id
order by b.name, c.name

--unique events
select distinct b.trace_event_id, b.name from msdb.sys.fn_trace_geteventinfo(1) a 
  join msdb.sys.trace_events b on a.eventid = b.trace_event_id
order by name

--filters
select * from msdb.sys.fn_trace_getfilterinfo(1)

--returns content of specified trace file as a table
select * from msdb.sys.fn_trace_gettable('D:\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_54.trc', default)

--turns on trace flag for session
DBCC TRACEON (3023)

--turns on trace flag globally
DBCC TRACEON (3023,-1)

--turns off trace flag for session
DBCC TRACEOFF (3023)

--turns off trace flag globally
DBCC TRACEOFF (3023,-1)

--shows enabled trace flags for current session
DBCC TRACESTATUS()

--shows enabled trace flags
DBCC TRACESTATUS

--shows enabled trace flags for specified trace
DBCC TRACESTATUS(1)

--shows enabled trace flags for specified event
DBCC TRACESTATUS(3023) 

 --default trace
declare @trc_file varchar(255)
--set @trc_file = cast((select value from ::fn_trace_getinfo(1) where property=2) as varchar(255))
set @trc_file = 'D:\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_65.trc'
--select @trc_file

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
--select distinct te.trace_event_id, te.name
from fn_trace_gettable(@trc_file, default) e
  join sys.trace_events te on e.eventclass=te.trace_event_id
where 1=1
  and e.starttime >= '2012-08-15 00:00'
  and textdata like '%Missing%'
    --and e.starttime < '2012-08-15 00:00'
  --and databasename like 'Inventory%'
  --and e.eventclass=46 --object created
  --and e.eventclass=47 --object deleted
  --and e.eventclass=22 --error log
  --and e.eventclass=20 --login failures
    --and e.eventclass=93 --log file autogrowth
    --and e.eventclass=92 --data file autogrowth
    --and e.eventclass=25 --deadlock
order by e.starttime desc