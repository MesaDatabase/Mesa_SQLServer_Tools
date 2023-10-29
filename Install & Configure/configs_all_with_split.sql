----------------------------------------------------------------------------------------------------------
----------------------------CAPACITY-----------------------------
----------------------------------------------------------------------------------------------------------
set nocount on

--SCRIPT #1: DISK CONFIGURATION
declare @db table (DatabaseName varchar(100))
insert into @db
select name from master.sys.databases
where state_desc not in ('OFFLINE','RESTORING')

if object_id('tempdb..#tDrives') is not null
begin
    drop table #tDrives
end
create table #tDrives (Server varchar(500), DbId int, DatabaseName varchar(100), file_id int, file_name varchar(100), physical_name varchar(200), TypeDesc varchar(10), drive char(1), sizeMB decimal(17,4), space_usedMB decimal(17,4), sizeGB decimal(17,4), space_usedGB decimal(17,4))

declare @dbname0 varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @db)
begin
set @dbname0 = (select top 1 DatabaseName from @db)
--USE master;
EXEC(N'USE [' + @dbname0 + N']; EXEC(''insert into #tDrives select @@servername, db_id(), db_name(), file_id, name, physical_name, type_desc, left(physical_name,1),
size/128.0 as SizeMB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0 as SpaceUsedMB,
size/128.0/1024 as SizeGB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0/1024 as SpaceUsedGB
FROM sys.database_files;'');');
delete from @db where DatabaseName = @dbname0
end 

declare @o1 table (Output varchar(1000))
declare @o2 table (Output varchar(1000))

set @sql = 'exec xp_cmdshell ''wmic volume get name, label, capacity, freespace /format:csv'''
insert into @o1
exec(@sql)

set @sql = 'exec xp_cmdshell ''wmic volume get name, blocksize /format:csv'''
insert into @o2
exec(@sql)

declare @dr1 table (Server varchar(500), Drive char(1), DriveLabel varchar(50), SizeMB int, FreeSpaceMB int)
insert into @dr1
select 
  master.dbo.fSplit(',',Output,1) as Server,
  left(master.dbo.fSplit(',',Output,5),1) as Drive,
  replace(master.dbo.fSplit(' ',master.dbo.fSplit(',',Output,4),1),'_VNX','') as DriveLabelClean,
  cast(master.dbo.fSplit(',',Output,2) as bigint)/1024/1024 as SizeMB,
  cast(master.dbo.fSplit(',',Output,3) as bigint)/1024/1024 as FreeSpaceMB
from @o1 as o1
where Output not like 'Capacity%'
  and ISNULL(Output,'') <> ''
  and Output not like '%\\?%'
  and Output like '%:\%'
  and cast(master.dbo.fSplit(',',Output,2) as bigint) > 0
  
declare @bk1 table (Server varchar(500), BlockSize int, Drive char(1))
insert into @bk1
select 
  master.dbo.fSplit(',',Output,1),
  cast(master.dbo.fSplit(',',Output,2) as int),
  left(master.dbo.fSplit(',',Output,3),1)
from @o2 as o2
where Output not like '%BlockSize%'
  and ISNULL(Output,'') <> ''
  and Output not like '%\\?%'
  and Output like '%:\%'
  and isnull(master.dbo.fSplit(',',Output,2),'') <> ''
  
declare @f table (Server varchar(500), Drive char(1), Label varchar(25), BlockSize int, DriveSizeGB int, DriveFreeGB int, DriveUsedGB int, SQLDataGB int, SQLLogGB int, FileSizeGB int, FileUsedGB int, SysDbFileCnt int, UserDbFileCnt int)
insert into @f
select
  dr1.Server,
  dr1.Drive,
  case when dr1.DriveLabel like '%data%' then 'Data'
	   when dr1.DriveLabel like '%log%' then 'Log'
	   when dr1.DriveLabel like '%temp%' then 'TempDB'
	   else dr1.DriveLabel
  end,
  bk1.BlockSize,
  dr1.SizeMB/1024,
  dr1.FreeSpaceMB/1024,
  (dr1.SizeMB - dr1.FreeSpaceMB)/1024,
  sum(case when tDrives.TypeDesc = 'ROWS' then tDrives.sizeGB when tDrives.TypeDesc = 'FULLTEXT' then tDrives.sizeGB else 0 end),
  sum(case when tDrives.TypeDesc = 'LOG' then tDrives.sizeGB else 0 end),
  sum(tDrives.sizeGB),
  sum(tDrives.space_usedGB),
  count(distinct case when DbId is not null and DbId <= 4 then DbId else NULL end),
  count(distinct case when DbId is not null and DbId > 4 then DbId else NULL end)
--select *
from #tDrives as tDrives
  right join @dr1 as dr1 on tDrives.Server = dr1.server and tDrives.drive = dr1.drive
  join @bk1 as bk1 on dr1.Server = bk1.server and dr1.drive = bk1.drive
group by   
  dr1.Server,
  dr1.Drive,
  case when dr1.DriveLabel like '%data%' then 'Data'
	   when dr1.DriveLabel like '%log%' then 'Log'
	   when dr1.DriveLabel like '%temp%' then 'TempDB'
	   else dr1.DriveLabel
  end,
  bk1.BlockSize,
  dr1.SizeMB,
  dr1.FreeSpaceMB
   
select 
  1 as ScriptNum,
  @@servername as SQLInstance, 
  Drive,
  Label,
  BlockSize,
  DriveSizeGB,
  DriveFreeGB,
  isnull(FileSizeGB,0) as FileSizeGB,
  DriveSizeGB - DriveFreeGB - isnull(FileSizeGB,0) as NonDbUsedGB,
  isnull(FileSizeGB,0) - isnull(FileUsedGB,0) as FileFreeGB,
  isnull(FileUsedGB,0) as FileUsedGB,
  isnull(SQLDataGB,0) as SQLDataGB,
  isnull(SQLLogGB,0) as SQLLogGB,
  isnull(SysDbFileCnt,0) as SysDbFileCnt,
  isnull(UserDbFileCnt,0) as UserDbFileCnt,
  case when isnull(FileSizeGB,0) = 0 then cast(100 as decimal(6,2))
    else cast((cast(isnull(FileSizeGB,0) - isnull(FileUsedGB,0) as decimal(18,4))/cast(isnull(FileSizeGB,0) as decimal(18,4))) as decimal(6,2)) end as FileFreePct,
  case when DriveSizeGB = 0 then cast(100 as decimal(6,2))
    else cast((cast(DriveFreeGB as decimal(18,4))/cast(DriveSizeGB as decimal(18,4))) as decimal(6,2)) end as DriveFreePct,
  case when DriveSizeGB = 0 then cast(100 as decimal(6,2))
    else cast((cast((isnull(FileSizeGB,0) - isnull(FileUsedGB,0) + DriveFreeGB) as decimal(18,4))/cast(DriveSizeGB as decimal(18,4))) as decimal(6,2)) end as DriveAndFileFreePct,
  isnull(FileSizeGB,0) - isnull(FileUsedGB,0) + DriveFreeGB as TotalFreeGB
from @f
where DriveSizeGB > 0

if object_id('tempdb..tDrives') is not null
begin
    drop table tDrives
end

--SCRIPT #2: CPU
select 2 as ScriptNum, @@servername as SQLInstance, cpu_count as virtual_cpu_count, cpu_count/hyperthread_ratio as physical_cpu_count FROM msdb.sys.dm_os_sys_info

--SCRIPT #3: MEMORY
declare @b varchar(20)
declare @sql2 varchar(2000)
set @b = (select cast(SERVERPROPERTY('productversion') as varchar(20)))

if (@b like '8%' or @b like '9%' or @b like '10%')
begin
  set @sql2 = 'select 3 as ScriptNum, @@servername as SQLInstance,
  physical_memory_in_bytes/1024/1024 AS physical_memory_mb, 
  virtual_memory_in_bytes/1024/1024 AS virtual_memory_in_mb, 
  bpool_committed*8/1024 AS bpool_committed_mb,
  bpool_commit_target*8/1024 AS bpool_commit_targt_mb,
  bpool_visible*8/1024  AS bpool_visible_mb
  FROM sys.dm_os_sys_info'
end

if (@b like '11%' or @b like '12%')
begin
  set @sql2 = 'select 3 as ScriptNum, @@servername as SQLInstance,
  physical_memory_kb/1024 AS physical_memory_mb, 
  virtual_memory_kb/1024 AS virtual_memory_in_mb, 
  committed_kb*8/1024 AS bpool_committed_mb,
  committed_target_kb*8/1024 AS bpool_commit_targt_mb,
  visible_target_kb*8/1024  AS bpool_visible_mb
FROM sys.dm_os_sys_info'
end

exec(@sql2)

----------------------------------------------------------------------------------------------------------
----------------------------VERSION-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #4: VERSION
SELECT 
  4 as ScriptNum,
  @@servername as SQLInstance,
  CAST(SERVERPROPERTY('MACHINENAME') AS VARCHAR(128)) + COALESCE('' +CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)), '') As InstanceName,
  CASE WHEN SERVERPROPERTY('IsClustered') = 1 THEN 'CLUSTERED' ELSE 'STANDALONE' END AS ServerType,
  @@version as Version, 
  SERVERPROPERTY('productversion') as BuildNum, 
  SERVERPROPERTY ('productlevel') as ServicePack, 
  SERVERPROPERTY ('edition') as Edition
  

----------------------------------------------------------------------------------------------------------
----------------------------SQL SERVICES-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #5: SQL INSTALLED COMPONENTS
declare @e1 int
declare @sql3 varchar(2000)
declare @t1 table (Output varchar(2000))

set @e1 = (select cast(value_in_use as int) from sys.configurations where name = 'xp_cmdshell')
set @sql3 = 'exec xp_cmdshell ''wmic service where "Caption like ''''%SQL%''''" get Caption, Name, StartMode, StartName, State /format:csv'''

if @e1 = 1
begin
  insert into @t1
  exec(@sql3)

  select 5 as ScriptNum, @@servername as SQLInstance, 
  master.dbo.fSplit(',',Output,2) as Caption,
  master.dbo.fSplit(',',Output,3) as Name,
  master.dbo.fSplit(',',Output,4) as StartMode,
  master.dbo.fSplit(',',Output,5) as StartName,
  master.dbo.fSplit(',',Output,6) as State
  from @t1
  where isnull(Output,'') != ''
    and Output like '%SQL%'
end

if @e1 = 0
begin
  select 5 as ScriptNum, @@servername as SQLInstance, 'xp_cmdshell is not enabled' as Output
end


--SCRIPT #6: STARTUP PARAMETERS
declare @ins varchar(100)
declare @insid varchar(100)
declare @i int
declare @v varchar(10)
declare @sql4 varchar(500)
declare @t1a table (Value varchar(100), Value2 varchar(100), Data varchar(100))
declare @t2a table (Value varchar(100), Data varchar(100))
declare @t3a table (Value varchar(100), Data varchar(100))
declare @RegistryPath varchar(200)
set @RegistryPath = 'SOFTWARE\Microsoft\Microsoft SQL Server'

insert into @t1a
EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=@RegistryPath,@value_name='InstalledInstances'

while exists (select top 1 * from @t1a)
begin
  set @ins = (select top 1 Value2 from @t1a)
  set @RegistryPath = 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'

  insert into @t2a
  EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=@RegistryPath,@value_name=@ins
  delete from @t1a where Value2 = @ins
end

set @i = 1

while exists (select top 1 * from @t2a)
begin
  set @insid = (select top 1 Data from @t2a)
  set @RegistryPath = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @insid + '\MSSQLServer\Parameters'

while @i < 10
begin
  set @v = 'SQLArg' + CAST(@i as CHAR(1))
  set @sql4 = 'EXEC master..xp_regread @rootkey=''HKEY_LOCAL_MACHINE'' ,@key=''' + @RegistryPath + ''',@value_name=''' + @v + ''''
  --print(@sql)
  insert into @t3a
  exec(@sql4)
  set @i = @i + 1
end
  
  delete from @t2a where Data = @insid
end

select 6 as ScriptNum, @@SERVERNAME as SQLInstance, Data as StartupParameter from @t3a


--SCRIPT #7: TCP PORT
declare @ins2 varchar(100)
declare @insid2 varchar(100)
declare @i2 int
declare @v2 varchar(10)
declare @sql5 varchar(500)
declare @t1b table (Value varchar(100), Value2 varchar(100), Data varchar(100))
declare @t2b table (Value varchar(100), Data varchar(100))
declare @t2c table (Value varchar(100), Data varchar(100))
declare @t2d table (Value varchar(100), Data varchar(100))
declare @t3b table (Instance varchar(200), Value varchar(100), Data varchar(100))
declare @RegistryPath2 varchar(200)
set @RegistryPath2 = 'SOFTWARE\Microsoft\Microsoft SQL Server'

insert into @t1b
EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=@RegistryPath2,@value_name='InstalledInstances'

while exists (select top 1 * from @t1b)
begin
  set @ins2 = (select top 1 Value2 from @t1b)
  set @RegistryPath2 = 'SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL'

  insert into @t2b
  EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=@RegistryPath2,@value_name=@ins2
  delete from @t1b where Value2 = @ins2
end

set @i2 = 1

while exists (select top 1 * from @t2b)
begin
  set @insid2 = (select top 1 Data from @t2b)
  set @RegistryPath2 = 'SOFTWARE\Microsoft\Microsoft SQL Server\' + @insid2 + '\MSSQLServer\SuperSocketNetLib\Tcp\IPAll'
  
  insert into @t2c
  EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=@RegistryPath2,@value_name='TcpDynamicPorts'
  
  insert into @t2d
  EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=@RegistryPath2,@value_name='TcpPort'
  
  insert into @t3b
  select @insid2, value, data from @t2c
  
  insert into @t3b
  select @insid2, value, data from @t2d
  
  delete from @t2b where Data = @insid2
  delete from @t2c
  delete from @t2d
end

select 7 as ScriptNum, @@servername as SQLInstance, * from @t3b


--SCRIPT #8: ALIASES
declare @t5b table (Value varchar(100), Data varchar(100))
declare @k int
declare @kt table (KeyExist int)

insert into @kt
EXEC master..xp_regread @rootkey='HKEY_LOCAL_MACHINE' ,@key=N'SOFTWARE\\Microsoft\\MSSQLServer\\Client\\ConnectTo'

if (select KeyExist from @kt) = 1
begin
  insert into @t5b
  EXEC   master..xp_instance_regenumvalues
       @rootkey = N'HKEY_LOCAL_MACHINE',
       @key     = N'SOFTWARE\\Microsoft\\MSSQLServer\\Client\\ConnectTo'
end

select 8 as ScriptNum, @@servername as SQLInstance, * from @t5b


----------------------------------------------------------------------------------------------------------
----------------------------INSTANCE CONFIGURATIONS-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #9: SP_CONFIGURE
select 9 as ScriptNum, @@servername as SQLInstance,
  configuration_id,
  name,
  value,
  value_in_use
from msdb.sys.configurations

--SCRIPT #10: TRACE FLAGS ENABLED
declare @t1e table (TraceFlag int, Status int, Global int, Session int)
insert into @t1e
exec('DBCC TRACESTATUS')

if exists (select * from @t1e)
begin
  select 10 as ScriptNum, @@servername as SQLInstance, * from @t1e
end
else
begin
  select 10 as ScriptNum, @@servername as SQLInstance, 'No traces enabled' as Notes
end

----------------------------------------------------------------------------------------------------------
----------------------------DATABASES-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #11: DATABASE INVENTORY
select 
  11 as ScriptNum,
  @@servername as SQLInstance, 
  d1.name as DbName,
  d1.database_id as DbId,
  d1.compatibility_level,
  d1.collation_name,
  d1.user_access_desc,
  d1.state_desc,
  d1.recovery_model_desc,
  d1.page_verify_option_desc,
  d1.is_read_only,
  d1.is_auto_close_on,
  d1.is_auto_shrink_on,
  d1.is_in_standby,
  d1.snapshot_isolation_state_desc,
  d1.is_read_committed_snapshot_on,
  d1.is_auto_create_stats_on,
  d1.is_auto_update_stats_on,
  d1.is_auto_update_stats_async_on,
  d1.is_ansi_null_default_on,
  d1.is_ansi_nulls_on,
  d1.is_ansi_padding_on,
  d1.is_ansi_warnings_on,
  d1.is_arithabort_on,
  d1.is_concat_null_yields_null_on,
  d1.is_numeric_roundabort_on,
  d1.is_quoted_identifier_on,
  d1.is_recursive_triggers_on,
  d1.is_cursor_close_on_commit_on,
  d1.is_local_cursor_default,
  d1.is_fulltext_enabled,
  d1.is_trustworthy_on,
  d1.is_db_chaining_on,
  d1.is_parameterization_forced,
  d1.is_master_key_encrypted_by_server,
  d1.is_published,
  d1.is_subscribed,
  d1.is_merge_published,
  d1.is_distributor,
  d1.is_date_correlation_on,
  d1.is_cdc_enabled,
  d1.is_encrypted,
  d1.is_honor_broker_priority_on,
  s1.name as OwnerName
from sys.databases as d1
  left join sys.server_principals as s1 on d1.owner_sid = s1.sid

--SCRIPT #12: DATABASE FILES
declare @t1f table (DatabaseName varchar(100))
insert into @t1f
select name from master.sys.databases  
where state_desc = 'ONLINE'
  and name not in ('master','msdb')
  
if object_id('tempdb..#t2') is not null begin drop table #t2 end
create table #t2 (DatabaseName varchar(100), FileId int, FileName varchar(100), PhysicalName varchar(200), Type varchar(10), Drive char(1), 
	SizeMB decimal(17,4), UsedMB decimal(17,4), SizeGB decimal(17,4), UsedGB decimal(17,4),
	MaxSize bigint, Growth bigint, IsPercentGrowth bit)

declare @dbname varchar(100), @SQL6 varchar (8000)
set @SQL6=''

while exists (select top 1 * from @t1f t1)
begin
set @dbname = (select top 1 DatabaseName from @t1f t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name(), file_id, name, physical_name, type_desc, left(physical_name,1),
size/128.0 as SizeMB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0 as SpaceUsedMB,
size/128.0/1024 as SizeGB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0/1024 as SpaceUsedGB,
max_size, growth, is_percent_growth
FROM sys.database_files;'');');
delete from @t1f where DatabaseName = @dbname
end 

select 
  12 as ScriptNum,
  @@servername as SQLInstance,
  DatabaseName,
  FileId,
  FileName,
  PhysicalName,
  Type,
  Drive,
  SizeMB,
  UsedMB,
  SizeGB,
  UsedGB, 
  case when UsedMB = 0 then 0 
	   else cast(((cast(UsedMB as decimal(17,2))/cast(SizeMB as decimal(17,2)))*100) as decimal(8,4)) end as UsedPct,
  case when MaxSize = -1 then 'Unlimited'
	   else cast(MaxSize*8/1024 as varchar(20)) end as MaxSizeMB,
  case when IsPercentGrowth = 0 then Growth*8/1024 
       else NULL end as GrowthMB,
  case when IsPercentGrowth = 1 then Growth
       else NULL end as GrowthPct
from #t2
order by DatabaseName, Type, FileId

if object_id('tempdb..#t2') is not null begin drop table #t2 end



----------------------------------------------------------------------------------------------------------
----------------------------BACKUPS-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #13: BACKUP HISTORY
select distinct
  13 as ScriptNum,
  @@SERVERNAME as SQLInstance,
  b1.database_name, 
  b1.backup_start_date,
  b1.backup_finish_date,
  DATEDIFF(MINUTE,b1.backup_start_date,b1.backup_finish_date) as Duration,
  case when b1.type = 'D' then 'Full'
		when b1.type = 'L' then 'Log'
		when b1.type = 'I' then 'Diff' end as BackupType,
  cast(b1.backup_size/1024/1024/1024/media_family_count as decimal(18,2)) as SizeCompressGB,
  b2.software_name,
  case when b3.physical_device_name like 'VNBU%' then left(b3.physical_device_name,4) else b3.physical_device_name end as PhysicalDeviceName
from msdb.dbo.backupset as b1
  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
where 1=1
  and b1.backup_finish_date >= GETDATE()-30
order by b1.database_name, b1.backup_finish_date desc

----------------------------------------------------------------------------------------------------------
----------------------------SQL AGENT-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #14: JOBS
select 
14 as ScriptNum,
@@servername as SQLInstance, 
j1.name as job_name,
j1.enabled, 
s2.freq_type,
s2.freq_interval,
s2.freq_subday_type,
s2.freq_subday_interval,
active_start_time,
next_run_date,
next_run_time,
p1.name as job_owner
from msdb.dbo.sysjobs j1 (nolock)
  left join msdb.dbo.syscategories c1 (nolock) on j1.category_id = c1.category_id
  left join msdb.dbo.sysjobschedules s1 (nolock) on j1.job_id = s1.job_id
  left join msdb.dbo.sysschedules s2 (nolock) on s1.schedule_id = s2.schedule_id
  left join msdb.dbo.sysoperators o1 (nolock) on j1.notify_email_operator_id = o1.id
  left join msdb.sys.server_principals as p1 (nolock) on j1.owner_sid = p1.sid
where 1=1
order by job_name

--SCRIPT #15: JOB HISTORY
select 15 as ScriptNum, @@servername as SQLInstance, job_name, run_datetime, run_duration, run_stat
from
(
    select job_name, run_datetime,
        SUBSTRING(run_duration, 1, 2) + ':' + SUBSTRING(run_duration, 3, 2) + ':' +
        SUBSTRING(run_duration, 5, 2) AS run_duration, 
        case when run_status = 0 then 'Failed' when run_status = 1 then 'Succeeded' else 'Other' end as run_stat
    from
    (
        select distinct
            j.name as job_name, 
            run_datetime = CONVERT(DATETIME, RTRIM(run_date)) +  
                (run_time * 9 + run_time % 10000 * 6 + run_time % 100 * 10) / 216e4,
            run_duration = RIGHT('000000' + CONVERT(varchar(6), run_duration), 6), run_status
        from msdb..sysjobhistory h
        inner join msdb..sysjobs j
        on h.job_id = j.job_id
    ) t
) t
where run_datetime >= getdate() - 30
order by job_name, run_datetime


----------------------------------------------------------------------------------------------------------
----------------------------SECURITY-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #16: SCRIPT LOGINS (save as text file with SQL instance name)
--select 16 as ScriptNum, @@servername as SQLInstance, 'Logins scripted on Messages tab'
--print '--SCRIPT #15: SCRIPT LOGINS'
--exec master.dbo.sp_help_revlogin_roles


--SCRIPT #17: SERVER PRINCIPALS
select 17 as ScriptNum, @@servername as SQLInstance, name, type_desc, is_disabled, sid
from sys.server_principals
where name not like '##%'
order by type_desc, name

--SCRIPT #18: SERVER PRINCIPAL ROLE MEMBERS
select 18 as ScriptNum, @@servername as SQLInstance, sp.name, sp2.name
from sys.server_role_members srm
  left join sys.server_principals sp on srm.member_principal_id = sp.principal_id
  left join sys.server_principals sp2 on srm.role_principal_id = sp2.principal_id

--SCRIPT #19: DATABASE USERS AND MAPPING
declare @t1g table (DatabaseName varchar(100))
insert into @t1g
select name from master.sys.databases  
where state_desc = 'ONLINE'
  and collation_name = 'SQL_Latin1_General_CP1_CI_AS'

if object_id('tempdb..#t2_dbusers') is not null begin drop table #t2_dbusers end
create table #t2_dbusers (DbName varchar(100), PrincipalName varchar(100), PrincipalId int, Type varchar(50), DefaultSchemaName varchar(100), CreateDate datetime, ModifyDate datetime, DbSid varbinary(85), SrvSid varbinary(85))

declare @dbname7 varchar(100), @SQL7 varchar (8000)
set @SQL7=''

while exists (select top 1 * from @t1g as t1)
begin
set @dbname7 = (select top 1 DatabaseName from @t1g as t1)
EXEC(N'USE [' + @dbname7 + N']; EXEC(''insert into #t2_dbusers select db_name(), s1.name, s1.principal_id, s1.type_desc, default_schema_name, s1.create_date, s1.modify_date, s1.sid, s2.sid
from sys.database_principals as s1 left join master.sys.server_principals as s2 on s1.name = s2.name
;'');');
delete from @t1g where DatabaseName = @dbname7
end 

select 
  19 as ScriptNum,
  @@servername as SQLInstance, *, 
  case when DbSid is null then 'MappingNotReqd'
	   when DbSid = 0 then 'MappingNotReqd'
	   when SrvSid is null and Type = 'DATABASE_ROLE' then 'MappingNotReqd'
	   when SrvSid is null then 'NotMapped'
	   when SrvSid = DbSid then 'Mapped'
	   when SrvSid != DbSid then 'Orphaned'
  end as Mapping
from #t2_dbusers

if object_id('tempdb..#t2_dbusers') is not null begin drop table #t2_dbusers end

--SCRIPT #20: DATABASE PRINCIPAL ROLE MEMBERS
declare @t2h table (DatabaseName varchar(100))
insert into @t2h
select name from master.sys.databases  
where state_desc = 'ONLINE'

if object_id('tempdb..#t3_dbrm') is not null begin drop table #t3_dbrm end
create table #t3_dbrm (DbName varchar(100), PrincipalId int, PrincipalName varchar(100), RolePrincipalId int, RolePrincipalName varchar(100))

declare @dbname8 varchar(100), @SQL8 varchar (8000)
set @SQL8=''

while exists (select top 1 * from @t2h as t2)
begin
set @dbname8 = (select top 1 DatabaseName from @t2h as t2)
EXEC(N'USE [' + @dbname8 + N']; EXEC(''insert into #t3_dbrm select db_name() as DbName, drm.member_principal_id, dp.name, drm.role_principal_id, dp2.name
from sys.database_role_members drm
  left join sys.database_principals dp on drm.member_principal_id = dp.principal_id
  left join sys.database_principals dp2 on drm.role_principal_id = dp2.principal_id
;'');');
delete from @t2h where DatabaseName = @dbname8
end 

select 20 as ScriptNum, @@servername as SQLInstance, DbName, PrincipalName, RolePrincipalName
from #t3_dbrm

if object_id('tempdb..#t3_dbrm') is not null begin drop table #t3_dbrm end


--SCRIPT #21: LINKED SERVERS
select 21 as ScripNum, @@servername as SQLInstance, s1.name, s1.product, s1.provider, s1.data_source, s1.catalog, s2.remote_name
from sys.servers as s1
  left join sys.linked_logins as s2 on s1.server_id = s2.server_id

--SCRIPT #22: CREDENTIALS
select 22 as ScriptNum, @@servername as SQLInstance, name, credential_id, credential_identity from sys.credentials

--SCRIPT #23: PROXIES
select 23 as ScriptNum, @@servername as SQLInstance, name, credential_id, enabled, description, user_sid from msdb.dbo.sysproxies

--SCRIPT #24: TDE ASYMMETRIC KEYS
select 24 as ScriptNum, @@servername as SQLInstance, ak.name as KeyName, ak.asymmetric_key_id, ak.pvt_key_encryption_type_desc, ak.thumbprint, ak.algorithm_desc, ak.key_length, ak.sid, ak.provider_type, sp.name as Owner 
  from master.sys.asymmetric_keys as ak
    left join sys.server_principals as sp on ak.principal_id = sp.principal_id

--SCRIPT #25: TDE SYMMETRIC KEYS
select 25 as ScriptNum, @@servername as SQLInstance, ak.name as KeyName, ak.symmetric_key_id, ak.key_length, ak.key_algorithm, ak.algorithm_desc, ak.key_guid, ak.key_thumbprint, ak.provider_type, sp.name as Owner 
from master.sys.symmetric_keys as ak
  left join sys.server_principals as sp on ak.principal_id = sp.principal_id
where ak.name != '##MS_ServiceMasterKey##'




----------------------------------------------------------------------------------------------------------
----------------------------HADR-----------------------------
----------------------------------------------------------------------------------------------------------

--SCRIPT #26: LOGSHIPPING PRIMARY
if exists (select * from msdb.dbo.log_shipping_primary_databases)
begin
  select 26 as ScriptNum, @@servername as SQLInstance, p.primary_database, p.backup_directory, p.backup_share, p.backup_retention_period, p.backup_job_id, p.monitor_server, p.user_specified_monitor, p.monitor_server_security_mode, p.last_backup_file, p.last_backup_date, p.backup_compression, ps.secondary_server, ps.secondary_database
  from msdb.dbo.log_shipping_primary_databases as p
    left join msdb.dbo.log_shipping_primary_secondaries as ps on p.primary_id = ps.primary_id
end
else
begin
  select 26 as ScriptNum, @@servername as SQLInstance, 'No logshipping primary configured' as Notes
end

--SCRIPT #27 LOGSHIPPING SECONDARY
select 27 as ScriptNum, @@servername as SQLInstance, 
  s.primary_server, s.primary_database, s.backup_source_directory, s.backup_destination_directory, s.file_retention_period, s.copy_job_id,
  s.restore_job_id, s.monitor_server, s.monitor_server_security_mode, s.user_specified_monitor, s.last_copied_file, s.last_copied_date,
  sd.secondary_database	restore_delay, sd.restore_all, sd.restore_mode, sd.disconnect_users, sd.block_size, sd.buffer_count, sd.max_transfer_size, sd.last_restored_file, sd.last_restored_date
from msdb.dbo.log_shipping_secondary as s
  left join msdb.dbo.log_shipping_secondary_databases as sd on s.secondary_id = sd.secondary_id

--SCRIPT #28: MIRRORING
select 28 as ScriptNum, @@servername as SQLInstance, database_id, DB_NAME(database_id) as DbName, mirroring_state_desc, mirroring_role_desc, mirroring_safety_level_desc, mirroring_partner_name, mirroring_partner_instance, mirroring_witness_name, mirroring_witness_state_desc, mirroring_connection_timeout, mirroring_redo_queue, mirroring_redo_queue_type
from msdb.sys.database_mirroring where mirroring_guid is not null

--SCRIPT #29: REPLICATION
declare @sql9 varchar(2000)

if exists (select * from sys.databases where name = 'distribution')
begin
  set @sql9 = '
		select
		  29 as ScriptNum,
		  @@servername as SQLInstance,
		  t2.data_source as PubServer,
		  t1.publisher_db, 
		  t3.data_source as SubServer,
		  t1.subscriber_db,
		  case when t1.status = 0 then ''Inactive''
			   when t1.status = 1 then ''Subscribed''
			   when t1.status = 2 then ''Active'' end as Status
		from distribution..MSsubscriptions as t1
		  join sys.servers as t2 on t1.publisher_id = t2.server_id
		  join sys.servers as t3 on t1.subscriber_id = t3.server_id
		where t1.subscription_type = 0 
		  and subscriber_id > 0
		group by
		  t2.data_source,
		  t1.publisher_db, 
		  t3.data_source,
		  t1.subscriber_db,
		  case when t1.status = 0 then ''Inactive''
			   when t1.status = 1 then ''Subscribed''
			   when t1.status = 2 then ''Active'' end
		order by 1,2,3,4'
  exec(@sql9)
end
else
begin
  select 29 as ScriptNum, @@SERVERNAME as ServerName, 'Not a Replication distributor' as Notes
end

--SCRIPT #30: AVAILABILITY GROUPS
declare @sql10 varchar(2000)

if exists (select * from sysobjects where xtype = 'V' and name like 'availability_%')
begin
  set @sql10 = '
  if exists (select * from sys.availability_groups)
  begin
	  select 
	  30 as ScriptNum,
	  @@servername as SQLInstance,
	  ag.name as AGName,
	  ag.failure_condition_level,
	  ag.health_check_timeout, 
	  ag.automated_backup_preference_desc,
	  agl.dns_name as ListenerName,
	  aglip.ip_address as ListenerIP,
	  aglip.ip_subnet_mask as ListenerSubnetMask,
	  aglip.network_subnet_ip as ListenerSubnetIP,
	  aglip.network_subnet_ipv4_mask as ListenerSubnetIPv4Mask,
	  aglip.state_desc as ListenerStatus,
	  rep.replica_server_name,
	  rep.endpoint_url,
	  rep.availability_mode_desc,
	  rep.failover_mode_desc,
	  rep.session_timeout,
	  rep.primary_role_allow_connections_desc,
	  rep.secondary_role_allow_connections_desc,
	  rep.backup_priority,
	  rep.read_only_routing_url,
	  rorl.routing_priority
	from sys.availability_groups as ag
	  left join sys.availability_group_listeners as agl on ag.group_id = agl.group_id
	  left join sys.availability_group_listener_ip_addresses as aglip on agl.listener_id = aglip.listener_id
	  left join sys.availability_replicas as rep on agl.group_id = rep.group_id
	  left join sys.availability_read_only_routing_lists as rorl on rep.replica_id = rorl.replica_id
  end
  else
  begin
    select 30 as ScriptNum, @@SERVERNAME as ServerName, ''Not enabled for AlwaysOn Availability Groups'' as Notes
  end'
  exec(@sql10)
end
else
begin
  select 30 as ScriptNum, @@SERVERNAME as ServerName, 'Not enabled for AlwaysOn Availability Groups' as Notes
end




