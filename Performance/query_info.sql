--just the good stuff
select   
 db_name(database_id) as DbName,
  session_id, 
  start_time, 
  status,
  wait_type,
  cpu_time,
  total_elapsed_time,
  reads,
  writes,
  logical_reads,
  statement_start_offset,
  statement_end_offset,
  sql_handle,
  plan_handle,
  query_hash,
  query_plan_hash,
 [text] as BatchText,
  substring([text], (statement_start_offset/2) + 1, 
  ((case statement_end_offset 
    when -1 then datalength([text]) else statement_end_offset end 
    - statement_start_offset)/2) + 1) as SQL_Statement,
  query_plan
from sys.dm_exec_requests as r
  cross apply sys.dm_exec_sql_text(sql_handle)
 CROSS apply sys.dm_exec_query_plan(plan_handle) as qp 






select * from sys.dm_exec_sessions
select * from sys.dm_exec_query_profiles

select * from sys.dm_exec_connections
select * from sys.dm_os_schedulers
select * from sys.dm_os_workers
select * from sys.dm_os_tasks
where session_id = 53

SELECT DB_NAME(eR.database_id) AS database_name
 , eR.session_id
 , oWT.exec_context_id
 , oWT.blocking_exec_context_id
 , oWT.wait_duration_ms
 , oWT.wait_type
 , oWT.resource_description
 --select *
FROM sys.dm_os_waiting_tasks oWT
 INNER JOIN sys.dm_exec_sessions eS 
  ON oWT.session_id = eS.session_id
 INNER JOIN sys.dm_exec_requests eR 
  ON oWT.session_id = eR.session_id
WHERE eS.session_id <> @@SPID
 AND is_user_process = 1
ORDER BY eR.session_id
 , oWT.exec_context_id
 , oWT.blocking_exec_context_id;

SELECT STasks.session_id, SThreads.os_thread_id  
  FROM sys.dm_os_tasks AS STasks  
  INNER JOIN sys.dm_os_threads AS SThreads  
    ON STasks.worker_address = SThreads.worker_address  
  WHERE STasks.session_id IS NOT NULL  
  ORDER BY STasks.session_id;  
GO  

sp_who2

