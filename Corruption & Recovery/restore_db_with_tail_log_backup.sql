USE master;
BACKUP DATABASE TestDB
TO DISK ='C:\Backups\TestDB.bak'
WITH INIT;
GO

-- Perform a transaction log backup of the Test database
BACKUP Log TestDB
TO DISK ='C:\Backups\TestDB_log.bak'
WITH INIT;
GO

-- ....<FAILURE OCCURS HERE>....

-- Back up the tail of the log to prepare for restore
BACKUP Log TestDB
TO DISK ='C:\Backups\TestDB_taillog.bak'
WITH NORECOVERY, INIT;
GO

-- Restore the full backup
RESTORE DATABASE TestDB
FROM DISK = 'C:\Backups\TestDB.bak'
WITH NORECOVERY;

-- Apply the transaction log backup
RESTORE LOG TestDB
FROM DISK = 'C:\Backups\TestDB_log.bak'
WITH NORECOVERY;

-- Apply the tail log backup
RESTORE LOG TestDB
FROM DISK = 'C:\Backups\TestDB_taillog.bak'
WITH NORECOVERY;

-- Recover the database
RESTORE DATABASE TestDB
WITH RECOVERY;
