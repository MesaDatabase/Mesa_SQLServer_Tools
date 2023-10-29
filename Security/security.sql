----------------------server----------------------
--server principals
select @@servername as server, principal_id, name, type, type_desc, is_disabled, create_date, modify_date 
from sys.server_principals
where name not like '##%'
order by type_desc, name

--server principal role members
select @@servername as server, sp.principal_id, sp.name, srm.role_principal_id, sp2.name
--select *
from sys.server_role_members srm
  left join sys.server_principals sp on srm.member_principal_id = sp.principal_id
  left join sys.server_principals sp2 on srm.role_principal_id = sp2.principal_id

--server principal permissions
select @@servername as server, sp.principal_id, sp.name, sp.type_desc, class_desc, spm.permission_name, spm.state_desc from sys.server_permissions spm
  join sys.server_principals sp on spm.grantee_principal_id = sp.principal_id
where sp.name not like '##%'
order by sp.name, spm.permission_name


--------------------database----------------------------------------------
--database principals
exec msdb.sys.sp_MSforeachdb 'use [?]; 
select db_name() as DbName, principal_id, name, type_desc, create_date, modify_date 
from sys.database_principals
where name not like ''##%''
  and principal_id > 4 
  and principal_id < 16000
order by principal_id'

--database principal role members
exec msdb.sys.sp_MSforeachdb 'use [?]; 
select db_name() as DbName, dp.principal_id, dp.name, dp.type_desc, class_desc, dpm.permission_name, dpm.state_desc, obj.name
from sys.database_permissions dpm
  join sys.database_principals dp on dpm.grantee_principal_id = dp.principal_id
  left join sys.sysobjects obj on dpm.major_id = obj.id
where dp.name not like ''##%''
  and dp.name != ''public''
  and dp.principal_id > 4 
order by dp.name, dpm.permission_name'

--database principal permissions
exec msdb.sys.sp_MSforeachdb 'use [?]; 
select db_name() as DbName, dp.principal_id, dp.name, dp.type_desc, class_desc, dpm.permission_name, dpm.state_desc, obj.name
from sys.database_permissions dpm
  join sys.database_principals dp on dpm.grantee_principal_id = dp.principal_id
  left join sys.sysobjects obj on dpm.major_id = obj.id
where dp.name not like ''##%''
  and dp.name != ''public''
order by dp.name, dpm.permission_name'

----------other-------------------
select * from sys.sql_logins (nolock) 

--sysadmins
select * from master.sys.syslogins
where sysadmin = 1
  and name <> SUSER_SNAME(0x01)
  and denylogin = 0