Check if Availability Group is Primary on this Replica


IF sys.fn_hadr_is_primary_replica ('DB1') = 0
BEGIN
  RAISERROR('This is not the primary replica for the specified database',16,1)
END



--next step
--success


--for non-admin users to be able to execute sys.fn_hadr_is_primary_replica, they will need:
-execute privs on sys.fn_hadr_is_primary_replica
-db_reader on master
-these:
	GRANT VIEW SERVER STATE TO [domain\user];
	GRANT VIEW ANY DEFINITION TO [domain\user];