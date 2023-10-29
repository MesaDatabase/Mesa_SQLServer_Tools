--- YOU MUST EXECUTE THE FOLLOWING SCRIPT IN SQLCMD MODE.
:Connect SERVERSQL01A

IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END


GO

use [master]

GO

GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SAAS\servicesqlprod]

GO

:Connect SERVERSQL01B

IF (SELECT state FROM sys.endpoints WHERE name = N'Hadr_endpoint') <> 0
BEGIN
	ALTER ENDPOINT [Hadr_endpoint] STATE = STARTED
END


GO

use [master]

GO

GRANT CONNECT ON ENDPOINT::[Hadr_endpoint] TO [SAAS\servicesqlprod]

GO

:Connect SERVERSQL01A

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END

GO

:Connect SERVERSQL01B

IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER WITH (STARTUP_STATE=ON);
END
IF NOT EXISTS(SELECT * FROM sys.dm_xe_sessions WHERE name='AlwaysOn_health')
BEGIN
  ALTER EVENT SESSION [AlwaysOn_health] ON SERVER STATE=START;
END

GO

:Connect SERVERSQL01A

USE [master]

GO

CREATE AVAILABILITY GROUP [dit-ag01]
WITH (AUTOMATED_BACKUP_PREFERENCE = SECONDARY)
FOR DATABASE [ClaimsProvider_DIT], [CMCDB_DIT]
REPLICA ON N'SERVERSQL01A' WITH (ENDPOINT_URL = N'TCP://SERVERSQL01A.SAAS.LOCAL:5022', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = READ_ONLY)),
	N'SERVERSQL01B' WITH (ENDPOINT_URL = N'TCP://SERVERSQL01B.SAAS.LOCAL:5022', FAILOVER_MODE = AUTOMATIC, AVAILABILITY_MODE = SYNCHRONOUS_COMMIT, BACKUP_PRIORITY = 50, SECONDARY_ROLE(ALLOW_CONNECTIONS = READ_ONLY));

GO

:Connect SERVERSQL01A

USE [master]

GO

ALTER AVAILABILITY GROUP [dit-ag01]
ADD LISTENER N'AUSCCATDITSQLAG' (
WITH IP
((N'10.49.115.134', N'255.255.255.192')
)
, PORT=1433);

GO

:Connect SERVERSQL01B

ALTER AVAILABILITY GROUP [dit-ag01] JOIN;

GO

:Connect SERVERSQL01A

BACKUP DATABASE [ClaimsProvider_DIT] TO  DISK = N'\\SERVERsql01a\temp\ClaimsProvider_DIT.bak' WITH  COPY_ONLY, FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

GO

:Connect SERVERSQL01B

RESTORE DATABASE [ClaimsProvider_DIT] FROM  DISK = N'\\SERVERsql01a\temp\ClaimsProvider_DIT.bak' WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO

:Connect SERVERSQL01A

BACKUP LOG [ClaimsProvider_DIT] TO  DISK = N'\\SERVERsql01a\temp\ClaimsProvider_DIT_20120625184400.trn' WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

GO

:Connect SERVERSQL01B

RESTORE LOG [ClaimsProvider_DIT] FROM  DISK = N'\\SERVERsql01a\temp\ClaimsProvider_DIT_20120625184400.trn' WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO

:Connect SERVERSQL01A

BACKUP DATABASE [CMCDB_DIT] TO  DISK = N'\\SERVERsql01a\temp\CMCDB_DIT.bak' WITH  COPY_ONLY, FORMAT, INIT, SKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

GO

:Connect SERVERSQL01B

RESTORE DATABASE [CMCDB_DIT] FROM  DISK = N'\\SERVERsql01a\temp\CMCDB_DIT.bak' WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO

:Connect SERVERSQL01A

BACKUP LOG [CMCDB_DIT] TO  DISK = N'\\SERVERsql01a\temp\CMCDB_DIT_20120625184400.trn' WITH NOFORMAT, NOINIT, NOSKIP, REWIND, NOUNLOAD, COMPRESSION,  STATS = 5

GO

:Connect SERVERSQL01B

RESTORE LOG [CMCDB_DIT] FROM  DISK = N'\\SERVERsql01a\temp\CMCDB_DIT_20120625184400.trn' WITH  NORECOVERY,  NOUNLOAD,  STATS = 5

GO


GO




# set backup preference
ALTER Availability group ag01 SET (automated_backup_preference = [PRIMARY|SECONDARY|SECONDARY_ONLY|NONE]

ALTER Availability group <ag_name> MODIFY REPLICA ON '<server_name1> WITH (Backup_Priority=4)
ALTER Availability group <ag_name> MODIFY REPLICA ON '<server_name2> WITH (Backup_Priority=1)
ALTER Availability group <ag_name> MODIFY REPLICA ON '<server_name3> WITH (Backup_Priority=2)
ALTER Availability group <ag_name> MODIFY REPLICA ON '<server_name4> WITH (Backup_Priority=3)


# look into
sys.dm_hadr_availability_replica_states and sys.availability_replicas.
select master.sys.fn_hadr_backup_is_preferred_replica('<db_name>')



