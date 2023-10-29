--tables with no index
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4
  and name <> 'DBA'

create table #t1  (DbName varchar(255), SchemaName varchar(100), TableName varchar(255), IndexName varchar(255), IndexType varchar(100))

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
	i.type
	FROM sys.objects o 
	left join sys.indexes i ON i.object_id = o.object_id
	where o.type = ''U''
	  and i.name is null'
 
  exec(@sql)
  
  delete from @t0 where DbName = @db
end

select * from #t1

drop table #t1
