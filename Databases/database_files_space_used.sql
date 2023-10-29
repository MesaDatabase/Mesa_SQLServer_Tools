--file sizes and autogrowth settings
set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.dbo.sysdatabases 
where name not in ('master','msdb','model','DBA')

create table #t2 (DatabaseName varchar(100), FileId int, FileName varchar(100), PhysicalName varchar(200), Type varchar(10), Drive char(1), 
	SizeMB decimal(17,4), UsedMB decimal(17,4), SizeGB decimal(17,4), UsedGB decimal(17,4),
	MaxSize bigint, Growth bigint, IsPercentGrowth bit)

declare @dbname varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select db_name(), file_id, name, physical_name, type_desc, left(physical_name,1),
size/128.0 as SizeMB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0 as SpaceUsedMB,
size/128.0/1024 as SizeGB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0/1024 as SpaceUsedGB,
max_size, growth, is_percent_growth
FROM sys.database_files;'');');
delete from @t1 where DatabaseName = @dbname
end 

select
  DatabaseName,
  FileId,
  FileName,
  PhysicalName,
  Type,
  Drive,
  SizeMB,
  UsedMB,
  SizeGB,
  UsedGB, 
  case when UsedMB = 0 then 0 
	   else cast(((cast(UsedMB as decimal(17,2))/cast(SizeMB as decimal(17,2)))*100) as decimal(8,4)) end as UsedPct,
  case when MaxSize = -1 then 'Unlimited'
	   else cast(MaxSize*8/1024 as varchar(20)) end as MaxSizeMB,
  case when IsPercentGrowth = 0 then Growth*8/1024 
       else NULL end as GrowthMB,
  case when IsPercentGrowth = 1 then Growth
       else NULL end as GrowthPct
from #t2
order by DatabaseName, Type, FileId

drop table #t2