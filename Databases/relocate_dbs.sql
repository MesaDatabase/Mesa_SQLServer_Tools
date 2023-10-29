set nocount on

declare @db varchar(255)
declare @file varchar(500)
declare @logfile varchar(255)
declare @filep1 varchar(500)
declare @filep2 varchar(500)
declare @sql varchar(500)

declare @t1 table (DbName varchar(255), Filename varchar(500), LogicalName varchar(255))
insert into @t1
select s2.name, s1.filename, s1.name from master.sys.sysaltfiles as s1
  join master.sys.databases as s2 on s1.dbid = s2.database_id
where state_desc = 'ONLINE'
  and filename like '%MSSQL\Data%' and filename not like '%Data\%'

while exists (select * from @t1)
begin
  set @db = (select top 1 DbName from @t1)
  set @file = (select top 1 Filename from @t1 where DbName = @db)
  set @logfile = (select top 1 LogicalName from @t1 where DbName = @db and Filename = @file)
  set @filep1 = (select left(@file,charindex('Data',@file)+3))
  set @filep2 = (select replace(@file,@filep1,''))
  --select @db, @file, @filep1, @filep2
  
  set @sql = 'ALTER DATABASE ' + @db + ' MODIFY FILE (name = ' + @logfile + ', filename = ''' + @filep1 + '\' + @filep2 + ''');'
  print @sql

  delete from @t1 where DbName = @db and Filename = @file
end

  