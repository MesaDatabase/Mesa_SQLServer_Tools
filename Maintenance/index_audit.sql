--find tables without clustered indexes
SELECT SCHEMA_NAME(o.schema_id) AS [schema]
	,object_name(i.object_id ) AS [table]
    ,p.rows
    ,user_seeks
    ,user_scans
    ,user_lookups
    ,user_updates
    ,last_user_seek
    ,last_user_scan
    ,last_user_lookup
FROM sys.indexes i 
	INNER JOIN sys.objects o ON i.object_id = o.object_id
    INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id
    LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id
WHERE i.type_desc = 'HEAP'
ORDER BY rows desc

--find indexes not in use
SELECT 
o.name
, indexname=i.name
, i.index_id   
, reads=user_seeks + user_scans + user_lookups   
, writes =  user_updates   
, rows = (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id)
, CASE
	WHEN s.user_updates < 1 THEN 100
	ELSE 1.00 * (s.user_seeks + s.user_scans + s.user_lookups) / s.user_updates
  END AS reads_per_write
, 'DROP INDEX ' + QUOTENAME(i.name) 
+ ' ON ' + QUOTENAME(c.name) + '.' + QUOTENAME(OBJECT_NAME(s.object_id)) as 'drop statement'
FROM sys.dm_db_index_usage_stats s  
INNER JOIN sys.indexes i ON i.index_id = s.index_id AND s.object_id = i.object_id   
INNER JOIN sys.objects o on s.object_id = o.object_id
INNER JOIN sys.schemas c on o.schema_id = c.schema_id
WHERE OBJECTPROPERTY(s.object_id,'IsUserTable') = 1
AND s.database_id = DB_ID()   
AND i.type_desc = 'nonclustered'
AND i.is_primary_key = 0
AND i.is_unique_constraint = 0
AND (SELECT SUM(p.rows) FROM sys.partitions p WHERE p.index_id = s.index_id AND s.object_id = p.object_id) > 10000
ORDER BY reads

--find missing indexes
SELECT  sys.objects.name
, (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) AS Impact
,  'CREATE NONCLUSTERED INDEX ix_IndexName ON ' + sys.objects.name COLLATE DATABASE_DEFAULT + ' ( ' + IsNull(mid.equality_columns, '') + CASE WHEN mid.inequality_columns IS NULL 
                THEN ''  
    ELSE CASE WHEN mid.equality_columns IS NULL 
                    THEN ''  
        ELSE ',' END + mid.inequality_columns END + ' ) ' + CASE WHEN mid.included_columns IS NULL 
                THEN ''  
    ELSE 'INCLUDE (' + mid.included_columns + ')' END + ';' AS CreateIndexStatement
, mid.equality_columns
, mid.inequality_columns
, mid.included_columns 
    FROM sys.dm_db_missing_index_group_stats AS migs 
            INNER JOIN sys.dm_db_missing_index_groups AS mig ON migs.group_handle = mig.index_group_handle 
            INNER JOIN sys.dm_db_missing_index_details AS mid ON mig.index_handle = mid.index_handle AND mid.database_id = DB_ID() 
            INNER JOIN sys.objects WITH (nolock) ON mid.OBJECT_ID = sys.objects.OBJECT_ID 
    WHERE     (migs.group_handle IN 
        ( 
        SELECT     TOP (500) group_handle 
            FROM          sys.dm_db_missing_index_group_stats WITH (nolock) 
            ORDER BY (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) DESC))  
        AND OBJECTPROPERTY(sys.objects.OBJECT_ID, 'isusertable')=1 
    ORDER BY 2 DESC , 3 DESC 
    
--queries in the plan cache that are missing an index
SELECT qp.query_plan
, total_worker_time/execution_count AS AvgCPU 
, total_elapsed_time/execution_count AS AvgDuration 
, (total_logical_reads+total_physical_reads)/execution_count AS AvgReads 
, execution_count 
, SUBSTRING(st.TEXT, (qs.statement_start_offset/2)+1 , ((CASE qs.statement_end_offset WHEN -1 THEN datalength(st.TEXT) ELSE qs.statement_end_offset END - qs.statement_start_offset)/2) + 1) AS txt 
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/@Impact)[1]' , 'decimal(18,4)') * execution_count AS TotalImpact
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Database)[1]' , 'varchar(100)') AS [DATABASE]
, qp.query_plan.value('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan"; (/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex/@Table)[1]' , 'varchar(100)') AS [TABLE]
FROM sys.dm_exec_query_stats qs
cross apply sys.dm_exec_sql_text(sql_handle) st
cross apply sys.dm_exec_query_plan(plan_handle) qp
WHERE qp.query_plan.exist('declare default element namespace "http://schemas.microsoft.com/sqlserver/2004/07/showplan";/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple/QueryPlan/MissingIndexes/MissingIndexGroup/MissingIndex[@Database!="m"]') = 1
ORDER BY TotalImpact DESC    

--index fragmentation
SELECT
      db.name AS databaseName
    , ps.OBJECT_ID AS objectID
    , ps.index_id AS indexID
    , ps.partition_number AS partitionNumber
    , ps.avg_fragmentation_in_percent AS fragmentation
    , ps.page_count
FROM sys.databases db
  INNER JOIN sys.dm_db_index_physical_stats (NULL, NULL, NULL , NULL, N'Limited') ps
      ON db.database_id = ps.database_id
WHERE ps.index_id > 0 
   AND ps.page_count > 100 
   AND ps.avg_fragmentation_in_percent > 30
OPTION (MaxDop 1);


--index stats for specified database
declare @dbname varchar(50)
set @dbname = 'SoftwareMgmt'

select db_name(t1.database_id) as dbname, OBJECT_NAME(t1.object_id) as table_name, t1.index_id, t2.name as index_name, t2.type_desc
  user_seeks, user_scans, user_lookups, user_updates, 
  system_seeks, system_scans, system_lookups, system_updates, 
  last_user_seek, last_user_scan, last_user_lookup, last_user_update,
  last_system_seek, last_system_scan, last_system_lookup, last_system_update,
  is_unique, is_primary_key, fill_factor
from sys.dm_db_index_usage_stats t1 (nolock)
  join sys.indexes t2 (nolock) on t1.object_id = t2.object_id and t1.index_id = t2.index_id
  join sys.objects t3 (nolock) on t1.object_id = t3.object_id
where 1=1
  and t1.database_id > 4
  and DB_NAME(t1.database_id) = @dbname
  and t3.is_ms_shipped = 0
order by 2, 3
