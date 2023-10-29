USE [DBA]
GO
/****** Object:  StoredProcedure [dbo].[usp_dba_CopyBackupFiles]    Script Date: 01/20/2015 13:28:26 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO






create procedure [dbo].[usp_dba_CopyBackupFiles] 
(
	@database varchar(100) = NULL,
	@destPath varchar(500),
	@execute char(1) = N'N',
	@backupType varchar(4) = N'FULL',
	@deleteOldFromDest char(1) = N'Y',
	@destPathFreePct int = 10,
	@printCmd char(1) = N'N',
	@checkFree char(1) = N'Y'
)
as

set nocount on
	
--declare variables and create tables
if exists (select * from DBA.sys.objects where name = 'tmp_BackupCopy' and type in (N'U'))
begin
  drop table DBA.[dbo].[tmp_BackupCopy]
end
create table DBA.dbo.tmp_BackupCopy (output varchar(5000))

declare @db varchar(100)
declare @path varchar(1000)
declare @sql varchar(3000)
declare @type char(1)
declare @ext char(3)
declare @v1 varchar(50)
declare @v2 int
declare @freeSpaceGB int
declare @spaceNeededGB int
declare @last int
declare @setid int

create table #t0 (Output varchar(100))
create table #t1 (DbName varchar(100))
create table #t2 (DbName varchar(100), BackupSetId int, FileSizeGB decimal(18,2), BakFilePath varchar(1000))
create table #t3 (BakFilePath varchar(1000))

select @type = 
  case when @backupType = 'FULL' then 'D' 
       when @backupType = 'DIFF' then 'I'
       when @backupType = 'TLOG' then 'L'
  end,
	   @ext = 
  case when @backupType = 'FULL' then 'bak' 
       when @backupType = 'DIFF' then 'dif'
       when @backupType = 'TLOG' then 'trn'
  end
  
--delete old files of type @type from @destPath for database @database
if @deleteOldFromDest = 'Y'
begin
  if @database is not null 
  begin
    set @sql = 'exec master.dbo.xp_cmdshell ''dir ' + @destPath + '\' + @database + '*.' + @ext + ''''
    insert into #t3 exec(@sql)
	set @sql = 'exec master.dbo.xp_cmdshell ''del /Q /F ' + @destPath + '\' + @database + '*.' + @ext + ''''
  end
  else 
  begin
    set @sql = 'exec master.dbo.xp_cmdshell ''dir ' + @destPath + '\*.' + @ext + ''''
    insert into #t3 exec(@sql)
    set @sql = 'exec master.dbo.xp_cmdshell ''del /Q /F ' + @destPath + '\*.' + @ext + ''''
  end
	if not exists (select * from #t3 as t3 where BakFilePath like 'File Not Found%')
    begin
      exec(@sql)
    end
end

--check @destPath for free space
set @sql = 'exec master.dbo.xp_cmdshell ''dir ' + @destPath + ' | findstr "bytes" | findstr "free"'''
insert into #t0
exec(@sql)

select @v1 = right(output,len(output)-charindex(')',output,1)-2)
from #t0 as t0
where output is not null

set @v2 = charindex('b',@v1,1)

set @freeSpaceGB = cast(replace(left(@v1,@v2-1),',','') as bigint)/1024/1024/1024

--get list of most recent backups of type @type
if @backupType = 'TLOG'
begin
--get list of tlog backups since last diff or last full
  if @database is not null
  begin
    set @last = (select top 1 backup_set_id from msdb.dbo.backupset
				 where database_name = @db
				   and type <> @type
				 order by backup_start_date desc)
	
	insert into #t2
	select b1.database_name, b1.backup_set_id, cast(b1.backup_size/1024/1024/1024 as decimal(18,2)), rtrim(b3.physical_device_name)
    from msdb.dbo.backupset as b1
      left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
      left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
    where database_name = @db
      and type = @type
      and b1.backup_set_id > @last
    order by backup_start_date desc
  end
  else --run for all databases
  begin
    insert into #t1
    select name from master.dbo.sysdatabases where dbid > 4 and name not in ('DBA','PSDBA')

    while exists (select top 1 * from #t1 t1)
    begin
      set @db = (select top 1 DbName from #t1 t1)
      set @last = (select top 1 backup_set_id from msdb.dbo.backupset
	  			   where database_name = @db
				     and type <> @type
				   order by backup_start_date desc)

	  insert into #t2
	  select b1.database_name, b1.backup_set_id, cast(b1.backup_size/1024/1024/1024 as decimal(18,2)), rtrim(b3.physical_device_name)
      from msdb.dbo.backupset as b1
        left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
        left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
      where database_name = @db
        and type = @type
        and b1.backup_set_id > @last
      order by backup_start_date desc

      delete from #t1 where DbName = @db
    end 
  end
end
else
begin
  if @database is not null
  begin
    set @setid = (select top 1 b1.backup_set_id
				  from msdb.dbo.backupset as b1
				    left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
				    left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
				  where database_name = @database
				    and type = @type
				  order by backup_start_date desc)
  
    insert into #t2
    select b1.database_name, b1.backup_set_id, cast(b1.compressed_backup_size/1024/1024/1024 as decimal(18,2))/b1.last_family_number, rtrim(b3.physical_device_name)
    from msdb.dbo.backupset as b1
      left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
      left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
    where database_name = @database
      and type = @type
      and b1.backup_set_id = @setid
    order by backup_start_date desc
  end
  else --run for all databases
  begin
    insert into #t1
    select name from master.dbo.sysdatabases where dbid > 4 and name not in ('DBA','PSDBA')

    while exists (select top 1 * from #t1 t1)
    begin
      set @db = (select top 1 DbName from #t1 t1)
      set @setid = (select top 1 b1.backup_set_id
				    from msdb.dbo.backupset as b1
				  	  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
					  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
				    where database_name = @db
					  and type = @type
				    order by backup_start_date desc)
				  
      insert into #t2
      select b1.database_name, b1.backup_set_id, cast(b1.compressed_backup_size/1024/1024/1024 as decimal(18,2))/b1.last_family_number, rtrim(b3.physical_device_name)
      from msdb.dbo.backupset as b1
        left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
        left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
      where database_name = @db
        and type = @type
        and b1.backup_set_id = @setid
      order by backup_start_date desc

      delete from #t1 where DbName = @db
    end 
  end
end

--check if enough file space on @destPath
if @checkFree = 'Y'
begin
  select @spaceNeededGB = SUM(FileSizeGB) from #t2 as t2
    if @spaceNeededGB >= @freeSpaceGB - (@freeSpaceGB*@destPathFreePct/100)
    begin
      print @@servername + ': Not enough space on destination drive (' + @destPath + '): Free space = ' + cast(@freeSpaceGB as varchar(5)) + 'GB, Needed space = ' + cast(@spaceNeededGB as varchar(5)) + 'GB'
      return
    end
end

--copy files to @destPath  
if @execute = 'N'
begin
  while exists (select 1 from #t2)
  begin
    set @setid = (select top 1 BackupSetId from #t2)
    set @path = (select top 1 BakFilePath from #t2)
    if @printCmd = 'Y'
    begin
      set @sql = 'xcopy ' + @path + ' ' + @destPath + ' /i /y'
      print(@sql)
    end
    else
    begin
      set @sql = 'exec master.dbo.xp_cmdshell ''xcopy ' + @path + ' ' + @destPath + ' /i /y'''
      print(@sql)
    end
    delete from #t2 where BackupSetId = @setid and BakFilePath = @path
  end
end
else
begin
  while exists (select 1 from #t2)
  begin
    set @setid = (select top 1 BackupSetId from #t2)
    set @path = (select top 1 BakFilePath from #t2)
    set @sql = 'exec master.dbo.xp_cmdshell ''xcopy ' + @path + ' ' + @destPath + ' /i /y'''
    insert into DBA.dbo.tmp_BackupCopy
    exec(@sql)
    delete from #t2 where BackupSetId = @setid and BakFilePath = @path
  end
set @sql = 'exec master.dbo.xp_cmdshell ''dir ' + @destPath + ''''
insert into DBA.dbo.tmp_BackupCopy
exec(@sql)
end


drop table #t0
drop table #t1
drop table #t2
drop table #t3



