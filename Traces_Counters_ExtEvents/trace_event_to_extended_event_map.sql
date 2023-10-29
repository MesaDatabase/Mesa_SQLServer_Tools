USE MASTER;
GO

--all trace event classes and columns
SELECT DISTINCT
   tb.trace_event_id,
   te.name AS 'Event Class',
   em.package_name AS 'Package',
   em.xe_event_name AS 'XEvent Name',
   tb.trace_column_id,
   tc.name AS 'SQL Trace Column',
   am.xe_action_name as 'Extended Events action'
FROM sys.trace_events te 
	LEFT OUTER JOIN sys.trace_xe_event_map em ON te.trace_event_id = em.trace_event_id
	LEFT OUTER JOIN sys.trace_event_bindings tb ON em.trace_event_id = tb.trace_event_id 
	LEFT OUTER JOIN sys.trace_columns tc ON tb.trace_column_id = tc.trace_column_id 
	LEFT OUTER JOIN sys.trace_xe_action_map am ON tc.trace_column_id = am.trace_column_id
--where te.trace_event_id = 20
where te.name like '%log%'
ORDER BY te.name, tc.name


--all trace event classes
SELECT DISTINCT
   te.trace_event_id,
   te.name AS 'Event Class',
   em.package_name AS 'Package',
   em.xe_event_name AS 'XEvent Name'
--select *
FROM sys.trace_events te 
	LEFT OUTER JOIN sys.trace_xe_event_map em ON te.trace_event_id = em.trace_event_id
	LEFT OUTER JOIN sys.trace_event_bindings tb ON em.trace_event_id = tb.trace_event_id 
where em.xe_event_name is not null
ORDER BY te.name
