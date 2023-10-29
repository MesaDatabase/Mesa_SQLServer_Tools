select db_name(database_id), last_commit_lsn, last_commit_time 
from sys.dm_hadr_database_replica_states 
where is_local = 1
order by db_name(database_id)