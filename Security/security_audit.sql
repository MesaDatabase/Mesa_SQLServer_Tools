----------------------server----------------------
--server principals
select @@servername, principal_id, sid, name, type, type_desc, is_disabled, create_date, modify_date 
from sys.server_principals
where name not like '##%'
order by type_desc, name

--server principal role members
select @@servername, sp.principal_id, sp.sid, sp.name, srm.role_principal_id, sp2.name
--select *
from sys.server_role_members srm
  left join sys.server_principals sp on srm.member_principal_id = sp.principal_id
  left join sys.server_principals sp2 on srm.role_principal_id = sp2.principal_id

--server principal permissions
select @@servername, sp.principal_id, sp.sid, sp.name, sp.type_desc, class_desc, spm.permission_name, spm.state_desc 
from sys.server_permissions spm
  join sys.server_principals sp on spm.grantee_principal_id = sp.principal_id
where sp.name not like '##%'
order by sp.name, spm.permission_name


--------------------database----------------------------------------------
--database users (includes mapping)
set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 
--where name = 'USA09'

create table #t2 (DbName varchar(100), PrincipalName varchar(100),PrincipalId int, Type varchar(50), DefaultSchemaName varchar(100), CreateDate datetime, ModifyDate datetime, DbSid varbinary(85), SrvSidOnSid varbinary(85), SrvSidOnName varbinary(85))

declare @dbname varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name(), s1.name, s1.principal_id, s1.type_desc, default_schema_name, s1.create_date, s1.modify_date, s1.sid, s2.sid, s3.sid
from sys.database_principals as s1 left join master.sys.server_principals as s2 on s1.sid = s2.sid
left join master.sys.server_principals as s3 on s1.name = s3.name
;'');');
delete from @t1 where DatabaseName = @dbname
end 

select @@servername, *, 
  case when DbSid is null then 'MappingNotReqd'
	   when DbSid = 0 then 'MappingNotReqd'
	   when SrvSidOnSid is null and Type = 'DATABASE_ROLE' then 'MappingNotReqd'
	   when SrvSidOnName is null then 'NotMapped'
	   when SrvSidOnName != DbSid then 'Orphaned'
	   when SrvSidOnSid = DbSid then 'Mapped'
  end as Mapping
from #t2
drop table #t2


--database principal role members
--database role members
set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 

create table #t2 (DbName varchar(100), PrincipalId int, PrincipalName varchar(100), RolePrincipalId int, RolePrincipalName varchar(100))

declare @dbname varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name() as DbName, drm.member_principal_id, dp.name, drm.role_principal_id, dp2.name
from sys.database_role_members drm
  left join sys.database_principals dp on drm.member_principal_id = dp.principal_id
  left join sys.database_principals dp2 on drm.role_principal_id = dp2.principal_id
;'');');
delete from @t1 where DatabaseName = @dbname
end 

select @@servername, *
from #t2
drop table #t2


--database permissions
set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 

create table #t2 (DbName varchar(100), PrincipalId int, PrincipalName varchar(100), Type varchar(50), ClassDesc varchar(100), PermissionName varchar(100), State varchar(100), ObjectName varchar(255))

declare @dbname varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name() as DbName, dp.principal_id, dp.name, dp.type_desc, class_desc, dpm.permission_name, dpm.state_desc, obj.name
from sys.database_permissions dpm
  join sys.database_principals dp on dpm.grantee_principal_id = dp.principal_id
  left join sys.sysobjects obj on dpm.major_id = obj.id where dp.name = ''''DYNGRP''''
;'');');
delete from @t1 where DatabaseName = @dbname
end 

select DbName, PrincipalName, ClassDesc, PermissionName, State, count(distinct isnull(ObjectName,'1'))
from #t2
group by DbName, PrincipalName, ClassDesc, PermissionName, State
order by 1,2,3,4,5
drop table #t2


----------other-------------------
select * from sys.sql_logins (nolock) 

--sysadmins
select * from master.sys.syslogins
where sysadmin = 1
  and name <> SUSER_SNAME(0x01)
  and denylogin = 0

--blank passwords
SELECT name,type_desc,create_date,modify_date,password_hash 
FROM sys.sql_logins 
WHERE PWDCOMPARE('',password_hash)=1;

--password same as login name
SELECT name,type_desc,create_date,modify_date,password_hash 
FROM sys.sql_logins 
WHERE PWDCOMPARE(name,password_hash)=1;

--report orphaned users (select database)
EXEC sp_change_users_login 'Report'

--link orphaned users to existing server principal
EXEC sp_change_users_login 'Auto_Fix', 'lgreatorex'


--orphaned users for all dbs
use master
go

set nocount on

declare @db varchar(255)
declare @sql varchar(max)

declare @t1 table (DbName varchar(255))
insert into @t1
select name from sys.databases
where database_id > 4
  and name <> 'DBA'
  and state_desc = 'ONLINE'
  
create table #t2 (UserName varchar(255), UserSID varbinary(85))
declare @t3 table (DbName varchar(255),UserName varchar(255), UserSID varbinary(85))

while exists (select top 1 * from @t1 as t1)
begin
  set @db = (select top 1 DbName from @t1 as t1)
  set @sql = 'use [' + @db + ']; insert into #t2 EXEC sp_change_users_login ''Report'';'
  --print @sql
  exec(@sql)
  insert into @t3 select @db, t2.* from #t2 as t2
  delete from @t1 where DbName = @db
  delete from #t2
end

select * from @t3
drop table #t2


--fix all orphaned users for all dbs
use master
go

set nocount on

declare @db varchar(255)
declare @sql varchar(max)
declare @login varchar(255)

declare @t1 table (DbName varchar(255))
insert into @t1
select name from sys.databases
where database_id > 4
  and name <> 'DBA'
  and state_desc = 'ONLINE'
  
create table #t2 (UserName varchar(255), UserSID varbinary(85))
declare @t3 table (DbName varchar(255),UserName varchar(255), UserSID varbinary(85))

while exists (select top 1 * from @t1 as t1)
begin
  set @db = (select top 1 DbName from @t1 as t1)
  set @sql = 'use [' + @db + ']; insert into #t2 EXEC sp_change_users_login ''Report'';'
  --print @sql
  exec(@sql)
  insert into @t3 select @db, t2.* from #t2 as t2 where UserName <> 'dbo'
  delete from #t2 where UserName = 'dbo'

  while exists (select top 1 * from #t2)
  begin
    set @login = (select top 1 UserName from #t2)
    set @sql = 'use [' + @db + ']; EXEC sp_change_users_login ''Auto_Fix'',''' + @login + ''';'
    --print @sql
    exec(@sql)  

    set @login = (select top 1 UserName from #t2)
    set @sql = 'use [' + @db + ']; insert into #t2 EXEC sp_change_users_login ''Report'';'
    --print @sql
    exec(@sql)  

    delete from #t2 where UserName = @login
  end
  
  delete from @t1 where DbName = @db
end

select * from @t3
drop table #t2



--check if specified login is orphaned
EXEC sp_change_users_login 'Report'

--fix specified orphaned login
EXEC sp_change_users_login 'Auto_Fix','Login'