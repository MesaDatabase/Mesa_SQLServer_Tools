/***********************************************************
-- Description  : Troubleshooting user connection
-- Created Date : 20210320
-- Notes		: Refer to https://blogs.msdn.microsoft.com/psssql/2016/07/09/why-do-i-get-the-infrastructure-error-for-login-failures/
-- Modified		: 
***********************************************************/

--check log for login failures and message

--validate that the login has CONNECT SQL for SERVER
--validate that the login does not have DENY or REVOKE
--validate that the public role has CONNECT on the TCP ENDPOINT
SELECT 
  sp.[name] AS ServerPrincipal, sp.type_desc as PrincipalType, perm.permission_name, class_desc, is_disabled, 
  ep.name AS EndpointName, ep.protocol_desc, ep.state_desc, ep.type_desc
FROM sys.server_principals AS sp
  JOIN sys.server_permissions AS perm ON sp.principal_id = perm.grantee_principal_id
  LEFT JOIN sys.endpoints AS ep ON perm.major_id = ep.endpoint_id
WHERE (permission_name = 'CONNECT SQL' AND class_desc = 'SERVER')
  OR (permission_name = 'CONNECT' AND class_desc = 'ENDPOINT')


--check UAC setting


--view tokens for fun
select distinct name, usage 
--select *
from sys.login_token
where type = 'WINDOWS GROUP'
order by 1

select * from sys.user_token
