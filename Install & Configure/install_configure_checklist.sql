------------------------------------------HARDWARE------------------------------------------

--CPU COUNT
select cpu_count as virtual_cpu_count, cpu_count/hyperthread_ratio as physical_cpu_count FROM sys.dm_os_sys_info

select * from sys.configurations
where configuration_id in (1550,1535,1551,1549,1538,1539)
order by name

--wmic cpu get name,NumberOfCores,NumberOfLogicalProcessors
--Num of Cores: 1 – MAXDOP: 1
--Num of Cores: 2 – MAXDOP: 1
--Num of Cores: 4 – MAXDOP: 2
--Num of Cores: 6 – MAXDOP: 4
--Num of Cores: >=8 – MAXDOP: 4

sp_configure 'show advanced options', 1
GO
RECONFIGURE
GO
sp_configure 'max degree of parallelism', 1
GO
RECONFIGURE
GO
sp_configure 'Agent XPs', 1
GO
RECONFIGURE
GO
sp_configure 'cost threshold for parallelism', 25
GO
RECONFIGURE
GO

--MEMORY
select 
  physical_memory_in_bytes/1024/1024 AS physical_memory_mb, 
  virtual_memory_in_bytes/1024/1024 AS virtual_memory_in_mb, 
  bpool_committed*8/1024 AS bpool_committed_mb,  --committed physical memory in the buffer pool
  bpool_commit_target*8/1024 AS bpool_commit_targt_mb, --needed physical RAM in buffer pool
  bpool_visible*8/1024  AS bpool_visible_mb  --total size of all buffers in the buffer pool that can be directly addressed
--select * 
FROM sys.dm_os_sys_info

--sql2012 version
select 
  physical_memory_kb/1024 AS physical_memory_mb, 
  virtual_memory_kb/1024 AS virtual_memory_in_mb, 
  committed_kb*8/1024 AS bpool_committed_mb,  --committed physical memory in the buffer pool
  committed_target_kb*8/1024 AS bpool_commit_targt_mb, --needed physical RAM in buffer pool
  visible_target_kb*8/1024  AS bpool_visible_mb  --total size of all buffers in the buffer pool that can be directly addressed
--select * 
FROM sys.dm_os_sys_info

--MEMORY CONFIGS
select * from sys.configurations
where configuration_id in (1505,1544,1540,1543,1541,1548)
order by name

sp_configure 'min server memory'
go
sp_configure 'max server memory',28672
go
sp_configure 'min memory per query'
go
sp_configure 'query wait'
go

--Turn off advanced options
sp_configure 'show advanced options', 0
GO
RECONFIGURE
GO

--INTERNAL MEMORY DISTRIBUTION
dbcc memorystatus

--DRIVES AND FREE SPACE
EXEC master.dbo.xp_fixeddrives

--SAN PERMISSIONS
--security permissions on SAN drives should be System and Administrators

--BLOCK SIZE
--format all SAN drives to NTFS data/tlog/tempdb 64KB, C&D 4KB
--wmic volume get name, blocksize
--reformat from command line
----format I: /A:64k
--quick format
----format I: /A:64k /q


------------------------------------------SERVER------------------------------------------

--SQL SERVER SERVICE ACCOUNT
----can set initially to LocalSystem
----needs to be a domain user account with Admin priviledges to server
----needs a corresponding sql login with sysadmin privs
----If using firewall: inbound rules-> new rule-> rule type = port-> protocal and ports = tcp->specific local ports=1433-> action = allow connection-> profile,name
----Verify autostart of all SQL Services

--LOCK PAGES IN MEMORY
----lock pages in memory enabled for SQL service account (tells Windows not to swap out SQL Server memory to disk)
------Admin Tools -> Local Security Policy -> Local Policies -> User Rights Assigment - Properties of Lock pages in memory
------click on Add User or group, add sql server service accounts

--DISABLE UNNECCESSARY SERVICES

--EXCLUDE DB FILES FROM VIRUS SCAN
----dat, db, dbf, ebd, ifs, ldf, log, mdf, ndf, odf, lock, ora


------------------------------------------SQL SERVER PROPERTIES------------------------------------------

--VERSION
SELECT @@version, SERVERPROPERTY('productversion'), SERVERPROPERTY ('productlevel'), SERVERPROPERTY ('edition')

--SERVER NAME AND INSTANCE PROPERTIES
SELECT @@SERVERNAME As [@@SERVERNAME], CAST(SERVERPROPERTY('MACHINENAME') AS VARCHAR(128)) + COALESCE('' +CAST(SERVERPROPERTY('INSTANCENAME') AS VARCHAR(128)), '') As RealInstanceName,
  CASE WHEN SERVERPROPERTY('IsClustered') = 1 THEN 'CLUSTERED' ELSE 'STANDALONE' END AS ServerType

--UPDATE SERVER NAME
----sp_dropserver 'SQL2K5SWSRV', null
----sp_helpserver
----sp_addserver 'SQL2K5SWPROD','LOCAL' 
----sp_helpserver
----restart sql services

--SQL CONFIGURATIONS
--configs_differ_from_2012defaults.sql
SELECT * FROM sys.configurations ORDER BY name

--RECONFIGURE
----sp_configure 'show advanced options', 1
----GO
----RECONFIGURE
----GO

--SQL SERVER LAST RESTART
SELECT sqlserver_start_time FROM sys.dm_os_sys_info

--ENABLED TRACE FLAGS
DBCC TRACESTATUS

--TURN ON TRACE FLAGS GLOBALLY
--1222: logs deadlock info in xml format
--3605: sends trace output to the error log
--8207: an update to a unique column that affects only one row (a singleton update) is replicated as an UPDATE and not as a DELETE or INSERT pair. If the update affects a column on which has a unique constraint or if the update affects multiple rows, the update is still replicated as a DELETE or INSERT pair.
----DBCC TRACEON (1118,-1)

--IS DEFAULT TRACE RUNNING
SELECT * FROM sys.configurations WHERE configuration_id = 1568

--ENABLE DEFAULT TRACE
----sp_configure 'default trace enabled', 1;
----GO
----RECONFIGURE;
----GO

--COLLATION
--collation.sql

------------------------------------------DATABASES------------------------------------------

--DBS AND THEIR PROPERTIES
select d.*, sp.name as owner
--select *
from sys.databases d
  join sys.server_principals sp on d.owner_sid = sp.sid

--CHANGE DB RECOVERY MODEL
USE [master]
GO
ALTER DATABASE [model] SET RECOVERY SIMPLE WITH NO_WAIT
GO

--TURN OFF ASYNC AUTO UPDATE STATS
USE [master]
GO
ALTER DATABASE CMCDB_PROD set AUTO_UPDATE_STATISTICS_ASYNC OFF

--CHANGE PAGE VERIFY TO CHECKSUM
USE [master]
GO
ALTER DATABASE [AMDBR] SET PAGE_VERIFY CHECKSUM  WITH NO_WAIT
GO

--CHANGE DB OWNER
EXEC sp_changedbowner 'sa'

--DB FILEGROUPS
EXEC master.dbo.sp_MSforeachdb @command1 = 'USE [?] SELECT db_name(), * FROM sys.filegroups'

--DB FILES AND THEIR PROPERTIES
--database_files_space_used.sql
----(autogrowth settings)
----(num of db/log files)
----(location)
----(size)

--MOVE TEMPDB
----restart SQL services after running code, then remove old log files
USE tempdb
GO
sp_helpfile

USE master
GO
ALTER DATABASE tempdb MODIFY FILE (NAME = tempdata, FILENAME = 'T:\MSSQL\Data\tempdb.mdf')
GO
ALTER DATABASE tempdb MODIFY FILE (NAME = templog, FILENAME = 'S:\MSSQL\Tlog\tempdb.ldf')
GO

--ADD FILES TO TEMPDB
----number of tempdb files = number of physical cpus and of equal size with same filegrowth settings

--USER OBJECTS IN SYSTEM DBS
SELECT *
FROM msdb.sys.tables
WHERE is_ms_shipped = 0 


------------------------------------------SECURITY------------------------------------------

--security_audit.sql
--SYSADMINS
select * from master.sys.syslogins
where sysadmin = 1
  and name <> SUSER_SNAME(0x01)
  and denylogin = 0

--ALL OTHER LOGINS
select name, denylogin, isntname, isntgroup, isntuser from master.dbo.syslogins
where sysadmin != 1 and securityadmin != 1 and name not like '##%'

--DB GUEST ACCOUNT SHOULD HAVE NO ROLES
--security_guest_roles.sql

--REMOVE ROLES FROM GUEST
----REVOKE CONNECT FROM GUEST

--REMOVE BUILTIN\ADMINISTRATORS LOGIN


------------------------------------------BACKUPS------------------------------------------

--LAST FULL BACKUP
select top 1 me.physical_device_name, bu.*
from msdb.dbo.backupset bu
  left join msdb.dbo.backupmediafamily me on bu.media_set_id = me.media_set_id
where bu.type = 'D' 
order by backup_start_date desc

--CHECK BACKUP SCHEDULES (FULL & TLOG)


------------------------------------------JOBS/MAINTENANCE/MONITORING------------------------------------------

--CHECK FOR JOBS WITH OVERLAPPING SCHEDULES
--INTEGRITY CHECK
--ERROR LOG CYCLE
--REINDEXING
--STATS UPDATE
--ALERTS FOR ERRORS 823, 824, 825; SEVERITY LEVELS 21-25
--DBMAIL


------------------------------------------INDEXES------------------------------------------

--index_audit.sql
----tables without clustered indexes


------------------------------------------HADR------------------------------------------

--SET UP MIRRORING OR AG

