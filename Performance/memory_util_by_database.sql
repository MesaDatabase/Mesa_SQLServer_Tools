--memory consumption by database
SELECT
    DB_NAME(database_id) AS [Database Name],
    COUNT(*) * 8/1024.0 AS [Buffer Size (MB)]
--select *
FROM sys.dm_os_buffer_descriptors
WHERE (database_id > 4) AND (database_id <> 32767)
GROUP BY DB_NAME(database_id)
ORDER BY 2 DESC
