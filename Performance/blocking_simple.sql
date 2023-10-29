-- Head of Blocked processes
IF EXISTS
(SELECT * FROM master.dbo.sysprocesses
WHERE spid IN (SELECT blocked FROM master.dbo.sysprocesses))
SELECT
sp.spid, sp.[status], sp.loginame,
sp.hostname, sp.[program_name],
sp.blocked, sp.open_tran,
dbname=db_name(sp.[dbid]), sp.cmd,
sp.waittype, sp.waittime, sp.last_batch, st.[text]
FROM master.dbo.sysprocesses sp
CROSS APPLY sys.dm_exec_sql_text (sp.[sql_handle]) st
WHERE spid IN (SELECT blocked FROM master.dbo.sysprocesses)
AND blocked=0
ELSE
SELECT 'No blocking processes found!' 


SELECT
sp.spid, sp.[status], sp.loginame,
sp.hostname, sp.[program_name],
sp.blocked, sp.open_tran,
dbname=db_name(sp.[dbid]), sp.cmd,
sp.waittype, sp.waittime, sp.last_batch, st.[text]
FROM master.dbo.sysprocesses sp
CROSS APPLY sys.dm_exec_sql_text (sp.[sql_handle]) st
WHERE spid IN (SELECT blocked FROM master.dbo.sysprocesses)
AND blocked>0


----more complex version
--select distinct 
--  es.session_id as BlkdProc,
--  er.blocking_session_id as BlkdBy,
--  db_name(tl.resource_database_id) as [Database],
--  tl.resource_type as LockType,
--  tl.resource_associated_entity_id as ObjectId,
--  object_name(tl.resource_associated_entity_id) as ObjectName,
--  es2.login_name as BlockingLoginName,
--  cast(es2.host_name as varchar(100)) as BlockingHostName, 
--  cast(es2.program_name as varchar(100)) as BlockingProgramName,
--  er2.command as BlockingCommand
----select *
--from msdb.sys.dm_exec_sessions es
--  left join msdb.sys.dm_exec_requests er on es.session_id = er.session_id
--  left join msdb.sys.dm_exec_sessions es2 on er.blocking_session_id = es2.session_id
--  left join msdb.sys.dm_exec_requests er2 on es2.session_id = er2.session_id
--  left join msdb.sys.dm_tran_locks tl on er.blocking_session_id = tl.request_session_id
--where er.blocking_session_id != 0 
--	and er.wait_type not like '%LATCH%'
--	and er.wait_time != 0
--	and es.session_id != er.blocking_session_id	
--	and tl.resource_type = 'OBJECT'
--order by er.blocking_session_id
