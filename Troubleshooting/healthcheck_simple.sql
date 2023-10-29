-----------------------------------------------------------
--Health check (SIMPLE)
--		MULTI-SERVER
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