--sprocs that use cursors that dont get closed
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where database_id > 4
  and name <> 'DBA'

create table #t1  (DbName varchar(255), SchemaName varchar(100), ObjectName varchar(255), Type varchar(100))

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
	o.type_desc
    from sys.sql_modules m 
      join sys.objects  o ON m.object_id=o.object_id
    where m.definition Like ''%cursor%''
      and m.definition like ''%open%''
      and m.definition not like ''%close%'' 
      and m.definition not like ''%deallocate%'''
 
  exec(@sql)
  
  delete from @t0 where DbName = @db
end

select distinct
DbName, SchemaName, ObjectName, Type
from #t1

drop table #t1
