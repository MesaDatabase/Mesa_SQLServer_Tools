--index width
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4
  and name <> 'DBA'

create table #t1  (DbName varchar(255), SchemaName varchar(100), TableName varchar(255), IndexName varchar(255), IndexType varchar(100), ColumnName varchar(255), IsIncludedColumn bit, MaxLength bigint)

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
		i.name,
		i.type,
		c.name,
		ic.is_included_column,
		c.max_length
		FROM sys.objects o 
		join sys.indexes i ON i.object_id = o.object_id
		join sys.index_columns ic on i.object_id = ic.object_id and i.index_id = ic.index_column_id
		join sys.columns c on ic.column_id = c.column_id
		where o.type = ''U''
		  and is_ms_shipped = 0'
 
  exec(@sql)
  
  delete from @t0 where DbName = @db
end

select *
from #t1
order by TableName, IndexName, IsIncludedColumn, ColumnName

select DbName, SchemaName, TableName, IndexName, IndexType, SUM(MaxLength)
from #t1
group by DbName, SchemaName, TableName, IndexName, IndexType
order by DbName, SchemaName, TableName, IndexName, IndexType

drop table #t1
