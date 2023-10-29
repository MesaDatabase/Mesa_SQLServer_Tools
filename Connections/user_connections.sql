 select 
   c.session_id, 
   c.auth_scheme,  
   r.scheduler_id,
   s.login_name, 
   p.hostname,
   p.program_name,
   p.hostprocess,
   db_name(p.dbid) as database_name, 
   case s.transaction_isolation_level when 0 then 'Unspecified' 
   when 1 then 'Read Uncomitted' 
   when 2 then 'Read Committed' 
   when 3 then 'Repeatable' 
   when 4 then 'Serializable' 
   when 5 then 'Snapshot' end as transaction_isolation_level, 
   s.status as SessionStatus, 
   r.status as RequestStatus,
   case when r.sql_handle is NULL then c.most_recent_sql_handle else r.sql_handle end as sql_handle,
   r.cpu_time,
   r.reads,
   r.writes,
   r.logical_reads,
   r.total_elapsed_time
from sys.dm_exec_connections c 
  join sys.dm_exec_sessions s on c.session_id = s.session_id
  left join sys.dm_exec_requests r on c.session_id = r.session_id
  join sys.sysprocesses p on c.session_id = p.spid
 