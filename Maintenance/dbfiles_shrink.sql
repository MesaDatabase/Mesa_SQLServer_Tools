/***********************************************************
-- Description  : Shrink database files 

-- Modified	: 20190307
***********************************************************/

--update db name
use DB1;
go

-----------for transaction logs
--look at tlog file
select * from sys.database_files
where type = 1

--check tlog space
dbcc sqlperf(logspace)

--view vlfs for db
dbcc loginfo(DB1);

--shrink tlog file
dbcc shrinkfile(2);

--if that doesnt work:
--if there are vlfs at the end of the file with Status = 2, try running tlog backup, then shrink again; repeat until the file shrinks


-----------for data files
--look at files
select * from sys.database_files
where type = 0

--shrink data file (update fileid)
dbcc shrinkfile(1);

--if regular shrink doesnt work, update to logical file name and try this
DBCC SHRINKFILE (N'tempdev', NOTRUNCATE) -- Move allocated pages from end of file to top of file, only works on data files




/* DO NOT RUN THESE ON PRODUCTION UNLESS ABSOLUTELY NECESSARY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--DBCC FREEPROCCACHE 
Removes all elements from the plan cache, removes a specific plan from the plan cache by specifying a plan handle or SQL handle, 
or removes all cache entries associated with a specified resource pool.

--DBCC FREESYSTEMCACHE ('ALL') 
Releases all unused cache entries from all caches. 
The SQL Server Database Engine proactively cleans up unused cache entries in the background to make memory available for current entries. 
However, you can use this command to manually remove unused entries from every cache or from a specified Resource Governor pool cache.
	--select distinct name from sys.dm_os_memory_clerks 
	--DBCC FREESYSTEMCACHE('SQL Plans') --clears ad-hoc plans
	--DBCC FREESYSTEMCACHE('TokenAndPermUserStore') --clears out mem consumed by the security cache for creation of objects in tempdb

--DBCC FREESESSIONCACHE
Removes all queries from the distributed query cache

--DBCC DROPCLEANBUFFERS
Removes all clean buffers from the buffer pool, and columnstore objects from the columnstore object pool
Use DBCC DROPCLEANBUFFERS to test queries with a cold buffer cache without shutting down and restarting the server.
To drop clean buffers from the buffer pool and columnstore objects from the columnstore object pool, first use CHECKPOINT to produce a cold buffer cache. This forces all dirty pages for the current database to be written to disk and cleans the buffers. After you do this, you can issue DBCC DROPCLEANBUFFERS command to remove all buffers from the buffer pool.
*/