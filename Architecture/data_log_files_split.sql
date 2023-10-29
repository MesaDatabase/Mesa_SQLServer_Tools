--are logs, data files and tempdb split?
declare @t0 table (DbName varchar(255))
insert into @t0
select name from sys.databases
where name not in ('master','msdb','model','DBA','PSDBA')

create table #t1  (DbName varchar(255), TypeDesc varchar(100), Drive char(1))

declare @sql varchar(4000)
declare @db varchar(255)

while exists (select 1 from @t0)
begin
  set @db = (select top 1 DbName from @t0)
  set @sql = 'use ' + @db + ';
	insert into #t1
	select db_name(),
	type_desc, LEFT(physical_name,1)
	from sys.database_files'
 
  exec(@sql)
  
  delete from @t0 where DbName = @db
end

select *
from #t1 as t1
  join #t1 as t2 on t1.DbName = t2.DbName and t1.TypeDesc <> t2.TypeDesc and t1.Drive = t2.Drive
where t1.DbName <> 'tempdb'
  
select *
from #t1 as t1
  join #t1 as t2 on t1.Drive = t2.Drive
where t1.DbName = 'tempdb'
  and t2.DbName <> 'tempdb'


drop table #t1
