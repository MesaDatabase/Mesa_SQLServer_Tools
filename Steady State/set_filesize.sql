set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.sys.databases 
where state_desc = 'ONLINE'
  and name not in ('master','msdb','tempdb','model','DBA')

create table #t2 (DatabaseName varchar(100), file_id int, file_name varchar(100), physical_name varchar(200), type varchar(10), drive char(1), sizeMB decimal(17,4), space_usedMB decimal(17,4), sizeGB decimal(17,4), space_usedGB decimal(17,4), growth bigint, is_percent_growth tinyint)

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
growth, is_percent_growth
FROM sys.database_files;'');');
delete from @t1 where DatabaseName = @dbname
end 

select * from #t2
--drop table #t2
--return

declare @filename varchar(255)
declare @sizeGB decimal(18,2)
declare @pct int
declare @g int

while exists (select top 1 * from #t2)
begin
  set @dbname = (select top 1 DatabaseName from #t2)
  set @filename = (select top 1 file_name from #t2 where DatabaseName = @dbname)
  set @sizeGB = (select top 1 sizeGB from #t2 where DatabaseName = @dbname and file_name = @filename)
  set @pct = (select top 1 is_percent_growth from #t2 where DatabaseName = @dbname and file_name = @filename)
  --set @gkb = (select top 1 growth*8/1024 from #t2 where DatabaseName = @dbname and file_name = @filename)

  if (@pct = 1)
  begin
    if (@sizeGB <= 1)
	begin
      set @sql = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @filename + ''', FILEGROWTH = 102400KB, MAXSIZE = UNLIMITED );'
	  print(@sql)
	  --exec(@sql)
	end

    if (@sizeGB > 1)
	begin
      set @sql = 'ALTER DATABASE [' + @dbname + '] MODIFY FILE ( NAME = N''' + @filename + ''', FILEGROWTH = 524288KB, MAXSIZE = UNLIMITED );'
	  print(@sql)
	  --exec(@sql)
	end
  end
	delete from #t2 where DatabaseName = @dbname and file_name = @filename
end

drop table #t2
