declare @t1 table (DatabaseName varchar(50), Value1 bigint, Value2 bigint)

insert into @t1 (DatabaseName, Value1)
select instance_name, cntr_value from sys.dm_os_performance_counters (nolock)
where object_name = 'SQLServer:Databases'
  and counter_name = 'Log Bytes Flushed/sec'
  and instance_name not in ('tempdb', 'model', 'DBA', 'mssqlsystemresource', 'msdb', 'master', '_Total')
				 
waitfor delay '00:00:30'

update t1
set t1.Value2 = d1.cntr_value
from @t1 as t1 
  join sys.dm_os_performance_counters (nolock) as d1 on d1.instance_name = t1.DatabaseName
where object_name = 'SQLServer:Databases'
  and counter_name = 'Log Bytes Flushed/sec'

--select DatabaseName, cast((value2-value1) as decimal(17,2))/5/1024 as LogKBFlushedPerSec from @t1 as t1
--order by 2 desc


select 
  h1.name as AGName,
  h2.replica_server_name as ReplicaName,
  h5.database_name,
  h6.log_send_queue_size,
  cast((value2-value1) as decimal(17,2))/30/1024 as LogKBFlushedPerSec,
  case when (cast((value2-value1) as decimal(17,2))/30/1024) = 0 then 0
  else (h6.log_send_queue_size / cast((value2-value1) as decimal(17,2))/30/1024 )
  end  as PotentialDataLossSeconds
from sys.availability_groups as h1
  join sys.dm_hadr_availability_replica_cluster_states as h2 on h1.group_id = h2.group_id
  join sys.availability_replicas as h3 on h2.replica_id = h3.replica_id
  join sys.dm_hadr_availability_replica_states as h4 on h2.replica_id = h4.replica_id
  join sys.availability_databases_cluster as h5 on h1.group_id = h5.group_id
  join sys.dm_hadr_database_replica_states as h6 on h4.replica_id = h6.replica_id and h5.group_database_id = h6.group_database_id
  join @t1 as t1 on h5.database_name = t1.DatabaseName
where role_desc <> 'PRIMARY'
  --and log_send_queue_size > 0


