--tables with no clustered index
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4

create table #t1  (DbName varchar(255), SchemaName varchar(100), TableName varchar(255), RowCnt bigint, UserSeeks bigint, UserScans bigint, UserLookups bigint, UserUpdates bigint, LastUserSeek datetime, LastUserScan datetime, LastUserLookup datetime, LastUserUpdate datetime)

declare @sql varchar(4000)
declare @db varchar(255)

while exists (select 1 from @t0)
begin
  set @db = (select top 1 DbName from @t0)
  set @sql = 'use ' + @db + ';
	insert into #t1
	select db_name(),
	SCHEMA_NAME(o.schema_id) 
	,object_name(i.object_id) 
	,p.rows
	,user_seeks 
	,user_scans 
	,user_lookups 
	,user_updates 
	,last_user_seek 
	,last_user_scan 
	,last_user_lookup 
	,last_user_update
	FROM sys.indexes i      
	INNER JOIN sys.objects o ON i.object_id = o.object_id
	INNER JOIN sys.partitions p ON i.object_id = p.object_id AND i.index_id = p.index_id 
	LEFT OUTER JOIN sys.dm_db_index_usage_stats ius ON i.object_id = ius.object_id AND i.index_id = ius.index_id 
	WHERE i.type_desc = ''HEAP''
	 and last_user_scan is not null
	 and is_ms_shipped = 0'
 
  exec(@sql)
  
  delete from @t0 where DbName = @db
end

select * from #t1

drop table #t1
