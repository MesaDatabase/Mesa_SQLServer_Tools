USE [master]
GO
/****** Object:  StoredProcedure [dbo].[usp_dba_generate_restore_script]    Script Date: 7/10/2015 4:34:34 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO




ALTER procedure [dbo].[usp_dba_generate_restore_script] 
(
  @bakType varchar(4) = 'FULL',
  @recovery char(1) = 'N',
  @copyDest varchar(500),
  @recoverOnly char(1) = 'N',
  @replace char(1) = 'N',
  @restoreAllFromDisk char(1) = 'Y',
  @dataLocation varchar(255),
  @logLocation varchar(255),
  @ftLocation varchar(255),
  @locationTable char(1) = 'N'
)
as


set nocount on

--declare @bakType varchar(4)
--declare @recovery char(1)
--declare @copyDest varchar(500)

--set @bakType = 'FULL'
--set @recovery = 'N'
--set @copyDest = '\\WKPEXGDVSQLCD01\d$\Migration'
  
declare @dbname varchar(100)
declare @sql varchar (8000)
declare @file varchar(200)
declare @recString varchar(500)
declare @last int
declare @filepath varchar(1000)
declare @logical varchar(100)
declare @physical varchar(100)
declare @newPath varchar(255)
declare @fileType varchar(25)

declare @t1 table (DatabaseName varchar(100))
declare @t2 table (database_name varchar(100), BackupSetId int, filepath varchar(1000))
declare @t3 table (Output varchar(1000))
declare @t4 table (LogicalName nvarchar(128), PhysicalName nvarchar(260), Type char(1), FileGroupName nvarchar(128), Size numeric(20,0), MaxSize numeric(20,0), FileId bigint, CreateLSN numeric(25,0), DropLSN numeric(25,0), UniqueId uniqueidentifier, ReadOnlyLSN numeric(25,0), ReadWriteLSN numeric(25,0), BackupSizeInBytes bigint, SourceBlockSize int, FileGroupId int, LogGroupGUID uniqueidentifier, DifferentialBaseLSN numeric(25,0), DifferentialBaseGUID uniqueidentifier, IsReadOnly bit, IsPresent bit, TDEThumbprint varbinary(32))
declare @t5 table (DatabaseName varchar(100), FileId int, LogicalFileName varchar(128), PhysicalFileName varchar(128), Type char(1))

if object_id('tempdb..#t2') is not null
begin
    drop table #t2
end
create table #t2 (database_name varchar(100), BackupSetId int, filepath varchar(1000))

if @recoverOnly = 'Y'
begin
  insert into @t1
  select name from master.sys.databases 
  where name not in ('master','DBA','master','model','msdb','tempdb')
    and state_desc = 'RESTORING'

  while exists (select top 1 * from @t1 as t1)
  begin
    select top 1 @dbname = DatabaseName
    from @t1 as t1
    order by DatabaseName asc

	set @sql = 'restore database [' + @dbname + '] with recovery'
	print(@sql)
	
	delete from @t1 where DatabaseName = @dbname
  end
return
end


if @copyDest is null
begin print '@copyDest must be specified' return end

if @recovery = 'Y'
begin
	set @recString = 'recovery'
end
else
begin
	set @recString = 'norecovery'
end

if @locationTable is null and (@dataLocation is null or @logLocation is null)
begin print 'Either @locationTable or @dataLocation and @logLocation must be specified' return end
  
if @bakType = 'FULL' set @bakType = 'D'
else if @bakType = 'DIFF' set @bakType = 'I'
else if @bakType = 'TLOG' set @bakType = 'L'
else begin print '@bakType must be FULL, DIFF or TLOG' return end

insert into @t1
select name from master.dbo.sysdatabases where name not in ('DBA','master','model','msdb','tempdb')

if @bakType = 'L'
begin
  --gets list of tlog backup file names since last full/diff
  while exists (select top 1 * from @t1 t1)
  begin
    set @dbname = (select top 1 DatabaseName from @t1 t1)
    set @last = (select top 1 backup_set_id from msdb.dbo.backupset
				 where database_name = @dbname
				   and type <> @bakType
				 order by backup_start_date desc)
				 
    insert into #t2
    select d1.name, b1.backup_set_id, b3.physical_device_name
    from master.sys.databases as d1
      left join msdb.dbo.backupset as b1 on d1.name = b1.database_name
      left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
      left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
    where database_name = @dbname
      and type = @bakType
      and b1.backup_set_id > @last
    order by backup_start_date desc

    delete from @t1 where DatabaseName = @dbname
  end 
end
else
begin
  --returns last backup file name of type @bakType
  if @restoreAllFromDisk = 'N'
  begin
	  while exists (select top 1 * from @t1 t1)
	  begin
		set @dbname = (select top 1 DatabaseName from @t1 t1)
		insert into #t2
		select top 1 d1.name, b1.backup_set_id, b3.physical_device_name
		from master.sys.databases as d1
		  left join msdb.dbo.backupset as b1 on d1.name = b1.database_name
		  left join msdb.dbo.backupmediaset as b2 on b1.media_set_id = b2.media_set_id
		  left join msdb.dbo.backupmediafamily as b3 on b2.media_set_id = b3.media_set_id
		where database_name = @dbname
		  and type = @bakType
		order by backup_start_date desc

		delete from @t1 where DatabaseName = @dbname
	  end 
	end
  if @restoreAllFromDisk = 'Y'
  begin
    set @sql = 'exec xp_cmdshell ''dir ' + @copyDest + ' /b'''
	insert into @t3 exec(@sql)
	
	insert into #t2
	select left(Output,len(Output)-len(rtrim(right(Output, charindex('_', reverse(Output)) - 1 +4)))), NULL, @copyDest + '\' + Output
	from @t3 as t3
	where Output like '%.bak%'
  end
end


--restore all from disk, specify move
while exists (select top 1 * from #t2 as t2)
begin
    if @restoreAllFromDisk = 'Y'
	begin
		select top 1 @dbname = database_name, @filepath = filepath
		from #t2 as t2
		order by database_name, filepath asc
		
		set @sql = 'restore filelistonly from disk = ''' + @filepath + ''''
		insert into @t4 exec(@sql)
		
		insert into @t5
		select @dbname, FileId, LogicalName, rtrim(right(PhysicalName, charindex('\', reverse(PhysicalName)) - 1)), Type 
		from @t4
		
		if @locationTable = 'Y'
		begin
			while exists (select top 1 * from @t5 where DatabaseName = @dbname order by Type, FileId)
			begin
				select top 1 @logical = LogicalFileName, @physical = PhysicalFileName, @newPath = d1.Drive + ':\MSSQL\Data\' + PhysicalFileName, @fileType = t5.Type from @t5 as t5
					left join master.dbo.tbl_dbfile_locations as d1 on t5.DatabaseName = d1.DbName and t5.LogicalFileName = d1.LogicalName
			
				if @recString is null and @physical like '%.mdf'
					set @recString = 'move ''' + @logical + ''' to ''' + @newPath + ''''
				if @recString is not null and @physical like '%.mdf'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
				if @physical like '%.ndf'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
				if @physical like '%.ldf'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
				if @fileType = 'F'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
			    
				delete from @t5 where DatabaseName = @dbname and LogicalFileName = @logical
			end

			if exists (select * from @t1 where DatabaseName = @dbname)
			begin
				if @recovery = 'Y'
				begin
					set @recString = @recString + ', replace, recovery'
				end
				else
				begin
					set @recString = @recString + ', replace, norecovery'
				end
			end
			else
			begin
				if @recovery = 'Y'
				begin
					set @recString = @recString + ', recovery'
				end
				else
				begin
					set @recString = @recString + ', norecovery'
				end
			end
			
			set @sql = 'restore database [' + @dbname + '] from disk = ''' + @filepath + ''' with ' + @recString + ''
			print(@sql)
			set @recString = NULL
		end
	
		if @locationTable = 'N'
		begin
			while exists (select top 1 * from @t5 where DatabaseName = @dbname order by Type, FileId)
			begin
				select top 1 @logical = LogicalFileName, @physical = PhysicalFileName, @newPath = case when t5.Type = 'D' then @dataLocation when t5.Type = 'L' then @logLocation when t5.Type = 'F' then @ftLocation end  + PhysicalFileName, @fileType = t5.Type from @t5 as t5
							
				if @recString is null and @physical like '%.mdf'
					set @recString = 'move ''' + @logical + ''' to ''' + @newPath + ''''
				if @recString is not null and @physical like '%.mdf'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
				if @physical like '%.ndf'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
				if @physical like '%.ldf'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
				if @fileType = 'F'
					set @recString = @recString + ', move ''' + @logical + ''' to ''' + @newPath + ''''
			    
				delete from @t5 where DatabaseName = @dbname and LogicalFileName = @logical
			end

			if exists (select * from @t1 where DatabaseName = @dbname)
			begin
				if @recovery = 'Y'
				begin
					set @recString = @recString + ', replace, recovery'
				end
				else
				begin
					set @recString = @recString + ', replace, norecovery'
				end
			end
			else
			begin
				if @recovery = 'Y'
				begin
					set @recString = @recString + ', recovery'
				end
				else
				begin
					set @recString = @recString + ', norecovery'
				end
			end
			
			set @sql = 'restore database [' + @dbname + '] from disk = ''' + @filepath + ''' with ' + @recString + ''
			print(@sql)
			set @recString = NULL
		end
	end
	
	if @restoreAllFromDisk = 'N'
	begin
		select top 1 @dbname = database_name, @file = master.dbo.fSplit('\',filepath,6), @filepath = filepath
		from #t2 as t2
		order by database_name, filepath asc

		set @sql = 'restore database [' + @dbname + '] from disk = ''' + @copyDest + '\' + @file + ''' with ' + @recString + ''
		print(@sql)
		set @recString = NULL
	end

	delete from #t2 where database_name = @dbname and filepath = @filepath
	delete from @t4
end

