set nocount on

declare @t1 table (DatabaseName varchar(50))
insert into @t1
select name from master.dbo.sysdatabases 
--where name = 'tempdb'

create table #t2 (DatabaseName varchar(50), sizeMB decimal(17,4), space_usedMB decimal(17,4))

declare @dbname varchar(50), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE ' + @dbname + N'; EXEC(''insert into #t2 select db_name(),
size/128.0 as SizeMB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0 as SpaceUsedMB
FROM sys.database_files where type=0;'');');
delete from @t1 where DatabaseName = @dbname
end 

select 
  @@servername as server, 
  DatabaseName,
  SUM(sizeMB) as SizeTotal,
  SUM(space_usedMB) as UsedTotal,
  SUM(sizeMB) - SUM(space_usedMB) as FreeSpace ,
  case when sum(space_usedMB) = 0 then 0 else cast(((cast(sum(space_usedMB) as decimal(17,2))/cast(sum(sizeMB) as decimal(17,2)))*100) as decimal(4,2)) end as pct_used 
from #t2
group by DatabaseName
order by DatabaseName
drop table #t2

--select * from sys.database_files 
