
--Logshipping
select * from msdb.dbo.log_shipping_primary_databases
select * from msdb.dbo.log_shipping_primary_secondaries
select * from msdb.dbo.log_shipping_secondary
select * from msdb.dbo.log_shipping_secondary_databases


--Mirroring
select * from msdb.sys.database_mirroring
select * from msdb.sys.database_mirroring_endpoints
select * from msdb.sys.dm_db_mirroring_connections

--Replication
select
  @@SERVERNAME as Distributor,
  t2.data_source as PubServer,
  t1.publisher_db, 
  t3.data_source as SubServer,
  t1.subscriber_db,
  case when t1.status = 0 then 'Inactive'
	   when t1.status = 1 then 'Subscribed'
	   when t1.status = 2 then 'Active' end as Status
--select *
from distribution..MSsubscriptions as t1
  join sys.servers as t2 on t1.publisher_id = t2.server_id
  join sys.servers as t3 on t1.subscriber_id = t3.server_id
where t1.subscription_type = 0 
--  and t1.status = 2
  and subscriber_id > 0
group by
  t2.data_source,
  t1.publisher_db, 
  t3.data_source,
  t1.subscriber_db,
  case when t1.status = 0 then 'Inactive'
	   when t1.status = 1 then 'Subscribed'
	   when t1.status = 2 then 'Active' end
order by 1,2,3,4


--Availability Groups
select * from sys.availability_groups
select * from sys.availability_group_listeners
select * from sys.availability_group_listener_ip_addresses
select * from sys.availability_replicas
select * from sys.availability_read_only_routing_lists

select * from sys.dm_hadr_auto_page_repair
select * from sys.dm_hadr_availability_replica_cluster_nodes
select * from sys.dm_hadr_availability_replica_cluster_states
select * from sys.dm_hadr_availability_replica_states
select * from sys.dm_hadr_cluster
select * from sys.dm_hadr_cluster_members
select * from sys.dm_hadr_cluster_networks
select * from sys.dm_hadr_database_replica_cluster_states
select * from sys.dm_hadr_database_replica_states
select * from sys.dm_hadr_instance_node_map
select * from sys.dm_hadr_name_id_map


--HADR waits
SELECT * FROM sys.dm_os_wait_stats 
WHERE wait_type LIKE '%hadr%'
ORDER BY wait_time_ms DESC

SELECT * FROM sys.dm_xe_map_values 
WHERE name='wait_types' AND map_value LIKE '%hadr%' 
ORDER BY map_key ASC

--
select 
  h1.name as AGName,
  h2.replica_server_name as ReplicaName,
  h2.join_state_desc,
  h3.availability_mode_desc,
  h3.failover_mode_desc,
  h3.primary_role_allow_connections_desc,
  h3.secondary_role_allow_connections_desc,
  h4.role_desc,
  h4.operational_state_desc,
  h4.connected_state_desc,
  h4.recovery_health_desc,
  h4.synchronization_health_desc,
  h5.database_name,
  h6.synchronization_state_desc,
  h6.synchronization_health_desc, 
  h6.database_state_desc,
  h6.last_sent_lsn,
  h6.last_sent_time,
  h6.last_received_lsn,
  h6.last_received_time,
  h6.last_hardened_lsn,
  h6.last_hardened_time,
  h6.last_redone_lsn,
  h6.last_redone_time,
  h6.log_send_queue_size,
  h6.log_send_rate,
  h6.redo_queue_size,
  h6.redo_rate,
  h6.end_of_log_lsn,
  h6.last_commit_lsn,
  h6.last_commit_time
from sys.availability_groups as h1
  join sys.dm_hadr_availability_replica_cluster_states as h2 on h1.group_id = h2.group_id
  join sys.availability_replicas as h3 on h2.replica_id = h3.replica_id
  join sys.dm_hadr_availability_replica_states as h4 on h2.replica_id = h4.replica_id
  left join sys.availability_databases_cluster as h5 on h1.group_id = h5.group_id
  left join sys.dm_hadr_database_replica_states as h6 on h4.replica_id = h6.replica_id and h5.group_database_id = h6.group_database_id
--where role_desc <> 'PRIMARY'
--  and log_send_queue_size > 0


