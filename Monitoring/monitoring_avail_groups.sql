select * from sys.dm_hadr_cluster
select * from sys.dm_hadr_cluster_members
select * from sys.dm_hadr_cluster_networks
select * from sys.availability_groups
select * from sys.availability_groups_cluster
select * from sys.dm_hadr_availability_group_states
select * from sys.availability_replicas
select * from sys.dm_hadr_availability_replica_cluster_nodes
select * from sys.dm_hadr_availability_replica_cluster_states
select * from sys.dm_hadr_availability_replica_states
select * from sys.dm_hadr_auto_page_repair
select * from sys.dm_hadr_database_replica_states
select * from sys.dm_hadr_database_replica_cluster_states
select * from sys.availability_group_listener_ip_addresses
select * from sys.availability_group_listeners
select * from sys.dm_tcp_listener_states

select object_name,counter_name,instance_name,cntr_value
--select distinct object_name, counter_name
--select distinct object_name
from sys.dm_os_performance_counters
where object_name like '%replica%'
order by object_name, counter_name

 SELECT name, description 
FROM sys.dm_xe_objects 
WHERE NAME IN ( 
'alwayson_ddl_executed', 
'availability_group_lease_expired', 
'availability_replica_automatic_failover_validation', 
'availability_replica_manager_state_change', 
'availability_replica_state_change', 
'error_reported', 
'lock_redo_blocked')

 SELECT message_id, severity, is_event_logged, text 
FROM sys.messages AS m 
WHERE m.language_id = SERVERPROPERTY('LCID') 
  AND  (m.message_id=(9691) 
        OR m.message_id=(35204) 
        OR m.message_id=(9693) 
        OR m.message_id=(26024) 
        OR m.message_id=(28047) 
        OR m.message_id=(26023) 
        OR m.message_id=(9692) 
        OR m.message_id=(28034) 
        OR m.message_id=(28036) 
        OR m.message_id=(28048) 
        OR m.message_id=(28080) 
        OR m.message_id=(28091) 
        OR m.message_id=(26022) 
        OR m.message_id=(9642) 
        OR m.message_id=(35201) 
        OR m.message_id=(35202) 
        OR m.message_id=(35206) 
        OR m.message_id=(35207) 
        OR m.message_id=(26069) 
        OR m.message_id=(26070) 
        OR m.message_id>(41047) 
        AND m.message_id<(41056) 
        OR m.message_id=(41142) 
        OR m.message_id=(41144) 
        OR m.message_id=(1480) 
        OR m.message_id=(823) 
        OR m.message_id=(824) 
        OR m.message_id=(829) 
        OR m.message_id=(35264) 
        OR m.message_id=(35265) 
) 

CREATE EVENT SESSION [AlwaysOn_health] ON SERVER 
--Occurs when AlwaysOn DDL is executed including CREATE, ALTER or DROP 
ADD EVENT sqlserver.alwayson_ddl_executed, 
--Occurs when there is a connectivity issue between the cluster and the Availability Group resulting 
--in a failure to renew the lease 
ADD EVENT sqlserver.availability_group_lease_expired, 
--Occurs when the failover validates the readiness of replica as a primary. For instance, the failover 
--validation will return false when not all databases are synchronized or not joined 
ADD EVENT sqlserver.availability_replica_automatic_failover_validation, 
--Occurs when the state of the Availability Replica Manager has changed. 
ADD EVENT sqlserver.availability_replica_manager_state_change, 
--Occurs when the state of the Availability Replica has changed. 
ADD EVENT sqlserver.availability_replica_state_change, 
--Occurs when an error is reported based on the previously listed table 
ADD EVENT sqlserver.error_reported( 
    WHERE ([error_number]=(9691) OR [error_number]=(35204) OR [error_number]=(9693) OR [error_number]=(26024) OR [error_number]=(28047) OR [error_number]=(26023) OR [error_number]=(9692) OR [error_number]=(28034) OR [error_number]=(28036) OR [error_number]=(28048) OR [error_number]=(28080) OR [error_number]=(28091) OR [error_number]=(26022) OR [error_number]=(9642) OR [error_number]=(35201) OR [error_number]=(35202) OR [error_number]=(35206) OR [error_number]=(35207) OR [error_number]=(26069) OR [error_number]=(26070) OR [error_number]>(41047) AND [error_number]<(41056) OR [error_number]=(41142) OR [error_number]=(41144) OR [error_number]=(1480) OR [error_number]=(823) OR [error_number]=(824) OR [error_number]=(829) OR [error_number]=(35264) OR [error_number]=(35265))), 
--Occurs when the redo thread blocks when trying to acquire a lock. 
ADD EVENT sqlserver.lock_redo_blocked 
--Writes to the file target for persistence in the system beyond failovers and service restarts 
ADD TARGET package0.event_file(SET filename=N'AlwaysOn_health.xel',max_file_size=(5),max_rollover_files=(4)) 
WITH (MAX_MEMORY=4096 KB, EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS, MAX_DISPATCH_LATENCY=30 SECONDS, MAX_EVENT_SIZE=0 KB, MEMORY_PARTITION_MODE=NONE, TRACK_CAUSALITY=OFF, STARTUP_STATE=ON) 
GO 

SELECT * FROM sys.fn_xe_file_target_read_file('D:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)
where object_name = 'availability_replica_manager_state_change'


ALTER DATABASE [AdventureWorks2012] SET HADR SUSPEND;

GO