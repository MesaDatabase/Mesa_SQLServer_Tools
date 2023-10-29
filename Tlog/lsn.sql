dbcc sqlperf(logspace)
dbcc loginfo( DB1)
select * from fn_dblog(null, null);


select top 10 * from msdb.dbo.backupset where database_name = 'DB1' order by backup_start_date desc
select top 10 * from msdb.dbo.backupfile where logical_name like '% DB1%'
select * from sys.database_files
select * from sys.master_files where database_id = 11

sys.database_recovery_status 

the first part is the VLF sequence number. 
the middle part is the offset to the log block 
the last part is the slot number inside the log block 

000b3b77:000a7fe8:0001
000b3b77:000a7fe8:0021
000b3b77:000a7fee:0001

SET NOCOUNT ON
DECLARE @LSN NVARCHAR(46)
DECLARE @LSN_HEX NVARCHAR(25)
DECLARE @tbl TABLE (id INT identity(1,1), i VARCHAR(10))
DECLARE @stmt VARCHAR(256)

SET @LSN = (SELECT TOP 1 [Current LSN] FROM fn_dblog(NULL, NULL))
PRINT @LSN

SET @stmt = 'SELECT CAST(0x' + SUBSTRING(@LSN, 1, 8) + ' AS INT)'
INSERT @tbl EXEC(@stmt)
SET @stmt = 'SELECT CAST(0x' + SUBSTRING(@LSN, 10, 8) + ' AS INT)'
INSERT @tbl EXEC(@stmt)
SET @stmt = 'SELECT CAST(0x' + SUBSTRING(@LSN, 19, 4) + ' AS INT)'
INSERT @tbl EXEC(@stmt)

SET @LSN_HEX =
(SELECT i FROM @tbl WHERE id = 1) + ':' + (SELECT i FROM @tbl WHERE id = 2) + ':' + (SELECT i FROM @tbl WHERE id = 3)
PRINT @LSN_HEX

SELECT *
FROM ::fn_dblog(@LSN_HEX, NULL) 

