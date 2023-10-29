-----high CACHESTORE_SQLCP found by running


--determine what plans are in the cache and how often they're used

SELECT  TOP 6
 LEFT([name], 20) as [name],
 LEFT([type], 20) as [type],
 [single_pages_kb] + [multi_pages_kb] AS cache_kb,
 [entries_count]
FROM sys.dm_os_memory_cache_counters 
order by single_pages_kb + multi_pages_kb DESC

--CACHESTORE_OBJCP are compiled plans for stored procedures, functions and triggers. 
--CACHESTORE_SQLCP are cached SQL statements or batches that aren't in stored procedures, functions and triggers.  This includes any dynamic SQL or raw SELECT statements sent to the server. 
--CACHESTORE_PHDR  These are algebrizer trees for views, constraints and defaults.  An algebrizer tree is the parsed SQL text that resolves the table and column names.



