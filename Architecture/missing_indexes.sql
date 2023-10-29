--tables with no index
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4
  and name <> 'DBA'

create table #t1  (DbName varchar(255), SchemaName varchar(100), TableName varchar(255), Impact numeric(18,2), EqualityColumns varchar(1000), InequalityColumns varchar(1000), IncludedColumns varchar(1000))

declare @sql varchar(4000)
declare @db varchar(255)

while exists (select 1 from @t0)
begin
  set @db = (select top 1 DbName from @t0)
  set @sql = 'use ' + @db + ';
	insert into #t1
	select db_name(),
	  SCHEMA_NAME(o.schema_id),
	  o.name,
	  (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans),
	  mid.equality_columns,
	  mid.inequality_columns,
	  mid.included_columns 
	from sys.dm_db_missing_index_group_stats as migs 
	  join sys.dm_db_missing_index_groups as mig on migs.group_handle = mig.index_group_handle 
	  join sys.dm_db_missing_index_details as mid on mig.index_handle = mid.index_handle and mid.database_id = db_id() 
	  join sys.objects as o on mid.object_id = o.object_id
	where (migs.group_handle in ( 
			select top 500 group_handle 
			from sys.dm_db_missing_index_group_stats (nolock) 
			order by (avg_total_user_cost * avg_user_impact) * (user_seeks + user_scans) desc))  
	  and OBJECTPROPERTY(o.object_id, ''isusertable'')=1 
	order by 2 desc , 3 desc'
 
  exec(@sql)
  
  delete from @t0 where DbName = @db
end

select * from #t1

drop table #t1
