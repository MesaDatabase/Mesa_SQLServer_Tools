--check tlog
--context = LCX_HEAP are data pages
--context = LCX_PFS are Page Free Space pages, tracking page allocation and available free space on pages
--context = LCX_DIFF_MAP are Differential Changed Map, tracking extents that have changes since the last database backup (to facilitate differential backups)

SELECT  Operation ,
        Context ,
        AllocUnitName ,
   --   Description ,
        [Log Record Length] ,
        [Log Record]
FROM    fn_dblog(NULL, NULL)
where AllocUnitName = 'dbo.SomeTable'
  and Context = 'LCX_HEAP'

--the log records (LCX_HEAP) describing the changes to SomeTable are all of type LOP_FORMAT_PAGE
----if they always appear in sets of 8, that means SQL Server was processing the insert one extent at a time and writing one log record for each page
----if each one is 8276 bytes long, that means each one contains the image of an entire page plus log headers








--if a hardware glitch causes some data corruption, but the db is still online and we wish to restore over that databas
--perform a tail log backup to capture the remaining contents of the log file and put the db into a restoring state, so that no further transactions against that db will succeed
BACKUP LOG...WITH NORECOVERY

--if the damage to the data file is severe enough that the db becomes unavailable and an attempt to bring it back online fails
--and if the db is in FULL recovery model, with regular log backups
--then as long as the log file is still available we can take a tail log backup
--using the NO_TRUNCATE	option instead which backs up the log file without truncating it and doesn't require the db to be online
--NO_TRUNCATE implies COPY_ONLY and CONTINUE_AFTER_ERROR
BACKUP LOG...WITH NO_TRUNCATE





--practice restoring db after simulated HW failure

USE master
GO
IF DB_ID('FullRecovery') IS NOT NULL 
    DROP DATABASE FullRecovery;
GO

-- Clear backup history
EXEC msdb.dbo.sp_delete_database_backuphistory 
    @database_name = N'FullRecovery'
GO

CREATE DATABASE FullRecovery ON
(NAME = FullRecovery_dat,
  FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\FullRecovery.mdf'
) LOG ON
(
  NAME = FullRecovery_log,
  FILENAME = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\DATA\FullRecovery.ldf'
);

ALTER DATABASE FullRecovery SET RECOVERY FULL
GO

BACKUP DATABASE FullRecovery TO DISK = 'C:\Program Files\Microsoft SQL Server\MSSQL11.MSSQLSERVER\MSSQL\Backup\FullRecovery.bak'
WITH INIT
GO









