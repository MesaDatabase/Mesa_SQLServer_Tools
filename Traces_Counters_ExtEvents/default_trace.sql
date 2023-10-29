select 
  @@servername,
  te.name as [event],
  v.subclass_name,
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
  e.clientprocessid,
  e.Severity,
  e.Error,
  e.ObjectName,
  e.ObjectType
--select top 10 *
--select distinct te.trace_event_id, te.name
from fn_trace_gettable(cast((select top 1 value from ::fn_trace_getinfo(1) where property=2) as varchar(255)), default) e
  join sys.trace_events te on e.eventclass=te.trace_event_id
  left join sys.trace_subclass_values v on te.trace_event_id = v.trace_event_id and e.EventSubClass = v.subclass_value
where 1=1
  --and e.eventclass=46 --object created
  --and e.eventclass=47 --object deleted
  --and e.eventclass=22 --error log
  --and e.eventclass=20 --login failures
  --and e.eventclass=93 --log file autogrowth
  --and e.eventclass=92 --data file autogrowth
  --and e.eventclass=25 --deadlock
  --and SPID = 886
  --and ApplicationName like '%DEB76E7C-4F22-42D5-BCA7-BCC53599D47C%'
  --and DatabaseName in ('tempdb')
  --and ISNULL(convert (varchar(20), object_name(e.objectid)),'') != ''
  --and e.starttime >= '2012-05-04 12:50'
  --and e.starttime < '2012-05-04 12:53'
order by e.starttime desc

/*
sp_configure 'default trace enabled'

select * from sys.traces where is_default = 1
select * from sys.trace_events order by name where trace_event_id = 79
select * from msdb.dbo.sysjobs where name like 'Reporting%'
*/

--by hour
select 
  datepart(yy,e.starttime) as [year],
  datepart(mm,e.starttime) as [month],
  datepart(dd,e.starttime) as [day],
  datepart(hh,e.starttime) as [hour],
  count(1)
  --select min(e.starttime)
--from fn_trace_gettable(cast((select top 1 value from ::fn_trace_getinfo(1) where property=2) as varchar(255)), default) e
from fn_trace_gettable('E:\MSSQL10_50.MSSQLSERVER\MSSQL\Log\log_6108.trc', default) e
  join sys.trace_events te on e.eventclass=te.trace_event_id
  left join sys.trace_subclass_values v on te.trace_event_id = v.trace_event_id and e.EventSubClass = v.subclass_value
where 1=1
  and ApplicationName = '.Net SqlClient Data Provider'
  and DatabaseName in ('tempdb')
  and te.name = 'Object:Created'
  --and e.starttime >= '2013-01-01'
  --and e.starttime < '2014-01-08'
group by
  datepart(yy,e.starttime), datepart(mm,e.starttime), datepart(dd,e.starttime), datepart(hh,e.starttime)
order by 1,2,3,4