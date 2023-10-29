select * 
from msdb.sys.server_permissions pe
  join msdb.sys.server_principals pr on pe.grantee_principal_id = pr.principal_id
where grantor_principal_id = 266

select * from sys.endpoints

REVOKE CONNECT ON ENDPOINT::Hadr_endpoint FROM [DellCloud\svc-sqladmin];
ALTER AUTHORIZATION ON ENDPOINT::Hadr_endpoint TO sa;

GRANT CONNECT ON ENDPOINT::Hadr_endpoint TO [DellCloud\svc-sqladmin];

USE [master]
GO

DROP LOGIN [Domain\user]
GO

CREATE LOGIN [Domain\user] FROM WINDOWS WITH DEFAULT_DATABASE=[master], DEFAULT_LANGUAGE=[us_english]
GO

ALTER SERVER ROLE [sysadmin] ADD MEMBER [Domain\user]
GO


