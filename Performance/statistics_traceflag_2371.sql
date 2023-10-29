/* The sysindexes.rowmodctr column maintains a running total of all modifications to a table that, over time, can adversely affect the query 
processor's decision making process. This counter is updated each time any of the following events occurs:
 * A single row insert is made
 * A single row delete is made
 * An update to an indexed column is made
 * TRUNCATE TABLE does not update rowmodctr

The basic algorithm for auto update statistics is:
 * If the cardinality for a table is less than six and the table is in the tempdb database, auto update with every six modifications to the table. 
 * If the cardinality for a table is greater than 6, but less than or equal to 500, update status every 500 modifications. 
 * If the cardinality for a table is greater than 500, update statistics when (500 + 20 percent of the table) changes have occurred. 
 * For table variables, cardinality changes do not trigger auto update statistics. 

Trace flag 2371 enabled:
  * The higher the number of rows in a table, the lower the threshold will become to trigger an update of the statistics.

Returns properties of statistics for the specified database object (2008 R2 SP2 and 2012 SP1)
SELECT
    sp.stats_id, name, filter_definition, last_updated, rows, rows_sampled, steps, unfiltered_rows, modification_counter 
FROM sys.stats AS stat 
CROSS APPLY sys.dm_db_stats_properties(stat.object_id, stat.stats_id) AS sp
WHERE stat.object_id = object_id('mapITAsset2ExecutablesUsage');

SELECT DISTINCT
	tablename=object_name(i.object_id)
	, o.type_desc
	,index_name=i.[name]
    , statistics_update_date = STATS_DATE(i.object_id, i.index_id)
	, si.rowmodctr
FROM sys.indexes i (nolock)
JOIN sys.objects o (nolock) on
	i.object_id=o.object_id
JOIN sys.sysindexes si (nolock) on
	i.object_id=si.id
	and i.index_id=si.indid
where
	o.type != 'S'  --ignore system objects
	and STATS_DATE(i.object_id, i.index_id) is not null
order by si.rowmodctr desc