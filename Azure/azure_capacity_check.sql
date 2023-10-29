--get elastic pool max size and used space
--connect to master
SELECT top 1 
	elastic_pool_storage_limit_mb AS ElasticPoolMaxSizeInMB, 
	elastic_pool_storage_limit_mb/1024 as ElasticPoolMaxSizeInGB,
	avg_storage_percent / 100.0 * elastic_pool_storage_limit_mb AS ElasticPoolDataSpaceUsedInMB,
	avg_storage_percent / 100.0 * (elastic_pool_storage_limit_mb/1024) AS ElasticPoolDataSpaceUsedInGB,
	*
FROM sys.elastic_pool_resource_stats
WHERE elastic_pool_name = 'npdtsuseamdapsqlelp'
ORDER BY end_time DESC


-- Database data space allocated in MB and database data space allocated unused in MB
--connect to database
SELECT 
	SUM(size/128.0) AS DatabaseDataSpaceAllocatedInMB,
	SUM(size/128.0)/1024 AS DatabaseDataSpaceAllocatedInGB,
	SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0) AS DatabaseDataSpaceAllocatedUnusedInMB,
	SUM(size/128.0 - CAST(FILEPROPERTY(name, 'SpaceUsed') AS int)/128.0)/1024 AS DatabaseDataSpaceAllocatedUnusedInGB
FROM sys.database_files
GROUP BY type_desc
HAVING type_desc = 'ROWS'


-- Database data max size in bytes
--connect to database
SELECT DATABASEPROPERTYEX('db1', 'MaxSizeInBytes') AS DatabaseDataMaxSizeInBytes,
	DATABASEPROPERTYEX('db1', 'MaxSizeInBytes')/1024/1024 AS DatabaseDataMaxSizeInMBs,
	DATABASEPROPERTYEX('db1', 'MaxSizeInBytes')/1024/1024/1024 AS DatabaseDataMaxSizeInGB

--shrink to reclaim allocated but unused space
--connect to database
dbcc shrinkdatabase (N'npduseamdapsqldbDW')