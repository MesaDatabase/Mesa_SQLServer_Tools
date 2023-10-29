--memory usage by object for specified db
declare @dbname varchar(50)
set @dbname = 'AMDBR'

SELECT
    OBJECT_NAME(t3.object_id) AS 'ObjectName',
    t3.object_id,
    COUNT(*) * 8/1024.0 AS '[Buffer Size (MB)]',
    COUNT(*) AS 'buffer_count'
FROM sys.allocation_units t1
INNER JOIN sys.dm_os_buffer_descriptors t2 ON (t1.allocation_unit_id = t2.allocation_unit_id)
INNER JOIN sys.partitions t3 ON (t1.container_id = t3.hobt_id)
INNER JOIN sys.objects t4 ON (t3.object_id = t4.object_id)
WHERE (t2.database_id = db_id(@dbname)) 
  AND (t4.type = 'U')
GROUP BY t3.object_id
ORDER BY 3 DESC;