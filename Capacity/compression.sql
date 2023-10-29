-- List all user tables and indexes
SELECT OBJECT_NAME(object_id) AS [ObjectName], [rows], data_compression_desc, index_id
FROM sys.partitions
WHERE LEFT(OBJECT_NAME(object_id),3) <> 'sys'    -- try to eliminate nonuser objects
AND LEFT(OBJECT_NAME(object_id),5) <> 'queue'
AND LEFT (OBJECT_NAME(object_id),10) <> 'filestream'
ORDER BY ObjectName;

-- List compressed tables and indexes
SELECT OBJECT_NAME(object_id) AS [ObjectName], [rows], data_compression_desc, index_id
FROM sys.partitions
WHERE data_compression > 0
ORDER BY ObjectName;

-- Most active indexes and tables for writes
SELECT objectname = OBJECT_NAME(s.object_id), indexname = i.name, i.index_id,
        reads=range_scan_count + singleton_lookup_count,
        'leaf_writes' = leaf_insert_count+leaf_update_count+ leaf_delete_count, 
        'leaf_page_splits' = leaf_allocation_count,
        'nonleaf_writes' = nonleaf_insert_count + nonleaf_update_count + nonleaf_delete_count,
        'nonleaf_page_splits' = nonleaf_allocation_count
FROM sys.dm_db_index_operational_stats (db_id(),NULL,NULL,NULL) AS s
INNER JOIN sys.indexes AS i
ON i.object_id = s.object_id
WHERE OBJECTPROPERTY(s.object_id,'IsUserTable') = 1
AND i.index_id = s.index_id
ORDER BY leaf_writes DESC, nonleaf_writes DESC

-- Check how much space you might save with PAGE data compression
EXEC sp_estimate_data_compression_savings  'WorkItem', 'Attribute', NULL, NULL, 'PAGE';

-- Check how much space you might save with ROW data compression
EXEC sp_estimate_data_compression_savings 'WorkItem', 'Attribute', NULL,NULL,'ROW';
