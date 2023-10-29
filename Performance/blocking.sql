/* Blocked Processes 
	select * from msdb.sys.dm_exec_requests
	select * from msdb.sys.dm_exec_sessions
	select * from msdb.sys.dm_tran_locks

	dm_exec_requests
		wait_type = type of resource that the connection is waiting on, NULL then the SPID is not currently waiting on any resource
		last_wait_type = the last waittype that the SPID experienced unless currently experiencing
		wait_time = number of milliseconds that the SPID has been waiting with the current waittype

	--get current wait_types
	select distinct wait_type, last_wait_type 
	from msdb.sys.dm_exec_requests
	where wait_type is not null
	order by last_wait_type
	
*/

--simple version
--blocking sessions
select blocking_session_id, wait_duration_ms, session_id from 
sys.dm_os_waiting_tasks
where blocking_session_id is not null

--what SQL is returned by the blocking_session_id from previous query
dbcc INPUTBUFFER(53)


--more complex version
select distinct 
  es.session_id as BlkdProc,
  er.blocking_session_id as BlkdBy,
  db_name(tl.resource_database_id) as [Database],
  tl.resource_type as LockType,
  tl.resource_associated_entity_id as ObjectId,
  object_name(tl.resource_associated_entity_id) as ObjectName,
  es2.login_name as BlockingLoginName,
  cast(es2.host_name as varchar(100)) as BlockingHostName, 
  cast(es2.program_name as varchar(100)) as BlockingProgramName,
  er2.command as BlockingCommand
--select *
from msdb.sys.dm_exec_sessions es
  left join msdb.sys.dm_exec_requests er on es.session_id = er.session_id
  left join msdb.sys.dm_exec_sessions es2 on er.blocking_session_id = es2.session_id
  left join msdb.sys.dm_exec_requests er2 on es2.session_id = er2.session_id
  left join msdb.sys.dm_tran_locks tl on er.blocking_session_id = tl.request_session_id
where er.blocking_session_id != 0 
	and er.wait_type not like '%LATCH%'
	and er.wait_time != 0
	and es.session_id != er.blocking_session_id	
	and tl.resource_type = 'OBJECT'
order by er.blocking_session_id



/*
--old version
select distinct  
	'Blkd Proc' = a.spid, 
	'Blkd by' = a.blocked,
	'Database' = convert(char(20), db_name(b.rsc_dbid)),
	'Table id' = b.rsc_objid ,
	'Lock type' = b.rsc_type
--select *
from master.dbo.sysprocesses a, master.dbo.syslockinfo b
where a.blocked != 0 
	and a.blocked = b.req_spid
	and a.waittype not in (0x400,0x401,0x402,0x403,0x404,0x405,0x410,0x411,0x412,0x413,0x414,0x415,0x420,0x421,0x422,0x423,0x424,0x425)
	and a.waittime != 0
	and a.spid != a.blocked		
order by a.blocked


execute ('select distinct a.spid, "Login Name" = convert(char(20), suser_sname(a.sid)), 
	"hostname" = convert(varchar(30), a.hostname), 
	"program_name" = convert(varchar(30), a.program_name), a.blocked,
	"cmd" = case charindex(char(0), convert(char(16), a.cmd))
		when 0 then convert(char(16), a.cmd)
		else convert(char(16), substring(a.cmd, 1, charindex(char(0), convert(char(16), a.cmd))-1))
		end
	from master.dbo.sysprocesses a, master.dbo.sysprocesses b
	where a.spid != a.blocked
	and a.waittype not in (0x400,0x401,0x402,0x403,0x404,0x405,0x410,0x411,0x412,0x413,0x414,0x415,0x420,0x421,0x422,0x423,0x424,0x425)	
	and ((a.spid = b.blocked) or (a.blocked != 0 and a.waittime != 0))'
)
go

*/