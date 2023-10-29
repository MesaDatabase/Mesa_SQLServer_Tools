--check for consistency errors suppress messages
DBCC CHECKDB ('DB Name') WITH NO_INFOMSGS

--check for consistency errors physical, on-disk structures only
DBCC CHECKDB ('DB Name') WITH PHYSICAL_ONLY

/* If Problem Found
  1. Look at output of CHECKDB to find what page is corrupted
      Page (1:94299) could not be processed
  2. See if the corrupted page is data in a heap, a clustered-index or a non-clustered index
      From CHECKDB message, identify Object ID and index id
      Run DBCC PAGE on the corrupted page
*/

--check what data the corrupted page holds, new window
DBCC TRACEON (3604,-1)
GO
DBCC PAGE('yourdb',1,94299,3)
GO 

/* Look at DBCC PAGE output for Metadata: IndexId = n
  1. n > 1 is a non-clustered index and can be safely dropped and recreated
  2. n = 0 or 1, then it is a data page or a clustered index, continue with options below
*/

/* Restore From Backup
  1. If recovery model is FULL, backup the tail of the log and perform a restore from last clean backup with norecovery followed by all log backups and the tail of the log
  2. If only a few pages are affected, you can restore just those pages:
		RESTORE DATABASE yourdb PAGE = '1:94299'
		FROM DISK = 'C:\yourdb.bak'
		WITH NORECOVERY
  3. If recovery model is SIMPLE, restore from the last full backup will result in transactions being lost.  Try Automatic Repair.
*/

/* Automatic Repair Options
  1. Run a full backup of the database with the corrupted pages before going any further
  2. Look at output of CHECKDB - it will specify the minimum repair level
  3. If minimum repair level is REPAIR_REBUILD:
		DBCC CHECKDB('DB_Name', REPAIR_REBUILD)
  4. !!!!!!!!!!!!!!!!!!!!!!!!LAST RESORT!!!!!!!!!!!!!!!!!!!!!!!! REPAIR_ALLOW_DATA_LOSS: 
		This attempts to repair all errors.  
		Sometimes the only way to repair an error is to deallocate the affected page and modify page links so that it looks like the page never existed. 
		This has the desired effect of restoring the database's structural integrity but means that something has been deleted. 
		There are likely to be issues with referential integrity, not to mention the important data that may now be missing.  
		DBCC CHECKDB('DB_Name', REPAIR_ALLOW_DATA_LOSS)
  5. Look for referential integrity issues and take appropriate action
		DBCC CHECKCONSTRAINTS ('DB_Name')
*/