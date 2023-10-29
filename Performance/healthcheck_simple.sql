-----------------------------------------------------------
--Health check (SIMPLE)
--		MULTI-SERVER
--	Run entire script at once
-----------------------------------------------------------

--Validate all databases are online and accessible
select
  @@servername, name, user_access_desc, is_read_only,
  state_desc, recovery_model_desc, page_verify_option_desc
from master.sys.databases

--Validate that the database instances are connected
select @@servername, * from sys.dm_db_mirroring_connections

--Validate that mirroring sessions are synchronized, check timeout value, validate metrics are within parameters
use master
go

set nocount on

declare @db varchar(500)
declare @sql varchar(500)

create table #t2 (DatabaseName varchar(100), Role bit, MirroringState int, WitnessStatus tinyint, LogGenerationKBPerSec bigint, UnsentLogKB bigint, SendRateKBPerSec bigint, UnrestoredLogKB bigint, RecoveryRateKBPerSec bigint, TransactionDelayMs bigint, PrincipalTransactionsPerSec bigint, AverageDelayPerTransaction bigint, TimeRecorded datetime, TimeBehind datetime, LocalTime datetime)

declare @t1 table (DbId int, DbName varchar(255))
insert into @t1
select database_id, DB_NAME(database_id)
from sys.database_mirroring
where database_id > 4
  and mirroring_guid is not null
order by DB_NAME(database_id)  

while exists (select * from @t1 t1)
begin
	set @db = (select top 1 DbName from @t1 t1)
	set @sql = 'exec msdb.dbo.sp_dbmmonitorresults @database_name = ''' + @db + ''';'
	
	insert into #t2
	exec(@sql)

	delete from @t1 where DbName = @db
end	

select 
  DatabaseName,
  case when Role = 1 then 'Principal' else 'Mirror' end as Role,
  case when MirroringState = 0 then 'Suspended'
	   when MirroringState = 1 then 'Disconnected'
	   when MirroringState = 2 then 'Synchronizing'
	   when MirroringState = 3 then 'Pending Failover'
	   when MirroringState = 4 then 'Synchronized' end as MirroringState,
  mirroring_safety_level_desc as SafetyLevel, 
  mirroring_connection_timeout as MirroringConnectionTimeout,
  LogGenerationKBPerSec,
  UnsentLogKB,
  SendRateKBPerSec,
  UnrestoredLogKB,
  RecoveryRateKBPerSec, 
  TransactionDelayMs, 
  PrincipalTransactionsPerSec, 
  AverageDelayPerTransaction, 
  TimeRecorded, 
  TimeBehind
from #t2 as t2
  join sys.database_mirroring as dm1 on t2.DatabaseName =DB_NAME(dm1.database_id)
drop table #t2


--Check logs for errors/corruption
declare @temp table (LogDate datetime, ProcessInfo char(8), Text varchar(max))
insert into @temp
exec master.dbo.xp_readerrorlog 0, 1, N'error', NULL, NULL, NULL, N'desc' 
insert into @temp
exec master.dbo.xp_readerrorlog 0, 1, N'fail', NULL, NULL, NULL, N'desc' 
insert into @temp
exec master.dbo.xp_readerrorlog 0, 1, N'inaccessible', NULL, NULL, NULL, N'desc'

select @@servername, * from @temp t1
where 1=1
  and LogDate >= GETDATE() - 1 --last day
  --and LogDate >= GETDATE() - .0013888 --last 2 minutes
  and Text not like 'The error log has been reinitialized%'
  and Text not like 'Logging SQL Server messages in file%'
  and Text not like 'DBCC CHECKDB%'
  and Text not like 'CHECKDB%'
  and Text not like '%ERRORLOG'
  and Text not like 'Registry startup parameters%'
  
--Check Windows logs - manually
  
--Validate server authentication mode is mixed
select @@servername, 
	   case SERVERPROPERTY('IsIntegratedSecurityOnly')   
		when 1 then 'Windows Authentication'   
		when 0 then 'Windows and SQL Server Authentication'   
	   end as AuthMode 
  
--Other health checks  


--last full backup
set nocount on

declare @t4 table (DatabaseName varchar(100))
insert into @t4
select name from master.dbo.sysdatabases 

create table #t5 (database_name varchar(100), backup_start_date datetime, backup_finish_date datetime, Duration int, BackupType varchar(10), SizeCompressGB numeric(8,4), Software varchar(255), physical_device_name varchar(500))

declare @dbname varchar(50), @SQL0 varchar (8000), @backup_set_id int
set @SQL0=''

while exists (select top 1 * from @t4 t4)
begin
set @dbname = (select top 1 DatabaseName from @t4 t4)
set @backup_set_id = (select top 1 backup_set_id from msdb.dbo.backupset where database_name = @dbname and type = 'D' order by backup_start_date desc)

insert into #t5
select top 1
  b1.database_name, 
  b1.backup_start_date,
  b1.backup_finish_date,
  DATEDIFF(MINUTE,b1.backup_start_date,b1.backup_finish_date) as Duration,
  case when b1.type = 'D' then 'Full'
		when b1.type = 'L' then 'Log'
		when b1.type = 'I' then 'Diff' end as BackupType,
  cast(b1.compressed_backup_size/1024/1024/1024/media_family_count as decimal(18,2)) as SizeCompressGB,
  b2.software_name,
  case when b3.physical_device_name like 'VNBU%' then left(b3.physical_device_name,4) else b3.physical_device_name end as PhysicalDeviceName
from msdb.dbo.backupset as b1
  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
where 1=1
  and b1.type = 'D'
  and b1.database_name = @dbname
  and backup_set_id = @backup_set_id
order by b1.backup_start_date desc

delete from @t4 where DatabaseName = @dbname
end 

select @@servername as server, * from #t5
drop table #t5




/*
LogGenerationKBPerSec: Amount of log generated since preceding update of the mirroring status of this database in kilobytes/sec.
UnsentLogKB: Size of the unsent log in the send queue on the principal in kilobytes.
SendRateKBPerSec: Send rate of log from the principal to the mirror in kilobytes/sec.
UnrestoredLogKB: Size of the redo queue on the mirror in kilobytes.
RecoveryRateKBPerSec: Redo rate on the mirror in kilobytes/sec.
TransactionDelayMs: Total delay for all transactions in milliseconds.
PrincipalTransactionsPerSec: Number of transactions that are occurring per second on the principal server instance.
AverageDelayPerTransaction: Average delay on the principal server instance for each transaction because of database mirroring. In high-performance mode (that is, when the SAFETY property is set to OFF), this value is generally 0.
TimeRecorded: Time at which the row was recorded by the database mirroring monitor. This is the system clock time of the principal.
TimeBehind: Approximate system-clock time of the principal to which the mirror database is currently caught up. This value is meaningful only on the principal server instance. 
*/