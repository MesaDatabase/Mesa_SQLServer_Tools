--run on primary
backup database test to
disk = 'V:\test\test.bak'

backup log test to
disk = 'V:\test\test_log.trn'


--run on mirror
restore database test from
--restore filelistonly from
disk = 'V:\test\test.bak'
with move 'test' to 'S:\MSSQL\DATA\test.mdf',
	 move 'test_log' to 'M:\MSSQL\DATA\test_log.ldf',
	 norecovery

restore database test from
disk = 'V:\test\test_log.trn'
with norecovery


--run on primary
Use master
IF Exists(Select * From sys.endpoints Where name ='Mirroring')
	Drop EndPoint Mirroring
GO
CREATE ENDPOINT [Mirroring]
AUTHORIZATION [na\na-s-cch-sql]
STATE=STARTED
AS TCP (LISTENER_PORT=5022, LISTENER_IP=ALL)
FOR DATA_MIRRORING (ROLE=PARTNER, AUTHENTICATION=WINDOWS NEGOTIATE,
ENCRYPTION=REQUIRED ALGORITHM RC4)
GO

Select * From sys.endpoints
GO

--run on mirror
ALTER DATABASE test SET PARTNER = 'TCP://10.xx.xx.xx:xxx1'

--run on primary
ALTER DATABASE test SET PARTNER = 'TCP://10.xxx.xxx.xx:xxx2'

ALTER DATABASE test SET PARTNER SAFETY OFF

--mirroring tables for reference
select * from sys.database_mirroring
select * from sys.database_mirroring_endpoints
select * from sys.server_principals
select * from msdb.sys.endpoints
select * from sys.dm_db_mirroring_connections
