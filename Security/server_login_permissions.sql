--grant view server state
USE master
GO

GRANT VIEW SERVER STATE TO [DOMAIN\svc-user1]
GO

--view permissions for specified server login
select * 
from msdb.sys.server_permissions pe
  join msdb.sys.server_principals pr on pe.grantee_principal_id = pr.principal_id
where pr.principal_id = 268

--permissions dmvs
select * from msdb.sys.server_permissions
select * from msdb.sys.server_principals