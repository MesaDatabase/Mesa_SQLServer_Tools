select top 100
  db_name(st.dbid) as DbName,
  st.[text] as Batch_Object, 
  substring(st.[text], (qs.statement_start_offset/2) + 1, 
  ((case qs.statement_end_offset 
    when -1 then datalength(st.[text]) else qs.statement_end_offset end 
    - qs.statement_start_offset)/2) + 1) as SQL_Statement,
  qp.query_plan,
  qs.execution_count,
  qs.total_physical_reads, 
  (qs.total_physical_reads / qs.execution_count) as average_physical_reads, 
  qs.total_logical_writes, 
  (qs.total_logical_writes / qs.execution_count) as average_logical_writes, 
  qs.total_logical_reads, 
  (qs.total_logical_reads / qs.execution_count) as average_logical_lReads, 
  qs.total_clr_time, 
  (qs.total_clr_time / qs.execution_count) as average_CLRTime, 
  qs.total_elapsed_time, 
  (qs.total_elapsed_time / qs.execution_count) as average_elapsed_time, 
  qs.last_execution_time, 
  qs.creation_time,
  (qs.total_worker_time / qs.execution_count) as average_worker_time, 
  total_worker_time,
  (qs.execution_count / (datediff(minute,qs.creation_time,getdate()))*60) as average_executions_per_hour,
  qs.creation_time as query_last_compiled,
  datediff(hour,qs.creation_time,getdate()) as hours_since_compile,
  query_hash,
  query_plan_hash,
  plan_handle
  --select top 10 qs.*
from sys.dm_exec_query_stats as qs 
       CROSS apply sys.dm_exec_sql_text(qs.sql_handle) as st 
       CROSS apply sys.dm_exec_query_plan(qs.plan_handle) as qp 
--where plan_handle = 0x05000600436DC129503E471D0C00000001000000000000000000000000000000000000000000000000000000
--where st.[text] like '%uspApplicantGet%'
--  and qs.execution_count > 0
--  and (qs.total_worker_time / qs.execution_count) >= 100000 --average cpu time more than 100mls
--  and substring(st.[text], (qs.statement_start_offset/2) + 1, 
--  ((case qs.statement_end_offset 
--    when -1 then datalength(st.[text]) else qs.statement_end_offset end 
--    - qs.statement_start_offset)/2) + 1) like '%PSCUCOMPANY%'
--order by qs.total_worker_time desc 
--order by qs.execution_count desc 
--order by (qs.total_worker_time / qs.execution_count) desc