select g.name, r.replica_server_name, s.role_desc,
  r.availability_mode_desc, r.failover_mode_desc, r.session_timeout, r.primary_role_allow_connections_desc, r.secondary_role_allow_connections_desc
--select *
from sys.availability_groups as g
  join sys.availability_replicas as r on g.group_id = r.group_id
  join sys.dm_hadr_availability_replica_states as s on g.group_id = s.group_id and r.replica_id = s.replica_id
order by g.name, s.role_desc, r.replica_server_name
