set nocount on

declare @t1 table (DatabaseName varchar(100))
insert into @t1
select name from master.sys.databases
where state_desc not in ('OFFLINE','RESTORING')

if object_id('tempdb..#t2') is not null
begin
    drop table #t2
end
create table #t2 (Server varchar(500), DbId int, DatabaseName varchar(100), file_id int, file_name varchar(100), physical_name varchar(200), TypeDesc varchar(10), drive char(1), sizeMB decimal(17,4), space_usedMB decimal(17,4), sizeGB decimal(17,4), space_usedGB decimal(17,4))

declare @dbname varchar(100), @SQL varchar (8000)
set @SQL=''

while exists (select top 1 * from @t1 t1)
begin
set @dbname = (select top 1 DatabaseName from @t1 t1)
--USE master;
EXEC(N'USE [' + @dbname + N']; EXEC(''insert into #t2 select @@servername, db_id(), db_name(), file_id, name, physical_name, type_desc, left(physical_name,1),
size/128.0 as SizeMB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0 as SpaceUsedMB,
size/128.0/1024 as SizeGB,
CAST(FILEPROPERTY(name, ''''SpaceUsed'''') AS int)/128.0/1024 as SpaceUsedGB
FROM sys.database_files;'');');
delete from @t1 where DatabaseName = @dbname
end 

declare @t3 table (Output varchar(1000))

set @sql = 'exec xp_cmdshell ''wmic volume get name, label, capacity, freespace /format:csv'''
insert into @t3
exec(@sql)

declare @t4 table (Server varchar(500), Drive char(1), DriveLabel varchar(50), SizeMB int, FreeSpaceMB int)
insert into @t4
select 
  master.dbo.fSplit(',',Output,1) as Server,
  left(master.dbo.fSplit(',',Output,5),1) as Drive,
  replace(master.dbo.fSplit(' ',master.dbo.fSplit(',',Output,4),1),'_VNX','') as DriveLabelClean,
  cast(master.dbo.fSplit(',',Output,2) as bigint)/1024/1024 as SizeMB,
  cast(master.dbo.fSplit(',',Output,3) as bigint)/1024/1024 as FreeSpaceMB
from @t3 as t3
where Output not like 'Capacity%'
  and ISNULL(Output,'') <> ''
  and Output not like '%\\?%'
  and Output like '%:\%'
  
declare @t5 table (Server varchar(500), Drive char(1), Label varchar(25), DriveSizeGB int, DriveFreeGB int, DriveUsedGB int, SQLDataGB int, SQLLogGB int, FileSizeGB int, FileUsedGB int, SysDbFileCnt int, UserDbFileCnt int)
insert into @t5
select
  t2.Server,
  t4.Drive,
  case when t4.DriveLabel like '%data%' then 'Data'
	   when t4.DriveLabel like '%log%' then 'Log'
	   when t4.DriveLabel like '%temp%' then 'TempDB'
	   else t4.DriveLabel
  end,
  t4.SizeMB/1024,
  t4.FreeSpaceMB/1024,
  (t4.SizeMB - t4.FreeSpaceMB)/1024,
  sum(case when t2.TypeDesc = 'ROWS' then t2.sizeGB when t2.TypeDesc = 'FULLTEXT' then t2.sizeGB else 0 end),
  sum(case when t2.TypeDesc = 'LOG' then t2.sizeGB else 0 end),
  sum(t2.sizeGB),
  sum(t2.space_usedGB),
  count(distinct case when DbId is not null and DbId <= 4 then DbId else NULL end),
  count(distinct case when DbId is not null and DbId > 4 then DbId else NULL end)
from #t2 as t2
  right join @t4 as t4 on t2.Server = t4.server and t2.drive = t4.drive
group by   
  t2.Server,
  t4.Drive,
  case when t4.DriveLabel like '%data%' then 'Data'
	   when t4.DriveLabel like '%log%' then 'Log'
	   when t4.DriveLabel like '%temp%' then 'TempDB'
	   else t4.DriveLabel
  end,
  t4.SizeMB,
  t4.FreeSpaceMB
  
   
select 
  @@SERVERNAME,
  Drive,
  Label,
  DriveSizeGB,
  DriveFreeGB,
  isnull(FileSizeGB,0) as FileSizeGB,
  DriveSizeGB - DriveFreeGB - isnull(FileSizeGB,0) as NonDbUsedGB,
  isnull(FileSizeGB,0) - isnull(FileUsedGB,0) as FileFreeGB,
  isnull(FileUsedGB,0) as FileUsedGB,
  isnull(SQLDataGB,0) as SQLDataGB,
  isnull(SQLLogGB,0) as SQLLogGB,
  isnull(SysDbFileCnt,0) as SysDbFileCnt,
  isnull(UserDbFileCnt,0) as UserDbFileCnt,
  case when isnull(FileSizeGB,0) = 0 then cast(100 as decimal(6,2))
    else cast((cast(isnull(FileSizeGB,0) - isnull(FileUsedGB,0) as decimal(18,4))/cast(isnull(FileSizeGB,0) as decimal(18,4))) as decimal(6,2)) end as FileFreePct,
  case when DriveSizeGB = 0 then cast(100 as decimal(6,2))
    else cast((cast(DriveFreeGB as decimal(18,4))/cast(DriveSizeGB as decimal(18,4))) as decimal(6,2)) end as DriveFreePct,
  case when DriveSizeGB = 0 then cast(100 as decimal(6,2))
    else cast((cast((isnull(FileSizeGB,0) - isnull(FileUsedGB,0) + DriveFreeGB) as decimal(18,4))/cast(DriveSizeGB as decimal(18,4))) as decimal(6,2)) end as DriveAndFileFreePct,
  isnull(FileSizeGB,0) - isnull(FileUsedGB,0) + DriveFreeGB as TotalFreeGB
from @t5
where DriveSizeGB > 0

drop table #t2

