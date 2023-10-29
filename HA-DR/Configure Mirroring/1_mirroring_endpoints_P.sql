-----------------------------------------------------------
--Configure mirroring endpoints on principal
-----------------------------------------------------------

--create endpoint
use master
if exists(select * from sys.endpoints where name ='Mirroring')
	drop endpoint Mirroring
go
CREATE ENDPOINT [Mirroring]
AUTHORIZATION [DOMAIN\serviceacct1]
STATE=STARTED
AS TCP (LISTENER_PORT=5022, LISTENER_IP=ALL)
FOR DATA_MIRRORING (ROLE=PARTNER, AUTHENTICATION=WINDOWS NEGOTIATE,
ENCRYPTION=REQUIRED ALGORITHM RC4)
go


--Validate that endpoint configuration is correct and is STARTED
select @@servername, * from sys.database_mirroring_endpoints